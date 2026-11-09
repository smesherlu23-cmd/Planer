import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import '../../data/database.dart';
import '../../data/dates.dart';
import '../../data/icon_keys.dart';
import '../../data/money_queries.dart';
import '../../data/queries.dart';
import '../../logic/calc.dart';
import '../../logic/finance.dart';
import '../common.dart';
import '../icons.dart';
import '../money_screen.dart';
import '../theme.dart';

/// «сегодня», «завтра», «через 5 дн.», «просрочен на 2 дн.»
String dueLabel(int day, int today) {
  final d = daysBetween(today, day);
  if (d < 0) return 'просрочен на ${-d} дн.';
  if (d == 0) return 'сегодня';
  if (d == 1) return 'завтра';
  if (d < 7) return 'через $d дн., ${formatDay(day)}';
  return formatDay(day, withYear: day ~/ 10000 != today ~/ 10000);
}

class RecurringTile extends StatelessWidget {
  const RecurringTile({super.key, required this.r, required this.category, required this.today, this.compact = false});
  final Recurring r;
  final Category? category;
  final int today;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final income = r.kind == RecurringKind.income;
    final overdue = r.nextDay < today;
    return ListTile(
      leading: ItemIcon(r.icon, size: 40, fallback: income ? 'salary' : 'payments'),
      title: Text(r.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        compact ? dueLabel(r.nextDay, today) : '${dueLabel(r.nextDay, today)} · ${repeatLabel(r.repeat, r.every)}',
        style: TextStyle(color: overdue ? theme.colorScheme.error : null),
      ),
      trailing: Text(
        '${income ? '+' : '−'}${formatMoney(r.amount)}',
        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: income ? Accent.habits : null),
      ),
      onTap: () => showPaySheet(context, r),
    );
  }
}

/// Отметить платёж: записать операцию, пропустить или изменить.
Future<void> showPaySheet(BuildContext context, Recurring r) {
  final amount = TextEditingController(text: formatNumber(r.amount, maxDecimals: 2));
  var day = todayKey();
  int? account = r.accountId;
  final income = r.kind == RecurringKind.income;
  return showFormSheet(
    context,
    (sheet) => StatefulBuilder(
      builder: (sheet, setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(r.name, style: Theme.of(sheet).textTheme.titleLarge),
          Text(
            '${dueLabel(r.nextDay, todayKey())} · ${repeatLabel(r.repeat, r.every)}',
            style: TextStyle(color: Theme.of(sheet).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          NumberField(controller: amount, label: 'Сумма', suffix: '₽'),
          StreamBuilder<List<Account>>(
            stream: sheet.db.watchAccounts(),
            builder: (context, snap) {
              final accounts = snap.data ?? const <Account>[];
              if (accounts.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 12),
                child: AccountChips(
                  accounts: accounts,
                  selected: account,
                  allowNone: true,
                  onSelected: (id) => setState(() => account = id),
                ),
              );
            },
          ),
          DayTile(day: day, onChanged: (d) => setState(() => day = d ?? day)),
          const SizedBox(height: 8),
          FilledButton.icon(
            icon: const Icon(Icons.check_rounded),
            label: Text(income ? 'Получено' : 'Оплачено'),
            onPressed: () async {
              final v = parseNumber(amount.text);
              if (v == null || v <= 0) return showSnack(sheet, 'Введи сумму');
              await sheet.db.payRecurring(r, amount: v, day: day, accountId: account);
              if (sheet.mounted) Navigator.pop(sheet);
            },
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    await sheet.db.skipRecurring(r);
                    if (sheet.mounted) Navigator.pop(sheet);
                  },
                  child: const Text('Пропустить раз'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(sheet);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => RecurringEditScreen(recurring: r)));
                  },
                  child: const Text('Изменить'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// Список всех регулярных платежей с итогами в месяц.
class RecurringSection extends StatelessWidget {
  const RecurringSection({super.key});

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    final today = todayKey();
    return Watch(
      streams: () => [db.watchRecurrings(), db.select(db.categories).watch()],
      builder: (context, v) {
        final list = v[0] as List<Recurring>;
        final cats = {for (final c in v[1] as List<Category>) c.id: c};
        final out = list.where((r) => r.kind != RecurringKind.income).fold<double>(0, (a, r) => a + monthlyCost(r));
        final inc = list.where((r) => r.kind == RecurringKind.income).fold<double>(0, (a, r) => a + monthlyCost(r));
        final theme = Theme.of(context);
        final muted = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionTitle(
              'Регулярные платежи',
              trailing: IconButton(
                tooltip: 'Добавить',
                icon: const Icon(Icons.add_rounded),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecurringEditScreen())),
              ),
            ),
            if (list.isEmpty)
              Card(
                child: EmptyHint(
                  'Добавь зарплату, связь, подписки и платёж по кредиту. Приложение покажет, что скоро платить, '
                  'и посчитает, сколько можно тратить в день до следующего дохода.',
                  icon: Icons.event_repeat_rounded,
                  action: FilledButton.tonal(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecurringEditScreen())),
                    child: const Text('Добавить'),
                  ),
                ),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 6),
                child: Text(
                  [
                    if (inc > 0) 'Приходит ${formatMoney(inc)} в месяц',
                    if (out > 0) 'уходит ${formatMoney(out)} в месяц (${formatMoney(out * 12)} в год)',
                    if (inc > 0 && out > 0) 'остаётся ${formatMoney(inc - out)}',
                  ].join(', '),
                  style: muted,
                ),
              ),
              GroupCard(
                children: [for (final r in list) RecurringTile(r: r, category: cats[r.categoryId], today: today)],
              ),
            ],
          ],
        );
      },
    );
  }
}

class RecurringEditScreen extends StatefulWidget {
  const RecurringEditScreen({super.key, this.recurring});
  final Recurring? recurring;

  @override
  State<RecurringEditScreen> createState() => _RecurringEditScreenState();
}

class _RecurringEditScreenState extends State<RecurringEditScreen> {
  late final Recurring? _r = widget.recurring;
  late final _name = TextEditingController(text: _r?.name ?? '');
  late final _amount = TextEditingController(text: _r == null ? '' : formatNumber(_r.amount, maxDecimals: 2));
  late String? _icon = iconKeyFor(_r?.icon);
  late RecurringKind _kind = _r?.kind ?? RecurringKind.expense;
  late int? _category = _r?.categoryId;
  late int? _account = _r?.accountId;
  late int? _fund = _r?.fundId;
  late RepeatKind _repeat = _r?.repeat ?? RepeatKind.monthly;
  late int _every = _r?.every ?? 1;
  late int _next = _r?.nextDay ?? todayKey();

  Future<void> _save() async {
    final name = _name.text.trim();
    final amount = parseNumber(_amount.text);
    if (name.isEmpty) return showSnack(context, 'Введи название');
    if (amount == null || amount <= 0) return showSnack(context, 'Введи сумму');
    if (_kind == RecurringKind.fund && _fund == null) return showSnack(context, 'Выбери копилку или долг');
    await context.db.saveRecurring(
      RecurringsCompanion(
        id: _r == null ? const Value.absent() : Value(_r.id),
        name: Value(name),
        icon: Value(_icon ?? (_kind == RecurringKind.income ? 'salary' : 'payments')),
        kind: Value(_kind),
        amount: Value(amount),
        categoryId: Value(_kind == RecurringKind.fund ? null : _category),
        accountId: Value(_account),
        fundId: Value(_kind == RecurringKind.fund ? _fund : null),
        repeat: Value(_repeat),
        every: Value(_every),
        nextDay: Value(_next),
        monthDay: Value(_repeat == RepeatKind.weekly ? null : dayFromKey(_next).day),
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(_r == null ? 'Регулярный платёж' : _r.name)),
      body: Watch(
        streams: () => [db.watchCategories(), db.watchAccounts(), db.watchFunds()],
        builder: (context, v) {
          final cats = (v[0] as List<Category>).where((c) => c.isIncome == (_kind == RecurringKind.income)).toList();
          final accounts = v[1] as List<Account>;
          final funds = v[2] as List<Fund>;
          Widget label(String t) => Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 6),
            child: Text(t, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          );
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SegmentedButton<RecurringKind>(
                segments: const [
                  ButtonSegment(value: RecurringKind.expense, label: Text('Расход')),
                  ButtonSegment(value: RecurringKind.income, label: Text('Доход')),
                  ButtonSegment(value: RecurringKind.fund, label: Text('Копилка, долг')),
                ],
                selected: {_kind},
                onSelectionChanged: (s) => setState(() {
                  _kind = s.first;
                  _category = null;
                }),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  IconField(
                    value: _icon,
                    fallback: _kind == RecurringKind.income ? 'salary' : 'payments',
                    onChanged: (v) => setState(() => _icon = v),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _name,
                      decoration: InputDecoration(
                        labelText: 'Название',
                        hintText: switch (_kind) {
                          RecurringKind.expense => 'Связь, интернет, подписка',
                          RecurringKind.income => 'Зарплата, аванс',
                          RecurringKind.fund => 'Платёж по кредиту',
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              NumberField(controller: _amount, label: 'Сумма', suffix: '₽'),
              if (_kind == RecurringKind.fund) ...[
                label('Куда'),
                if (funds.isEmpty)
                  Text('Сначала добавь копилку или долг на обзоре.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final f in funds)
                      ChoiceChip(
                        avatar: Icon(
                          appIcon(f.icon, fallback: 'savings').icon,
                          color: appIcon(f.icon, fallback: 'savings').color,
                        ),
                        label: Text(f.name),
                        selected: _fund == f.id,
                        onSelected: (on) => setState(() {
                          _fund = on ? f.id : null;
                          if (on && _name.text.trim().isEmpty) {
                            _name.text = f.kind == FundKind.debt ? 'Платёж: ${f.name}' : 'В копилку: ${f.name}';
                          }
                          if (on && _amount.text.trim().isEmpty && f.monthlyAmount != null) _amount.text = formatNumber(f.monthlyAmount!);
                        }),
                      ),
                  ],
                ),
              ] else if (cats.isNotEmpty) ...[
                label('Категория'),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final c in cats)
                      ChoiceChip(
                        avatar: Icon(
                          appIcon(c.icon, fallback: 'payments').icon,
                          color: appIcon(c.icon, fallback: 'payments').color,
                        ),
                        label: Text(c.name),
                        selected: _category == c.id,
                        onSelected: (on) => setState(() {
                          _category = on ? c.id : null;
                          if (on && _icon == null) _icon = iconKeyFor(c.icon);
                        }),
                      ),
                  ],
                ),
              ],
              if (accounts.isNotEmpty) ...[
                label(_kind == RecurringKind.income ? 'На счёт' : 'Со счёта'),
                AccountChips(accounts: accounts, selected: _account, allowNone: true, onSelected: (id) => setState(() => _account = id)),
              ],
              label('Как часто'),
              SegmentedButton<RepeatKind>(
                segments: const [
                  ButtonSegment(value: RepeatKind.weekly, label: Text('Неделя')),
                  ButtonSegment(value: RepeatKind.monthly, label: Text('Месяц')),
                  ButtonSegment(value: RepeatKind.yearly, label: Text('Год')),
                ],
                selected: {_repeat},
                onSelectionChanged: (s) => setState(() => _repeat = s.first),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: Text(repeatLabel(_repeat, _every), style: theme.textTheme.titleSmall)),
                  IconButton.outlined(
                    icon: const Icon(Icons.remove_rounded),
                    onPressed: _every > 1 ? () => setState(() => _every--) : null,
                  ),
                  const SizedBox(width: 6),
                  IconButton.outlined(icon: const Icon(Icons.add_rounded), onPressed: _every < 12 ? () => setState(() => _every++) : null),
                ],
              ),
              DayTile(day: _next, title: 'Ближайшая дата', onChanged: (d) => setState(() => _next = d ?? _next)),
              const SizedBox(height: 12),
              FilledButton(onPressed: _save, child: const Text('Сохранить')),
              if (_r != null) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Удалить'),
                  onPressed: () async {
                    if (await confirm(
                      context,
                      'Удалить «${_r.name}»?',
                      text: 'Записанные операции останутся.',
                      ok: 'Удалить',
                      danger: true,
                    )) {
                      await db.deleteById(db.recurrings, _r.id);
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
