import 'package:flutter/material.dart';

import '../data/database.dart';
import '../data/dates.dart';
import '../data/queries.dart';
import '../data/time_queries.dart';
import '../logic/day_plan.dart';
import '../logic/focus.dart';
import '../logic/tasks.dart';
import 'common.dart';
import 'day_plan_screen.dart';
import 'tasks_screen.dart';

const _focusColor = Color(0xFF6366F1);
const _breakColor = Color(0xFF22C55E);

/// Вкладка «Фокус»: таймер помидора, привязанный к задаче, и записи за день.
class FocusTab extends StatefulWidget {
  const FocusTab({super.key});

  @override
  State<FocusTab> createState() => _FocusTabState();
}

class _FocusTabState extends State<FocusTab> {
  /// Чем закончился последний отрезок, пока экран открыт: для кнопок «Перерыв» и «Ещё круг».
  ({int minutes, int round, int? taskId, BlockKind? kind})? _finished;
  var _finishing = false;
  int? _pickedTask;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    if (_finishing) return;
    _finishing = true;
    final db = context.db;
    final before = await db.focusState();
    final m = await db.finishFocusIfDue();
    _finishing = false;
    if (m != null && before != null && mounted) {
      setState(() => _finished = before.isBreak ? null : (minutes: m, round: before.round, taskId: before.taskId, kind: before.kind));
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    final today = todayKey();
    return Watch(
      streams: () => [
        db.watchSetting(focusSettingKey),
        db.watchTasks(),
        db.watchFocus(from: addDays(today, -60)),
        db.watchSetting('focus_minutes'),
        db.watchSetting('break_minutes'),
      ],
      builder: (context, v) {
        final state = FocusState.decode(v[0] as String?);
        final tasks = v[1] as List<Task>;
        final sessions = v[2] as List<FocusSession>;
        final focusMinutes = int.tryParse(v[3] as String? ?? '') ?? 25;
        final breakMinutes = int.tryParse(v[4] as String? ?? '') ?? 5;
        final byId = {for (final t in tasks) t.id: t};
        final todaySessions = sessions.where((s) => s.day == today).toList();
        final todayTotal = todaySessions.fold(0, (a, s) => a + s.minutes);
        final streak = focusStreak(sessions, today);
        final taskId = state?.taskId ?? _pickedTask;
        final task = taskId == null ? null : byId[taskId];

        return Scaffold(
          appBar: AppBar(title: const Text('Фокус')),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
                  child: Every(
                    const Duration(seconds: 1),
                    builder: (context) {
                      final now = DateTime.now();
                      if (state != null && state.finished(now)) WidgetsBinding.instance.addPostFrameCallback((_) => _check());
                      return _TimerPanel(
                        state: state,
                        now: now,
                        idleMinutes: focusMinutes,
                        task: task,
                        finished: state == null ? _finished : null,
                        breakMinutes: breakMinutes,
                        onPickTask: state == null ? () => _pickTask(context, tasks) : null,
                        onPreset: (m) => db.setSetting('focus_minutes', '$m'),
                        onBreakPreset: (m) => db.setSetting('break_minutes', '$m'),
                        onStart: () async {
                          final f = _finished;
                          setState(() => _finished = null);
                          await db.setFocusState(
                            FocusState.start(minutes: focusMinutes, taskId: taskId, kind: task?.kind, round: f == null ? 1 : f.round + 1),
                          );
                        },
                        onBreak: (minutes) async {
                          final f = _finished;
                          setState(() => _finished = null);
                          await db.setFocusState(
                            FocusState.start(minutes: minutes, isBreak: true, taskId: f?.taskId, round: f?.round ?? 1),
                          );
                        },
                        onPause: () => db.setFocusState(state!.pause(DateTime.now())),
                        onResume: () => db.setFocusState(state!.resume(DateTime.now())),
                        onStop: () async {
                          final m = await db.stopFocus();
                          if (context.mounted && m > 0) showSnack(context, 'Записано ${formatDuration(m)}');
                        },
                        onTaskDone: task == null || task.doneDay != null
                            ? null
                            : () async {
                                await db.setTaskDone(task, true);
                                setState(() => _pickedTask = null);
                                if (context.mounted) showSnack(context, 'Задача сделана');
                              },
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: _Stat(label: 'Сегодня', value: todayTotal == 0 ? '—' : formatDuration(todayTotal)),
                    ),
                    Expanded(
                      child: _Stat(label: 'Отрезков', value: '${todaySessions.length}'),
                    ),
                    Expanded(
                      child: _Stat(label: 'Дней подряд', value: '$streak'),
                    ),
                  ],
                ),
              ),
              if (todaySessions.isNotEmpty) ...[
                const SectionTitle('Сегодня'),
                GroupCard(
                  children: [
                    for (final s in todaySessions)
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: (s.kind == null ? _focusColor : kindColor(s.kind!)).withValues(alpha: 0.15),
                          child: Icon(Icons.timer_outlined, color: s.kind == null ? _focusColor : kindColor(s.kind!)),
                        ),
                        title: Text(byId[s.taskId]?.title ?? s.kind?.label ?? 'Без задачи'),
                        subtitle: Text('${formatMinutes(s.at.hour * 60 + s.at.minute)} · ${formatDuration(s.minutes)}'),
                        trailing: IconButton(
                          tooltip: 'Удалить запись',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => db.deleteById(db.focusSessions, s.id),
                        ),
                      ),
                  ],
                ),
              ],
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Text(
                  'Как это работает: выбери одну задачу, убери телефон и работай до сигнала. '
                  'Потом короткий перерыв, после четырёх кругов длинный. '
                  'Таймер идёт, даже если закрыть приложение.',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickTask(BuildContext context, List<Task> all) async {
    final today = todayKey();
    final t = todayTasks(all, today);
    final list = t.open;
    final picked = await showModalBottomSheet<int>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheet) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Text('Над чем работаешь', style: Theme.of(sheet).textTheme.titleLarge),
          ),
          ListTile(
            leading: const Icon(Icons.do_not_disturb_on_outlined),
            title: const Text('Без задачи'),
            onTap: () => Navigator.pop(sheet, -1),
          ),
          for (final x in list)
            ListTile(
              leading: Icon(Icons.flag_rounded, color: priorityColor(x.priority, Theme.of(sheet).colorScheme)),
              title: Text(x.title),
              subtitle: Text(
                [
                  if (x.day != null && x.day != today) dayLabel(x.day!, today: today),
                  if (x.estimate != null) formatDuration(x.estimate!),
                  if (x.kind != null) x.kind!.label,
                ].join(' · '),
              ),
              onTap: () => Navigator.pop(sheet, x.id),
            ),
          if (list.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Text('На сегодня задач нет. Добавь их на вкладке «Задачи».')),
        ],
      ),
    );
    if (picked != null) setState(() => _pickedTask = picked == -1 ? null : picked);
  }
}

class _TimerPanel extends StatelessWidget {
  const _TimerPanel({
    required this.state,
    required this.now,
    required this.idleMinutes,
    required this.breakMinutes,
    required this.task,
    required this.finished,
    required this.onPickTask,
    required this.onPreset,
    required this.onBreakPreset,
    required this.onStart,
    required this.onBreak,
    required this.onPause,
    required this.onResume,
    required this.onStop,
    required this.onTaskDone,
  });

  final FocusState? state;
  final DateTime now;
  final int idleMinutes;
  final int breakMinutes;
  final Task? task;
  final ({int minutes, int round, int? taskId, BlockKind? kind})? finished;
  final VoidCallback? onPickTask;
  final ValueChanged<int> onPreset;
  final ValueChanged<int> onBreakPreset;
  final VoidCallback onStart;
  final ValueChanged<int> onBreak;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;
  final VoidCallback? onTaskDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final s = state;
    final color = s?.isBreak ?? false ? _breakColor : _focusColor;
    final total = (s?.minutes ?? idleMinutes) * 60;
    final left = s?.secondsLeft(now) ?? total;
    final f = finished;
    final longBreak = f != null && f.round % 4 == 0;
    final status = switch (s) {
      null => f == null ? 'Готов начать' : 'Круг ${f.round} готов: +${formatDuration(f.minutes)}',
      _ when s.paused => 'Пауза',
      _ when s.isBreak => 'Перерыв',
      _ => 'Фокус · круг ${s.round}',
    };
    return Column(
      children: [
        ProgressRing(
          value: s == null ? (f == null ? 0 : 1) : 1 - left / total,
          size: 230,
          stroke: 14,
          color: color,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatClock(left),
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(status, style: TextStyle(color: muted)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ActionChip(
          avatar: Icon(task == null ? Icons.add_task_rounded : Icons.task_alt_rounded, size: 18),
          label: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Text(task?.title ?? 'Выбрать задачу', overflow: TextOverflow.ellipsis),
          ),
          onPressed: onPickTask,
        ),
        const SizedBox(height: 14),
        if (s == null && f == null) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              for (final m in focusPresets) ChoiceChip(label: Text('$m мин'), selected: idleMinutes == m, onSelected: (_) => onPreset(m)),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size(200, 52)),
            onPressed: onStart,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Начать'),
          ),
        ] else if (s == null && f != null) ...[
          Text(
            longBreak ? 'Четыре круга позади. Пора на длинный перерыв, минут 15.' : 'Отдохни пару минут, потом следующий круг.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              for (final m in breakPresets)
                ChoiceChip(label: Text('$m мин'), selected: breakMinutes == m, onSelected: (_) => onBreakPreset(m)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.tonalIcon(
                onPressed: () => onBreak(breakMinutes),
                icon: const Icon(Icons.local_cafe_outlined),
                label: const Text('Перерыв'),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(onPressed: onStart, icon: const Icon(Icons.replay_rounded), label: const Text('Ещё круг')),
            ],
          ),
        ] else
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (s!.paused)
                FilledButton.icon(onPressed: onResume, icon: const Icon(Icons.play_arrow_rounded), label: const Text('Дальше'))
              else
                FilledButton.tonalIcon(onPressed: onPause, icon: const Icon(Icons.pause_rounded), label: const Text('Пауза')),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: onStop,
                icon: const Icon(Icons.stop_rounded),
                label: Text(s.isBreak ? 'Хватит отдыхать' : 'Стоп'),
              ),
            ],
          ),
        if (onTaskDone != null && (s == null || !s.isBreak)) ...[
          const SizedBox(height: 6),
          TextButton.icon(onPressed: onTaskDone, icon: const Icon(Icons.check_rounded), label: const Text('Задача сделана')),
        ],
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.all(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: theme.textTheme.titleLarge),
            ),
          ],
        ),
      ),
    );
  }
}

/// Короткая строка про идущий таймер для других экранов модуля.
class FocusBanner extends StatelessWidget {
  const FocusBanner({super.key, required this.state, required this.task, required this.onTap});
  final FocusState state;
  final Task? task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = state.isBreak ? _breakColor : _focusColor;
    return Every(
      const Duration(seconds: 1),
      builder: (context) => Card(
        color: color.withValues(alpha: 0.12),
        child: ListTile(
          onTap: onTap,
          leading: Icon(state.isBreak ? Icons.local_cafe_outlined : Icons.timer_outlined, color: color),
          title: Text(state.isBreak ? 'Перерыв' : (task?.title ?? 'Фокус')),
          trailing: Text(
            formatClock(state.secondsLeft(DateTime.now())),
            style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 18, fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ),
      ),
    );
  }
}
