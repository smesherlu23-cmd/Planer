/// Иконки хранятся в базе как короткие ключи: 'bedtime', 'code', 'savings'.
/// Раньше вместо них были эмодзи, поэтому здесь же перевод старых значений.
library;

/// Эмодзи из старых версий и похожие на них, переведённые в ключи иконок.
const emojiToIconKey = {
  '✅': 'check',
  '📈': 'chart',
  '💸': 'payments',
  '💵': 'payments',
  '💰': 'salary',
  '🐷': 'savings',
  '🏦': 'bank',
  '🍌': 'fruit',
  '🍎': 'fruit',
  '👕': 'clothes',
  '🧴': 'soap',
  '🚌': 'bus',
  '📱': 'phone',
  '🎮': 'game',
  '📚': 'book',
  '📖': 'book',
  '🎁': 'gift',
  '⚖': 'scale',
  '⏱': 'timer',
  '💪': 'fitness',
  '🏋': 'fitness',
  '🙌': 'gymnastics',
  '🎯': 'target',
  '😴': 'bedtime',
  '🛌': 'bedtime',
  '💻': 'code',
  '🧘': 'yoga',
  '🪪': 'license',
  '🚗': 'car',
  '🏃': 'run',
  '💧': 'water',
  '☕': 'coffee',
  '🍔': 'fastfood',
  '🍕': 'pizza',
  '🎵': 'music',
  '🎬': 'movie',
  '🏠': 'house',
  '📝': 'note',
  '🛒': 'cart',
  '❤': 'heart',
  '⭐': 'star',
  '🔥': 'fire',
  '🧠': 'brain',
  '🎓': 'school',
  '✈': 'flight',
  '⛽': 'fuel',
  '🥚': 'egg',
  '🥛': 'milk',
};

/// Ключ иконки для значения из базы: старое эмодзи переводится, ключ остаётся как есть.
/// null, если значение не похоже ни на то, ни на другое.
String? iconKeyFor(String? value) {
  if (value == null) return null;
  final v = value.replaceAll('️', '').trim();
  if (v.isEmpty) return null;
  if (RegExp(r'^[a-z_0-9]+$').hasMatch(v)) return v;
  return emojiToIconKey[v];
}
