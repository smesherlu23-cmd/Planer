/// Питание: цели на день, итоги дня и подсказка по весу.
library;

import 'dart:convert';
import 'dart:math';

import '../data/database.dart';
import '../data/dates.dart';
import 'calc.dart';
import 'minimum.dart';

enum FoodMode {
  gain('Набор массы', 'Набор'),
  keep('Поддержание', 'Держать'),
  lose('Снижение веса', 'Снижение');

  const FoodMode(this.label, this.short);
  final String label;

  /// Для переключателя, где мало места.
  final String short;
}

/// Цели по питанию из настроек.
class FoodGoals {
  FoodGoals({
    required this.kcal,
    required this.protein,
    required this.water,
    required this.glass,
    required this.mode,
    this.kcalMin,
    this.proteinMin,
    this.weightTrackerId,
    this.onToday = false,
    double? fat,
    double? carbs,
  }) : fat = fat ?? _defaultFat(kcal),
       carbs = carbs ?? _carbsLeft(kcal, protein, fat ?? _defaultFat(kcal));

  /// Жиры по умолчанию: 25% калорий, середина нормы 20–35%.
  static double _defaultFat(double kcal) => (kcal * fatShare / 9).roundToDouble();

  /// Углеводы: всё, что осталось от калорий после белка и жиров.
  static double _carbsLeft(double kcal, double protein, double fat) =>
      ((kcal - protein * 4 - fat * 9) / 4).clamp(0, double.infinity).roundToDouble();

  factory FoodGoals.from(Map<String, String> s) => FoodGoals(
    kcal: double.tryParse(s[keyKcal] ?? '') ?? 2500,
    protein: double.tryParse(s[keyProtein] ?? '') ?? 100,
    water: int.tryParse(s[keyWater] ?? '') ?? 2000,
    glass: int.tryParse(s[keyGlass] ?? '') ?? 250,
    mode: FoodMode.values.where((m) => m.name == s[keyMode]).firstOrNull ?? FoodMode.keep,
    kcalMin: double.tryParse(s[keyKcalMin] ?? ''),
    proteinMin: double.tryParse(s[keyProteinMin] ?? ''),
    weightTrackerId: int.tryParse(s[keyWeight] ?? ''),
    onToday: s[keyOn] == '1',
    fat: double.tryParse(s[keyFat] ?? ''),
    carbs: double.tryParse(s[keyCarbs] ?? ''),
  );

  static const keyKcal = 'food_kcal';
  static const keyProtein = 'food_protein';
  static const keyKcalMin = 'food_kcal_min';
  static const keyProteinMin = 'food_protein_min';
  static const keyWater = 'food_water';
  static const keyGlass = 'food_glass';
  static const keyMode = 'food_mode';
  static const keyWeight = 'food_weight';
  static const keyOn = 'food_on';
  static const keyFat = 'food_fat';
  static const keyCarbs = 'food_carbs';

  /// Доля калорий из жиров по умолчанию.
  static const fatShare = 0.25;

  final double kcal;
  final double protein;

  /// Жиры и углеводы в граммах. Если не заданы вручную, считаются из калорий и белка.
  final double fat;
  final double carbs;

  /// Минимум на тяжёлый день. Калорийный минимум бывает только при наборе и поддержании.
  final double? kcalMin;
  final double? proteinMin;

  /// Вода за день и размер стакана, мл.
  final int water;
  final int glass;
  final FoodMode mode;

  /// Трекер веса для подсказки, сколько есть.
  final int? weightTrackerId;

  /// Показывать питание на экране «Сегодня».
  final bool onToday;
}

/// Итог дня: калории, белки, жиры, углеводы, вода.
typedef DayFood = ({double kcal, double protein, double fat, double carbs, int water});

DayFood dayFood(int day, Iterable<Meal> meals, Iterable<WaterLog> water) {
  var kcal = 0.0, protein = 0.0, fat = 0.0, carbs = 0.0, ml = 0;
  for (final m in meals) {
    if (m.day != day) continue;
    kcal += m.kcal;
    protein += m.protein;
    fat += m.fat;
    carbs += m.carbs;
  }
  for (final w in water) {
    if (w.day == day) ml += w.ml;
  }
  return (kcal: kcal, protein: protein, fat: fat, carbs: carbs, water: ml);
}

/// Калории по БЖУ: 4 ккал в грамме белка и углеводов, 9 в грамме жира (коэффициенты Этуотера).
double kcalFromMacros({double protein = 0, double fat = 0, double carbs = 0}) => protein * 4 + fat * 9 + carbs * 4;

// ---------------------------------------------------------------------------
// Приёмы пищи
// ---------------------------------------------------------------------------

enum MealSlot {
  breakfast('Завтрак'),
  lunch('Обед'),
  dinner('Ужин'),
  snack('Перекус');

  const MealSlot(this.label);
  final String label;

  /// Приём пищи по времени, если не выбран явно.
  static MealSlot forTime(DateTime t) {
    final h = t.hour;
    if (h >= 4 && h < 11) return breakfast;
    if (h >= 11 && h < 16) return lunch;
    if (h >= 17 && h < 22) return dinner;
    return snack;
  }

  static MealSlot of(Meal m) => m.slot != null && m.slot! >= 0 && m.slot! < values.length ? values[m.slot!] : forTime(m.at);
}

/// Белка за один приём, чтобы мышцы использовали его по максимуму: около 0,4 г на кг веса
/// (Schoenfeld, Aragon 2018). Ориентир, а не жёсткий предел.
double proteinPerMeal(double weightKg) => weightKg * 0.4;

// ---------------------------------------------------------------------------
// Расчёт нормы
// ---------------------------------------------------------------------------

enum Sex {
  male('Мужской'),
  female('Женский');

  const Sex(this.label);
  final String label;
}

/// Уровень активности: множитель к обмену в покое (PAL).
enum Activity {
  sedentary(1.2, 'Сидячий', 'работа сидя, спорта почти нет'),
  light(1.375, 'Лёгкий', 'сидячая работа и 1–3 тренировки в неделю'),
  moderate(1.55, 'Средний', 'работа на ногах или 3–5 тренировок в неделю'),
  high(1.725, 'Высокий', 'физическая работа и тренировки'),
  extreme(1.9, 'Очень высокий', 'тяжёлый труд и спорт почти каждый день');

  const Activity(this.factor, this.label, this.hint);
  final double factor;
  final String label;
  final String hint;
}

/// Данные тела для расчёта нормы.
class Body {
  const Body({required this.sex, required this.age, required this.heightCm, required this.activity});

  /// null, если в настройках чего-то не хватает.
  static Body? from(Map<String, String> s) {
    final birth = int.tryParse(s[keyBirthYear] ?? '');
    final height = double.tryParse(s[keyHeight] ?? '');
    if (birth == null || height == null) return null;
    return Body(
      sex: Sex.values.where((v) => v.name == s[keySex]).firstOrNull ?? Sex.male,
      age: DateTime.now().year - birth,
      heightCm: height,
      activity: Activity.values.where((v) => v.name == s[keyActivity]).firstOrNull ?? Activity.moderate,
    );
  }

  static const keySex = 'body_sex';
  static const keyBirthYear = 'body_birth_year';
  static const keyHeight = 'body_height';
  static const keyActivity = 'body_activity';

  final Sex sex;
  final int age;
  final double heightCm;
  final Activity activity;
}

/// Обмен в покое по формуле Миффлина — Сан Жеора: точнее других формул для здоровых взрослых
/// (Frankenfield и др., 2005).
double restingKcal(Body b, double weightKg) => 10 * weightKg + 6.25 * b.heightCm - 5 * b.age + (b.sex == Sex.male ? 5 : -161);

/// Норма на день с разбивкой, откуда взялась каждая цифра.
class FoodPlan {
  const FoodPlan({
    required this.resting,
    required this.maintenance,
    required this.kcal,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.water,
    required this.perMeal,
  });

  final double resting;
  final double maintenance;
  final double kcal;
  final double protein;
  final double fat;
  final double carbs;
  final int water;
  final double perMeal;
}

double _round(double v, int step) => (v / step).round() * step.toDouble();

/// Сколько есть, чтобы набирать, держать или снижать вес.
///
/// - Калории: обмен в покое × активность. Набор +10% (рост 0,25–0,5% веса в неделю, Iraki и др., 2019),
///   снижение −20% (0,5–1% веса в неделю).
/// - Белок: 1,6 г/кг дают почти весь эффект для мышц, до 2,2 г/кг с запасом (Morton и др., 2018).
///   На наборе 1,8 г/кг, на снижении 2,2 г/кг, чтобы сохранить мышцы.
/// - Жиры: 25% калорий (норма 20–35%), но не меньше 0,8 г/кг.
/// - Углеводы: остаток калорий, они дают энергию на тренировки.
/// - Вода: 30 мл/кг из напитков, не меньше 2 л для мужчин (EFSA: 2,5 л в день вместе с едой).
FoodPlan planFor(Body b, double weightKg, FoodMode mode) {
  final resting = restingKcal(b, weightKg);
  final maintenance = resting * b.activity.factor;
  final kcal = _round(
    maintenance *
        switch (mode) {
          FoodMode.gain => 1.10,
          FoodMode.keep => 1.0,
          FoodMode.lose => 0.80,
        },
    50,
  );
  final protein = _round(
    weightKg *
        switch (mode) {
          FoodMode.gain => 1.8,
          FoodMode.keep => 1.6,
          FoodMode.lose => 2.2,
        },
    5,
  );
  final fat = _round(max(kcal * FoodGoals.fatShare / 9, weightKg * 0.8), 5);
  final carbs = _round(max(0, (kcal - protein * 4 - fat * 9) / 4), 5);
  final water = _round(max(weightKg * 30, b.sex == Sex.male ? 2000 : 1600), 250).round();
  return FoodPlan(
    resting: resting,
    maintenance: maintenance,
    kcal: kcal,
    protein: protein,
    fat: fat,
    carbs: carbs,
    water: water,
    perMeal: proteinPerMeal(weightKg),
  );
}

/// День засчитан, если набрал хотя бы 90% калорий (для набора и поддержания)
/// или не превысил цель больше чем на 10% (для снижения).
bool kcalOnTarget(double kcal, FoodGoals g) => g.mode == FoodMode.lose ? kcal > 0 && kcal <= g.kcal * 1.1 : kcal >= g.kcal * 0.9;

/// Уровень дня по калориям и белку. null, если за день ничего не записано.
Level? foodLevel(DayFood d, FoodGoals g) {
  if (d.kcal <= 0) return null;
  final kcalFull = kcalOnTarget(d.kcal, g);
  final proteinFull = g.protein <= 0 || d.protein >= g.protein * 0.9;
  if (kcalFull && proteinFull) return Level.full;
  final kcalOk = kcalFull || (g.mode != FoodMode.lose && g.kcalMin != null && d.kcal >= g.kcalMin!);
  final proteinOk = proteinFull || (g.proteinMin != null && d.protein >= g.proteinMin!);
  return kcalOk && proteinOk ? Level.minimum : Level.below;
}

/// Темп веса за последние 3 недели по наклону прямой через все взвешивания.
/// Так одно взвешивание после солёного ужина не сбивает вывод.
({double perWeek, double percent, double avg})? weightTrend(List<(int day, double value)> series, {required int today, int days = 21}) {
  final recent = series.where((p) => p.$1 >= addDays(today, -days) && p.$1 <= today).toList();
  if (recent.length < 3) return null;
  final span = daysBetween(recent.first.$1, recent.last.$1);
  if (span < 10) return null;
  final xs = [for (final p in recent) daysBetween(recent.first.$1, p.$1).toDouble()];
  final ys = [for (final p in recent) p.$2];
  final mx = xs.reduce((a, b) => a + b) / xs.length;
  final my = ys.reduce((a, b) => a + b) / ys.length;
  var num = 0.0, den = 0.0;
  for (var i = 0; i < xs.length; i++) {
    num += (xs[i] - mx) * (ys[i] - my);
    den += (xs[i] - mx) * (xs[i] - mx);
  }
  if (den == 0) return null;
  final perWeek = num / den * 7;
  return (perWeek: perWeek, percent: perWeek / my * 100, avg: my);
}

/// Нужный темп в процентах веса за неделю.
(double, double) targetPace(FoodMode mode) => switch (mode) {
  FoodMode.gain => (0.25, 0.5),
  FoodMode.keep => (-0.25, 0.25),
  FoodMode.lose => (-1.0, -0.5),
};

/// Подсказка по весу: темп за неделю, нужный темп и на сколько поменять калории.
/// [kcalDelta] = 0, если темп хороший. Килограмм веса считаем за 7700 ккал.
({String text, bool adjust, int kcalDelta})? weightAdvice(List<(int day, double value)> series, FoodMode mode, {required int today}) {
  final trend = weightTrend(series, today: today);
  if (trend == null) return null;
  final (lo, hi) = targetPace(mode);
  String kg(double v) => '${v >= 0 ? '+' : '−'}${formatNumber(v.abs(), maxDecimals: 2)} кг';
  final pace = '${kg(trend.perWeek)} в неделю';
  final target =
      '${formatNumber(trend.avg * lo.abs() / 100, maxDecimals: 2)}–${formatNumber(trend.avg * hi.abs() / 100, maxDecimals: 2)} кг';
  if (trend.percent >= lo && trend.percent <= hi) {
    final good = switch (mode) {
      FoodMode.gain => 'Хороший темп набора: $pace. Так мышцы растут, а жира прибавляется мало.',
      FoodMode.keep => 'Вес держится ровно: $pace.',
      FoodMode.lose => 'Хороший темп снижения: $pace. Мышцы при таком темпе сохраняются.',
    };
    return (text: good, adjust: false, kcalDelta: 0);
  }
  final midKg = trend.avg * (lo + hi) / 2 / 100;
  final raw = (midKg - trend.perWeek) * 7700 / 7;
  final delta = (raw.clamp(-500, 500) / 50).round() * 50;
  if (delta == 0) return (text: 'Вес меняется: $pace. Почти в норме.', adjust: false, kcalDelta: 0);
  final need = switch (mode) {
    FoodMode.gain => 'Для набора нужно $target в неделю.',
    FoodMode.keep => 'Чтобы держать вес, нужно не больше ±${formatNumber(trend.avg * 0.25 / 100, maxDecimals: 2)} кг в неделю.',
    FoodMode.lose => 'Для снижения без потери мышц нужно $target в неделю.',
  };
  return (text: 'Вес: $pace. $need ${delta > 0 ? 'Добавь' : 'Убери'} около ${delta.abs()} ккал в день.', adjust: true, kcalDelta: delta);
}

// ---------------------------------------------------------------------------
// Порции, граммы и рецепты
// ---------------------------------------------------------------------------

/// Калории и БЖУ одной порции или суммы.
typedef Macros = ({double kcal, double protein, double fat, double carbs});

const zeroMacros = (kcal: 0.0, protein: 0.0, fat: 0.0, carbs: 0.0);

Macros scaleMacros(Macros m, double k) => (kcal: m.kcal * k, protein: m.protein * k, fat: m.fat * k, carbs: m.carbs * k);

Macros addMacros(Macros a, Macros b) =>
    (kcal: a.kcal + b.kcal, protein: a.protein + b.protein, fat: a.fat + b.fat, carbs: a.carbs + b.carbs);

Macros foodMacros(Food f) => (kcal: f.kcal, protein: f.protein, fat: f.fat, carbs: f.carbs);

Macros mealMacros(Meal m) => (kcal: m.kcal, protein: m.protein, fat: m.fat, carbs: m.carbs);

/// Ингредиент рецепта: вес и состав на 100 г.
class RecipePart {
  const RecipePart({required this.name, required this.grams, required this.per100});

  factory RecipePart.fromJson(Map<String, Object?> j) {
    double n(String k) => (j[k] as num?)?.toDouble() ?? 0;
    return RecipePart(name: j['n'] as String? ?? '', grams: n('g'), per100: (kcal: n('k'), protein: n('p'), fat: n('f'), carbs: n('c')));
  }

  final String name;
  final double grams;
  final Macros per100;

  Macros get total => scaleMacros(per100, grams / 100);

  RecipePart withGrams(double g) => RecipePart(name: name, grams: g, per100: per100);

  Map<String, Object?> toJson() => {'n': name, 'g': grams, 'k': per100.kcal, 'p': per100.protein, 'f': per100.fat, 'c': per100.carbs};
}

/// Рецепт хранится у блюда текстом. Пустой список, если это не рецепт или текст испорчен.
List<RecipePart> decodeRecipe(String? json) {
  if (json == null || json.isEmpty) return const [];
  try {
    final list = jsonDecode(json) as List;
    return [for (final e in list) RecipePart.fromJson((e as Map).cast<String, Object?>())];
  } catch (_) {
    return const [];
  }
}

String encodeRecipe(List<RecipePart> parts) => jsonEncode([for (final p in parts) p.toJson()]);

Macros recipeTotal(List<RecipePart> parts) => parts.fold(zeroMacros, (a, p) => addMacros(a, p.total));

double recipeWeight(List<RecipePart> parts) => parts.fold(0.0, (a, p) => a + p.grams);

/// Одна порция рецепта. [portions] не меньше 1.
Macros recipePortion(List<RecipePart> parts, double portions) => scaleMacros(recipeTotal(parts), 1 / max(1, portions));

// ---------------------------------------------------------------------------
// Расход по факту
// ---------------------------------------------------------------------------

/// Сколько на самом деле тратишь за день, по съеденному и изменению веса.
///
/// Так считают MacroFactor и подобные программы: если ел в среднем 2800 ккал и прибавил 0,3 кг
/// за неделю (≈ 330 ккал в день в запас), значит тратишь около 2470. Формулы ошибаются на 10% и больше,
/// а этот расчёт подстраивается под конкретного человека.
///
/// Нужно хотя бы 14 дней записей еды за последние 4 недели и взвешивания минимум за 10 дней.
/// Дни без записей не учитываются: считается, что в них ел как обычно. Дни меньше [minDay] ккал
/// тоже: скорее всего, записал не всё, и такой день занизил бы расход.
({double kcal, int days, double perWeek})? measuredExpenditure({
  required Map<int, double> intake,
  required List<(int day, double value)> weights,
  required int today,
  int window = 28,
  double minDay = 0,
}) {
  // Сегодняшний день ещё не закончился: его не берём.
  final from = addDays(today, -window), to = addDays(today, -1);
  final logged = [
    for (final e in intake.entries)
      if (e.key >= from && e.key <= to && e.value > 0 && e.value >= minDay) e.value,
  ];
  if (logged.length < 14) return null;
  final trend = weightTrend(weights, today: today, days: window);
  if (trend == null) return null;
  final avgIntake = logged.reduce((a, b) => a + b) / logged.length;
  final kcal = avgIntake - trend.perWeek * 7700 / 7;
  if (kcal < 1200 || kcal > 6000) return null;
  return (kcal: kcal, days: logged.length, perWeek: trend.perWeek);
}

/// Цель калорий от расхода: набор +10%, снижение −20%, как в [planFor].
double kcalForMode(double expenditure, FoodMode mode) => _round(
  expenditure *
      switch (mode) {
        FoodMode.gain => 1.10,
        FoodMode.keep => 1.0,
        FoodMode.lose => 0.80,
      },
  50,
);

// ---------------------------------------------------------------------------
// Чем добрать норму
// ---------------------------------------------------------------------------

/// До трёх блюд, которые лучше всего закрывают остаток калорий и белка, без большого перебора.
/// Если белка не хватает сильнее, чем калорий, выше идут белковые блюда.
List<T> fillSuggestions<T>(List<(T, Macros)> options, {required double kcalLeft, required double proteinLeft, int limit = 3}) {
  var k = kcalLeft, p = max(0.0, proteinLeft);
  final picked = <T>[];
  final pool = [...options];
  while (picked.length < limit && k >= 150 && pool.isNotEmpty) {
    (T, Macros)? best;
    var bestScore = 0.0;
    for (final o in pool) {
      final m = o.$2;
      if (m.kcal <= 0 || m.kcal > k * 1.15 + 50) continue;
      final kcalPart = min(m.kcal, k) / k;
      final proteinPart = p < 5 ? 0.0 : min(m.protein, p) / p;
      final proteinWeight = p / max(k, 1) * 100 > 4 ? 1.5 : 0.7;
      final score = kcalPart + proteinPart * proteinWeight;
      if (score > bestScore) {
        bestScore = score;
        best = o;
      }
    }
    if (best == null) break;
    picked.add(best.$1);
    pool.remove(best);
    k -= best.$2.kcal;
    p = max(0, p - best.$2.protein);
  }
  return picked;
}

// ---------------------------------------------------------------------------
// Статистика за период
// ---------------------------------------------------------------------------

/// Дней подряд, когда набрана хотя бы минимальная планка. Сегодня считается, только если уже набрано:
/// незаконченный день серию не рвёт.
int foodStreak(Map<int, DayFood> days, FoodGoals g, {required int today}) {
  bool ok(int d) {
    final f = days[d];
    if (f == null) return false;
    final l = foodLevel(f, g);
    return l == Level.full || l == Level.minimum;
  }

  var d = ok(today) ? today : addDays(today, -1);
  var n = 0;
  while (ok(d)) {
    n++;
    d = addDays(d, -1);
  }
  return n;
}

/// Доли калорий из белков, жиров и углеводов, в процентах.
({int protein, int fat, int carbs})? macroSplit(double protein, double fat, double carbs) {
  final p = protein * 4, f = fat * 9, c = carbs * 4;
  final total = p + f + c;
  if (total <= 0) return null;
  final pp = (p / total * 100).round(), fp = (f / total * 100).round();
  return (protein: pp, fat: fp, carbs: 100 - pp - fp);
}
