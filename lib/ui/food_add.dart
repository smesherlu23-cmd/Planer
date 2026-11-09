// Добавление еды: поиск по своим блюдам, недавнему и справочнику, ввод граммов и порций,
// рецепты из ингредиентов и библиотека своих блюд.
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import '../data/database.dart';
import '../data/dates.dart';
import '../data/food_catalog.dart';
import '../data/icon_keys.dart';
import '../data/queries.dart';
import '../logic/calc.dart';
import '../logic/food.dart';
import 'common.dart';
import 'food_screen.dart';
import 'icons.dart';
import 'theme.dart';

String _kcal(double v) => '${formatNumber(v, maxDecimals: 0)} ккал';
String _g(double v) => '${formatNumber(v, maxDecimals: 0)} г';
String _bju(Macros m) =>
    'Б ${formatNumber(m.protein, maxDecimals: 0)} · Ж ${formatNumber(m.fat, maxDecimals: 0)} · У ${formatNumber(m.carbs, maxDecimals: 0)}';

/// Поиск без учёта регистра и разницы «е» и «ё».
String _norm(String s) => s.toLowerCase().replaceAll('ё', 'е').trim();

bool _matches(String name, String query) {
  if (query.isEmpty) return true;
  final n = _norm(name);
  return _norm(query).split(RegExp(r'\s+')).every(n.contains);
}

/// Что можно записать: своё блюдо, продукт из справочника или недавняя запись.
class FoodPick {
  const FoodPick({
    required this.name,
    required this.icon,
    required this.base,
    this.baseGrams,
    this.defaultGrams,
    this.portionName,
    this.food,
    this.catalog = false,
  });

  factory FoodPick.food(Food f) =>
      FoodPick(name: f.name, icon: f.icon, base: foodMacros(f), baseGrams: f.grams, defaultGrams: f.grams, food: f);

  factory FoodPick.catalog(CatalogFood c) => FoodPick(
    name: c.name,
    icon: c.icon,
    base: (kcal: c.kcal, protein: c.protein, fat: c.fat, carbs: c.carbs),
    baseGrams: 100,
    defaultGrams: c.portion,
    portionName: c.portionName,
    catalog: true,
  );

  factory FoodPick.meal(Meal m, Food? food) =>
      FoodPick(name: m.name, icon: m.icon, base: mealMacros(m), baseGrams: m.grams, defaultGrams: m.grams, food: food);

  final String name;
  final String icon;

  /// Цифры на [baseGrams] граммов, а если вес не известен, на одну порцию.
  final Macros base;
  final double? baseGrams;
  final double? defaultGrams;
  final String? portionName;
  final Food? food;
  final bool catalog;

  bool get byWeight => baseGrams != null && baseGrams! > 0;

  /// Порция по умолчанию: обычный вес или одна порция.
  Macros get defaultMacros => byWeight ? scaleMacros(base, (defaultGrams ?? baseGrams!) / baseGrams!) : base;

  String get subtitle {
    if (catalog) return '${_kcal(base.kcal)} на 100 г · ${_bju(base)}';
    final w = byWeight ? ' · ${_g(defaultGrams ?? baseGrams!)}' : '';
    return '${_kcal(defaultMacros.kcal)}$w · ${_bju(defaultMacros)}';
  }

  /// Состав на 100 г: для ингредиентов рецепта.
  Macros? get per100 => byWeight ? scaleMacros(base, 100 / baseGrams!) : null;
}

/// Записать порцию по умолчанию сразу, без вопросов.
Future<void> quickEat(BuildContext context, FoodPick p, {required int day, MealSlot? slot}) async {
  final m = p.defaultMacros;
  await _writeMeal(
    context,
    p,
    m,
    grams: p.byWeight ? (p.defaultGrams ?? p.baseGrams) : null,
    day: day,
    slot: slot ?? MealSlot.forTime(DateTime.now()),
  );
}

Future<void> _writeMeal(BuildContext context, FoodPick p, Macros m, {double? grams, required int day, required MealSlot slot}) async {
  final db = context.db;
  final messenger = ScaffoldMessenger.of(context);
  final id = await db.saveMeal(
    MealsCompanion.insert(
      day: day,
      name: p.name,
      icon: Value(p.icon),
      kcal: m.kcal,
      protein: Value(m.protein),
      fat: Value(m.fat),
      carbs: Value(m.carbs),
      slot: Value(slot.index),
      grams: Value(grams),
      foodId: Value(p.food?.id),
    ),
  );
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('Записано: ${p.name}, ${_kcal(m.kcal)}'),
        action: SnackBarAction(label: 'Отменить', onPressed: () => db.deleteById(db.meals, id)),
      ),
    );
}

// ---------------------------------------------------------------------------
// Поиск
// ---------------------------------------------------------------------------

/// Добавить еду: поиск по своим блюдам, недавнему и справочнику.
Future<void> showAddFoodSheet(BuildContext context, {required int day, MealSlot? slot}) async {
  final pick = await _showSearch(context, title: 'Добавить еду', day: day);
  if (pick == null || !context.mounted) return;
  if (pick.manual) return showMealSheet(context, day: day, slot: slot);
  if (pick.instant) return quickEat(context, pick.pick!, day: day, slot: slot);
  return showAmountSheet(context, pick.pick!, day: day, slot: slot);
}

class _SearchResult {
  const _SearchResult({this.pick, this.manual = false, this.instant = false});
  final FoodPick? pick;
  final bool manual;
  final bool instant;
}

Future<_SearchResult?> _showSearch(BuildContext context, {required String title, int? day, bool ingredients = false}) {
  return showModalBottomSheet<_SearchResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheet) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (sheet, scroll) => _SearchSheet(title: title, scroll: scroll, ingredients: ingredients),
    ),
  );
}

class _SearchSheet extends StatefulWidget {
  const _SearchSheet({required this.title, required this.scroll, required this.ingredients});
  final String title;
  final ScrollController scroll;

  /// Подбор ингредиента для рецепта: нужны только продукты с известным весом.
  final bool ingredients;

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  final _query = TextEditingController();
  String? _group;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    final today = todayKey();
    return Watch(
      streams: () => [db.watchFoods(), db.watchMeals(from: addDays(today, -30), to: today)],
      builder: (context, v) {
        final foods = (v[0] as List<Food>).where((f) => !widget.ingredients || (f.grams != null && f.ingredients == null)).toList();
        final meals = v[1] as List<Meal>;
        final q = _query.text;
        final theme = Theme.of(context);
        final muted = theme.colorScheme.onSurfaceVariant;

        // Недавнее: что ешь чаще всего за месяц, без повторов своих блюд.
        final byName = <String, (Meal, int)>{};
        for (final m in meals) {
          final prev = byName[m.name];
          byName[m.name] = (prev == null || m.at.isAfter(prev.$1.at) ? m : prev.$1, (prev?.$2 ?? 0) + 1);
        }
        final foodNames = {for (final f in foods) f.name};
        final recent = widget.ingredients
            ? <(Meal, int)>[]
            : (byName.values.where((e) => !foodNames.contains(e.$1.name) && _matches(e.$1.name, q)).toList()
                    ..sort((a, b) => b.$2.compareTo(a.$2)))
                  .take(q.isEmpty ? 6 : 20)
                  .toList();
        final mine = foods.where((f) => _matches(f.name, q)).toList()
          ..sort((a, b) => (byName[b.name]?.$2 ?? 0).compareTo(byName[a.name]?.$2 ?? 0));
        final catalog = foodCatalog.where((c) => _matches(c.name, q) && (q.isNotEmpty || _group == null || c.group == _group)).toList();

        Widget tile(FoodPick p, {Widget? badge}) => ListTile(
          contentPadding: const EdgeInsets.fromLTRB(20, 0, 8, 0),
          leading: ItemIcon(p.icon, size: 40, fallback: 'restaurant'),
          title: Row(
            children: [
              Flexible(child: Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis)),
              if (badge != null) ...[const SizedBox(width: 6), badge],
            ],
          ),
          subtitle: Text(p.subtitle, style: TextStyle(color: muted, fontSize: 12)),
          trailing: widget.ingredients
              ? const Icon(Icons.chevron_right_rounded)
              : IconButton(
                  tooltip: 'Записать сразу',
                  icon: const Icon(Icons.add_circle_rounded, color: Accent.food),
                  onPressed: () => Navigator.pop(context, _SearchResult(pick: p, instant: true)),
                ),
          onTap: () => Navigator.pop(context, _SearchResult(pick: p)),
        );

        Widget header(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
          child: Text(
            text,
            style: theme.textTheme.titleSmall?.copyWith(color: muted, fontWeight: FontWeight.w700),
          ),
        );

        return ListView(
          controller: widget.scroll,
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Text(widget.title, style: theme.textTheme.titleLarge),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _query,
                onChanged: (_) => setState(() {}),
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Гречка, творог, банан…',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: q.isEmpty
                      ? null
                      : IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => setState(() => _query.clear())),
                ),
              ),
            ),
            if (!widget.ingredients)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                leading: const ColorIcon(Icons.edit_rounded, color: Accent.settings, size: 40),
                title: const Text('Записать вручную'),
                subtitle: Text('Своё название, калории и БЖУ', style: TextStyle(color: muted, fontSize: 12)),
                onTap: () => Navigator.pop(context, const _SearchResult(manual: true)),
              ),
            if (recent.isNotEmpty) ...[
              header('Недавнее'),
              for (final (m, n) in recent) tile(FoodPick.meal(m, null), badge: n > 1 ? Pill('×$n') : null),
            ],
            if (mine.isNotEmpty) ...[
              header(widget.ingredients ? 'Мои продукты' : 'Мои блюда и рецепты'),
              for (final f in mine) tile(FoodPick.food(f), badge: f.ingredients != null ? const Pill('рецепт', color: Accent.food) : null),
            ],
            header('Справочник, на 100 г'),
            if (q.isEmpty)
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    for (final g in [null, ...catalogGroups])
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(label: Text(g ?? 'Всё'), selected: _group == g, onSelected: (_) => setState(() => _group = g)),
                      ),
                  ],
                ),
              ),
            for (final c in catalog) tile(FoodPick.catalog(c)),
            if (q.isNotEmpty && recent.isEmpty && mine.isEmpty && catalog.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  widget.ingredients
                      ? 'Ничего не нашлось. Добавь продукт в «Мои блюда» с весом порции, и он появится здесь.'
                      : 'Ничего не нашлось. Запиши вручную: цифры есть на упаковке.',
                  style: TextStyle(color: muted),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Сколько съел
// ---------------------------------------------------------------------------

/// Выбрать вес или число порций и записать.
Future<void> showAmountSheet(BuildContext context, FoodPick p, {required int day, MealSlot? slot}) {
  final byWeight = p.byWeight;
  final amount = TextEditingController(text: formatNumber(byWeight ? (p.defaultGrams ?? p.baseGrams!) : 1, maxDecimals: 1));
  var mealSlot = slot ?? MealSlot.forTime(DateTime.now());
  var remember = false;
  final presets = <(String, double)>[
    if (byWeight && p.portionName != null && p.defaultGrams != null)
      for (final n in [1, 2, 3]) ('$n ${p.portionName}', p.defaultGrams! * n)
    else if (byWeight)
      for (final g in {if (p.defaultGrams != null) p.defaultGrams!, 50.0, 100.0, 150.0, 200.0, 300.0}.toList()..sort()) (_g(g), g)
    else
      for (final k in [0.5, 1.0, 1.5, 2.0]) ('${formatNumber(k)} порц.', k),
  ];
  return showFormSheet(
    context,
    (sheet) => StatefulBuilder(
      builder: (sheet, setState) {
        final theme = Theme.of(sheet);
        final muted = theme.colorScheme.onSurfaceVariant;
        final a = parseNumber(amount.text) ?? 0;
        final m = scaleMacros(p.base, byWeight ? a / p.baseGrams! : a);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                ItemIcon(p.icon, size: 44, fallback: 'restaurant'),
                const SizedBox(width: 14),
                Expanded(child: Text(p.name, style: theme.textTheme.titleLarge)),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              children: [
                for (final s in MealSlot.values)
                  ChoiceChip(label: Text(s.label), selected: mealSlot == s, onSelected: (_) => setState(() => mealSlot = s)),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amount,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(labelText: byWeight ? 'Вес' : 'Порций', suffixText: byWeight ? 'г' : null),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final (label, value) in presets)
                  ActionChip(label: Text(label), onPressed: () => setState(() => amount.text = formatNumber(value, maxDecimals: 1))),
              ],
            ),
            const SizedBox(height: 14),
            Card(
              margin: EdgeInsets.zero,
              color: Accent.food.withValues(alpha: 0.08),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Text(
                      formatNumber(m.kcal, maxDecimals: 0),
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: Accent.food),
                    ),
                    const SizedBox(width: 6),
                    Text('ккал', style: TextStyle(color: muted)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${_bju(m)} г',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (p.food == null)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: remember,
                onChanged: (v) => setState(() => remember = v ?? false),
                title: const Text('Сохранить в мои блюда'),
                subtitle: Text('Потом записывать одним нажатием', style: TextStyle(color: muted, fontSize: 12)),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: a <= 0
                  ? null
                  : () async {
                      var pick = p;
                      if (remember) {
                        final db = sheet.db;
                        final id = await db.saveFood(
                          FoodsCompanion.insert(
                            name: p.name,
                            icon: Value(p.icon),
                            kcal: m.kcal,
                            protein: Value(m.protein),
                            fat: Value(m.fat),
                            carbs: Value(m.carbs),
                            grams: Value(byWeight ? a : null),
                          ),
                        );
                        final saved = await (db.select(db.foods)..where((t) => t.id.equals(id))).getSingle();
                        pick = FoodPick.food(saved);
                      }
                      if (!sheet.mounted || !context.mounted) return;
                      Navigator.pop(sheet);
                      await _writeMeal(context, pick, m, grams: byWeight ? a : null, day: day, slot: mealSlot);
                    },
              child: const Text('Записать'),
            ),
          ],
        );
      },
    ),
  );
}

// ---------------------------------------------------------------------------
// Рецепт
// ---------------------------------------------------------------------------

/// Рецепт из ингредиентов: калории и БЖУ порции считаются сами.
Future<void> showRecipeSheet(BuildContext context, {Food? existing}) {
  final name = TextEditingController(text: existing?.name ?? '');
  var icon = iconKeyFor(existing?.icon) ?? 'blender';
  var parts = decodeRecipe(existing?.ingredients).toList();
  final total0 = recipeTotal(parts);
  // Порции не хранятся отдельно: их видно из того, во сколько раз весь рецепт больше порции.
  final portions0 = existing == null || existing.kcal <= 0 || total0.kcal <= 0 ? 1.0 : (total0.kcal / existing.kcal * 2).round() / 2;
  final portions = TextEditingController(text: formatNumber(portions0 < 1 ? 1 : portions0));
  final cooked0 = existing?.grams == null ? null : existing!.grams! * portions0;
  final cooked = TextEditingController(
    text: cooked0 == null || (cooked0 - recipeWeight(parts)).abs() < 1 ? '' : formatNumber(cooked0, maxDecimals: 0),
  );
  return showFormSheet(
    context,
    (sheet) => StatefulBuilder(
      builder: (sheet, setState) {
        final theme = Theme.of(sheet);
        final muted = theme.colorScheme.onSurfaceVariant;
        final n = (parseNumber(portions.text) ?? 1).clamp(1, 100).toDouble();
        final total = recipeTotal(parts);
        final portion = recipePortion(parts, n);
        final weight = parseNumber(cooked.text) ?? recipeWeight(parts);

        Future<void> editGrams(int? index, RecipePart part) async {
          final c = TextEditingController(text: formatNumber(part.grams, maxDecimals: 0));
          final g = await showDialog<double>(
            context: sheet,
            builder: (d) => AlertDialog(
              title: Text(part.name),
              content: NumberField(controller: c, label: 'Вес', suffix: 'г', autofocus: true),
              actions: [
                if (index != null)
                  TextButton(
                    onPressed: () => Navigator.pop(d, 0.0),
                    child: Text('Убрать', style: TextStyle(color: Theme.of(d).colorScheme.error)),
                  ),
                TextButton(onPressed: () => Navigator.pop(d), child: const Text('Отмена')),
                FilledButton(onPressed: () => Navigator.pop(d, parseNumber(c.text)), child: const Text('Готово')),
              ],
            ),
          );
          if (g == null) return;
          setState(() {
            if (index == null) {
              if (g > 0) parts.add(part.withGrams(g));
            } else if (g <= 0) {
              parts.removeAt(index);
            } else {
              parts[index] = part.withGrams(g);
            }
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(existing == null ? 'Новый рецепт' : 'Рецепт', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('Добавь ингредиенты с весом в сыром виде. Калории и БЖУ порции посчитаются сами.', style: TextStyle(color: muted)),
            const SizedBox(height: 14),
            Row(
              children: [
                IconField(value: icon, fallback: 'restaurant', onChanged: (v) => setState(() => icon = v)),
                const SizedBox(width: 14),
                Expanded(
                  child: TextField(
                    controller: name,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(labelText: 'Название'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < parts.length; i++)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                dense: true,
                title: Text(parts[i].name),
                subtitle: Text(_bju(parts[i].total), style: TextStyle(color: muted)),
                trailing: Text('${_g(parts[i].grams)} · ${_kcal(parts[i].total.kcal)}'),
                onTap: () => editGrams(i, parts[i]),
              ),
            OutlinedButton.icon(
              onPressed: () async {
                final r = await _showSearch(sheet, title: 'Ингредиент', ingredients: true);
                final p = r?.pick;
                if (p == null || p.per100 == null) return;
                await editGrams(null, RecipePart(name: p.name, grams: p.defaultGrams ?? 100, per100: p.per100!));
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Ингредиент'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: portions,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(labelText: 'Порций'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: cooked,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Вес готового',
                      suffixText: 'г',
                      hintText: parts.isEmpty ? null : formatNumber(recipeWeight(parts), maxDecimals: 0),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                'Крупа и макароны при варке тяжелеют, мясо худеет. Взвесь готовое блюдо, и порцию можно будет записать в граммах.',
                style: TextStyle(color: muted, fontSize: 12, height: 1.3),
              ),
            ),
            if (parts.isNotEmpty) ...[
              const SizedBox(height: 12),
              Card(
                margin: EdgeInsets.zero,
                color: Accent.food.withValues(alpha: 0.08),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Всё блюдо: ${_kcal(total.kcal)}, ${_g(weight)}', style: TextStyle(color: muted)),
                      const SizedBox(height: 4),
                      Text(
                        'Порция: ${_kcal(portion.kcal)} · ${_g(weight / n)}',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text('${_bju(portion)} г'),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () async {
                if (name.text.trim().isEmpty || parts.isEmpty) return showSnack(sheet, 'Нужны название и хотя бы один ингредиент');
                await sheet.db.saveFood(
                  FoodsCompanion(
                    id: existing == null ? const Value.absent() : Value(existing.id),
                    name: Value(name.text.trim()),
                    icon: Value(icon),
                    kcal: Value(portion.kcal.roundToDouble()),
                    protein: Value(portion.protein),
                    fat: Value(portion.fat),
                    carbs: Value(portion.carbs),
                    grams: Value(weight > 0 ? weight / n : null),
                    ingredients: Value(encodeRecipe(parts)),
                  ),
                );
                if (sheet.mounted) Navigator.pop(sheet);
              },
              child: const Text('Сохранить'),
            ),
            if (existing != null)
              TextButton(
                style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                onPressed: () async {
                  await sheet.db.setArchived(sheet.db.foods, existing.id, true);
                  if (sheet.mounted) Navigator.pop(sheet);
                },
                child: const Text('Убрать из быстрых'),
              ),
          ],
        );
      },
    ),
  );
}

// ---------------------------------------------------------------------------
// Мои блюда
// ---------------------------------------------------------------------------

/// Все свои блюда и рецепты, скрытые блюда и справочник.
class FoodLibraryScreen extends StatelessWidget {
  const FoodLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = context.db;
    return Watch(
      streams: () => [db.watchFoods(), db.watchFoods(archived: true)],
      builder: (context, v) {
        final foods = v[0] as List<Food>;
        final hidden = v[1] as List<Food>;
        final recipes = foods.where((f) => f.ingredients != null).toList();
        final dishes = foods.where((f) => f.ingredients == null).toList();
        final muted = Theme.of(context).colorScheme.onSurfaceVariant;
        Widget tile(Food f, {bool archived = false}) => ListTile(
          leading: ItemIcon(f.icon, size: 40, fallback: 'restaurant'),
          title: Text(f.name),
          subtitle: Text(FoodPick.food(f).subtitle, style: TextStyle(color: muted, fontSize: 12)),
          trailing: archived
              ? TextButton(onPressed: () => db.setArchived(db.foods, f.id, false), child: const Text('Вернуть'))
              : const Icon(Icons.chevron_right_rounded),
          onTap: archived ? null : () => showFoodEditSheet(context, existing: f),
        );
        return Scaffold(
          appBar: AppBar(title: const Text('Мои блюда')),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () => showFoodEditSheet(context),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Блюдо'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () => showRecipeSheet(context),
                        icon: const Icon(Icons.menu_book_rounded),
                        label: const Text('Рецепт'),
                      ),
                    ),
                  ],
                ),
              ),
              SectionTitle('Рецепты', trailing: recipes.isEmpty ? null : Pill('${recipes.length}')),
              if (recipes.isEmpty)
                const Card(
                  child: EmptyHint(
                    'Например, гейнер из молока, банана, овсянки и арахисовой пасты. Собери из ингредиентов, и калории посчитаются сами.',
                    icon: Icons.menu_book_rounded,
                  ),
                )
              else
                Card(child: Column(children: [for (final f in recipes) tile(f)])),
              SectionTitle('Блюда', trailing: dishes.isEmpty ? null : Pill('${dishes.length}')),
              if (dishes.isEmpty)
                const Card(child: EmptyHint('Здесь будут блюда для записи в одно нажатие.', icon: Icons.restaurant_rounded))
              else
                Card(child: Column(children: [for (final f in dishes) tile(f)])),
              if (hidden.isNotEmpty) ...[
                SectionTitle('Скрытые', trailing: Pill('${hidden.length}')),
                Card(child: Column(children: [for (final f in hidden) tile(f, archived: true)])),
              ],
              const SectionTitle('Справочник'),
              Card(
                child: Column(
                  children: [
                    for (final g in catalogGroups)
                      ExpansionTile(
                        title: Text(g),
                        subtitle: Text(
                          '${foodCatalog.where((c) => c.group == g).length} продуктов',
                          style: TextStyle(color: muted, fontSize: 12),
                        ),
                        children: [
                          for (final c in foodCatalog.where((c) => c.group == g))
                            ListTile(
                              dense: true,
                              title: Text(c.name),
                              subtitle: Text(FoodPick.catalog(c).subtitle, style: TextStyle(color: muted)),
                              trailing: const Icon(Icons.add_circle_outline_rounded, color: Accent.food),
                              onTap: () => showAmountSheet(context, FoodPick.catalog(c), day: todayKey()),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Text(
                  'Цифры справочника из таблиц состава продуктов (Скурихин, USDA), у конкретной марки могут отличаться на 10–20%. '
                  'Если есть упаковка, точнее записать по ней.',
                  style: TextStyle(color: muted, fontSize: 12, height: 1.35),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
