import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/database.dart';
import '../data/dates.dart';
import '../logic/calc.dart';
import '../logic/report.dart';
import 'common.dart';
import 'journal_screen.dart';
import 'theme.dart';

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
          final theme = Theme.of(context);
          final dark = theme.brightness == Brightness.dark;
          final muted = theme.colorScheme.onSurfaceVariant;
          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              HeroCard(
                colors: dark ? const [Color(0xFF0E7490), Color(0xFF1D4ED8)] : const [Color(0xFF0891B2), Color(0xFF2563EB)],
                child: Column(
                  children: [
                    Row(
                      children: [
                        HeroArrow(Icons.chevron_left_rounded, onTap: () => setState(() => _monday = addDays(_monday, -7))),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                '${formatDay(r.from)} – ${formatDay(r.to)}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17),
                              ),
                              if (isCurrent) const Text('неделя идёт', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),
                        HeroArrow(
                          Icons.chevron_right_rounded,
                          onTap: isCurrent ? null : () => setState(() => _monday = addDays(_monday, 7)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: HeroStat(label: 'Привычки', value: '${r.habitsDone} из ${r.habitsPlanned}'),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: HeroStat(label: 'Тренировки', value: '${r.workoutsDone} из ${r.workoutsPlanned}'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: HeroStat(label: 'Итоги дня', value: '${r.dayNotes} из 7'),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: HeroStat(
                            label: 'Настроение',
                            value: r.moodAvg == null ? '—' : '${moodEmoji(r.moodAvg!.round())} ${formatNumber(r.moodAvg!)}',
                          ),
                        ),
                      ],
                    ),
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
                        child: Text(r.review == null ? 'Написать обзор' : 'Открыть обзор'),
                        onPressed: () => openJournalEditor(context, kind: JournalKind.week, day: _monday, existing: r.review),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
                        child: const Text('Скопировать'),
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: r.toText()));
                          if (context.mounted) showSnack(context, 'Отчёт скопирован, можно вставить в любой чат');
                        },
                      ),
                    ),
                  ],
                ),
              ),
              if (r.habits.isNotEmpty) ...[
                const SectionTitle('Привычки'),
                GroupCard(
                  children: [
                    for (final h in r.habits)
                      ListTile(
                        leading: EmojiAvatar(h.habit.icon, size: 40, color: Accent.habits),
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
                        leading: EmojiAvatar(t.tracker.icon, size: 40, color: Accent.trackers),
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
                        leading: EmojiAvatar(f.icon, size: 40, color: Accent.money),
                        title: Text(f.name),
                        subtitle: Text(f.kind == FundKind.debt ? 'выплачено' : (sum >= 0 ? 'отложено' : 'снято')),
                        trailing: Text(formatMoney(sum.abs()), style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
              if (r.review != null && r.review!.body.trim().isNotEmpty) ...[
                const SectionTitle('Обзор недели'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(r.review!.body, style: const TextStyle(height: 1.45)),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
