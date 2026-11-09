import 'package:flutter/material.dart';

import '../data/database.dart';
import '../data/dates.dart';
import '../data/queries.dart';
import '../data/time_queries.dart';
import '../logic/day_plan.dart';
import '../logic/focus.dart';
import 'charts.dart';
import 'common.dart';
import 'day_plan_screen.dart';

/// Вкладка «Итоги»: куда ушла неделя, план против факта, точность оценок.
class TimeStatsTab extends StatefulWidget {
  const TimeStatsTab({super.key});

  @override
  State<TimeStatsTab> createState() => _TimeStatsTabState();
}

class _TimeStatsTabState extends State<TimeStatsTab> {
  var _week = weekStart(todayKey());

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    final thisWeek = weekStart(todayKey());
    return Watch(
      streams: () => [db.watchTasks(), db.watchFocus(), db.watchTimeBlocks()],
      builder: (context, v) {
        final tasks = v[0] as List<Task>;
        final sessions = v[1] as List<FocusSession>;
        final blocks = v[2] as List<TimeBlock>;
        final w = timeWeek(weekStartDay: _week, tasks: tasks, sessions: sessions, blocks: blocks);
        final prev = timeWeek(weekStartDay: addDays(_week, -7), tasks: tasks, sessions: sessions, blocks: blocks);
        final theme = Theme.of(context);
        final muted = theme.colorScheme.onSurfaceVariant;
        final labels = [for (final d in w.days) weekdayShort[dayFromKey(d).weekday - 1]];
        // Работу, дорогу, еду и отдых таймером не меряют: показываем их, только если фокус на них был.
        const measured = {BlockKind.study, BlockKind.home, BlockKind.sport, BlockKind.other};
        final kinds = {...w.focusByKind.keys.whereType<BlockKind>(), ...w.planByKind.keys.where(measured.contains)}.toList()
          ..sort((a, b) => (w.planByKind[b] ?? 0).compareTo(w.planByKind[a] ?? 0));
        final diff = w.focusTotal - prev.focusTotal;
        return Scaffold(
          appBar: AppBar(title: const Text('Итоги')),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              HeroCard(
                colors: const [Color(0xFF0EA5E9), Color(0xFF6366F1)],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        HeroArrow(Icons.chevron_left_rounded, onTap: () => setState(() => _week = addDays(_week, -7))),
                        Expanded(
                          child: Text(
                            _week == thisWeek ? 'Эта неделя' : '${formatDay(_week)} – ${formatDay(addDays(_week, 6))}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                        ),
                        HeroArrow(
                          Icons.chevron_right_rounded,
                          onTap: _week >= thisWeek ? null : () => setState(() => _week = addDays(_week, 7)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      w.focusTotal == 0 ? 'Фокуса пока нет' : formatDuration(w.focusTotal),
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
                    ),
                    const Text('сосредоточенной работы', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: HeroStat(label: 'Задач сделано', value: '${w.doneTotal}'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: HeroStat(label: 'Дней с фокусом', value: '${w.activeDays} из 7'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: HeroStat(
                            label: 'К прошлой неделе',
                            value: prev.focusTotal == 0 && w.focusTotal == 0
                                ? '—'
                                : '${diff >= 0 ? '+' : '−'}${formatDuration(diff.abs())}',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SectionTitle('Фокус по дням'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                  child: BarChart(
                    bars: [for (var i = 0; i < 7; i++) (labels[i], w.focusByDay[i] == 0 ? null : w.focusByDay[i] / 60)],
                    color: const Color(0xFF6366F1),
                  ),
                ),
              ),
              const Padding(padding: EdgeInsets.fromLTRB(24, 6, 24, 0), child: Text('Столбики в часах.')),
              const SectionTitle('Задачи по дням'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                  child: BarChart(
                    bars: [for (var i = 0; i < 7; i++) (labels[i], w.doneByDay[i] == 0 ? null : w.doneByDay[i].toDouble())],
                    color: const Color(0xFF22C55E),
                  ),
                ),
              ),
              if (kinds.isNotEmpty) ...[
                const SectionTitle('План и факт по сферам'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        for (final k in kinds) _KindRow(kind: k, fact: w.focusByKind[k] ?? 0, plan: w.planByKind[k] ?? 0),
                        if ((w.focusByKind[null] ?? 0) > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text('Без сферы: ${formatDuration(w.focusByKind[null]!)}', style: TextStyle(color: muted)),
                          ),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 6, 24, 0),
                  child: Text('План: сколько времени на сферу заложено в «Дне» за неделю. Факт: таймер фокуса.'),
                ),
              ],
              if (w.topTasks.isNotEmpty) ...[
                const SectionTitle('Больше всего времени'),
                GroupCard(
                  children: [
                    for (final (title, minutes) in w.topTasks)
                      ListTile(
                        title: Text(title),
                        trailing: Text(formatDuration(minutes), style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
              ],
              const SectionTitle('Точность оценок'),
              Card(
                child: Padding(padding: const EdgeInsets.all(16), child: Text(_estimateText(w.estimateRatio, w.estimateSamples))),
              ),
            ],
          ),
        );
      },
    );
  }
}

String _estimateText(double? ratio, int samples) {
  if (ratio == null) {
    return 'Ставь задачам оценку и работай над ними с таймером. После трёх таких задач здесь будет видно, '
        'насколько твои оценки совпадают с реальностью (сделано $samples).';
  }
  final pct = ((ratio - 1) * 100).round();
  if (pct.abs() <= 10) return 'Оценки почти точные: реальное время отличается меньше чем на 10%. По $samples задачам.';
  if (pct > 0) {
    return 'Задачи занимают на $pct% больше, чем кажется. Закладывай с запасом: план на час это примерно '
        '${formatDuration((60 * ratio).round())}. По $samples задачам.';
  }
  return 'Задачи занимают на ${-pct}% меньше, чем ты закладываешь. Можно планировать смелее. По $samples задачам.';
}

class _KindRow extends StatelessWidget {
  const _KindRow({required this.kind, required this.fact, required this.plan});
  final BlockKind kind;
  final int fact;
  final int plan;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final color = kindColor(kind);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(backgroundColor: color, radius: 5),
              const SizedBox(width: 8),
              Expanded(
                child: Text(kind.label, style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              Text(formatDuration(fact), style: const TextStyle(fontWeight: FontWeight.w700)),
              if (plan > 0) Text(' из ${formatDuration(plan)}', style: TextStyle(color: muted)),
            ],
          ),
          const SizedBox(height: 6),
          ProgressLine(value: plan == 0 ? (fact > 0 ? 1 : 0) : fact / plan, color: color, height: 6),
        ],
      ),
    );
  }
}
