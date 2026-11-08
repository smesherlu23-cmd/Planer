import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import '../data/database.dart';
import '../data/dates.dart';
import '../data/queries.dart';
import 'common.dart';
import 'theme.dart';

String journalKindLabel(JournalKind k) => switch (k) {
  JournalKind.day => 'Итог дня',
  JournalKind.week => 'Обзор недели',
  JournalKind.note => 'Заметка',
};

String journalKindEmoji(JournalKind k) => switch (k) {
  JournalKind.day => '📝',
  JournalKind.week => '📊',
  JournalKind.note => '💭',
};

String _kindHint(JournalKind k) => switch (k) {
  JournalKind.day => '3 дела и настроение перед сном',
  JournalKind.week => 'Что получилось, что нет, что меняю',
  JournalKind.note => 'Любая мысль или идея',
};

String moodEmoji(int mood) => mood <= 3
    ? '😞'
    : mood <= 5
    ? '😕'
    : mood <= 7
    ? '🙂'
    : '😄';

/// Цвет настроения: от красного к зелёному.
Color moodColor(int mood) => Color.lerp(const Color(0xFFEF4444), const Color(0xFF22C55E), (mood - 1) / 9)!;

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
      floatingActionButton: FloatingActionButton(heroTag: null, onPressed: () => _create(context), child: const Icon(Icons.add_rounded)),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Все'),
                  showCheckmark: false,
                  selected: _filter == null,
                  onSelected: (_) => setState(() => _filter = null),
                ),
                for (final k in JournalKind.values) ...[
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text('${journalKindEmoji(k)} ${journalKindLabel(k)}'),
                    showCheckmark: false,
                    selected: _filter == k,
                    onSelected: (_) => setState(() => _filter = k),
                  ),
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
                  return const EmptyHint(
                    'Итог дня: 3 дела и настроение перед сном. Через месяц это доказательство, что ты движешься.',
                    icon: Icons.auto_stories_rounded,
                  );
                }
                return ListView(
                  padding: const EdgeInsets.only(bottom: 96),
                  children: [
                    for (final e in entries)
                      _EntryCard(
                        entry: e,
                        preview: _preview(e.body),
                        onTap: () => openJournalEditor(context, kind: e.kind, day: e.day, existing: e),
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
            for (final k in JournalKind.values)
              ListTile(
                leading: EmojiAvatar(journalKindEmoji(k), size: 40, color: Accent.journal),
                title: Text(journalKindLabel(k)),
                subtitle: Text(_kindHint(k)),
                onTap: () => Navigator.pop(context, k),
              ),
            const SizedBox(height: 8),
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

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry, required this.preview, required this.onTap});
  final JournalEntry entry;
  final String preview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final e = entry;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final date = e.kind == JournalKind.week ? 'неделя с ${formatDay(e.day)}' : dayLabel(e.day);
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  EmojiAvatar(journalKindEmoji(e.kind), size: 40, color: Accent.journal),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(journalKindLabel(e.kind), style: theme.textTheme.titleSmall),
                        Text(date, style: theme.textTheme.bodySmall?.copyWith(color: muted)),
                      ],
                    ),
                  ),
                  if (e.mood != null) Pill('${moodEmoji(e.mood!)} ${e.mood}', color: moodColor(e.mood!)),
                ],
              ),
              if (preview.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(preview, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(height: 1.4)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Настроение от 1 до 10 одной строкой.
class MoodPicker extends StatelessWidget {
  const MoodPicker({super.key, required this.value, required this.onChanged});
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (var i = 1; i <= 10; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: GestureDetector(
                onTap: () => onChanged(value == i ? null : i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: value == i ? moodColor(i) : moodColor(i).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$i',
                    style: TextStyle(fontWeight: FontWeight.w700, color: value == i ? Colors.white : scheme.onSurface),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
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
              icon: const Icon(Icons.delete_outline_rounded),
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
            Text(
              _mood == null ? 'Настроение' : 'Настроение ${moodEmoji(_mood!)} $_mood из 10',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 10),
            MoodPicker(value: _mood, onChanged: (m) => setState(() => _mood = m)),
            const SizedBox(height: 20),
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
