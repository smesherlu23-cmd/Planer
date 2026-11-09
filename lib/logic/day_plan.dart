/// План дня: блоки времени, распределение суток и «что сейчас».
library;

import '../data/database.dart';
import '../data/dates.dart';
import 'sleep.dart';

const minutesInDay = 24 * 60;

extension BlockKindLabel on BlockKind {
  String get label => switch (this) {
    BlockKind.sleep => 'Сон',
    BlockKind.work => 'Работа',
    BlockKind.study => 'Учёба и код',
    BlockKind.sport => 'Спорт',
    BlockKind.rest => 'Отдых',
    BlockKind.home => 'Дом и дела',
    BlockKind.road => 'Дорога',
    BlockKind.food => 'Еда',
    BlockKind.other => 'Другое',
  };

  /// Иконка по умолчанию для нового блока этого вида.
  String get defaultIcon => switch (this) {
    BlockKind.sleep => 'bedtime',
    BlockKind.work => 'work',
    BlockKind.study => 'code',
    BlockKind.sport => 'fitness',
    BlockKind.rest => 'game',
    BlockKind.home => 'house',
    BlockKind.road => 'bus',
    BlockKind.food => 'restaurant',
    BlockKind.other => 'clock',
  };
}

/// Блок на конкретный день: из таблицы или сон из раздела «Сон».
class PlanBlock {
  const PlanBlock({required this.name, required this.icon, required this.kind, required this.start, required this.end, this.source});

  factory PlanBlock.of(TimeBlock b) => PlanBlock(name: b.name, icon: b.icon, kind: b.kind, start: b.start, end: b.end, source: b);

  final String name;
  final String icon;
  final BlockKind kind;
  final int start;
  final int end;

  /// null у сна, который берётся из целей раздела «Сон».
  final TimeBlock? source;

  /// Длительность в минутах. Конец раньше начала: блок идёт через полночь.
  int get minutes => blockMinutes(start, end);

  bool contains(int minute) => (minute - start) % minutesInDay < minutes;
}

int blockMinutes(int start, int end) {
  final d = (end - start) % minutesInDay;
  return d == 0 ? minutesInDay : d;
}

/// Блоки на день недели (1 = понедельник), по порядку от утра. Сон из раздела «Сон» добавляется, если он включён.
List<PlanBlock> blocksForWeekday(Iterable<TimeBlock> all, int weekday, {SleepGoals? sleep}) {
  final list = [
    for (final b in all)
      if (maskHasWeekday(b.daysMask, weekday)) PlanBlock.of(b),
    if (sleep != null && !all.any((b) => b.kind == BlockKind.sleep && maskHasWeekday(b.daysMask, weekday)))
      PlanBlock(name: 'Сон', icon: 'bedtime', kind: BlockKind.sleep, start: sleep.bed, end: sleep.wake),
  ];
  // День начинается с подъёма: так сон оказывается в конце списка, а не посередине.
  final anchor = sleep?.wake ?? list.where((b) => b.kind == BlockKind.sleep).map((b) => b.end).firstOrNull ?? 0;
  list.sort((a, b) => ((a.start - anchor) % minutesInDay).compareTo((b.start - anchor) % minutesInDay));
  return list;
}

/// Сколько минут суток уходит на каждый вид. Пересечения не считаются дважды: минуту забирает блок, что идёт позже в списке.
({Map<BlockKind, int> byKind, int free}) distribution(List<PlanBlock> blocks) {
  final owner = List<BlockKind?>.filled(minutesInDay, null);
  for (final b in blocks) {
    for (var i = 0; i < b.minutes; i++) {
      owner[(b.start + i) % minutesInDay] = b.kind;
    }
  }
  final byKind = <BlockKind, int>{};
  var free = 0;
  for (final k in owner) {
    if (k == null) {
      free++;
    } else {
      byKind[k] = (byKind[k] ?? 0) + 1;
    }
  }
  return (byKind: byKind, free: free);
}

/// Блок, который идёт сейчас, и следующий за ним.
({PlanBlock? now, PlanBlock? next}) currentBlocks(List<PlanBlock> blocks, int minute) {
  PlanBlock? now;
  for (final b in blocks) {
    if (b.contains(minute)) now = b;
  }
  PlanBlock? next;
  var best = minutesInDay + 1;
  for (final b in blocks) {
    if (identical(b, now)) continue;
    final until = (b.start - minute) % minutesInDay;
    if (until > 0 && until < best) {
      best = until;
      next = b;
    }
  }
  return (now: now, next: next);
}

/// Сколько свободных минут после блока [i] до следующего. 0, если следующий начинается сразу или блоки пересекаются.
int gapAfter(List<PlanBlock> blocks, int i) {
  if (blocks.length < 2) return 0;
  final cur = blocks[i];
  final next = blocks[(i + 1) % blocks.length];
  final gap = (next.start - cur.end) % minutesInDay;
  return gap < minutesInDay - cur.minutes ? gap : 0;
}
