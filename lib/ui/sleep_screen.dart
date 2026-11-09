import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import '../data/database.dart';
import '../data/dates.dart';
import '../data/queries.dart';
import '../logic/minimum.dart';
import '../logic/sleep.dart';
import 'charts.dart';
import 'common.dart';
import 'icons.dart';
import 'theme.dart';

const _qualityColors = [Color(0xFFEF4444), Color(0xFFF97316), Color(0xFFF59E0B), Color(0xFF84CC16), Color(0xFF22C55E)];
const _qualityIcons = [
  Icons.sentiment_very_dissatisfied_rounded,
  Icons.sentiment_dissatisfied_rounded,
  Icons.sentiment_neutral_rounded,
  Icons.sentiment_satisfied_rounded,
  Icons.sentiment_very_satisfied_rounded,
];
const _qualityLabels = ['Разбитый', 'Не выспался', 'Нормально', 'Хорошо', 'Отлично'];

/// Момент «лёг спать», если сон сейчас идёт.
DateTime? sleepStartedAt(Map<String, String> settings) {
  final ms = int.tryParse(settings[SleepGoals.keyStarted] ?? '');
  return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
}

Future<void> startSleep(BuildContext context) => context.db.setSetting(SleepGoals.keyStarted, '${DateTime.now().millisecondsSinceEpoch}');

/// «Я проснулся»: открыть запись ночи с временем отбоя из таймера.
Future<void> finishSleep(BuildContext context, DateTime started) =>
    showSleepSheet(context, bedAt: started, wakeAt: DateTime.now(), fromTimer: true);

class SleepScreen extends StatelessWidget {
  const SleepScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    final today = todayKey();
    return Watch(
      streams: () => [db.watchSleep(from: addDays(today, -90)), db.watchAllSettings()],
      builder: (context, v) {
        final logs = v[0] as List<SleepLog>;
        final settings = v[1] as Map<String, String>;
        final goals = SleepGoals.from(settings);
        final week = sleepStats(logs, goals, from: addDays(today, -6), to: today, today: today);
        final byDay = {for (final l in logs) l.day: l};
        final muted = Theme.of(context).colorScheme.onSurfaceVariant;
        return Scaffold(
          appBar: AppBar(title: const Text('Сон')),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              _SleepHero(lastNight: byDay[today], started: sleepStartedAt(settings), goals: goals),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('За 7 дней', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: muted)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _Stat(label: 'Средний сон', value: week.avgDuration == null ? '—' : formatDuration(week.avgDuration!)),
                          _Stat(label: 'Отбой', value: week.avgBed == null ? '—' : formatMinutes(week.avgBed!)),
                          _Stat(label: 'Вовремя', value: week.nights == 0 ? '—' : '${week.onTime} из ${week.nights}'),
                        ],
                      ),
                      if (week.streak > 0 || week.debt > 0 || week.nights > 0) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (week.nights > 0) Pill('выспался: ${week.full} из ${week.nights}', color: Accent.sleep),
                            if (goals.minimum != null && week.minimum > 0) Pill('минимум: ${week.minimum}', color: Accent.reminders),
                            if (week.streak > 0)
                              Pill(
                                '${week.streak} ${_nights(week.streak)} подряд вовремя',
                                icon: Icons.local_fire_department_rounded,
                                color: Accent.workouts,
                              ),
                            if (week.debt > 0) Pill('недосып ${formatDuration(week.debt)}', icon: Icons.battery_3_bar_rounded),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SectionTitle('Последние 2 недели'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 10),
                  child: BarChart(
                    bars: [
                      for (var i = 13; i >= 0; i--)
                        (
                          weekdayShort[dayFromKey(addDays(today, -i)).weekday - 1].substring(0, 1),
                          byDay[addDays(today, -i)] == null ? null : sleepMinutes(byDay[addDays(today, -i)]!) / 60,
                        ),
                    ],
                    target: goals.duration / 60,
                    minimum: goals.minimum == null ? null : goals.minimum! / 60,
                    color: Accent.sleep.withValues(alpha: 0.3),
                    minColor: Accent.sleep.withValues(alpha: 0.6),
                    goodColor: Accent.sleep,
                  ),
                ),
              ),
              const SectionTitle('Цели'),
              _GoalsCard(goals: goals),
              const SectionTitle('Ночи'),
              if (logs.isEmpty)
                const Card(
                  child: EmptyHint(
                    'Нажми «Ложусь спать» перед сном и «Я проснулся» утром. Или запиши ночь вручную.',
                    icon: Icons.bedtime_rounded,
                  ),
                ),
              if (logs.isNotEmpty)
                GroupCard(
                  children: [for (final l in logs.take(30)) _NightTile(log: l, goals: goals)],
                ),
            ],
          ),
        );
      },
    );
  }
}

String _nights(int n) {
  final mod10 = n % 10, mod100 = n % 100;
  if (mod10 == 1 && mod100 != 11) return 'ночь';
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) return 'ночи';
  return 'ночей';
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: theme.textTheme.titleLarge),
            ),
            Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

List<Color> _nightGradient(BuildContext context) => Theme.of(context).brightness == Brightness.dark
    ? const [Color(0xFF312E81), Color(0xFF4C1D95)]
    : const [Color(0xFF4338CA), Color(0xFF6D28D9)];

class _SleepHero extends StatelessWidget {
  const _SleepHero({required this.lastNight, required this.started, required this.goals});
  final SleepLog? lastNight;
  final DateTime? started;
  final SleepGoals goals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final big = theme.textTheme.headlineMedium?.copyWith(color: Colors.white);
    const sub = TextStyle(color: Colors.white70, fontWeight: FontWeight.w500);
    final s = started;
    final l = lastNight;
    return HeroCard(
      colors: _nightGradient(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (s != null) ...[
            Text('Спишь с ${formatMinutes(minutesOfDay(s))}', style: sub),
            const SizedBox(height: 4),
            Every(const Duration(seconds: 30), builder: (_) => Text(formatDuration(DateTime.now().difference(s).inMinutes), style: big)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF4338CA)),
                    onPressed: () => finishSleep(context, s),
                    icon: const Icon(Icons.wb_sunny_rounded),
                    label: const Text('Я проснулся'),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.white70),
                  onPressed: () => context.db.setSetting(SleepGoals.keyStarted, null),
                  child: const Text('Отменить'),
                ),
              ],
            ),
          ] else ...[
            Text(l?.quality == null ? 'Прошлая ночь' : 'Прошлая ночь · ${_qualityLabels[l!.quality! - 1].toLowerCase()}', style: sub),
            const SizedBox(height: 4),
            Text(l == null ? 'Не записана' : formatDuration(sleepMinutes(l)), style: big),
            const SizedBox(height: 2),
            Text(
              l == null
                  ? 'Цель: отбой в ${formatMinutes(goals.bed)}, подъём в ${formatMinutes(goals.wake)}'
                  : '${formatMinutes(minutesOfDay(l.bedAt))} → ${formatMinutes(minutesOfDay(l.wakeAt))}',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF4338CA)),
                    onPressed: () => startSleep(context),
                    icon: const Icon(Icons.bedtime_rounded),
                    label: const Text('Ложусь спать'),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    minimumSize: const Size(64, 52),
                  ),
                  onPressed: () => showSleepSheet(context, existing: l, goals: goals),
                  child: Text(l == null ? 'Записать' : 'Изменить'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _GoalsCard extends StatelessWidget {
  const _GoalsCard({required this.goals});
  final SleepGoals goals;

  Future<int?> _time(BuildContext context, int minutes) async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
    );
    return t == null ? null : t.hour * 60 + t.minute;
  }

  Future<int?> _choose(BuildContext context, String title, List<int> options, int current, String Function(int) label) {
    return showModalBottomSheet<int>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final o in options)
                    ChoiceChip(
                      showCheckmark: false,
                      label: Text(label(o)),
                      selected: o == current,
                      onSelected: (_) => Navigator.pop(context, o),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    final remind = goals.remindBefore;
    return GroupCard(
      children: [
        ListTile(
          leading: const ColorIcon(Icons.bedtime_rounded, color: Accent.sleep, size: 40),
          title: const Text('Отбой'),
          trailing: _TimeText(formatMinutes(goals.bed)),
          onTap: () async {
            final m = await _time(context, goals.bed);
            if (m != null) await db.setSetting(SleepGoals.keyBed, '$m');
          },
        ),
        ListTile(
          leading: const ColorIcon(Icons.wb_sunny_rounded, color: Accent.money, size: 40),
          title: const Text('Подъём'),
          trailing: _TimeText(formatMinutes(goals.wake)),
          onTap: () async {
            final m = await _time(context, goals.wake);
            if (m != null) await db.setSetting(SleepGoals.keyWake, '$m');
          },
        ),
        ListTile(
          leading: const ColorIcon(Icons.hourglass_bottom_rounded, color: Accent.trackers, size: 40),
          title: const Text('Сколько спать'),
          trailing: _TimeText(formatDuration(goals.duration)),
          onTap: () async {
            final m = await _choose(context, 'Сколько спать', [for (var h = 12; h <= 20; h++) h * 30], goals.duration, formatDuration);
            if (m != null) await db.setSetting(SleepGoals.keyDuration, '$m');
          },
        ),
        ListTile(
          leading: const ColorIcon(Icons.contrast_rounded, color: Accent.reminders, size: 40),
          title: const Text('Минимум сна'),
          subtitle: const Text('Меньше него ночь считается короткой'),
          trailing: _TimeText(goals.minimum == null ? 'нет' : formatDuration(goals.minimum!)),
          onTap: () async {
            final options = [for (var h = 8; h * 30 < goals.duration; h++) h * 30];
            final m = await _choose(
              context,
              'Минимум сна',
              [0, ...options],
              goals.minimum ?? 0,
              (v) => v == 0 ? 'Без минимума' : formatDuration(v),
            );
            if (m != null) await db.setSetting(SleepGoals.keyMinimum, m == 0 ? null : '$m');
          },
        ),
        SwitchListTile(
          secondary: const ColorIcon(Icons.notifications_active_rounded, color: Accent.reminders, size: 40),
          title: const Text('Напомнить перед отбоем'),
          subtitle: Text(
            remind == null ? 'Выключено' : 'За ${formatDuration(remind)} до отбоя, в ${formatMinutes((goals.bed - remind) % 1440)}',
          ),
          value: remind != null,
          onChanged: (on) async {
            if (!on) return db.setSetting(SleepGoals.keyRemind, null);
            if (!context.mounted) return;
            final m = await _choose(context, 'За сколько напомнить', const [15, 30, 45, 60, 90], 30, formatDuration);
            if (m != null) await db.setSetting(SleepGoals.keyRemind, '$m');
          },
        ),
        SwitchListTile(
          secondary: const ColorIcon(Icons.wb_twilight_rounded, color: Accent.journal, size: 40),
          title: const Text('Показывать на «Сегодня»'),
          value: goals.onToday,
          onChanged: (on) => db.setSetting(SleepGoals.keyOn, on ? '1' : null),
        ),
      ],
    );
  }
}

class _TimeText extends StatelessWidget {
  const _TimeText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, fontFeatures: [FontFeature.tabularFigures()]),
  );
}

class _NightTile extends StatelessWidget {
  const _NightTile({required this.log, required this.goals});
  final SleepLog log;
  final SleepGoals goals;

  @override
  Widget build(BuildContext context) {
    final l = log;
    final level = sleepLevel(l, goals);
    final onTime = wentToBedOnTime(l, goals.bed);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return ListTile(
      leading: SizedBox(
        width: 40,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${dayFromKey(l.day).day}', style: Theme.of(context).textTheme.titleMedium?.copyWith(height: 1.1)),
            Text(weekdayShort[dayFromKey(l.day).weekday - 1], style: TextStyle(fontSize: 11, color: muted)),
          ],
        ),
      ),
      title: Text(
        formatDuration(sleepMinutes(l)),
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: switch (level) {
            Level.full => null,
            Level.minimum => Accent.reminders,
            Level.below => Theme.of(context).colorScheme.error,
          },
        ),
      ),
      subtitle: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: formatMinutes(minutesOfDay(l.bedAt)),
              style: TextStyle(color: onTime ? null : Theme.of(context).colorScheme.error),
            ),
            TextSpan(text: ' → ${formatMinutes(minutesOfDay(l.wakeAt))}'),
            if (l.note != null) TextSpan(text: ' · ${l.note}'),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: l.quality == null ? null : Icon(_qualityIcons[l.quality! - 1], color: _qualityColors[l.quality! - 1]),
      onTap: () => showSleepSheet(context, existing: l, goals: goals),
    );
  }
}

// ---------------------------------------------------------------------------
// Запись ночи
// ---------------------------------------------------------------------------

Future<void> showSleepSheet(
  BuildContext context, {
  SleepLog? existing,
  DateTime? bedAt,
  DateTime? wakeAt,
  SleepGoals? goals,
  bool fromTimer = false,
}) async {
  final g = goals ?? SleepGoals.from(await context.db.watchAllSettings().first);
  if (!context.mounted) return;
  return showFormSheet(context, (_) => _SleepForm(existing: existing, bedAt: bedAt, wakeAt: wakeAt, goals: g, fromTimer: fromTimer));
}

class _SleepForm extends StatefulWidget {
  const _SleepForm({this.existing, this.bedAt, this.wakeAt, required this.goals, required this.fromTimer});
  final SleepLog? existing;
  final DateTime? bedAt;
  final DateTime? wakeAt;
  final SleepGoals goals;
  final bool fromTimer;

  @override
  State<_SleepForm> createState() => _SleepFormState();
}

class _SleepFormState extends State<_SleepForm> {
  late final DateTime? _wakeAt = widget.existing?.wakeAt ?? widget.wakeAt;
  late final DateTime? _bedAt = widget.existing?.bedAt ?? widget.bedAt;
  late int _day = widget.existing?.day ?? (_wakeAt == null ? todayKey() : dayKey(_wakeAt));
  late int _bed = _bedAt == null ? widget.goals.bed : minutesOfDay(_bedAt);
  late int _wake = _wakeAt == null ? widget.goals.wake : minutesOfDay(_wakeAt);
  late int? _quality = widget.existing?.quality;
  late final _note = TextEditingController(text: widget.existing?.note ?? '');

  int get _minutes {
    final t = sleepTimes(wakeDay: _day, bedMinutes: _bed, wakeMinutes: _wake);
    return t.wakeAt.difference(t.bedAt).inMinutes;
  }

  Future<void> _pick(bool bed) async {
    final m = bed ? _bed : _wake;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: m ~/ 60, minute: m % 60),
    );
    if (t == null) return;
    setState(() => bed ? _bed = t.hour * 60 + t.minute : _wake = t.hour * 60 + t.minute);
  }

  Future<void> _save() async {
    if (_minutes <= 0 || _minutes > 20 * 60) return showSnack(context, 'Проверь время: сон должен быть от минуты до 20 часов');
    final db = context.db;
    final t = sleepTimes(wakeDay: _day, bedMinutes: _bed, wakeMinutes: _wake);
    await db.saveSleep(
      SleepLogsCompanion(
        id: widget.existing == null ? const Value.absent() : Value(widget.existing!.id),
        day: Value(_day),
        bedAt: Value(t.bedAt),
        wakeAt: Value(t.wakeAt),
        quality: Value(_quality),
        note: Value(emptyToNull(_note.text)),
      ),
    );
    if (widget.fromTimer) await db.setSetting(SleepGoals.keyStarted, null);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.existing == null ? 'Как спал?' : 'Ночь', style: theme.textTheme.titleLarge),
        DayTile(title: 'Проснулся', day: _day, onChanged: (d) => setState(() => _day = d ?? _day)),
        Row(
          children: [
            Expanded(
              child: _TimeBox(icon: Icons.bedtime_rounded, label: 'Лёг', minutes: _bed, color: Accent.sleep, onTap: () => _pick(true)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TimeBox(icon: Icons.wb_sunny_rounded, label: 'Встал', minutes: _wake, color: Accent.money, onTap: () => _pick(false)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          _minutes > 0 ? 'Сон: ${formatDuration(_minutes)}' : 'Проверь время',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(color: _minutes > 0 ? null : theme.colorScheme.error),
        ),
        const SizedBox(height: 16),
        Text('Как выспался', style: theme.textTheme.titleSmall?.copyWith(color: muted)),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var q = 1; q <= 5; q++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => setState(() => _quality = _quality == q ? null : q),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _quality == q ? _qualityColors[q - 1].withValues(alpha: 0.18) : theme.colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _quality == q ? _qualityColors[q - 1] : Colors.transparent, width: 1.5),
                      ),
                      child: Icon(_qualityIcons[q - 1], color: _qualityColors[q - 1], size: 28),
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (_quality != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _qualityLabels[_quality! - 1],
              textAlign: TextAlign.center,
              style: TextStyle(color: muted),
            ),
          ),
        const SizedBox(height: 12),
        TextField(
          controller: _note,
          decoration: const InputDecoration(labelText: 'Заметка (необязательно)'),
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: _save, child: const Text('Сохранить')),
        if (widget.existing != null)
          TextButton(
            style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
            onPressed: () async {
              await context.db.deleteById(context.db.sleepLogs, widget.existing!.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Удалить'),
          ),
      ],
    );
  }
}

class _TimeBox extends StatelessWidget {
  const _TimeBox({required this.icon, required this.label, required this.minutes, required this.color, required this.onTap});
  final IconData icon;
  final String label;
  final int minutes;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  Text(
                    formatMinutes(minutes),
                    style: theme.textTheme.titleLarge?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Карточка на «Сегодня»
// ---------------------------------------------------------------------------

class SleepTodayCard extends StatelessWidget {
  const SleepTodayCard({super.key, required this.today, required this.lastNight, required this.settings});
  final int today;
  final SleepLog? lastNight;
  final Map<String, String> settings;

  @override
  Widget build(BuildContext context) {
    final goals = SleepGoals.from(settings);
    final started = sleepStartedAt(settings);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final l = lastNight;
    void open() => Navigator.push(context, MaterialPageRoute(builder: (_) => const SleepScreen()));

    Widget card({required String title, required Widget subtitle, Widget? trailing, Widget? action}) => Card(
      child: InkWell(
        onTap: open,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Column(
            children: [
              Row(
                children: [
                  const ColorIcon(Icons.bedtime_rounded, color: Accent.sleep),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 2),
                        subtitle,
                      ],
                    ),
                  ),
                  ?trailing,
                ],
              ),
              if (action != null) ...[const SizedBox(height: 12), action],
            ],
          ),
        ),
      ),
    );

    if (started != null) {
      return card(
        title: 'Спишь с ${formatMinutes(minutesOfDay(started))}',
        subtitle: Every(
          const Duration(seconds: 30),
          builder: (_) => Text(
            formatDuration(DateTime.now().difference(started).inMinutes),
            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600, color: Accent.sleep),
          ),
        ),
        action: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Accent.sleep, foregroundColor: Colors.white),
            onPressed: () => finishSleep(context, started),
            icon: const Icon(Icons.wb_sunny_rounded),
            label: const Text('Я проснулся'),
          ),
        ),
      );
    }
    final hour = DateTime.now().hour;
    if (l == null && hour < 16) {
      return card(
        title: 'Как спал?',
        subtitle: Text('Запиши, когда лёг и встал', style: TextStyle(color: muted)),
        trailing: IconButton.filled(
          style: IconButton.styleFrom(backgroundColor: Accent.sleep, foregroundColor: Colors.white),
          tooltip: 'Записать сон',
          onPressed: () => showSleepSheet(context, goals: goals),
          icon: const Icon(Icons.add_rounded),
        ),
      );
    }
    if (hour >= 18 || l == null) {
      return card(
        title: 'Отбой в ${formatMinutes(goals.bed)}',
        subtitle: Every(
          const Duration(minutes: 1),
          builder: (_) {
            final left = minutesUntilBed(DateTime.now(), goals.bed);
            return Text(
              left > 0 ? 'Через ${formatDuration(left)}' : 'Уже пора спать',
              style: TextStyle(color: left > 0 ? muted : theme.colorScheme.error, fontWeight: left > 0 ? null : FontWeight.w600),
            );
          },
        ),
        trailing: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Accent.sleep,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: 14),
          ),
          onPressed: () => startSleep(context),
          icon: const Icon(Icons.bedtime_rounded, size: 18),
          label: const Text('Ложусь'),
        ),
      );
    }
    return card(
      title: 'Сон ${formatDuration(sleepMinutes(l))}',
      subtitle: Text(
        '${formatMinutes(minutesOfDay(l.bedAt))} → ${formatMinutes(minutesOfDay(l.wakeAt))}'
        '${wentToBedOnTime(l, goals.bed) ? ' · вовремя' : ''}',
        style: TextStyle(color: muted),
      ),
      trailing: const CheckDot(checked: true, color: Accent.habits, size: 28),
    );
  }
}
