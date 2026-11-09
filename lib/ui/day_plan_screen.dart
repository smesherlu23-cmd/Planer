import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import '../data/database.dart';
import '../data/dates.dart';
import '../data/icon_keys.dart';
import '../data/queries.dart';
import '../logic/day_plan.dart';
import '../logic/sleep.dart';
import 'common.dart';
import 'icons.dart';
import 'sleep_screen.dart';
import 'theme.dart';

Color kindColor(BlockKind k) => switch (k) {
  BlockKind.sleep => Accent.sleep,
  BlockKind.work => const Color(0xFFB45309),
  BlockKind.study => const Color(0xFF6366F1),
  BlockKind.sport => const Color(0xFFF97316),
  BlockKind.rest => const Color(0xFF22C55E),
  BlockKind.home => const Color(0xFF14B8A6),
  BlockKind.road => const Color(0xFF64748B),
  BlockKind.food => const Color(0xFFEAB308),
  BlockKind.other => const Color(0xFF94A3B8),
};

int _nowMinute() => DateTime.now().hour * 60 + DateTime.now().minute;

class DayPlanScreen extends StatefulWidget {
  const DayPlanScreen({super.key});

  @override
  State<DayPlanScreen> createState() => _DayPlanScreenState();
}

class _DayPlanScreenState extends State<DayPlanScreen> {
  var _weekday = DateTime.now().weekday;

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    return Watch(
      streams: () => [db.watchTimeBlocks(), db.watchAllSettings()],
      builder: (context, v) {
        final all = v[0] as List<TimeBlock>;
        final sleepGoals = SleepGoals.from(v[1] as Map<String, String>);
        final blocks = blocksForWeekday(all, _weekday, sleep: sleepGoals.onToday ? sleepGoals : null);
        final isToday = _weekday == DateTime.now().weekday;
        return Scaffold(
          appBar: AppBar(title: const Text('План дня')),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: null,
            onPressed: () => showBlockSheet(context, weekday: _weekday, after: blocks.where((b) => b.kind != BlockKind.sleep).lastOrNull),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Блок'),
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 110),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Row(
                  children: [
                    for (var w = 1; w <= 7; w++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: _DayChip(
                            label: weekdayShort[w - 1],
                            selected: w == _weekday,
                            today: w == DateTime.now().weekday,
                            onTap: () => setState(() => _weekday = w),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              _SplitCard(blocks: blocks, isToday: isToday),
              if (blocks.isEmpty)
                const Card(
                  child: EmptyHint(
                    'Разложи день на блоки: работа, код, спорт, отдых. Здесь будет видно, куда уходят сутки и что сейчас по плану.',
                    icon: Icons.view_timeline_outlined,
                  ),
                ),
              if (blocks.isNotEmpty) ...[
                SectionTitle(isToday ? 'Сегодня по плану' : 'По плану'),
                GroupCard(
                  children: [
                    for (final (i, b) in blocks.indexed) ...[
                      _BlockTile(block: b, now: isToday && b.contains(_nowMinute())),
                      if (gapAfter(blocks, i) case final gap when gap >= 10) _GapTile(start: b.end, minutes: gap),
                    ],
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 10, 24, 0),
                  child: Text('Нажми на блок, чтобы изменить время или дни. Сон берётся из раздела «Сон».'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.label, required this.selected, required this.today, required this.onTap});
  final String label;
  final bool selected;
  final bool today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primary : scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(fontWeight: FontWeight.w600, color: selected ? scheme.onPrimary : scheme.onSurface),
              ),
              const SizedBox(height: 3),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: today ? (selected ? scheme.onPrimary : scheme.primary) : Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Распределение суток: полоса на 24 часа и подписи по видам.
class _SplitCard extends StatelessWidget {
  const _SplitCard({required this.blocks, required this.isToday});
  final List<PlanBlock> blocks;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final d = distribution(blocks);
    final kinds = d.byKind.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final cur = isToday ? currentBlocks(blocks, _nowMinute()) : null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (cur != null && (cur.now != null || cur.next != null)) ...[
              _NowLine(now: cur.now, next: cur.next),
              const SizedBox(height: 14),
            ],
            Text('Сутки по плану', style: theme.textTheme.titleSmall?.copyWith(color: muted)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 18,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final e in kinds)
                      Expanded(
                        flex: e.value,
                        child: ColoredBox(color: kindColor(e.key)),
                      ),
                    if (d.free > 0)
                      Expanded(
                        flex: d.free,
                        child: ColoredBox(color: theme.colorScheme.surfaceContainerHighest),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 14,
              runSpacing: 8,
              children: [
                for (final e in kinds) _Legend(color: kindColor(e.key), label: e.key.label, minutes: e.value),
                if (d.free > 0) _Legend(color: theme.colorScheme.surfaceContainerHighest, label: 'Свободно', minutes: d.free),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NowLine extends StatelessWidget {
  const _NowLine({required this.now, required this.next});
  final PlanBlock? now;
  final PlanBlock? next;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final n = now;
    return Row(
      children: [
        if (n != null)
          ItemIcon(n.icon, size: 44, fallback: n.kind.defaultIcon)
        else
          const ColorIcon(Icons.free_breakfast_rounded, color: Accent.habits),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(n == null ? 'Сейчас свободно' : 'Сейчас: ${n.name}', style: theme.textTheme.titleMedium),
              Text(
                [
                  if (n != null) 'до ${formatMinutes(n.end)}',
                  if (next != null) 'дальше ${next!.name} в ${formatMinutes(next!.start)}',
                ].join(' · '),
                style: TextStyle(color: muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label, required this.minutes});
  final Color color;
  final String label;
  final int minutes;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text('$label ', style: const TextStyle(fontSize: 13)),
        Text(formatDuration(minutes), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _BlockTile extends StatelessWidget {
  const _BlockTile({required this.block, required this.now});
  final PlanBlock block;
  final bool now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final b = block;
    final color = kindColor(b.kind);
    return InkWell(
      onTap: () => b.source == null
          ? Navigator.push(context, MaterialPageRoute(builder: (_) => const SleepScreen()))
          : showBlockSheet(context, existing: b.source),
      child: Container(
        color: now ? color.withValues(alpha: 0.1) : null,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 46,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formatMinutes(b.start),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()]),
                    ),
                    Text(
                      formatMinutes(b.end),
                      style: TextStyle(fontSize: 12, color: muted, fontFeatures: const [FontFeature.tabularFigures()]),
                    ),
                  ],
                ),
              ),
              Container(
                width: 4,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
              ),
              ItemIcon(b.icon, size: 40, fallback: b.kind.defaultIcon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(b.name, style: theme.textTheme.titleMedium),
                    Text(
                      [formatDuration(b.minutes), b.kind.label, if (b.source?.remind ?? false) 'с напоминанием'].join(' · '),
                      style: TextStyle(color: muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (now) Center(child: Pill('сейчас', color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _GapTile extends StatelessWidget {
  const _GapTile({required this.start, required this.minutes});
  final int start;
  final int minutes;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          SizedBox(
            width: 46,
            child: Text(formatMinutes(start), style: TextStyle(fontSize: 12, color: muted)),
          ),
          const SizedBox(width: 24),
          Icon(Icons.more_horiz_rounded, size: 18, color: muted),
          const SizedBox(width: 8),
          Text('Свободно ${formatDuration(minutes)}', style: TextStyle(color: muted, fontSize: 13)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Блок: создание и изменение
// ---------------------------------------------------------------------------

Future<void> showBlockSheet(BuildContext context, {TimeBlock? existing, int? weekday, PlanBlock? after}) {
  final name = TextEditingController(text: existing?.name ?? '');
  var kind = existing?.kind ?? BlockKind.study;
  var icon = iconKeyFor(existing?.icon) ?? kind.defaultIcon;
  var iconTouched = existing != null;
  var start = existing?.start ?? after?.end ?? 18 * 60;
  var end = existing?.end ?? (start + 60) % minutesInDay;
  var mask = existing?.daysMask ?? (weekday == null ? everyDay : (weekday <= 5 ? weekdaysOnly : 1 << (weekday - 1)));
  var remind = existing?.remind ?? false;
  return showFormSheet(
    context,
    (sheet) => StatefulBuilder(
      builder: (sheet, setState) {
        Future<void> pick(bool isStart) async {
          final m = isStart ? start : end;
          final t = await showTimePicker(
            context: sheet,
            initialTime: TimeOfDay(hour: m ~/ 60, minute: m % 60),
          );
          if (t == null) return;
          setState(() {
            final v = t.hour * 60 + t.minute;
            if (isStart) {
              // Сдвигаем конец вместе с началом, чтобы длительность сохранилась.
              final len = blockMinutes(start, end);
              start = v;
              end = (v + len) % minutesInDay;
            } else {
              end = v;
            }
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(existing == null ? 'Новый блок' : 'Блок', style: Theme.of(sheet).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              children: [
                IconField(
                  value: icon,
                  fallback: kind.defaultIcon,
                  onChanged: (v) => setState(() {
                    icon = v;
                    iconTouched = true;
                  }),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: name,
                    autofocus: existing == null,
                    decoration: const InputDecoration(labelText: 'Название', hintText: 'Например: Код'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final k in BlockKind.values)
                  ChoiceChip(
                    showCheckmark: false,
                    avatar: CircleAvatar(backgroundColor: kindColor(k), radius: 5),
                    label: Text(k.label),
                    selected: kind == k,
                    onSelected: (_) => setState(() {
                      kind = k;
                      if (!iconTouched) icon = k.defaultIcon;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _TimeButton(label: 'Начало', minutes: start, onTap: () => pick(true)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TimeButton(label: 'Конец', minutes: end, onTap: () => pick(false)),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Длительность: ${formatDuration(blockMinutes(start, end))}', textAlign: TextAlign.center),
            ),
            const SizedBox(height: 12),
            DaysPicker(mask: mask, onChanged: (m) => setState(() => mask = m)),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Напомнить в начале'),
              value: remind,
              onChanged: (v) => setState(() => remind = v),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () async {
                final n = name.text.trim().isEmpty ? kind.label : name.text.trim();
                if (mask == 0) return showSnack(sheet, 'Выбери хотя бы один день');
                await sheet.db.saveTimeBlock(
                  TimeBlocksCompanion(
                    id: existing == null ? const Value.absent() : Value(existing.id),
                    name: Value(n),
                    icon: Value(icon),
                    kind: Value(kind),
                    start: Value(start),
                    end: Value(end),
                    daysMask: Value(mask),
                    remind: Value(remind),
                  ),
                );
                if (sheet.mounted) Navigator.pop(sheet);
              },
              child: const Text('Сохранить'),
            ),
            if (existing != null)
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: Theme.of(sheet).colorScheme.error),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Удалить блок'),
                onPressed: () async {
                  await sheet.db.deleteById(sheet.db.timeBlocks, existing.id);
                  if (sheet.mounted) Navigator.pop(sheet);
                },
              ),
          ],
        );
      },
    ),
  );
}

class _TimeButton extends StatelessWidget {
  const _TimeButton({required this.label, required this.minutes, required this.onTap});
  final String label;
  final int minutes;
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              Text(formatMinutes(minutes), style: theme.textTheme.titleLarge?.copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
            ],
          ),
        ),
      ),
    );
  }
}

/// Карточка на «Сегодня»: что сейчас по плану и что дальше.
class DayPlanTodayCard extends StatelessWidget {
  const DayPlanTodayCard({super.key, required this.blocks});
  final List<PlanBlock> blocks;

  @override
  Widget build(BuildContext context) {
    return Every(
      const Duration(minutes: 1),
      builder: (context) {
        final minute = _nowMinute();
        final cur = currentBlocks(blocks, minute);
        final n = cur.now;
        final progress = n == null ? null : ((minute - n.start) % minutesInDay) / n.minutes;
        return Card(
          child: InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DayPlanScreen())),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                children: [
                  _NowLine(now: n, next: cur.next),
                  if (progress != null) ...[
                    const SizedBox(height: 10),
                    ProgressLine(value: progress, color: kindColor(n!.kind), height: 6),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Блоки на сегодня для карточки на «Сегодня».
List<PlanBlock> todayBlocks(List<TimeBlock> all, Map<String, String> settings) {
  final sleep = SleepGoals.from(settings);
  if (all.isEmpty) return const [];
  return blocksForWeekday(all, DateTime.now().weekday, sleep: sleep.onToday ? sleep : null);
}
