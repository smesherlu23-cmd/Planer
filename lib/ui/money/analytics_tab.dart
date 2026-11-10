import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/database.dart';
import '../../data/dates.dart';
import '../../data/money_queries.dart';
import '../../logic/calc.dart';
import '../../logic/finance.dart';
import '../common.dart';
import '../icons.dart';
import '../theme.dart';
import 'operations_tab.dart';

const _otherColor = Color(0xFF94A3B8);
const _expenseColor = Color(0xFFF97316);

/// Аналитика за неделю, месяц или год: структура расходов, динамика, крупные траты.
class MoneyAnalyticsTab extends StatefulWidget {
  const MoneyAnalyticsTab({super.key});

  @override
  State<MoneyAnalyticsTab> createState() => _MoneyAnalyticsTabState();
}

class _MoneyAnalyticsTabState extends State<MoneyAnalyticsTab> with AutomaticKeepAliveClientMixin {
  var _period = Period.month;
  var _shift = 0;

  @override
  bool get wantKeepAlive => true;

  String _title(int from, int to) {
    switch (_period) {
      case Period.week:
        return '${formatDay(from)} – ${formatDay(to)}';
      case Period.month:
        final d = dayFromKey(from);
        return monthTitle(d.year, d.month);
      case Period.year:
        return '${from ~/ 10000}';
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final db = context.db;
    final theme = Theme.of(context);
    final today = todayKey();
    final (from, to) = periodRange(_period, today, shift: _shift);
    final (pFrom, pFullTo) = periodRange(_period, today, shift: _shift - 1);
    // Текущий период ещё идёт: сравниваем с тем же числом дней прошлого, иначе любой месяц в начале выглядит экономным.
    final passed = daysPassed(from, to, today);
    final pTo = today <= to ? math.min(pFullTo, addDays(pFrom, passed - 1)) : pFullTo;
    return Watch(
      streams: () => [db.watchAllTransactions(), db.select(db.categories).watch()],
      builder: (context, v) {
        final all = v[0] as List<Transaction>;
        final cats = {for (final c in v[1] as List<Category>) c.id: c};
        final cur = all.where((t) => t.day >= from && t.day <= to).toList();
        final prev = all.where((t) => t.day >= pFrom && t.day <= pTo).toList();
        final expenses = cur.where((t) => !t.isIncome).fold<double>(0, (a, t) => a + t.amount);
        final income = cur.where((t) => t.isIncome).fold<double>(0, (a, t) => a + t.amount);
        final prevExpenses = prev.where((t) => !t.isIncome).fold<double>(0, (a, t) => a + t.amount);
        final days = daysPassed(from, to, today);
        final shares = categoryShares(cur, prev);
        final top = (cur.where((t) => !t.isIncome).toList()..sort((a, b) => b.amount.compareTo(a.amount))).take(5).toList();
        final end = dayFromKey(math.min(to, today));
        final series = monthlySeries(all, DateTime(end.year, end.month), count: 6);
        final muted = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);

        // Сегменты кольца: шесть самых больших категорий и «остальное».
        final segs = <(String, double, Color, String?)>[];
        for (final s in shares.take(6)) {
          final c = cats[s.categoryId];
          segs.add((c?.name ?? 'Без категории', s.sum, appIcon(c?.icon, fallback: 'payments').color, c?.icon));
        }
        final rest = shares.skip(6).fold<double>(0, (a, s) => a + s.sum);
        if (rest > 0) segs.add(('Остальное', rest, _otherColor, null));

        return ListView(
          padding: const EdgeInsets.only(top: 8, bottom: 110),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SegmentedButton<Period>(
                segments: [for (final p in Period.values) ButtonSegment(value: p, label: Text(p.label))],
                selected: {_period},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() {
                  _period = s.first;
                  _shift = 0;
                }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.chevron_left_rounded), onPressed: () => setState(() => _shift--)),
                  Expanded(
                    child: Text(_title(from, to), textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
                  ),
                  IconButton(icon: const Icon(Icons.chevron_right_rounded), onPressed: _shift >= 0 ? null : () => setState(() => _shift++)),
                ],
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _Stat(
                            label: 'Расходы',
                            value: formatMoney(expenses),
                            change: changePercent(expenses, prevExpenses),
                            lowerIsBetter: true,
                          ),
                        ),
                        Expanded(
                          child: _Stat(label: 'Доходы', value: formatMoney(income), color: Accent.habits),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _Stat(
                            label: income >= expenses ? 'Осталось' : 'Перерасход',
                            value: formatMoney((income - expenses).abs()),
                            color: income >= expenses ? null : theme.colorScheme.error,
                          ),
                        ),
                        Expanded(
                          child: _Stat(label: 'В среднем в день', value: days == 0 ? '—' : formatMoney(expenses / days)),
                        ),
                      ],
                    ),
                    if (income > 0) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Норма сбережений ${(100 * (income - expenses) / income).round()}%',
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ProgressLine(value: ((income - expenses) / income).clamp(0, 1).toDouble(), color: Accent.habits, height: 8),
                      const SizedBox(height: 6),
                      Text('Хороший ориентир: откладывать 10–20% дохода.', style: theme.textTheme.bodySmall?.copyWith(color: muted?.color)),
                    ],
                  ],
                ),
              ),
            ),
            const SectionTitle('Куда уходят деньги'),
            if (shares.isEmpty)
              const Card(child: EmptyHint('Расходов за этот период нет', icon: Icons.pie_chart_outline_rounded))
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 190,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: const Size.square(190),
                              painter: _DonutPainter([
                                for (final s in segs) (s.$2, s.$3),
                              ], track: theme.colorScheme.surfaceContainerHighest),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('всего', style: muted),
                                Text(formatMoney(expenses), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (final s in shares)
                        _ShareRow(
                          share: s,
                          category: cats[s.categoryId],
                          onTap: () => _showCategory(
                            context,
                            cats[s.categoryId],
                            cur.where((t) => !t.isIncome && t.categoryId == s.categoryId).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            const SectionTitle('Доходы и расходы по месяцам'),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                child: Column(
                  children: [
                    SizedBox(
                      height: 170,
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: _FlowBarsPainter(
                          series,
                          income: Accent.habits,
                          expense: _expenseColor,
                          labelStyle: (theme.textTheme.labelSmall ?? const TextStyle()).copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _legendDot(Accent.habits),
                        Text(' доходы', style: muted),
                        const SizedBox(width: 16),
                        _legendDot(_expenseColor),
                        Text(' расходы', style: muted),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (top.isNotEmpty) ...[
              const SectionTitle('Самые крупные траты'),
              GroupCard(
                children: [for (final t in top) TransactionTile(t: t, category: cats[t.categoryId], showAccount: false)],
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _legendDot(Color c) => Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
  );

  void _showCategory(BuildContext context, Category? c, List<Transaction> txs) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheet) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (sheet, controller) => ListView(
          controller: controller,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Text(c?.name ?? 'Без категории', style: Theme.of(sheet).textTheme.titleLarge),
            ),
            ...operationGroups(sheet, txs: txs, transfers: const [], categories: c == null ? const {} : {c.id: c}, accounts: const {}),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.color, this.change, this.lowerIsBetter = false});
  final String label;
  final String value;
  final Color? color;
  final int? change;
  final bool lowerIsBetter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ch = change;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: color),
          ),
        ),
        if (ch != null && ch != 0)
          Text(
            '${ch > 0 ? '↑' : '↓'} ${ch.abs()}% к прошлому',
            style: theme.textTheme.labelSmall?.copyWith(
              color: (ch > 0) == lowerIsBetter ? theme.colorScheme.error : Accent.habits,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

class _ShareRow extends StatelessWidget {
  const _ShareRow({required this.share, required this.category, required this.onTap});
  final CategoryShare share;
  final Category? category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ch = changePercent(share.sum, share.previous);
    final color = appIcon(category?.icon, fallback: 'payments').color;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
        child: Row(
          children: [
            ItemIcon(category?.icon, size: 36, fallback: 'payments'),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          category?.name ?? 'Без категории',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(formatMoney(share.sum), style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(
                        child: ProgressLine(value: share.share, color: color, height: 6),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 92,
                        child: Text(
                          '${(share.share * 100).round()}%${ch == null || ch == 0 ? '' : ' · ${ch > 0 ? '↑' : '↓'}${ch.abs()}%'}',
                          textAlign: TextAlign.end,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: ch != null && ch >= 20 ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.segments, {required this.track});
  final List<(double, Color)> segments;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 26.0;
    final r = math.min(size.width, size.height) / 2 - stroke / 2;
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: r);
    canvas.drawCircle(
      rect.center,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );
    final total = segments.fold<double>(0, (a, s) => a + s.$1);
    if (total <= 0) return;
    const gap = 0.025;
    var start = -math.pi / 2;
    for (final (v, c) in segments) {
      final sweep = 2 * math.pi * v / total;
      final draw = segments.length == 1 ? sweep : math.max(0.001, sweep - gap);
      canvas.drawArc(
        rect,
        start + (segments.length == 1 ? 0 : gap / 2),
        draw,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.butt
          ..color = c,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => true;
}

/// Парные столбики: доход и расход за каждый месяц.
class _FlowBarsPainter extends CustomPainter {
  _FlowBarsPainter(this.series, {required this.income, required this.expense, required this.labelStyle});
  final List<({int month, double income, double expenses})> series;
  final Color income, expense;
  final TextStyle labelStyle;

  static const _short = ['янв', 'фев', 'мар', 'апр', 'май', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];

  @override
  void paint(Canvas canvas, Size size) {
    if (series.isEmpty) return;
    const bottom = 20.0, top = 18.0;
    final h = size.height - top - bottom;
    final maxV = series.fold<double>(0, (a, s) => math.max(a, math.max(s.income, s.expenses)));
    final slot = size.width / series.length;
    final w = math.min(14.0, slot * 0.28);
    for (var i = 0; i < series.length; i++) {
      final s = series[i];
      final cx = slot * i + slot / 2;
      void bar(double v, double x, Color c) {
        if (maxV <= 0 || v <= 0) return;
        final bh = math.max(2.0, h * v / maxV);
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(x, top + h - bh, w, bh),
            topLeft: Radius.circular(w / 2.5),
            topRight: Radius.circular(w / 2.5),
          ),
          Paint()..color = c,
        );
      }

      bar(s.income, cx - w - 1.5, income);
      bar(s.expenses, cx + 1.5, expense);
      final diff = s.income - s.expenses;
      if (s.income > 0 || s.expenses > 0) {
        final tp = TextPainter(
          text: TextSpan(
            text: _compact(diff),
            style: labelStyle.copyWith(fontSize: 9.5, color: diff < 0 ? const Color(0xFFEF4444) : labelStyle.color),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        )..layout(minWidth: slot, maxWidth: slot);
        tp.paint(canvas, Offset(slot * i, 0));
      }
      final lp = TextPainter(
        text: TextSpan(text: _short[s.month % 100 - 1], style: labelStyle),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(minWidth: slot, maxWidth: slot);
      lp.paint(canvas, Offset(slot * i, size.height - bottom + 5));
    }
  }

  String _compact(double v) {
    final sign = v < 0 ? '−' : '+';
    final a = v.abs();
    if (a >= 1000) return '$sign${formatNumber(a / 1000, maxDecimals: a >= 10000 ? 0 : 1)}к';
    return '$sign${a.round()}';
  }

  @override
  bool shouldRepaint(_FlowBarsPainter old) => true;
}
