import 'package:flutter/material.dart';

import '../data/database.dart';
import '../data/dates.dart';
import '../data/queries.dart';
import '../logic/calc.dart';
import '../logic/values.dart';
import 'common.dart';
import 'habits_screen.dart';
import 'journal_screen.dart';
import 'money_screen.dart';
import 'report_screen.dart';
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
      appBar: AppBar(
        title: const Text('Сегодня'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Align(alignment: Alignment.centerLeft, child: Text(formatDayLong(today))),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => showTransactionSheet(context),
        icon: const Icon(Icons.add),
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

  @override
  Widget build(BuildContext context) {
    final db = context.db;
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
    total++; // итог дня
    if (dayNote != null) done++;

    final nothingPlanned = todayHabits.isEmpty && todayTrackers.isEmpty && todayPrograms.isEmpty;

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  done == total ? 'Всё сделано. Хороший день 💪' : 'Сделано $done из $total',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ProgressLine(value: total == 0 ? 0 : done / total),
              ],
            ),
          ),
        ),
        Card(
          child: SwitchListTile(
            secondary: const Icon(Icons.battery_2_bar),
            title: const Text('Тяжёлый день'),
            subtitle: const Text('Хватит минимума. Главное не обнулять цепочку'),
            value: badDay,
            onChanged: (on) => db.setSetting('bad_day', on ? '$today' : null),
          ),
        ),
        if (nothingPlanned)
          EmptyHint(
            'На сегодня ничего не запланировано. Добавь привычки или трекеры, и они появятся здесь в нужные дни.',
            action: FilledButton.tonal(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HabitEditScreen())),
              child: const Text('Добавить привычку'),
            ),
          ),
        if (todayHabits.isNotEmpty) const SectionTitle('Привычки'),
        for (final h in todayHabits)
          _HabitTile(
            habit: h,
            log: logsToday[h.id],
            badDay: badDay,
            streak: currentStreak(daysMask: h.daysMask, doneDays: doneByHabit[h.id] ?? const {}, today: today),
            today: today,
          ),
        if (todayTrackers.isNotEmpty) const SectionTitle('Записать'),
        for (final t in todayTrackers) TrackerTodayTile(tracker: t, value: dayValue(t, entriesToday), today: today, settings: settings),
        if (todayPrograms.isNotEmpty) ...[
          const SectionTitle('Тренировка'),
          _WorkoutCard(programs: todayPrograms, sessions: sessions, sessionToday: sessionToday, badDay: badDay),
        ],
        const SectionTitle('Вечер'),
        Card(
          child: ListTile(
            leading: Icon(dayNote == null ? Icons.edit_note : Icons.check_circle, color: dayNote == null ? null : Colors.green),
            title: const Text('Итог дня'),
            subtitle: Text(
              dayNote == null
                  ? '3 дела, которые сделал, и настроение'
                  : 'Записан${dayNote!.mood == null ? '' : ', настроение ${dayNote!.mood} из 10'}',
            ),
            onTap: () => openJournalEditor(context, kind: JournalKind.day, day: today, existing: dayNote),
          ),
        ),
        if (dayFromKey(today).weekday == DateTime.sunday)
          Card(
            child: ListTile(
              leading: const Icon(Icons.insights),
              title: const Text('Обзор недели'),
              subtitle: const Text('Посмотри итоги и запиши, что меняешь'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReportScreen(weekStartDay: weekStart(today)))),
            ),
          ),
      ],
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
    final subtitle = <String>[
      if (badDay && habit.minimumText != null) 'Минимум: ${habit.minimumText}',
      if (done && log!.minimum) 'засчитан минимум',
      if (streak > 0) '🔥 $streak подряд',
    ];
    return Card(
      child: ListTile(
        leading: EmojiAvatar(habit.icon),
        title: Text(habit.name, style: done ? const TextStyle(decoration: TextDecoration.lineThrough) : null),
        subtitle: subtitle.isEmpty ? null : Text(subtitle.join(' · ')),
        trailing: Checkbox(
          value: done,
          onChanged: (v) => db.setHabitDone(habit.id, today, done: v ?? false, minimum: badDay),
        ),
        onTap: () => db.setHabitDone(habit.id, today, done: !done, minimum: badDay),
        onLongPress: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HabitDetailScreen(habitId: habit.id))),
      ),
    );
  }
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
      return Card(
        child: ListTile(
          leading: const Icon(Icons.check_circle, color: Colors.green),
          title: Text('${sessionToday!.programName}: сделано'),
          subtitle: const Text('Отдых и еда теперь важнее всего'),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SessionViewScreen(sessionId: sessionToday!.id))),
        ),
      );
    }
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
            Text(suggested.name, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              [
                if (lastDay != null) 'В прошлый раз: ${dayLabel(lastDay)}' else 'Ещё ни разу',
                if (suggested.reminderMinutes != null) 'в ${formatMinutes(suggested.reminderMinutes!)}',
              ].join(' · '),
            ),
            if (badDay)
              const Padding(padding: EdgeInsets.only(top: 4), child: Text('Тяжёлый день: сделай хотя бы разминку и блок для спины.')),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SessionScreen(programId: suggested.id))),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Начать'),
                ),
                const SizedBox(width: 8),
                if (programs.length > 1)
                  PopupMenuButton<Program>(
                    tooltip: 'Другая тренировка',
                    onSelected: (p) => Navigator.push(context, MaterialPageRoute(builder: (_) => SessionScreen(programId: p.id))),
                    itemBuilder: (_) => [
                      for (final p in programs)
                        if (p.id != suggested.id) PopupMenuItem(value: p, child: Text(p.name)),
                    ],
                    child: const Padding(padding: EdgeInsets.all(8), child: Text('Другая')),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
