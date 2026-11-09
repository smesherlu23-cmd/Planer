import 'dart:math' as math;

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

class SleepScreen extends StatefulWidget {
  const SleepScreen({super.key});

  @override
  State<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends State<SleepScreen> {
  int _period = 7;

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    final today = todayKey();
    return Watch(
      streams: () => [db.watchSleep(from: addDays(today, -120)), db.watchAllSettings()],
      builder: (context, v) {
        final logs = v[0] as List<SleepLog>;
        final settings = v[1] as Map<String, String>;
        final goals = SleepGoals.from(settings);
        final from = addDays(today, -(_period - 1));
        final stats = sleepStats(logs, goals, from: from, to: today, today: today);
        final diary = sleepDiaryStats(logs, from: from, to: today);
        final rhythm = sleepRhythm(logs, from: addDays(today, -27), to: today);
        final impacts = factorImpacts(logs.where((l) => l.day >= addDays(today, -89)));
        final debt = sleepDebt(logs, goals, today: today);
        final byDay = {for (final l in logs) l.day: l};
        final muted = Theme.of(context).colorScheme.onSurfaceVariant;
        final chartDays = _period == 30 ? 30 : 14;
        return Scaffold(
          appBar: AppBar(title: const Text('Сон')),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              _SleepHero(lastNight: byDay[today], started: sleepStartedAt(settings), goals: goals, debt: debt),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
                child: SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 7, label: Text('7 дней')),
                    ButtonSegment(value: 14, label: Text('14 дней')),
                    ButtonSegment(value: 30, label: Text('30 дней')),
                  ],
                  selected: {_period},
                  onSelectionChanged: (s) => setState(() => _period = s.first),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _Stat(label: 'Средний сон', value: stats.avgDuration == null ? '—' : formatDuration(stats.avgDuration!)),
                          _Stat(label: 'Отбой', value: stats.avgBed == null ? '—' : formatMinutes(stats.avgBed!)),
                          _Stat(label: 'Подъём', value: stats.avgWake == null ? '—' : formatMinutes(stats.avgWake!)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _Stat(label: 'Вовремя', value: stats.nights == 0 ? '—' : '${stats.onTime} из ${stats.nights}'),
                          _Stat(label: 'Эффективность', value: diary.avgEfficiency == null ? '—' : '${diary.avgEfficiency}%'),
                          _Stat(label: 'Засыпаю за', value: diary.avgLatency == null ? '—' : formatDuration(diary.avgLatency!)),
                        ],
                      ),
                      if (stats.streak > 0 || stats.debt > 0 || stats.nights > 0) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (stats.nights > 0) Pill('выспался: ${stats.full} из ${stats.nights}', color: Accent.sleep),
                            if (goals.minimum != null && stats.minimum > 0) Pill('минимум: ${stats.minimum}', color: Accent.reminders),
                            if (stats.streak > 0)
                              Pill(
                                '${stats.streak} ${_nights(stats.streak)} подряд вовремя',
                                icon: Icons.local_fire_department_rounded,
                                color: Accent.workouts,
                              ),
                            if (stats.debt > 0) Pill('недосып ${formatDuration(stats.debt)}', icon: Icons.battery_3_bar_rounded),
                          ],
                        ),
                      ],
                      if (diary.avgEfficiency != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          diary.avgEfficiency! >= 85 ? 'Эффективность 85% и выше: в постели ты в основном спишь.' : 'Эффективность ниже 85%: много времени в постели без сна. Помогает ложиться только когда хочется спать и вставать в одно время.',
                          style: TextStyle(color: muted, fontSize: 12, height: 1.35),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SectionTitle('Длительность, $chartDays ${_nights(chartDays)}'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 10),
                  child: BarChart(
                    bars: [
                      for (var i = chartDays - 1; i >= 0; i--)
                        (
                          chartDays > 14 && i % 3 != 0 ? '' : weekdayShort[dayFromKey(addDays(today, -i)).weekday - 1].substring(0, 1),
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
              SectionTitle('Окно сна, $chartDays ${_nights(chartDays)}'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 10),
                  child: _SleepWindowChart(
                    nights: [for (var i = chartDays - 1; i >= 0; i--) (addDays(today, -i), byDay[addDays(today, -i)])],
                    goals: goals,
                  ),
                ),
              ),
              const SectionTitle('Режим'),
              _RhythmCard(rhythm: rhythm),
              const SectionTitle('Что влияет на мой сон'),
              _FactorsCard(impacts: impacts, hasTags: logs.any((l) => l.tags != null)),
              const SectionTitle('Инструменты'),
              _ToolsCard(goals: goals, latency: diary.avgLatency),
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
  const _Stat({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

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
              child: Text(value, style: theme.textTheme.titleLarge?.copyWith(color: color)),
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
  const _SleepHero({required this.lastNight, required this.started, required this.goals, this.debt = 0});
  final int debt;
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
                  : [
                      '${formatMinutes(minutesOfDay(l.bedAt))} → ${formatMinutes(minutesOfDay(l.wakeAt))}',
                      if (sleepEfficiency(l) != null) 'спал ${formatDuration(actualSleepMinutes(l))}, эффективность ${sleepEfficiency(l)}%',
                    ].join(' · '),
              style: const TextStyle(color: Colors.white),
            ),
            if (debt >= 60) ...[
              const SizedBox(height: 6),
              Text(
                'Недосып за 2 недели: ${formatDuration(debt)}. Отдавай его понемногу: ложись на 20–30 минут раньше, а не отсыпайся до обеда.',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
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
            if (sleepEfficiency(l) != null) TextSpan(text: ' · ${sleepEfficiency(l)}%'),
            if (sleepTags(l).isNotEmpty)
              TextSpan(text: ' · ${sleepTags(l).map((t) => sleepFactor(t)?.label.toLowerCase() ?? t).join(', ')}'),
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
// Окно сна: когда лёг и когда встал, полосой по каждой ночи
// ---------------------------------------------------------------------------

class _SleepWindowChart extends StatelessWidget {
  const _SleepWindowChart({required this.nights, required this.goals});
  final List<(int day, SleepLog? log)> nights;
  final SleepGoals goals;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final logs = nights.map((n) => n.$2).whereType<SleepLog>().toList();
    if (logs.isEmpty) {
      return SizedBox(
        height: 60,
        child: Center(
          child: Text('Пока нет ночей', style: TextStyle(color: scheme.onSurfaceVariant)),
        ),
      );
    }
    return SizedBox(
      height: 190,
      child: CustomPaint(
        size: Size.infinite,
        painter: _WindowPainter(
          nights: nights,
          goals: goals,
          bar: Accent.sleep,
          late: scheme.error,
          grid: scheme.outlineVariant,
          goal: scheme.onSurfaceVariant,
          label: (Theme.of(context).textTheme.labelSmall ?? const TextStyle()).copyWith(color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _WindowPainter extends CustomPainter {
  _WindowPainter({
    required this.nights,
    required this.goals,
    required this.bar,
    required this.late,
    required this.grid,
    required this.goal,
    required this.label,
  });
  final List<(int, SleepLog?)> nights;
  final SleepGoals goals;
  final Color bar;
  final Color late;
  final Color grid;
  final Color goal;
  final TextStyle label;

  /// Минуты от 18:00, чтобы ночь шла сверху вниз без разрыва в полночь.
  static int _fromEvening(int minutesOfDay) => (minutesOfDay - 18 * 60) % 1440;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 40.0, bottom = 16.0;
    final values = <int>[_fromEvening(goals.bed), _fromEvening(goals.wake)];
    for (final (_, l) in nights) {
      if (l == null) continue;
      values.add(_fromEvening(minutesOfDay(l.bedAt)));
      values.add(_fromEvening(minutesOfDay(l.bedAt)) + sleepMinutes(l));
    }
    var lo = values.reduce(math.min), hi = values.reduce(math.max);
    lo = (lo ~/ 60) * 60;
    hi = ((hi + 59) ~/ 60) * 60;
    if (hi - lo < 240) hi = lo + 240;
    final h = size.height - bottom;
    double y(num m) => (m - lo) / (hi - lo) * h;
    final gridPaint = Paint()
      ..color = grid.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    final step = (hi - lo) > 9 * 60 ? 120 : 60;
    for (var m = lo; m <= hi; m += step) {
      canvas.drawLine(Offset(left, y(m)), Offset(size.width, y(m)), gridPaint);
      final tp = TextPainter(
        text: TextSpan(text: formatMinutes((m + 18 * 60) % 1440), style: label),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y(m) - tp.height / 2));
    }
    final goalPaint = Paint()
      ..color = goal
      ..strokeWidth = 1.2;
    for (final g in [_fromEvening(goals.bed), _fromEvening(goals.wake)]) {
      final yy = y(g);
      for (var x = left; x < size.width; x += 8) {
        canvas.drawLine(Offset(x, yy), Offset(math.min(x + 4, size.width), yy), goalPaint);
      }
    }
    final n = nights.length;
    final slot = (size.width - left) / n;
    final w = math.min(14.0, slot * 0.6);
    for (var i = 0; i < n; i++) {
      final (day, l) = nights[i];
      final cx = left + slot * (i + 0.5);
      if (l != null) {
        final start = _fromEvening(minutesOfDay(l.bedAt));
        final end = start + sleepMinutes(l);
        final onTime = wentToBedOnTime(l, goals.bed);
        final rect = RRect.fromRectAndRadius(Rect.fromLTRB(cx - w / 2, y(start), cx + w / 2, y(end)), Radius.circular(w / 2));
        canvas.drawRRect(rect, Paint()..color = onTime ? bar : late.withValues(alpha: 0.8));
        final lat = l.latency ?? 0;
        if (lat > 0) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromLTRB(cx - w / 2, y(start), cx + w / 2, y(start + lat)), Radius.circular(w / 2)),
            Paint()..color = Colors.white.withValues(alpha: 0.45),
          );
        }
      }
      if (n <= 14 || i % 3 == (n - 1) % 3) {
        final tp = TextPainter(
          text: TextSpan(text: '${dayFromKey(day).day}', style: label),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(cx - tp.width / 2, size.height - tp.height));
      }
    }
  }

  @override
  bool shouldRepaint(_WindowPainter old) => old.nights != nights || old.goals != goals || old.bar != bar;
}

// ---------------------------------------------------------------------------
// Режим: регулярность, социальный джетлаг, хронотип
// ---------------------------------------------------------------------------

class _RhythmCard extends StatelessWidget {
  const _RhythmCard({required this.rhythm});
  final SleepRhythm rhythm;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final r = rhythm;
    String spreadText(int? m) => m == null ? '—' : '±${formatDuration(m)}';
    final bad = Theme.of(context).colorScheme.error;
    Color? spreadColor(int? m) => m == null ? null : (m <= 30 ? Accent.habits : (m <= 60 ? Accent.reminders : bad));
    if (r.bedSpread == null) {
      return const Card(
        child: EmptyHint('Запиши хотя бы 3 ночи, и здесь появится, насколько ровный у тебя режим.', icon: Icons.schedule_rounded),
      );
    }
    final jet = r.socialJetlag;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Stat(label: 'Разброс отбоя', value: spreadText(r.bedSpread), color: spreadColor(r.bedSpread)),
                _Stat(label: 'Разброс подъёма', value: spreadText(r.wakeSpread), color: spreadColor(r.wakeSpread)),
                _Stat(
                  label: 'Выходные vs будни',
                  value: jet == null ? '—' : formatDuration(jet),
                  color: jet == null ? null : (jet < 60 ? Accent.habits : (jet < 120 ? Accent.reminders : bad)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              [
                'Ровный режим так же важен, как длительность: чем меньше разброс, тем легче засыпать и вставать.',
                if (jet != null && jet >= 60)
                  'В выходные середина сна сдвигается на ${formatDuration(jet)}: это «социальный джетлаг», как перелёт через часовые пояса каждую неделю. Старайся вставать не позже чем на час от будней.',
                if (r.chronotype != null)
                  'Середина сна ${r.midFree != null ? 'в выходные' : ''} около ${formatMinutes((r.midFree ?? r.midWork)!)}: по типу ты ${r.chronotype}.',
              ].join(' '),
              style: TextStyle(color: muted, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Факторы
// ---------------------------------------------------------------------------

class _FactorsCard extends StatelessWidget {
  const _FactorsCard({required this.impacts, required this.hasTags});
  final List<FactorImpact> impacts;
  final bool hasTags;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (impacts.isEmpty) {
      return Card(
        child: EmptyHint(
          hasTags
              ? 'Отмечай, что было вечером, ещё несколько ночей. Когда наберётся хотя бы по 3 ночи с фактором и без него, здесь появится, как он влияет на твой сон.'
              : 'В записи ночи отмечай, что было вечером: кофе, экран в кровати, тренировка, стресс. Через пару недель станет видно, что именно мешает спать.',
          icon: Icons.science_outlined,
        ),
      );
    }
    return GroupCard(
      children: [
        for (final i in impacts.take(6))
          ListTile(
            leading: Icon(_factorIcons[i.factor.key] ?? Icons.label_outline_rounded, color: Accent.sleep),
            title: Text(i.factor.label),
            subtitle: Text(
              '${i.withCount} ${_nights(i.withCount)} с ним, ${i.withoutCount} без'
              '${i.qualityDiff == null || i.qualityDiff!.abs() < 0.1 ? '' : ' · самочувствие ${i.qualityDiff! >= 0 ? '+' : '−'}${i.qualityDiff!.abs().toStringAsFixed(1).replaceAll('.', ',')}'}',
            ),
            trailing: Text(
              '${i.durationDiff >= 0 ? '+' : '−'}${formatDuration(i.durationDiff.abs())}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: i.durationDiff.abs() < 15 ? scheme.onSurfaceVariant : (i.durationDiff > 0 ? Accent.habits : scheme.error),
              ),
            ),
            onTap: () => showSnack(context, i.factor.hint),
          ),
      ],
    );
  }
}

const _factorIcons = {
  'coffee': Icons.coffee_rounded,
  'alcohol': Icons.wine_bar_rounded,
  'screen': Icons.smartphone_rounded,
  'late_food': Icons.restaurant_rounded,
  'workout': Icons.fitness_center_rounded,
  'stress': Icons.psychology_alt_rounded,
  'nap': Icons.airline_seat_flat_rounded,
  'games': Icons.sports_esports_rounded,
  'walk': Icons.directions_walk_rounded,
  'reading': Icons.menu_book_rounded,
};

// ---------------------------------------------------------------------------
// Инструменты: калькулятор циклов и вечерний план
// ---------------------------------------------------------------------------

class _ToolsCard extends StatelessWidget {
  const _ToolsCard({required this.goals, this.latency});
  final SleepGoals goals;
  final int? latency;

  @override
  Widget build(BuildContext context) {
    return GroupCard(
      children: [
        ListTile(
          leading: const ColorIcon(Icons.calculate_rounded, color: Accent.sleep, size: 40),
          title: const Text('Когда лечь, когда встать'),
          subtitle: const Text('Расчёт по циклам сна'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => showFormSheet(context, (_) => _CyclesSheet(goals: goals, latency: latency ?? 15)),
        ),
        ListTile(
          leading: const ColorIcon(Icons.nights_stay_rounded, color: Accent.journal, size: 40),
          title: const Text('Вечерний план'),
          subtitle: Text('Что закончить до отбоя в ${formatMinutes(goals.bed)}'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => showFormSheet(context, (_) => _EveningSheet(goals: goals)),
        ),
      ],
    );
  }
}

class _CyclesSheet extends StatefulWidget {
  const _CyclesSheet({required this.goals, required this.latency});
  final SleepGoals goals;
  final int latency;

  @override
  State<_CyclesSheet> createState() => _CyclesSheetState();
}

class _CyclesSheetState extends State<_CyclesSheet> {
  bool _bedNow = false;
  late int _wake = widget.goals.wake;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final now = minutesOfDay(DateTime.now());
    final rows = _bedNow
        ? [for (final w in wakeTimesFor(now, latency: widget.latency)) (w.cycles, w.wake, w.sleep)]
        : [for (final b in bedtimesFor(_wake, latency: widget.latency)) (b.cycles, b.bed, b.sleep)];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Циклы сна', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        SegmentedButton<bool>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: false, label: Text('Встать в…')),
            ButtonSegment(value: true, label: Text('Лечь сейчас')),
          ],
          selected: {_bedNow},
          onSelectionChanged: (s) => setState(() => _bedNow = s.first),
        ),
        if (!_bedNow)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.wb_sunny_rounded, color: Accent.money),
            title: const Text('Встать в'),
            trailing: _TimeText(formatMinutes(_wake)),
            onTap: () async {
              final t = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(hour: _wake ~/ 60, minute: _wake % 60),
              );
              if (t != null) setState(() => _wake = t.hour * 60 + t.minute);
            },
          ),
        const SizedBox(height: 8),
        for (final (cycles, at, sleep) in rows)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: theme.colorScheme.surfaceContainerHigh,
            child: ListTile(
              title: Text(_bedNow ? 'Встать в ${formatMinutes(at)}' : 'Лечь в ${formatMinutes(at)}', style: theme.textTheme.titleMedium),
              subtitle: Text('$cycles ${cycles == 4 ? 'цикла' : 'циклов'} · сон ${formatDuration(sleep)}'),
              trailing: sleep >= 7 * 60 ? const Pill('норма', color: Accent.habits) : const Pill('мало', color: Accent.reminders),
            ),
          ),
        const SizedBox(height: 4),
        Text(
          'Цикл в среднем длится около 90 минут, проснуться в конце цикла легче. Время на засыпание: ${formatDuration(widget.latency)}. '
          'Это ориентир: длина циклов у всех разная, главное спать 7–9 часов и вставать в одно время.',
          style: TextStyle(color: muted, fontSize: 12, height: 1.35),
        ),
      ],
    );
  }
}

class _EveningSheet extends StatelessWidget {
  const _EveningSheet({required this.goals});
  final SleepGoals goals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final plan = eveningPlan(goals.bed);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Вечерний план', style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text('Для отбоя в ${formatMinutes(goals.bed)}', style: TextStyle(color: muted)),
        const SizedBox(height: 12),
        for (var i = 0; i < plan.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 56,
                  child: Text(
                    formatMinutes(plan[i].at),
                    style: theme.textTheme.titleMedium?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                  ),
                ),
                Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsets.only(top: 5),
                      decoration: BoxDecoration(color: i == plan.length - 1 ? Accent.sleep : Accent.journal, shape: BoxShape.circle),
                    ),
                    if (i < plan.length - 1) Expanded(child: Container(width: 2, color: theme.colorScheme.outlineVariant)),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(plan[i].title, style: theme.textTheme.titleSmall),
                        Text(plan[i].hint, style: TextStyle(color: muted)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        Text(
          'Утром выйди на дневной свет хотя бы на 10 минут: это помогает вечером уснуть вовремя.',
          style: TextStyle(color: muted, fontSize: 12, height: 1.35),
        ),
      ],
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
  late int? _latency = widget.existing?.latency;
  late int? _awakenings = widget.existing?.awakenings;
  late int? _awakeMinutes = widget.existing?.awakeMinutes;
  late final Set<String> _tags = widget.existing == null ? {} : sleepTags(widget.existing!);
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
        latency: Value(_latency),
        awakenings: Value(_awakenings),
        awakeMinutes: Value((_awakenings ?? 0) == 0 ? null : _awakeMinutes),
        tags: Value(joinSleepTags(_tags)),
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
        const SizedBox(height: 16),
        Text('Засыпал', style: theme.textTheme.titleSmall?.copyWith(color: muted)),
        const SizedBox(height: 6),
        _Chips(
          options: const [5, 15, 30, 45, 60, 90],
          value: _latency,
          label: (m) => m >= 90 ? '1,5 ч+' : (m == 60 ? '1 ч' : '$m мин'),
          onChanged: (v) => setState(() => _latency = v),
        ),
        const SizedBox(height: 12),
        Text('Просыпался ночью', style: theme.textTheme.titleSmall?.copyWith(color: muted)),
        const SizedBox(height: 6),
        _Chips(
          options: const [0, 1, 2, 3],
          value: _awakenings,
          label: (n) => n == 0 ? 'Ни разу' : (n == 3 ? '3+' : '$n'),
          onChanged: (v) => setState(() => _awakenings = v),
        ),
        if ((_awakenings ?? 0) > 0) ...[
          const SizedBox(height: 10),
          Text('Не спал ночью в сумме', style: theme.textTheme.titleSmall?.copyWith(color: muted)),
          const SizedBox(height: 6),
          _Chips(
            options: const [5, 15, 30, 60, 90],
            value: _awakeMinutes,
            label: (m) => m >= 60 ? formatDuration(m) : '$m мин',
            onChanged: (v) => setState(() => _awakeMinutes = v),
          ),
        ],
        const SizedBox(height: 12),
        Text('Что было вечером', style: theme.textTheme.titleSmall?.copyWith(color: muted)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final f in sleepFactors)
              FilterChip(
                avatar: Icon(_factorIcons[f.key], size: 16),
                label: Text(f.label),
                selected: _tags.contains(f.key),
                onSelected: (on) => setState(() => on ? _tags.add(f.key) : _tags.remove(f.key)),
              ),
          ],
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

/// Ряд вариантов с одним выбором; повторное нажатие снимает выбор.
class _Chips extends StatelessWidget {
  const _Chips({required this.options, required this.value, required this.label, required this.onChanged});
  final List<int> options;
  final int? value;
  final String Function(int) label;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 6,
    runSpacing: 6,
    children: [
      for (final o in options)
        ChoiceChip(showCheckmark: false, label: Text(label(o)), selected: value == o, onSelected: (_) => onChanged(value == o ? null : o)),
    ],
  );
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
