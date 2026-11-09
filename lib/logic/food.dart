/// Питание: цели на день, итоги дня и подсказка по весу.
library;

import '../data/database.dart';
import '../data/dates.dart';
import 'calc.dart';
import 'minimum.dart';

enum FoodMode {
  gain('Набор массы'),
  keep('Поддержание'),
  lose('Снижение веса');

  const FoodMode(this.label);
  final String label;
}

/// Цели по питанию из настроек.
class FoodGoals {
  const FoodGoals({
    required this.kcal,
    required this.protein,
    required this.water,
    required this.glass,
    required this.mode,
    this.kcalMin,
    this.proteinMin,
    this.weightTrackerId,
    this.onToday = false,
  });

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

  final double kcal;
  final double protein;

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

/// Итог дня: калории, белок, вода.
typedef DayFood = ({double kcal, double protein, int water});

DayFood dayFood(int day, Iterable<Meal> meals, Iterable<WaterLog> water) {
  var kcal = 0.0, protein = 0.0, ml = 0;
  for (final m in meals) {
    if (m.day != day) continue;
    kcal += m.kcal;
    protein += m.protein;
  }
  for (final w in water) {
    if (w.day == day) ml += w.ml;
  }
  return (kcal: kcal, protein: protein, water: ml);
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

/// Подсказка по весу за последние недели. null, если записей веса мало.
({String text, bool adjust})? weightAdvice(List<(int day, double value)> series, FoodMode mode, {required int today}) {
  final recent = series.where((p) => p.$1 >= addDays(today, -21)).toList();
  if (recent.length < 2) return null;
  final days = daysBetween(recent.first.$1, recent.last.$1);
  if (days < 10) return null;
  final per2w = (recent.last.$2 - recent.first.$2) / days * 14;
  final pace = '${per2w >= 0 ? '+' : '−'}${formatNumber(per2w.abs())} кг за 2 недели';
  switch (mode) {
    case FoodMode.gain:
      if (per2w < 0.2) {
        return (text: 'Вес почти не растёт ($pace). Добавь 200–300 ккал в день, например стакан молока и банан.', adjust: true);
      }
      if (per2w > 0.7) return (text: 'Вес растёт быстро ($pace), часть уходит в жир. Можно убрать около 200 ккал в день.', adjust: true);
      return (text: 'Хороший темп: $pace. Так держать.', adjust: false);
    case FoodMode.lose:
      if (per2w > -0.2) return (text: 'Вес почти не снижается ($pace). Убери 200–300 ккал в день.', adjust: true);
      if (per2w < -1.0) return (text: 'Вес уходит слишком быстро ($pace). Добавь около 200 ккал в день.', adjust: true);
      return (text: 'Хороший темп: $pace.', adjust: false);
    case FoodMode.keep:
      if (per2w.abs() > 0.5) {
        return (text: 'Вес меняется ($pace). ${per2w > 0 ? 'Убери' : 'Добавь'} около 200 ккал в день.', adjust: true);
      }
      return (text: 'Вес держится ровно: $pace.', adjust: false);
  }
}
