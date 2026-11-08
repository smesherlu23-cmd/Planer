import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/dates.dart';
import '../logic/calc.dart';

/// Простой линейный график значений по дням.
class LineChart extends StatelessWidget {
  const LineChart({super.key, required this.points, this.height = 180, this.target});

  final List<(int day, double value)> points;
  final double height;

  /// Линия цели, если есть.
  final double? target;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (points.length < 2) {
      return SizedBox(
        height: height / 2,
        child: Center(
          child: Text('Для графика нужно хотя бы 2 дня с записями', style: TextStyle(color: scheme.onSurfaceVariant)),
        ),
      );
    }
    return SizedBox(
      height: height,
      child: CustomPaint(
        size: Size.infinite,
        painter: _LinePainter(
          points: points,
          target: target,
          line: scheme.primary,
          grid: scheme.outlineVariant,
          text: scheme.onSurfaceVariant,
          targetColor: scheme.tertiary,
          labelStyle: Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
        ),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.points,
    required this.target,
    required this.line,
    required this.grid,
    required this.text,
    required this.targetColor,
    required this.labelStyle,
  });

  final TextStyle labelStyle;

  final List<(int, double)> points;
  final double? target;
  final Color line, grid, text, targetColor;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 40.0, bottom = 20.0, top = 8.0, right = 8.0;
    final w = size.width - left - right;
    final h = size.height - top - bottom;
    final first = points.first.$1;
    final span = math.max(1, daysBetween(first, points.last.$1));
    var minV = points.map((p) => p.$2).reduce(math.min);
    var maxV = points.map((p) => p.$2).reduce(math.max);
    if (target != null) {
      minV = math.min(minV, target!);
      maxV = math.max(maxV, target!);
    }
    if (maxV == minV) {
      maxV += 1;
      minV -= 1;
    }
    final pad = (maxV - minV) * 0.1;
    minV -= pad;
    maxV += pad;

    Offset at(int day, double v) => Offset(left + w * daysBetween(first, day) / span, top + h * (1 - (v - minV) / (maxV - minV)));

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final v = minV + (maxV - minV) * i / 3;
      final y = top + h * (1 - i / 3);
      canvas.drawLine(Offset(left, y), Offset(size.width - right, y), gridPaint);
      _label(canvas, formatNumber(v), Offset(0, y - 7), 36, TextAlign.right);
    }
    _label(canvas, formatDay(first), Offset(left, size.height - 16), 100, TextAlign.left);
    _label(canvas, formatDay(points.last.$1), Offset(size.width - right - 100, size.height - 16), 100, TextAlign.right);

    if (target != null) {
      final y = at(first, target!).dy;
      final p = Paint()
        ..color = targetColor
        ..strokeWidth = 1.5;
      for (var x = left; x < size.width - right; x += 8) {
        canvas.drawLine(Offset(x, y), Offset(math.min(x + 4, size.width - right), y), p);
      }
    }

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final o = at(points[i].$1, points[i].$2);
      i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );
    final dot = Paint()..color = line;
    if (points.length <= 60) {
      for (final p in points) {
        canvas.drawCircle(at(p.$1, p.$2), 3, dot);
      }
    }
  }

  void _label(Canvas canvas, String s, Offset o, double width, TextAlign align) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(color: text, fontSize: 11),
      ),
      textAlign: align,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: width, maxWidth: width);
    tp.paint(canvas, o);
  }

  @override
  bool shouldRepaint(_LinePainter old) => old.points != points || old.target != target || old.line != line;
}

/// Сетка дней по неделям, как на GitHub: столбец = неделя, строка = день недели.
class DayGrid extends StatelessWidget {
  const DayGrid({
    super.key,
    required this.today,
    required this.weeks,
    required this.isDone,
    required this.isPlanned,
    this.isMinimum,
    this.onTap,
  });

  final int today;
  final int weeks;
  final bool Function(int day) isDone;
  final bool Function(int day) isPlanned;
  final bool Function(int day)? isMinimum;
  final void Function(int day)? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final start = addDays(weekStart(today), -7 * (weeks - 1));
    return LayoutBuilder(
      builder: (context, c) {
        final cell = math.min(28.0, (c.maxWidth - 24) / weeks - 3);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                for (var d = 0; d < 7; d++)
                  SizedBox(
                    height: cell + 3,
                    width: 22,
                    child: Text(d.isEven ? weekdayShort[d] : '', style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
                  ),
              ],
            ),
            for (var w = 0; w < weeks; w++)
              Column(
                children: [
                  for (var d = 0; d < 7; d++)
                    Builder(
                      builder: (context) {
                        final day = addDays(start, w * 7 + d);
                        final future = day > today;
                        final done = !future && isDone(day);
                        final planned = isPlanned(day);
                        final minimum = done && (isMinimum?.call(day) ?? false);
                        Color color;
                        if (future) {
                          color = Colors.transparent;
                        } else if (done) {
                          color = minimum ? scheme.primary.withValues(alpha: 0.5) : scheme.primary;
                        } else if (planned) {
                          color = scheme.surfaceContainerHighest;
                        } else {
                          color = scheme.surfaceContainerHighest.withValues(alpha: 0.35);
                        }
                        return GestureDetector(
                          onTap: future || onTap == null ? null : () => onTap!(day),
                          child: Container(
                            width: cell,
                            height: cell,
                            margin: const EdgeInsets.all(1.5),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(4),
                              border: day == today ? Border.all(color: scheme.primary, width: 1.5) : null,
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
          ],
        );
      },
    );
  }
}
