import 'dart:math';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import '../data/database.dart';
import '../data/dates.dart';
import '../data/icon_keys.dart';
import '../data/queries.dart';
import '../logic/calc.dart';
import '../logic/food.dart';
import '../logic/minimum.dart';
import '../logic/values.dart';
import 'charts.dart';
import 'common.dart';
import 'food_add.dart';
import 'icons.dart';
import 'theme.dart';

String _kcal(double v) => '${formatNumber(v, maxDecimals: 0)} ккал';
String _grams(double v) => '${formatNumber(v, maxDecimals: 0)} г';

/// «Б 30 · Ж 22 · У 95 г»: коротко про состав порции.
String _macros(double p, double f, double c) =>
    'Б ${formatNumber(p, maxDecimals: 0)} · Ж ${formatNumber(f, maxDecimals: 0)} · У ${formatNumber(c, maxDecimals: 0)} г';
String _liters(int ml) => '${formatNumber(ml / 1000, maxDecimals: 1)} л';

/// Добавить блюдо в один тап и показать «Отменить».
Future<void> eatFood(BuildContext context, Food f, {required int day, MealSlot? slot}) async {
  final db = context.db;
  final messenger = ScaffoldMessenger.of(context);
  final id = await db.eatFood(f, day: day, slot: (slot ?? MealSlot.forTime(DateTime.now())).index);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('Записано: ${f.name}, ${_kcal(f.kcal)}'),
        action: SnackBarAction(label: 'Отменить', onPressed: () => db.deleteById(db.meals, id)),
      ),
    );
}

Future<void> addGlass(BuildContext context, {required int day, required int ml}) => context.db.addWater(ml, day: day);

class FoodScreen extends StatefulWidget {
  const FoodScreen({super.key});

  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> {
  int _day = todayKey();

  /// Период статистики: 7 или 30 дней.
  int _period = 7;

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    final today = todayKey();
    // Месяц для статистики и ещё немного для расчёта расхода по факту.
    final from = addDays(_day, -34);
    return Watch(
      deps: [_day],
      streams: () => [
        db.watchAllSettings(),
        db.watchFoods(),
        db.watchMeals(from: from, to: today),
        db.watchWater(from: from, to: today),
        db.watchTrackers(),
        db.watchAllEntries(),
      ],
      builder: (context, v) {
        final settings = v[0] as Map<String, String>;
        final goals = FoodGoals.from(settings);
        final body = Body.from(settings);
        final foods = v[1] as List<Food>;
        final meals = v[2] as List<Meal>;
        final water = v[3] as List<WaterLog>;
        final trackers = v[4] as List<Tracker>;
        final entries = v[5] as List<TrackerEntry>;
        final totals = dayFood(_day, meals, water);
        final dayMeals = meals.where((m) => m.day == _day).toList();
        final weightTracker = trackers.where((t) => t.id == goals.weightTrackerId).firstOrNull;
        final weightSeries = weightTracker == null ? const <(int, double)>[] : dailySeries(weightTracker, entries);
        final weight = weightSeries.lastOrNull?.$2;
        final advice = weightTracker == null ? null : weightAdvice(weightSeries, goals.mode, today: today);
        final byDay = <int, DayFood>{
          for (final d in {for (final m in meals) m.day}) d: dayFood(d, meals, water),
        };
        final period = [for (var i = _period - 1; i >= 0; i--) byDay[addDays(_day, -i)] ?? dayFood(addDays(_day, -i), const [], water)];
        final bySlot = <MealSlot, List<Meal>>{};
        for (final m in dayMeals) {
          bySlot.putIfAbsent(MealSlot.of(m), () => []).add(m);
        }
        final yesterday = addDays(_day, -1);
        final prevMeals = meals.where((m) => m.day == yesterday).toList();
        final expenditure = weightTracker == null
            ? null
            : measuredExpenditure(
                intake: {for (final e in byDay.entries) e.key: e.value.kcal},
                weights: weightSeries,
                today: today,
                minDay: goals.kcal * 0.5,
              );
        final suggestions = _day != today || goals.mode == FoodMode.lose
            ? const <Food>[]
            : fillSuggestions(
                [for (final f in foods) (f, foodMacros(f))],
                kcalLeft: goals.kcal - totals.kcal,
                proteinLeft: goals.protein - totals.protein,
              );
        return ScrollFabScope(
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Питание'),
              actions: [
                IconButton(
                  tooltip: 'Мои блюда и рецепты',
                  icon: const Icon(Icons.menu_book_rounded),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FoodLibraryScreen())),
                ),
                IconButton(
                  tooltip: 'Цели',
                  icon: const Icon(Icons.tune_rounded),
                  onPressed: () => showFoodGoalsSheet(context, goals: goals, trackers: trackers, weight: weight),
                ),
              ],
            ),
            floatingActionButton: ScrollFab(
              child: FloatingActionButton.extended(
                heroTag: null,
                backgroundColor: Accent.food,
                foregroundColor: Colors.white,
                onPressed: () => showAddFoodSheet(context, day: _day),
                icon: const Icon(Icons.search_rounded),
                label: const Text('Добавить'),
              ),
            ),
            body: ListView(
              padding: const EdgeInsets.only(bottom: 110),
              children: [
                _FoodHero(day: _day, today: today, totals: totals, goals: goals, onShift: (d) => setState(() => _day = addDays(_day, d))),
                if (body == null)
                  _CalcPromptCard(
                    onTap: () => showFoodCalcSheet(context, goals: goals, weight: weight),
                  )
                else if (advice != null || expenditure != null)
                  _AdviceCard(advice: advice, expenditure: expenditure, goals: goals),
                if (suggestions.isNotEmpty && goals.kcal - totals.kcal >= 200)
                  _FillCard(foods: suggestions, kcalLeft: goals.kcal - totals.kcal, proteinLeft: goals.protein - totals.protein, day: _day),
                SectionTitle(
                  'Быстро добавить',
                  trailing: PopupMenuButton<int>(
                    tooltip: 'Новое блюдо или рецепт',
                    icon: const Icon(Icons.add_rounded),
                    onSelected: (v) => v == 0 ? showFoodEditSheet(context) : showRecipeSheet(context),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 0, child: Text('Новое блюдо')),
                      PopupMenuItem(value: 1, child: Text('Рецепт из ингредиентов')),
                    ],
                  ),
                ),
                if (foods.isEmpty)
                  Card(
                    child: EmptyHint(
                      'Добавь то, что ешь часто: завтрак, обед, перекус. Потом записывать еду можно одним нажатием. '
                      'Или найди продукт в справочнике кнопкой «Добавить».',
                      icon: Icons.restaurant_rounded,
                      action: FilledButton.tonal(onPressed: () => showFoodEditSheet(context), child: const Text('Добавить блюдо')),
                    ),
                  )
                else
                  _FoodGrid(
                    foods: foods,
                    onTap: (f) => eatFood(context, f, day: _day),
                  ),
                _WaterCard(day: _day, ml: totals.water, goals: goals),
                SectionTitle(
                  'Съедено',
                  trailing: dayMeals.isEmpty
                      ? (prevMeals.isEmpty
                            ? null
                            : TextButton.icon(
                                onPressed: () async {
                                  final n = await db.copyMeals(from: yesterday, to: _day);
                                  if (context.mounted) showSnack(context, 'Повторил вчерашний день: $n записей');
                                },
                                icon: const Icon(Icons.replay_rounded, size: 18),
                                label: const Text('Как вчера'),
                              ))
                      : Pill(_kcal(totals.kcal), color: Accent.food),
                ),
                for (final slot in MealSlot.values)
                  _SlotCard(
                    slot: slot,
                    meals: bySlot[slot] ?? const [],
                    day: _day,
                    today: today,
                    perMeal: weight == null ? null : proteinPerMeal(weight),
                    hasYesterday: prevMeals.any((m) => MealSlot.of(m) == slot),
                  ),
                if (dayMeals.isNotEmpty && weight != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 2, 22, 0),
                    child: Text(
                      'Белок лучше делить на 3–5 приёмов, примерно по ${_grams(proteinPerMeal(weight))} за раз.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ),
                SectionTitle(
                  'Статистика',
                  trailing: SegmentedButton<int>(
                    showSelectedIcon: false,
                    style: const ButtonStyle(visualDensity: VisualDensity.compact),
                    segments: const [
                      ButtonSegment(value: 7, label: Text('7 дней')),
                      ButtonSegment(value: 30, label: Text('30 дней')),
                    ],
                    selected: {_period},
                    onSelectionChanged: (v) => setState(() => _period = v.first),
                  ),
                ),
                _StatsCard(
                  days: period,
                  firstDay: addDays(_day, -_period + 1),
                  goals: goals,
                  streak: foodStreak(byDay, goals, today: today),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Приём пищи: что съел, сколько калорий и хватило ли белка. Пустой приём занимает одну строку.
class _SlotCard extends StatelessWidget {
  const _SlotCard({
    required this.slot,
    required this.meals,
    required this.day,
    required this.today,
    required this.perMeal,
    required this.hasYesterday,
  });
  final MealSlot slot;
  final List<Meal> meals;
  final int day;
  final int today;
  final double? perMeal;
  final bool hasYesterday;

  Future<void> _repeat(BuildContext context, {required int from, required int to}) async {
    final n = await context.db.copyMeals(from: from, to: to, where: (m) => MealSlot.of(m) == slot);
    if (context.mounted) showSnack(context, n == 0 ? 'Нечего повторять' : '${slot.label}: добавлено $n');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    if (meals.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 6, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(slot.label, style: theme.textTheme.titleMedium?.copyWith(color: muted)),
              ),
              if (hasYesterday)
                TextButton(
                  onPressed: () => _repeat(context, from: addDays(day, -1), to: day),
                  child: const Text('Как вчера'),
                ),
              IconButton(
                tooltip: 'Добавить: ${slot.label.toLowerCase()}',
                icon: const Icon(Icons.add_rounded, color: Accent.food),
                onPressed: () => showAddFoodSheet(context, day: day, slot: slot),
              ),
            ],
          ),
        ),
      );
    }
    final kcal = meals.fold<double>(0, (a, m) => a + m.kcal);
    final protein = meals.fold<double>(0, (a, m) => a + m.protein);
    // Перекус не обязан быть белковым, поэтому для него отметки нет.
    final enough = perMeal != null && slot != MealSlot.snack ? protein >= perMeal! * 0.9 : null;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 0, 0),
            child: Row(
              children: [
                Expanded(child: Text(slot.label, style: theme.textTheme.titleMedium)),
                if (enough != null) ...[
                  // При крупном шрифте отметка белка сжимается, а не выталкивает калории за край.
                  Flexible(
                    child: Pill(
                      'белок ${_grams(protein)}',
                      icon: enough ? Icons.check_rounded : Icons.arrow_upward_rounded,
                      color: enough ? Accent.habits : Accent.money,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(_kcal(kcal), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                PopupMenuButton<int>(
                  tooltip: 'Действия',
                  icon: Icon(Icons.more_vert_rounded, color: muted),
                  onSelected: (v) => switch (v) {
                    0 => showAddFoodSheet(context, day: day, slot: slot),
                    1 => _repeat(context, from: day, to: today),
                    _ => null,
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 0, child: Text('Добавить сюда')),
                    if (day != today) const PopupMenuItem(value: 1, child: Text('Повторить сегодня')),
                  ],
                ),
              ],
            ),
          ),
          for (final m in meals)
            ListTile(
              leading: ItemIcon(m.icon, size: 40, fallback: 'restaurant'),
              title: Text(m.name, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                [
                  formatMinutes(m.at.hour * 60 + m.at.minute),
                  if (m.grams != null) _grams(m.grams!),
                  _macros(m.protein, m.fat, m.carbs),
                ].join(' · '),
                style: TextStyle(color: muted),
              ),
              trailing: Text(_kcal(m.kcal), style: const TextStyle(fontWeight: FontWeight.w600)),
              onTap: () => showMealSheet(context, day: day, existing: m),
            ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

/// Чем добрать норму сегодня: подходящие блюда из своих.
class _FillCard extends StatelessWidget {
  const _FillCard({required this.foods, required this.kcalLeft, required this.proteinLeft, required this.day});
  final List<Food> foods;
  final double kcalLeft;
  final double proteinLeft;
  final int day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final sum = foods.fold(zeroMacros, (a, f) => addMacros(a, foodMacros(f)));
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const ColorIcon(Icons.auto_awesome_rounded, color: Accent.food, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Чем добрать', style: theme.textTheme.titleMedium),
                      Text(
                        'Осталось ${_kcal(kcalLeft)}${proteinLeft > 5 ? ' и ${_grams(proteinLeft)} белка' : ''}. '
                        'Эти блюда дадут ${_kcal(sum.kcal)} и ${_grams(sum.protein)} белка.',
                        style: TextStyle(color: muted, fontSize: 13, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final f in foods)
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.only(left: 4),
                leading: ItemIcon(f.icon, size: 34, fallback: 'restaurant'),
                title: Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('${_kcal(f.kcal)} · ${_macros(f.protein, f.fat, f.carbs)}', style: TextStyle(color: muted)),
                trailing: IconButton(
                  tooltip: 'Записать',
                  icon: const Icon(Icons.add_circle_rounded, color: Accent.food),
                  onPressed: () => eatFood(context, f, day: day),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Статистика за 7 или 30 дней: калории по дням, средние, доли БЖУ, серия.
class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.days, required this.firstDay, required this.goals, required this.streak});
  final List<DayFood> days;
  final int firstDay;
  final FoodGoals goals;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final logged = days.where((d) => d.kcal > 0).toList();
    double avg(double Function(DayFood d) f) => logged.isEmpty ? 0 : logged.fold<double>(0, (a, d) => a + f(d)) / logged.length;
    final full = logged.where((d) => foodLevel(d, goals) == Level.full).length;
    final minimum = logged.where((d) => foodLevel(d, goals) == Level.minimum).length;
    final proteinDays = logged.where((d) => d.protein >= goals.protein * 0.9).length;
    final split = macroSplit(avg((d) => d.protein), avg((d) => d.fat), avg((d) => d.carbs));
    final long = days.length > 7;
    Widget stat(String value, String label) => Expanded(
      child: Column(
        children: [
          Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, fontSize: 12, height: 1.2),
          ),
        ],
      ),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BarChart(
              bars: [
                for (var i = 0; i < days.length; i++)
                  (
                    // На 30 столбиков подписи не помещаются: даты начала и конца идут строкой ниже.
                    long ? '' : weekdayShort[dayFromKey(addDays(firstDay, i)).weekday - 1].substring(0, 1),
                    days[i].kcal == 0 ? null : days[i].kcal,
                  ),
              ],
              target: goals.kcal,
              minimum: goals.mode == FoodMode.lose ? null : goals.kcalMin,
              color: Accent.food.withValues(alpha: 0.3),
              minColor: Accent.food.withValues(alpha: 0.6),
              goodColor: Accent.food,
            ),
            if (long)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(dayLabel(firstDay), style: TextStyle(color: muted, fontSize: 12)),
                    Text(dayLabel(addDays(firstDay, days.length - 1)), style: TextStyle(color: muted, fontSize: 12)),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            if (logged.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Цель: ${_kcal(goals.kcal)} и ${_grams(goals.protein)} белка в день. Записей за этот период пока нет.',
                  style: TextStyle(color: muted, height: 1.35),
                ),
              )
            else ...[
              Row(
                children: [
                  stat('$full из ${logged.length}', 'дней с нормой${minimum > 0 ? ',\nещё $minimum с минимумом' : ''}'),
                  stat('$proteinDays', 'дней с нормой\nбелка'),
                  stat('$streak', 'дней подряд\nбез срыва'),
                ],
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'В среднем ${_kcal(avg((d) => d.kcal))} из ${_kcal(goals.kcal)}: белки ${_grams(avg((d) => d.protein))}, '
                  'жиры ${_grams(avg((d) => d.fat))}, углеводы ${_grams(avg((d) => d.carbs))}. '
                  'Вода ${formatNumber(avg((d) => d.water.toDouble()) / 1000, maxDecimals: 1)} л.',
                  style: TextStyle(color: muted, height: 1.35),
                ),
              ),
              if (split != null) ...[const SizedBox(height: 12), _SplitBar(split: split)],
              if (logged.length < days.length)
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
                  child: Text(
                    'Без записей ${days.length - logged.length} ${_daysWord(days.length - logged.length)}: они не входят в среднее.',
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

String _daysWord(int n) {
  final d = n % 10, h = n % 100;
  if (d == 1 && h != 11) return 'день';
  if (d >= 2 && d <= 4 && (h < 12 || h > 14)) return 'дня';
  return 'дней';
}

/// Доли калорий из белков, жиров и углеводов одной полосой.
class _SplitBar extends StatelessWidget {
  const _SplitBar({required this.split});
  final ({int protein, int fat, int carbs}) split;

  static const _colors = [Color(0xFF0EA5E9), Color(0xFFF59E0B), Color(0xFF10B981)];

  @override
  Widget build(BuildContext context) {
    final parts = [('Белки', split.protein), ('Жиры', split.fat), ('Углеводы', split.carbs)];
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Row(
              children: [
                for (var i = 0; i < 3; i++)
                  if (parts[i].$2 > 0)
                    Expanded(
                      flex: parts[i].$2,
                      child: Container(height: 10, color: _colors[i]),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 14,
            children: [
              for (var i = 0; i < 3; i++)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: _colors[i], shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Text('${parts[i].$1} ${parts[i].$2}%', style: TextStyle(color: muted, fontSize: 12)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Предложение рассчитать норму, пока не заполнены рост и возраст.
class _CalcPromptCard extends StatelessWidget {
  const _CalcPromptCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(14, 8, 12, 8),
        leading: const ColorIcon(Icons.calculate_rounded, color: Accent.food, size: 40),
        title: const Text('Рассчитать норму'),
        subtitle: const Text('По росту, весу, возрасту и активности: калории, белки, жиры, углеводы и вода'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

List<Color> _foodGradient(BuildContext context) => Theme.of(context).brightness == Brightness.dark
    ? const [Color(0xFF0F766E), Color(0xFF047857)]
    : const [Color(0xFF0D9488), Color(0xFF059669)];

class _FoodHero extends StatelessWidget {
  const _FoodHero({required this.day, required this.today, required this.totals, required this.goals, required this.onShift});
  final int day;
  final int today;
  final DayFood totals;
  final FoodGoals goals;
  final ValueChanged<int> onShift;

  @override
  Widget build(BuildContext context) {
    final left = goals.kcal - totals.kcal;
    final label = dayLabel(day);
    final over = goals.mode == FoodMode.lose && totals.kcal > goals.kcal * 1.1;
    return HeroCard(
      colors: _foodGradient(context),
      child: Column(
        children: [
          Row(
            children: [
              HeroArrow(Icons.chevron_left_rounded, onTap: () => onShift(-1)),
              Expanded(
                child: Text(
                  label[0].toUpperCase() + label.substring(1),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
              HeroArrow(Icons.chevron_right_rounded, onTap: day >= today ? null : () => onShift(1)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ProgressRing(
                value: goals.kcal <= 0 ? 0 : totals.kcal / goals.kcal,
                size: 112,
                stroke: 11,
                color: Colors.white,
                trackColor: Colors.white24,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      child: Text(
                        formatNumber(totals.kcal, maxDecimals: 0),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 24),
                      ),
                    ),
                    Text('из ${formatNumber(goals.kcal, maxDecimals: 0)}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      over
                          ? 'Больше цели на ${_kcal(-left)}'
                          : left > 0
                          ? 'Осталось ${_kcal(left)}'
                          : 'Норма калорий набрана',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    if (foodLevel(totals, goals) case final level? when level != Level.below) ...[
                      const SizedBox(height: 6),
                      HeroChip(
                        level == Level.full ? 'Норма дня' : 'Минимум набран',
                        icon: level == Level.full ? Icons.check_rounded : Icons.contrast_rounded,
                      ),
                    ] else if (goals.kcalMin != null && goals.mode != FoodMode.lose && totals.kcal < goals.kcalMin!) ...[
                      const SizedBox(height: 4),
                      Text('Минимум: ${_kcal(goals.kcalMin!)}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                    const SizedBox(height: 12),
                    _HeroBar(
                      label: 'Белки',
                      value: totals.protein,
                      goal: goals.protein,
                      text: '${_grams(totals.protein)} из ${_grams(goals.protein)}',
                    ),
                    const SizedBox(height: 8),
                    _HeroBar(label: 'Жиры', value: totals.fat, goal: goals.fat, text: '${_grams(totals.fat)} из ${_grams(goals.fat)}'),
                    const SizedBox(height: 8),
                    _HeroBar(
                      label: 'Углеводы',
                      value: totals.carbs,
                      goal: goals.carbs,
                      text: '${_grams(totals.carbs)} из ${_grams(goals.carbs)}',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroBar extends StatelessWidget {
  const _HeroBar({required this.label, required this.value, required this.goal, required this.text});
  final String label;
  final double value;
  final double goal;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // При крупном шрифте цифры чуть уменьшаются, но не обрезаются.
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$label  ',
                  style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
                ),
                TextSpan(
                  text: text,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            style: const TextStyle(fontSize: 12),
          ),
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: goal <= 0 ? 0 : (value / goal).clamp(0, 1).toDouble(),
            minHeight: 7,
            color: Colors.white,
            backgroundColor: Colors.white24,
          ),
        ),
      ],
    );
  }
}

/// Подсказка по весу и расход по факту.
class _AdviceCard extends StatelessWidget {
  const _AdviceCard({required this.advice, required this.expenditure, required this.goals});
  final ({String text, bool adjust, int kcalDelta})? advice;
  final ({double kcal, int days, double perWeek})? expenditure;
  final FoodGoals goals;

  Future<void> _setKcal(BuildContext context, double newKcal) async {
    final db = context.db;
    final delta = newKcal - goals.kcal;
    await db.setSetting(FoodGoals.keyKcal, '${newKcal.round()}');
    // Разницу берут углеводы: белок и жиры уже посчитаны от веса.
    final carbs = await db.getSetting(FoodGoals.keyCarbs);
    if (carbs != null) {
      final c = (double.tryParse(carbs) ?? 0) + delta / 4;
      await db.setSetting(FoodGoals.keyCarbs, '${c.clamp(0, 2000).round()}');
    }
    if (context.mounted) showSnack(context, 'Новая цель: ${_kcal(newKcal)} в день');
  }

  @override
  Widget build(BuildContext context) {
    final adjust = advice?.adjust ?? false;
    final color = adjust ? Accent.money : Accent.habits;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final exp = expenditure;
    final fromExp = exp == null ? null : kcalForMode(exp.kcal, goals.mode);
    // Цель от расхода по факту точнее подсказки по темпу: если она есть, предлагаем её.
    final newKcal = fromExp != null && (fromExp - goals.kcal).abs() >= 100
        ? fromExp
        : (advice != null && advice!.kcalDelta != 0 ? goals.kcal + advice!.kcalDelta : null);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (advice != null)
              Row(
                children: [
                  ColorIcon(adjust ? Icons.tips_and_updates_rounded : Icons.trending_up_rounded, color: color, size: 40),
                  const SizedBox(width: 12),
                  Expanded(child: Text(advice!.text, style: const TextStyle(height: 1.35))),
                ],
              ),
            if (exp != null) ...[
              if (advice != null) const Divider(height: 22),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ColorIcon(Icons.local_fire_department_rounded, color: Accent.food, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Расход по факту: ${_kcal(exp.kcal)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(
                          'По ${exp.days} ${_daysWord(exp.days)} записей еды и весу за 4 недели. Точнее формулы, потому что '
                          'считается по тебе. ${goals.mode.label}: ${_kcal(fromExp!)} в день.',
                          style: TextStyle(color: muted, fontSize: 13, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            if (newKcal != null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonal(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                  onPressed: () => _setKcal(context, newKcal),
                  child: Text('Цель ${_kcal(newKcal)}'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FoodGrid extends StatelessWidget {
  const _FoodGrid({required this.foods, required this.onTap});
  final List<Food> foods;
  final ValueChanged<Food> onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          for (var i = 0; i < foods.length; i += 2)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _FoodTile(food: foods[i], onTap: () => onTap(foods[i])),
                  ),
                  Expanded(
                    child: i + 1 < foods.length ? _FoodTile(food: foods[i + 1], onTap: () => onTap(foods[i + 1])) : const SizedBox(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _FoodTile extends StatelessWidget {
  const _FoodTile({required this.food, required this.onTap});
  final Food food;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.all(4),
      child: InkWell(
        onTap: onTap,
        onLongPress: () => showFoodEditSheet(context, existing: food),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ItemIcon(food.icon, size: 36, fallback: 'restaurant'),
                  const Spacer(),
                  if (food.ingredients != null) ...[
                    Icon(Icons.menu_book_rounded, size: 18, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                  ],
                  Icon(Icons.add_circle_rounded, color: Accent.food.withValues(alpha: 0.85)),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                food.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, height: 1.25),
              ),
              const SizedBox(height: 4),
              Text(
                '${_kcal(food.kcal)}${food.grams == null ? '' : ' · ${_grams(food.grams!)}'}\n${_macros(food.protein, food.fat, food.carbs)}',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WaterCard extends StatelessWidget {
  const _WaterCard({required this.day, required this.ml, required this.goals});
  final int day;
  final int ml;
  final FoodGoals goals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glasses = (goals.water / goals.glass).ceil().clamp(1, 16);
    final drunk = (ml / goals.glass).floor();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const ColorIcon(Icons.water_drop_rounded, color: Accent.water, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Вода', style: theme.textTheme.titleMedium),
                        Text(
                          '${_liters(ml)} из ${_liters(goals.water)} · стакан ${goals.glass} мл',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Убрать стакан',
                    onPressed: ml == 0 ? null : () => context.db.undoWater(day),
                    icon: const Icon(Icons.remove_rounded),
                  ),
                  IconButton.filled(
                    tooltip: 'Стакан воды',
                    style: IconButton.styleFrom(backgroundColor: Accent.water, foregroundColor: Colors.white),
                    onPressed: () => addGlass(context, day: day, ml: goals.glass),
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (var i = 0; i < glasses; i++)
                    Icon(
                      i < drunk ? Icons.local_drink_rounded : Icons.local_drink_outlined,
                      color: i < drunk ? Accent.water : theme.colorScheme.outline,
                      size: 26,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Формы
// ---------------------------------------------------------------------------

/// Калории и БЖУ. Если калории не указаны, они считаются из БЖУ; если указаны, видно, сходятся ли.
class _MacroFields extends StatefulWidget {
  const _MacroFields({required this.kcal, required this.protein, required this.fat, required this.carbs});
  final TextEditingController kcal;
  final TextEditingController protein;
  final TextEditingController fat;
  final TextEditingController carbs;

  @override
  State<_MacroFields> createState() => _MacroFieldsState();
}

class _MacroFieldsState extends State<_MacroFields> {
  late final _all = [widget.kcal, widget.protein, widget.fat, widget.carbs];

  void _changed() => setState(() {});

  @override
  void initState() {
    super.initState();
    for (final c in _all) {
      c.addListener(_changed);
    }
  }

  @override
  void dispose() {
    for (final c in _all) {
      c.removeListener(_changed);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fromMacros = _macroKcal(widget.protein, widget.fat, widget.carbs);
    final typed = parseNumber(widget.kcal.text);
    final String? hint;
    if (fromMacros <= 0) {
      hint = 'Можно указать только калории. БЖУ точнее: их видно на упаковке, на 100 г.';
    } else if (typed == null) {
      hint = 'По БЖУ выходит ${_kcal(fromMacros)}, запишу их';
    } else if ((typed - fromMacros).abs() > max(30, typed * 0.15)) {
      hint = 'По БЖУ выходит ${_kcal(fromMacros)}. Проверь цифры';
    } else {
      hint = null;
    }
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NumberField(controller: widget.kcal, label: 'Калории', suffix: 'ккал'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: NumberField(controller: widget.protein, label: 'Белки', suffix: 'г'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: NumberField(controller: widget.fat, label: 'Жиры', suffix: 'г'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: NumberField(controller: widget.carbs, label: 'Углев.', suffix: 'г'),
            ),
          ],
        ),
        if (hint != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(hint, style: TextStyle(color: muted, fontSize: 12, height: 1.3)),
          ),
      ],
    );
  }
}

double _macroKcal(TextEditingController p, TextEditingController f, TextEditingController c) =>
    kcalFromMacros(protein: parseNumber(p.text) ?? 0, fat: parseNumber(f.text) ?? 0, carbs: parseNumber(c.text) ?? 0);

/// Калории из поля, а если поле пустое, из БЖУ. null, если нет ни того, ни другого.
double? _kcalOrMacros(TextEditingController k, TextEditingController p, TextEditingController f, TextEditingController c) {
  final typed = parseNumber(k.text);
  if (typed != null && typed > 0) return typed;
  final m = _macroKcal(p, f, c);
  return m > 0 ? m.roundToDouble() : null;
}

TextEditingController _num(double? v, {int decimals = 0}) =>
    TextEditingController(text: v == null || v == 0 ? '' : formatNumber(v, maxDecimals: decimals));

/// Записать еду вручную или поправить запись.
Future<void> showMealSheet(BuildContext context, {required int day, Meal? existing, MealSlot? slot}) {
  final name = TextEditingController(text: existing?.name ?? '');
  final kcal = _num(existing?.kcal);
  final protein = _num(existing?.protein, decimals: 1);
  final fat = _num(existing?.fat, decimals: 1);
  final carbs = _num(existing?.carbs, decimals: 1);
  final grams = _num(existing?.grams);
  // Если вес известен, его правка пересчитывает калории и БЖУ.
  final origGrams = existing?.grams;
  void rescale(String _) {
    final g = parseNumber(grams.text);
    if (existing == null || origGrams == null || origGrams <= 0 || g == null || g <= 0) return;
    final k = g / origGrams;
    kcal.text = formatNumber(existing.kcal * k, maxDecimals: 0);
    protein.text = formatNumber(existing.protein * k, maxDecimals: 1);
    fat.text = formatNumber(existing.fat * k, maxDecimals: 1);
    carbs.text = formatNumber(existing.carbs * k, maxDecimals: 1);
  }

  var icon = iconKeyFor(existing?.icon) ?? 'restaurant';
  var mealSlot = slot ?? (existing == null ? MealSlot.forTime(DateTime.now()) : MealSlot.of(existing));
  var remember = false;
  return showFormSheet(
    context,
    (sheet) => StatefulBuilder(
      builder: (sheet, setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(existing == null ? 'Что съел' : 'Запись', style: Theme.of(sheet).textTheme.titleLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            children: [
              for (final s in MealSlot.values)
                ChoiceChip(label: Text(s.label), selected: mealSlot == s, onSelected: (_) => setState(() => mealSlot = s)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconField(value: icon, fallback: 'restaurant', onChanged: (v) => setState(() => icon = v)),
              const SizedBox(width: 14),
              Expanded(
                child: TextField(
                  controller: name,
                  autofocus: existing == null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Название'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: grams,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: rescale,
            decoration: InputDecoration(
              labelText: 'Вес, необязательно',
              suffixText: 'г',
              helperText: origGrams != null ? 'Поменяй вес, и калории с БЖУ пересчитаются' : null,
            ),
          ),
          const SizedBox(height: 10),
          _MacroFields(kcal: kcal, protein: protein, fat: fat, carbs: carbs),
          if (existing == null)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: remember,
              onChanged: (v) => setState(() => remember = v ?? false),
              title: const Text('Сохранить в быстрые блюда'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () async {
              final k = _kcalOrMacros(kcal, protein, fat, carbs);
              if (name.text.trim().isEmpty || k == null) return showSnack(sheet, 'Заполни название и калории или БЖУ');
              final p = parseNumber(protein.text) ?? 0, f = parseNumber(fat.text) ?? 0, c = parseNumber(carbs.text) ?? 0;
              final g = parseNumber(grams.text);
              final w = g == null || g <= 0 ? null : g;
              final db = sheet.db;
              int? foodId = existing?.foodId;
              if (remember) {
                foodId = await db.saveFood(
                  FoodsCompanion.insert(
                    name: name.text.trim(),
                    icon: Value(icon),
                    kcal: k,
                    protein: Value(p),
                    fat: Value(f),
                    carbs: Value(c),
                    grams: Value(w),
                  ),
                );
              }
              await db.saveMeal(
                MealsCompanion(
                  id: existing == null ? const Value.absent() : Value(existing.id),
                  day: Value(existing?.day ?? day),
                  name: Value(name.text.trim()),
                  icon: Value(icon),
                  kcal: Value(k),
                  protein: Value(p),
                  fat: Value(f),
                  carbs: Value(c),
                  slot: Value(mealSlot.index),
                  grams: Value(w),
                  foodId: Value(foodId),
                ),
              );
              if (sheet.mounted) Navigator.pop(sheet);
            },
            child: const Text('Сохранить'),
          ),
          if (existing != null)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Theme.of(sheet).colorScheme.error),
              onPressed: () async {
                await sheet.db.deleteById(sheet.db.meals, existing.id);
                if (sheet.mounted) Navigator.pop(sheet);
              },
              child: const Text('Удалить'),
            ),
        ],
      ),
    ),
  );
}

/// Новое быстрое блюдо или правка старого.
Future<void> showFoodEditSheet(BuildContext context, {Food? existing}) {
  if (existing?.ingredients != null) return showRecipeSheet(context, existing: existing);
  final grams = _num(existing?.grams);
  final name = TextEditingController(text: existing?.name ?? '');
  final kcal = _num(existing?.kcal);
  final protein = _num(existing?.protein, decimals: 1);
  final fat = _num(existing?.fat, decimals: 1);
  final carbs = _num(existing?.carbs, decimals: 1);
  var icon = iconKeyFor(existing?.icon) ?? 'restaurant';
  return showFormSheet(
    context,
    (sheet) => StatefulBuilder(
      builder: (sheet, setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(existing == null ? 'Новое блюдо' : 'Блюдо', style: Theme.of(sheet).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Порция, которую обычно ешь. Укажи её вес, и потом можно будет записать любое количество в граммах.',
            style: TextStyle(color: Theme.of(sheet).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              IconField(value: icon, fallback: 'restaurant', onChanged: (v) => setState(() => icon = v)),
              const SizedBox(width: 14),
              Expanded(
                child: TextField(
                  controller: name,
                  autofocus: existing == null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Название'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          NumberField(controller: grams, label: 'Вес порции, необязательно', suffix: 'г'),
          const SizedBox(height: 10),
          _MacroFields(kcal: kcal, protein: protein, fat: fat, carbs: carbs),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              final k = _kcalOrMacros(kcal, protein, fat, carbs);
              if (name.text.trim().isEmpty || k == null) return showSnack(sheet, 'Заполни название и калории или БЖУ');
              await sheet.db.saveFood(
                FoodsCompanion(
                  id: existing == null ? const Value.absent() : Value(existing.id),
                  name: Value(name.text.trim()),
                  icon: Value(icon),
                  kcal: Value(k),
                  protein: Value(parseNumber(protein.text) ?? 0),
                  fat: Value(parseNumber(fat.text) ?? 0),
                  carbs: Value(parseNumber(carbs.text) ?? 0),
                  grams: Value(switch (parseNumber(grams.text)) {
                    final g? when g > 0 => g,
                    _ => null,
                  }),
                ),
              );
              if (sheet.mounted) Navigator.pop(sheet);
            },
            child: const Text('Сохранить'),
          ),
          if (existing != null)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Theme.of(sheet).colorScheme.error),
              onPressed: () async {
                // Прячем, а не удаляем: записи о съеденном остаются как были.
                await sheet.db.setArchived(sheet.db.foods, existing.id, true);
                if (sheet.mounted) Navigator.pop(sheet);
              },
              child: const Text('Убрать из быстрых'),
            ),
        ],
      ),
    ),
  );
}

Future<void> showFoodGoalsSheet(BuildContext context, {required FoodGoals goals, required List<Tracker> trackers, double? weight}) {
  final kcal = TextEditingController(text: formatNumber(goals.kcal, maxDecimals: 0));
  final protein = TextEditingController(text: formatNumber(goals.protein, maxDecimals: 0));
  final fat = TextEditingController(text: formatNumber(goals.fat, maxDecimals: 0));
  final carbs = TextEditingController(text: formatNumber(goals.carbs, maxDecimals: 0));
  final water = TextEditingController(text: '${goals.water}');
  final glass = TextEditingController(text: '${goals.glass}');
  final kcalMin = TextEditingController(text: goals.kcalMin == null ? '' : formatNumber(goals.kcalMin!, maxDecimals: 0));
  final proteinMin = TextEditingController(text: goals.proteinMin == null ? '' : formatNumber(goals.proteinMin!, maxDecimals: 0));
  var mode = goals.mode;
  var weightTracker = goals.weightTrackerId;
  var onToday = goals.onToday;
  final numeric = trackers.where((t) => t.kind == TrackerKind.number).toList();
  return showFormSheet(
    context,
    (sheet) => StatefulBuilder(
      builder: (sheet, setState) {
        final muted = Theme.of(sheet).colorScheme.onSurfaceVariant;
        final macroKcal = _macroKcal(protein, fat, carbs);
        final k = parseNumber(kcal.text) ?? 0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Цели питания', style: Theme.of(sheet).textTheme.titleLarge),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(sheet);
                showFoodCalcSheet(context, goals: goals, weight: weight);
              },
              icon: const Icon(Icons.calculate_rounded),
              label: const Text('Рассчитать по формуле'),
            ),
            const SizedBox(height: 16),
            SegmentedButton<FoodMode>(
              showSelectedIcon: false,
              segments: [for (final m in FoodMode.values) ButtonSegment(value: m, label: Text(m.short))],
              selected: {mode},
              onSelectionChanged: (s) => setState(() => mode = s.first),
            ),
            const SizedBox(height: 16),
            NumberField(controller: kcal, label: 'Калории в день', suffix: 'ккал'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: NumberField(controller: protein, label: 'Белки', suffix: 'г'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: NumberField(controller: fat, label: 'Жиры', suffix: 'г'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: NumberField(controller: carbs, label: 'Углев.', suffix: 'г'),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                (k - macroKcal).abs() > 100
                    ? 'БЖУ дают ${_kcal(macroKcal)}, а цель ${_kcal(k)}. Лучше, чтобы сходилось: поправь углеводы.'
                    : 'БЖУ дают ${_kcal(macroKcal)}, сходится с целью.',
                style: TextStyle(color: muted, fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
            Text('Минимум на тяжёлый день', style: Theme.of(sheet).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                if (mode != FoodMode.lose) ...[
                  Expanded(
                    child: NumberField(controller: kcalMin, label: 'Калории', suffix: 'ккал'),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: NumberField(controller: proteinMin, label: 'Белок', suffix: 'г'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: NumberField(controller: water, label: 'Вода в день', suffix: 'мл'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: NumberField(controller: glass, label: 'Стакан', suffix: 'мл'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              initialValue: numeric.any((t) => t.id == weightTracker) ? weightTracker : null,
              decoration: const InputDecoration(labelText: 'Трекер веса для подсказок'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Не нужен')),
                for (final t in numeric) DropdownMenuItem(value: t.id, child: Text(t.name)),
              ],
              onChanged: (v) => setState(() => weightTracker = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Показывать на «Сегодня»'),
              value: onToday,
              onChanged: (v) => setState(() => onToday = v),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () async {
                final db = sheet.db;
                final k = parseNumber(kcal.text);
                if (k == null || k <= 0) return showSnack(sheet, 'Укажи калории');
                String? grams(TextEditingController c) => parseNumber(c.text) == null ? null : '${parseNumber(c.text)!.round()}';
                await db.setSetting(FoodGoals.keyKcal, '${k.round()}');
                await db.setSetting(FoodGoals.keyProtein, grams(protein) ?? '0');
                await db.setSetting(FoodGoals.keyFat, grams(fat));
                await db.setSetting(FoodGoals.keyCarbs, grams(carbs));
                final km = parseNumber(kcalMin.text), pm = parseNumber(proteinMin.text);
                await db.setSetting(FoodGoals.keyKcalMin, km == null || km <= 0 ? null : '${km.round()}');
                await db.setSetting(FoodGoals.keyProteinMin, pm == null || pm <= 0 ? null : '${pm.round()}');
                await db.setSetting(FoodGoals.keyWater, '${(parseNumber(water.text) ?? 2000).round()}');
                await db.setSetting(FoodGoals.keyGlass, '${(parseNumber(glass.text) ?? 250).round().clamp(50, 1000)}');
                await db.setSetting(FoodGoals.keyMode, mode.name);
                await db.setSetting(FoodGoals.keyWeight, weightTracker == null ? null : '$weightTracker');
                await db.setSetting(FoodGoals.keyOn, onToday ? '1' : null);
                if (sheet.mounted) Navigator.pop(sheet);
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    ),
  );
}

/// Расчёт нормы по росту, весу, возрасту и активности, с пояснением каждой цифры.
Future<void> showFoodCalcSheet(BuildContext context, {required FoodGoals goals, double? weight}) async {
  final settings = await context.db.watchAllSettings().first;
  if (!context.mounted) return;
  final body = Body.from(settings);
  final birth = TextEditingController(text: settings[Body.keyBirthYear] ?? '');
  final height = TextEditingController(text: body == null ? '' : formatNumber(body.heightCm, maxDecimals: 0));
  final weightField = TextEditingController(text: weight == null ? '' : formatNumber(weight, maxDecimals: 1));
  var sex = body?.sex ?? Sex.male;
  var activity = body?.activity ?? Activity.moderate;
  var mode = goals.mode;
  if (!context.mounted) return;
  return showFormSheet(
    context,
    (sheet) => StatefulBuilder(
      builder: (sheet, setState) {
        final theme = Theme.of(sheet);
        final muted = theme.colorScheme.onSurfaceVariant;
        final year = int.tryParse(birth.text.trim());
        final h = parseNumber(height.text);
        final w = parseNumber(weightField.text);
        final now = DateTime.now().year;
        final valid =
            year != null && year > now - 100 && year < now - 12 && h != null && h > 100 && h < 250 && w != null && w > 30 && w < 300;
        final plan = valid ? planFor(Body(sex: sex, age: now - year, heightCm: h, activity: activity), w, mode) : null;
        void redraw(String _) => setState(() {});
        Widget row(String label, String value, {String? note, bool strong = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: strong ? const TextStyle(fontWeight: FontWeight.w700) : null),
                    if (note != null) Text(note, style: TextStyle(color: muted, fontSize: 12, height: 1.3)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(value, style: TextStyle(fontWeight: strong ? FontWeight.w700 : FontWeight.w600)),
            ],
          ),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Расчёт нормы', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            SegmentedButton<Sex>(
              showSelectedIcon: false,
              segments: [for (final s in Sex.values) ButtonSegment(value: s, label: Text(s.label))],
              selected: {sex},
              onSelectionChanged: (s) => setState(() => sex = s.first),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: birth,
                    keyboardType: TextInputType.number,
                    onChanged: redraw,
                    decoration: const InputDecoration(labelText: 'Год рожд.'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: height,
                    keyboardType: TextInputType.number,
                    onChanged: redraw,
                    decoration: const InputDecoration(labelText: 'Рост', suffixText: 'см'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: weightField,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: redraw,
                    decoration: const InputDecoration(labelText: 'Вес', suffixText: 'кг'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Activity>(
              initialValue: activity,
              isExpanded: true,
              decoration: InputDecoration(labelText: 'Активность', helperText: activity.hint),
              selectedItemBuilder: (_) => [for (final a in Activity.values) Text(a.label)],
              items: [
                for (final a in Activity.values)
                  DropdownMenuItem(
                    value: a,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(a.label),
                        Text(
                          a.hint,
                          style: TextStyle(color: muted, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
              ],
              onChanged: (a) => setState(() => activity = a ?? activity),
            ),
            const SizedBox(height: 12),
            SegmentedButton<FoodMode>(
              showSelectedIcon: false,
              segments: [for (final m in FoodMode.values) ButtonSegment(value: m, label: Text(m.short))],
              selected: {mode},
              onSelectionChanged: (s) => setState(() => mode = s.first),
            ),
            const SizedBox(height: 14),
            if (plan == null)
              Text('Заполни год рождения, рост и вес, и здесь появится расчёт.', style: TextStyle(color: muted))
            else
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  child: Column(
                    children: [
                      row('Обмен в покое', _kcal(plan.resting), note: 'формула Миффлина — Сан Жеора'),
                      row(
                        'Чтобы держать вес',
                        _kcal(plan.maintenance),
                        note: '× ${formatNumber(activity.factor, maxDecimals: 3)} за активность',
                      ),
                      row(
                        'Цель',
                        _kcal(plan.kcal),
                        strong: true,
                        note: switch (mode) {
                          FoodMode.gain => '+10%: вес растёт на 0,25–0,5% в неделю, почти без жира',
                          FoodMode.keep => 'ровно столько, сколько тратишь',
                          FoodMode.lose => '−20%: минус 0,5–1% веса в неделю, мышцы сохраняются',
                        },
                      ),
                      const Divider(),
                      row(
                        'Белки',
                        _grams(plan.protein),
                        note:
                            '${formatNumber(plan.protein / w!, maxDecimals: 1)} г на кг: для роста мышц хватает 1,6, больше 2,2 смысла нет',
                      ),
                      row('Жиры', _grams(plan.fat), note: 'около 25% калорий, для гормонов нужно не меньше 20%'),
                      row('Углеводы', _grams(plan.carbs), note: 'остальные калории: энергия на работу и тренировки'),
                      row('Вода', _liters(plan.water), note: '30 мл на кг из напитков, в жару и после тренировки больше'),
                      row('Белок за приём', _grams(plan.perMeal), note: '0,4 г на кг, лучше 3–5 приёмов в день'),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 10),
            Text(
              'Формула даёт оценку с точностью около 10%. Через 2–3 недели взвешиваний подсказка на экране «Питание» '
              'покажет, нужно ли поправить калории.',
              style: TextStyle(color: muted, fontSize: 12, height: 1.35),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: plan == null
                  ? null
                  : () async {
                      final db = sheet.db;
                      await db.setSetting(Body.keySex, sex.name);
                      await db.setSetting(Body.keyBirthYear, '$year');
                      await db.setSetting(Body.keyHeight, '${h!.round()}');
                      await db.setSetting(Body.keyActivity, activity.name);
                      await db.setSetting(FoodGoals.keyMode, mode.name);
                      await db.setSetting(FoodGoals.keyKcal, '${plan.kcal.round()}');
                      await db.setSetting(FoodGoals.keyProtein, '${plan.protein.round()}');
                      await db.setSetting(FoodGoals.keyFat, '${plan.fat.round()}');
                      await db.setSetting(FoodGoals.keyCarbs, '${plan.carbs.round()}');
                      await db.setSetting(FoodGoals.keyWater, '${plan.water}');
                      if (sheet.mounted) Navigator.pop(sheet);
                      if (context.mounted) showSnack(context, 'Норма обновлена: ${_kcal(plan.kcal)}');
                    },
              child: const Text('Применить'),
            ),
          ],
        );
      },
    ),
  );
}

/// Добавить еду с экрана «Сегодня»: тот же поиск, что и в «Питании».
Future<void> showEatSheet(BuildContext context, {required int day}) => showAddFoodSheet(context, day: day);

// ---------------------------------------------------------------------------
// Карточка на «Сегодня»
// ---------------------------------------------------------------------------

class FoodTodayCard extends StatelessWidget {
  const FoodTodayCard({super.key, required this.today, required this.totals, required this.goals});
  final int today;
  final DayFood totals;
  final FoodGoals goals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final glasses = (totals.water / goals.glass).floor();
    final goalGlasses = (goals.water / goals.glass).ceil();
    return Card(
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FoodScreen())),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const ColorIcon(Icons.restaurant_rounded, color: Accent.food),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: formatNumber(totals.kcal, maxDecimals: 0),
                                style: const TextStyle(fontWeight: FontWeight.w700, color: Accent.food),
                              ),
                              TextSpan(text: ' из ${_kcal(goals.kcal)}'),
                            ],
                          ),
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          'белок ${formatNumber(totals.protein, maxDecimals: 0)} из ${_grams(goals.protein)} · вода $glasses из $goalGlasses',
                          style: TextStyle(color: muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ProgressLine(value: goals.kcal <= 0 ? 0 : totals.kcal / goals.kcal, color: Accent.food, height: 8),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Accent.food,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 44),
                      ),
                      onPressed: () => showEatSheet(context, day: today),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Еда'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Accent.water.withValues(alpha: 0.14),
                        foregroundColor: Accent.water,
                        minimumSize: const Size(0, 44),
                      ),
                      onPressed: () => addGlass(context, day: today, ml: goals.glass),
                      icon: const Icon(Icons.water_drop_rounded),
                      label: const Text('Стакан'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
