/// Бюджет на месяц: план доходов, платежей, накоплений и расходов против факта.
library;

import '../data/database.dart';

enum BudgetGroup {
  income('Доходы'),
  debts('Платежи по долгам'),
  savings('Накопления'),
  expenses('Расходы');

  const BudgetGroup(this.label);
  final String label;
}

class BudgetRow {
  const BudgetRow({required this.group, required this.plan, required this.fact, this.category, this.fund});

  final BudgetGroup group;
  final Category? category;
  final Fund? fund;
  final double plan;
  final double fact;

  String get name => fund?.name ?? category?.name ?? 'Без категории';
  String? get icon => fund?.icon ?? category?.icon;

  /// Строка без плана: деньги ушли или пришли, но в бюджете их не было.
  bool get unplanned => plan <= 0;

  /// Для расходов: вышли за план.
  bool get over => group == BudgetGroup.expenses && fact > plan + 0.5;

  /// Для доходов, платежей и накоплений: план выполнен.
  bool get done => group != BudgetGroup.expenses && plan > 0 && fact >= plan - 0.5;
}

class MonthBudget {
  const MonthBudget(this.rows);
  final List<BudgetRow> rows;

  bool get planned => rows.any((r) => r.plan > 0);

  Iterable<BudgetRow> of(BudgetGroup g) => rows.where((r) => r.group == g);

  double _sum(Iterable<BudgetRow> rs, double Function(BudgetRow) f) => rs.fold(0, (a, r) => a + f(r));

  double get incomePlan => _sum(of(BudgetGroup.income), (r) => r.plan);
  double get incomeFact => _sum(of(BudgetGroup.income), (r) => r.fact);
  double get savePlan => _sum(rows.where((r) => r.fund != null), (r) => r.plan);
  double get saveFact => _sum(rows.where((r) => r.fund != null), (r) => r.fact);
  double get expensePlan => _sum(of(BudgetGroup.expenses), (r) => r.plan);
  double get expenseFact => _sum(of(BudgetGroup.expenses), (r) => r.fact);

  /// Сколько дохода ещё не распределено. Меньше нуля: распределено больше, чем придёт.
  double get unallocated => incomePlan - savePlan - expensePlan;

  /// Сколько ещё можно потратить по плану расходов. Меньше нуля: перерасход.
  double get leftToSpend => expensePlan - expenseFact;
}

/// Свести план и факт за месяц.
MonthBudget buildBudget({
  required List<BudgetLine> lines,
  required List<Category> categories,
  required List<Fund> funds,
  required List<Transaction> transactions,
  required List<FundMove> moves,
}) {
  final catById = {for (final c in categories) c.id: c};
  final fundById = {for (final f in funds) f.id: f};
  final planCat = <int, double>{};
  final planFund = <int, double>{};
  for (final l in lines) {
    if (l.categoryId != null) planCat[l.categoryId!] = (planCat[l.categoryId!] ?? 0) + l.amount;
    if (l.fundId != null) planFund[l.fundId!] = (planFund[l.fundId!] ?? 0) + l.amount;
  }
  final factCat = <int?, double>{};
  for (final t in transactions) {
    factCat[t.categoryId] = (factCat[t.categoryId] ?? 0) + t.amount;
  }
  final factFund = <int, double>{};
  for (final m in moves) {
    factFund[m.fundId] = (factFund[m.fundId] ?? 0) + m.amount;
  }

  final rows = <BudgetRow>[];
  final catIds = {...planCat.keys, ...factCat.keys.whereType<int>()};
  for (final id in catIds) {
    final c = catById[id];
    if (c == null) continue;
    rows.add(
      BudgetRow(group: c.isIncome ? BudgetGroup.income : BudgetGroup.expenses, category: c, plan: planCat[id] ?? 0, fact: factCat[id] ?? 0),
    );
  }
  // Операции без категории.
  final noCategory = transactions.where((t) => t.categoryId == null || !catById.containsKey(t.categoryId));
  final noCatExpense = noCategory.where((t) => !t.isIncome).fold<double>(0, (a, t) => a + t.amount);
  final noCatIncome = noCategory.where((t) => t.isIncome).fold<double>(0, (a, t) => a + t.amount);
  if (noCatExpense > 0) rows.add(BudgetRow(group: BudgetGroup.expenses, plan: 0, fact: noCatExpense));
  if (noCatIncome > 0) rows.add(BudgetRow(group: BudgetGroup.income, plan: 0, fact: noCatIncome));

  for (final id in {...planFund.keys, ...factFund.keys}) {
    final f = fundById[id];
    if (f == null) continue;
    rows.add(
      BudgetRow(
        group: f.kind == FundKind.debt ? BudgetGroup.debts : BudgetGroup.savings,
        fund: f,
        plan: planFund[id] ?? 0,
        fact: factFund[id] ?? 0,
      ),
    );
  }
  // Сначала строки с планом, крупные выше; без плана в конце группы.
  rows.sort((a, b) {
    final g = a.group.index.compareTo(b.group.index);
    if (g != 0) return g;
    if (a.unplanned != b.unplanned) return a.unplanned ? 1 : -1;
    return (b.plan > 0 ? b.plan : b.fact).compareTo(a.plan > 0 ? a.plan : a.fact);
  });
  return MonthBudget(rows);
}

/// Месяц как число yyyymm.
int monthKey(DateTime d) => d.year * 100 + d.month;

DateTime monthFromKey(int key) => DateTime(key ~/ 100, key % 100);

/// Сколько дней месяца осталось, включая сегодня. Для прошлых месяцев 0, для будущих все дни.
int daysLeftInMonth(DateTime month, DateTime now) {
  final last = DateTime(month.year, month.month + 1, 0);
  if (!now.isBefore(DateTime(month.year, month.month + 1))) return 0;
  if (now.isBefore(month)) return last.day;
  return last.day - now.day + 1;
}
