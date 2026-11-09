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
import 'icons.dart';
import 'theme.dart';

String _kcal(double v) => '${formatNumber(v, maxDecimals: 0)} ккал';
String _grams(double v) => '${formatNumber(v, maxDecimals: 0)} г';
String _liters(int ml) => '${formatNumber(ml / 1000, maxDecimals: 1)} л';

/// Добавить блюдо в один тап и показать «Отменить».
Future<void> eatFood(BuildContext context, Food f, {required int day}) async {
  final db = context.db;
  final messenger = ScaffoldMessenger.of(context);
  final id = await db.eatFood(f, day: day);
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

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    final today = todayKey();
    final weekFrom = addDays(_day, -6);
    return Watch(
      deps: [_day],
      streams: () => [
        db.watchAllSettings(),
        db.watchFoods(),
        db.watchMeals(from: weekFrom, to: _day),
        db.watchWater(from: weekFrom, to: _day),
        db.watchTrackers(),
        db.watchAllEntries(),
      ],
      builder: (context, v) {
        final settings = v[0] as Map<String, String>;
        final goals = FoodGoals.from(settings);
        final foods = v[1] as List<Food>;
        final meals = v[2] as List<Meal>;
        final water = v[3] as List<WaterLog>;
        final trackers = v[4] as List<Tracker>;
        final entries = v[5] as List<TrackerEntry>;
        final totals = dayFood(_day, meals, water);
        final dayMeals = meals.where((m) => m.day == _day).toList();
        final weight = trackers.where((t) => t.id == goals.weightTrackerId).firstOrNull;
        final advice = weight == null ? null : weightAdvice(dailySeries(weight, entries), goals.mode, today: today);
        final week = [for (var i = 6; i >= 0; i--) dayFood(addDays(_day, -i), meals, water)];
        final logged = week.where((d) => d.kcal > 0).toList();
        return ScrollFabScope(
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Питание'),
              actions: [
                IconButton(
                  tooltip: 'Цели',
                  icon: const Icon(Icons.tune_rounded),
                  onPressed: () => showFoodGoalsSheet(context, goals: goals, trackers: trackers),
                ),
              ],
            ),
            floatingActionButton: ScrollFab(
              child: FloatingActionButton.extended(
                heroTag: null,
                backgroundColor: Accent.food,
                foregroundColor: Colors.white,
                onPressed: () => showMealSheet(context, day: _day),
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Вручную'),
              ),
            ),
            body: ListView(
              padding: const EdgeInsets.only(bottom: 110),
              children: [
                _FoodHero(day: _day, today: today, totals: totals, goals: goals, onShift: (d) => setState(() => _day = addDays(_day, d))),
                if (advice != null) _AdviceCard(text: advice.text, adjust: advice.adjust),
                SectionTitle(
                  'Быстро добавить',
                  trailing: IconButton(
                    tooltip: 'Новое блюдо',
                    icon: const Icon(Icons.add_rounded),
                    onPressed: () => showFoodEditSheet(context),
                  ),
                ),
                if (foods.isEmpty)
                  Card(
                    child: EmptyHint(
                      'Добавь то, что ешь часто: завтрак, обед, перекус. Потом записывать еду можно одним нажатием.',
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
                SectionTitle('Съедено', trailing: dayMeals.isEmpty ? null : Pill(_kcal(totals.kcal), color: Accent.food)),
                if (dayMeals.isEmpty)
                  const Card(child: EmptyHint('Пока ничего. Нажми на блюдо выше, и оно запишется.', icon: Icons.no_food_rounded)),
                if (dayMeals.isNotEmpty)
                  GroupCard(
                    children: [
                      for (final m in dayMeals)
                        ListTile(
                          leading: ItemIcon(m.icon, size: 40, fallback: 'restaurant'),
                          title: Text(m.name, maxLines: 2, overflow: TextOverflow.ellipsis),
                          subtitle: Text('${formatMinutes(m.at.hour * 60 + m.at.minute)} · белок ${_grams(m.protein)}'),
                          trailing: Text(_kcal(m.kcal), style: const TextStyle(fontWeight: FontWeight.w700)),
                          onTap: () => showMealSheet(context, day: _day, existing: m),
                        ),
                    ],
                  ),
                const SectionTitle('Неделя'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BarChart(
                          bars: [
                            for (var i = 0; i < 7; i++)
                              (
                                weekdayShort[dayFromKey(addDays(_day, i - 6)).weekday - 1].substring(0, 1),
                                week[i].kcal == 0 ? null : week[i].kcal,
                              ),
                          ],
                          target: goals.kcal,
                          minimum: goals.mode == FoodMode.lose ? null : goals.kcalMin,
                          color: Accent.food.withValues(alpha: 0.3),
                          minColor: Accent.food.withValues(alpha: 0.6),
                          goodColor: Accent.food,
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            logged.isEmpty
                                ? 'Цель: ${_kcal(goals.kcal)} и ${_grams(goals.protein)} белка в день'
                                : 'Норма в ${logged.where((d) => foodLevel(d, goals) == Level.full).length} из ${logged.length} дней'
                                      '${goals.kcalMin != null || goals.proteinMin != null ? ', минимум в ${logged.where((d) => foodLevel(d, goals) == Level.minimum).length}' : ''} · '
                                      'в среднем ${_kcal(logged.fold<double>(0, (a, d) => a + d.kcal) / logged.length)} '
                                      'и ${_grams(logged.fold<double>(0, (a, d) => a + d.protein) / logged.length)} белка',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
                      left > 0 ? 'Осталось ${_kcal(left)}' : 'Норма калорий набрана',
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
                      label: 'Белок',
                      value: totals.protein,
                      goal: goals.protein,
                      text: '${_grams(totals.protein)} из ${_grams(goals.protein)}',
                    ),
                    const SizedBox(height: 10),
                    _HeroBar(
                      label: 'Вода',
                      value: totals.water.toDouble(),
                      goal: goals.water.toDouble(),
                      text: '${_liters(totals.water)} из ${_liters(goals.water)}',
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

class _AdviceCard extends StatelessWidget {
  const _AdviceCard({required this.text, required this.adjust});
  final String text;
  final bool adjust;

  @override
  Widget build(BuildContext context) {
    final color = adjust ? Accent.money : Accent.habits;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            ColorIcon(adjust ? Icons.tips_and_updates_rounded : Icons.trending_up_rounded, color: color, size: 40),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: const TextStyle(height: 1.35))),
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
                '${_kcal(food.kcal)} · ${_grams(food.protein)}',
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

/// Записать еду вручную или поправить запись.
Future<void> showMealSheet(BuildContext context, {required int day, Meal? existing}) {
  final name = TextEditingController(text: existing?.name ?? '');
  final kcal = TextEditingController(text: existing == null ? '' : formatNumber(existing.kcal, maxDecimals: 0));
  final protein = TextEditingController(text: existing == null ? '' : formatNumber(existing.protein, maxDecimals: 1));
  var icon = iconKeyFor(existing?.icon) ?? 'restaurant';
  var remember = false;
  return showFormSheet(
    context,
    (sheet) => StatefulBuilder(
      builder: (sheet, setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(existing == null ? 'Что съел' : 'Запись', style: Theme.of(sheet).textTheme.titleLarge),
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
          Row(
            children: [
              Expanded(
                child: NumberField(controller: kcal, label: 'Калории', suffix: 'ккал'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: NumberField(controller: protein, label: 'Белок', suffix: 'г'),
              ),
            ],
          ),
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
              final k = parseNumber(kcal.text);
              if (name.text.trim().isEmpty || k == null || k <= 0) return showSnack(sheet, 'Заполни название и калории');
              final p = parseNumber(protein.text) ?? 0;
              final db = sheet.db;
              int? foodId = existing?.foodId;
              if (remember) {
                foodId = await db.saveFood(FoodsCompanion.insert(name: name.text.trim(), icon: Value(icon), kcal: k, protein: Value(p)));
              }
              await db.saveMeal(
                MealsCompanion(
                  id: existing == null ? const Value.absent() : Value(existing.id),
                  day: Value(existing?.day ?? day),
                  name: Value(name.text.trim()),
                  icon: Value(icon),
                  kcal: Value(k),
                  protein: Value(p),
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
  final name = TextEditingController(text: existing?.name ?? '');
  final kcal = TextEditingController(text: existing == null ? '' : formatNumber(existing.kcal, maxDecimals: 0));
  final protein = TextEditingController(text: existing == null ? '' : formatNumber(existing.protein, maxDecimals: 1));
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
            'Порция, которую обычно ешь. Калории и белок примерные, этого достаточно.',
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
          Row(
            children: [
              Expanded(
                child: NumberField(controller: kcal, label: 'Калории', suffix: 'ккал'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: NumberField(controller: protein, label: 'Белок', suffix: 'г'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              final k = parseNumber(kcal.text);
              if (name.text.trim().isEmpty || k == null || k <= 0) return showSnack(sheet, 'Заполни название и калории');
              await sheet.db.saveFood(
                FoodsCompanion(
                  id: existing == null ? const Value.absent() : Value(existing.id),
                  name: Value(name.text.trim()),
                  icon: Value(icon),
                  kcal: Value(k),
                  protein: Value(parseNumber(protein.text) ?? 0),
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

Future<void> showFoodGoalsSheet(BuildContext context, {required FoodGoals goals, required List<Tracker> trackers}) {
  final kcal = TextEditingController(text: formatNumber(goals.kcal, maxDecimals: 0));
  final protein = TextEditingController(text: formatNumber(goals.protein, maxDecimals: 0));
  final water = TextEditingController(text: '${goals.water}');
  final glass = TextEditingController(text: '${goals.glass}');
  final kcalMin = TextEditingController(text: goals.kcalMin == null ? '' : formatNumber(goals.kcalMin!, maxDecimals: 0));
  final proteinMin = TextEditingController(text: goals.proteinMin == null ? '' : formatNumber(goals.proteinMin!, maxDecimals: 0));
  var mode = goals.mode;
  var weight = goals.weightTrackerId;
  var onToday = goals.onToday;
  final numeric = trackers.where((t) => t.kind == TrackerKind.number).toList();
  return showFormSheet(
    context,
    (sheet) => StatefulBuilder(
      builder: (sheet, setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Цели питания', style: Theme.of(sheet).textTheme.titleLarge),
          const SizedBox(height: 16),
          SegmentedButton<FoodMode>(
            showSelectedIcon: false,
            segments: [for (final m in FoodMode.values) ButtonSegment(value: m, label: Text(m.label))],
            selected: {mode},
            onSelectionChanged: (s) => setState(() => mode = s.first),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: NumberField(controller: kcal, label: 'Калории в день', suffix: 'ккал'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: NumberField(controller: protein, label: 'Белок в день', suffix: 'г'),
              ),
            ],
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
            initialValue: numeric.any((t) => t.id == weight) ? weight : null,
            decoration: const InputDecoration(labelText: 'Трекер веса для подсказок'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Не нужен')),
              for (final t in numeric) DropdownMenuItem(value: t.id, child: Text(t.name)),
            ],
            onChanged: (v) => setState(() => weight = v),
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
              await db.setSetting(FoodGoals.keyKcal, '${k.round()}');
              await db.setSetting(FoodGoals.keyProtein, '${(parseNumber(protein.text) ?? 0).round()}');
              final km = parseNumber(kcalMin.text), pm = parseNumber(proteinMin.text);
              await db.setSetting(FoodGoals.keyKcalMin, km == null || km <= 0 ? null : '${km.round()}');
              await db.setSetting(FoodGoals.keyProteinMin, pm == null || pm <= 0 ? null : '${pm.round()}');
              await db.setSetting(FoodGoals.keyWater, '${(parseNumber(water.text) ?? 2000).round()}');
              await db.setSetting(FoodGoals.keyGlass, '${(parseNumber(glass.text) ?? 250).round().clamp(50, 1000)}');
              await db.setSetting(FoodGoals.keyMode, mode.name);
              await db.setSetting(FoodGoals.keyWeight, weight == null ? null : '$weight');
              await db.setSetting(FoodGoals.keyOn, onToday ? '1' : null);
              if (sheet.mounted) Navigator.pop(sheet);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    ),
  );
}

/// Список быстрых блюд в нижнем листе: для кнопки «Еда» на экране «Сегодня».
Future<void> showEatSheet(BuildContext context, {required int day}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheet) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      maxChildSize: 0.95,
      builder: (sheet, scroll) => StreamBuilder<List<Food>>(
        stream: sheet.db.watchFoods(),
        builder: (sheet, snap) {
          final foods = snap.data ?? const <Food>[];
          return ListView(
            controller: scroll,
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text('Что съел?', style: Theme.of(sheet).textTheme.titleLarge),
              ),
              for (final f in foods)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  leading: ItemIcon(f.icon, size: 40, fallback: 'restaurant'),
                  title: Text(f.name),
                  subtitle: Text('${_kcal(f.kcal)} · белок ${_grams(f.protein)}'),
                  trailing: const Icon(Icons.add_circle_rounded, color: Accent.food),
                  onTap: () {
                    Navigator.pop(sheet);
                    eatFood(context, f, day: day);
                  },
                ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                leading: const ColorIcon(Icons.edit_rounded, color: Accent.settings, size: 40),
                title: const Text('Записать вручную'),
                onTap: () {
                  Navigator.pop(sheet);
                  showMealSheet(context, day: day);
                },
              ),
            ],
          );
        },
      ),
    ),
  );
}

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
