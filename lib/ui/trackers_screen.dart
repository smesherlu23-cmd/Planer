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
              icon: const Icon(Icons.inventory_2_outlined),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackersScreen(archived: true))),
            ),
        ],
      ),
      floatingActionButton: archived
          ? null
          : FloatingActionButton(
              heroTag: null,
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackerEditScreen())),
              child: const Icon(Icons.add),
            ),
      body: Watch(
        streams: () => [db.watchTrackers(archived: archived), db.watchAllEntries()],
        builder: (context, v) {
          final trackers = v[0] as List<Tracker>;
          final entries = v[1] as List<TrackerEntry>;
          if (trackers.isEmpty) {
            return EmptyHint(
              archived
                  ? 'В архиве пусто.'
                  : 'Трекер хранит любую величину с историей: вес, время кода, настроение, уровень Faceit. Нажми +, чтобы добавить.',
            );
          }
          return ListView(
            padding: const EdgeInsets.only(top: 8, bottom: 88),
            children: [
              for (final t in trackers)
                Card(
                  child: ListTile(
                    leading: EmojiAvatar(t.icon),
                    title: Text(t.name),
                    subtitle: Text(_lastLabel(t, entries)),
                    trailing: archived ? null : IconButton(icon: const Icon(Icons.add), onPressed: () => showEntryDialog(context, t)),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TrackerDetailScreen(trackerId: t.id))),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _lastLabel(Tracker t, List<TrackerEntry> entries) {
    final series = dailySeries(t, entries);
    if (series.isEmpty) return '${trackerKindLabel(t.kind)} · пока нет записей';
    final last = series.last;
    return '${formatTrackerValue(t, last.$2)} · ${dayLabel(last.$1)}';
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
    return Card(
      child: ListTile(
        leading: EmojiAvatar(tracker.icon),
        title: Text(tracker.name),
        subtitle: started != null
            ? _Elapsed(since: DateTime.fromMillisecondsSinceEpoch(started), prefix: 'Идёт таймер: ')
            : Text(value == null ? 'не записано' : formatTrackerValue(tracker, value!)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isDuration)
              IconButton.filledTonal(
                tooltip: started == null ? 'Запустить таймер' : 'Остановить и записать',
                icon: Icon(started == null ? Icons.play_arrow : Icons.stop),
                onPressed: () => started == null ? startTimer(context, tracker) : stopTimer(context, tracker, started),
              ),
            if (value != null && started == null) const Icon(Icons.check_circle, color: Colors.green),
          ],
        ),
        onTap: () => showEntryDialog(context, tracker, day: today),
        onLongPress: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TrackerDetailScreen(trackerId: tracker.id))),
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
      style: TextStyle(color: Theme.of(context).colorScheme.primary, fontFeatures: const []),
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
        return Scaffold(
          appBar: AppBar(
            title: Text('${t.icon} ${t.name}'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Изменить',
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TrackerEditScreen(tracker: t))),
              ),
            ],
          ),
          floatingActionButton: t.archived
              ? null
              : FloatingActionButton(heroTag: null, onPressed: () => showEntryDialog(context, t), child: const Icon(Icons.add)),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 88),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  [
                    trackerKindLabel(t.kind),
                    if (t.daysMask != 0) 'на «Сегодня»: ${maskLabel(t.daysMask)}',
                    if (t.reminderMinutes != null) 'напоминание в ${formatMinutes(t.reminderMinutes!)}',
                  ].join(' · '),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Text('За 30 дней: ${summary30.label}', style: Theme.of(context).textTheme.titleSmall),
              ),
              if (t.kind != TrackerKind.yesNo)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                  child: LineChart(points: chartPoints, target: goal != null && t.kind != TrackerKind.duration ? goal.targetValue : null),
                ),
              const SectionTitle('Записи'),
              if (entries.isEmpty) const EmptyHint('Пока нет записей'),
              for (final e in entries)
                ListTile(
                  title: Text(formatTrackerValue(t, e.value)),
                  subtitle: Text([dayLabel(e.day), if (e.note != null) e.note!].join(' · ')),
                  onTap: () => showEntryDialog(context, t, existing: e),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      if (await confirm(context, 'Удалить запись?', ok: 'Удалить', danger: true)) {
                        await db.deleteById(db.trackerEntries, e.id);
                      }
                    },
                  ),
                ),
            ],
          ),
        );
      },
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
