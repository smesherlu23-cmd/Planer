import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/database.dart';
import '../data/dates.dart';
import '../data/queries.dart';
import '../logic/calc.dart';
import '../logic/day_plan.dart';
import '../logic/food.dart';
import '../logic/minimum.dart';
import '../logic/sleep.dart';
import '../logic/values.dart';
import 'common.dart';
import 'day_plan_screen.dart';
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
    return ScrollFabScope(
      child: Scaffold(
        floatingActionButton: ScrollFab(
          child: FloatingActionButton.extended(
            heroTag: null,
            onPressed: () => _showQuickAdd(context, today),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Записать'),
          ),
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
            db.watchHardDays(),
            db.watchTimeBlocks(),
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
            badDay: (v[11] as Set<int>).contains(today),
            blocks: todayBlocks(v[12] as List<TimeBlock>, v[7] as Map<String, String>),
          ),
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
    required this.badDay,
    required this.blocks,
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

  /// Тяжёлый день: всё, что отмечаешь, сохраняется как минимум.
  final bool badDay;

  /// План дня на сегодня.
  final List<PlanBlock> blocks;

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    final sleepGoals = SleepGoals.from(settings);
    final foodGoals = FoodGoals.from(settings);
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
        todayHabits.where((h) => logsToday.containsKey(h.id)).length +
        todayTrackers.where((t) => trackerCounts(t, dayValue(t, entriesToday))).length;
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
    final trackersDone = todayTrackers.where((t) => trackerCounts(t, dayValue(t, entriesToday))).length;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final sleepFirst = sleepGoals.onToday && (sleepStartedAt(settings) != null || (lastNight == null && DateTime.now().hour < 16));

    return ListView(
      padding: const EdgeInsets.only(bottom: 110),
      children: [
        PageHeader(overline: formatDayLong(today), title: greeting(DateTime.now().hour)),
        HeroCard(
          colors: dark ? const [Color(0xFF4338CA), Color(0xFF7C3AED)] : const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          child: Column(
            children: [
              Row(
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
              const SizedBox(height: 14),
              _HardDaySwitch(
                on: badDay,
                onChanged: (on) async {
                  await db.setHardDay(today, on);
                  if (on && context.mounted) showSnack(context, 'День отмечен как тяжёлый. Всё, что сделаешь, сохранится как минимум');
                },
              ),
            ],
          ),
        ),
        if (blocks.isNotEmpty) ...[const SectionTitle('По плану'), DayPlanTodayCard(blocks: blocks)],
        // Утром, пока сон не записан, и ночью с включённым таймером сон важнее всего: карточка сверху.
        if (sleepFirst) ...[const SectionTitle('Сон'), SleepTodayCard(today: today, lastNight: lastNight, settings: settings)],
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
        if ((sleepGoals.onToday && !sleepFirst) || foodGoals.onToday)
          SectionTitle(sleepGoals.onToday && !sleepFirst ? (foodGoals.onToday ? 'Сон и питание' : 'Сон') : 'Питание'),
        if (sleepGoals.onToday && !sleepFirst) SleepTodayCard(today: today, lastNight: lastNight, settings: settings),
        if (foodGoals.onToday) FoodTodayCard(today: today, totals: food, goals: foodGoals),
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

/// Быстрая запись за сегодня: всё, что обычно вносишь за день, в одном месте.
Future<void> _showQuickAdd(BuildContext context, int today) async {
  final db = context.db;
  final settings = await db.watchAllSettings().first;
  final trackers = (await db.watchTrackers().first).where((t) => maskHasDay(t.daysMask, today)).toList();
  final dayNote = await db.watchJournalFor(JournalKind.day, today).first;
  if (!context.mounted) return;
  final food = FoodGoals.from(settings);
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheet) {
      void run(Future<void> Function() action) {
        Navigator.pop(sheet);
        action();
      }

      Widget item(IconData icon, Color color, String label, Future<void> Function() action) =>
          _QuickItem(icon: icon, color: color, label: label, onTap: () => run(action));

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
              child: Text('Записать за сегодня', style: Theme.of(sheet).textTheme.titleLarge),
            ),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.05,
              children: [
                item(Icons.payments_rounded, Accent.money, 'Расход', () => showTransactionSheet(context)),
                item(Icons.restaurant_rounded, Accent.food, 'Еда', () => showEatSheet(context, day: today)),
                item(Icons.water_drop_rounded, Accent.food, 'Стакан воды', () async {
                  await addGlass(context, day: today, ml: food.glass);
                  if (context.mounted) showSnack(context, 'Записал стакан воды');
                }),
                item(Icons.bedtime_rounded, Accent.sleep, 'Сон', () => showSleepSheet(context)),
                item(
                  Icons.edit_note_rounded,
                  Accent.journal,
                  'Итог дня',
                  () => openJournalEditor(context, kind: JournalKind.day, day: today, existing: dayNote),
                ),
                for (final t in trackers)
                  item(
                    appIcon(t.icon, fallback: 'chart').icon,
                    appIcon(t.icon, fallback: 'chart').color,
                    t.name,
                    () => showEntryDialog(context, t, day: today),
                  ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

class _QuickItem extends StatelessWidget {
  const _QuickItem({required this.icon, required this.color, required this.label, required this.onTap});
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconBadge(icon, color: color, size: 44, soft: true),
              const SizedBox(height: 8),
              Text(label, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.labelLarge),
            ],
          ),
        ),
      ),
    );
  }
}

String greeting(int hour) {
  if (hour >= 5 && hour < 12) return 'Доброе утро';
  if (hour >= 12 && hour < 18) return 'Добрый день';
  if (hour >= 18) return 'Добрый вечер';
  return 'Доброй ночи';
}

/// Переключатель «Тяжёлый день» внутри главной карточки: не занимает отдельную карточку.
class _HardDaySwitch extends StatelessWidget {
  const _HardDaySwitch({required this.on, required this.onChanged});
  final bool on;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: on ? 0.24 : 0.14),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onChanged(!on),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
          child: Row(
            children: [
              Icon(on ? Icons.battery_alert_rounded : Icons.battery_full_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Тяжёлый день',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      on ? 'Засчитывается минимум' : 'Мало сил? Хватит минимума',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Switch(
                value: on,
                onChanged: onChanged,
                activeThumbColor: const Color(0xFF6366F1),
                activeTrackColor: Colors.white,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: Colors.white24,
                trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
        onTap: () {
          HapticFeedback.lightImpact();
          db.setHabitDone(habit.id, today, done: !done, minimum: badDay);
        },
        onLongPress: () => _markSheet(context),
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

extension on _HabitTile {
  /// Долгое нажатие: выбрать, как сделано, или открыть привычку.
  Future<void> _markSheet(BuildContext context) async {
    final db = context.db;
    final done = log != null;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) {
        Widget option(IconData icon, String title, String? subtitle, bool selected, VoidCallback onTap) => ListTile(
          leading: Icon(icon, color: selected ? Accent.habits : null),
          title: Text(title),
          subtitle: subtitle == null ? null : Text(subtitle),
          trailing: selected ? const Icon(Icons.check_rounded, color: Accent.habits) : null,
          onTap: () {
            Navigator.pop(sheet);
            onTap();
          },
        );
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(habit.name, style: Theme.of(sheet).textTheme.titleLarge),
              ),
              option(
                Icons.check_circle_rounded,
                'Сделано полностью',
                null,
                done && !log!.minimum,
                () => db.setHabitDone(habit.id, today, done: true),
              ),
              option(
                Icons.contrast_rounded,
                'Сделан минимум',
                habit.minimumText,
                done && log!.minimum,
                () => db.setHabitDone(habit.id, today, done: true, minimum: true),
              ),
              option(Icons.radio_button_unchecked_rounded, 'Не сделано', null, !done, () => db.setHabitDone(habit.id, today, done: false)),
              const Divider(),
              option(
                Icons.insights_rounded,
                'Открыть привычку',
                'История и настройки',
                false,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => HabitDetailScreen(habitId: habit.id))),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

String _setsLabel(int n) => n == 1 ? '1 подход' : (n < 5 ? '$n подхода' : '$n подходов');

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
        title: '${sessionToday!.programName}: ${sessionToday!.minimum ? 'сделан минимум' : 'сделано'}',
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
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Accent.reminders.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                child: Text(
                  [
                    'Тяжёлый день: хватит облегчённой версии, ${_setsLabel(suggested.minSets ?? 1)} на упражнение.',
                    ?suggested.minimumText,
                  ].join(' '),
                  style: const TextStyle(height: 1.35),
                ),
              ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: Accent.workouts, foregroundColor: Colors.white),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SessionScreen(programId: suggested.id, light: badDay),
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(badDay ? 'Минимум' : 'Начать'),
                  ),
                ),
                if (programs.length > 1) ...[
                  const SizedBox(width: 8),
                  PopupMenuButton<Program>(
                    tooltip: 'Другая тренировка',
                    onSelected: (p) => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SessionScreen(programId: p.id, light: badDay),
                      ),
                    ),
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
