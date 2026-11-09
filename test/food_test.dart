import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planer/data/database.dart';
import 'package:planer/data/dates.dart';
import 'package:planer/data/food_catalog.dart';
import 'package:planer/data/queries.dart';
import 'package:planer/logic/food.dart';
import 'package:planer/logic/minimum.dart';

import 'health_test.dart' show downgradeToV4;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('справочник: калории сходятся с БЖУ, названия не повторяются', () {
    final names = <String>{};
    for (final c in foodCatalog) {
      expect(names.add(c.name), isTrue, reason: 'повтор: ${c.name}');
      expect(catalogGroups, contains(c.group), reason: c.name);
      expect(c.portion, greaterThan(0), reason: c.name);
      final byMacros = kcalFromMacros(protein: c.protein, fat: c.fat, carbs: c.carbs);
      // Клетчатка и округления дают расхождение, но не больше 15% или 25 ккал.
      expect((byMacros - c.kcal).abs(), lessThanOrEqualTo(c.kcal * 0.15 + 25), reason: '${c.name}: $byMacros vs ${c.kcal}');
    }
    expect(foodCatalog.length, greaterThan(90));
  });

  test('рецепт: сумма ингредиентов и порция', () {
    final parts = [
      const RecipePart(name: 'Молоко', grams: 500, per100: (kcal: 52, protein: 2.8, fat: 2.5, carbs: 4.7)),
      const RecipePart(name: 'Банан', grams: 120, per100: (kcal: 96, protein: 1.5, fat: 0.2, carbs: 21.8)),
      const RecipePart(name: 'Овсянка', grams: 50, per100: (kcal: 366, protein: 12.3, fat: 6.2, carbs: 61.8)),
    ];
    final total = recipeTotal(parts);
    expect(total.kcal, closeTo(260 + 115.2 + 183, 0.01));
    expect(recipeWeight(parts), 670);
    final half = recipePortion(parts, 2);
    expect(half.protein, closeTo(total.protein / 2, 0.001));
    final back = decodeRecipe(encodeRecipe(parts));
    expect(back.length, 3);
    expect(back[1].name, 'Банан');
    expect(back[1].total.carbs, closeTo(26.16, 0.001));
    expect(decodeRecipe('не json'), isEmpty);
    expect(decodeRecipe(null), isEmpty);
  });

  test('расход по факту: еда минус изменение веса', () {
    const today = 20261130;
    // 28 дней по 3000 ккал, вес растёт на 0,35 кг в неделю.
    final intake = {for (var i = 1; i <= 28; i++) addDays(today, -i): 3000.0};
    final weights = [for (var i = 0; i <= 28; i += 2) (addDays(today, -28 + i), 68 + i * 0.05)];
    final e = measuredExpenditure(intake: intake, weights: weights, today: today)!;
    expect(e.perWeek, closeTo(0.35, 0.001));
    // 0,35 кг в неделю = 385 ккал в день в запас.
    expect(e.kcal, closeTo(3000 - 385, 1));
    expect(e.days, 28);
    expect(kcalForMode(e.kcal, FoodMode.gain), 2900);
    expect(kcalForMode(e.kcal, FoodMode.keep), 2600);

    // Мало дней с записями еды: не считаем.
    final sparse = {for (var i = 1; i <= 10; i++) addDays(today, -i): 3000.0};
    expect(measuredExpenditure(intake: sparse, weights: weights, today: today), isNull);
    // Недописанные дни (меньше половины цели) не берём.
    final partial = {...intake, for (var i = 1; i <= 5; i++) addDays(today, -i): 900.0};
    expect(measuredExpenditure(intake: partial, weights: weights, today: today, minDay: 1500)!.days, 23);
    // Без веса тоже.
    expect(measuredExpenditure(intake: intake, weights: const [], today: today), isNull);
  });

  test('чем добрать: белковое при нехватке белка, без перебора калорий', () {
    const shake = (kcal: 700.0, protein: 28.0, fat: 25.0, carbs: 90.0);
    const curd = (kcal: 250.0, protein: 30.0, fat: 10.0, carbs: 8.0);
    const banana = (kcal: 100.0, protein: 1.0, fat: 0.0, carbs: 23.0);
    const options = [('shake', shake), ('curd', curd), ('banana', banana)];
    // Осталось 300 ккал и 30 г белка: творог, а не коктейль на 700.
    expect(fillSuggestions(options, kcalLeft: 300, proteinLeft: 30), ['curd']);
    // Осталось 1000 ккал: коктейль и творог.
    expect(fillSuggestions(options, kcalLeft: 1000, proteinLeft: 60), containsAll(['shake', 'curd']));
    // Норма набрана: ничего.
    expect(fillSuggestions(options, kcalLeft: 100, proteinLeft: 0), isEmpty);
  });

  test('серия дней и доли БЖУ', () {
    final g = FoodGoals.from({'food_kcal': '3000', 'food_protein': '130', 'food_kcal_min': '2500', 'food_protein_min': '100'});
    const today = 20261110;
    DayFood d(double kcal, double protein) => (kcal: kcal, protein: protein, fat: 80, carbs: 400, water: 0);
    final days = {20261106: d(1500, 50), 20261107: d(3000, 130), 20261108: d(2600, 110), 20261109: d(3100, 140), today: d(800, 30)};
    expect(foodLevel(days[20261108]!, g), Level.minimum);
    // Сегодня ещё не набрано, но серия не рвётся: считаем со вчера.
    expect(foodStreak(days, g, today: today), 3);
    expect(foodStreak({...days, today: d(3000, 130)}, g, today: today), 4);
    final split = macroSplit(150, 80, 400)!;
    expect(split.protein + split.fat + split.carbs, 100);
    expect(split.carbs, greaterThan(split.protein));
    expect(macroSplit(0, 0, 0), isNull);
  });

  test('порция, граммы и повтор вчерашнего дня', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final id = await db.saveFood(
      FoodsCompanion.insert(name: 'Гречка с курицей', kcal: 600, protein: const Value(45), grams: const Value(350)),
    );
    final food = (await db.select(db.foods).get()).firstWhere((f) => f.id == id);
    await db.eatFood(food, day: 20261109, slot: MealSlot.lunch.index, portions: 1.5);
    await db.eatFood(food, day: 20261109, slot: MealSlot.dinner.index);
    final eaten = await db.mealsBetween(20261109, 20261109);
    expect(eaten.first.kcal, 900);
    expect(eaten.first.grams, 525);

    expect(await db.copyMeals(from: 20261109, to: 20261110, where: (m) => MealSlot.of(m) == MealSlot.dinner), 1);
    expect(await db.copyMeals(from: 20261109, to: 20261111), 2);
    final copied = await db.mealsBetween(20261111, 20261111);
    expect(copied.map((m) => m.kcal).toList()..sort(), [600, 900]);
    expect(copied.every((m) => m.foodId == id), isTrue);
    // Исходный день не тронут.
    expect((await db.mealsBetween(20261109, 20261109)).length, 2);
  });

  test('переход с версии 4: вес порции и рецепты', () async {
    final dir = await Directory.systemTemp.createTemp('planer_migration5');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/db.sqlite');
    final current = AppDatabase(NativeDatabase(file));
    await current.saveFood(FoodsCompanion.insert(name: 'Творог', kcal: 250, protein: const Value(30)));
    await downgradeToV4(current);
    await current.close();

    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);
    final f = (await db.select(db.foods).get()).single;
    expect(f.grams, isNull);
    expect(f.ingredients, isNull);
    await db.saveFood(FoodsCompanion(id: Value(f.id), grams: const Value(200)));
    expect((await db.select(db.foods).get()).single.grams, 200);
  });
}
