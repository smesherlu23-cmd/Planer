import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import '../data/database.dart';
import '../data/dates.dart';
import '../data/queries.dart';
import '../logic/calc.dart';
import '../logic/values.dart';
import 'charts.dart';
import 'common.dart';
import 'theme.dart';

class TrackersScreen extends StatelessWidget {
  const TrackersScreen({super.key, this.archived = false});
  final bool archived;

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    return Scaffold(
      appBar: AppBar(
        title: Text(archived ? 'Трекеры в архиве' : 'Трекеры'),
        actions: [
          if (!archived)
            IconButton(
              tooltip: 'Архив',
              icon: const Icon(Icons.inventory_2_rounded),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackersScreen(archived: true))),
            ),
        ],
      ),
      floatingActionButton: archived
          ? null
          : FloatingActionButton(
              heroTag: null,
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackerEditScreen())),
              child: const Icon(Icons.add_rounded),
            ),
      body: Watch(
        streams: () => [db.watchTrackers(archived: archived), db.watchAllEntries()],
        builder: (context, v) {
          final trackers = v[0] as List<Tracker>;
          final entries = v[1] as List<TrackerEntry>;
          if (trackers.isEmpty) {
            return EmptyHint(
              icon: Icons.show_chart_rounded,
              archived
                  ? 'В архиве пусто.'
                  : 'Трекер хранит любую величину с историей: вес, время кода, настроение, уровень Faceit. Нажми +, чтобы добавить.',
            );
          }
          return ListView(
            padding: const EdgeInsets.only(top: 4, bottom: 96),
            children: [for (final t in trackers) _TrackerCard(tracker: t, entries: entries, archived: archived)],
          );
        },
      ),
    );
  }
}

class _TrackerCard extends StatelessWidget {
  const _TrackerCard({required this.tracker, required this.entries, required this.archived});
  final Tracker tracker;
  final List<TrackerEntry> entries;
  final bool archived;

  @override
  Widget build(BuildContext context) {
    final t = tracker;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final series = dailySeries(t, entries);
    final last = series.lastOrNull;
    final spark = series.length > 14 ? series.sublist(series.length - 14) : series;
    return Card(
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TrackerDetailScreen(trackerId: t.id))),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(
            children: [
              EmojiAvatar(t.icon, color: Accent.trackers),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    if (last == null)
                      Text('${trackerKindLabel(t.kind)} · пока нет записей', style: TextStyle(color: muted))
                    else
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: formatTrackerValue(t, last.$2),
                              style: const TextStyle(fontWeight: FontWeight.w700, color: Accent.trackers),
                            ),
                            TextSpan(
                              text: '  ${dayLabel(last.$1)}',
                              style: TextStyle(color: muted),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (t.kind != TrackerKind.yesNo && spark.length >= 2) ...[
                Sparkline(values: [for (final p in spark) p.$2], color: Accent.trackers),
                const SizedBox(width: 6),
              ],
              if (!archived)
                IconButton(tooltip: 'Записать', icon: const Icon(Icons.add_rounded), onPressed: () => showEntryDialog(context, t)),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Строка трекера на экране «Сегодня» с таймером
// ---------------------------------------------------------------------------

String timerKey(int trackerId) => 'timer_$trackerId';

class TrackerTodayTile extends StatelessWidget {
  const TrackerTodayTile({super.key, required this.tracker, required this.value, required this.today, required this.settings});
  final Tracker tracker;
  final double? value;
  final int today;
  final Map<String, String> settings;

  @override
  Widget build(BuildContext context) {
    final started = int.tryParse(settings[timerKey(tracker.id)] ?? '');
    final isDuration = tracker.kind == TrackerKind.duration;
    final theme = Theme.of(context);
    final running = started != null;
    return Card(
      child: InkWell(
        onTap: () => showEntryDialog(context, tracker, day: today),
        onLongPress: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TrackerDetailScreen(trackerId: tracker.id))),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            children: [
              EmojiAvatar(tracker.icon, color: Accent.trackers),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tracker.name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    if (running)
                      _Elapsed(since: DateTime.fromMillisecondsSinceEpoch(started), prefix: 'Таймер идёт · ')
                    else
                      Text(
                        value == null ? 'Нажми, чтобы записать' : formatTrackerValue(tracker, value!),
                        style: value == null
                            ? TextStyle(color: theme.colorScheme.onSurfaceVariant)
                            : theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, color: Accent.trackers),
                      ),
                  ],
                ),
              ),
              if (isDuration)
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: running ? theme.colorScheme.error : Accent.trackers,
                    foregroundColor: Colors.white,
                  ),
                  tooltip: running ? 'Остановить и записать' : 'Запустить таймер',
                  icon: Icon(running ? Icons.stop_rounded : Icons.play_arrow_rounded),
                  onPressed: () => running ? stopTimer(context, tracker, started) : startTimer(context, tracker),
                ),
              if (!isDuration || value != null) ...[
                const SizedBox(width: 6),
                CheckDot(checked: value != null && !running, color: Accent.habits),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> startTimer(BuildContext context, Tracker t) =>
    context.db.setSetting(timerKey(t.id), '${DateTime.now().millisecondsSinceEpoch}');

Future<void> stopTimer(BuildContext context, Tracker t, int startedMs) async {
  final db = context.db;
  final started = DateTime.fromMillisecondsSinceEpoch(startedMs);
  final minutes = DateTime.now().difference(started).inSeconds / 60;
  await db.setSetting(timerKey(t.id), null);
  final rounded = minutes.round();
  if (rounded < 1) {
    if (context.mounted) showSnack(context, 'Меньше минуты, не записываю');
    return;
  }
  // Записываем на день, когда таймер запустили: если сидел за кодом до полуночи и позже.
  await db.addEntry(t.id, rounded.toDouble(), day: dayKey(started));
  if (context.mounted) showSnack(context, '${t.name}: записано ${formatDuration(rounded)}');
}

class _Elapsed extends StatefulWidget {
  const _Elapsed({required this.since, this.prefix = ''});
  final DateTime since;
  final String prefix;

  @override
  State<_Elapsed> createState() => _ElapsedState();
}

class _ElapsedState extends State<_Elapsed> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = DateTime.now().difference(widget.since);
    String two(int v) => v.toString().padLeft(2, '0');
    final text = '${d.inHours}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
    return Text(
      '${widget.prefix}$text',
      style: TextStyle(
        color: Theme.of(context).colorScheme.error,
        fontWeight: FontWeight.w600,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ввод значения
// ---------------------------------------------------------------------------

Future<void> showEntryDialog(BuildContext context, Tracker t, {int? day, TrackerEntry? existing}) {
  return showFormSheet(context, (_) => _EntryForm(tracker: t, day: existing?.day ?? day ?? todayKey(), existing: existing));
}

class _EntryForm extends StatefulWidget {
  const _EntryForm({required this.tracker, required this.day, this.existing});
  final Tracker tracker;
  final int day;
  final TrackerEntry? existing;

  @override
  State<_EntryForm> createState() => _EntryFormState();
}

class _EntryFormState extends State<_EntryForm> {
  late int _day = widget.day;
  late final _value = TextEditingController(text: widget.existing == null ? '' : formatNumber(widget.existing!.value, maxDecimals: 2));
  late final _note = TextEditingController(text: widget.existing?.note ?? '');
  late int? _scale = widget.existing?.value.round();
  late bool? _yes = widget.existing == null ? null : widget.existing!.value > 0;

  Tracker get t => widget.tracker;

  Future<void> _save(double value) async {
    final db = context.db;
    final note = emptyToNull(_note.text);
    if (widget.existing != null) {
      await db.updateEntry(widget.existing!.id, value: value, day: _day, note: note);
    } else {
      await db.addEntry(t.id, value, day: _day, note: note);
    }
    if (mounted) Navigator.pop(context);
  }

  void _saveTyped() {
    final v = parseNumber(_value.text);
    if (v == null) {
      showSnack(context, 'Введи число');
      return;
    }
    _save(v);
  }

  @override
  Widget build(BuildContext context) {
    Widget input;
    switch (t.kind) {
      case TrackerKind.number:
        input = NumberField(controller: _value, label: 'Значение', suffix: t.unit, autofocus: true, allowNegative: true);
      case TrackerKind.duration:
        input = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NumberField(controller: _value, label: 'Сколько минут', suffix: 'мин', autofocus: true),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final m in [15, 30, 45, 60, 90, 120]) ActionChip(label: Text(formatDuration(m)), onPressed: () => _value.text = '$m'),
              ],
            ),
          ],
        );
      case TrackerKind.scale10:
        input = Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var i = 1; i <= 10; i++)
              ChoiceChip(label: Text('$i'), selected: _scale == i, onSelected: (_) => setState(() => _scale = i)),
          ],
        );
      case TrackerKind.yesNo:
        input = Row(
          children: [
            Expanded(
              child: ChoiceChip(label: const Text('Да'), selected: _yes == true, onSelected: (_) => setState(() => _yes = true)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ChoiceChip(label: const Text('Нет'), selected: _yes == false, onSelected: (_) => setState(() => _yes = false)),
            ),
          ],
        );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('${t.icon} ${t.name}', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        input,
        DayTile(day: _day, onChanged: (d) => setState(() => _day = d ?? _day)),
        TextField(
          controller: _note,
          decoration: const InputDecoration(labelText: 'Заметка (необязательно)'),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () {
            switch (t.kind) {
              case TrackerKind.number:
              case TrackerKind.duration:
                _saveTyped();
              case TrackerKind.scale10:
                if (_scale == null) return showSnack(context, 'Выбери оценку');
                _save(_scale!.toDouble());
              case TrackerKind.yesNo:
                if (_yes == null) return showSnack(context, 'Выбери ответ');
                _save(_yes! ? 1 : 0);
            }
          },
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Карточка трекера
// ---------------------------------------------------------------------------

class TrackerDetailScreen extends StatelessWidget {
  const TrackerDetailScreen({super.key, required this.trackerId});
  final int trackerId;

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    return Watch(
      deps: [trackerId],
      streams: () => [
        (db.select(db.trackers)..where((t) => t.id.equals(trackerId))).watchSingleOrNull(),
        db.watchEntries(trackerId),
        db.watchGoals(),
      ],
      builder: (context, v) {
        final t = v[0] as Tracker?;
        if (t == null) return const Scaffold(body: Center(child: Text('Трекер удалён')));
        final entries = v[1] as List<TrackerEntry>;
        final goal = (v[2] as List<Goal>).where((g) => g.trackerId == t.id).firstOrNull;
        final series = dailySeries(t, entries);
        final chartPoints = series.length > 120 ? series.sublist(series.length - 120) : series;
        final from30 = addDays(todayKey(), -29);
        final summary30 = periodSummary(t, entries.where((e) => e.day >= from30));
        final theme = Theme.of(context);
        final muted = theme.colorScheme.onSurfaceVariant;
        final last = series.lastOrNull;
        return Scaffold(
          appBar: AppBar(
            title: Text(t.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_rounded),
                tooltip: 'Изменить',
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TrackerEditScreen(tracker: t))),
              ),
            ],
          ),
          floatingActionButton: t.archived
              ? null
              : FloatingActionButton.extended(
                  heroTag: null,
                  onPressed: () => showEntryDialog(context, t),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Записать'),
                ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 110),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          EmojiAvatar(t.icon, size: 56, color: Accent.trackers),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(last == null ? 'Пока нет записей' : 'Последнее: ${dayLabel(last.$1)}', style: TextStyle(color: muted)),
                                if (last != null)
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(formatTrackerValue(t, last.$2), style: theme.textTheme.headlineMedium),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          Pill(trackerKindLabel(t.kind), color: Accent.trackers),
                          if (t.daysMask != 0) Pill('на «Сегодня»: ${maskLabel(t.daysMask)}'),
                          if (t.reminderMinutes != null) Pill('⏰ ${formatMinutes(t.reminderMinutes!)}'),
                          if (goal != null) Pill('🎯 ${goal.name}', color: Accent.goals),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'За 30 дней: ',
                              style: TextStyle(color: muted),
                            ),
                            TextSpan(
                              text: summary30.label,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (t.kind != TrackerKind.yesNo)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 18, 16, 10),
                    child: LineChart(
                      points: chartPoints,
                      color: Accent.trackers,
                      target: goal != null && t.kind != TrackerKind.duration ? goal.targetValue : null,
                    ),
                  ),
                ),
              const SectionTitle('Записи'),
              if (entries.isEmpty) const Card(child: EmptyHint('Пока нет записей', icon: Icons.edit_note_rounded)),
              if (entries.isNotEmpty)
                GroupCard(
                  children: [
                    for (final e in entries)
                      ListTile(
                        leading: _DayColumn(e.day),
                        title: Text(formatTrackerValue(t, e.value), style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: e.note == null ? null : Text(e.note!),
                        onTap: () => showEntryDialog(context, t, existing: e),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded),
                          onPressed: () async {
                            if (await confirm(context, 'Удалить запись?', ok: 'Удалить', danger: true)) {
                              await db.deleteById(db.trackerEntries, e.id);
                            }
                          },
                        ),
                      ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

const _monthsShort = ['янв', 'фев', 'мар', 'апр', 'мая', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];

/// Дата столбиком для узкой колонки слева: число крупно, месяц мелко.
class _DayColumn extends StatelessWidget {
  const _DayColumn(this.day);
  final int day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final d = dayFromKey(day);
    return SizedBox(
      width: 40,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('${d.day}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, height: 1.1)),
          Text(_monthsShort[d.month - 1], style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Создание и изменение трекера
// ---------------------------------------------------------------------------

class TrackerEditScreen extends StatefulWidget {
  const TrackerEditScreen({super.key, this.tracker});
  final Tracker? tracker;

  @override
  State<TrackerEditScreen> createState() => _TrackerEditScreenState();
}

class _TrackerEditScreenState extends State<TrackerEditScreen> {
  late final _name = TextEditingController(text: widget.tracker?.name ?? '');
  late final _icon = TextEditingController(text: widget.tracker?.icon ?? '📈');
  late final _unit = TextEditingController(text: widget.tracker?.unit ?? '');
  late TrackerKind _kind = widget.tracker?.kind ?? TrackerKind.number;
  late int _mask = widget.tracker?.daysMask ?? 0;
  late int? _reminder = widget.tracker?.reminderMinutes;

  bool get _isNew => widget.tracker == null;

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return showSnack(context, 'Введи название');
    final c = TrackersCompanion(
      id: _isNew ? const Value.absent() : Value(widget.tracker!.id),
      name: Value(name),
      icon: Value(emptyToNull(_icon.text) ?? '📈'),
      unit: Value(_kind == TrackerKind.number ? emptyToNull(_unit.text) : null),
      kind: Value(_kind),
      daysMask: Value(_mask),
      reminderMinutes: Value(_mask == 0 ? null : _reminder),
    );
    await context.db.saveTracker(c);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    final t = widget.tracker;
    return Scaffold(
      appBar: AppBar(title: Text(_isNew ? 'Новый трекер' : 'Трекер')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              EmojiField(controller: _icon),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _name,
                  autofocus: _isNew,
                  decoration: const InputDecoration(labelText: 'Название'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Что записываем', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final k in TrackerKind.values)
                ChoiceChip(
                  label: Text(trackerKindLabel(k)),
                  selected: _kind == k,
                  // Тип у трекера с историей не меняем: старые записи потеряют смысл.
                  onSelected: _isNew ? (_) => setState(() => _kind = k) : null,
                ),
            ],
          ),
          if (_kind == TrackerKind.number) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _unit,
              decoration: const InputDecoration(labelText: 'Единица (кг, км, ELO...)'),
            ),
          ],
          const SizedBox(height: 20),
          Text('Показывать на «Сегодня»', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          const Text('Если не выбрать дни, трекер живёт только здесь, в «Ещё → Трекеры».'),
          const SizedBox(height: 8),
          DaysPicker(mask: _mask, onChanged: (m) => setState(() => _mask = m)),
          TextButton(onPressed: () => setState(() => _mask = 0), child: const Text('Не показывать')),
          if (_mask != 0) ReminderTile(minutes: _reminder, onChanged: (m) => setState(() => _reminder = m)),
          const SizedBox(height: 16),
          FilledButton(onPressed: _save, child: const Text('Сохранить')),
          if (t != null) ...[
            const SizedBox(height: 24),
            OutlinedButton.icon(
              icon: Icon(t.archived ? Icons.unarchive_outlined : Icons.archive_outlined),
              label: Text(t.archived ? 'Вернуть из архива' : 'В архив'),
              onPressed: () async {
                await db.setArchived(db.trackers, t.id, !t.archived);
                if (context.mounted) Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Удалить вместе с историей'),
              onPressed: () async {
                if (await confirm(
                  context,
                  'Удалить трекер?',
                  text: 'Все записи этого трекера тоже удалятся. Если хочешь просто убрать его, лучше отправь в архив.',
                  ok: 'Удалить',
                  danger: true,
                )) {
                  await db.deleteById(db.trackers, t.id);
                  if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}
