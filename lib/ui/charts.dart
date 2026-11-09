import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/dates.dart';
import '../logic/calc.dart';

/// Простой линейный график значений по дням.
class LineChart extends StatelessWidget {
  const LineChart({super.key, required this.points, this.height = 180, this.target, this.color});

  final List<(int day, double value)> points;
  final double height;
  final Color? color;

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
          line: color ?? scheme.primary,
          grid: scheme.outlineVariant,
          surface: scheme.surfaceContainer,
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
    required this.surface,
  });

  final Color surface;

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
      ..color = grid.withValues(alpha: 0.7)
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

    final offsets = [for (final p in points) at(p.$1, p.$2)];
    final path = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (var i = 1; i < offsets.length; i++) {
      // Плавная кривая: середина между точками как опорная.
      final a = offsets[i - 1], b = offsets[i];
      final mx = (a.dx + b.dx) / 2;
      path.cubicTo(mx, a.dy, mx, b.dy, b.dx, b.dy);
    }
    final fill = Path.from(path)
      ..lineTo(offsets.last.dx, top + h)
      ..lineTo(offsets.first.dx, top + h)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [line.withValues(alpha: 0.28), line.withValues(alpha: 0)],
        ).createShader(Rect.fromLTWH(left, top, w, h)),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    final dot = Paint()..color = line;
    if (points.length <= 30) {
      for (final o in offsets) {
        canvas.drawCircle(o, 3.5, Paint()..color = surface);
        canvas.drawCircle(o, 2.5, dot);
      }
    }
    // Последняя точка крупнее: это «сейчас».
    canvas.drawCircle(offsets.last, 6, Paint()..color = surface);
    canvas.drawCircle(offsets.last, 4.5, dot);
  }

  void _label(Canvas canvas, String s, Offset o, double width, TextAlign align) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: labelStyle.copyWith(color: text, fontSize: 11),
      ),
      textAlign: align,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: width, maxWidth: width);
    tp.paint(canvas, o);
  }

  @override
  bool shouldRepaint(_LinePainter old) => old.points != points || old.target != target || old.line != line || old.surface != surface;
}

/// Маленький график без подписей, для карточки в списке.
class Sparkline extends StatelessWidget {
  const Sparkline({super.key, required this.values, required this.color, this.width = 64, this.height = 30});
  final List<double> values;
  final Color color;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(painter: _SparkPainter(values, color)),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.values, this.color);
  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    var minV = values.reduce(math.min), maxV = values.reduce(math.max);
    if (maxV == minV) {
      maxV += 1;
      minV -= 1;
    }
    const pad = 3.0;
    Offset at(int i) => Offset(
      pad + (size.width - 2 * pad) * i / (values.length - 1),
      pad + (size.height - 2 * pad) * (1 - (values[i] - minV) / (maxV - minV)),
    );
    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < values.length; i++) {
      final a = at(i - 1), b = at(i);
      final mx = (a.dx + b.dx) / 2;
      path.cubicTo(mx, a.dy, mx, b.dy, b.dx, b.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(at(values.length - 1), 3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparkPainter old) => old.values != values || old.color != color;
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
    this.color,
  });

  final Color? color;

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
                          final c = this.color ?? scheme.primary;
                          color = minimum ? c.withValues(alpha: 0.5) : c;
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

/// Столбики по дням с линией цели: сон по ночам, калории по дням.
class BarChart extends StatelessWidget {
  const BarChart({super.key, required this.bars, required this.color, this.target, this.goodColor, this.height = 150});

  /// Подпись под столбиком и значение. null: записи нет.
  final List<(String label, double? value)> bars;
  final Color color;

  /// Цвет столбика, который дотянул до цели.
  final Color? goodColor;
  final double? target;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: height,
      child: CustomPaint(
        size: Size.infinite,
        painter: _BarPainter(
          bars: bars,
          color: color,
          goodColor: goodColor ?? color,
          target: target,
          track: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
          targetColor: scheme.onSurfaceVariant,
          labelStyle: (Theme.of(context).textTheme.labelSmall ?? const TextStyle()).copyWith(color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.bars,
    required this.color,
    required this.goodColor,
    required this.target,
    required this.track,
    required this.targetColor,
    required this.labelStyle,
  });

  final List<(String, double?)> bars;
  final Color color, goodColor, track, targetColor;
  final double? target;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;
    const bottom = 20.0, top = 6.0;
    final h = size.height - top - bottom;
    final values = [for (final b in bars) b.$2 ?? 0];
    final maxV = math.max(values.reduce(math.max), target ?? 0) * 1.12;
    if (maxV <= 0) return;
    final slot = size.width / bars.length;
    final w = math.min(28.0, slot * 0.62);
    for (var i = 0; i < bars.length; i++) {
      final cx = slot * i + slot / 2;
      final rect = Rect.fromLTWH(cx - w / 2, top, w, h);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(w / 3)), Paint()..color = track);
      final v = bars[i].$2;
      if (v != null && v > 0) {
        final bh = h * v / maxV;
        final good = target != null && v >= target! * 0.97;
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(cx - w / 2, top + h - bh, w, bh), Radius.circular(w / 3)),
          Paint()..color = good ? goodColor : color,
        );
      }
      final tp = TextPainter(
        text: TextSpan(text: bars[i].$1, style: labelStyle),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(minWidth: slot, maxWidth: slot);
      tp.paint(canvas, Offset(slot * i, size.height - bottom + 5));
    }
    if (target != null) {
      final y = top + h * (1 - target! / maxV);
      final p = Paint()
        ..color = targetColor.withValues(alpha: 0.7)
        ..strokeWidth = 1.4;
      for (var x = 0.0; x < size.width; x += 8) {
        canvas.drawLine(Offset(x, y), Offset(math.min(x + 4, size.width), y), p);
      }
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) => old.bars != bars || old.target != target || old.color != color;
}
