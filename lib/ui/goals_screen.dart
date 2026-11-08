import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import '../data/database.dart';
import '../data/dates.dart';
import '../data/queries.dart';
import '../logic/calc.dart';
import '../logic/values.dart';
import 'common.dart';

/// Текущее значение цели и подпись к нему.
({double? current, String unit, bool money}) goalCurrent(
  Goal g, {
  required Map<int, Tracker> trackers,
  required List<TrackerEntry> entries,
  required Map<int, double> fundValues,
}) {
  switch (g.kind) {
    case GoalKind.tracker:
      final t = trackers[g.trackerId];
      if (t == null) return (current: null, unit: '', money: false);
      return (current: trackerGoalValue(t, entries), unit: goalUnit(t), money: false);
    case GoalKind.fund:
      return (current: fundValues[g.fundId], unit: '₽', money: true);
  }
}

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    return Scaffold(
      appBar: AppBar(title: const Text('Цели')),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GoalEditScreen())),
        child: const Icon(Icons.add),
      ),
      body: Watch(
        streams: () => [db.watchGoals(), db.watchTrackers(), db.watchAllEntries(), db.watchFundValues()],
        builder: (context, v) {
          final goals = v[0] as List<Goal>;
          final trackers = {for (final t in v[1] as List<Tracker>) t.id: t};
          final entries = v[2] as List<TrackerEntry>;
          final fundValues = v[3] as Map<int, double>;
          if (goals.isEmpty) {
            return const EmptyHint(
              'Цель это измеримый результат к сроку: «Вес 73 кг», «Закрыть кредит». Она берёт значение из трекера или копилки и показывает прогноз.',
            );
          }
          final today = todayKey();
          return ListView(
            padding: const EdgeInsets.only(top: 8, bottom: 88),
            children: [
              for (final g in goals)
                _GoalCard(
                  goal: g,
                  info: goalCurrent(g, trackers: trackers, entries: entries, fundValues: fundValues),
                  today: today,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal, required this.info, required this.today});
  final Goal goal;
  final ({double? current, String unit, bool money}) info;
  final int today;

  String _fmt(double v) => info.money ? formatMoney(v) : '${formatNumber(v)}${info.unit.isEmpty ? '' : ' ${info.unit}'}';

  @override
  Widget build(BuildContext context) {
    final g = goal;
    final scheme = Theme.of(context).colorScheme;
    final current = info.current;
    final lines = <Widget>[];
    double fraction = 0;
    if (current == null) {
      lines.add(const Text('Пока нет данных'));
    } else {
      final p = goalProgress(start: g.startValue, target: g.targetValue, current: current, startDay: g.startDay, today: today);
      fraction = p.fraction;
      lines.add(Text('${_fmt(current)} · цель ${_fmt(g.targetValue)}'));
      if (p.reached) {
        lines.add(const Text('🎉 Достигнута'));
      } else if (p.forecastDay != null) {
        final late = g.deadline != null && p.forecastDay! > g.deadline!;
        lines.add(
          Text(
            'При текущем темпе: ${formatDay(p.forecastDay!, withYear: true)}${late ? ', позже срока' : ''}',
            style: TextStyle(color: late ? scheme.error : scheme.onSurfaceVariant),
          ),
        );
      } else if (daysBetween(g.startDay, today) < 7) {
        lines.add(Text('Прогноз появится через неделю данных', style: TextStyle(color: scheme.onSurfaceVariant)));
      }
    }
    if (g.deadline != null) {
      final left = daysBetween(today, g.deadline!);
      lines.add(
        Text(
          'Срок: ${formatDay(g.deadline!, withYear: true)}${left >= 0 ? ' (осталось $left дн.)' : ' (прошёл)'}',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
      );
    }
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GoalEditScreen(goal: g))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(g.name, style: Theme.of(context).textTheme.titleMedium)),
                  Text('${(fraction * 100).round()}%'),
                ],
              ),
              const SizedBox(height: 8),
              ProgressLine(value: fraction),
              const SizedBox(height: 8),
              ...lines,
            ],
          ),
        ),
      ),
    );
  }
}

class GoalEditScreen extends StatefulWidget {
  const GoalEditScreen({super.key, this.goal});
  final Goal? goal;

  @override
  State<GoalEditScreen> createState() => _GoalEditScreenState();
}

class _GoalEditScreenState extends State<GoalEditScreen> {
  late final _name = TextEditingController(text: widget.goal?.name ?? '');
  late GoalKind _kind = widget.goal?.kind ?? GoalKind.tracker;
  late int? _trackerId = widget.goal?.trackerId;
  late int? _fundId = widget.goal?.fundId;
  late final _start = TextEditingController(text: widget.goal == null ? '' : formatNumber(widget.goal!.startValue, maxDecimals: 2));
  late final _target = TextEditingController(text: widget.goal == null ? '' : formatNumber(widget.goal!.targetValue, maxDecimals: 2));
  late int? _deadline = widget.goal?.deadline;

  Future<void> _save() async {
    final start = parseNumber(_start.text);
    final target = parseNumber(_target.text);
    if (_name.text.trim().isEmpty) return showSnack(context, 'Введи название');
    if (_kind == GoalKind.tracker && _trackerId == null) return showSnack(context, 'Выбери трекер');
    if (_kind == GoalKind.fund && _fundId == null) return showSnack(context, 'Выбери копилку или долг');
    if (start == null || target == null) return showSnack(context, 'Укажи старт и цель');
    await context.db.saveGoal(
      GoalsCompanion(
        id: widget.goal == null ? const Value.absent() : Value(widget.goal!.id),
        name: Value(_name.text.trim()),
        kind: Value(_kind),
        trackerId: Value(_kind == GoalKind.tracker ? _trackerId : null),
        fundId: Value(_kind == GoalKind.fund ? _fundId : null),
        startValue: Value(start),
        targetValue: Value(target),
        deadline: Value(_deadline),
        startDay: widget.goal == null ? Value(todayKey()) : const Value.absent(),
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    final g = widget.goal;
    return Scaffold(
      appBar: AppBar(title: Text(g == null ? 'Новая цель' : 'Цель')),
      body: Watch(
        streams: () => [db.watchTrackers(), db.watchFunds(), db.watchAllEntries(), db.watchFundValues()],
        builder: (context, v) {
          final trackers = v[0] as List<Tracker>;
          final funds = v[1] as List<Fund>;
          final entries = v[2] as List<TrackerEntry>;
          final fundValues = v[3] as Map<int, double>;
          final trackerMap = {for (final t in trackers) t.id: t};
          String? hint;
          if (_kind == GoalKind.tracker && trackerMap[_trackerId] != null) {
            final t = trackerMap[_trackerId]!;
            final cur = trackerGoalValue(t, entries);
            hint = [
              if (t.kind == TrackerKind.duration) 'Цель по времени считается в часах суммарно.',
              if (t.kind == TrackerKind.yesNo) 'Цель считается в днях с ответом «да».',
              if (cur != null) 'Сейчас: ${formatNumber(cur)} ${goalUnit(t)}',
            ].join(' ');
          } else if (_kind == GoalKind.fund && _fundId != null && fundValues[_fundId] != null) {
            hint = 'Сейчас: ${formatMoney(fundValues[_fundId]!)}';
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Название', hintText: 'Например: Вес 73 кг'),
              ),
              const SizedBox(height: 16),
              SegmentedButton<GoalKind>(
                segments: const [
                  ButtonSegment(value: GoalKind.tracker, label: Text('По трекеру')),
                  ButtonSegment(value: GoalKind.fund, label: Text('По копилке или долгу')),
                ],
                selected: {_kind},
                onSelectionChanged: (s) => setState(() => _kind = s.first),
              ),
              const SizedBox(height: 16),
              if (_kind == GoalKind.tracker)
                DropdownButtonFormField<int>(
                  initialValue: trackerMap.containsKey(_trackerId) ? _trackerId : null,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Трекер'),
                  items: [for (final t in trackers) DropdownMenuItem(value: t.id, child: Text('${t.icon} ${t.name}'))],
                  onChanged: (id) => setState(() {
                    _trackerId = id;
                    final t = trackerMap[id];
                    final cur = t == null ? null : trackerGoalValue(t, entries);
                    if (_start.text.isEmpty && cur != null) _start.text = formatNumber(cur, maxDecimals: 2);
                  }),
                )
              else
                DropdownButtonFormField<int>(
                  initialValue: funds.any((f) => f.id == _fundId) ? _fundId : null,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Копилка или долг'),
                  items: [for (final f in funds) DropdownMenuItem(value: f.id, child: Text('${f.icon} ${f.name}'))],
                  onChanged: (id) => setState(() {
                    _fundId = id;
                    final f = funds.where((f) => f.id == id).firstOrNull;
                    if (f == null) return;
                    if (_start.text.isEmpty) _start.text = formatNumber(fundValues[id] ?? f.initialAmount);
                    if (_target.text.isEmpty) {
                      final t = f.kind == FundKind.debt ? 0.0 : f.target;
                      if (t != null) _target.text = formatNumber(t);
                    }
                  }),
                ),
              if (hint != null && hint.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(hint)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: NumberField(controller: _start, label: 'Старт', allowNegative: true),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: NumberField(controller: _target, label: 'Цель', allowNegative: true),
                  ),
                ],
              ),
              DayTile(title: 'Срок', day: _deadline, allowClear: true, onChanged: (d) => setState(() => _deadline = d)),
              const SizedBox(height: 16),
              FilledButton(onPressed: _save, child: const Text('Сохранить')),
              if (g != null) ...[
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  icon: const Icon(Icons.archive_outlined),
                  label: const Text('В архив'),
                  onPressed: () async {
                    await db.setArchived(db.goals, g.id, true);
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Удалить цель'),
                  onPressed: () async {
                    if (await confirm(
                      context,
                      'Удалить цель?',
                      text: 'Данные трекера или копилки останутся.',
                      ok: 'Удалить',
                      danger: true,
                    )) {
                      await db.deleteById(db.goals, g.id);
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
