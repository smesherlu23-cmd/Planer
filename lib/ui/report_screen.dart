import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/database.dart';
import '../data/dates.dart';
import '../logic/calc.dart';
import '../logic/report.dart';
import 'common.dart';
import 'journal_screen.dart';

Stream<WeekReport> watchWeekReport(AppDatabase db, int monday) async* {
  yield await buildWeekReport(db, monday);
  await for (final _ in db.tableUpdates()) {
    yield await buildWeekReport(db, monday);
  }
}

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key, this.weekStartDay});
  final int? weekStartDay;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  late int _monday = widget.weekStartDay ?? weekStart(todayKey());

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    final isCurrent = _monday == weekStart(todayKey());
    return Scaffold(
      appBar: AppBar(title: const Text('Отчёт недели')),
      body: Watch(
        deps: [_monday],
        streams: () => [watchWeekReport(db, _monday)],
        builder: (context, v) {
          final r = v[0] as WeekReport;
          final scheme = Theme.of(context).colorScheme;
          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              Row(
                children: [
                  IconButton(onPressed: () => setState(() => _monday = addDays(_monday, -7)), icon: const Icon(Icons.chevron_left)),
                  Expanded(
                    child: Text(
                      '${formatDay(r.from)} – ${formatDay(r.to)}${isCurrent ? ' (идёт)' : ''}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    onPressed: isCurrent ? null : () => setState(() => _monday = addDays(_monday, 7)),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Wrap(
                  spacing: 8,
                  children: [
                    FilledButton.tonalIcon(
                      icon: const Icon(Icons.edit_note),
                      label: Text(r.review == null ? 'Написать обзор' : 'Открыть обзор'),
                      onPressed: () => openJournalEditor(context, kind: JournalKind.week, day: _monday, existing: r.review),
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.copy),
                      label: const Text('Скопировать текстом'),
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: r.toText()));
                        if (context.mounted) showSnack(context, 'Отчёт скопирован, можно вставить в любой чат');
                      },
                    ),
                  ],
                ),
              ),
              if (r.habits.isNotEmpty) ...[
                SectionTitle('Привычки: ${r.habitsDone} из ${r.habitsPlanned}'),
                for (final h in r.habits)
                  ListTile(
                    dense: true,
                    leading: Text(h.habit.icon, style: const TextStyle(fontSize: 20)),
                    title: Text(h.habit.name),
                    subtitle: h.minimum > 0 ? Text('минимумом: ${h.minimum}') : null,
                    trailing: Text(
                      '${h.done} из ${h.planned}',
                      style: TextStyle(color: h.planned > 0 && h.done >= h.planned ? Colors.green : null, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
              if (r.trackers.isNotEmpty) ...[
                const SectionTitle('Трекеры'),
                for (final t in r.trackers)
                  ListTile(
                    dense: true,
                    leading: Text(t.tracker.icon, style: const TextStyle(fontSize: 20)),
                    title: Text(t.tracker.name),
                    subtitle: Text(t.label),
                  ),
              ],
              if (r.workoutsPlanned > 0 || r.workoutsDone > 0) ...[
                SectionTitle('Тренировки: ${r.workoutsDone} из ${r.workoutsPlanned}'),
                if (r.workoutNames.isNotEmpty)
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(r.workoutNames.join(', '))),
              ],
              SectionTitle('Деньги: расходы ${formatMoney(r.expenses)}'),
              if (r.income > 0)
                Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('Доходы: ${formatMoney(r.income)}')),
              for (final (name, sum) in r.topCategories) ListTile(dense: true, title: Text(name), trailing: Text(formatMoney(sum))),
              for (final (f, sum) in r.fundMoves)
                ListTile(
                  dense: true,
                  leading: Text(f.icon, style: const TextStyle(fontSize: 20)),
                  title: Text(f.name),
                  trailing: Text('${f.kind == FundKind.debt ? 'выплачено' : (sum >= 0 ? 'отложено' : 'снято')} ${formatMoney(sum.abs())}'),
                ),
              SectionTitle('Итогов дня: ${r.dayNotes} из 7'),
              if (r.moodAvg != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Среднее настроение: ${formatNumber(r.moodAvg!)} из 10'),
                ),
              if (r.review != null && r.review!.body.trim().isNotEmpty) ...[
                const SectionTitle('Обзор недели'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(r.review!.body, style: TextStyle(color: scheme.onSurface)),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
