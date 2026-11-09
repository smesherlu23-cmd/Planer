import 'package:flutter/material.dart';

import '../data/database.dart';
import '../data/dates.dart';
import '../data/queries.dart';
import '../logic/calc.dart';
import '../logic/food.dart';
import '../logic/sleep.dart';
import '../logic/values.dart';
import 'common.dart';
import 'food_screen.dart';
import 'icons.dart';
import 'habits_screen.dart';
import 'journal_screen.dart';
import 'money_screen.dart';
import 'report_screen.dart';
import 'sleep_screen.dart';
import 'theme.dart';
import 'trackers_screen.dart';
import 'workouts_screen.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> with WidgetsBindingObserver {
  var _today = todayKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Если приложение открыли на следующий день, экран переключается на новый день.
    if (state == AppLifecycleState.resumed && todayKey() != _today) setState(() => _today = todayKey());
  }

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    final today = _today;
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => showTransactionSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Расход'),
      ),
      body: Watch(
        deps: [today],
        streams: () => [
          db.watchHabits(),
          db.watchAllHabitLogs(),
          db.watchTrackers(),
          db.watchAllEntriesBetween(today, today),
          db.watchPrograms(),
          db.watchSessions(),
          db.watchJournalFor(JournalKind.day, today),
          db.watchAllSettings(),
          db.watchSleep(from: today),
          db.watchMeals(from: today, to: today),
          db.watchWater(from: today, to: today),
        ],
        builder: (context, v) => _TodayBody(
          today: today,
          habits: v[0] as List<Habit>,
          logs: v[1] as List<HabitLog>,
          trackers: v[2] as List<Tracker>,
          entriesToday: v[3] as List<TrackerEntry>,
          programs: v[4] as List<Program>,
          sessions: v[5] as List<WorkoutSession>,
          dayNote: v[6] as JournalEntry?,
          settings: v[7] as Map<String, String>,
          lastNight: (v[8] as List<SleepLog>).firstOrNull,
          food: dayFood(today, v[9] as List<Meal>, v[10] as List<WaterLog>),
        ),
      ),
    );
  }
}

class _TodayBody extends StatelessWidget {
  const _TodayBody({
    required this.today,
    required this.habits,
    required this.logs,
    required this.trackers,
    required this.entriesToday,
    required this.programs,
    required this.sessions,
    required this.dayNote,
    required this.settings,
    required this.lastNight,
    required this.food,
  });

  final int today;
  final List<Habit> habits;
  final List<HabitLog> logs;
  final List<Tracker> trackers;
  final List<TrackerEntry> entriesToday;
  final List<Program> programs;
  final List<WorkoutSession> sessions;
  final JournalEntry? dayNote;
  final Map<String, String> settings;
  final SleepLog? lastNight;
  final DayFood food;

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    final sleepGoals = SleepGoals.from(settings);
    final foodGoals = FoodGoals.from(settings);
    final badDay = settings['bad_day'] == '$today';
    final todayHabits = habits.where((h) => maskHasDay(h.daysMask, today)).toList();
    final todayTrackers = trackers.where((t) => maskHasDay(t.daysMask, today)).toList();
    final todayPrograms = programs.where((p) => maskHasDay(p.daysMask, today)).toList();
    final sessionToday = sessions.where((s) => s.day == today).firstOrNull;
    final logsToday = {for (final l in logs.where((l) => l.day == today)) l.habitId: l};
    final doneByHabit = <int, Set<int>>{};
    for (final l in logs) {
      doneByHabit.putIfAbsent(l.habitId, () => {}).add(l.day);
    }

    // Сколько дел на сегодня и сколько сделано.
    var total = todayHabits.length + todayTrackers.length;
    var done =
        todayHabits.where((h) => logsToday.containsKey(h.id)).length + todayTrackers.where((t) => dayValue(t, entriesToday) != null).length;
    if (todayPrograms.isNotEmpty) {
      total++;
      if (sessionToday != null) done++;
    }
    if (sleepGoals.onToday) {
      total++;
      if (lastNight != null) done++;
    }
    total++; // итог дня
    if (dayNote != null) done++;

    final nothingPlanned =
        todayHabits.isEmpty && todayTrackers.isEmpty && todayPrograms.isEmpty && !sleepGoals.onToday && !foodGoals.onToday;
    final habitsDone = todayHabits.where((h) => logsToday.containsKey(h.id)).length;
    final trackersDone = todayTrackers.where((t) => dayValue(t, entriesToday) != null).length;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.only(bottom: 110),
      children: [
        PageHeader(overline: formatDayLong(today), title: greeting(DateTime.now().hour)),
        HeroCard(
          colors: dark ? const [Color(0xFF4338CA), Color(0xFF7C3AED)] : const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Сделано сегодня',
                      style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text('$done из $total', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white)),
                    const SizedBox(height: 6),
                    Text(_motivation(done, total, badDay), style: const TextStyle(color: Colors.white, height: 1.3)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ProgressRing(
                value: total == 0 ? 0 : done / total,
                size: 84,
                stroke: 9,
                color: Colors.white,
                trackColor: Colors.white24,
                child: Text(
                  '${total == 0 ? 0 : (100 * done / total).round()}%',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
                ),
              ),
            ],
          ),
        ),
        Card(
          child: SwitchListTile(
            contentPadding: const EdgeInsets.fromLTRB(16, 4, 12, 4),
            secondary: const ColorIcon(Icons.battery_alert_rounded, color: Accent.reminders, size: 40),
            title: const Text('Тяжёлый день'),
            subtitle: const Text('Засчитывается минимум'),
            value: badDay,
            onChanged: (on) => db.setSetting('bad_day', on ? '$today' : null),
          ),
        ),
        if (sleepGoals.onToday || foodGoals.onToday) const SectionTitle('Сон и питание'),
        if (sleepGoals.onToday) SleepTodayCard(today: today, lastNight: lastNight, settings: settings),
        if (foodGoals.onToday) FoodTodayCard(today: today, totals: food, goals: foodGoals),
        if (nothingPlanned)
          EmptyHint(
            'На сегодня ничего не запланировано. Добавь привычки или трекеры, и они появятся здесь в нужные дни.',
            icon: Icons.wb_sunny_outlined,
            action: FilledButton.tonal(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HabitEditScreen())),
              child: const Text('Добавить привычку'),
            ),
          ),
        if (todayHabits.isNotEmpty) SectionTitle('Привычки', trailing: _Counter(habitsDone, todayHabits.length)),
        for (final h in todayHabits)
          _HabitTile(
            habit: h,
            log: logsToday[h.id],
            badDay: badDay,
            streak: currentStreak(daysMask: h.daysMask, doneDays: doneByHabit[h.id] ?? const {}, today: today),
            today: today,
          ),
        if (todayTrackers.isNotEmpty) SectionTitle('Записать', trailing: _Counter(trackersDone, todayTrackers.length)),
        for (final t in todayTrackers) TrackerTodayTile(tracker: t, value: dayValue(t, entriesToday), today: today, settings: settings),
        if (todayPrograms.isNotEmpty) ...[
          const SectionTitle('Тренировка'),
          _WorkoutCard(programs: todayPrograms, sessions: sessions, sessionToday: sessionToday, badDay: badDay),
        ],
        const SectionTitle('Вечер'),
        _ActionCard(
          icon: Icons.edit_note_rounded,
          color: Accent.journal,
          title: 'Итог дня',
          subtitle: dayNote == null
              ? '3 дела, которые сделал, и настроение'
              : 'Записан${dayNote!.mood == null ? '' : ' · настроение ${dayNote!.mood} из 10'}',
          done: dayNote != null,
          onTap: () => openJournalEditor(context, kind: JournalKind.day, day: today, existing: dayNote),
        ),
        if (dayFromKey(today).weekday == DateTime.sunday)
          _ActionCard(
            icon: Icons.insights_rounded,
            color: Accent.report,
            title: 'Обзор недели',
            subtitle: 'Посмотри итоги и запиши, что меняешь',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReportScreen(weekStartDay: weekStart(today)))),
          ),
      ],
    );
  }

  String _motivation(int done, int total, bool badDay) {
    if (total > 0 && done >= total) return 'Всё сделано. Хороший день!';
    if (badDay) return 'Сегодня хватит минимума. Это тоже засчитывается.';
    if (done == 0) return 'Начни с самого простого дела.';
    final left = total - done;
    return 'Осталось $left. Ты уже в пути.';
  }
}

String greeting(int hour) {
  if (hour >= 5 && hour < 12) return 'Доброе утро';
  if (hour >= 12 && hour < 18) return 'Добрый день';
  if (hour >= 18) return 'Добрый вечер';
  return 'Доброй ночи';
}

class _Counter extends StatelessWidget {
  const _Counter(this.done, this.total);
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Pill('$done / $total', color: done >= total ? Accent.habits : null);
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.done = false,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        leading: ColorIcon(icon, color: color),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: done ? const CheckDot(checked: true, color: Accent.habits, size: 28) : const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

class _HabitTile extends StatelessWidget {
  const _HabitTile({required this.habit, required this.log, required this.badDay, required this.streak, required this.today});
  final Habit habit;
  final HabitLog? log;
  final bool badDay;
  final int streak;
  final int today;

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    final done = log != null;
    final theme = Theme.of(context);
    final showMinimum = badDay && habit.minimumText != null && !done;
    return Card(
      child: InkWell(
        onTap: () => db.setHabitDone(habit.id, today, done: !done, minimum: badDay),
        onLongPress: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HabitDetailScreen(habitId: habit.id))),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
          child: Row(
            children: [
              ItemIcon(habit.icon),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(habit.name, style: theme.textTheme.titleMedium),
                    if (showMinimum)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text('Минимум: ${habit.minimumText}', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                      ),
                    if (streak > 0 || (done && log!.minimum))
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Wrap(
                          spacing: 6,
                          children: [
                            if (streak > 0)
                              Pill('$streak ${_days(streak)}', icon: Icons.local_fire_department_rounded, color: Accent.workouts),
                            if (done && log!.minimum) const Pill('минимум', color: Accent.reminders),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              CheckDot(checked: done, half: done && log!.minimum, color: Accent.habits),
            ],
          ),
        ),
      ),
    );
  }
}

String _days(int n) {
  final m10 = n % 10, m100 = n % 100;
  if (m10 == 1 && m100 != 11) return 'день';
  if (m10 >= 2 && m10 <= 4 && (m100 < 12 || m100 > 14)) return 'дня';
  return 'дней';
}

class _WorkoutCard extends StatelessWidget {
  const _WorkoutCard({required this.programs, required this.sessions, required this.sessionToday, required this.badDay});
  final List<Program> programs;
  final List<WorkoutSession> sessions;
  final WorkoutSession? sessionToday;
  final bool badDay;

  @override
  Widget build(BuildContext context) {
    if (sessionToday != null) {
      return _ActionCard(
        icon: Icons.fitness_center_rounded,
        color: Accent.workouts,
        title: '${sessionToday!.programName}: сделано',
        subtitle: 'Отдых и еда теперь важнее всего',
        done: true,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SessionViewScreen(sessionId: sessionToday!.id))),
      );
    }
    final theme = Theme.of(context);
    final suggested = suggestProgram(programs, sessions)!;
    final lastDay = sessions
        .where((s) => s.programId == suggested.id)
        .map((s) => s.day)
        .fold<int?>(null, (a, d) => a == null || d > a ? d : a);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const ColorIcon(Icons.fitness_center_rounded, color: Accent.workouts),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(suggested.name, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (lastDay != null) 'В прошлый раз: ${dayLabel(lastDay)}' else 'Ещё ни разу',
                          if (suggested.reminderMinutes != null) 'в ${formatMinutes(suggested.reminderMinutes!)}',
                        ].join(' · '),
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (badDay)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'Тяжёлый день: сделай хотя бы разминку и блок для спины.',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: Accent.workouts, foregroundColor: Colors.white),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SessionScreen(programId: suggested.id))),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Начать'),
                  ),
                ),
                if (programs.length > 1) ...[
                  const SizedBox(width: 8),
                  PopupMenuButton<Program>(
                    tooltip: 'Другая тренировка',
                    onSelected: (p) => Navigator.push(context, MaterialPageRoute(builder: (_) => SessionScreen(programId: p.id))),
                    itemBuilder: (_) => [
                      for (final p in programs)
                        if (p.id != suggested.id) PopupMenuItem(value: p, child: Text(p.name)),
                    ],
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: theme.colorScheme.outline),
                      ),
                      child: const Text('Другая'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
