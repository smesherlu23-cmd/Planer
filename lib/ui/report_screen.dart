import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/database.dart';
import '../data/dates.dart';
import '../logic/calc.dart';
import '../logic/journal.dart';
import '../logic/report.dart';
import 'common.dart';
import 'charts.dart';
import 'food_screen.dart';
import 'goals_screen.dart';
import 'icons.dart';
import 'journal_screen.dart';
import 'sleep_screen.dart';
import 'theme.dart';

Stream<WeekReport> watchWeekReport(AppDatabase db, int monday) => watchReport(db, ReportPeriod.week, monday);

Stream<WeekReport> watchReport(AppDatabase db, ReportPeriod period, int day) async* {
  yield await buildReport(db, period, day);
  await for (final _ in db.tableUpdates()) {
    yield await buildReport(db, period, day);
  }
}

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key, this.weekStartDay, this.period = ReportPeriod.week, this.day});

  /// Открыть сразу на этой неделе.
  final int? weekStartDay;
  final ReportPeriod period;
  final int? day;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  late ReportPeriod _period = widget.weekStartDay != null ? ReportPeriod.week : widget.period;
  late int _day = widget.weekStartDay ?? widget.day ?? todayKey();

  int get _from => periodRange(_period, _day).from;

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    final today = todayKey();
    final isCurrent = periodRange(_period, today).from == _from;
    return Scaffold(
      appBar: AppBar(title: const Text('Итоги')),
      body: Watch(
        deps: [_period, _from],
        streams: () => [watchReport(db, _period, _from)],
        builder: (context, v) {
          final r = v[0] as WeekReport;
          final theme = Theme.of(context);
          final dark = theme.brightness == Brightness.dark;
          final muted = theme.colorScheme.onSurfaceVariant;
          final prev = r.prev;
          final day = _period == ReportPeriod.day;
          final prevName = switch (_period) {
            ReportPeriod.day => 'вчера',
            ReportPeriod.week => 'прошлая неделя',
            ReportPeriod.month => 'прошлый месяц',
          };
          final moodValues = [for (final (_, m) in r.moods) m];
          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                child: SegmentedButton<ReportPeriod>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: ReportPeriod.day, label: Text('День')),
                    ButtonSegment(value: ReportPeriod.week, label: Text('Неделя')),
                    ButtonSegment(value: ReportPeriod.month, label: Text('Месяц')),
                  ],
                  selected: {_period},
                  onSelectionChanged: (s) => setState(() {
                    _period = s.first;
                    _day = isCurrent ? today : _from;
                  }),
                ),
              ),
              HeroCard(
                colors: dark ? const [Color(0xFF0E7490), Color(0xFF1D4ED8)] : const [Color(0xFF0891B2), Color(0xFF2563EB)],
                child: Column(
                  children: [
                    Row(
                      children: [
                        HeroArrow(Icons.chevron_left_rounded, onTap: () => setState(() => _day = shiftPeriod(_period, _from, -1))),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                periodTitle(_period, r.from, r.to),
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17),
                              ),
                              if (isCurrent)
                                Text(switch (_period) {
                                  ReportPeriod.day => 'сегодня',
                                  ReportPeriod.week => 'неделя идёт',
                                  ReportPeriod.month => 'месяц идёт',
                                }, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),
                        HeroArrow(
                          Icons.chevron_right_rounded,
                          onTap: isCurrent ? null : () => setState(() => _day = shiftPeriod(_period, _from, 1)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: HeroStat(
                            label: 'Привычки${_delta(r.habitsRate, prev?.habitsRate, percent: true)}',
                            value: '${r.habitsDone} из ${r.habitsPlanned}',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: HeroStat(
                            label:
                                'Тренировки${prev == null || day ? '' : _delta(r.workoutsDone.toDouble(), prev.workoutsDone.toDouble())}',
                            value: '${r.workoutsDone} из ${r.workoutsPlanned}',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: HeroStat(
                            label: day ? 'Итог дня' : 'Итоги дня',
                            value: day ? (r.dayNotes > 0 ? 'записан' : 'нет') : '${r.dayNotes} из ${r.days}',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: HeroStat(
                            label: 'Настроение${_delta(r.moodAvg, prev?.moodAvg)}',
                            value: r.moodAvg == null ? '—' : '${formatNumber(r.moodAvg!)} из 10',
                          ),
                        ),
                      ],
                    ),
                    if (prev != null && (prev.habitsRate != null || prev.moodAvg != null))
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          'В скобках: изменение к периоду «$prevName»',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              if (r.hardDays > 0 || r.habits.any((h) => h.minimum > 0) || r.workoutsMinimum > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (r.hardDays > 0)
                        Pill(
                          day ? 'тяжёлый день' : 'тяжёлых дней: ${r.hardDays}',
                          icon: Icons.battery_alert_rounded,
                          color: Accent.reminders,
                        ),
                      if (r.habits.any((h) => h.minimum > 0))
                        Pill('привычек минимумом: ${r.habits.fold(0, (a, h) => a + h.minimum)}', color: Accent.reminders),
                      if (r.workoutsMinimum > 0) Pill('облегчённых тренировок: ${r.workoutsMinimum}', color: Accent.reminders),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonal(
                        style: FilledButton.styleFrom(minimumSize: const Size(64, 48), padding: const EdgeInsets.symmetric(horizontal: 12)),
                        child: Text(
                          r.review == null
                              ? switch (_period) {
                                  ReportPeriod.day => 'Записать итог дня',
                                  ReportPeriod.week => 'Написать обзор',
                                  ReportPeriod.month => 'Обзор месяца',
                                }
                              : 'Открыть ${day ? 'итог' : 'обзор'}',
                        ),
                        onPressed: () => openJournalEditor(context, kind: reviewKind(_period), day: r.from, existing: r.review),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
                        child: const Text('Скопировать'),
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: r.toText()));
                          if (context.mounted) showSnack(context, 'Итоги скопированы, можно вставить в любой чат');
                        },
                      ),
                    ),
                  ],
                ),
              ),
              if (r.review != null && journalHasContent(r.review!)) ...[
                SectionTitle(day ? 'Итог дня' : 'Обзор'),
                _ReviewCard(entry: r.review!),
              ],
              if (r.goals.isNotEmpty) ...[
                const SectionTitle('Цели'),
                GroupCard(
                  children: [
                    for (final g in r.goals)
                      ListTile(
                        leading: ProgressRing(
                          value: g.status.fraction,
                          size: 40,
                          stroke: 5,
                          color: goalAreaColor(g.goal.area),
                          child: Text(
                            '${(g.status.fraction * 100).round()}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ),
                        title: Text(g.goal.name),
                        subtitle: Text(g.text),
                        trailing: Icon(
                          g.forward
                              ? Icons.trending_up_rounded
                              : (g.delta == null || g.delta == 0 ? Icons.trending_flat_rounded : Icons.trending_down_rounded),
                          color: g.forward ? Accent.habits : (g.delta == null || g.delta == 0 ? muted : Accent.workouts),
                        ),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GoalDetailScreen(goalId: g.goal.id))),
                      ),
                  ],
                ),
              ],
              if (!day && moodValues.whereType<int>().length >= 2) ...[
                const SectionTitle('Настроение по дням'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                    child: BarChart(
                      bars: [
                        for (final (d, m) in r.moods)
                          (
                            _period == ReportPeriod.week
                                ? weekdayShort[dayFromKey(d).weekday - 1]
                                : (dayFromKey(d).day % 5 == 1 ? '${dayFromKey(d).day}' : ''),
                            m?.toDouble(),
                          ),
                      ],
                      color: Accent.journal.withValues(alpha: 0.55),
                      goodColor: Accent.journal,
                      target: r.moodAvg,
                      height: 120,
                    ),
                  ),
                ),
              ],
              if (!day && r.wins.isNotEmpty) ...[
                SectionTitle(
                  'Победы',
                  trailing: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text('${r.wins.length}', style: theme.textTheme.labelLarge?.copyWith(color: muted)),
                  ),
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final (d, w) in r.wins.take(20))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Icon(Icons.emoji_events_outlined, size: 16, color: Accent.reminders),
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: Text(w, style: const TextStyle(height: 1.3))),
                                Text(weekdayShort[dayFromKey(d).weekday - 1], style: theme.textTheme.bodySmall?.copyWith(color: muted)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
              if (!day && r.tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [for (final (t, n) in r.tags.take(10)) Pill('#$t · $n', color: Accent.journal)],
                  ),
                ),
              if (r.habits.isNotEmpty) ...[
                const SectionTitle('Привычки'),
                GroupCard(
                  children: [
                    for (final h in r.habits)
                      ListTile(
                        leading: ItemIcon(h.habit.icon, size: 40),
                        title: Text(h.habit.name),
                        subtitle: h.minimum > 0 ? Text('минимумом: ${h.minimum}') : null,
                        trailing: Pill('${h.done} из ${h.planned}', color: h.planned > 0 && h.done >= h.planned ? Accent.habits : null),
                      ),
                  ],
                ),
              ],
              if (r.trackers.isNotEmpty) ...[
                const SectionTitle('Трекеры'),
                GroupCard(
                  children: [
                    for (final t in r.trackers)
                      ListTile(
                        leading: ItemIcon(t.tracker.icon, size: 40, fallback: 'chart'),
                        title: Text(t.tracker.name),
                        subtitle: Text(t.label),
                      ),
                  ],
                ),
              ],
              if (r.workoutNames.isNotEmpty) ...[
                const SectionTitle('Тренировки'),
                GroupCard(
                  children: [
                    for (final name in r.workoutNames)
                      ListTile(
                        leading: const IconBadge(Icons.fitness_center_rounded, color: Accent.workouts, soft: true),
                        title: Text(name),
                      ),
                  ],
                ),
              ],
              if (r.sleep != null && r.sleep!.stats.nights > 0) ...[
                const SectionTitle('Сон'),
                _StatsCard(
                  icon: Icons.bedtime_rounded,
                  color: Accent.sleep,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SleepScreen())),
                  stats: [
                    ('В среднем', formatDuration(r.sleep!.stats.avgDuration!)),
                    ('Отбой', formatMinutes(r.sleep!.stats.avgBed!)),
                    ('Выспался', '${r.sleep!.stats.full} из ${r.sleep!.stats.nights}'),
                  ],
                ),
              ],
              if (r.food != null && r.food!.days > 0) ...[
                const SectionTitle('Питание'),
                _StatsCard(
                  icon: Icons.restaurant_rounded,
                  color: Accent.food,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FoodScreen())),
                  stats: [
                    ('Ккал в день', formatNumber(r.food!.avgKcal, maxDecimals: 0)),
                    ('Белок', '${formatNumber(r.food!.avgProtein, maxDecimals: 0)} г'),
                    (
                      r.food!.minimum > 0 ? 'Норма · минимум' : 'В норме',
                      r.food!.minimum > 0 ? '${r.food!.onTarget} · ${r.food!.minimum}' : '${r.food!.onTarget} из ${r.food!.days}',
                    ),
                  ],
                ),
              ],
              SectionTitle(
                'Деньги',
                trailing: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    r.income > 0 ? '−${formatMoney(r.expenses)} · +${formatMoney(r.income)}' : '−${formatMoney(r.expenses)}',
                    style: theme.textTheme.labelLarge?.copyWith(color: muted),
                  ),
                ),
              ),
              if (r.topCategories.isEmpty && r.fundMoves.isEmpty)
                const Card(child: EmptyHint('За неделю операций нет', icon: Icons.receipt_long_outlined)),
              if (r.topCategories.isNotEmpty || r.fundMoves.isNotEmpty)
                GroupCard(
                  children: [
                    for (final (name, sum) in r.topCategories)
                      ListTile(
                        leading: const IconBadge(Icons.shopping_bag_rounded, color: Accent.money, soft: true),
                        title: Text(name),
                        trailing: Text('−${formatMoney(sum)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    for (final (f, sum) in r.fundMoves)
                      ListTile(
                        leading: ItemIcon(f.icon, size: 40, fallback: 'savings'),
                        title: Text(f.name),
                        subtitle: Text(f.kind == FundKind.debt ? 'выплачено' : (sum >= 0 ? 'отложено' : 'снято')),
                        trailing: Text(formatMoney(sum.abs()), style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Карточка с иконкой и тремя цифрами в ряд.
class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.icon, required this.color, required this.stats, required this.onTap});
  final IconData icon;
  final Color color;
  final List<(String, String)> stats;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
          child: Row(
            children: [
              ColorIcon(icon, color: color),
              const SizedBox(width: 12),
              for (final (label, value) in stats)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        ),
                      ),
                      Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

String _delta(double? now, double? before, {bool percent = false}) {
  if (now == null || before == null) return '';
  final d = percent ? (now - before) * 100 : now - before;
  if (d.abs() < (percent ? 1 : 0.1)) return ' (=)';
  final sign = d > 0 ? '+' : '−';
  return ' ($sign${formatNumber(d.abs(), maxDecimals: percent ? 0 : 1)}${percent ? '%' : ''})';
}

/// Обзор или итог дня по полям.
class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.entry});
  final JournalEntry entry;

  @override
  Widget build(BuildContext context) {
    final e = entry;
    final f = journalFields(e.kind);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final blocks = [
      if (f.wins != null) (f.wins!, e.wins),
      if (f.gratitude != null) (f.gratitude!, e.gratitude),
      if (f.lesson != null) (f.lesson!, e.lesson),
      if (f.focus != null) (f.focus!, e.focus),
      (f.body, e.body),
    ].where((b) => listLines(b.$2).isNotEmpty).toList();
    return Card(
      child: InkWell(
        onTap: () => openJournalEditor(context, kind: e.kind, day: e.day, existing: e),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (e.mood != null || parseTags(e.tags).isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (e.mood != null) Pill('настроение ${e.mood}', icon: moodIcon(e.mood!), color: moodColor(e.mood!)),
                      if (e.energy != null) Pill('энергия ${e.energy}/5', icon: Icons.bolt_rounded, color: Accent.reminders),
                      for (final t in parseTags(e.tags)) Pill('#$t', color: Accent.journal),
                    ],
                  ),
                ),
              for (final (label, text) in blocks)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: theme.textTheme.labelLarge?.copyWith(color: muted)),
                      const SizedBox(height: 2),
                      Text(text!.trim(), style: const TextStyle(height: 1.45)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
