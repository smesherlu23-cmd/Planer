/// Справочник упражнений для дома: мышцы, отдых и лестницы усложнения.
///
/// Упражнения в программах хранятся по названию. Если название совпадает
/// со справочником, приложение само знает мышцы, отдых и следующий шаг.
library;

/// Мышечные группы. Ключи хранятся в базе, подписи только для экрана.
enum Muscle {
  chest('Грудь'),
  back('Спина'),
  shoulders('Плечи'),
  arms('Руки'),
  legs('Ноги'),
  glutes('Ягодицы'),
  core('Пресс и кор'),
  mobility('Осанка и растяжка');

  const Muscle(this.label);
  final String label;

  /// Для осанки и растяжки недельный объём не считаем: это не на рост мышц.
  bool get countsVolume => this != mobility;

  static Muscle? byKey(String? key) {
    for (final m in values) {
      if (m.name == key) return m;
    }
    return null;
  }
}

class CatalogExercise {
  const CatalogExercise(
    this.name, {
    required this.muscle,
    this.secondary = const [],
    this.sets = 3,
    this.repsMin = 8,
    this.repsMax = 12,
    this.unit = 'повт',
    this.restSec = 90,
    this.hint,
    this.chain,
    this.spineLoad = false,
  });

  final String name;
  final Muscle muscle;

  /// Мышцы, которые работают вторым номером: в недельном объёме идут за половину подхода.
  final List<Muscle> secondary;
  final int sets;
  final int repsMin;
  final int repsMax;
  final String unit;
  final int restSec;

  /// Техника коротко.
  final String? hint;

  /// Лестница усложнения, в которой стоит упражнение.
  final String? chain;

  /// Осевая нагрузка на позвоночник: с весом на плечах или в руках стоя.
  final bool spineLoad;
}

/// Лестницы: от лёгкого к тяжёлому. Когда во всех подходах верхняя граница, берём следующую ступень.
const exerciseChains = <String, List<String>>{
  'push': [
    'Отжимания от стены',
    'Отжимания от стола',
    'Отжимания с колен',
    'Отжимания от пола',
    'Отжимания ноги на стуле',
    'Отжимания с рюкзаком',
    'Отжимания лучником',
  ],
  'pull': [
    'Вис на турнике',
    'Негативные подтягивания',
    'Подтягивания с резинкой',
    'Подтягивания',
    'Подтягивания с паузой наверху',
    'Подтягивания с рюкзаком',
    'Подтягивания лучником',
  ],
  'row': ['Австралийские подтягивания', 'Австралийские подтягивания ноги на стуле', 'Австралийские подтягивания с паузой'],
  'triceps': ['Узкие отжимания', 'Узкие отжимания ноги на стуле', 'Алмазные отжимания'],
  'dips': ['Обратные отжимания от стула', 'Обратные отжимания ноги на стуле', 'Отжимания на брусьях'],
  'pike': ['Отжимания домиком', 'Отжимания домиком ноги на стуле'],
  'squat': ['Приседания без веса', 'Приседания с паузой внизу', 'Болгарские выпады', 'Приседания на одной ноге к стулу', 'Пистолетик'],
  'lunge': ['Выпады назад без веса', 'Болгарские выпады'],
  'bridge': ['Ягодичный мост', 'Ягодичный мост на одной ноге', 'Ягодичный мост с плечами на диване'],
  'calf': ['Подъём на носки', 'Подъём на носки на одной ноге'],
  'plank': ['Планка', 'Планка с подъёмом руки'],
  'side_plank': ['Боковая планка', 'Боковая планка с подъёмом ноги'],
  'abs': ['Скручивания', 'Подъём ног лёжа', 'Подъём коленей в висе', 'Подъём ног в висе'],
};

const exerciseCatalog = <CatalogExercise>[
  // Грудь и трицепс
  CatalogExercise(
    'Отжимания от стены',
    muscle: Muscle.chest,
    secondary: [Muscle.arms],
    repsMin: 12,
    repsMax: 20,
    chain: 'push',
    restSec: 60,
  ),
  CatalogExercise('Отжимания от стола', muscle: Muscle.chest, secondary: [Muscle.arms], repsMin: 10, repsMax: 15, chain: 'push'),
  CatalogExercise('Отжимания с колен', muscle: Muscle.chest, secondary: [Muscle.arms], repsMin: 10, repsMax: 15, chain: 'push'),
  CatalogExercise(
    'Отжимания от пола',
    muscle: Muscle.chest,
    secondary: [Muscle.arms, Muscle.shoulders],
    repsMin: 10,
    repsMax: 12,
    chain: 'push',
    hint: 'Тело прямое, локти под 45° к корпусу',
  ),
  CatalogExercise('Отжимания ноги на стуле', muscle: Muscle.chest, secondary: [Muscle.arms, Muscle.shoulders], chain: 'push'),
  CatalogExercise('Отжимания с рюкзаком', muscle: Muscle.chest, secondary: [Muscle.arms, Muscle.shoulders], chain: 'push'),
  CatalogExercise('Отжимания лучником', muscle: Muscle.chest, secondary: [Muscle.arms], repsMin: 5, repsMax: 8, chain: 'push'),
  CatalogExercise('Узкие отжимания', muscle: Muscle.arms, secondary: [Muscle.chest], chain: 'triceps', hint: 'Локти вдоль тела'),
  CatalogExercise('Узкие отжимания ноги на стуле', muscle: Muscle.arms, secondary: [Muscle.chest], chain: 'triceps'),
  CatalogExercise('Алмазные отжимания', muscle: Muscle.arms, secondary: [Muscle.chest], repsMin: 6, repsMax: 10, chain: 'triceps'),
  CatalogExercise('Обратные отжимания от стула', muscle: Muscle.arms, secondary: [Muscle.chest], repsMin: 10, repsMax: 15, chain: 'dips'),
  CatalogExercise('Обратные отжимания ноги на стуле', muscle: Muscle.arms, secondary: [Muscle.chest], chain: 'dips'),
  CatalogExercise(
    'Отжимания на брусьях',
    muscle: Muscle.chest,
    secondary: [Muscle.arms],
    repsMin: 6,
    repsMax: 10,
    chain: 'dips',
    restSec: 120,
  ),
  // Плечи
  CatalogExercise(
    'Отжимания домиком',
    muscle: Muscle.shoulders,
    secondary: [Muscle.arms],
    repsMin: 8,
    repsMax: 10,
    chain: 'pike',
    hint: 'Таз вверх',
  ),
  CatalogExercise(
    'Отжимания домиком ноги на стуле',
    muscle: Muscle.shoulders,
    secondary: [Muscle.arms],
    repsMin: 6,
    repsMax: 10,
    chain: 'pike',
  ),
  CatalogExercise('Подъём рук с резинкой в стороны', muscle: Muscle.shoulders, repsMin: 12, repsMax: 20, restSec: 60),
  // Спина и бицепс
  CatalogExercise(
    'Вис на турнике',
    muscle: Muscle.mobility,
    secondary: [Muscle.back],
    repsMin: 20,
    repsMax: 40,
    unit: 'сек',
    chain: 'pull',
    hint: 'Плечи расслаблены',
  ),
  CatalogExercise(
    'Негативные подтягивания',
    muscle: Muscle.back,
    secondary: [Muscle.arms],
    repsMin: 3,
    repsMax: 6,
    chain: 'pull',
    restSec: 120,
    hint: 'Запрыгнуть наверх и опускаться 3–5 секунд',
  ),
  CatalogExercise(
    'Подтягивания с резинкой',
    muscle: Muscle.back,
    secondary: [Muscle.arms],
    repsMin: 6,
    repsMax: 10,
    chain: 'pull',
    restSec: 120,
  ),
  CatalogExercise(
    'Подтягивания',
    muscle: Muscle.back,
    secondary: [Muscle.arms],
    sets: 4,
    repsMin: 6,
    repsMax: 8,
    chain: 'pull',
    restSec: 120,
    hint: 'Оставляй 2 повтора в запасе',
  ),
  CatalogExercise(
    'Подтягивания с паузой наверху',
    muscle: Muscle.back,
    secondary: [Muscle.arms],
    sets: 4,
    repsMin: 5,
    repsMax: 8,
    chain: 'pull',
    restSec: 120,
  ),
  CatalogExercise(
    'Подтягивания с рюкзаком',
    muscle: Muscle.back,
    secondary: [Muscle.arms],
    sets: 4,
    repsMin: 5,
    repsMax: 8,
    chain: 'pull',
    restSec: 150,
  ),
  CatalogExercise(
    'Подтягивания лучником',
    muscle: Muscle.back,
    secondary: [Muscle.arms],
    repsMin: 3,
    repsMax: 6,
    chain: 'pull',
    restSec: 150,
  ),
  CatalogExercise('Подтягивания обратным хватом', muscle: Muscle.arms, secondary: [Muscle.back], repsMin: 6, repsMax: 10, restSec: 120),
  CatalogExercise(
    'Австралийские подтягивания',
    muscle: Muscle.back,
    secondary: [Muscle.arms],
    repsMin: 12,
    repsMax: 15,
    chain: 'row',
    hint: 'К низкой перекладине или краю крепкого стола',
  ),
  CatalogExercise(
    'Австралийские подтягивания ноги на стуле',
    muscle: Muscle.back,
    secondary: [Muscle.arms],
    repsMin: 10,
    repsMax: 15,
    chain: 'row',
  ),
  CatalogExercise(
    'Австралийские подтягивания с паузой',
    muscle: Muscle.back,
    secondary: [Muscle.arms],
    repsMin: 8,
    repsMax: 12,
    chain: 'row',
  ),
  CatalogExercise('Тяга резинки к поясу', muscle: Muscle.back, secondary: [Muscle.arms], repsMin: 12, repsMax: 20, restSec: 60),
  CatalogExercise('Сгибание рук с резинкой', muscle: Muscle.arms, repsMin: 12, repsMax: 20, restSec: 60),
  // Ноги и ягодицы
  CatalogExercise('Приседания без веса', muscle: Muscle.legs, secondary: [Muscle.glutes], repsMin: 15, repsMax: 20, chain: 'squat'),
  CatalogExercise('Приседания с паузой внизу', muscle: Muscle.legs, secondary: [Muscle.glutes], repsMin: 12, repsMax: 15, chain: 'squat'),
  CatalogExercise(
    'Болгарские выпады',
    muscle: Muscle.legs,
    secondary: [Muscle.glutes],
    repsMin: 8,
    repsMax: 12,
    chain: 'squat',
    hint: 'Задняя нога на диване. На каждую ногу',
  ),
  CatalogExercise(
    'Приседания на одной ноге к стулу',
    muscle: Muscle.legs,
    secondary: [Muscle.glutes],
    repsMin: 5,
    repsMax: 10,
    chain: 'squat',
  ),
  CatalogExercise('Пистолетик', muscle: Muscle.legs, secondary: [Muscle.glutes], repsMin: 3, repsMax: 8, chain: 'squat', restSec: 120),
  CatalogExercise(
    'Выпады назад без веса',
    muscle: Muscle.legs,
    secondary: [Muscle.glutes],
    repsMin: 10,
    repsMax: 12,
    chain: 'lunge',
    hint: 'На каждую ногу',
  ),
  CatalogExercise('Приседания с рюкзаком', muscle: Muscle.legs, secondary: [Muscle.glutes], repsMin: 10, repsMax: 15, spineLoad: true),
  CatalogExercise('Выпады с рюкзаком', muscle: Muscle.legs, secondary: [Muscle.glutes], spineLoad: true),
  CatalogExercise(
    'Ягодичный мост',
    muscle: Muscle.glutes,
    secondary: [Muscle.legs],
    repsMin: 15,
    repsMax: 20,
    chain: 'bridge',
    restSec: 60,
  ),
  CatalogExercise(
    'Ягодичный мост на одной ноге',
    muscle: Muscle.glutes,
    secondary: [Muscle.legs],
    repsMin: 10,
    repsMax: 15,
    chain: 'bridge',
    restSec: 60,
  ),
  CatalogExercise(
    'Ягодичный мост с плечами на диване',
    muscle: Muscle.glutes,
    secondary: [Muscle.legs],
    repsMin: 12,
    repsMax: 20,
    chain: 'bridge',
  ),
  CatalogExercise('Подъём на носки', muscle: Muscle.legs, repsMin: 15, repsMax: 25, chain: 'calf', restSec: 60),
  CatalogExercise('Подъём на носки на одной ноге', muscle: Muscle.legs, repsMin: 12, repsMax: 20, chain: 'calf', restSec: 60),
  // Кор
  CatalogExercise('Планка', muscle: Muscle.core, repsMin: 30, repsMax: 60, unit: 'сек', chain: 'plank', restSec: 60),
  CatalogExercise('Планка с подъёмом руки', muscle: Muscle.core, repsMin: 20, repsMax: 45, unit: 'сек', chain: 'plank', restSec: 60),
  CatalogExercise(
    'Боковая планка',
    muscle: Muscle.core,
    repsMin: 20,
    repsMax: 30,
    unit: 'сек',
    chain: 'side_plank',
    restSec: 60,
    hint: 'На каждую сторону',
  ),
  CatalogExercise(
    'Боковая планка с подъёмом ноги',
    muscle: Muscle.core,
    repsMin: 15,
    repsMax: 30,
    unit: 'сек',
    chain: 'side_plank',
    restSec: 60,
  ),
  CatalogExercise('Мёртвый жук', muscle: Muscle.core, repsMin: 10, repsMax: 12, restSec: 60, hint: 'Поясница прижата к полу'),
  CatalogExercise('Скручивания', muscle: Muscle.core, repsMin: 15, repsMax: 20, chain: 'abs', restSec: 60),
  CatalogExercise('Подъём ног лёжа', muscle: Muscle.core, repsMin: 10, repsMax: 15, chain: 'abs', restSec: 60),
  CatalogExercise('Подъём коленей в висе', muscle: Muscle.core, repsMin: 8, repsMax: 15, chain: 'abs', restSec: 60),
  CatalogExercise('Подъём ног в висе', muscle: Muscle.core, repsMin: 6, repsMax: 12, chain: 'abs', restSec: 90),
  // Осанка
  CatalogExercise(
    'Тяга резинки к лицу',
    muscle: Muscle.mobility,
    secondary: [Muscle.back, Muscle.shoulders],
    repsMin: 15,
    repsMax: 15,
    restSec: 45,
  ),
  CatalogExercise('Разгибание на валике', muscle: Muscle.mobility, sets: 1, repsMin: 10, repsMax: 10, restSec: 30),
  CatalogExercise('Ангел у стены', muscle: Muscle.mobility, sets: 2, repsMin: 10, repsMax: 10, restSec: 30),
  CatalogExercise('Растяжка груди в дверном проёме', muscle: Muscle.mobility, sets: 2, repsMin: 30, repsMax: 30, unit: 'сек', restSec: 15),
  CatalogExercise(
    'Птица-собака',
    muscle: Muscle.mobility,
    secondary: [Muscle.core],
    sets: 2,
    repsMin: 8,
    repsMax: 8,
    restSec: 30,
    hint: 'На каждую сторону',
  ),
];

String _norm(String s) => s.trim().toLowerCase().replaceAll('ё', 'е');

final Map<String, CatalogExercise> _byName = {for (final e in exerciseCatalog) _norm(e.name): e};

/// Упражнение из справочника по названию, без учёта регистра и «ё».
CatalogExercise? catalogExercise(String name) => _byName[_norm(name)];

/// Следующая ступень лестницы, если она есть.
String? nextStep(String name) {
  final e = catalogExercise(name);
  final chain = e == null ? null : exerciseChains[e.chain];
  if (chain == null) return null;
  final i = chain.indexWhere((x) => _norm(x) == _norm(name));
  return i >= 0 && i + 1 < chain.length ? chain[i + 1] : null;
}

/// Предыдущая ступень: если текущая пока не даётся.
String? previousStep(String name) {
  final e = catalogExercise(name);
  final chain = e == null ? null : exerciseChains[e.chain];
  if (chain == null) return null;
  final i = chain.indexWhere((x) => _norm(x) == _norm(name));
  return i > 0 ? chain[i - 1] : null;
}

/// Готовые программы, которые можно добавить одной кнопкой.
class ReadyProgram {
  const ReadyProgram(this.name, this.description, this.weekdays, this.exercises);
  final String name;
  final String description;

  /// Дни недели, 1 = понедельник.
  final List<int> weekdays;
  final List<String> exercises;
}

const readyPrograms = <ReadyProgram>[
  ReadyProgram(
    'Всё тело дома: A',
    'Три раза в неделю, чередовать с B. Нужен турник.',
    [1, 3, 5],
    ['Подтягивания', 'Отжимания от пола', 'Приседания без веса', 'Ягодичный мост', 'Боковая планка'],
  ),
  ReadyProgram(
    'Всё тело дома: B',
    'Пара к программе A.',
    [1, 3, 5],
    ['Австралийские подтягивания', 'Узкие отжимания', 'Выпады назад без веса', 'Отжимания домиком', 'Мёртвый жук'],
  ),
  ReadyProgram(
    'Подтягивания с нуля',
    'Если пока не подтягиваешься. 3 раза в неделю, через месяц обычно выходит первое.',
    [2, 4, 6],
    ['Вис на турнике', 'Негативные подтягивания', 'Австралийские подтягивания', 'Подтягивания с резинкой'],
  ),
  ReadyProgram(
    'Без турника',
    'Всё тело на полу и со стулом.',
    [1, 3, 5],
    [
      'Отжимания от пола',
      'Обратные отжимания от стула',
      'Болгарские выпады',
      'Ягодичный мост на одной ноге',
      'Отжимания домиком',
      'Планка',
    ],
  ),
  ReadyProgram('Осанка за 10 минут', 'В дни без тренировки или после неё.', [], [
    'Вис на турнике',
    'Тяга резинки к лицу',
    'Разгибание на валике',
    'Ангел у стены',
    'Растяжка груди в дверном проёме',
    'Птица-собака',
  ]),
];
