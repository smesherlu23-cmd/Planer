import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import '../data/database.dart';
import '../data/dates.dart';
import '../data/queries.dart';
import 'common.dart';

String journalKindLabel(JournalKind k) => switch (k) {
  JournalKind.day => 'Итог дня',
  JournalKind.week => 'Обзор недели',
  JournalKind.note => 'Заметка',
};

const _dayTemplate = 'Что сделал сегодня:\n1. \n2. \n3. \n';
const _weekTemplate = 'Что получилось:\n\nЧто не получилось:\n\nЧто меняю на следующей неделе:\n';

/// Открыть запись. Для итога дня и обзора недели на один день бывает только одна запись.
Future<void> openJournalEditor(BuildContext context, {required JournalKind kind, required int day, JournalEntry? existing}) {
  return Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => JournalEditScreen(kind: kind, day: day, existing: existing),
    ),
  );
}

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  JournalKind? _filter;

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    return Scaffold(
      appBar: AppBar(title: const Text('Записи')),
      floatingActionButton: FloatingActionButton(heroTag: null, onPressed: () => _create(context), child: const Icon(Icons.add)),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                ChoiceChip(label: const Text('Все'), selected: _filter == null, onSelected: (_) => setState(() => _filter = null)),
                for (final k in JournalKind.values) ...[
                  const SizedBox(width: 6),
                  ChoiceChip(label: Text(journalKindLabel(k)), selected: _filter == k, onSelected: (_) => setState(() => _filter = k)),
                ],
              ],
            ),
          ),
          Expanded(
            child: Watch(
              deps: [_filter],
              streams: () => [db.watchJournal(kind: _filter)],
              builder: (context, v) {
                final entries = v[0] as List<JournalEntry>;
                if (entries.isEmpty) {
                  return const EmptyHint('Итог дня: 3 дела и настроение перед сном. Через месяц это доказательство, что ты движешься.');
                }
                return ListView(
                  padding: const EdgeInsets.only(bottom: 88),
                  children: [
                    for (final e in entries)
                      Card(
                        child: ListTile(
                          title: Text(
                            [
                              e.kind == JournalKind.week ? 'Неделя с ${formatDay(e.day)}' : dayLabel(e.day),
                              journalKindLabel(e.kind),
                              if (e.mood != null) 'настроение ${e.mood}',
                            ].join(' · '),
                          ),
                          subtitle: Text(_preview(e.body), maxLines: 3, overflow: TextOverflow.ellipsis),
                          onTap: () => openJournalEditor(context, kind: e.kind, day: e.day, existing: e),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _preview(String body) =>
      body.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty && !RegExp(r'^\d+\.$').hasMatch(l)).join(' · ');

  Future<void> _create(BuildContext context) async {
    final db = context.db;
    final kind = await showModalBottomSheet<JournalKind>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final k in JournalKind.values) ListTile(title: Text(journalKindLabel(k)), onTap: () => Navigator.pop(context, k)),
          ],
        ),
      ),
    );
    if (kind == null || !context.mounted) return;
    final today = todayKey();
    final day = kind == JournalKind.week ? weekStart(today) : today;
    // Если итог за сегодня уже есть, открываем его, а не создаём второй.
    final existing = kind == JournalKind.note ? null : await db.watchJournalFor(kind, day).first;
    if (context.mounted) await openJournalEditor(context, kind: kind, day: day, existing: existing);
  }
}

class JournalEditScreen extends StatefulWidget {
  const JournalEditScreen({super.key, required this.kind, required this.day, this.existing});
  final JournalKind kind;
  final int day;
  final JournalEntry? existing;

  @override
  State<JournalEditScreen> createState() => _JournalEditScreenState();
}

class _JournalEditScreenState extends State<JournalEditScreen> {
  late final _body = TextEditingController(
    text:
        widget.existing?.body ??
        switch (widget.kind) {
          JournalKind.day => _dayTemplate,
          JournalKind.week => _weekTemplate,
          JournalKind.note => '',
        },
  );
  late int? _mood = widget.existing?.mood;
  late int _day = widget.existing?.day ?? widget.day;

  Future<void> _save() async {
    await context.db.saveJournal(
      JournalEntriesCompanion(
        id: widget.existing == null ? const Value.absent() : Value(widget.existing!.id),
        kind: Value(widget.kind),
        day: Value(_day),
        mood: Value(_mood),
        body: Value(_body.text.trimRight()),
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    final title = switch (widget.kind) {
      JournalKind.day => 'Итог дня, ${dayLabel(_day)}',
      JournalKind.week => 'Обзор недели с ${formatDay(_day)}',
      JournalKind.note => 'Заметка',
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (widget.existing != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                if (await confirm(context, 'Удалить запись?', ok: 'Удалить', danger: true)) {
                  await db.deleteById(db.journalEntries, widget.existing!.id);
                  if (context.mounted) Navigator.pop(context);
                }
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.kind != JournalKind.note) ...[
            Text('Настроение', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var i = 1; i <= 10; i++)
                  ChoiceChip(label: Text('$i'), selected: _mood == i, onSelected: (on) => setState(() => _mood = on ? i : null)),
              ],
            ),
            const SizedBox(height: 16),
          ],
          if (widget.kind == JournalKind.note) DayTile(day: _day, onChanged: (d) => setState(() => _day = d ?? _day)),
          TextField(
            controller: _body,
            minLines: 8,
            maxLines: null,
            autofocus: widget.existing == null && widget.kind == JournalKind.note,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(alignLabelWithHint: true),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _save, child: const Text('Сохранить')),
        ],
      ),
    );
  }
}
