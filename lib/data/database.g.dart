// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $TrackersTable extends Trackers with TableInfo<$TrackersTable, Tracker> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrackersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('chart'),
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TrackerKind, int> kind = GeneratedColumn<int>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  ).withConverter<TrackerKind>($TrackersTable.$converterkind);
  static const VerificationMeta _daysMaskMeta = const VerificationMeta('daysMask');
  @override
  late final GeneratedColumn<int> daysMask = GeneratedColumn<int>(
    'days_mask',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _reminderMinutesMeta = const VerificationMeta('reminderMinutes');
  @override
  late final GeneratedColumn<int> reminderMinutes = GeneratedColumn<int>(
    'reminder_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dailyGoalMeta = const VerificationMeta('dailyGoal');
  @override
  late final GeneratedColumn<double> dailyGoal = GeneratedColumn<double>(
    'daily_goal',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dailyMinMeta = const VerificationMeta('dailyMin');
  @override
  late final GeneratedColumn<double> dailyMin = GeneratedColumn<double>(
    'daily_min',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta('archived');
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("archived" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    icon,
    unit,
    kind,
    daysMask,
    reminderMinutes,
    dailyGoal,
    dailyMin,
    archived,
    sortOrder,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'trackers';
  @override
  VerificationContext validateIntegrity(Insertable<Tracker> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(_iconMeta, icon.isAcceptableOrUnknown(data['icon']!, _iconMeta));
    }
    if (data.containsKey('unit')) {
      context.handle(_unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    }
    if (data.containsKey('days_mask')) {
      context.handle(_daysMaskMeta, daysMask.isAcceptableOrUnknown(data['days_mask']!, _daysMaskMeta));
    }
    if (data.containsKey('reminder_minutes')) {
      context.handle(_reminderMinutesMeta, reminderMinutes.isAcceptableOrUnknown(data['reminder_minutes']!, _reminderMinutesMeta));
    }
    if (data.containsKey('daily_goal')) {
      context.handle(_dailyGoalMeta, dailyGoal.isAcceptableOrUnknown(data['daily_goal']!, _dailyGoalMeta));
    }
    if (data.containsKey('daily_min')) {
      context.handle(_dailyMinMeta, dailyMin.isAcceptableOrUnknown(data['daily_min']!, _dailyMinMeta));
    }
    if (data.containsKey('archived')) {
      context.handle(_archivedMeta, archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta, sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Tracker map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tracker(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      icon: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}icon'])!,
      unit: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}unit']),
      kind: $TrackersTable.$converterkind.fromSql(attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}kind'])!),
      daysMask: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}days_mask'])!,
      reminderMinutes: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}reminder_minutes']),
      dailyGoal: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}daily_goal']),
      dailyMin: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}daily_min']),
      archived: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}archived'])!,
      sortOrder: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $TrackersTable createAlias(String alias) {
    return $TrackersTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TrackerKind, int, int> $converterkind = const EnumIndexConverter<TrackerKind>(TrackerKind.values);
}

class Tracker extends DataClass implements Insertable<Tracker> {
  final int id;
  final String name;
  final String icon;
  final String? unit;
  final TrackerKind kind;

  /// В какие дни трекер показывается на экране «Сегодня». 0 = не показывать.
  final int daysMask;
  final int? reminderMinutes;

  /// Норма и минимум за день, для чисел и времени. Без них засчитывается любое значение.
  final double? dailyGoal;
  final double? dailyMin;
  final bool archived;
  final int sortOrder;
  final DateTime createdAt;
  const Tracker({
    required this.id,
    required this.name,
    required this.icon,
    this.unit,
    required this.kind,
    required this.daysMask,
    this.reminderMinutes,
    this.dailyGoal,
    this.dailyMin,
    required this.archived,
    required this.sortOrder,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['icon'] = Variable<String>(icon);
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    {
      map['kind'] = Variable<int>($TrackersTable.$converterkind.toSql(kind));
    }
    map['days_mask'] = Variable<int>(daysMask);
    if (!nullToAbsent || reminderMinutes != null) {
      map['reminder_minutes'] = Variable<int>(reminderMinutes);
    }
    if (!nullToAbsent || dailyGoal != null) {
      map['daily_goal'] = Variable<double>(dailyGoal);
    }
    if (!nullToAbsent || dailyMin != null) {
      map['daily_min'] = Variable<double>(dailyMin);
    }
    map['archived'] = Variable<bool>(archived);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TrackersCompanion toCompanion(bool nullToAbsent) {
    return TrackersCompanion(
      id: Value(id),
      name: Value(name),
      icon: Value(icon),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      kind: Value(kind),
      daysMask: Value(daysMask),
      reminderMinutes: reminderMinutes == null && nullToAbsent ? const Value.absent() : Value(reminderMinutes),
      dailyGoal: dailyGoal == null && nullToAbsent ? const Value.absent() : Value(dailyGoal),
      dailyMin: dailyMin == null && nullToAbsent ? const Value.absent() : Value(dailyMin),
      archived: Value(archived),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
    );
  }

  factory Tracker.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tracker(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      icon: serializer.fromJson<String>(json['icon']),
      unit: serializer.fromJson<String?>(json['unit']),
      kind: $TrackersTable.$converterkind.fromJson(serializer.fromJson<int>(json['kind'])),
      daysMask: serializer.fromJson<int>(json['daysMask']),
      reminderMinutes: serializer.fromJson<int?>(json['reminderMinutes']),
      dailyGoal: serializer.fromJson<double?>(json['dailyGoal']),
      dailyMin: serializer.fromJson<double?>(json['dailyMin']),
      archived: serializer.fromJson<bool>(json['archived']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'icon': serializer.toJson<String>(icon),
      'unit': serializer.toJson<String?>(unit),
      'kind': serializer.toJson<int>($TrackersTable.$converterkind.toJson(kind)),
      'daysMask': serializer.toJson<int>(daysMask),
      'reminderMinutes': serializer.toJson<int?>(reminderMinutes),
      'dailyGoal': serializer.toJson<double?>(dailyGoal),
      'dailyMin': serializer.toJson<double?>(dailyMin),
      'archived': serializer.toJson<bool>(archived),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Tracker copyWith({
    int? id,
    String? name,
    String? icon,
    Value<String?> unit = const Value.absent(),
    TrackerKind? kind,
    int? daysMask,
    Value<int?> reminderMinutes = const Value.absent(),
    Value<double?> dailyGoal = const Value.absent(),
    Value<double?> dailyMin = const Value.absent(),
    bool? archived,
    int? sortOrder,
    DateTime? createdAt,
  }) => Tracker(
    id: id ?? this.id,
    name: name ?? this.name,
    icon: icon ?? this.icon,
    unit: unit.present ? unit.value : this.unit,
    kind: kind ?? this.kind,
    daysMask: daysMask ?? this.daysMask,
    reminderMinutes: reminderMinutes.present ? reminderMinutes.value : this.reminderMinutes,
    dailyGoal: dailyGoal.present ? dailyGoal.value : this.dailyGoal,
    dailyMin: dailyMin.present ? dailyMin.value : this.dailyMin,
    archived: archived ?? this.archived,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
  );
  Tracker copyWithCompanion(TrackersCompanion data) {
    return Tracker(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      icon: data.icon.present ? data.icon.value : this.icon,
      unit: data.unit.present ? data.unit.value : this.unit,
      kind: data.kind.present ? data.kind.value : this.kind,
      daysMask: data.daysMask.present ? data.daysMask.value : this.daysMask,
      reminderMinutes: data.reminderMinutes.present ? data.reminderMinutes.value : this.reminderMinutes,
      dailyGoal: data.dailyGoal.present ? data.dailyGoal.value : this.dailyGoal,
      dailyMin: data.dailyMin.present ? data.dailyMin.value : this.dailyMin,
      archived: data.archived.present ? data.archived.value : this.archived,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tracker(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('unit: $unit, ')
          ..write('kind: $kind, ')
          ..write('daysMask: $daysMask, ')
          ..write('reminderMinutes: $reminderMinutes, ')
          ..write('dailyGoal: $dailyGoal, ')
          ..write('dailyMin: $dailyMin, ')
          ..write('archived: $archived, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, icon, unit, kind, daysMask, reminderMinutes, dailyGoal, dailyMin, archived, sortOrder, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tracker &&
          other.id == this.id &&
          other.name == this.name &&
          other.icon == this.icon &&
          other.unit == this.unit &&
          other.kind == this.kind &&
          other.daysMask == this.daysMask &&
          other.reminderMinutes == this.reminderMinutes &&
          other.dailyGoal == this.dailyGoal &&
          other.dailyMin == this.dailyMin &&
          other.archived == this.archived &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt);
}

class TrackersCompanion extends UpdateCompanion<Tracker> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> icon;
  final Value<String?> unit;
  final Value<TrackerKind> kind;
  final Value<int> daysMask;
  final Value<int?> reminderMinutes;
  final Value<double?> dailyGoal;
  final Value<double?> dailyMin;
  final Value<bool> archived;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  const TrackersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.icon = const Value.absent(),
    this.unit = const Value.absent(),
    this.kind = const Value.absent(),
    this.daysMask = const Value.absent(),
    this.reminderMinutes = const Value.absent(),
    this.dailyGoal = const Value.absent(),
    this.dailyMin = const Value.absent(),
    this.archived = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  TrackersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.icon = const Value.absent(),
    this.unit = const Value.absent(),
    required TrackerKind kind,
    this.daysMask = const Value.absent(),
    this.reminderMinutes = const Value.absent(),
    this.dailyGoal = const Value.absent(),
    this.dailyMin = const Value.absent(),
    this.archived = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : name = Value(name),
       kind = Value(kind);
  static Insertable<Tracker> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? icon,
    Expression<String>? unit,
    Expression<int>? kind,
    Expression<int>? daysMask,
    Expression<int>? reminderMinutes,
    Expression<double>? dailyGoal,
    Expression<double>? dailyMin,
    Expression<bool>? archived,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (icon != null) 'icon': icon,
      if (unit != null) 'unit': unit,
      if (kind != null) 'kind': kind,
      if (daysMask != null) 'days_mask': daysMask,
      if (reminderMinutes != null) 'reminder_minutes': reminderMinutes,
      if (dailyGoal != null) 'daily_goal': dailyGoal,
      if (dailyMin != null) 'daily_min': dailyMin,
      if (archived != null) 'archived': archived,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  TrackersCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? icon,
    Value<String?>? unit,
    Value<TrackerKind>? kind,
    Value<int>? daysMask,
    Value<int?>? reminderMinutes,
    Value<double?>? dailyGoal,
    Value<double?>? dailyMin,
    Value<bool>? archived,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
  }) {
    return TrackersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      unit: unit ?? this.unit,
      kind: kind ?? this.kind,
      daysMask: daysMask ?? this.daysMask,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      dailyMin: dailyMin ?? this.dailyMin,
      archived: archived ?? this.archived,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (kind.present) {
      map['kind'] = Variable<int>($TrackersTable.$converterkind.toSql(kind.value));
    }
    if (daysMask.present) {
      map['days_mask'] = Variable<int>(daysMask.value);
    }
    if (reminderMinutes.present) {
      map['reminder_minutes'] = Variable<int>(reminderMinutes.value);
    }
    if (dailyGoal.present) {
      map['daily_goal'] = Variable<double>(dailyGoal.value);
    }
    if (dailyMin.present) {
      map['daily_min'] = Variable<double>(dailyMin.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrackersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('unit: $unit, ')
          ..write('kind: $kind, ')
          ..write('daysMask: $daysMask, ')
          ..write('reminderMinutes: $reminderMinutes, ')
          ..write('dailyGoal: $dailyGoal, ')
          ..write('dailyMin: $dailyMin, ')
          ..write('archived: $archived, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $TrackerEntriesTable extends TrackerEntries with TableInfo<$TrackerEntriesTable, TrackerEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TrackerEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _trackerIdMeta = const VerificationMeta('trackerId');
  @override
  late final GeneratedColumn<int> trackerId = GeneratedColumn<int>(
    'tracker_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES trackers (id) ON DELETE CASCADE'),
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<int> day = GeneratedColumn<int>('day', aliasedName, false, type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, trackerId, day, at, value, note];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tracker_entries';
  @override
  VerificationContext validateIntegrity(Insertable<TrackerEntry> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('tracker_id')) {
      context.handle(_trackerIdMeta, trackerId.isAcceptableOrUnknown(data['tracker_id']!, _trackerIdMeta));
    } else if (isInserting) {
      context.missing(_trackerIdMeta);
    }
    if (data.containsKey('day')) {
      context.handle(_dayMeta, day.isAcceptableOrUnknown(data['day']!, _dayMeta));
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    }
    if (data.containsKey('value')) {
      context.handle(_valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('note')) {
      context.handle(_noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TrackerEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TrackerEntry(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      trackerId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}tracker_id'])!,
      day: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}day'])!,
      at: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}at'])!,
      value: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}value'])!,
      note: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}note']),
    );
  }

  @override
  $TrackerEntriesTable createAlias(String alias) {
    return $TrackerEntriesTable(attachedDatabase, alias);
  }
}

class TrackerEntry extends DataClass implements Insertable<TrackerEntry> {
  final int id;
  final int trackerId;
  final int day;
  final DateTime at;
  final double value;
  final String? note;
  const TrackerEntry({required this.id, required this.trackerId, required this.day, required this.at, required this.value, this.note});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['tracker_id'] = Variable<int>(trackerId);
    map['day'] = Variable<int>(day);
    map['at'] = Variable<DateTime>(at);
    map['value'] = Variable<double>(value);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  TrackerEntriesCompanion toCompanion(bool nullToAbsent) {
    return TrackerEntriesCompanion(
      id: Value(id),
      trackerId: Value(trackerId),
      day: Value(day),
      at: Value(at),
      value: Value(value),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory TrackerEntry.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TrackerEntry(
      id: serializer.fromJson<int>(json['id']),
      trackerId: serializer.fromJson<int>(json['trackerId']),
      day: serializer.fromJson<int>(json['day']),
      at: serializer.fromJson<DateTime>(json['at']),
      value: serializer.fromJson<double>(json['value']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'trackerId': serializer.toJson<int>(trackerId),
      'day': serializer.toJson<int>(day),
      'at': serializer.toJson<DateTime>(at),
      'value': serializer.toJson<double>(value),
      'note': serializer.toJson<String?>(note),
    };
  }

  TrackerEntry copyWith({int? id, int? trackerId, int? day, DateTime? at, double? value, Value<String?> note = const Value.absent()}) =>
      TrackerEntry(
        id: id ?? this.id,
        trackerId: trackerId ?? this.trackerId,
        day: day ?? this.day,
        at: at ?? this.at,
        value: value ?? this.value,
        note: note.present ? note.value : this.note,
      );
  TrackerEntry copyWithCompanion(TrackerEntriesCompanion data) {
    return TrackerEntry(
      id: data.id.present ? data.id.value : this.id,
      trackerId: data.trackerId.present ? data.trackerId.value : this.trackerId,
      day: data.day.present ? data.day.value : this.day,
      at: data.at.present ? data.at.value : this.at,
      value: data.value.present ? data.value.value : this.value,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TrackerEntry(')
          ..write('id: $id, ')
          ..write('trackerId: $trackerId, ')
          ..write('day: $day, ')
          ..write('at: $at, ')
          ..write('value: $value, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, trackerId, day, at, value, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrackerEntry &&
          other.id == this.id &&
          other.trackerId == this.trackerId &&
          other.day == this.day &&
          other.at == this.at &&
          other.value == this.value &&
          other.note == this.note);
}

class TrackerEntriesCompanion extends UpdateCompanion<TrackerEntry> {
  final Value<int> id;
  final Value<int> trackerId;
  final Value<int> day;
  final Value<DateTime> at;
  final Value<double> value;
  final Value<String?> note;
  const TrackerEntriesCompanion({
    this.id = const Value.absent(),
    this.trackerId = const Value.absent(),
    this.day = const Value.absent(),
    this.at = const Value.absent(),
    this.value = const Value.absent(),
    this.note = const Value.absent(),
  });
  TrackerEntriesCompanion.insert({
    this.id = const Value.absent(),
    required int trackerId,
    required int day,
    this.at = const Value.absent(),
    required double value,
    this.note = const Value.absent(),
  }) : trackerId = Value(trackerId),
       day = Value(day),
       value = Value(value);
  static Insertable<TrackerEntry> custom({
    Expression<int>? id,
    Expression<int>? trackerId,
    Expression<int>? day,
    Expression<DateTime>? at,
    Expression<double>? value,
    Expression<String>? note,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (trackerId != null) 'tracker_id': trackerId,
      if (day != null) 'day': day,
      if (at != null) 'at': at,
      if (value != null) 'value': value,
      if (note != null) 'note': note,
    });
  }

  TrackerEntriesCompanion copyWith({
    Value<int>? id,
    Value<int>? trackerId,
    Value<int>? day,
    Value<DateTime>? at,
    Value<double>? value,
    Value<String?>? note,
  }) {
    return TrackerEntriesCompanion(
      id: id ?? this.id,
      trackerId: trackerId ?? this.trackerId,
      day: day ?? this.day,
      at: at ?? this.at,
      value: value ?? this.value,
      note: note ?? this.note,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (trackerId.present) {
      map['tracker_id'] = Variable<int>(trackerId.value);
    }
    if (day.present) {
      map['day'] = Variable<int>(day.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TrackerEntriesCompanion(')
          ..write('id: $id, ')
          ..write('trackerId: $trackerId, ')
          ..write('day: $day, ')
          ..write('at: $at, ')
          ..write('value: $value, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }
}

class $HabitsTable extends Habits with TableInfo<$HabitsTable, Habit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HabitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('check'),
  );
  static const VerificationMeta _daysMaskMeta = const VerificationMeta('daysMask');
  @override
  late final GeneratedColumn<int> daysMask = GeneratedColumn<int>(
    'days_mask',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(everyDay),
  );
  static const VerificationMeta _reminderMinutesMeta = const VerificationMeta('reminderMinutes');
  @override
  late final GeneratedColumn<int> reminderMinutes = GeneratedColumn<int>(
    'reminder_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _minimumTextMeta = const VerificationMeta('minimumText');
  @override
  late final GeneratedColumn<String> minimumText = GeneratedColumn<String>(
    'minimum_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _trackerIdMeta = const VerificationMeta('trackerId');
  @override
  late final GeneratedColumn<int> trackerId = GeneratedColumn<int>(
    'tracker_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES trackers (id) ON DELETE SET NULL'),
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta('archived');
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("archived" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, icon, daysMask, reminderMinutes, minimumText, trackerId, archived, sortOrder, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'habits';
  @override
  VerificationContext validateIntegrity(Insertable<Habit> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(_iconMeta, icon.isAcceptableOrUnknown(data['icon']!, _iconMeta));
    }
    if (data.containsKey('days_mask')) {
      context.handle(_daysMaskMeta, daysMask.isAcceptableOrUnknown(data['days_mask']!, _daysMaskMeta));
    }
    if (data.containsKey('reminder_minutes')) {
      context.handle(_reminderMinutesMeta, reminderMinutes.isAcceptableOrUnknown(data['reminder_minutes']!, _reminderMinutesMeta));
    }
    if (data.containsKey('minimum_text')) {
      context.handle(_minimumTextMeta, minimumText.isAcceptableOrUnknown(data['minimum_text']!, _minimumTextMeta));
    }
    if (data.containsKey('tracker_id')) {
      context.handle(_trackerIdMeta, trackerId.isAcceptableOrUnknown(data['tracker_id']!, _trackerIdMeta));
    }
    if (data.containsKey('archived')) {
      context.handle(_archivedMeta, archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta, sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Habit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Habit(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      icon: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}icon'])!,
      daysMask: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}days_mask'])!,
      reminderMinutes: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}reminder_minutes']),
      minimumText: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}minimum_text']),
      trackerId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}tracker_id']),
      archived: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}archived'])!,
      sortOrder: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $HabitsTable createAlias(String alias) {
    return $HabitsTable(attachedDatabase, alias);
  }
}

class Habit extends DataClass implements Insertable<Habit> {
  final int id;
  final String name;
  final String icon;
  final int daysMask;

  /// Время напоминания в минутах от полуночи.
  final int? reminderMinutes;

  /// Что считается минимумом в плохой день.
  final String? minimumText;

  /// Если задан, привычка отмечается сама, когда в этот трекер вносят значение.
  final int? trackerId;
  final bool archived;
  final int sortOrder;
  final DateTime createdAt;
  const Habit({
    required this.id,
    required this.name,
    required this.icon,
    required this.daysMask,
    this.reminderMinutes,
    this.minimumText,
    this.trackerId,
    required this.archived,
    required this.sortOrder,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['icon'] = Variable<String>(icon);
    map['days_mask'] = Variable<int>(daysMask);
    if (!nullToAbsent || reminderMinutes != null) {
      map['reminder_minutes'] = Variable<int>(reminderMinutes);
    }
    if (!nullToAbsent || minimumText != null) {
      map['minimum_text'] = Variable<String>(minimumText);
    }
    if (!nullToAbsent || trackerId != null) {
      map['tracker_id'] = Variable<int>(trackerId);
    }
    map['archived'] = Variable<bool>(archived);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  HabitsCompanion toCompanion(bool nullToAbsent) {
    return HabitsCompanion(
      id: Value(id),
      name: Value(name),
      icon: Value(icon),
      daysMask: Value(daysMask),
      reminderMinutes: reminderMinutes == null && nullToAbsent ? const Value.absent() : Value(reminderMinutes),
      minimumText: minimumText == null && nullToAbsent ? const Value.absent() : Value(minimumText),
      trackerId: trackerId == null && nullToAbsent ? const Value.absent() : Value(trackerId),
      archived: Value(archived),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
    );
  }

  factory Habit.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Habit(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      icon: serializer.fromJson<String>(json['icon']),
      daysMask: serializer.fromJson<int>(json['daysMask']),
      reminderMinutes: serializer.fromJson<int?>(json['reminderMinutes']),
      minimumText: serializer.fromJson<String?>(json['minimumText']),
      trackerId: serializer.fromJson<int?>(json['trackerId']),
      archived: serializer.fromJson<bool>(json['archived']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'icon': serializer.toJson<String>(icon),
      'daysMask': serializer.toJson<int>(daysMask),
      'reminderMinutes': serializer.toJson<int?>(reminderMinutes),
      'minimumText': serializer.toJson<String?>(minimumText),
      'trackerId': serializer.toJson<int?>(trackerId),
      'archived': serializer.toJson<bool>(archived),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Habit copyWith({
    int? id,
    String? name,
    String? icon,
    int? daysMask,
    Value<int?> reminderMinutes = const Value.absent(),
    Value<String?> minimumText = const Value.absent(),
    Value<int?> trackerId = const Value.absent(),
    bool? archived,
    int? sortOrder,
    DateTime? createdAt,
  }) => Habit(
    id: id ?? this.id,
    name: name ?? this.name,
    icon: icon ?? this.icon,
    daysMask: daysMask ?? this.daysMask,
    reminderMinutes: reminderMinutes.present ? reminderMinutes.value : this.reminderMinutes,
    minimumText: minimumText.present ? minimumText.value : this.minimumText,
    trackerId: trackerId.present ? trackerId.value : this.trackerId,
    archived: archived ?? this.archived,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
  );
  Habit copyWithCompanion(HabitsCompanion data) {
    return Habit(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      icon: data.icon.present ? data.icon.value : this.icon,
      daysMask: data.daysMask.present ? data.daysMask.value : this.daysMask,
      reminderMinutes: data.reminderMinutes.present ? data.reminderMinutes.value : this.reminderMinutes,
      minimumText: data.minimumText.present ? data.minimumText.value : this.minimumText,
      trackerId: data.trackerId.present ? data.trackerId.value : this.trackerId,
      archived: data.archived.present ? data.archived.value : this.archived,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Habit(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('daysMask: $daysMask, ')
          ..write('reminderMinutes: $reminderMinutes, ')
          ..write('minimumText: $minimumText, ')
          ..write('trackerId: $trackerId, ')
          ..write('archived: $archived, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, icon, daysMask, reminderMinutes, minimumText, trackerId, archived, sortOrder, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Habit &&
          other.id == this.id &&
          other.name == this.name &&
          other.icon == this.icon &&
          other.daysMask == this.daysMask &&
          other.reminderMinutes == this.reminderMinutes &&
          other.minimumText == this.minimumText &&
          other.trackerId == this.trackerId &&
          other.archived == this.archived &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt);
}

class HabitsCompanion extends UpdateCompanion<Habit> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> icon;
  final Value<int> daysMask;
  final Value<int?> reminderMinutes;
  final Value<String?> minimumText;
  final Value<int?> trackerId;
  final Value<bool> archived;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  const HabitsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.icon = const Value.absent(),
    this.daysMask = const Value.absent(),
    this.reminderMinutes = const Value.absent(),
    this.minimumText = const Value.absent(),
    this.trackerId = const Value.absent(),
    this.archived = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  HabitsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.icon = const Value.absent(),
    this.daysMask = const Value.absent(),
    this.reminderMinutes = const Value.absent(),
    this.minimumText = const Value.absent(),
    this.trackerId = const Value.absent(),
    this.archived = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Habit> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? icon,
    Expression<int>? daysMask,
    Expression<int>? reminderMinutes,
    Expression<String>? minimumText,
    Expression<int>? trackerId,
    Expression<bool>? archived,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (icon != null) 'icon': icon,
      if (daysMask != null) 'days_mask': daysMask,
      if (reminderMinutes != null) 'reminder_minutes': reminderMinutes,
      if (minimumText != null) 'minimum_text': minimumText,
      if (trackerId != null) 'tracker_id': trackerId,
      if (archived != null) 'archived': archived,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  HabitsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? icon,
    Value<int>? daysMask,
    Value<int?>? reminderMinutes,
    Value<String?>? minimumText,
    Value<int?>? trackerId,
    Value<bool>? archived,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
  }) {
    return HabitsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      daysMask: daysMask ?? this.daysMask,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      minimumText: minimumText ?? this.minimumText,
      trackerId: trackerId ?? this.trackerId,
      archived: archived ?? this.archived,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (daysMask.present) {
      map['days_mask'] = Variable<int>(daysMask.value);
    }
    if (reminderMinutes.present) {
      map['reminder_minutes'] = Variable<int>(reminderMinutes.value);
    }
    if (minimumText.present) {
      map['minimum_text'] = Variable<String>(minimumText.value);
    }
    if (trackerId.present) {
      map['tracker_id'] = Variable<int>(trackerId.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HabitsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('daysMask: $daysMask, ')
          ..write('reminderMinutes: $reminderMinutes, ')
          ..write('minimumText: $minimumText, ')
          ..write('trackerId: $trackerId, ')
          ..write('archived: $archived, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $HabitLogsTable extends HabitLogs with TableInfo<$HabitLogsTable, HabitLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HabitLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _habitIdMeta = const VerificationMeta('habitId');
  @override
  late final GeneratedColumn<int> habitId = GeneratedColumn<int>(
    'habit_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES habits (id) ON DELETE CASCADE'),
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<int> day = GeneratedColumn<int>('day', aliasedName, false, type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _minimumMeta = const VerificationMeta('minimum');
  @override
  late final GeneratedColumn<bool> minimum = GeneratedColumn<bool>(
    'minimum',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("minimum" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [id, habitId, day, minimum];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'habit_logs';
  @override
  VerificationContext validateIntegrity(Insertable<HabitLog> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('habit_id')) {
      context.handle(_habitIdMeta, habitId.isAcceptableOrUnknown(data['habit_id']!, _habitIdMeta));
    } else if (isInserting) {
      context.missing(_habitIdMeta);
    }
    if (data.containsKey('day')) {
      context.handle(_dayMeta, day.isAcceptableOrUnknown(data['day']!, _dayMeta));
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('minimum')) {
      context.handle(_minimumMeta, minimum.isAcceptableOrUnknown(data['minimum']!, _minimumMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {habitId, day},
  ];
  @override
  HabitLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HabitLog(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      habitId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}habit_id'])!,
      day: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}day'])!,
      minimum: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}minimum'])!,
    );
  }

  @override
  $HabitLogsTable createAlias(String alias) {
    return $HabitLogsTable(attachedDatabase, alias);
  }
}

class HabitLog extends DataClass implements Insertable<HabitLog> {
  final int id;
  final int habitId;
  final int day;
  final bool minimum;
  const HabitLog({required this.id, required this.habitId, required this.day, required this.minimum});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['habit_id'] = Variable<int>(habitId);
    map['day'] = Variable<int>(day);
    map['minimum'] = Variable<bool>(minimum);
    return map;
  }

  HabitLogsCompanion toCompanion(bool nullToAbsent) {
    return HabitLogsCompanion(id: Value(id), habitId: Value(habitId), day: Value(day), minimum: Value(minimum));
  }

  factory HabitLog.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HabitLog(
      id: serializer.fromJson<int>(json['id']),
      habitId: serializer.fromJson<int>(json['habitId']),
      day: serializer.fromJson<int>(json['day']),
      minimum: serializer.fromJson<bool>(json['minimum']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'habitId': serializer.toJson<int>(habitId),
      'day': serializer.toJson<int>(day),
      'minimum': serializer.toJson<bool>(minimum),
    };
  }

  HabitLog copyWith({int? id, int? habitId, int? day, bool? minimum}) =>
      HabitLog(id: id ?? this.id, habitId: habitId ?? this.habitId, day: day ?? this.day, minimum: minimum ?? this.minimum);
  HabitLog copyWithCompanion(HabitLogsCompanion data) {
    return HabitLog(
      id: data.id.present ? data.id.value : this.id,
      habitId: data.habitId.present ? data.habitId.value : this.habitId,
      day: data.day.present ? data.day.value : this.day,
      minimum: data.minimum.present ? data.minimum.value : this.minimum,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HabitLog(')
          ..write('id: $id, ')
          ..write('habitId: $habitId, ')
          ..write('day: $day, ')
          ..write('minimum: $minimum')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, habitId, day, minimum);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HabitLog && other.id == this.id && other.habitId == this.habitId && other.day == this.day && other.minimum == this.minimum);
}

class HabitLogsCompanion extends UpdateCompanion<HabitLog> {
  final Value<int> id;
  final Value<int> habitId;
  final Value<int> day;
  final Value<bool> minimum;
  const HabitLogsCompanion({
    this.id = const Value.absent(),
    this.habitId = const Value.absent(),
    this.day = const Value.absent(),
    this.minimum = const Value.absent(),
  });
  HabitLogsCompanion.insert({this.id = const Value.absent(), required int habitId, required int day, this.minimum = const Value.absent()})
    : habitId = Value(habitId),
      day = Value(day);
  static Insertable<HabitLog> custom({Expression<int>? id, Expression<int>? habitId, Expression<int>? day, Expression<bool>? minimum}) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (habitId != null) 'habit_id': habitId,
      if (day != null) 'day': day,
      if (minimum != null) 'minimum': minimum,
    });
  }

  HabitLogsCompanion copyWith({Value<int>? id, Value<int>? habitId, Value<int>? day, Value<bool>? minimum}) {
    return HabitLogsCompanion(id: id ?? this.id, habitId: habitId ?? this.habitId, day: day ?? this.day, minimum: minimum ?? this.minimum);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (habitId.present) {
      map['habit_id'] = Variable<int>(habitId.value);
    }
    if (day.present) {
      map['day'] = Variable<int>(day.value);
    }
    if (minimum.present) {
      map['minimum'] = Variable<bool>(minimum.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HabitLogsCompanion(')
          ..write('id: $id, ')
          ..write('habitId: $habitId, ')
          ..write('day: $day, ')
          ..write('minimum: $minimum')
          ..write(')'))
        .toString();
  }
}

class $FundsTable extends Funds with TableInfo<$FundsTable, Fund> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FundsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('savings'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<FundKind, int> kind = GeneratedColumn<int>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  ).withConverter<FundKind>($FundsTable.$converterkind);
  static const VerificationMeta _initialAmountMeta = const VerificationMeta('initialAmount');
  @override
  late final GeneratedColumn<double> initialAmount = GeneratedColumn<double>(
    'initial_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _targetMeta = const VerificationMeta('target');
  @override
  late final GeneratedColumn<double> target = GeneratedColumn<double>(
    'target',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _interestRateMeta = const VerificationMeta('interestRate');
  @override
  late final GeneratedColumn<double> interestRate = GeneratedColumn<double>(
    'interest_rate',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _monthlyAmountMeta = const VerificationMeta('monthlyAmount');
  @override
  late final GeneratedColumn<double> monthlyAmount = GeneratedColumn<double>(
    'monthly_amount',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta('archived');
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("archived" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    icon,
    kind,
    initialAmount,
    target,
    interestRate,
    monthlyAmount,
    archived,
    sortOrder,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'funds';
  @override
  VerificationContext validateIntegrity(Insertable<Fund> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(_iconMeta, icon.isAcceptableOrUnknown(data['icon']!, _iconMeta));
    }
    if (data.containsKey('initial_amount')) {
      context.handle(_initialAmountMeta, initialAmount.isAcceptableOrUnknown(data['initial_amount']!, _initialAmountMeta));
    }
    if (data.containsKey('target')) {
      context.handle(_targetMeta, target.isAcceptableOrUnknown(data['target']!, _targetMeta));
    }
    if (data.containsKey('interest_rate')) {
      context.handle(_interestRateMeta, interestRate.isAcceptableOrUnknown(data['interest_rate']!, _interestRateMeta));
    }
    if (data.containsKey('monthly_amount')) {
      context.handle(_monthlyAmountMeta, monthlyAmount.isAcceptableOrUnknown(data['monthly_amount']!, _monthlyAmountMeta));
    }
    if (data.containsKey('archived')) {
      context.handle(_archivedMeta, archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta, sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Fund map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Fund(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      icon: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}icon'])!,
      kind: $FundsTable.$converterkind.fromSql(attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}kind'])!),
      initialAmount: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}initial_amount'])!,
      target: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}target']),
      interestRate: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}interest_rate']),
      monthlyAmount: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}monthly_amount']),
      archived: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}archived'])!,
      sortOrder: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $FundsTable createAlias(String alias) {
    return $FundsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<FundKind, int, int> $converterkind = const EnumIndexConverter<FundKind>(FundKind.values);
}

class Fund extends DataClass implements Insertable<Fund> {
  final int id;
  final String name;
  final String icon;
  final FundKind kind;

  /// Для копилки: сколько уже было на старте. Для долга: сколько был должен на старте.
  final double initialAmount;

  /// Для копилки: сколько нужно накопить.
  final double? target;

  /// Для долга: годовая ставка в процентах.
  final double? interestRate;

  /// Для долга: плановый платёж в месяц. Для копилки: плановый взнос в месяц.
  final double? monthlyAmount;
  final bool archived;
  final int sortOrder;
  final DateTime createdAt;
  const Fund({
    required this.id,
    required this.name,
    required this.icon,
    required this.kind,
    required this.initialAmount,
    this.target,
    this.interestRate,
    this.monthlyAmount,
    required this.archived,
    required this.sortOrder,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['icon'] = Variable<String>(icon);
    {
      map['kind'] = Variable<int>($FundsTable.$converterkind.toSql(kind));
    }
    map['initial_amount'] = Variable<double>(initialAmount);
    if (!nullToAbsent || target != null) {
      map['target'] = Variable<double>(target);
    }
    if (!nullToAbsent || interestRate != null) {
      map['interest_rate'] = Variable<double>(interestRate);
    }
    if (!nullToAbsent || monthlyAmount != null) {
      map['monthly_amount'] = Variable<double>(monthlyAmount);
    }
    map['archived'] = Variable<bool>(archived);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  FundsCompanion toCompanion(bool nullToAbsent) {
    return FundsCompanion(
      id: Value(id),
      name: Value(name),
      icon: Value(icon),
      kind: Value(kind),
      initialAmount: Value(initialAmount),
      target: target == null && nullToAbsent ? const Value.absent() : Value(target),
      interestRate: interestRate == null && nullToAbsent ? const Value.absent() : Value(interestRate),
      monthlyAmount: monthlyAmount == null && nullToAbsent ? const Value.absent() : Value(monthlyAmount),
      archived: Value(archived),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
    );
  }

  factory Fund.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Fund(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      icon: serializer.fromJson<String>(json['icon']),
      kind: $FundsTable.$converterkind.fromJson(serializer.fromJson<int>(json['kind'])),
      initialAmount: serializer.fromJson<double>(json['initialAmount']),
      target: serializer.fromJson<double?>(json['target']),
      interestRate: serializer.fromJson<double?>(json['interestRate']),
      monthlyAmount: serializer.fromJson<double?>(json['monthlyAmount']),
      archived: serializer.fromJson<bool>(json['archived']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'icon': serializer.toJson<String>(icon),
      'kind': serializer.toJson<int>($FundsTable.$converterkind.toJson(kind)),
      'initialAmount': serializer.toJson<double>(initialAmount),
      'target': serializer.toJson<double?>(target),
      'interestRate': serializer.toJson<double?>(interestRate),
      'monthlyAmount': serializer.toJson<double?>(monthlyAmount),
      'archived': serializer.toJson<bool>(archived),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Fund copyWith({
    int? id,
    String? name,
    String? icon,
    FundKind? kind,
    double? initialAmount,
    Value<double?> target = const Value.absent(),
    Value<double?> interestRate = const Value.absent(),
    Value<double?> monthlyAmount = const Value.absent(),
    bool? archived,
    int? sortOrder,
    DateTime? createdAt,
  }) => Fund(
    id: id ?? this.id,
    name: name ?? this.name,
    icon: icon ?? this.icon,
    kind: kind ?? this.kind,
    initialAmount: initialAmount ?? this.initialAmount,
    target: target.present ? target.value : this.target,
    interestRate: interestRate.present ? interestRate.value : this.interestRate,
    monthlyAmount: monthlyAmount.present ? monthlyAmount.value : this.monthlyAmount,
    archived: archived ?? this.archived,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
  );
  Fund copyWithCompanion(FundsCompanion data) {
    return Fund(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      icon: data.icon.present ? data.icon.value : this.icon,
      kind: data.kind.present ? data.kind.value : this.kind,
      initialAmount: data.initialAmount.present ? data.initialAmount.value : this.initialAmount,
      target: data.target.present ? data.target.value : this.target,
      interestRate: data.interestRate.present ? data.interestRate.value : this.interestRate,
      monthlyAmount: data.monthlyAmount.present ? data.monthlyAmount.value : this.monthlyAmount,
      archived: data.archived.present ? data.archived.value : this.archived,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Fund(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('kind: $kind, ')
          ..write('initialAmount: $initialAmount, ')
          ..write('target: $target, ')
          ..write('interestRate: $interestRate, ')
          ..write('monthlyAmount: $monthlyAmount, ')
          ..write('archived: $archived, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, icon, kind, initialAmount, target, interestRate, monthlyAmount, archived, sortOrder, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Fund &&
          other.id == this.id &&
          other.name == this.name &&
          other.icon == this.icon &&
          other.kind == this.kind &&
          other.initialAmount == this.initialAmount &&
          other.target == this.target &&
          other.interestRate == this.interestRate &&
          other.monthlyAmount == this.monthlyAmount &&
          other.archived == this.archived &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt);
}

class FundsCompanion extends UpdateCompanion<Fund> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> icon;
  final Value<FundKind> kind;
  final Value<double> initialAmount;
  final Value<double?> target;
  final Value<double?> interestRate;
  final Value<double?> monthlyAmount;
  final Value<bool> archived;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  const FundsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.icon = const Value.absent(),
    this.kind = const Value.absent(),
    this.initialAmount = const Value.absent(),
    this.target = const Value.absent(),
    this.interestRate = const Value.absent(),
    this.monthlyAmount = const Value.absent(),
    this.archived = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  FundsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.icon = const Value.absent(),
    required FundKind kind,
    this.initialAmount = const Value.absent(),
    this.target = const Value.absent(),
    this.interestRate = const Value.absent(),
    this.monthlyAmount = const Value.absent(),
    this.archived = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : name = Value(name),
       kind = Value(kind);
  static Insertable<Fund> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? icon,
    Expression<int>? kind,
    Expression<double>? initialAmount,
    Expression<double>? target,
    Expression<double>? interestRate,
    Expression<double>? monthlyAmount,
    Expression<bool>? archived,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (icon != null) 'icon': icon,
      if (kind != null) 'kind': kind,
      if (initialAmount != null) 'initial_amount': initialAmount,
      if (target != null) 'target': target,
      if (interestRate != null) 'interest_rate': interestRate,
      if (monthlyAmount != null) 'monthly_amount': monthlyAmount,
      if (archived != null) 'archived': archived,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  FundsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? icon,
    Value<FundKind>? kind,
    Value<double>? initialAmount,
    Value<double?>? target,
    Value<double?>? interestRate,
    Value<double?>? monthlyAmount,
    Value<bool>? archived,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
  }) {
    return FundsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      kind: kind ?? this.kind,
      initialAmount: initialAmount ?? this.initialAmount,
      target: target ?? this.target,
      interestRate: interestRate ?? this.interestRate,
      monthlyAmount: monthlyAmount ?? this.monthlyAmount,
      archived: archived ?? this.archived,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (kind.present) {
      map['kind'] = Variable<int>($FundsTable.$converterkind.toSql(kind.value));
    }
    if (initialAmount.present) {
      map['initial_amount'] = Variable<double>(initialAmount.value);
    }
    if (target.present) {
      map['target'] = Variable<double>(target.value);
    }
    if (interestRate.present) {
      map['interest_rate'] = Variable<double>(interestRate.value);
    }
    if (monthlyAmount.present) {
      map['monthly_amount'] = Variable<double>(monthlyAmount.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FundsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('kind: $kind, ')
          ..write('initialAmount: $initialAmount, ')
          ..write('target: $target, ')
          ..write('interestRate: $interestRate, ')
          ..write('monthlyAmount: $monthlyAmount, ')
          ..write('archived: $archived, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $GoalsTable extends Goals with TableInfo<$GoalsTable, Goal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<GoalKind, int> kind = GeneratedColumn<int>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  ).withConverter<GoalKind>($GoalsTable.$converterkind);
  static const VerificationMeta _trackerIdMeta = const VerificationMeta('trackerId');
  @override
  late final GeneratedColumn<int> trackerId = GeneratedColumn<int>(
    'tracker_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES trackers (id) ON DELETE SET NULL'),
  );
  static const VerificationMeta _fundIdMeta = const VerificationMeta('fundId');
  @override
  late final GeneratedColumn<int> fundId = GeneratedColumn<int>(
    'fund_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES funds (id) ON DELETE SET NULL'),
  );
  static const VerificationMeta _startValueMeta = const VerificationMeta('startValue');
  @override
  late final GeneratedColumn<double> startValue = GeneratedColumn<double>(
    'start_value',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetValueMeta = const VerificationMeta('targetValue');
  @override
  late final GeneratedColumn<double> targetValue = GeneratedColumn<double>(
    'target_value',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minimumValueMeta = const VerificationMeta('minimumValue');
  @override
  late final GeneratedColumn<double> minimumValue = GeneratedColumn<double>(
    'minimum_value',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deadlineMeta = const VerificationMeta('deadline');
  @override
  late final GeneratedColumn<int> deadline = GeneratedColumn<int>(
    'deadline',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startDayMeta = const VerificationMeta('startDay');
  @override
  late final GeneratedColumn<int> startDay = GeneratedColumn<int>(
    'start_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta('archived');
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("archived" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    kind,
    trackerId,
    fundId,
    startValue,
    targetValue,
    minimumValue,
    deadline,
    startDay,
    archived,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goals';
  @override
  VerificationContext validateIntegrity(Insertable<Goal> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('tracker_id')) {
      context.handle(_trackerIdMeta, trackerId.isAcceptableOrUnknown(data['tracker_id']!, _trackerIdMeta));
    }
    if (data.containsKey('fund_id')) {
      context.handle(_fundIdMeta, fundId.isAcceptableOrUnknown(data['fund_id']!, _fundIdMeta));
    }
    if (data.containsKey('start_value')) {
      context.handle(_startValueMeta, startValue.isAcceptableOrUnknown(data['start_value']!, _startValueMeta));
    } else if (isInserting) {
      context.missing(_startValueMeta);
    }
    if (data.containsKey('target_value')) {
      context.handle(_targetValueMeta, targetValue.isAcceptableOrUnknown(data['target_value']!, _targetValueMeta));
    } else if (isInserting) {
      context.missing(_targetValueMeta);
    }
    if (data.containsKey('minimum_value')) {
      context.handle(_minimumValueMeta, minimumValue.isAcceptableOrUnknown(data['minimum_value']!, _minimumValueMeta));
    }
    if (data.containsKey('deadline')) {
      context.handle(_deadlineMeta, deadline.isAcceptableOrUnknown(data['deadline']!, _deadlineMeta));
    }
    if (data.containsKey('start_day')) {
      context.handle(_startDayMeta, startDay.isAcceptableOrUnknown(data['start_day']!, _startDayMeta));
    } else if (isInserting) {
      context.missing(_startDayMeta);
    }
    if (data.containsKey('archived')) {
      context.handle(_archivedMeta, archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta, sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Goal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Goal(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      kind: $GoalsTable.$converterkind.fromSql(attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}kind'])!),
      trackerId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}tracker_id']),
      fundId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}fund_id']),
      startValue: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}start_value'])!,
      targetValue: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}target_value'])!,
      minimumValue: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}minimum_value']),
      deadline: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}deadline']),
      startDay: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}start_day'])!,
      archived: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}archived'])!,
      sortOrder: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
    );
  }

  @override
  $GoalsTable createAlias(String alias) {
    return $GoalsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<GoalKind, int, int> $converterkind = const EnumIndexConverter<GoalKind>(GoalKind.values);
}

class Goal extends DataClass implements Insertable<Goal> {
  final int id;
  final String name;
  final GoalKind kind;
  final int? trackerId;
  final int? fundId;
  final double startValue;
  final double targetValue;

  /// Минимальный результат, который уже можно считать успехом. Необязательно.
  final double? minimumValue;

  /// Желаемый срок (ключ дня), необязательно.
  final int? deadline;
  final int startDay;
  final bool archived;
  final int sortOrder;
  const Goal({
    required this.id,
    required this.name,
    required this.kind,
    this.trackerId,
    this.fundId,
    required this.startValue,
    required this.targetValue,
    this.minimumValue,
    this.deadline,
    required this.startDay,
    required this.archived,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    {
      map['kind'] = Variable<int>($GoalsTable.$converterkind.toSql(kind));
    }
    if (!nullToAbsent || trackerId != null) {
      map['tracker_id'] = Variable<int>(trackerId);
    }
    if (!nullToAbsent || fundId != null) {
      map['fund_id'] = Variable<int>(fundId);
    }
    map['start_value'] = Variable<double>(startValue);
    map['target_value'] = Variable<double>(targetValue);
    if (!nullToAbsent || minimumValue != null) {
      map['minimum_value'] = Variable<double>(minimumValue);
    }
    if (!nullToAbsent || deadline != null) {
      map['deadline'] = Variable<int>(deadline);
    }
    map['start_day'] = Variable<int>(startDay);
    map['archived'] = Variable<bool>(archived);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  GoalsCompanion toCompanion(bool nullToAbsent) {
    return GoalsCompanion(
      id: Value(id),
      name: Value(name),
      kind: Value(kind),
      trackerId: trackerId == null && nullToAbsent ? const Value.absent() : Value(trackerId),
      fundId: fundId == null && nullToAbsent ? const Value.absent() : Value(fundId),
      startValue: Value(startValue),
      targetValue: Value(targetValue),
      minimumValue: minimumValue == null && nullToAbsent ? const Value.absent() : Value(minimumValue),
      deadline: deadline == null && nullToAbsent ? const Value.absent() : Value(deadline),
      startDay: Value(startDay),
      archived: Value(archived),
      sortOrder: Value(sortOrder),
    );
  }

  factory Goal.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Goal(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      kind: $GoalsTable.$converterkind.fromJson(serializer.fromJson<int>(json['kind'])),
      trackerId: serializer.fromJson<int?>(json['trackerId']),
      fundId: serializer.fromJson<int?>(json['fundId']),
      startValue: serializer.fromJson<double>(json['startValue']),
      targetValue: serializer.fromJson<double>(json['targetValue']),
      minimumValue: serializer.fromJson<double?>(json['minimumValue']),
      deadline: serializer.fromJson<int?>(json['deadline']),
      startDay: serializer.fromJson<int>(json['startDay']),
      archived: serializer.fromJson<bool>(json['archived']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<int>($GoalsTable.$converterkind.toJson(kind)),
      'trackerId': serializer.toJson<int?>(trackerId),
      'fundId': serializer.toJson<int?>(fundId),
      'startValue': serializer.toJson<double>(startValue),
      'targetValue': serializer.toJson<double>(targetValue),
      'minimumValue': serializer.toJson<double?>(minimumValue),
      'deadline': serializer.toJson<int?>(deadline),
      'startDay': serializer.toJson<int>(startDay),
      'archived': serializer.toJson<bool>(archived),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  Goal copyWith({
    int? id,
    String? name,
    GoalKind? kind,
    Value<int?> trackerId = const Value.absent(),
    Value<int?> fundId = const Value.absent(),
    double? startValue,
    double? targetValue,
    Value<double?> minimumValue = const Value.absent(),
    Value<int?> deadline = const Value.absent(),
    int? startDay,
    bool? archived,
    int? sortOrder,
  }) => Goal(
    id: id ?? this.id,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    trackerId: trackerId.present ? trackerId.value : this.trackerId,
    fundId: fundId.present ? fundId.value : this.fundId,
    startValue: startValue ?? this.startValue,
    targetValue: targetValue ?? this.targetValue,
    minimumValue: minimumValue.present ? minimumValue.value : this.minimumValue,
    deadline: deadline.present ? deadline.value : this.deadline,
    startDay: startDay ?? this.startDay,
    archived: archived ?? this.archived,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  Goal copyWithCompanion(GoalsCompanion data) {
    return Goal(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      trackerId: data.trackerId.present ? data.trackerId.value : this.trackerId,
      fundId: data.fundId.present ? data.fundId.value : this.fundId,
      startValue: data.startValue.present ? data.startValue.value : this.startValue,
      targetValue: data.targetValue.present ? data.targetValue.value : this.targetValue,
      minimumValue: data.minimumValue.present ? data.minimumValue.value : this.minimumValue,
      deadline: data.deadline.present ? data.deadline.value : this.deadline,
      startDay: data.startDay.present ? data.startDay.value : this.startDay,
      archived: data.archived.present ? data.archived.value : this.archived,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Goal(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('trackerId: $trackerId, ')
          ..write('fundId: $fundId, ')
          ..write('startValue: $startValue, ')
          ..write('targetValue: $targetValue, ')
          ..write('minimumValue: $minimumValue, ')
          ..write('deadline: $deadline, ')
          ..write('startDay: $startDay, ')
          ..write('archived: $archived, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, kind, trackerId, fundId, startValue, targetValue, minimumValue, deadline, startDay, archived, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Goal &&
          other.id == this.id &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.trackerId == this.trackerId &&
          other.fundId == this.fundId &&
          other.startValue == this.startValue &&
          other.targetValue == this.targetValue &&
          other.minimumValue == this.minimumValue &&
          other.deadline == this.deadline &&
          other.startDay == this.startDay &&
          other.archived == this.archived &&
          other.sortOrder == this.sortOrder);
}

class GoalsCompanion extends UpdateCompanion<Goal> {
  final Value<int> id;
  final Value<String> name;
  final Value<GoalKind> kind;
  final Value<int?> trackerId;
  final Value<int?> fundId;
  final Value<double> startValue;
  final Value<double> targetValue;
  final Value<double?> minimumValue;
  final Value<int?> deadline;
  final Value<int> startDay;
  final Value<bool> archived;
  final Value<int> sortOrder;
  const GoalsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.trackerId = const Value.absent(),
    this.fundId = const Value.absent(),
    this.startValue = const Value.absent(),
    this.targetValue = const Value.absent(),
    this.minimumValue = const Value.absent(),
    this.deadline = const Value.absent(),
    this.startDay = const Value.absent(),
    this.archived = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  GoalsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required GoalKind kind,
    this.trackerId = const Value.absent(),
    this.fundId = const Value.absent(),
    required double startValue,
    required double targetValue,
    this.minimumValue = const Value.absent(),
    this.deadline = const Value.absent(),
    required int startDay,
    this.archived = const Value.absent(),
    this.sortOrder = const Value.absent(),
  }) : name = Value(name),
       kind = Value(kind),
       startValue = Value(startValue),
       targetValue = Value(targetValue),
       startDay = Value(startDay);
  static Insertable<Goal> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? kind,
    Expression<int>? trackerId,
    Expression<int>? fundId,
    Expression<double>? startValue,
    Expression<double>? targetValue,
    Expression<double>? minimumValue,
    Expression<int>? deadline,
    Expression<int>? startDay,
    Expression<bool>? archived,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (trackerId != null) 'tracker_id': trackerId,
      if (fundId != null) 'fund_id': fundId,
      if (startValue != null) 'start_value': startValue,
      if (targetValue != null) 'target_value': targetValue,
      if (minimumValue != null) 'minimum_value': minimumValue,
      if (deadline != null) 'deadline': deadline,
      if (startDay != null) 'start_day': startDay,
      if (archived != null) 'archived': archived,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  GoalsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<GoalKind>? kind,
    Value<int?>? trackerId,
    Value<int?>? fundId,
    Value<double>? startValue,
    Value<double>? targetValue,
    Value<double?>? minimumValue,
    Value<int?>? deadline,
    Value<int>? startDay,
    Value<bool>? archived,
    Value<int>? sortOrder,
  }) {
    return GoalsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      trackerId: trackerId ?? this.trackerId,
      fundId: fundId ?? this.fundId,
      startValue: startValue ?? this.startValue,
      targetValue: targetValue ?? this.targetValue,
      minimumValue: minimumValue ?? this.minimumValue,
      deadline: deadline ?? this.deadline,
      startDay: startDay ?? this.startDay,
      archived: archived ?? this.archived,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] = Variable<int>($GoalsTable.$converterkind.toSql(kind.value));
    }
    if (trackerId.present) {
      map['tracker_id'] = Variable<int>(trackerId.value);
    }
    if (fundId.present) {
      map['fund_id'] = Variable<int>(fundId.value);
    }
    if (startValue.present) {
      map['start_value'] = Variable<double>(startValue.value);
    }
    if (targetValue.present) {
      map['target_value'] = Variable<double>(targetValue.value);
    }
    if (minimumValue.present) {
      map['minimum_value'] = Variable<double>(minimumValue.value);
    }
    if (deadline.present) {
      map['deadline'] = Variable<int>(deadline.value);
    }
    if (startDay.present) {
      map['start_day'] = Variable<int>(startDay.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoalsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('trackerId: $trackerId, ')
          ..write('fundId: $fundId, ')
          ..write('startValue: $startValue, ')
          ..write('targetValue: $targetValue, ')
          ..write('minimumValue: $minimumValue, ')
          ..write('deadline: $deadline, ')
          ..write('startDay: $startDay, ')
          ..write('archived: $archived, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('payments'),
  );
  static const VerificationMeta _isIncomeMeta = const VerificationMeta('isIncome');
  @override
  late final GeneratedColumn<bool> isIncome = GeneratedColumn<bool>(
    'is_income',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("is_income" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _monthlyLimitMeta = const VerificationMeta('monthlyLimit');
  @override
  late final GeneratedColumn<double> monthlyLimit = GeneratedColumn<double>(
    'monthly_limit',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta('archived');
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("archived" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, icon, isIncome, monthlyLimit, archived, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(Insertable<Category> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(_iconMeta, icon.isAcceptableOrUnknown(data['icon']!, _iconMeta));
    }
    if (data.containsKey('is_income')) {
      context.handle(_isIncomeMeta, isIncome.isAcceptableOrUnknown(data['is_income']!, _isIncomeMeta));
    }
    if (data.containsKey('monthly_limit')) {
      context.handle(_monthlyLimitMeta, monthlyLimit.isAcceptableOrUnknown(data['monthly_limit']!, _monthlyLimitMeta));
    }
    if (data.containsKey('archived')) {
      context.handle(_archivedMeta, archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta, sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      icon: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}icon'])!,
      isIncome: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}is_income'])!,
      monthlyLimit: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}monthly_limit']),
      archived: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}archived'])!,
      sortOrder: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class Category extends DataClass implements Insertable<Category> {
  final int id;
  final String name;
  final String icon;
  final bool isIncome;

  /// Лимит на месяц, необязательно.
  final double? monthlyLimit;
  final bool archived;
  final int sortOrder;
  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.isIncome,
    this.monthlyLimit,
    required this.archived,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['icon'] = Variable<String>(icon);
    map['is_income'] = Variable<bool>(isIncome);
    if (!nullToAbsent || monthlyLimit != null) {
      map['monthly_limit'] = Variable<double>(monthlyLimit);
    }
    map['archived'] = Variable<bool>(archived);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      icon: Value(icon),
      isIncome: Value(isIncome),
      monthlyLimit: monthlyLimit == null && nullToAbsent ? const Value.absent() : Value(monthlyLimit),
      archived: Value(archived),
      sortOrder: Value(sortOrder),
    );
  }

  factory Category.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      icon: serializer.fromJson<String>(json['icon']),
      isIncome: serializer.fromJson<bool>(json['isIncome']),
      monthlyLimit: serializer.fromJson<double?>(json['monthlyLimit']),
      archived: serializer.fromJson<bool>(json['archived']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'icon': serializer.toJson<String>(icon),
      'isIncome': serializer.toJson<bool>(isIncome),
      'monthlyLimit': serializer.toJson<double?>(monthlyLimit),
      'archived': serializer.toJson<bool>(archived),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  Category copyWith({
    int? id,
    String? name,
    String? icon,
    bool? isIncome,
    Value<double?> monthlyLimit = const Value.absent(),
    bool? archived,
    int? sortOrder,
  }) => Category(
    id: id ?? this.id,
    name: name ?? this.name,
    icon: icon ?? this.icon,
    isIncome: isIncome ?? this.isIncome,
    monthlyLimit: monthlyLimit.present ? monthlyLimit.value : this.monthlyLimit,
    archived: archived ?? this.archived,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      icon: data.icon.present ? data.icon.value : this.icon,
      isIncome: data.isIncome.present ? data.isIncome.value : this.isIncome,
      monthlyLimit: data.monthlyLimit.present ? data.monthlyLimit.value : this.monthlyLimit,
      archived: data.archived.present ? data.archived.value : this.archived,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('isIncome: $isIncome, ')
          ..write('monthlyLimit: $monthlyLimit, ')
          ..write('archived: $archived, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, icon, isIncome, monthlyLimit, archived, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.id == this.id &&
          other.name == this.name &&
          other.icon == this.icon &&
          other.isIncome == this.isIncome &&
          other.monthlyLimit == this.monthlyLimit &&
          other.archived == this.archived &&
          other.sortOrder == this.sortOrder);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> icon;
  final Value<bool> isIncome;
  final Value<double?> monthlyLimit;
  final Value<bool> archived;
  final Value<int> sortOrder;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.icon = const Value.absent(),
    this.isIncome = const Value.absent(),
    this.monthlyLimit = const Value.absent(),
    this.archived = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  CategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.icon = const Value.absent(),
    this.isIncome = const Value.absent(),
    this.monthlyLimit = const Value.absent(),
    this.archived = const Value.absent(),
    this.sortOrder = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Category> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? icon,
    Expression<bool>? isIncome,
    Expression<double>? monthlyLimit,
    Expression<bool>? archived,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (icon != null) 'icon': icon,
      if (isIncome != null) 'is_income': isIncome,
      if (monthlyLimit != null) 'monthly_limit': monthlyLimit,
      if (archived != null) 'archived': archived,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  CategoriesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? icon,
    Value<bool>? isIncome,
    Value<double?>? monthlyLimit,
    Value<bool>? archived,
    Value<int>? sortOrder,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      isIncome: isIncome ?? this.isIncome,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      archived: archived ?? this.archived,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (isIncome.present) {
      map['is_income'] = Variable<bool>(isIncome.value);
    }
    if (monthlyLimit.present) {
      map['monthly_limit'] = Variable<double>(monthlyLimit.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('isIncome: $isIncome, ')
          ..write('monthlyLimit: $monthlyLimit, ')
          ..write('archived: $archived, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions with TableInfo<$TransactionsTable, Transaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isIncomeMeta = const VerificationMeta('isIncome');
  @override
  late final GeneratedColumn<bool> isIncome = GeneratedColumn<bool>(
    'is_income',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("is_income" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES categories (id) ON DELETE SET NULL'),
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<int> day = GeneratedColumn<int>('day', aliasedName, false, type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, amount, isIncome, categoryId, day, at, note];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(Insertable<Transaction> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta, amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('is_income')) {
      context.handle(_isIncomeMeta, isIncome.isAcceptableOrUnknown(data['is_income']!, _isIncomeMeta));
    }
    if (data.containsKey('category_id')) {
      context.handle(_categoryIdMeta, categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta));
    }
    if (data.containsKey('day')) {
      context.handle(_dayMeta, day.isAcceptableOrUnknown(data['day']!, _dayMeta));
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    }
    if (data.containsKey('note')) {
      context.handle(_noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Transaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Transaction(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      amount: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      isIncome: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}is_income'])!,
      categoryId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}category_id']),
      day: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}day'])!,
      at: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}at'])!,
      note: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}note']),
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }
}

class Transaction extends DataClass implements Insertable<Transaction> {
  final int id;
  final double amount;
  final bool isIncome;
  final int? categoryId;
  final int day;
  final DateTime at;
  final String? note;
  const Transaction({
    required this.id,
    required this.amount,
    required this.isIncome,
    this.categoryId,
    required this.day,
    required this.at,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['amount'] = Variable<double>(amount);
    map['is_income'] = Variable<bool>(isIncome);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    map['day'] = Variable<int>(day);
    map['at'] = Variable<DateTime>(at);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      amount: Value(amount),
      isIncome: Value(isIncome),
      categoryId: categoryId == null && nullToAbsent ? const Value.absent() : Value(categoryId),
      day: Value(day),
      at: Value(at),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory Transaction.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Transaction(
      id: serializer.fromJson<int>(json['id']),
      amount: serializer.fromJson<double>(json['amount']),
      isIncome: serializer.fromJson<bool>(json['isIncome']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
      day: serializer.fromJson<int>(json['day']),
      at: serializer.fromJson<DateTime>(json['at']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'amount': serializer.toJson<double>(amount),
      'isIncome': serializer.toJson<bool>(isIncome),
      'categoryId': serializer.toJson<int?>(categoryId),
      'day': serializer.toJson<int>(day),
      'at': serializer.toJson<DateTime>(at),
      'note': serializer.toJson<String?>(note),
    };
  }

  Transaction copyWith({
    int? id,
    double? amount,
    bool? isIncome,
    Value<int?> categoryId = const Value.absent(),
    int? day,
    DateTime? at,
    Value<String?> note = const Value.absent(),
  }) => Transaction(
    id: id ?? this.id,
    amount: amount ?? this.amount,
    isIncome: isIncome ?? this.isIncome,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    day: day ?? this.day,
    at: at ?? this.at,
    note: note.present ? note.value : this.note,
  );
  Transaction copyWithCompanion(TransactionsCompanion data) {
    return Transaction(
      id: data.id.present ? data.id.value : this.id,
      amount: data.amount.present ? data.amount.value : this.amount,
      isIncome: data.isIncome.present ? data.isIncome.value : this.isIncome,
      categoryId: data.categoryId.present ? data.categoryId.value : this.categoryId,
      day: data.day.present ? data.day.value : this.day,
      at: data.at.present ? data.at.value : this.at,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Transaction(')
          ..write('id: $id, ')
          ..write('amount: $amount, ')
          ..write('isIncome: $isIncome, ')
          ..write('categoryId: $categoryId, ')
          ..write('day: $day, ')
          ..write('at: $at, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, amount, isIncome, categoryId, day, at, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Transaction &&
          other.id == this.id &&
          other.amount == this.amount &&
          other.isIncome == this.isIncome &&
          other.categoryId == this.categoryId &&
          other.day == this.day &&
          other.at == this.at &&
          other.note == this.note);
}

class TransactionsCompanion extends UpdateCompanion<Transaction> {
  final Value<int> id;
  final Value<double> amount;
  final Value<bool> isIncome;
  final Value<int?> categoryId;
  final Value<int> day;
  final Value<DateTime> at;
  final Value<String?> note;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.amount = const Value.absent(),
    this.isIncome = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.day = const Value.absent(),
    this.at = const Value.absent(),
    this.note = const Value.absent(),
  });
  TransactionsCompanion.insert({
    this.id = const Value.absent(),
    required double amount,
    this.isIncome = const Value.absent(),
    this.categoryId = const Value.absent(),
    required int day,
    this.at = const Value.absent(),
    this.note = const Value.absent(),
  }) : amount = Value(amount),
       day = Value(day);
  static Insertable<Transaction> custom({
    Expression<int>? id,
    Expression<double>? amount,
    Expression<bool>? isIncome,
    Expression<int>? categoryId,
    Expression<int>? day,
    Expression<DateTime>? at,
    Expression<String>? note,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (amount != null) 'amount': amount,
      if (isIncome != null) 'is_income': isIncome,
      if (categoryId != null) 'category_id': categoryId,
      if (day != null) 'day': day,
      if (at != null) 'at': at,
      if (note != null) 'note': note,
    });
  }

  TransactionsCompanion copyWith({
    Value<int>? id,
    Value<double>? amount,
    Value<bool>? isIncome,
    Value<int?>? categoryId,
    Value<int>? day,
    Value<DateTime>? at,
    Value<String?>? note,
  }) {
    return TransactionsCompanion(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      isIncome: isIncome ?? this.isIncome,
      categoryId: categoryId ?? this.categoryId,
      day: day ?? this.day,
      at: at ?? this.at,
      note: note ?? this.note,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (isIncome.present) {
      map['is_income'] = Variable<bool>(isIncome.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (day.present) {
      map['day'] = Variable<int>(day.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('amount: $amount, ')
          ..write('isIncome: $isIncome, ')
          ..write('categoryId: $categoryId, ')
          ..write('day: $day, ')
          ..write('at: $at, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }
}

class $FundMovesTable extends FundMoves with TableInfo<$FundMovesTable, FundMove> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FundMovesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _fundIdMeta = const VerificationMeta('fundId');
  @override
  late final GeneratedColumn<int> fundId = GeneratedColumn<int>(
    'fund_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES funds (id) ON DELETE CASCADE'),
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<int> day = GeneratedColumn<int>('day', aliasedName, false, type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, fundId, amount, day, note];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fund_moves';
  @override
  VerificationContext validateIntegrity(Insertable<FundMove> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('fund_id')) {
      context.handle(_fundIdMeta, fundId.isAcceptableOrUnknown(data['fund_id']!, _fundIdMeta));
    } else if (isInserting) {
      context.missing(_fundIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta, amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('day')) {
      context.handle(_dayMeta, day.isAcceptableOrUnknown(data['day']!, _dayMeta));
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('note')) {
      context.handle(_noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FundMove map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FundMove(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      fundId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}fund_id'])!,
      amount: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      day: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}day'])!,
      note: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}note']),
    );
  }

  @override
  $FundMovesTable createAlias(String alias) {
    return $FundMovesTable(attachedDatabase, alias);
  }
}

class FundMove extends DataClass implements Insertable<FundMove> {
  final int id;
  final int fundId;
  final double amount;
  final int day;
  final String? note;
  const FundMove({required this.id, required this.fundId, required this.amount, required this.day, this.note});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['fund_id'] = Variable<int>(fundId);
    map['amount'] = Variable<double>(amount);
    map['day'] = Variable<int>(day);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  FundMovesCompanion toCompanion(bool nullToAbsent) {
    return FundMovesCompanion(
      id: Value(id),
      fundId: Value(fundId),
      amount: Value(amount),
      day: Value(day),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory FundMove.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FundMove(
      id: serializer.fromJson<int>(json['id']),
      fundId: serializer.fromJson<int>(json['fundId']),
      amount: serializer.fromJson<double>(json['amount']),
      day: serializer.fromJson<int>(json['day']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'fundId': serializer.toJson<int>(fundId),
      'amount': serializer.toJson<double>(amount),
      'day': serializer.toJson<int>(day),
      'note': serializer.toJson<String?>(note),
    };
  }

  FundMove copyWith({int? id, int? fundId, double? amount, int? day, Value<String?> note = const Value.absent()}) => FundMove(
    id: id ?? this.id,
    fundId: fundId ?? this.fundId,
    amount: amount ?? this.amount,
    day: day ?? this.day,
    note: note.present ? note.value : this.note,
  );
  FundMove copyWithCompanion(FundMovesCompanion data) {
    return FundMove(
      id: data.id.present ? data.id.value : this.id,
      fundId: data.fundId.present ? data.fundId.value : this.fundId,
      amount: data.amount.present ? data.amount.value : this.amount,
      day: data.day.present ? data.day.value : this.day,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FundMove(')
          ..write('id: $id, ')
          ..write('fundId: $fundId, ')
          ..write('amount: $amount, ')
          ..write('day: $day, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, fundId, amount, day, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FundMove &&
          other.id == this.id &&
          other.fundId == this.fundId &&
          other.amount == this.amount &&
          other.day == this.day &&
          other.note == this.note);
}

class FundMovesCompanion extends UpdateCompanion<FundMove> {
  final Value<int> id;
  final Value<int> fundId;
  final Value<double> amount;
  final Value<int> day;
  final Value<String?> note;
  const FundMovesCompanion({
    this.id = const Value.absent(),
    this.fundId = const Value.absent(),
    this.amount = const Value.absent(),
    this.day = const Value.absent(),
    this.note = const Value.absent(),
  });
  FundMovesCompanion.insert({
    this.id = const Value.absent(),
    required int fundId,
    required double amount,
    required int day,
    this.note = const Value.absent(),
  }) : fundId = Value(fundId),
       amount = Value(amount),
       day = Value(day);
  static Insertable<FundMove> custom({
    Expression<int>? id,
    Expression<int>? fundId,
    Expression<double>? amount,
    Expression<int>? day,
    Expression<String>? note,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fundId != null) 'fund_id': fundId,
      if (amount != null) 'amount': amount,
      if (day != null) 'day': day,
      if (note != null) 'note': note,
    });
  }

  FundMovesCompanion copyWith({Value<int>? id, Value<int>? fundId, Value<double>? amount, Value<int>? day, Value<String?>? note}) {
    return FundMovesCompanion(
      id: id ?? this.id,
      fundId: fundId ?? this.fundId,
      amount: amount ?? this.amount,
      day: day ?? this.day,
      note: note ?? this.note,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (fundId.present) {
      map['fund_id'] = Variable<int>(fundId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (day.present) {
      map['day'] = Variable<int>(day.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FundMovesCompanion(')
          ..write('id: $id, ')
          ..write('fundId: $fundId, ')
          ..write('amount: $amount, ')
          ..write('day: $day, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }
}

class $ProgramsTable extends Programs with TableInfo<$ProgramsTable, Program> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProgramsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _daysMaskMeta = const VerificationMeta('daysMask');
  @override
  late final GeneratedColumn<int> daysMask = GeneratedColumn<int>(
    'days_mask',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _reminderMinutesMeta = const VerificationMeta('reminderMinutes');
  @override
  late final GeneratedColumn<int> reminderMinutes = GeneratedColumn<int>(
    'reminder_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _minSetsMeta = const VerificationMeta('minSets');
  @override
  late final GeneratedColumn<int> minSets = GeneratedColumn<int>(
    'min_sets',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _minimumTextMeta = const VerificationMeta('minimumText');
  @override
  late final GeneratedColumn<String> minimumText = GeneratedColumn<String>(
    'minimum_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta('archived');
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("archived" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, daysMask, reminderMinutes, note, minSets, minimumText, archived, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'programs';
  @override
  VerificationContext validateIntegrity(Insertable<Program> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('days_mask')) {
      context.handle(_daysMaskMeta, daysMask.isAcceptableOrUnknown(data['days_mask']!, _daysMaskMeta));
    }
    if (data.containsKey('reminder_minutes')) {
      context.handle(_reminderMinutesMeta, reminderMinutes.isAcceptableOrUnknown(data['reminder_minutes']!, _reminderMinutesMeta));
    }
    if (data.containsKey('note')) {
      context.handle(_noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('min_sets')) {
      context.handle(_minSetsMeta, minSets.isAcceptableOrUnknown(data['min_sets']!, _minSetsMeta));
    }
    if (data.containsKey('minimum_text')) {
      context.handle(_minimumTextMeta, minimumText.isAcceptableOrUnknown(data['minimum_text']!, _minimumTextMeta));
    }
    if (data.containsKey('archived')) {
      context.handle(_archivedMeta, archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta, sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Program map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Program(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      daysMask: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}days_mask'])!,
      reminderMinutes: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}reminder_minutes']),
      note: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}note']),
      minSets: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}min_sets']),
      minimumText: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}minimum_text']),
      archived: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}archived'])!,
      sortOrder: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
    );
  }

  @override
  $ProgramsTable createAlias(String alias) {
    return $ProgramsTable(attachedDatabase, alias);
  }
}

class Program extends DataClass implements Insertable<Program> {
  final int id;
  final String name;
  final int daysMask;
  final int? reminderMinutes;
  final String? note;

  /// Минимум на тяжёлый день: сколько подходов на упражнение и что ещё сделать.
  final int? minSets;
  final String? minimumText;
  final bool archived;
  final int sortOrder;
  const Program({
    required this.id,
    required this.name,
    required this.daysMask,
    this.reminderMinutes,
    this.note,
    this.minSets,
    this.minimumText,
    required this.archived,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['days_mask'] = Variable<int>(daysMask);
    if (!nullToAbsent || reminderMinutes != null) {
      map['reminder_minutes'] = Variable<int>(reminderMinutes);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || minSets != null) {
      map['min_sets'] = Variable<int>(minSets);
    }
    if (!nullToAbsent || minimumText != null) {
      map['minimum_text'] = Variable<String>(minimumText);
    }
    map['archived'] = Variable<bool>(archived);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  ProgramsCompanion toCompanion(bool nullToAbsent) {
    return ProgramsCompanion(
      id: Value(id),
      name: Value(name),
      daysMask: Value(daysMask),
      reminderMinutes: reminderMinutes == null && nullToAbsent ? const Value.absent() : Value(reminderMinutes),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      minSets: minSets == null && nullToAbsent ? const Value.absent() : Value(minSets),
      minimumText: minimumText == null && nullToAbsent ? const Value.absent() : Value(minimumText),
      archived: Value(archived),
      sortOrder: Value(sortOrder),
    );
  }

  factory Program.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Program(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      daysMask: serializer.fromJson<int>(json['daysMask']),
      reminderMinutes: serializer.fromJson<int?>(json['reminderMinutes']),
      note: serializer.fromJson<String?>(json['note']),
      minSets: serializer.fromJson<int?>(json['minSets']),
      minimumText: serializer.fromJson<String?>(json['minimumText']),
      archived: serializer.fromJson<bool>(json['archived']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'daysMask': serializer.toJson<int>(daysMask),
      'reminderMinutes': serializer.toJson<int?>(reminderMinutes),
      'note': serializer.toJson<String?>(note),
      'minSets': serializer.toJson<int?>(minSets),
      'minimumText': serializer.toJson<String?>(minimumText),
      'archived': serializer.toJson<bool>(archived),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  Program copyWith({
    int? id,
    String? name,
    int? daysMask,
    Value<int?> reminderMinutes = const Value.absent(),
    Value<String?> note = const Value.absent(),
    Value<int?> minSets = const Value.absent(),
    Value<String?> minimumText = const Value.absent(),
    bool? archived,
    int? sortOrder,
  }) => Program(
    id: id ?? this.id,
    name: name ?? this.name,
    daysMask: daysMask ?? this.daysMask,
    reminderMinutes: reminderMinutes.present ? reminderMinutes.value : this.reminderMinutes,
    note: note.present ? note.value : this.note,
    minSets: minSets.present ? minSets.value : this.minSets,
    minimumText: minimumText.present ? minimumText.value : this.minimumText,
    archived: archived ?? this.archived,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  Program copyWithCompanion(ProgramsCompanion data) {
    return Program(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      daysMask: data.daysMask.present ? data.daysMask.value : this.daysMask,
      reminderMinutes: data.reminderMinutes.present ? data.reminderMinutes.value : this.reminderMinutes,
      note: data.note.present ? data.note.value : this.note,
      minSets: data.minSets.present ? data.minSets.value : this.minSets,
      minimumText: data.minimumText.present ? data.minimumText.value : this.minimumText,
      archived: data.archived.present ? data.archived.value : this.archived,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Program(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('daysMask: $daysMask, ')
          ..write('reminderMinutes: $reminderMinutes, ')
          ..write('note: $note, ')
          ..write('minSets: $minSets, ')
          ..write('minimumText: $minimumText, ')
          ..write('archived: $archived, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, daysMask, reminderMinutes, note, minSets, minimumText, archived, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Program &&
          other.id == this.id &&
          other.name == this.name &&
          other.daysMask == this.daysMask &&
          other.reminderMinutes == this.reminderMinutes &&
          other.note == this.note &&
          other.minSets == this.minSets &&
          other.minimumText == this.minimumText &&
          other.archived == this.archived &&
          other.sortOrder == this.sortOrder);
}

class ProgramsCompanion extends UpdateCompanion<Program> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> daysMask;
  final Value<int?> reminderMinutes;
  final Value<String?> note;
  final Value<int?> minSets;
  final Value<String?> minimumText;
  final Value<bool> archived;
  final Value<int> sortOrder;
  const ProgramsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.daysMask = const Value.absent(),
    this.reminderMinutes = const Value.absent(),
    this.note = const Value.absent(),
    this.minSets = const Value.absent(),
    this.minimumText = const Value.absent(),
    this.archived = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  ProgramsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.daysMask = const Value.absent(),
    this.reminderMinutes = const Value.absent(),
    this.note = const Value.absent(),
    this.minSets = const Value.absent(),
    this.minimumText = const Value.absent(),
    this.archived = const Value.absent(),
    this.sortOrder = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Program> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? daysMask,
    Expression<int>? reminderMinutes,
    Expression<String>? note,
    Expression<int>? minSets,
    Expression<String>? minimumText,
    Expression<bool>? archived,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (daysMask != null) 'days_mask': daysMask,
      if (reminderMinutes != null) 'reminder_minutes': reminderMinutes,
      if (note != null) 'note': note,
      if (minSets != null) 'min_sets': minSets,
      if (minimumText != null) 'minimum_text': minimumText,
      if (archived != null) 'archived': archived,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  ProgramsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? daysMask,
    Value<int?>? reminderMinutes,
    Value<String?>? note,
    Value<int?>? minSets,
    Value<String?>? minimumText,
    Value<bool>? archived,
    Value<int>? sortOrder,
  }) {
    return ProgramsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      daysMask: daysMask ?? this.daysMask,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      note: note ?? this.note,
      minSets: minSets ?? this.minSets,
      minimumText: minimumText ?? this.minimumText,
      archived: archived ?? this.archived,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (daysMask.present) {
      map['days_mask'] = Variable<int>(daysMask.value);
    }
    if (reminderMinutes.present) {
      map['reminder_minutes'] = Variable<int>(reminderMinutes.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (minSets.present) {
      map['min_sets'] = Variable<int>(minSets.value);
    }
    if (minimumText.present) {
      map['minimum_text'] = Variable<String>(minimumText.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProgramsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('daysMask: $daysMask, ')
          ..write('reminderMinutes: $reminderMinutes, ')
          ..write('note: $note, ')
          ..write('minSets: $minSets, ')
          ..write('minimumText: $minimumText, ')
          ..write('archived: $archived, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $ProgramExercisesTable extends ProgramExercises with TableInfo<$ProgramExercisesTable, ProgramExercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProgramExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _programIdMeta = const VerificationMeta('programId');
  @override
  late final GeneratedColumn<int> programId = GeneratedColumn<int>(
    'program_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES programs (id) ON DELETE CASCADE'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _setsMeta = const VerificationMeta('sets');
  @override
  late final GeneratedColumn<int> sets = GeneratedColumn<int>(
    'sets',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(3),
  );
  static const VerificationMeta _repsMinMeta = const VerificationMeta('repsMin');
  @override
  late final GeneratedColumn<int> repsMin = GeneratedColumn<int>(
    'reps_min',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(8),
  );
  static const VerificationMeta _repsMaxMeta = const VerificationMeta('repsMax');
  @override
  late final GeneratedColumn<int> repsMax = GeneratedColumn<int>(
    'reps_max',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(12),
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('повт'),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, programId, name, sets, repsMin, repsMax, unit, note, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'program_exercises';
  @override
  VerificationContext validateIntegrity(Insertable<ProgramExercise> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('program_id')) {
      context.handle(_programIdMeta, programId.isAcceptableOrUnknown(data['program_id']!, _programIdMeta));
    } else if (isInserting) {
      context.missing(_programIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sets')) {
      context.handle(_setsMeta, sets.isAcceptableOrUnknown(data['sets']!, _setsMeta));
    }
    if (data.containsKey('reps_min')) {
      context.handle(_repsMinMeta, repsMin.isAcceptableOrUnknown(data['reps_min']!, _repsMinMeta));
    }
    if (data.containsKey('reps_max')) {
      context.handle(_repsMaxMeta, repsMax.isAcceptableOrUnknown(data['reps_max']!, _repsMaxMeta));
    }
    if (data.containsKey('unit')) {
      context.handle(_unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    }
    if (data.containsKey('note')) {
      context.handle(_noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta, sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProgramExercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProgramExercise(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      programId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}program_id'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      sets: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}sets'])!,
      repsMin: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}reps_min'])!,
      repsMax: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}reps_max'])!,
      unit: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}unit'])!,
      note: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}note']),
      sortOrder: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
    );
  }

  @override
  $ProgramExercisesTable createAlias(String alias) {
    return $ProgramExercisesTable(attachedDatabase, alias);
  }
}

class ProgramExercise extends DataClass implements Insertable<ProgramExercise> {
  final int id;
  final int programId;
  final String name;
  final int sets;
  final int repsMin;
  final int repsMax;

  /// «повт» или «сек».
  final String unit;
  final String? note;
  final int sortOrder;
  const ProgramExercise({
    required this.id,
    required this.programId,
    required this.name,
    required this.sets,
    required this.repsMin,
    required this.repsMax,
    required this.unit,
    this.note,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['program_id'] = Variable<int>(programId);
    map['name'] = Variable<String>(name);
    map['sets'] = Variable<int>(sets);
    map['reps_min'] = Variable<int>(repsMin);
    map['reps_max'] = Variable<int>(repsMax);
    map['unit'] = Variable<String>(unit);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  ProgramExercisesCompanion toCompanion(bool nullToAbsent) {
    return ProgramExercisesCompanion(
      id: Value(id),
      programId: Value(programId),
      name: Value(name),
      sets: Value(sets),
      repsMin: Value(repsMin),
      repsMax: Value(repsMax),
      unit: Value(unit),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      sortOrder: Value(sortOrder),
    );
  }

  factory ProgramExercise.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProgramExercise(
      id: serializer.fromJson<int>(json['id']),
      programId: serializer.fromJson<int>(json['programId']),
      name: serializer.fromJson<String>(json['name']),
      sets: serializer.fromJson<int>(json['sets']),
      repsMin: serializer.fromJson<int>(json['repsMin']),
      repsMax: serializer.fromJson<int>(json['repsMax']),
      unit: serializer.fromJson<String>(json['unit']),
      note: serializer.fromJson<String?>(json['note']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'programId': serializer.toJson<int>(programId),
      'name': serializer.toJson<String>(name),
      'sets': serializer.toJson<int>(sets),
      'repsMin': serializer.toJson<int>(repsMin),
      'repsMax': serializer.toJson<int>(repsMax),
      'unit': serializer.toJson<String>(unit),
      'note': serializer.toJson<String?>(note),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  ProgramExercise copyWith({
    int? id,
    int? programId,
    String? name,
    int? sets,
    int? repsMin,
    int? repsMax,
    String? unit,
    Value<String?> note = const Value.absent(),
    int? sortOrder,
  }) => ProgramExercise(
    id: id ?? this.id,
    programId: programId ?? this.programId,
    name: name ?? this.name,
    sets: sets ?? this.sets,
    repsMin: repsMin ?? this.repsMin,
    repsMax: repsMax ?? this.repsMax,
    unit: unit ?? this.unit,
    note: note.present ? note.value : this.note,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  ProgramExercise copyWithCompanion(ProgramExercisesCompanion data) {
    return ProgramExercise(
      id: data.id.present ? data.id.value : this.id,
      programId: data.programId.present ? data.programId.value : this.programId,
      name: data.name.present ? data.name.value : this.name,
      sets: data.sets.present ? data.sets.value : this.sets,
      repsMin: data.repsMin.present ? data.repsMin.value : this.repsMin,
      repsMax: data.repsMax.present ? data.repsMax.value : this.repsMax,
      unit: data.unit.present ? data.unit.value : this.unit,
      note: data.note.present ? data.note.value : this.note,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProgramExercise(')
          ..write('id: $id, ')
          ..write('programId: $programId, ')
          ..write('name: $name, ')
          ..write('sets: $sets, ')
          ..write('repsMin: $repsMin, ')
          ..write('repsMax: $repsMax, ')
          ..write('unit: $unit, ')
          ..write('note: $note, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, programId, name, sets, repsMin, repsMax, unit, note, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProgramExercise &&
          other.id == this.id &&
          other.programId == this.programId &&
          other.name == this.name &&
          other.sets == this.sets &&
          other.repsMin == this.repsMin &&
          other.repsMax == this.repsMax &&
          other.unit == this.unit &&
          other.note == this.note &&
          other.sortOrder == this.sortOrder);
}

class ProgramExercisesCompanion extends UpdateCompanion<ProgramExercise> {
  final Value<int> id;
  final Value<int> programId;
  final Value<String> name;
  final Value<int> sets;
  final Value<int> repsMin;
  final Value<int> repsMax;
  final Value<String> unit;
  final Value<String?> note;
  final Value<int> sortOrder;
  const ProgramExercisesCompanion({
    this.id = const Value.absent(),
    this.programId = const Value.absent(),
    this.name = const Value.absent(),
    this.sets = const Value.absent(),
    this.repsMin = const Value.absent(),
    this.repsMax = const Value.absent(),
    this.unit = const Value.absent(),
    this.note = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  ProgramExercisesCompanion.insert({
    this.id = const Value.absent(),
    required int programId,
    required String name,
    this.sets = const Value.absent(),
    this.repsMin = const Value.absent(),
    this.repsMax = const Value.absent(),
    this.unit = const Value.absent(),
    this.note = const Value.absent(),
    this.sortOrder = const Value.absent(),
  }) : programId = Value(programId),
       name = Value(name);
  static Insertable<ProgramExercise> custom({
    Expression<int>? id,
    Expression<int>? programId,
    Expression<String>? name,
    Expression<int>? sets,
    Expression<int>? repsMin,
    Expression<int>? repsMax,
    Expression<String>? unit,
    Expression<String>? note,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (programId != null) 'program_id': programId,
      if (name != null) 'name': name,
      if (sets != null) 'sets': sets,
      if (repsMin != null) 'reps_min': repsMin,
      if (repsMax != null) 'reps_max': repsMax,
      if (unit != null) 'unit': unit,
      if (note != null) 'note': note,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  ProgramExercisesCompanion copyWith({
    Value<int>? id,
    Value<int>? programId,
    Value<String>? name,
    Value<int>? sets,
    Value<int>? repsMin,
    Value<int>? repsMax,
    Value<String>? unit,
    Value<String?>? note,
    Value<int>? sortOrder,
  }) {
    return ProgramExercisesCompanion(
      id: id ?? this.id,
      programId: programId ?? this.programId,
      name: name ?? this.name,
      sets: sets ?? this.sets,
      repsMin: repsMin ?? this.repsMin,
      repsMax: repsMax ?? this.repsMax,
      unit: unit ?? this.unit,
      note: note ?? this.note,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (programId.present) {
      map['program_id'] = Variable<int>(programId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sets.present) {
      map['sets'] = Variable<int>(sets.value);
    }
    if (repsMin.present) {
      map['reps_min'] = Variable<int>(repsMin.value);
    }
    if (repsMax.present) {
      map['reps_max'] = Variable<int>(repsMax.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProgramExercisesCompanion(')
          ..write('id: $id, ')
          ..write('programId: $programId, ')
          ..write('name: $name, ')
          ..write('sets: $sets, ')
          ..write('repsMin: $repsMin, ')
          ..write('repsMax: $repsMax, ')
          ..write('unit: $unit, ')
          ..write('note: $note, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $WorkoutSessionsTable extends WorkoutSessions with TableInfo<$WorkoutSessionsTable, WorkoutSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _programIdMeta = const VerificationMeta('programId');
  @override
  late final GeneratedColumn<int> programId = GeneratedColumn<int>(
    'program_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES programs (id) ON DELETE SET NULL'),
  );
  static const VerificationMeta _programNameMeta = const VerificationMeta('programName');
  @override
  late final GeneratedColumn<String> programName = GeneratedColumn<String>(
    'program_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<int> day = GeneratedColumn<int>('day', aliasedName, false, type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _minimumMeta = const VerificationMeta('minimum');
  @override
  late final GeneratedColumn<bool> minimum = GeneratedColumn<bool>(
    'minimum',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("minimum" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [id, programId, programName, day, at, note, minimum];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_sessions';
  @override
  VerificationContext validateIntegrity(Insertable<WorkoutSession> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('program_id')) {
      context.handle(_programIdMeta, programId.isAcceptableOrUnknown(data['program_id']!, _programIdMeta));
    }
    if (data.containsKey('program_name')) {
      context.handle(_programNameMeta, programName.isAcceptableOrUnknown(data['program_name']!, _programNameMeta));
    } else if (isInserting) {
      context.missing(_programNameMeta);
    }
    if (data.containsKey('day')) {
      context.handle(_dayMeta, day.isAcceptableOrUnknown(data['day']!, _dayMeta));
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    }
    if (data.containsKey('note')) {
      context.handle(_noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('minimum')) {
      context.handle(_minimumMeta, minimum.isAcceptableOrUnknown(data['minimum']!, _minimumMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutSession(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      programId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}program_id']),
      programName: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}program_name'])!,
      day: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}day'])!,
      at: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}at'])!,
      note: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}note']),
      minimum: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}minimum'])!,
    );
  }

  @override
  $WorkoutSessionsTable createAlias(String alias) {
    return $WorkoutSessionsTable(attachedDatabase, alias);
  }
}

class WorkoutSession extends DataClass implements Insertable<WorkoutSession> {
  final int id;
  final int? programId;
  final String programName;
  final int day;
  final DateTime at;
  final String? note;

  /// Сделано меньше плана: облегчённая тренировка.
  final bool minimum;
  const WorkoutSession({
    required this.id,
    this.programId,
    required this.programName,
    required this.day,
    required this.at,
    this.note,
    required this.minimum,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || programId != null) {
      map['program_id'] = Variable<int>(programId);
    }
    map['program_name'] = Variable<String>(programName);
    map['day'] = Variable<int>(day);
    map['at'] = Variable<DateTime>(at);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['minimum'] = Variable<bool>(minimum);
    return map;
  }

  WorkoutSessionsCompanion toCompanion(bool nullToAbsent) {
    return WorkoutSessionsCompanion(
      id: Value(id),
      programId: programId == null && nullToAbsent ? const Value.absent() : Value(programId),
      programName: Value(programName),
      day: Value(day),
      at: Value(at),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      minimum: Value(minimum),
    );
  }

  factory WorkoutSession.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutSession(
      id: serializer.fromJson<int>(json['id']),
      programId: serializer.fromJson<int?>(json['programId']),
      programName: serializer.fromJson<String>(json['programName']),
      day: serializer.fromJson<int>(json['day']),
      at: serializer.fromJson<DateTime>(json['at']),
      note: serializer.fromJson<String?>(json['note']),
      minimum: serializer.fromJson<bool>(json['minimum']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'programId': serializer.toJson<int?>(programId),
      'programName': serializer.toJson<String>(programName),
      'day': serializer.toJson<int>(day),
      'at': serializer.toJson<DateTime>(at),
      'note': serializer.toJson<String?>(note),
      'minimum': serializer.toJson<bool>(minimum),
    };
  }

  WorkoutSession copyWith({
    int? id,
    Value<int?> programId = const Value.absent(),
    String? programName,
    int? day,
    DateTime? at,
    Value<String?> note = const Value.absent(),
    bool? minimum,
  }) => WorkoutSession(
    id: id ?? this.id,
    programId: programId.present ? programId.value : this.programId,
    programName: programName ?? this.programName,
    day: day ?? this.day,
    at: at ?? this.at,
    note: note.present ? note.value : this.note,
    minimum: minimum ?? this.minimum,
  );
  WorkoutSession copyWithCompanion(WorkoutSessionsCompanion data) {
    return WorkoutSession(
      id: data.id.present ? data.id.value : this.id,
      programId: data.programId.present ? data.programId.value : this.programId,
      programName: data.programName.present ? data.programName.value : this.programName,
      day: data.day.present ? data.day.value : this.day,
      at: data.at.present ? data.at.value : this.at,
      note: data.note.present ? data.note.value : this.note,
      minimum: data.minimum.present ? data.minimum.value : this.minimum,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSession(')
          ..write('id: $id, ')
          ..write('programId: $programId, ')
          ..write('programName: $programName, ')
          ..write('day: $day, ')
          ..write('at: $at, ')
          ..write('note: $note, ')
          ..write('minimum: $minimum')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, programId, programName, day, at, note, minimum);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutSession &&
          other.id == this.id &&
          other.programId == this.programId &&
          other.programName == this.programName &&
          other.day == this.day &&
          other.at == this.at &&
          other.note == this.note &&
          other.minimum == this.minimum);
}

class WorkoutSessionsCompanion extends UpdateCompanion<WorkoutSession> {
  final Value<int> id;
  final Value<int?> programId;
  final Value<String> programName;
  final Value<int> day;
  final Value<DateTime> at;
  final Value<String?> note;
  final Value<bool> minimum;
  const WorkoutSessionsCompanion({
    this.id = const Value.absent(),
    this.programId = const Value.absent(),
    this.programName = const Value.absent(),
    this.day = const Value.absent(),
    this.at = const Value.absent(),
    this.note = const Value.absent(),
    this.minimum = const Value.absent(),
  });
  WorkoutSessionsCompanion.insert({
    this.id = const Value.absent(),
    this.programId = const Value.absent(),
    required String programName,
    required int day,
    this.at = const Value.absent(),
    this.note = const Value.absent(),
    this.minimum = const Value.absent(),
  }) : programName = Value(programName),
       day = Value(day);
  static Insertable<WorkoutSession> custom({
    Expression<int>? id,
    Expression<int>? programId,
    Expression<String>? programName,
    Expression<int>? day,
    Expression<DateTime>? at,
    Expression<String>? note,
    Expression<bool>? minimum,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (programId != null) 'program_id': programId,
      if (programName != null) 'program_name': programName,
      if (day != null) 'day': day,
      if (at != null) 'at': at,
      if (note != null) 'note': note,
      if (minimum != null) 'minimum': minimum,
    });
  }

  WorkoutSessionsCompanion copyWith({
    Value<int>? id,
    Value<int?>? programId,
    Value<String>? programName,
    Value<int>? day,
    Value<DateTime>? at,
    Value<String?>? note,
    Value<bool>? minimum,
  }) {
    return WorkoutSessionsCompanion(
      id: id ?? this.id,
      programId: programId ?? this.programId,
      programName: programName ?? this.programName,
      day: day ?? this.day,
      at: at ?? this.at,
      note: note ?? this.note,
      minimum: minimum ?? this.minimum,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (programId.present) {
      map['program_id'] = Variable<int>(programId.value);
    }
    if (programName.present) {
      map['program_name'] = Variable<String>(programName.value);
    }
    if (day.present) {
      map['day'] = Variable<int>(day.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (minimum.present) {
      map['minimum'] = Variable<bool>(minimum.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSessionsCompanion(')
          ..write('id: $id, ')
          ..write('programId: $programId, ')
          ..write('programName: $programName, ')
          ..write('day: $day, ')
          ..write('at: $at, ')
          ..write('note: $note, ')
          ..write('minimum: $minimum')
          ..write(')'))
        .toString();
  }
}

class $SessionSetsTable extends SessionSets with TableInfo<$SessionSetsTable, SessionSet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionSetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta('sessionId');
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES workout_sessions (id) ON DELETE CASCADE'),
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta('exerciseId');
  @override
  late final GeneratedColumn<int> exerciseId = GeneratedColumn<int>(
    'exercise_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES program_exercises (id) ON DELETE SET NULL'),
  );
  static const VerificationMeta _exerciseNameMeta = const VerificationMeta('exerciseName');
  @override
  late final GeneratedColumn<String> exerciseName = GeneratedColumn<String>(
    'exercise_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _setIndexMeta = const VerificationMeta('setIndex');
  @override
  late final GeneratedColumn<int> setIndex = GeneratedColumn<int>(
    'set_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<int> reps = GeneratedColumn<int>(
    'reps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<double> weight = GeneratedColumn<double>(
    'weight',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, sessionId, exerciseId, exerciseName, setIndex, reps, weight];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'session_sets';
  @override
  VerificationContext validateIntegrity(Insertable<SessionSet> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta, sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(_exerciseIdMeta, exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta));
    }
    if (data.containsKey('exercise_name')) {
      context.handle(_exerciseNameMeta, exerciseName.isAcceptableOrUnknown(data['exercise_name']!, _exerciseNameMeta));
    } else if (isInserting) {
      context.missing(_exerciseNameMeta);
    }
    if (data.containsKey('set_index')) {
      context.handle(_setIndexMeta, setIndex.isAcceptableOrUnknown(data['set_index']!, _setIndexMeta));
    } else if (isInserting) {
      context.missing(_setIndexMeta);
    }
    if (data.containsKey('reps')) {
      context.handle(_repsMeta, reps.isAcceptableOrUnknown(data['reps']!, _repsMeta));
    } else if (isInserting) {
      context.missing(_repsMeta);
    }
    if (data.containsKey('weight')) {
      context.handle(_weightMeta, weight.isAcceptableOrUnknown(data['weight']!, _weightMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionSet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionSet(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      sessionId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}session_id'])!,
      exerciseId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}exercise_id']),
      exerciseName: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}exercise_name'])!,
      setIndex: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}set_index'])!,
      reps: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}reps'])!,
      weight: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}weight']),
    );
  }

  @override
  $SessionSetsTable createAlias(String alias) {
    return $SessionSetsTable(attachedDatabase, alias);
  }
}

class SessionSet extends DataClass implements Insertable<SessionSet> {
  final int id;
  final int sessionId;
  final int? exerciseId;
  final String exerciseName;
  final int setIndex;
  final int reps;
  final double? weight;
  const SessionSet({
    required this.id,
    required this.sessionId,
    this.exerciseId,
    required this.exerciseName,
    required this.setIndex,
    required this.reps,
    this.weight,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<int>(sessionId);
    if (!nullToAbsent || exerciseId != null) {
      map['exercise_id'] = Variable<int>(exerciseId);
    }
    map['exercise_name'] = Variable<String>(exerciseName);
    map['set_index'] = Variable<int>(setIndex);
    map['reps'] = Variable<int>(reps);
    if (!nullToAbsent || weight != null) {
      map['weight'] = Variable<double>(weight);
    }
    return map;
  }

  SessionSetsCompanion toCompanion(bool nullToAbsent) {
    return SessionSetsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      exerciseId: exerciseId == null && nullToAbsent ? const Value.absent() : Value(exerciseId),
      exerciseName: Value(exerciseName),
      setIndex: Value(setIndex),
      reps: Value(reps),
      weight: weight == null && nullToAbsent ? const Value.absent() : Value(weight),
    );
  }

  factory SessionSet.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionSet(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<int>(json['sessionId']),
      exerciseId: serializer.fromJson<int?>(json['exerciseId']),
      exerciseName: serializer.fromJson<String>(json['exerciseName']),
      setIndex: serializer.fromJson<int>(json['setIndex']),
      reps: serializer.fromJson<int>(json['reps']),
      weight: serializer.fromJson<double?>(json['weight']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<int>(sessionId),
      'exerciseId': serializer.toJson<int?>(exerciseId),
      'exerciseName': serializer.toJson<String>(exerciseName),
      'setIndex': serializer.toJson<int>(setIndex),
      'reps': serializer.toJson<int>(reps),
      'weight': serializer.toJson<double?>(weight),
    };
  }

  SessionSet copyWith({
    int? id,
    int? sessionId,
    Value<int?> exerciseId = const Value.absent(),
    String? exerciseName,
    int? setIndex,
    int? reps,
    Value<double?> weight = const Value.absent(),
  }) => SessionSet(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    exerciseId: exerciseId.present ? exerciseId.value : this.exerciseId,
    exerciseName: exerciseName ?? this.exerciseName,
    setIndex: setIndex ?? this.setIndex,
    reps: reps ?? this.reps,
    weight: weight.present ? weight.value : this.weight,
  );
  SessionSet copyWithCompanion(SessionSetsCompanion data) {
    return SessionSet(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      exerciseId: data.exerciseId.present ? data.exerciseId.value : this.exerciseId,
      exerciseName: data.exerciseName.present ? data.exerciseName.value : this.exerciseName,
      setIndex: data.setIndex.present ? data.setIndex.value : this.setIndex,
      reps: data.reps.present ? data.reps.value : this.reps,
      weight: data.weight.present ? data.weight.value : this.weight,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionSet(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('exerciseName: $exerciseName, ')
          ..write('setIndex: $setIndex, ')
          ..write('reps: $reps, ')
          ..write('weight: $weight')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, sessionId, exerciseId, exerciseName, setIndex, reps, weight);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionSet &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.exerciseId == this.exerciseId &&
          other.exerciseName == this.exerciseName &&
          other.setIndex == this.setIndex &&
          other.reps == this.reps &&
          other.weight == this.weight);
}

class SessionSetsCompanion extends UpdateCompanion<SessionSet> {
  final Value<int> id;
  final Value<int> sessionId;
  final Value<int?> exerciseId;
  final Value<String> exerciseName;
  final Value<int> setIndex;
  final Value<int> reps;
  final Value<double?> weight;
  const SessionSetsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.exerciseName = const Value.absent(),
    this.setIndex = const Value.absent(),
    this.reps = const Value.absent(),
    this.weight = const Value.absent(),
  });
  SessionSetsCompanion.insert({
    this.id = const Value.absent(),
    required int sessionId,
    this.exerciseId = const Value.absent(),
    required String exerciseName,
    required int setIndex,
    required int reps,
    this.weight = const Value.absent(),
  }) : sessionId = Value(sessionId),
       exerciseName = Value(exerciseName),
       setIndex = Value(setIndex),
       reps = Value(reps);
  static Insertable<SessionSet> custom({
    Expression<int>? id,
    Expression<int>? sessionId,
    Expression<int>? exerciseId,
    Expression<String>? exerciseName,
    Expression<int>? setIndex,
    Expression<int>? reps,
    Expression<double>? weight,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (exerciseName != null) 'exercise_name': exerciseName,
      if (setIndex != null) 'set_index': setIndex,
      if (reps != null) 'reps': reps,
      if (weight != null) 'weight': weight,
    });
  }

  SessionSetsCompanion copyWith({
    Value<int>? id,
    Value<int>? sessionId,
    Value<int?>? exerciseId,
    Value<String>? exerciseName,
    Value<int>? setIndex,
    Value<int>? reps,
    Value<double?>? weight,
  }) {
    return SessionSetsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      setIndex: setIndex ?? this.setIndex,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<int>(exerciseId.value);
    }
    if (exerciseName.present) {
      map['exercise_name'] = Variable<String>(exerciseName.value);
    }
    if (setIndex.present) {
      map['set_index'] = Variable<int>(setIndex.value);
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (weight.present) {
      map['weight'] = Variable<double>(weight.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionSetsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('exerciseName: $exerciseName, ')
          ..write('setIndex: $setIndex, ')
          ..write('reps: $reps, ')
          ..write('weight: $weight')
          ..write(')'))
        .toString();
  }
}

class $JournalEntriesTable extends JournalEntries with TableInfo<$JournalEntriesTable, JournalEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JournalEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<JournalKind, int> kind = GeneratedColumn<int>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  ).withConverter<JournalKind>($JournalEntriesTable.$converterkind);
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<int> day = GeneratedColumn<int>('day', aliasedName, false, type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _moodMeta = const VerificationMeta('mood');
  @override
  late final GeneratedColumn<int> mood = GeneratedColumn<int>(
    'mood',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [id, kind, day, at, mood, body];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'journal_entries';
  @override
  VerificationContext validateIntegrity(Insertable<JournalEntry> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('day')) {
      context.handle(_dayMeta, day.isAcceptableOrUnknown(data['day']!, _dayMeta));
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    }
    if (data.containsKey('mood')) {
      context.handle(_moodMeta, mood.isAcceptableOrUnknown(data['mood']!, _moodMeta));
    }
    if (data.containsKey('body')) {
      context.handle(_bodyMeta, body.isAcceptableOrUnknown(data['body']!, _bodyMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  JournalEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JournalEntry(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      kind: $JournalEntriesTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}kind'])!,
      ),
      day: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}day'])!,
      at: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}at'])!,
      mood: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}mood']),
      body: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}body'])!,
    );
  }

  @override
  $JournalEntriesTable createAlias(String alias) {
    return $JournalEntriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<JournalKind, int, int> $converterkind = const EnumIndexConverter<JournalKind>(JournalKind.values);
}

class JournalEntry extends DataClass implements Insertable<JournalEntry> {
  final int id;
  final JournalKind kind;
  final int day;
  final DateTime at;
  final int? mood;
  final String body;
  const JournalEntry({required this.id, required this.kind, required this.day, required this.at, this.mood, required this.body});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['kind'] = Variable<int>($JournalEntriesTable.$converterkind.toSql(kind));
    }
    map['day'] = Variable<int>(day);
    map['at'] = Variable<DateTime>(at);
    if (!nullToAbsent || mood != null) {
      map['mood'] = Variable<int>(mood);
    }
    map['body'] = Variable<String>(body);
    return map;
  }

  JournalEntriesCompanion toCompanion(bool nullToAbsent) {
    return JournalEntriesCompanion(
      id: Value(id),
      kind: Value(kind),
      day: Value(day),
      at: Value(at),
      mood: mood == null && nullToAbsent ? const Value.absent() : Value(mood),
      body: Value(body),
    );
  }

  factory JournalEntry.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JournalEntry(
      id: serializer.fromJson<int>(json['id']),
      kind: $JournalEntriesTable.$converterkind.fromJson(serializer.fromJson<int>(json['kind'])),
      day: serializer.fromJson<int>(json['day']),
      at: serializer.fromJson<DateTime>(json['at']),
      mood: serializer.fromJson<int?>(json['mood']),
      body: serializer.fromJson<String>(json['body']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'kind': serializer.toJson<int>($JournalEntriesTable.$converterkind.toJson(kind)),
      'day': serializer.toJson<int>(day),
      'at': serializer.toJson<DateTime>(at),
      'mood': serializer.toJson<int?>(mood),
      'body': serializer.toJson<String>(body),
    };
  }

  JournalEntry copyWith({int? id, JournalKind? kind, int? day, DateTime? at, Value<int?> mood = const Value.absent(), String? body}) =>
      JournalEntry(
        id: id ?? this.id,
        kind: kind ?? this.kind,
        day: day ?? this.day,
        at: at ?? this.at,
        mood: mood.present ? mood.value : this.mood,
        body: body ?? this.body,
      );
  JournalEntry copyWithCompanion(JournalEntriesCompanion data) {
    return JournalEntry(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      day: data.day.present ? data.day.value : this.day,
      at: data.at.present ? data.at.value : this.at,
      mood: data.mood.present ? data.mood.value : this.mood,
      body: data.body.present ? data.body.value : this.body,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JournalEntry(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('day: $day, ')
          ..write('at: $at, ')
          ..write('mood: $mood, ')
          ..write('body: $body')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, kind, day, at, mood, body);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JournalEntry &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.day == this.day &&
          other.at == this.at &&
          other.mood == this.mood &&
          other.body == this.body);
}

class JournalEntriesCompanion extends UpdateCompanion<JournalEntry> {
  final Value<int> id;
  final Value<JournalKind> kind;
  final Value<int> day;
  final Value<DateTime> at;
  final Value<int?> mood;
  final Value<String> body;
  const JournalEntriesCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.day = const Value.absent(),
    this.at = const Value.absent(),
    this.mood = const Value.absent(),
    this.body = const Value.absent(),
  });
  JournalEntriesCompanion.insert({
    this.id = const Value.absent(),
    required JournalKind kind,
    required int day,
    this.at = const Value.absent(),
    this.mood = const Value.absent(),
    this.body = const Value.absent(),
  }) : kind = Value(kind),
       day = Value(day);
  static Insertable<JournalEntry> custom({
    Expression<int>? id,
    Expression<int>? kind,
    Expression<int>? day,
    Expression<DateTime>? at,
    Expression<int>? mood,
    Expression<String>? body,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (day != null) 'day': day,
      if (at != null) 'at': at,
      if (mood != null) 'mood': mood,
      if (body != null) 'body': body,
    });
  }

  JournalEntriesCompanion copyWith({
    Value<int>? id,
    Value<JournalKind>? kind,
    Value<int>? day,
    Value<DateTime>? at,
    Value<int?>? mood,
    Value<String>? body,
  }) {
    return JournalEntriesCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      day: day ?? this.day,
      at: at ?? this.at,
      mood: mood ?? this.mood,
      body: body ?? this.body,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<int>($JournalEntriesTable.$converterkind.toSql(kind.value));
    }
    if (day.present) {
      map['day'] = Variable<int>(day.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (mood.present) {
      map['mood'] = Variable<int>(mood.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JournalEntriesCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('day: $day, ')
          ..write('at: $at, ')
          ..write('mood: $mood, ')
          ..write('body: $body')
          ..write(')'))
        .toString();
  }
}

class $RemindersTable extends Reminders with TableInfo<$RemindersTable, Reminder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemindersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _minutesMeta = const VerificationMeta('minutes');
  @override
  late final GeneratedColumn<int> minutes = GeneratedColumn<int>(
    'minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _daysMaskMeta = const VerificationMeta('daysMask');
  @override
  late final GeneratedColumn<int> daysMask = GeneratedColumn<int>(
    'days_mask',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(everyDay),
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta('enabled');
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("enabled" IN (0, 1))'),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [id, title, body, minutes, daysMask, enabled];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminders';
  @override
  VerificationContext validateIntegrity(Insertable<Reminder> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(_titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body')) {
      context.handle(_bodyMeta, body.isAcceptableOrUnknown(data['body']!, _bodyMeta));
    }
    if (data.containsKey('minutes')) {
      context.handle(_minutesMeta, minutes.isAcceptableOrUnknown(data['minutes']!, _minutesMeta));
    } else if (isInserting) {
      context.missing(_minutesMeta);
    }
    if (data.containsKey('days_mask')) {
      context.handle(_daysMaskMeta, daysMask.isAcceptableOrUnknown(data['days_mask']!, _daysMaskMeta));
    }
    if (data.containsKey('enabled')) {
      context.handle(_enabledMeta, enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Reminder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Reminder(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      body: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}body']),
      minutes: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}minutes'])!,
      daysMask: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}days_mask'])!,
      enabled: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}enabled'])!,
    );
  }

  @override
  $RemindersTable createAlias(String alias) {
    return $RemindersTable(attachedDatabase, alias);
  }
}

class Reminder extends DataClass implements Insertable<Reminder> {
  final int id;
  final String title;
  final String? body;
  final int minutes;
  final int daysMask;
  final bool enabled;
  const Reminder({required this.id, required this.title, this.body, required this.minutes, required this.daysMask, required this.enabled});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || body != null) {
      map['body'] = Variable<String>(body);
    }
    map['minutes'] = Variable<int>(minutes);
    map['days_mask'] = Variable<int>(daysMask);
    map['enabled'] = Variable<bool>(enabled);
    return map;
  }

  RemindersCompanion toCompanion(bool nullToAbsent) {
    return RemindersCompanion(
      id: Value(id),
      title: Value(title),
      body: body == null && nullToAbsent ? const Value.absent() : Value(body),
      minutes: Value(minutes),
      daysMask: Value(daysMask),
      enabled: Value(enabled),
    );
  }

  factory Reminder.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Reminder(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String?>(json['body']),
      minutes: serializer.fromJson<int>(json['minutes']),
      daysMask: serializer.fromJson<int>(json['daysMask']),
      enabled: serializer.fromJson<bool>(json['enabled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String?>(body),
      'minutes': serializer.toJson<int>(minutes),
      'daysMask': serializer.toJson<int>(daysMask),
      'enabled': serializer.toJson<bool>(enabled),
    };
  }

  Reminder copyWith({int? id, String? title, Value<String?> body = const Value.absent(), int? minutes, int? daysMask, bool? enabled}) =>
      Reminder(
        id: id ?? this.id,
        title: title ?? this.title,
        body: body.present ? body.value : this.body,
        minutes: minutes ?? this.minutes,
        daysMask: daysMask ?? this.daysMask,
        enabled: enabled ?? this.enabled,
      );
  Reminder copyWithCompanion(RemindersCompanion data) {
    return Reminder(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      minutes: data.minutes.present ? data.minutes.value : this.minutes,
      daysMask: data.daysMask.present ? data.daysMask.value : this.daysMask,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Reminder(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('minutes: $minutes, ')
          ..write('daysMask: $daysMask, ')
          ..write('enabled: $enabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, body, minutes, daysMask, enabled);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Reminder &&
          other.id == this.id &&
          other.title == this.title &&
          other.body == this.body &&
          other.minutes == this.minutes &&
          other.daysMask == this.daysMask &&
          other.enabled == this.enabled);
}

class RemindersCompanion extends UpdateCompanion<Reminder> {
  final Value<int> id;
  final Value<String> title;
  final Value<String?> body;
  final Value<int> minutes;
  final Value<int> daysMask;
  final Value<bool> enabled;
  const RemindersCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.minutes = const Value.absent(),
    this.daysMask = const Value.absent(),
    this.enabled = const Value.absent(),
  });
  RemindersCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.body = const Value.absent(),
    required int minutes,
    this.daysMask = const Value.absent(),
    this.enabled = const Value.absent(),
  }) : title = Value(title),
       minutes = Value(minutes);
  static Insertable<Reminder> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? body,
    Expression<int>? minutes,
    Expression<int>? daysMask,
    Expression<bool>? enabled,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (minutes != null) 'minutes': minutes,
      if (daysMask != null) 'days_mask': daysMask,
      if (enabled != null) 'enabled': enabled,
    });
  }

  RemindersCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String?>? body,
    Value<int>? minutes,
    Value<int>? daysMask,
    Value<bool>? enabled,
  }) {
    return RemindersCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      minutes: minutes ?? this.minutes,
      daysMask: daysMask ?? this.daysMask,
      enabled: enabled ?? this.enabled,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (minutes.present) {
      map['minutes'] = Variable<int>(minutes.value);
    }
    if (daysMask.present) {
      map['days_mask'] = Variable<int>(daysMask.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemindersCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('minutes: $minutes, ')
          ..write('daysMask: $daysMask, ')
          ..write('enabled: $enabled')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(Insertable<Setting> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(_keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(_valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      key: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String key;
  final String value;
  const Setting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory Setting.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(key: serializer.fromJson<String>(json['key']), value: serializer.fromJson<String>(json['value']));
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'key': serializer.toJson<String>(key), 'value': serializer.toJson<String>(value)};
  }

  Setting copyWith({String? key, String? value}) => Setting(key: key ?? this.key, value: value ?? this.value);
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(key: data.key.present ? data.key.value : this.key, value: data.value.present ? data.value.value : this.value);
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) => identical(this, other) || (other is Setting && other.key == this.key && other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({this.key = const Value.absent(), this.value = const Value.absent(), this.rowid = const Value.absent()});
  SettingsCompanion.insert({required String key, required String value, this.rowid = const Value.absent()})
    : key = Value(key),
      value = Value(value);
  static Insertable<Setting> custom({Expression<String>? key, Expression<String>? value, Expression<int>? rowid}) {
    return RawValuesInsertable({if (key != null) 'key': key, if (value != null) 'value': value, if (rowid != null) 'rowid': rowid});
  }

  SettingsCompanion copyWith({Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return SettingsCompanion(key: key ?? this.key, value: value ?? this.value, rowid: rowid ?? this.rowid);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SleepLogsTable extends SleepLogs with TableInfo<$SleepLogsTable, SleepLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SleepLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<int> day = GeneratedColumn<int>('day', aliasedName, false, type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _bedAtMeta = const VerificationMeta('bedAt');
  @override
  late final GeneratedColumn<DateTime> bedAt = GeneratedColumn<DateTime>(
    'bed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wakeAtMeta = const VerificationMeta('wakeAt');
  @override
  late final GeneratedColumn<DateTime> wakeAt = GeneratedColumn<DateTime>(
    'wake_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _qualityMeta = const VerificationMeta('quality');
  @override
  late final GeneratedColumn<int> quality = GeneratedColumn<int>(
    'quality',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, day, bedAt, wakeAt, quality, note];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sleep_logs';
  @override
  VerificationContext validateIntegrity(Insertable<SleepLog> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('day')) {
      context.handle(_dayMeta, day.isAcceptableOrUnknown(data['day']!, _dayMeta));
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('bed_at')) {
      context.handle(_bedAtMeta, bedAt.isAcceptableOrUnknown(data['bed_at']!, _bedAtMeta));
    } else if (isInserting) {
      context.missing(_bedAtMeta);
    }
    if (data.containsKey('wake_at')) {
      context.handle(_wakeAtMeta, wakeAt.isAcceptableOrUnknown(data['wake_at']!, _wakeAtMeta));
    } else if (isInserting) {
      context.missing(_wakeAtMeta);
    }
    if (data.containsKey('quality')) {
      context.handle(_qualityMeta, quality.isAcceptableOrUnknown(data['quality']!, _qualityMeta));
    }
    if (data.containsKey('note')) {
      context.handle(_noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SleepLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SleepLog(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      day: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}day'])!,
      bedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}bed_at'])!,
      wakeAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}wake_at'])!,
      quality: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}quality']),
      note: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}note']),
    );
  }

  @override
  $SleepLogsTable createAlias(String alias) {
    return $SleepLogsTable(attachedDatabase, alias);
  }
}

class SleepLog extends DataClass implements Insertable<SleepLog> {
  final int id;
  final int day;
  final DateTime bedAt;
  final DateTime wakeAt;

  /// Как выспался, от 1 до 5.
  final int? quality;
  final String? note;
  const SleepLog({required this.id, required this.day, required this.bedAt, required this.wakeAt, this.quality, this.note});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['day'] = Variable<int>(day);
    map['bed_at'] = Variable<DateTime>(bedAt);
    map['wake_at'] = Variable<DateTime>(wakeAt);
    if (!nullToAbsent || quality != null) {
      map['quality'] = Variable<int>(quality);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  SleepLogsCompanion toCompanion(bool nullToAbsent) {
    return SleepLogsCompanion(
      id: Value(id),
      day: Value(day),
      bedAt: Value(bedAt),
      wakeAt: Value(wakeAt),
      quality: quality == null && nullToAbsent ? const Value.absent() : Value(quality),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory SleepLog.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SleepLog(
      id: serializer.fromJson<int>(json['id']),
      day: serializer.fromJson<int>(json['day']),
      bedAt: serializer.fromJson<DateTime>(json['bedAt']),
      wakeAt: serializer.fromJson<DateTime>(json['wakeAt']),
      quality: serializer.fromJson<int?>(json['quality']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'day': serializer.toJson<int>(day),
      'bedAt': serializer.toJson<DateTime>(bedAt),
      'wakeAt': serializer.toJson<DateTime>(wakeAt),
      'quality': serializer.toJson<int?>(quality),
      'note': serializer.toJson<String?>(note),
    };
  }

  SleepLog copyWith({
    int? id,
    int? day,
    DateTime? bedAt,
    DateTime? wakeAt,
    Value<int?> quality = const Value.absent(),
    Value<String?> note = const Value.absent(),
  }) => SleepLog(
    id: id ?? this.id,
    day: day ?? this.day,
    bedAt: bedAt ?? this.bedAt,
    wakeAt: wakeAt ?? this.wakeAt,
    quality: quality.present ? quality.value : this.quality,
    note: note.present ? note.value : this.note,
  );
  SleepLog copyWithCompanion(SleepLogsCompanion data) {
    return SleepLog(
      id: data.id.present ? data.id.value : this.id,
      day: data.day.present ? data.day.value : this.day,
      bedAt: data.bedAt.present ? data.bedAt.value : this.bedAt,
      wakeAt: data.wakeAt.present ? data.wakeAt.value : this.wakeAt,
      quality: data.quality.present ? data.quality.value : this.quality,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SleepLog(')
          ..write('id: $id, ')
          ..write('day: $day, ')
          ..write('bedAt: $bedAt, ')
          ..write('wakeAt: $wakeAt, ')
          ..write('quality: $quality, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, day, bedAt, wakeAt, quality, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SleepLog &&
          other.id == this.id &&
          other.day == this.day &&
          other.bedAt == this.bedAt &&
          other.wakeAt == this.wakeAt &&
          other.quality == this.quality &&
          other.note == this.note);
}

class SleepLogsCompanion extends UpdateCompanion<SleepLog> {
  final Value<int> id;
  final Value<int> day;
  final Value<DateTime> bedAt;
  final Value<DateTime> wakeAt;
  final Value<int?> quality;
  final Value<String?> note;
  const SleepLogsCompanion({
    this.id = const Value.absent(),
    this.day = const Value.absent(),
    this.bedAt = const Value.absent(),
    this.wakeAt = const Value.absent(),
    this.quality = const Value.absent(),
    this.note = const Value.absent(),
  });
  SleepLogsCompanion.insert({
    this.id = const Value.absent(),
    required int day,
    required DateTime bedAt,
    required DateTime wakeAt,
    this.quality = const Value.absent(),
    this.note = const Value.absent(),
  }) : day = Value(day),
       bedAt = Value(bedAt),
       wakeAt = Value(wakeAt);
  static Insertable<SleepLog> custom({
    Expression<int>? id,
    Expression<int>? day,
    Expression<DateTime>? bedAt,
    Expression<DateTime>? wakeAt,
    Expression<int>? quality,
    Expression<String>? note,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (day != null) 'day': day,
      if (bedAt != null) 'bed_at': bedAt,
      if (wakeAt != null) 'wake_at': wakeAt,
      if (quality != null) 'quality': quality,
      if (note != null) 'note': note,
    });
  }

  SleepLogsCompanion copyWith({
    Value<int>? id,
    Value<int>? day,
    Value<DateTime>? bedAt,
    Value<DateTime>? wakeAt,
    Value<int?>? quality,
    Value<String?>? note,
  }) {
    return SleepLogsCompanion(
      id: id ?? this.id,
      day: day ?? this.day,
      bedAt: bedAt ?? this.bedAt,
      wakeAt: wakeAt ?? this.wakeAt,
      quality: quality ?? this.quality,
      note: note ?? this.note,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (day.present) {
      map['day'] = Variable<int>(day.value);
    }
    if (bedAt.present) {
      map['bed_at'] = Variable<DateTime>(bedAt.value);
    }
    if (wakeAt.present) {
      map['wake_at'] = Variable<DateTime>(wakeAt.value);
    }
    if (quality.present) {
      map['quality'] = Variable<int>(quality.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SleepLogsCompanion(')
          ..write('id: $id, ')
          ..write('day: $day, ')
          ..write('bedAt: $bedAt, ')
          ..write('wakeAt: $wakeAt, ')
          ..write('quality: $quality, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }
}

class $FoodsTable extends Foods with TableInfo<$FoodsTable, Food> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoodsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('restaurant'),
  );
  static const VerificationMeta _kcalMeta = const VerificationMeta('kcal');
  @override
  late final GeneratedColumn<double> kcal = GeneratedColumn<double>(
    'kcal',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proteinMeta = const VerificationMeta('protein');
  @override
  late final GeneratedColumn<double> protein = GeneratedColumn<double>(
    'protein',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _fatMeta = const VerificationMeta('fat');
  @override
  late final GeneratedColumn<double> fat = GeneratedColumn<double>(
    'fat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _carbsMeta = const VerificationMeta('carbs');
  @override
  late final GeneratedColumn<double> carbs = GeneratedColumn<double>(
    'carbs',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta('archived');
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("archived" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, icon, kcal, protein, fat, carbs, sortOrder, archived];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'foods';
  @override
  VerificationContext validateIntegrity(Insertable<Food> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(_iconMeta, icon.isAcceptableOrUnknown(data['icon']!, _iconMeta));
    }
    if (data.containsKey('kcal')) {
      context.handle(_kcalMeta, kcal.isAcceptableOrUnknown(data['kcal']!, _kcalMeta));
    } else if (isInserting) {
      context.missing(_kcalMeta);
    }
    if (data.containsKey('protein')) {
      context.handle(_proteinMeta, protein.isAcceptableOrUnknown(data['protein']!, _proteinMeta));
    }
    if (data.containsKey('fat')) {
      context.handle(_fatMeta, fat.isAcceptableOrUnknown(data['fat']!, _fatMeta));
    }
    if (data.containsKey('carbs')) {
      context.handle(_carbsMeta, carbs.isAcceptableOrUnknown(data['carbs']!, _carbsMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta, sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('archived')) {
      context.handle(_archivedMeta, archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Food map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Food(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      icon: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}icon'])!,
      kcal: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}kcal'])!,
      protein: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}protein'])!,
      fat: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}fat'])!,
      carbs: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}carbs'])!,
      sortOrder: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      archived: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}archived'])!,
    );
  }

  @override
  $FoodsTable createAlias(String alias) {
    return $FoodsTable(attachedDatabase, alias);
  }
}

class Food extends DataClass implements Insertable<Food> {
  final int id;
  final String name;
  final String icon;
  final double kcal;
  final double protein;
  final double fat;
  final double carbs;
  final int sortOrder;
  final bool archived;
  const Food({
    required this.id,
    required this.name,
    required this.icon,
    required this.kcal,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.sortOrder,
    required this.archived,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['icon'] = Variable<String>(icon);
    map['kcal'] = Variable<double>(kcal);
    map['protein'] = Variable<double>(protein);
    map['fat'] = Variable<double>(fat);
    map['carbs'] = Variable<double>(carbs);
    map['sort_order'] = Variable<int>(sortOrder);
    map['archived'] = Variable<bool>(archived);
    return map;
  }

  FoodsCompanion toCompanion(bool nullToAbsent) {
    return FoodsCompanion(
      id: Value(id),
      name: Value(name),
      icon: Value(icon),
      kcal: Value(kcal),
      protein: Value(protein),
      fat: Value(fat),
      carbs: Value(carbs),
      sortOrder: Value(sortOrder),
      archived: Value(archived),
    );
  }

  factory Food.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Food(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      icon: serializer.fromJson<String>(json['icon']),
      kcal: serializer.fromJson<double>(json['kcal']),
      protein: serializer.fromJson<double>(json['protein']),
      fat: serializer.fromJson<double>(json['fat']),
      carbs: serializer.fromJson<double>(json['carbs']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      archived: serializer.fromJson<bool>(json['archived']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'icon': serializer.toJson<String>(icon),
      'kcal': serializer.toJson<double>(kcal),
      'protein': serializer.toJson<double>(protein),
      'fat': serializer.toJson<double>(fat),
      'carbs': serializer.toJson<double>(carbs),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'archived': serializer.toJson<bool>(archived),
    };
  }

  Food copyWith({
    int? id,
    String? name,
    String? icon,
    double? kcal,
    double? protein,
    double? fat,
    double? carbs,
    int? sortOrder,
    bool? archived,
  }) => Food(
    id: id ?? this.id,
    name: name ?? this.name,
    icon: icon ?? this.icon,
    kcal: kcal ?? this.kcal,
    protein: protein ?? this.protein,
    fat: fat ?? this.fat,
    carbs: carbs ?? this.carbs,
    sortOrder: sortOrder ?? this.sortOrder,
    archived: archived ?? this.archived,
  );
  Food copyWithCompanion(FoodsCompanion data) {
    return Food(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      icon: data.icon.present ? data.icon.value : this.icon,
      kcal: data.kcal.present ? data.kcal.value : this.kcal,
      protein: data.protein.present ? data.protein.value : this.protein,
      fat: data.fat.present ? data.fat.value : this.fat,
      carbs: data.carbs.present ? data.carbs.value : this.carbs,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      archived: data.archived.present ? data.archived.value : this.archived,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Food(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('kcal: $kcal, ')
          ..write('protein: $protein, ')
          ..write('fat: $fat, ')
          ..write('carbs: $carbs, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('archived: $archived')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, icon, kcal, protein, fat, carbs, sortOrder, archived);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Food &&
          other.id == this.id &&
          other.name == this.name &&
          other.icon == this.icon &&
          other.kcal == this.kcal &&
          other.protein == this.protein &&
          other.fat == this.fat &&
          other.carbs == this.carbs &&
          other.sortOrder == this.sortOrder &&
          other.archived == this.archived);
}

class FoodsCompanion extends UpdateCompanion<Food> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> icon;
  final Value<double> kcal;
  final Value<double> protein;
  final Value<double> fat;
  final Value<double> carbs;
  final Value<int> sortOrder;
  final Value<bool> archived;
  const FoodsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.icon = const Value.absent(),
    this.kcal = const Value.absent(),
    this.protein = const Value.absent(),
    this.fat = const Value.absent(),
    this.carbs = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.archived = const Value.absent(),
  });
  FoodsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.icon = const Value.absent(),
    required double kcal,
    this.protein = const Value.absent(),
    this.fat = const Value.absent(),
    this.carbs = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.archived = const Value.absent(),
  }) : name = Value(name),
       kcal = Value(kcal);
  static Insertable<Food> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? icon,
    Expression<double>? kcal,
    Expression<double>? protein,
    Expression<double>? fat,
    Expression<double>? carbs,
    Expression<int>? sortOrder,
    Expression<bool>? archived,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (icon != null) 'icon': icon,
      if (kcal != null) 'kcal': kcal,
      if (protein != null) 'protein': protein,
      if (fat != null) 'fat': fat,
      if (carbs != null) 'carbs': carbs,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (archived != null) 'archived': archived,
    });
  }

  FoodsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? icon,
    Value<double>? kcal,
    Value<double>? protein,
    Value<double>? fat,
    Value<double>? carbs,
    Value<int>? sortOrder,
    Value<bool>? archived,
  }) {
    return FoodsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      kcal: kcal ?? this.kcal,
      protein: protein ?? this.protein,
      fat: fat ?? this.fat,
      carbs: carbs ?? this.carbs,
      sortOrder: sortOrder ?? this.sortOrder,
      archived: archived ?? this.archived,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (kcal.present) {
      map['kcal'] = Variable<double>(kcal.value);
    }
    if (protein.present) {
      map['protein'] = Variable<double>(protein.value);
    }
    if (fat.present) {
      map['fat'] = Variable<double>(fat.value);
    }
    if (carbs.present) {
      map['carbs'] = Variable<double>(carbs.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoodsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('kcal: $kcal, ')
          ..write('protein: $protein, ')
          ..write('fat: $fat, ')
          ..write('carbs: $carbs, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('archived: $archived')
          ..write(')'))
        .toString();
  }
}

class $MealsTable extends Meals with TableInfo<$MealsTable, Meal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<int> day = GeneratedColumn<int>('day', aliasedName, false, type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('restaurant'),
  );
  static const VerificationMeta _kcalMeta = const VerificationMeta('kcal');
  @override
  late final GeneratedColumn<double> kcal = GeneratedColumn<double>(
    'kcal',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _proteinMeta = const VerificationMeta('protein');
  @override
  late final GeneratedColumn<double> protein = GeneratedColumn<double>(
    'protein',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _fatMeta = const VerificationMeta('fat');
  @override
  late final GeneratedColumn<double> fat = GeneratedColumn<double>(
    'fat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _carbsMeta = const VerificationMeta('carbs');
  @override
  late final GeneratedColumn<double> carbs = GeneratedColumn<double>(
    'carbs',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _slotMeta = const VerificationMeta('slot');
  @override
  late final GeneratedColumn<int> slot = GeneratedColumn<int>(
    'slot',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _foodIdMeta = const VerificationMeta('foodId');
  @override
  late final GeneratedColumn<int> foodId = GeneratedColumn<int>(
    'food_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES foods (id) ON DELETE SET NULL'),
  );
  @override
  List<GeneratedColumn> get $columns => [id, day, at, name, icon, kcal, protein, fat, carbs, slot, foodId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meals';
  @override
  VerificationContext validateIntegrity(Insertable<Meal> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('day')) {
      context.handle(_dayMeta, day.isAcceptableOrUnknown(data['day']!, _dayMeta));
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(_iconMeta, icon.isAcceptableOrUnknown(data['icon']!, _iconMeta));
    }
    if (data.containsKey('kcal')) {
      context.handle(_kcalMeta, kcal.isAcceptableOrUnknown(data['kcal']!, _kcalMeta));
    } else if (isInserting) {
      context.missing(_kcalMeta);
    }
    if (data.containsKey('protein')) {
      context.handle(_proteinMeta, protein.isAcceptableOrUnknown(data['protein']!, _proteinMeta));
    }
    if (data.containsKey('fat')) {
      context.handle(_fatMeta, fat.isAcceptableOrUnknown(data['fat']!, _fatMeta));
    }
    if (data.containsKey('carbs')) {
      context.handle(_carbsMeta, carbs.isAcceptableOrUnknown(data['carbs']!, _carbsMeta));
    }
    if (data.containsKey('slot')) {
      context.handle(_slotMeta, slot.isAcceptableOrUnknown(data['slot']!, _slotMeta));
    }
    if (data.containsKey('food_id')) {
      context.handle(_foodIdMeta, foodId.isAcceptableOrUnknown(data['food_id']!, _foodIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Meal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Meal(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      day: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}day'])!,
      at: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}at'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      icon: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}icon'])!,
      kcal: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}kcal'])!,
      protein: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}protein'])!,
      fat: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}fat'])!,
      carbs: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}carbs'])!,
      slot: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}slot']),
      foodId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}food_id']),
    );
  }

  @override
  $MealsTable createAlias(String alias) {
    return $MealsTable(attachedDatabase, alias);
  }
}

class Meal extends DataClass implements Insertable<Meal> {
  final int id;
  final int day;
  final DateTime at;
  final String name;
  final String icon;
  final double kcal;
  final double protein;
  final double fat;
  final double carbs;

  /// Приём пищи: 0 завтрак, 1 обед, 2 ужин, 3 перекус. null у записей до версии 4: определяется по времени.
  final int? slot;
  final int? foodId;
  const Meal({
    required this.id,
    required this.day,
    required this.at,
    required this.name,
    required this.icon,
    required this.kcal,
    required this.protein,
    required this.fat,
    required this.carbs,
    this.slot,
    this.foodId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['day'] = Variable<int>(day);
    map['at'] = Variable<DateTime>(at);
    map['name'] = Variable<String>(name);
    map['icon'] = Variable<String>(icon);
    map['kcal'] = Variable<double>(kcal);
    map['protein'] = Variable<double>(protein);
    map['fat'] = Variable<double>(fat);
    map['carbs'] = Variable<double>(carbs);
    if (!nullToAbsent || slot != null) {
      map['slot'] = Variable<int>(slot);
    }
    if (!nullToAbsent || foodId != null) {
      map['food_id'] = Variable<int>(foodId);
    }
    return map;
  }

  MealsCompanion toCompanion(bool nullToAbsent) {
    return MealsCompanion(
      id: Value(id),
      day: Value(day),
      at: Value(at),
      name: Value(name),
      icon: Value(icon),
      kcal: Value(kcal),
      protein: Value(protein),
      fat: Value(fat),
      carbs: Value(carbs),
      slot: slot == null && nullToAbsent ? const Value.absent() : Value(slot),
      foodId: foodId == null && nullToAbsent ? const Value.absent() : Value(foodId),
    );
  }

  factory Meal.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Meal(
      id: serializer.fromJson<int>(json['id']),
      day: serializer.fromJson<int>(json['day']),
      at: serializer.fromJson<DateTime>(json['at']),
      name: serializer.fromJson<String>(json['name']),
      icon: serializer.fromJson<String>(json['icon']),
      kcal: serializer.fromJson<double>(json['kcal']),
      protein: serializer.fromJson<double>(json['protein']),
      fat: serializer.fromJson<double>(json['fat']),
      carbs: serializer.fromJson<double>(json['carbs']),
      slot: serializer.fromJson<int?>(json['slot']),
      foodId: serializer.fromJson<int?>(json['foodId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'day': serializer.toJson<int>(day),
      'at': serializer.toJson<DateTime>(at),
      'name': serializer.toJson<String>(name),
      'icon': serializer.toJson<String>(icon),
      'kcal': serializer.toJson<double>(kcal),
      'protein': serializer.toJson<double>(protein),
      'fat': serializer.toJson<double>(fat),
      'carbs': serializer.toJson<double>(carbs),
      'slot': serializer.toJson<int?>(slot),
      'foodId': serializer.toJson<int?>(foodId),
    };
  }

  Meal copyWith({
    int? id,
    int? day,
    DateTime? at,
    String? name,
    String? icon,
    double? kcal,
    double? protein,
    double? fat,
    double? carbs,
    Value<int?> slot = const Value.absent(),
    Value<int?> foodId = const Value.absent(),
  }) => Meal(
    id: id ?? this.id,
    day: day ?? this.day,
    at: at ?? this.at,
    name: name ?? this.name,
    icon: icon ?? this.icon,
    kcal: kcal ?? this.kcal,
    protein: protein ?? this.protein,
    fat: fat ?? this.fat,
    carbs: carbs ?? this.carbs,
    slot: slot.present ? slot.value : this.slot,
    foodId: foodId.present ? foodId.value : this.foodId,
  );
  Meal copyWithCompanion(MealsCompanion data) {
    return Meal(
      id: data.id.present ? data.id.value : this.id,
      day: data.day.present ? data.day.value : this.day,
      at: data.at.present ? data.at.value : this.at,
      name: data.name.present ? data.name.value : this.name,
      icon: data.icon.present ? data.icon.value : this.icon,
      kcal: data.kcal.present ? data.kcal.value : this.kcal,
      protein: data.protein.present ? data.protein.value : this.protein,
      fat: data.fat.present ? data.fat.value : this.fat,
      carbs: data.carbs.present ? data.carbs.value : this.carbs,
      slot: data.slot.present ? data.slot.value : this.slot,
      foodId: data.foodId.present ? data.foodId.value : this.foodId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Meal(')
          ..write('id: $id, ')
          ..write('day: $day, ')
          ..write('at: $at, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('kcal: $kcal, ')
          ..write('protein: $protein, ')
          ..write('fat: $fat, ')
          ..write('carbs: $carbs, ')
          ..write('slot: $slot, ')
          ..write('foodId: $foodId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, day, at, name, icon, kcal, protein, fat, carbs, slot, foodId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Meal &&
          other.id == this.id &&
          other.day == this.day &&
          other.at == this.at &&
          other.name == this.name &&
          other.icon == this.icon &&
          other.kcal == this.kcal &&
          other.protein == this.protein &&
          other.fat == this.fat &&
          other.carbs == this.carbs &&
          other.slot == this.slot &&
          other.foodId == this.foodId);
}

class MealsCompanion extends UpdateCompanion<Meal> {
  final Value<int> id;
  final Value<int> day;
  final Value<DateTime> at;
  final Value<String> name;
  final Value<String> icon;
  final Value<double> kcal;
  final Value<double> protein;
  final Value<double> fat;
  final Value<double> carbs;
  final Value<int?> slot;
  final Value<int?> foodId;
  const MealsCompanion({
    this.id = const Value.absent(),
    this.day = const Value.absent(),
    this.at = const Value.absent(),
    this.name = const Value.absent(),
    this.icon = const Value.absent(),
    this.kcal = const Value.absent(),
    this.protein = const Value.absent(),
    this.fat = const Value.absent(),
    this.carbs = const Value.absent(),
    this.slot = const Value.absent(),
    this.foodId = const Value.absent(),
  });
  MealsCompanion.insert({
    this.id = const Value.absent(),
    required int day,
    this.at = const Value.absent(),
    required String name,
    this.icon = const Value.absent(),
    required double kcal,
    this.protein = const Value.absent(),
    this.fat = const Value.absent(),
    this.carbs = const Value.absent(),
    this.slot = const Value.absent(),
    this.foodId = const Value.absent(),
  }) : day = Value(day),
       name = Value(name),
       kcal = Value(kcal);
  static Insertable<Meal> custom({
    Expression<int>? id,
    Expression<int>? day,
    Expression<DateTime>? at,
    Expression<String>? name,
    Expression<String>? icon,
    Expression<double>? kcal,
    Expression<double>? protein,
    Expression<double>? fat,
    Expression<double>? carbs,
    Expression<int>? slot,
    Expression<int>? foodId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (day != null) 'day': day,
      if (at != null) 'at': at,
      if (name != null) 'name': name,
      if (icon != null) 'icon': icon,
      if (kcal != null) 'kcal': kcal,
      if (protein != null) 'protein': protein,
      if (fat != null) 'fat': fat,
      if (carbs != null) 'carbs': carbs,
      if (slot != null) 'slot': slot,
      if (foodId != null) 'food_id': foodId,
    });
  }

  MealsCompanion copyWith({
    Value<int>? id,
    Value<int>? day,
    Value<DateTime>? at,
    Value<String>? name,
    Value<String>? icon,
    Value<double>? kcal,
    Value<double>? protein,
    Value<double>? fat,
    Value<double>? carbs,
    Value<int?>? slot,
    Value<int?>? foodId,
  }) {
    return MealsCompanion(
      id: id ?? this.id,
      day: day ?? this.day,
      at: at ?? this.at,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      kcal: kcal ?? this.kcal,
      protein: protein ?? this.protein,
      fat: fat ?? this.fat,
      carbs: carbs ?? this.carbs,
      slot: slot ?? this.slot,
      foodId: foodId ?? this.foodId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (day.present) {
      map['day'] = Variable<int>(day.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (kcal.present) {
      map['kcal'] = Variable<double>(kcal.value);
    }
    if (protein.present) {
      map['protein'] = Variable<double>(protein.value);
    }
    if (fat.present) {
      map['fat'] = Variable<double>(fat.value);
    }
    if (carbs.present) {
      map['carbs'] = Variable<double>(carbs.value);
    }
    if (slot.present) {
      map['slot'] = Variable<int>(slot.value);
    }
    if (foodId.present) {
      map['food_id'] = Variable<int>(foodId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MealsCompanion(')
          ..write('id: $id, ')
          ..write('day: $day, ')
          ..write('at: $at, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('kcal: $kcal, ')
          ..write('protein: $protein, ')
          ..write('fat: $fat, ')
          ..write('carbs: $carbs, ')
          ..write('slot: $slot, ')
          ..write('foodId: $foodId')
          ..write(')'))
        .toString();
  }
}

class $WaterLogsTable extends WaterLogs with TableInfo<$WaterLogsTable, WaterLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WaterLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<int> day = GeneratedColumn<int>('day', aliasedName, false, type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _mlMeta = const VerificationMeta('ml');
  @override
  late final GeneratedColumn<int> ml = GeneratedColumn<int>('ml', aliasedName, false, type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, day, at, ml];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'water_logs';
  @override
  VerificationContext validateIntegrity(Insertable<WaterLog> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('day')) {
      context.handle(_dayMeta, day.isAcceptableOrUnknown(data['day']!, _dayMeta));
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    }
    if (data.containsKey('ml')) {
      context.handle(_mlMeta, ml.isAcceptableOrUnknown(data['ml']!, _mlMeta));
    } else if (isInserting) {
      context.missing(_mlMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WaterLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WaterLog(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      day: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}day'])!,
      at: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}at'])!,
      ml: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}ml'])!,
    );
  }

  @override
  $WaterLogsTable createAlias(String alias) {
    return $WaterLogsTable(attachedDatabase, alias);
  }
}

class WaterLog extends DataClass implements Insertable<WaterLog> {
  final int id;
  final int day;
  final DateTime at;
  final int ml;
  const WaterLog({required this.id, required this.day, required this.at, required this.ml});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['day'] = Variable<int>(day);
    map['at'] = Variable<DateTime>(at);
    map['ml'] = Variable<int>(ml);
    return map;
  }

  WaterLogsCompanion toCompanion(bool nullToAbsent) {
    return WaterLogsCompanion(id: Value(id), day: Value(day), at: Value(at), ml: Value(ml));
  }

  factory WaterLog.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WaterLog(
      id: serializer.fromJson<int>(json['id']),
      day: serializer.fromJson<int>(json['day']),
      at: serializer.fromJson<DateTime>(json['at']),
      ml: serializer.fromJson<int>(json['ml']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'day': serializer.toJson<int>(day),
      'at': serializer.toJson<DateTime>(at),
      'ml': serializer.toJson<int>(ml),
    };
  }

  WaterLog copyWith({int? id, int? day, DateTime? at, int? ml}) =>
      WaterLog(id: id ?? this.id, day: day ?? this.day, at: at ?? this.at, ml: ml ?? this.ml);
  WaterLog copyWithCompanion(WaterLogsCompanion data) {
    return WaterLog(
      id: data.id.present ? data.id.value : this.id,
      day: data.day.present ? data.day.value : this.day,
      at: data.at.present ? data.at.value : this.at,
      ml: data.ml.present ? data.ml.value : this.ml,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WaterLog(')
          ..write('id: $id, ')
          ..write('day: $day, ')
          ..write('at: $at, ')
          ..write('ml: $ml')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, day, at, ml);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WaterLog && other.id == this.id && other.day == this.day && other.at == this.at && other.ml == this.ml);
}

class WaterLogsCompanion extends UpdateCompanion<WaterLog> {
  final Value<int> id;
  final Value<int> day;
  final Value<DateTime> at;
  final Value<int> ml;
  const WaterLogsCompanion({
    this.id = const Value.absent(),
    this.day = const Value.absent(),
    this.at = const Value.absent(),
    this.ml = const Value.absent(),
  });
  WaterLogsCompanion.insert({this.id = const Value.absent(), required int day, this.at = const Value.absent(), required int ml})
    : day = Value(day),
      ml = Value(ml);
  static Insertable<WaterLog> custom({Expression<int>? id, Expression<int>? day, Expression<DateTime>? at, Expression<int>? ml}) {
    return RawValuesInsertable({if (id != null) 'id': id, if (day != null) 'day': day, if (at != null) 'at': at, if (ml != null) 'ml': ml});
  }

  WaterLogsCompanion copyWith({Value<int>? id, Value<int>? day, Value<DateTime>? at, Value<int>? ml}) {
    return WaterLogsCompanion(id: id ?? this.id, day: day ?? this.day, at: at ?? this.at, ml: ml ?? this.ml);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (day.present) {
      map['day'] = Variable<int>(day.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (ml.present) {
      map['ml'] = Variable<int>(ml.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WaterLogsCompanion(')
          ..write('id: $id, ')
          ..write('day: $day, ')
          ..write('at: $at, ')
          ..write('ml: $ml')
          ..write(')'))
        .toString();
  }
}

class $HardDaysTable extends HardDays with TableInfo<$HardDaysTable, HardDay> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HardDaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<int> day = GeneratedColumn<int>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [day];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hard_days';
  @override
  VerificationContext validateIntegrity(Insertable<HardDay> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('day')) {
      context.handle(_dayMeta, day.isAcceptableOrUnknown(data['day']!, _dayMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {day};
  @override
  HardDay map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HardDay(day: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}day'])!);
  }

  @override
  $HardDaysTable createAlias(String alias) {
    return $HardDaysTable(attachedDatabase, alias);
  }
}

class HardDay extends DataClass implements Insertable<HardDay> {
  final int day;
  const HardDay({required this.day});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['day'] = Variable<int>(day);
    return map;
  }

  HardDaysCompanion toCompanion(bool nullToAbsent) {
    return HardDaysCompanion(day: Value(day));
  }

  factory HardDay.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HardDay(day: serializer.fromJson<int>(json['day']));
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'day': serializer.toJson<int>(day)};
  }

  HardDay copyWith({int? day}) => HardDay(day: day ?? this.day);
  HardDay copyWithCompanion(HardDaysCompanion data) {
    return HardDay(day: data.day.present ? data.day.value : this.day);
  }

  @override
  String toString() {
    return (StringBuffer('HardDay(')
          ..write('day: $day')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => day.hashCode;
  @override
  bool operator ==(Object other) => identical(this, other) || (other is HardDay && other.day == this.day);
}

class HardDaysCompanion extends UpdateCompanion<HardDay> {
  final Value<int> day;
  const HardDaysCompanion({this.day = const Value.absent()});
  HardDaysCompanion.insert({this.day = const Value.absent()});
  static Insertable<HardDay> custom({Expression<int>? day}) {
    return RawValuesInsertable({if (day != null) 'day': day});
  }

  HardDaysCompanion copyWith({Value<int>? day}) {
    return HardDaysCompanion(day: day ?? this.day);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (day.present) {
      map['day'] = Variable<int>(day.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HardDaysCompanion(')
          ..write('day: $day')
          ..write(')'))
        .toString();
  }
}

class $TimeBlocksTable extends TimeBlocks with TableInfo<$TimeBlocksTable, TimeBlock> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TimeBlocksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('clock'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<BlockKind, int> kind = GeneratedColumn<int>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  ).withConverter<BlockKind>($TimeBlocksTable.$converterkind);
  static const VerificationMeta _startMeta = const VerificationMeta('start');
  @override
  late final GeneratedColumn<int> start = GeneratedColumn<int>(
    'start',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endMeta = const VerificationMeta('end');
  @override
  late final GeneratedColumn<int> end = GeneratedColumn<int>('end', aliasedName, false, type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _daysMaskMeta = const VerificationMeta('daysMask');
  @override
  late final GeneratedColumn<int> daysMask = GeneratedColumn<int>(
    'days_mask',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(everyDay),
  );
  static const VerificationMeta _remindMeta = const VerificationMeta('remind');
  @override
  late final GeneratedColumn<bool> remind = GeneratedColumn<bool>(
    'remind',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("remind" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, icon, kind, start, end, daysMask, remind, note];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'time_blocks';
  @override
  VerificationContext validateIntegrity(Insertable<TimeBlock> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(_iconMeta, icon.isAcceptableOrUnknown(data['icon']!, _iconMeta));
    }
    if (data.containsKey('start')) {
      context.handle(_startMeta, start.isAcceptableOrUnknown(data['start']!, _startMeta));
    } else if (isInserting) {
      context.missing(_startMeta);
    }
    if (data.containsKey('end')) {
      context.handle(_endMeta, end.isAcceptableOrUnknown(data['end']!, _endMeta));
    } else if (isInserting) {
      context.missing(_endMeta);
    }
    if (data.containsKey('days_mask')) {
      context.handle(_daysMaskMeta, daysMask.isAcceptableOrUnknown(data['days_mask']!, _daysMaskMeta));
    }
    if (data.containsKey('remind')) {
      context.handle(_remindMeta, remind.isAcceptableOrUnknown(data['remind']!, _remindMeta));
    }
    if (data.containsKey('note')) {
      context.handle(_noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TimeBlock map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TimeBlock(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      icon: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}icon'])!,
      kind: $TimeBlocksTable.$converterkind.fromSql(attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}kind'])!),
      start: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}start'])!,
      end: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}end'])!,
      daysMask: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}days_mask'])!,
      remind: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}remind'])!,
      note: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}note']),
    );
  }

  @override
  $TimeBlocksTable createAlias(String alias) {
    return $TimeBlocksTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<BlockKind, int, int> $converterkind = const EnumIndexConverter<BlockKind>(BlockKind.values);
}

class TimeBlock extends DataClass implements Insertable<TimeBlock> {
  final int id;
  final String name;
  final String icon;
  final BlockKind kind;

  /// Начало и конец в минутах от полуночи. Конец меньше начала: блок через полночь.
  final int start;
  final int end;
  final int daysMask;

  /// Напомнить в начале блока.
  final bool remind;
  final String? note;
  const TimeBlock({
    required this.id,
    required this.name,
    required this.icon,
    required this.kind,
    required this.start,
    required this.end,
    required this.daysMask,
    required this.remind,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['icon'] = Variable<String>(icon);
    {
      map['kind'] = Variable<int>($TimeBlocksTable.$converterkind.toSql(kind));
    }
    map['start'] = Variable<int>(start);
    map['end'] = Variable<int>(end);
    map['days_mask'] = Variable<int>(daysMask);
    map['remind'] = Variable<bool>(remind);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  TimeBlocksCompanion toCompanion(bool nullToAbsent) {
    return TimeBlocksCompanion(
      id: Value(id),
      name: Value(name),
      icon: Value(icon),
      kind: Value(kind),
      start: Value(start),
      end: Value(end),
      daysMask: Value(daysMask),
      remind: Value(remind),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory TimeBlock.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TimeBlock(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      icon: serializer.fromJson<String>(json['icon']),
      kind: $TimeBlocksTable.$converterkind.fromJson(serializer.fromJson<int>(json['kind'])),
      start: serializer.fromJson<int>(json['start']),
      end: serializer.fromJson<int>(json['end']),
      daysMask: serializer.fromJson<int>(json['daysMask']),
      remind: serializer.fromJson<bool>(json['remind']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'icon': serializer.toJson<String>(icon),
      'kind': serializer.toJson<int>($TimeBlocksTable.$converterkind.toJson(kind)),
      'start': serializer.toJson<int>(start),
      'end': serializer.toJson<int>(end),
      'daysMask': serializer.toJson<int>(daysMask),
      'remind': serializer.toJson<bool>(remind),
      'note': serializer.toJson<String?>(note),
    };
  }

  TimeBlock copyWith({
    int? id,
    String? name,
    String? icon,
    BlockKind? kind,
    int? start,
    int? end,
    int? daysMask,
    bool? remind,
    Value<String?> note = const Value.absent(),
  }) => TimeBlock(
    id: id ?? this.id,
    name: name ?? this.name,
    icon: icon ?? this.icon,
    kind: kind ?? this.kind,
    start: start ?? this.start,
    end: end ?? this.end,
    daysMask: daysMask ?? this.daysMask,
    remind: remind ?? this.remind,
    note: note.present ? note.value : this.note,
  );
  TimeBlock copyWithCompanion(TimeBlocksCompanion data) {
    return TimeBlock(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      icon: data.icon.present ? data.icon.value : this.icon,
      kind: data.kind.present ? data.kind.value : this.kind,
      start: data.start.present ? data.start.value : this.start,
      end: data.end.present ? data.end.value : this.end,
      daysMask: data.daysMask.present ? data.daysMask.value : this.daysMask,
      remind: data.remind.present ? data.remind.value : this.remind,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TimeBlock(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('kind: $kind, ')
          ..write('start: $start, ')
          ..write('end: $end, ')
          ..write('daysMask: $daysMask, ')
          ..write('remind: $remind, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, icon, kind, start, end, daysMask, remind, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TimeBlock &&
          other.id == this.id &&
          other.name == this.name &&
          other.icon == this.icon &&
          other.kind == this.kind &&
          other.start == this.start &&
          other.end == this.end &&
          other.daysMask == this.daysMask &&
          other.remind == this.remind &&
          other.note == this.note);
}

class TimeBlocksCompanion extends UpdateCompanion<TimeBlock> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> icon;
  final Value<BlockKind> kind;
  final Value<int> start;
  final Value<int> end;
  final Value<int> daysMask;
  final Value<bool> remind;
  final Value<String?> note;
  const TimeBlocksCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.icon = const Value.absent(),
    this.kind = const Value.absent(),
    this.start = const Value.absent(),
    this.end = const Value.absent(),
    this.daysMask = const Value.absent(),
    this.remind = const Value.absent(),
    this.note = const Value.absent(),
  });
  TimeBlocksCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.icon = const Value.absent(),
    required BlockKind kind,
    required int start,
    required int end,
    this.daysMask = const Value.absent(),
    this.remind = const Value.absent(),
    this.note = const Value.absent(),
  }) : name = Value(name),
       kind = Value(kind),
       start = Value(start),
       end = Value(end);
  static Insertable<TimeBlock> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? icon,
    Expression<int>? kind,
    Expression<int>? start,
    Expression<int>? end,
    Expression<int>? daysMask,
    Expression<bool>? remind,
    Expression<String>? note,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (icon != null) 'icon': icon,
      if (kind != null) 'kind': kind,
      if (start != null) 'start': start,
      if (end != null) 'end': end,
      if (daysMask != null) 'days_mask': daysMask,
      if (remind != null) 'remind': remind,
      if (note != null) 'note': note,
    });
  }

  TimeBlocksCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? icon,
    Value<BlockKind>? kind,
    Value<int>? start,
    Value<int>? end,
    Value<int>? daysMask,
    Value<bool>? remind,
    Value<String?>? note,
  }) {
    return TimeBlocksCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      kind: kind ?? this.kind,
      start: start ?? this.start,
      end: end ?? this.end,
      daysMask: daysMask ?? this.daysMask,
      remind: remind ?? this.remind,
      note: note ?? this.note,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (kind.present) {
      map['kind'] = Variable<int>($TimeBlocksTable.$converterkind.toSql(kind.value));
    }
    if (start.present) {
      map['start'] = Variable<int>(start.value);
    }
    if (end.present) {
      map['end'] = Variable<int>(end.value);
    }
    if (daysMask.present) {
      map['days_mask'] = Variable<int>(daysMask.value);
    }
    if (remind.present) {
      map['remind'] = Variable<bool>(remind.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TimeBlocksCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('kind: $kind, ')
          ..write('start: $start, ')
          ..write('end: $end, ')
          ..write('daysMask: $daysMask, ')
          ..write('remind: $remind, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }
}

class $BudgetLinesTable extends BudgetLines with TableInfo<$BudgetLinesTable, BudgetLine> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetLinesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _monthMeta = const VerificationMeta('month');
  @override
  late final GeneratedColumn<int> month = GeneratedColumn<int>(
    'month',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES categories (id) ON DELETE CASCADE'),
  );
  static const VerificationMeta _fundIdMeta = const VerificationMeta('fundId');
  @override
  late final GeneratedColumn<int> fundId = GeneratedColumn<int>(
    'fund_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES funds (id) ON DELETE CASCADE'),
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, month, categoryId, fundId, amount];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budget_lines';
  @override
  VerificationContext validateIntegrity(Insertable<BudgetLine> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('month')) {
      context.handle(_monthMeta, month.isAcceptableOrUnknown(data['month']!, _monthMeta));
    } else if (isInserting) {
      context.missing(_monthMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(_categoryIdMeta, categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta));
    }
    if (data.containsKey('fund_id')) {
      context.handle(_fundIdMeta, fundId.isAcceptableOrUnknown(data['fund_id']!, _fundIdMeta));
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta, amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BudgetLine map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BudgetLine(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      month: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}month'])!,
      categoryId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}category_id']),
      fundId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}fund_id']),
      amount: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
    );
  }

  @override
  $BudgetLinesTable createAlias(String alias) {
    return $BudgetLinesTable(attachedDatabase, alias);
  }
}

class BudgetLine extends DataClass implements Insertable<BudgetLine> {
  final int id;

  /// Месяц как yyyymm, например 202611.
  final int month;
  final int? categoryId;
  final int? fundId;
  final double amount;
  const BudgetLine({required this.id, required this.month, this.categoryId, this.fundId, required this.amount});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['month'] = Variable<int>(month);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    if (!nullToAbsent || fundId != null) {
      map['fund_id'] = Variable<int>(fundId);
    }
    map['amount'] = Variable<double>(amount);
    return map;
  }

  BudgetLinesCompanion toCompanion(bool nullToAbsent) {
    return BudgetLinesCompanion(
      id: Value(id),
      month: Value(month),
      categoryId: categoryId == null && nullToAbsent ? const Value.absent() : Value(categoryId),
      fundId: fundId == null && nullToAbsent ? const Value.absent() : Value(fundId),
      amount: Value(amount),
    );
  }

  factory BudgetLine.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BudgetLine(
      id: serializer.fromJson<int>(json['id']),
      month: serializer.fromJson<int>(json['month']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
      fundId: serializer.fromJson<int?>(json['fundId']),
      amount: serializer.fromJson<double>(json['amount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'month': serializer.toJson<int>(month),
      'categoryId': serializer.toJson<int?>(categoryId),
      'fundId': serializer.toJson<int?>(fundId),
      'amount': serializer.toJson<double>(amount),
    };
  }

  BudgetLine copyWith({
    int? id,
    int? month,
    Value<int?> categoryId = const Value.absent(),
    Value<int?> fundId = const Value.absent(),
    double? amount,
  }) => BudgetLine(
    id: id ?? this.id,
    month: month ?? this.month,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    fundId: fundId.present ? fundId.value : this.fundId,
    amount: amount ?? this.amount,
  );
  BudgetLine copyWithCompanion(BudgetLinesCompanion data) {
    return BudgetLine(
      id: data.id.present ? data.id.value : this.id,
      month: data.month.present ? data.month.value : this.month,
      categoryId: data.categoryId.present ? data.categoryId.value : this.categoryId,
      fundId: data.fundId.present ? data.fundId.value : this.fundId,
      amount: data.amount.present ? data.amount.value : this.amount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BudgetLine(')
          ..write('id: $id, ')
          ..write('month: $month, ')
          ..write('categoryId: $categoryId, ')
          ..write('fundId: $fundId, ')
          ..write('amount: $amount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, month, categoryId, fundId, amount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BudgetLine &&
          other.id == this.id &&
          other.month == this.month &&
          other.categoryId == this.categoryId &&
          other.fundId == this.fundId &&
          other.amount == this.amount);
}

class BudgetLinesCompanion extends UpdateCompanion<BudgetLine> {
  final Value<int> id;
  final Value<int> month;
  final Value<int?> categoryId;
  final Value<int?> fundId;
  final Value<double> amount;
  const BudgetLinesCompanion({
    this.id = const Value.absent(),
    this.month = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.fundId = const Value.absent(),
    this.amount = const Value.absent(),
  });
  BudgetLinesCompanion.insert({
    this.id = const Value.absent(),
    required int month,
    this.categoryId = const Value.absent(),
    this.fundId = const Value.absent(),
    required double amount,
  }) : month = Value(month),
       amount = Value(amount);
  static Insertable<BudgetLine> custom({
    Expression<int>? id,
    Expression<int>? month,
    Expression<int>? categoryId,
    Expression<int>? fundId,
    Expression<double>? amount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (month != null) 'month': month,
      if (categoryId != null) 'category_id': categoryId,
      if (fundId != null) 'fund_id': fundId,
      if (amount != null) 'amount': amount,
    });
  }

  BudgetLinesCompanion copyWith({Value<int>? id, Value<int>? month, Value<int?>? categoryId, Value<int?>? fundId, Value<double>? amount}) {
    return BudgetLinesCompanion(
      id: id ?? this.id,
      month: month ?? this.month,
      categoryId: categoryId ?? this.categoryId,
      fundId: fundId ?? this.fundId,
      amount: amount ?? this.amount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (month.present) {
      map['month'] = Variable<int>(month.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (fundId.present) {
      map['fund_id'] = Variable<int>(fundId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetLinesCompanion(')
          ..write('id: $id, ')
          ..write('month: $month, ')
          ..write('categoryId: $categoryId, ')
          ..write('fundId: $fundId, ')
          ..write('amount: $amount')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TrackersTable trackers = $TrackersTable(this);
  late final $TrackerEntriesTable trackerEntries = $TrackerEntriesTable(this);
  late final $HabitsTable habits = $HabitsTable(this);
  late final $HabitLogsTable habitLogs = $HabitLogsTable(this);
  late final $FundsTable funds = $FundsTable(this);
  late final $GoalsTable goals = $GoalsTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $FundMovesTable fundMoves = $FundMovesTable(this);
  late final $ProgramsTable programs = $ProgramsTable(this);
  late final $ProgramExercisesTable programExercises = $ProgramExercisesTable(this);
  late final $WorkoutSessionsTable workoutSessions = $WorkoutSessionsTable(this);
  late final $SessionSetsTable sessionSets = $SessionSetsTable(this);
  late final $JournalEntriesTable journalEntries = $JournalEntriesTable(this);
  late final $RemindersTable reminders = $RemindersTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $SleepLogsTable sleepLogs = $SleepLogsTable(this);
  late final $FoodsTable foods = $FoodsTable(this);
  late final $MealsTable meals = $MealsTable(this);
  late final $WaterLogsTable waterLogs = $WaterLogsTable(this);
  late final $HardDaysTable hardDays = $HardDaysTable(this);
  late final $TimeBlocksTable timeBlocks = $TimeBlocksTable(this);
  late final $BudgetLinesTable budgetLines = $BudgetLinesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    trackers,
    trackerEntries,
    habits,
    habitLogs,
    funds,
    goals,
    categories,
    transactions,
    fundMoves,
    programs,
    programExercises,
    workoutSessions,
    sessionSets,
    journalEntries,
    reminders,
    settings,
    sleepLogs,
    foods,
    meals,
    waterLogs,
    hardDays,
    timeBlocks,
    budgetLines,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName('trackers', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('tracker_entries', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('trackers', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('habits', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('habits', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('habit_logs', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('trackers', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('goals', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('funds', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('goals', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('categories', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('transactions', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('funds', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('fund_moves', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('programs', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('program_exercises', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('programs', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('workout_sessions', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('workout_sessions', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('session_sets', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('program_exercises', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('session_sets', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('foods', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('meals', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('categories', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('budget_lines', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('funds', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('budget_lines', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$TrackersTableCreateCompanionBuilder = TrackersCompanion Function({
  Value<int> id,
  required String name,
  Value<String> icon,
  Value<String?> unit,
  required TrackerKind kind,
  Value<int> daysMask,
  Value<int?> reminderMinutes,
  Value<double?> dailyGoal,
  Value<double?> dailyMin,
  Value<bool> archived,
  Value<int> sortOrder,
  Value<DateTime> createdAt,
});
typedef $$TrackersTableUpdateCompanionBuilder = TrackersCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> icon,
  Value<String?> unit,
  Value<TrackerKind> kind,
  Value<int> daysMask,
  Value<int?> reminderMinutes,
  Value<double?> dailyGoal,
  Value<double?> dailyMin,
  Value<bool> archived,
  Value<int> sortOrder,
  Value<DateTime> createdAt,
});

final class $$TrackersTableReferences extends BaseReferences<_$AppDatabase, $TrackersTable, Tracker> {
  $$TrackersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TrackerEntriesTable, List<TrackerEntry>> _trackerEntriesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.trackerEntries, aliasName: 'trackers__id__tracker_entries__tracker_id');

  $$TrackerEntriesTableProcessedTableManager get trackerEntriesRefs {
    final manager = $$TrackerEntriesTableTableManager(
      $_db,
      $_db.trackerEntries,
    ).filter((f) => f.trackerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_trackerEntriesRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$HabitsTable, List<Habit>> _habitsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.habits, aliasName: 'trackers__id__habits__tracker_id');

  $$HabitsTableProcessedTableManager get habitsRefs {
    final manager = $$HabitsTableTableManager($_db, $_db.habits).filter((f) => f.trackerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_habitsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$GoalsTable, List<Goal>> _goalsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.goals, aliasName: 'trackers__id__goals__tracker_id');

  $$GoalsTableProcessedTableManager get goalsRefs {
    final manager = $$GoalsTableTableManager($_db, $_db.goals).filter((f) => f.trackerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_goalsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$TrackersTableFilterComposer extends Composer<_$AppDatabase, $TrackersTable> {
  $$TrackersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get icon => $composableBuilder(column: $table.icon, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unit => $composableBuilder(column: $table.unit, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<TrackerKind, TrackerKind, int> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get daysMask => $composableBuilder(column: $table.daysMask, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reminderMinutes => $composableBuilder(column: $table.reminderMinutes, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get dailyGoal => $composableBuilder(column: $table.dailyGoal, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get dailyMin => $composableBuilder(column: $table.dailyMin, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get archived => $composableBuilder(column: $table.archived, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> trackerEntriesRefs(Expression<bool> Function($$TrackerEntriesTableFilterComposer f) f) {
    final $$TrackerEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trackerEntries,
      getReferencedColumn: (t) => t.trackerId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$TrackerEntriesTableFilterComposer(
        $db: $db,
        $table: $db.trackerEntries,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return f(composer);
  }

  Expression<bool> habitsRefs(Expression<bool> Function($$HabitsTableFilterComposer f) f) {
    final $$HabitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.trackerId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$HabitsTableFilterComposer(
        $db: $db,
        $table: $db.habits,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return f(composer);
  }

  Expression<bool> goalsRefs(Expression<bool> Function($$GoalsTableFilterComposer f) f) {
    final $$GoalsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.goals,
      getReferencedColumn: (t) => t.trackerId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$GoalsTableFilterComposer(
        $db: $db,
        $table: $db.goals,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return f(composer);
  }
}

class $$TrackersTableOrderingComposer extends Composer<_$AppDatabase, $TrackersTable> {
  $$TrackersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get icon => $composableBuilder(column: $table.icon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unit => $composableBuilder(column: $table.unit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get kind => $composableBuilder(column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get daysMask => $composableBuilder(column: $table.daysMask, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reminderMinutes =>
      $composableBuilder(column: $table.reminderMinutes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get dailyGoal => $composableBuilder(column: $table.dailyGoal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get dailyMin => $composableBuilder(column: $table.dailyMin, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get archived => $composableBuilder(column: $table.archived, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$TrackersTableAnnotationComposer extends Composer<_$AppDatabase, $TrackersTable> {
  $$TrackersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get icon => $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<String> get unit => $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TrackerKind, int> get kind => $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get daysMask => $composableBuilder(column: $table.daysMask, builder: (column) => column);

  GeneratedColumn<int> get reminderMinutes => $composableBuilder(column: $table.reminderMinutes, builder: (column) => column);

  GeneratedColumn<double> get dailyGoal => $composableBuilder(column: $table.dailyGoal, builder: (column) => column);

  GeneratedColumn<double> get dailyMin => $composableBuilder(column: $table.dailyMin, builder: (column) => column);

  GeneratedColumn<bool> get archived => $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> trackerEntriesRefs<T extends Object>(Expression<T> Function($$TrackerEntriesTableAnnotationComposer a) f) {
    final $$TrackerEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.trackerEntries,
      getReferencedColumn: (t) => t.trackerId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TrackerEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.trackerEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> habitsRefs<T extends Object>(Expression<T> Function($$HabitsTableAnnotationComposer a) f) {
    final $$HabitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.trackerId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$HabitsTableAnnotationComposer(
        $db: $db,
        $table: $db.habits,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return f(composer);
  }

  Expression<T> goalsRefs<T extends Object>(Expression<T> Function($$GoalsTableAnnotationComposer a) f) {
    final $$GoalsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.goals,
      getReferencedColumn: (t) => t.trackerId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$GoalsTableAnnotationComposer(
        $db: $db,
        $table: $db.goals,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return f(composer);
  }
}

class $$TrackersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TrackersTable,
          Tracker,
          $$TrackersTableFilterComposer,
          $$TrackersTableOrderingComposer,
          $$TrackersTableAnnotationComposer,
          $$TrackersTableCreateCompanionBuilder,
          $$TrackersTableUpdateCompanionBuilder,
          (Tracker, $$TrackersTableReferences),
          Tracker,
          PrefetchHooks Function({bool trackerEntriesRefs, bool habitsRefs, bool goalsRefs})
        > {
  $$TrackersTableTableManager(_$AppDatabase db, $TrackersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$TrackersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$TrackersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$TrackersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> icon = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<TrackerKind> kind = const Value.absent(),
                Value<int> daysMask = const Value.absent(),
                Value<int?> reminderMinutes = const Value.absent(),
                Value<double?> dailyGoal = const Value.absent(),
                Value<double?> dailyMin = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => TrackersCompanion(
                id: id,
                name: name,
                icon: icon,
                unit: unit,
                kind: kind,
                daysMask: daysMask,
                reminderMinutes: reminderMinutes,
                dailyGoal: dailyGoal,
                dailyMin: dailyMin,
                archived: archived,
                sortOrder: sortOrder,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String> icon = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                required TrackerKind kind,
                Value<int> daysMask = const Value.absent(),
                Value<int?> reminderMinutes = const Value.absent(),
                Value<double?> dailyGoal = const Value.absent(),
                Value<double?> dailyMin = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => TrackersCompanion.insert(
                id: id,
                name: name,
                icon: icon,
                unit: unit,
                kind: kind,
                daysMask: daysMask,
                reminderMinutes: reminderMinutes,
                dailyGoal: dailyGoal,
                dailyMin: dailyMin,
                archived: archived,
                sortOrder: sortOrder,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable<$TrackersTable, Tracker>(table), $$TrackersTableReferences(db, table, e))).toList(),
          prefetchHooksCallback: ({trackerEntriesRefs = false, habitsRefs = false, goalsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (trackerEntriesRefs) db.trackerEntries, if (habitsRefs) db.habits, if (goalsRefs) db.goals],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (trackerEntriesRefs)
                    await $_getPrefetchedDataByColumns<Tracker, $TrackersTable, TrackerEntry, $TrackerEntriesTable>(
                      currentTable: table,
                      referencedTable: $$TrackersTableReferences._trackerEntriesRefsTable(db),
                      managerFromTypedResult: (p0) => $$TrackersTableReferences(db, table, p0).trackerEntriesRefs,
                      currentColumn: 'id',
                      referencedColumn: 'tracker_id',
                      typedResults: items,
                    ),
                  if (habitsRefs)
                    await $_getPrefetchedDataByColumns<Tracker, $TrackersTable, Habit, $HabitsTable>(
                      currentTable: table,
                      referencedTable: $$TrackersTableReferences._habitsRefsTable(db),
                      managerFromTypedResult: (p0) => $$TrackersTableReferences(db, table, p0).habitsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'tracker_id',
                      typedResults: items,
                    ),
                  if (goalsRefs)
                    await $_getPrefetchedDataByColumns<Tracker, $TrackersTable, Goal, $GoalsTable>(
                      currentTable: table,
                      referencedTable: $$TrackersTableReferences._goalsRefsTable(db),
                      managerFromTypedResult: (p0) => $$TrackersTableReferences(db, table, p0).goalsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'tracker_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TrackersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TrackersTable,
      Tracker,
      $$TrackersTableFilterComposer,
      $$TrackersTableOrderingComposer,
      $$TrackersTableAnnotationComposer,
      $$TrackersTableCreateCompanionBuilder,
      $$TrackersTableUpdateCompanionBuilder,
      (Tracker, $$TrackersTableReferences),
      Tracker,
      PrefetchHooks Function({bool trackerEntriesRefs, bool habitsRefs, bool goalsRefs})
    >;
typedef $$TrackerEntriesTableCreateCompanionBuilder = TrackerEntriesCompanion Function({
  Value<int> id,
  required int trackerId,
  required int day,
  Value<DateTime> at,
  required double value,
  Value<String?> note,
});
typedef $$TrackerEntriesTableUpdateCompanionBuilder = TrackerEntriesCompanion Function({
  Value<int> id,
  Value<int> trackerId,
  Value<int> day,
  Value<DateTime> at,
  Value<double> value,
  Value<String?> note,
});

final class $$TrackerEntriesTableReferences extends BaseReferences<_$AppDatabase, $TrackerEntriesTable, TrackerEntry> {
  $$TrackerEntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TrackersTable _trackerIdTable(_$AppDatabase db) => db.trackers.createAlias('tracker_entries__tracker_id__trackers__id');

  $$TrackersTableProcessedTableManager get trackerId {
    final $_column = $_itemColumn<int>('tracker_id')!;

    final manager = $$TrackersTableTableManager($_db, $_db.trackers).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_trackerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$TrackerEntriesTableFilterComposer extends Composer<_$AppDatabase, $TrackerEntriesTable> {
  $$TrackerEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get day => $composableBuilder(column: $table.day, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get at => $composableBuilder(column: $table.at, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get value => $composableBuilder(column: $table.value, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(column: $table.note, builder: (column) => ColumnFilters(column));

  $$TrackersTableFilterComposer get trackerId {
    final $$TrackersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackerId,
      referencedTable: $db.trackers,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$TrackersTableFilterComposer(
        $db: $db,
        $table: $db.trackers,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }
}

class $$TrackerEntriesTableOrderingComposer extends Composer<_$AppDatabase, $TrackerEntriesTable> {
  $$TrackerEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get day => $composableBuilder(column: $table.day, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get at => $composableBuilder(column: $table.at, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get value => $composableBuilder(column: $table.value, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(column: $table.note, builder: (column) => ColumnOrderings(column));

  $$TrackersTableOrderingComposer get trackerId {
    final $$TrackersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackerId,
      referencedTable: $db.trackers,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$TrackersTableOrderingComposer(
        $db: $db,
        $table: $db.trackers,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }
}

class $$TrackerEntriesTableAnnotationComposer extends Composer<_$AppDatabase, $TrackerEntriesTable> {
  $$TrackerEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get day => $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<DateTime> get at => $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<double> get value => $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get note => $composableBuilder(column: $table.note, builder: (column) => column);

  $$TrackersTableAnnotationComposer get trackerId {
    final $$TrackersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackerId,
      referencedTable: $db.trackers,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$TrackersTableAnnotationComposer(
        $db: $db,
        $table: $db.trackers,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }
}

class $$TrackerEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TrackerEntriesTable,
          TrackerEntry,
          $$TrackerEntriesTableFilterComposer,
          $$TrackerEntriesTableOrderingComposer,
          $$TrackerEntriesTableAnnotationComposer,
          $$TrackerEntriesTableCreateCompanionBuilder,
          $$TrackerEntriesTableUpdateCompanionBuilder,
          (TrackerEntry, $$TrackerEntriesTableReferences),
          TrackerEntry,
          PrefetchHooks Function({bool trackerId})
        > {
  $$TrackerEntriesTableTableManager(_$AppDatabase db, $TrackerEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$TrackerEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$TrackerEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$TrackerEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> trackerId = const Value.absent(),
            Value<int> day = const Value.absent(),
            Value<DateTime> at = const Value.absent(),
            Value<double> value = const Value.absent(),
            Value<String?> note = const Value.absent(),
          }) => TrackerEntriesCompanion(id: id, trackerId: trackerId, day: day, at: at, value: value, note: note),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int trackerId,
            required int day,
            Value<DateTime> at = const Value.absent(),
            required double value,
            Value<String?> note = const Value.absent(),
          }) => TrackerEntriesCompanion.insert(id: id, trackerId: trackerId, day: day, at: at, value: value, note: note),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable<$TrackerEntriesTable, TrackerEntry>(table), $$TrackerEntriesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({trackerId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (trackerId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.trackerId,
                        referencedTable: $$TrackerEntriesTableReferences._trackerIdTable(db),
                        referencedColumn: $$TrackerEntriesTableReferences._trackerIdTable(db).id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TrackerEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TrackerEntriesTable,
      TrackerEntry,
      $$TrackerEntriesTableFilterComposer,
      $$TrackerEntriesTableOrderingComposer,
      $$TrackerEntriesTableAnnotationComposer,
      $$TrackerEntriesTableCreateCompanionBuilder,
      $$TrackerEntriesTableUpdateCompanionBuilder,
      (TrackerEntry, $$TrackerEntriesTableReferences),
      TrackerEntry,
      PrefetchHooks Function({bool trackerId})
    >;
typedef $$HabitsTableCreateCompanionBuilder = HabitsCompanion Function({
  Value<int> id,
  required String name,
  Value<String> icon,
  Value<int> daysMask,
  Value<int?> reminderMinutes,
  Value<String?> minimumText,
  Value<int?> trackerId,
  Value<bool> archived,
  Value<int> sortOrder,
  Value<DateTime> createdAt,
});
typedef $$HabitsTableUpdateCompanionBuilder = HabitsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> icon,
  Value<int> daysMask,
  Value<int?> reminderMinutes,
  Value<String?> minimumText,
  Value<int?> trackerId,
  Value<bool> archived,
  Value<int> sortOrder,
  Value<DateTime> createdAt,
});

final class $$HabitsTableReferences extends BaseReferences<_$AppDatabase, $HabitsTable, Habit> {
  $$HabitsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TrackersTable _trackerIdTable(_$AppDatabase db) => db.trackers.createAlias('habits__tracker_id__trackers__id');

  $$TrackersTableProcessedTableManager? get trackerId {
    final $_column = $_itemColumn<int>('tracker_id');
    if ($_column == null) return null;
    final manager = $$TrackersTableTableManager($_db, $_db.trackers).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_trackerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$HabitLogsTable, List<HabitLog>> _habitLogsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.habitLogs, aliasName: 'habits__id__habit_logs__habit_id');

  $$HabitLogsTableProcessedTableManager get habitLogsRefs {
    final manager = $$HabitLogsTableTableManager($_db, $_db.habitLogs).filter((f) => f.habitId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_habitLogsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$HabitsTableFilterComposer extends Composer<_$AppDatabase, $HabitsTable> {
  $$HabitsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get icon => $composableBuilder(column: $table.icon, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get daysMask => $composableBuilder(column: $table.daysMask, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reminderMinutes => $composableBuilder(column: $table.reminderMinutes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get minimumText => $composableBuilder(column: $table.minimumText, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get archived => $composableBuilder(column: $table.archived, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$TrackersTableFilterComposer get trackerId {
    final $$TrackersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackerId,
      referencedTable: $db.trackers,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$TrackersTableFilterComposer(
        $db: $db,
        $table: $db.trackers,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }

  Expression<bool> habitLogsRefs(Expression<bool> Function($$HabitLogsTableFilterComposer f) f) {
    final $$HabitLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.habitLogs,
      getReferencedColumn: (t) => t.habitId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$HabitLogsTableFilterComposer(
        $db: $db,
        $table: $db.habitLogs,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return f(composer);
  }
}

class $$HabitsTableOrderingComposer extends Composer<_$AppDatabase, $HabitsTable> {
  $$HabitsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get icon => $composableBuilder(column: $table.icon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get daysMask => $composableBuilder(column: $table.daysMask, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reminderMinutes =>
      $composableBuilder(column: $table.reminderMinutes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get minimumText => $composableBuilder(column: $table.minimumText, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get archived => $composableBuilder(column: $table.archived, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$TrackersTableOrderingComposer get trackerId {
    final $$TrackersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackerId,
      referencedTable: $db.trackers,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$TrackersTableOrderingComposer(
        $db: $db,
        $table: $db.trackers,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }
}

class $$HabitsTableAnnotationComposer extends Composer<_$AppDatabase, $HabitsTable> {
  $$HabitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get icon => $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<int> get daysMask => $composableBuilder(column: $table.daysMask, builder: (column) => column);

  GeneratedColumn<int> get reminderMinutes => $composableBuilder(column: $table.reminderMinutes, builder: (column) => column);

  GeneratedColumn<String> get minimumText => $composableBuilder(column: $table.minimumText, builder: (column) => column);

  GeneratedColumn<bool> get archived => $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$TrackersTableAnnotationComposer get trackerId {
    final $$TrackersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackerId,
      referencedTable: $db.trackers,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$TrackersTableAnnotationComposer(
        $db: $db,
        $table: $db.trackers,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }

  Expression<T> habitLogsRefs<T extends Object>(Expression<T> Function($$HabitLogsTableAnnotationComposer a) f) {
    final $$HabitLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.habitLogs,
      getReferencedColumn: (t) => t.habitId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$HabitLogsTableAnnotationComposer(
        $db: $db,
        $table: $db.habitLogs,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return f(composer);
  }
}

class $$HabitsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HabitsTable,
          Habit,
          $$HabitsTableFilterComposer,
          $$HabitsTableOrderingComposer,
          $$HabitsTableAnnotationComposer,
          $$HabitsTableCreateCompanionBuilder,
          $$HabitsTableUpdateCompanionBuilder,
          (Habit, $$HabitsTableReferences),
          Habit,
          PrefetchHooks Function({bool trackerId, bool habitLogsRefs})
        > {
  $$HabitsTableTableManager(_$AppDatabase db, $HabitsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$HabitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$HabitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$HabitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> icon = const Value.absent(),
                Value<int> daysMask = const Value.absent(),
                Value<int?> reminderMinutes = const Value.absent(),
                Value<String?> minimumText = const Value.absent(),
                Value<int?> trackerId = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => HabitsCompanion(
                id: id,
                name: name,
                icon: icon,
                daysMask: daysMask,
                reminderMinutes: reminderMinutes,
                minimumText: minimumText,
                trackerId: trackerId,
                archived: archived,
                sortOrder: sortOrder,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String> icon = const Value.absent(),
                Value<int> daysMask = const Value.absent(),
                Value<int?> reminderMinutes = const Value.absent(),
                Value<String?> minimumText = const Value.absent(),
                Value<int?> trackerId = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => HabitsCompanion.insert(
                id: id,
                name: name,
                icon: icon,
                daysMask: daysMask,
                reminderMinutes: reminderMinutes,
                minimumText: minimumText,
                trackerId: trackerId,
                archived: archived,
                sortOrder: sortOrder,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable<$HabitsTable, Habit>(table), $$HabitsTableReferences(db, table, e))).toList(),
          prefetchHooksCallback: ({trackerId = false, habitLogsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (habitLogsRefs) db.habitLogs],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (trackerId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.trackerId,
                        referencedTable: $$HabitsTableReferences._trackerIdTable(db),
                        referencedColumn: $$HabitsTableReferences._trackerIdTable(db).id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (habitLogsRefs)
                    await $_getPrefetchedDataByColumns<Habit, $HabitsTable, HabitLog, $HabitLogsTable>(
                      currentTable: table,
                      referencedTable: $$HabitsTableReferences._habitLogsRefsTable(db),
                      managerFromTypedResult: (p0) => $$HabitsTableReferences(db, table, p0).habitLogsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'habit_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$HabitsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HabitsTable,
      Habit,
      $$HabitsTableFilterComposer,
      $$HabitsTableOrderingComposer,
      $$HabitsTableAnnotationComposer,
      $$HabitsTableCreateCompanionBuilder,
      $$HabitsTableUpdateCompanionBuilder,
      (Habit, $$HabitsTableReferences),
      Habit,
      PrefetchHooks Function({bool trackerId, bool habitLogsRefs})
    >;
typedef $$HabitLogsTableCreateCompanionBuilder = HabitLogsCompanion Function({
  Value<int> id,
  required int habitId,
  required int day,
  Value<bool> minimum,
});
typedef $$HabitLogsTableUpdateCompanionBuilder = HabitLogsCompanion Function({
  Value<int> id,
  Value<int> habitId,
  Value<int> day,
  Value<bool> minimum,
});

final class $$HabitLogsTableReferences extends BaseReferences<_$AppDatabase, $HabitLogsTable, HabitLog> {
  $$HabitLogsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $HabitsTable _habitIdTable(_$AppDatabase db) => db.habits.createAlias('habit_logs__habit_id__habits__id');

  $$HabitsTableProcessedTableManager get habitId {
    final $_column = $_itemColumn<int>('habit_id')!;

    final manager = $$HabitsTableTableManager($_db, $_db.habits).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_habitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$HabitLogsTableFilterComposer extends Composer<_$AppDatabase, $HabitLogsTable> {
  $$HabitLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get day => $composableBuilder(column: $table.day, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get minimum => $composableBuilder(column: $table.minimum, builder: (column) => ColumnFilters(column));

  $$HabitsTableFilterComposer get habitId {
    final $$HabitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$HabitsTableFilterComposer(
        $db: $db,
        $table: $db.habits,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }
}

class $$HabitLogsTableOrderingComposer extends Composer<_$AppDatabase, $HabitLogsTable> {
  $$HabitLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get day => $composableBuilder(column: $table.day, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get minimum => $composableBuilder(column: $table.minimum, builder: (column) => ColumnOrderings(column));

  $$HabitsTableOrderingComposer get habitId {
    final $$HabitsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$HabitsTableOrderingComposer(
        $db: $db,
        $table: $db.habits,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }
}

class $$HabitLogsTableAnnotationComposer extends Composer<_$AppDatabase, $HabitLogsTable> {
  $$HabitLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get day => $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<bool> get minimum => $composableBuilder(column: $table.minimum, builder: (column) => column);

  $$HabitsTableAnnotationComposer get habitId {
    final $$HabitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$HabitsTableAnnotationComposer(
        $db: $db,
        $table: $db.habits,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }
}

class $$HabitLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HabitLogsTable,
          HabitLog,
          $$HabitLogsTableFilterComposer,
          $$HabitLogsTableOrderingComposer,
          $$HabitLogsTableAnnotationComposer,
          $$HabitLogsTableCreateCompanionBuilder,
          $$HabitLogsTableUpdateCompanionBuilder,
          (HabitLog, $$HabitLogsTableReferences),
          HabitLog,
          PrefetchHooks Function({bool habitId})
        > {
  $$HabitLogsTableTableManager(_$AppDatabase db, $HabitLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$HabitLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$HabitLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$HabitLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> habitId = const Value.absent(),
            Value<int> day = const Value.absent(),
            Value<bool> minimum = const Value.absent(),
          }) => HabitLogsCompanion(id: id, habitId: habitId, day: day, minimum: minimum),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int habitId,
            required int day,
            Value<bool> minimum = const Value.absent(),
          }) => HabitLogsCompanion.insert(id: id, habitId: habitId, day: day, minimum: minimum),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable<$HabitLogsTable, HabitLog>(table), $$HabitLogsTableReferences(db, table, e))).toList(),
          prefetchHooksCallback: ({habitId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (habitId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.habitId,
                        referencedTable: $$HabitLogsTableReferences._habitIdTable(db),
                        referencedColumn: $$HabitLogsTableReferences._habitIdTable(db).id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$HabitLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HabitLogsTable,
      HabitLog,
      $$HabitLogsTableFilterComposer,
      $$HabitLogsTableOrderingComposer,
      $$HabitLogsTableAnnotationComposer,
      $$HabitLogsTableCreateCompanionBuilder,
      $$HabitLogsTableUpdateCompanionBuilder,
      (HabitLog, $$HabitLogsTableReferences),
      HabitLog,
      PrefetchHooks Function({bool habitId})
    >;
typedef $$FundsTableCreateCompanionBuilder = FundsCompanion Function({
  Value<int> id,
  required String name,
  Value<String> icon,
  required FundKind kind,
  Value<double> initialAmount,
  Value<double?> target,
  Value<double?> interestRate,
  Value<double?> monthlyAmount,
  Value<bool> archived,
  Value<int> sortOrder,
  Value<DateTime> createdAt,
});
typedef $$FundsTableUpdateCompanionBuilder = FundsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> icon,
  Value<FundKind> kind,
  Value<double> initialAmount,
  Value<double?> target,
  Value<double?> interestRate,
  Value<double?> monthlyAmount,
  Value<bool> archived,
  Value<int> sortOrder,
  Value<DateTime> createdAt,
});

final class $$FundsTableReferences extends BaseReferences<_$AppDatabase, $FundsTable, Fund> {
  $$FundsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$GoalsTable, List<Goal>> _goalsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.goals, aliasName: 'funds__id__goals__fund_id');

  $$GoalsTableProcessedTableManager get goalsRefs {
    final manager = $$GoalsTableTableManager($_db, $_db.goals).filter((f) => f.fundId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_goalsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$FundMovesTable, List<FundMove>> _fundMovesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.fundMoves, aliasName: 'funds__id__fund_moves__fund_id');

  $$FundMovesTableProcessedTableManager get fundMovesRefs {
    final manager = $$FundMovesTableTableManager($_db, $_db.fundMoves).filter((f) => f.fundId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_fundMovesRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$BudgetLinesTable, List<BudgetLine>> _budgetLinesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.budgetLines, aliasName: 'funds__id__budget_lines__fund_id');

  $$BudgetLinesTableProcessedTableManager get budgetLinesRefs {
    final manager = $$BudgetLinesTableTableManager($_db, $_db.budgetLines).filter((f) => f.fundId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_budgetLinesRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$FundsTableFilterComposer extends Composer<_$AppDatabase, $FundsTable> {
  $$FundsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get icon => $composableBuilder(column: $table.icon, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<FundKind, FundKind, int> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<double> get initialAmount => $composableBuilder(column: $table.initialAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get target => $composableBuilder(column: $table.target, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get interestRate => $composableBuilder(column: $table.interestRate, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get monthlyAmount => $composableBuilder(column: $table.monthlyAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get archived => $composableBuilder(column: $table.archived, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> goalsRefs(Expression<bool> Function($$GoalsTableFilterComposer f) f) {
    final $$GoalsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.goals,
      getReferencedColumn: (t) => t.fundId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$GoalsTableFilterComposer(
        $db: $db,
        $table: $db.goals,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return f(composer);
  }

  Expression<bool> fundMovesRefs(Expression<bool> Function($$FundMovesTableFilterComposer f) f) {
    final $$FundMovesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.fundMoves,
      getReferencedColumn: (t) => t.fundId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$FundMovesTableFilterComposer(
        $db: $db,
        $table: $db.fundMoves,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return f(composer);
  }

  Expression<bool> budgetLinesRefs(Expression<bool> Function($$BudgetLinesTableFilterComposer f) f) {
    final $$BudgetLinesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.budgetLines,
      getReferencedColumn: (t) => t.fundId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$BudgetLinesTableFilterComposer(
        $db: $db,
        $table: $db.budgetLines,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return f(composer);
  }
}

class $$FundsTableOrderingComposer extends Composer<_$AppDatabase, $FundsTable> {
  $$FundsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get icon => $composableBuilder(column: $table.icon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get kind => $composableBuilder(column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get initialAmount =>
      $composableBuilder(column: $table.initialAmount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get target => $composableBuilder(column: $table.target, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get interestRate => $composableBuilder(column: $table.interestRate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get monthlyAmount =>
      $composableBuilder(column: $table.monthlyAmount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get archived => $composableBuilder(column: $table.archived, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$FundsTableAnnotationComposer extends Composer<_$AppDatabase, $FundsTable> {
  $$FundsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get icon => $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumnWithTypeConverter<FundKind, int> get kind => $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<double> get initialAmount => $composableBuilder(column: $table.initialAmount, builder: (column) => column);

  GeneratedColumn<double> get target => $composableBuilder(column: $table.target, builder: (column) => column);

  GeneratedColumn<double> get interestRate => $composableBuilder(column: $table.interestRate, builder: (column) => column);

  GeneratedColumn<double> get monthlyAmount => $composableBuilder(column: $table.monthlyAmount, builder: (column) => column);

  GeneratedColumn<bool> get archived => $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> goalsRefs<T extends Object>(Expression<T> Function($$GoalsTableAnnotationComposer a) f) {
    final $$GoalsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.goals,
      getReferencedColumn: (t) => t.fundId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$GoalsTableAnnotationComposer(
        $db: $db,
        $table: $db.goals,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return f(composer);
  }

  Expression<T> fundMovesRefs<T extends Object>(Expression<T> Function($$FundMovesTableAnnotationComposer a) f) {
    final $$FundMovesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.fundMoves,
      getReferencedColumn: (t) => t.fundId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$FundMovesTableAnnotationComposer(
        $db: $db,
        $table: $db.fundMoves,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return f(composer);
  }

  Expression<T> budgetLinesRefs<T extends Object>(Expression<T> Function($$BudgetLinesTableAnnotationComposer a) f) {
    final $$BudgetLinesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.budgetLines,
      getReferencedColumn: (t) => t.fundId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$BudgetLinesTableAnnotationComposer(
        $db: $db,
        $table: $db.budgetLines,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return f(composer);
  }
}

class $$FundsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FundsTable,
          Fund,
          $$FundsTableFilterComposer,
          $$FundsTableOrderingComposer,
          $$FundsTableAnnotationComposer,
          $$FundsTableCreateCompanionBuilder,
          $$FundsTableUpdateCompanionBuilder,
          (Fund, $$FundsTableReferences),
          Fund,
          PrefetchHooks Function({bool goalsRefs, bool fundMovesRefs, bool budgetLinesRefs})
        > {
  $$FundsTableTableManager(_$AppDatabase db, $FundsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$FundsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$FundsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$FundsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> icon = const Value.absent(),
                Value<FundKind> kind = const Value.absent(),
                Value<double> initialAmount = const Value.absent(),
                Value<double?> target = const Value.absent(),
                Value<double?> interestRate = const Value.absent(),
                Value<double?> monthlyAmount = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => FundsCompanion(
                id: id,
                name: name,
                icon: icon,
                kind: kind,
                initialAmount: initialAmount,
                target: target,
                interestRate: interestRate,
                monthlyAmount: monthlyAmount,
                archived: archived,
                sortOrder: sortOrder,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String> icon = const Value.absent(),
                required FundKind kind,
                Value<double> initialAmount = const Value.absent(),
                Value<double?> target = const Value.absent(),
                Value<double?> interestRate = const Value.absent(),
                Value<double?> monthlyAmount = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => FundsCompanion.insert(
                id: id,
                name: name,
                icon: icon,
                kind: kind,
                initialAmount: initialAmount,
                target: target,
                interestRate: interestRate,
                monthlyAmount: monthlyAmount,
                archived: archived,
                sortOrder: sortOrder,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable<$FundsTable, Fund>(table), $$FundsTableReferences(db, table, e))).toList(),
          prefetchHooksCallback: ({goalsRefs = false, fundMovesRefs = false, budgetLinesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (goalsRefs) db.goals, if (fundMovesRefs) db.fundMoves, if (budgetLinesRefs) db.budgetLines],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (goalsRefs)
                    await $_getPrefetchedDataByColumns<Fund, $FundsTable, Goal, $GoalsTable>(
                      currentTable: table,
                      referencedTable: $$FundsTableReferences._goalsRefsTable(db),
                      managerFromTypedResult: (p0) => $$FundsTableReferences(db, table, p0).goalsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'fund_id',
                      typedResults: items,
                    ),
                  if (fundMovesRefs)
                    await $_getPrefetchedDataByColumns<Fund, $FundsTable, FundMove, $FundMovesTable>(
                      currentTable: table,
                      referencedTable: $$FundsTableReferences._fundMovesRefsTable(db),
                      managerFromTypedResult: (p0) => $$FundsTableReferences(db, table, p0).fundMovesRefs,
                      currentColumn: 'id',
                      referencedColumn: 'fund_id',
                      typedResults: items,
                    ),
                  if (budgetLinesRefs)
                    await $_getPrefetchedDataByColumns<Fund, $FundsTable, BudgetLine, $BudgetLinesTable>(
                      currentTable: table,
                      referencedTable: $$FundsTableReferences._budgetLinesRefsTable(db),
                      managerFromTypedResult: (p0) => $$FundsTableReferences(db, table, p0).budgetLinesRefs,
                      currentColumn: 'id',
                      referencedColumn: 'fund_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$FundsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FundsTable,
      Fund,
      $$FundsTableFilterComposer,
      $$FundsTableOrderingComposer,
      $$FundsTableAnnotationComposer,
      $$FundsTableCreateCompanionBuilder,
      $$FundsTableUpdateCompanionBuilder,
      (Fund, $$FundsTableReferences),
      Fund,
      PrefetchHooks Function({bool goalsRefs, bool fundMovesRefs, bool budgetLinesRefs})
    >;
typedef $$GoalsTableCreateCompanionBuilder = GoalsCompanion Function({
  Value<int> id,
  required String name,
  required GoalKind kind,
  Value<int?> trackerId,
  Value<int?> fundId,
  required double startValue,
  required double targetValue,
  Value<double?> minimumValue,
  Value<int?> deadline,
  required int startDay,
  Value<bool> archived,
  Value<int> sortOrder,
});
typedef $$GoalsTableUpdateCompanionBuilder = GoalsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<GoalKind> kind,
  Value<int?> trackerId,
  Value<int?> fundId,
  Value<double> startValue,
  Value<double> targetValue,
  Value<double?> minimumValue,
  Value<int?> deadline,
  Value<int> startDay,
  Value<bool> archived,
  Value<int> sortOrder,
});

final class $$GoalsTableReferences extends BaseReferences<_$AppDatabase, $GoalsTable, Goal> {
  $$GoalsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TrackersTable _trackerIdTable(_$AppDatabase db) => db.trackers.createAlias('goals__tracker_id__trackers__id');

  $$TrackersTableProcessedTableManager? get trackerId {
    final $_column = $_itemColumn<int>('tracker_id');
    if ($_column == null) return null;
    final manager = $$TrackersTableTableManager($_db, $_db.trackers).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_trackerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static $FundsTable _fundIdTable(_$AppDatabase db) => db.funds.createAlias('goals__fund_id__funds__id');

  $$FundsTableProcessedTableManager? get fundId {
    final $_column = $_itemColumn<int>('fund_id');
    if ($_column == null) return null;
    final manager = $$FundsTableTableManager($_db, $_db.funds).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_fundIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$GoalsTableFilterComposer extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<GoalKind, GoalKind, int> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<double> get startValue => $composableBuilder(column: $table.startValue, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get targetValue => $composableBuilder(column: $table.targetValue, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get minimumValue => $composableBuilder(column: $table.minimumValue, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get deadline => $composableBuilder(column: $table.deadline, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get startDay => $composableBuilder(column: $table.startDay, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get archived => $composableBuilder(column: $table.archived, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  $$TrackersTableFilterComposer get trackerId {
    final $$TrackersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackerId,
      referencedTable: $db.trackers,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$TrackersTableFilterComposer(
        $db: $db,
        $table: $db.trackers,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }

  $$FundsTableFilterComposer get fundId {
    final $$FundsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fundId,
      referencedTable: $db.funds,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$FundsTableFilterComposer(
        $db: $db,
        $table: $db.funds,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }
}

class $$GoalsTableOrderingComposer extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get kind => $composableBuilder(column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get startValue => $composableBuilder(column: $table.startValue, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get targetValue => $composableBuilder(column: $table.targetValue, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get minimumValue => $composableBuilder(column: $table.minimumValue, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deadline => $composableBuilder(column: $table.deadline, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get startDay => $composableBuilder(column: $table.startDay, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get archived => $composableBuilder(column: $table.archived, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  $$TrackersTableOrderingComposer get trackerId {
    final $$TrackersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackerId,
      referencedTable: $db.trackers,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$TrackersTableOrderingComposer(
        $db: $db,
        $table: $db.trackers,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }

  $$FundsTableOrderingComposer get fundId {
    final $$FundsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fundId,
      referencedTable: $db.funds,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$FundsTableOrderingComposer(
        $db: $db,
        $table: $db.funds,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }
}

class $$GoalsTableAnnotationComposer extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<GoalKind, int> get kind => $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<double> get startValue => $composableBuilder(column: $table.startValue, builder: (column) => column);

  GeneratedColumn<double> get targetValue => $composableBuilder(column: $table.targetValue, builder: (column) => column);

  GeneratedColumn<double> get minimumValue => $composableBuilder(column: $table.minimumValue, builder: (column) => column);

  GeneratedColumn<int> get deadline => $composableBuilder(column: $table.deadline, builder: (column) => column);

  GeneratedColumn<int> get startDay => $composableBuilder(column: $table.startDay, builder: (column) => column);

  GeneratedColumn<bool> get archived => $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$TrackersTableAnnotationComposer get trackerId {
    final $$TrackersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackerId,
      referencedTable: $db.trackers,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$TrackersTableAnnotationComposer(
        $db: $db,
        $table: $db.trackers,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }

  $$FundsTableAnnotationComposer get fundId {
    final $$FundsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fundId,
      referencedTable: $db.funds,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$FundsTableAnnotationComposer(
        $db: $db,
        $table: $db.funds,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }
}

class $$GoalsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GoalsTable,
          Goal,
          $$GoalsTableFilterComposer,
          $$GoalsTableOrderingComposer,
          $$GoalsTableAnnotationComposer,
          $$GoalsTableCreateCompanionBuilder,
          $$GoalsTableUpdateCompanionBuilder,
          (Goal, $$GoalsTableReferences),
          Goal,
          PrefetchHooks Function({bool trackerId, bool fundId})
        > {
  $$GoalsTableTableManager(_$AppDatabase db, $GoalsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$GoalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$GoalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$GoalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<GoalKind> kind = const Value.absent(),
                Value<int?> trackerId = const Value.absent(),
                Value<int?> fundId = const Value.absent(),
                Value<double> startValue = const Value.absent(),
                Value<double> targetValue = const Value.absent(),
                Value<double?> minimumValue = const Value.absent(),
                Value<int?> deadline = const Value.absent(),
                Value<int> startDay = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => GoalsCompanion(
                id: id,
                name: name,
                kind: kind,
                trackerId: trackerId,
                fundId: fundId,
                startValue: startValue,
                targetValue: targetValue,
                minimumValue: minimumValue,
                deadline: deadline,
                startDay: startDay,
                archived: archived,
                sortOrder: sortOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required GoalKind kind,
                Value<int?> trackerId = const Value.absent(),
                Value<int?> fundId = const Value.absent(),
                required double startValue,
                required double targetValue,
                Value<double?> minimumValue = const Value.absent(),
                Value<int?> deadline = const Value.absent(),
                required int startDay,
                Value<bool> archived = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => GoalsCompanion.insert(
                id: id,
                name: name,
                kind: kind,
                trackerId: trackerId,
                fundId: fundId,
                startValue: startValue,
                targetValue: targetValue,
                minimumValue: minimumValue,
                deadline: deadline,
                startDay: startDay,
                archived: archived,
                sortOrder: sortOrder,
              ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable<$GoalsTable, Goal>(table), $$GoalsTableReferences(db, table, e))).toList(),
          prefetchHooksCallback: ({trackerId = false, fundId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (trackerId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.trackerId,
                        referencedTable: $$GoalsTableReferences._trackerIdTable(db),
                        referencedColumn: $$GoalsTableReferences._trackerIdTable(db).id,
                      ) as T;
                    }
                    if (fundId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.fundId,
                        referencedTable: $$GoalsTableReferences._fundIdTable(db),
                        referencedColumn: $$GoalsTableReferences._fundIdTable(db).id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$GoalsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GoalsTable,
      Goal,
      $$GoalsTableFilterComposer,
      $$GoalsTableOrderingComposer,
      $$GoalsTableAnnotationComposer,
      $$GoalsTableCreateCompanionBuilder,
      $$GoalsTableUpdateCompanionBuilder,
      (Goal, $$GoalsTableReferences),
      Goal,
      PrefetchHooks Function({bool trackerId, bool fundId})
    >;
typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  Value<int> id,
  required String name,
  Value<String> icon,
  Value<bool> isIncome,
  Value<double?> monthlyLimit,
  Value<bool> archived,
  Value<int> sortOrder,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> icon,
  Value<bool> isIncome,
  Value<double?> monthlyLimit,
  Value<bool> archived,
  Value<int> sortOrder,
});

final class $$CategoriesTableReferences extends BaseReferences<_$AppDatabase, $CategoriesTable, Category> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TransactionsTable, List<Transaction>> _transactionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.transactions, aliasName: 'categories__id__transactions__category_id');

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$BudgetLinesTable, List<BudgetLine>> _budgetLinesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.budgetLines, aliasName: 'categories__id__budget_lines__category_id');

  $$BudgetLinesTableProcessedTableManager get budgetLinesRefs {
    final manager = $$BudgetLinesTableTableManager(
      $_db,
      $_db.budgetLines,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_budgetLinesRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$CategoriesTableFilterComposer extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get icon => $composableBuilder(column: $table.icon, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isIncome => $composableBuilder(column: $table.isIncome, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get monthlyLimit => $composableBuilder(column: $table.monthlyLimit, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get archived => $composableBuilder(column: $table.archived, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  Expression<bool> transactionsRefs(Expression<bool> Function($$TransactionsTableFilterComposer f) f) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.categoryId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$TransactionsTableFilterComposer(
        $db: $db,
        $table: $db.transactions,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return f(composer);
  }

  Expression<bool> budgetLinesRefs(Expression<bool> Function($$BudgetLinesTableFilterComposer f) f) {
    final $$BudgetLinesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.budgetLines,
      getReferencedColumn: (t) => t.categoryId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$BudgetLinesTableFilterComposer(
        $db: $db,
        $table: $db.budgetLines,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return f(composer);
  }
}

class $$CategoriesTableOrderingComposer extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get icon => $composableBuilder(column: $table.icon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isIncome => $composableBuilder(column: $table.isIncome, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get monthlyLimit => $composableBuilder(column: $table.monthlyLimit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get archived => $composableBuilder(column: $table.archived, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnOrderings(column));
}

class $$CategoriesTableAnnotationComposer extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get icon => $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<bool> get isIncome => $composableBuilder(column: $table.isIncome, builder: (column) => column);

  GeneratedColumn<double> get monthlyLimit => $composableBuilder(column: $table.monthlyLimit, builder: (column) => column);

  GeneratedColumn<bool> get archived => $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  Expression<T> transactionsRefs<T extends Object>(Expression<T> Function($$TransactionsTableAnnotationComposer a) f) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.categoryId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$TransactionsTableAnnotationComposer(
        $db: $db,
        $table: $db.transactions,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return f(composer);
  }

  Expression<T> budgetLinesRefs<T extends Object>(Expression<T> Function($$BudgetLinesTableAnnotationComposer a) f) {
    final $$BudgetLinesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.budgetLines,
      getReferencedColumn: (t) => t.categoryId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$BudgetLinesTableAnnotationComposer(
        $db: $db,
        $table: $db.budgetLines,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return f(composer);
  }
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          Category,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (Category, $$CategoriesTableReferences),
          Category,
          PrefetchHooks Function({bool transactionsRefs, bool budgetLinesRefs})
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> icon = const Value.absent(),
                Value<bool> isIncome = const Value.absent(),
                Value<double?> monthlyLimit = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                name: name,
                icon: icon,
                isIncome: isIncome,
                monthlyLimit: monthlyLimit,
                archived: archived,
                sortOrder: sortOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String> icon = const Value.absent(),
                Value<bool> isIncome = const Value.absent(),
                Value<double?> monthlyLimit = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                name: name,
                icon: icon,
                isIncome: isIncome,
                monthlyLimit: monthlyLimit,
                archived: archived,
                sortOrder: sortOrder,
              ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable<$CategoriesTable, Category>(table), $$CategoriesTableReferences(db, table, e))).toList(),
          prefetchHooksCallback: ({transactionsRefs = false, budgetLinesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (transactionsRefs) db.transactions, if (budgetLinesRefs) db.budgetLines],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (transactionsRefs)
                    await $_getPrefetchedDataByColumns<Category, $CategoriesTable, Transaction, $TransactionsTable>(
                      currentTable: table,
                      referencedTable: $$CategoriesTableReferences._transactionsRefsTable(db),
                      managerFromTypedResult: (p0) => $$CategoriesTableReferences(db, table, p0).transactionsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'category_id',
                      typedResults: items,
                    ),
                  if (budgetLinesRefs)
                    await $_getPrefetchedDataByColumns<Category, $CategoriesTable, BudgetLine, $BudgetLinesTable>(
                      currentTable: table,
                      referencedTable: $$CategoriesTableReferences._budgetLinesRefsTable(db),
                      managerFromTypedResult: (p0) => $$CategoriesTableReferences(db, table, p0).budgetLinesRefs,
                      currentColumn: 'id',
                      referencedColumn: 'category_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      Category,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (Category, $$CategoriesTableReferences),
      Category,
      PrefetchHooks Function({bool transactionsRefs, bool budgetLinesRefs})
    >;
typedef $$TransactionsTableCreateCompanionBuilder = TransactionsCompanion Function({
  Value<int> id,
  required double amount,
  Value<bool> isIncome,
  Value<int?> categoryId,
  required int day,
  Value<DateTime> at,
  Value<String?> note,
});
typedef $$TransactionsTableUpdateCompanionBuilder = TransactionsCompanion Function({
  Value<int> id,
  Value<double> amount,
  Value<bool> isIncome,
  Value<int?> categoryId,
  Value<int> day,
  Value<DateTime> at,
  Value<String?> note,
});

final class $$TransactionsTableReferences extends BaseReferences<_$AppDatabase, $TransactionsTable, Transaction> {
  $$TransactionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) => db.categories.createAlias('transactions__category_id__categories__id');

  $$CategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<int>('category_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager($_db, $_db.categories).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$TransactionsTableFilterComposer extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isIncome => $composableBuilder(column: $table.isIncome, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get day => $composableBuilder(column: $table.day, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get at => $composableBuilder(column: $table.at, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(column: $table.note, builder: (column) => ColumnFilters(column));

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$CategoriesTableFilterComposer(
        $db: $db,
        $table: $db.categories,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }
}

class $$TransactionsTableOrderingComposer extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isIncome => $composableBuilder(column: $table.isIncome, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get day => $composableBuilder(column: $table.day, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get at => $composableBuilder(column: $table.at, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(column: $table.note, builder: (column) => ColumnOrderings(column));

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$CategoriesTableOrderingComposer(
        $db: $db,
        $table: $db.categories,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }
}

class $$TransactionsTableAnnotationComposer extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get amount => $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<bool> get isIncome => $composableBuilder(column: $table.isIncome, builder: (column) => column);

  GeneratedColumn<int> get day => $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<DateTime> get at => $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<String> get note => $composableBuilder(column: $table.note, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$CategoriesTableAnnotationComposer(
        $db: $db,
        $table: $db.categories,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }
}

class $$TransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionsTable,
          Transaction,
          $$TransactionsTableFilterComposer,
          $$TransactionsTableOrderingComposer,
          $$TransactionsTableAnnotationComposer,
          $$TransactionsTableCreateCompanionBuilder,
          $$TransactionsTableUpdateCompanionBuilder,
          (Transaction, $$TransactionsTableReferences),
          Transaction,
          PrefetchHooks Function({bool categoryId})
        > {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<bool> isIncome = const Value.absent(),
            Value<int?> categoryId = const Value.absent(),
            Value<int> day = const Value.absent(),
            Value<DateTime> at = const Value.absent(),
            Value<String?> note = const Value.absent(),
          }) => TransactionsCompanion(id: id, amount: amount, isIncome: isIncome, categoryId: categoryId, day: day, at: at, note: note),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required double amount,
                Value<bool> isIncome = const Value.absent(),
                Value<int?> categoryId = const Value.absent(),
                required int day,
                Value<DateTime> at = const Value.absent(),
                Value<String?> note = const Value.absent(),
              }) => TransactionsCompanion.insert(
                id: id,
                amount: amount,
                isIncome: isIncome,
                categoryId: categoryId,
                day: day,
                at: at,
                note: note,
              ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable<$TransactionsTable, Transaction>(table), $$TransactionsTableReferences(db, table, e))).toList(),
          prefetchHooksCallback: ({categoryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (categoryId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.categoryId,
                        referencedTable: $$TransactionsTableReferences._categoryIdTable(db),
                        referencedColumn: $$TransactionsTableReferences._categoryIdTable(db).id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionsTable,
      Transaction,
      $$TransactionsTableFilterComposer,
      $$TransactionsTableOrderingComposer,
      $$TransactionsTableAnnotationComposer,
      $$TransactionsTableCreateCompanionBuilder,
      $$TransactionsTableUpdateCompanionBuilder,
      (Transaction, $$TransactionsTableReferences),
      Transaction,
      PrefetchHooks Function({bool categoryId})
    >;
typedef $$FundMovesTableCreateCompanionBuilder = FundMovesCompanion Function({
  Value<int> id,
  required int fundId,
  required double amount,
  required int day,
  Value<String?> note,
});
typedef $$FundMovesTableUpdateCompanionBuilder = FundMovesCompanion Function({
  Value<int> id,
  Value<int> fundId,
  Value<double> amount,
  Value<int> day,
  Value<String?> note,
});

final class $$FundMovesTableReferences extends BaseReferences<_$AppDatabase, $FundMovesTable, FundMove> {
  $$FundMovesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FundsTable _fundIdTable(_$AppDatabase db) => db.funds.createAlias('fund_moves__fund_id__funds__id');

  $$FundsTableProcessedTableManager get fundId {
    final $_column = $_itemColumn<int>('fund_id')!;

    final manager = $$FundsTableTableManager($_db, $_db.funds).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_fundIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$FundMovesTableFilterComposer extends Composer<_$AppDatabase, $FundMovesTable> {
  $$FundMovesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get day => $composableBuilder(column: $table.day, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(column: $table.note, builder: (column) => ColumnFilters(column));

  $$FundsTableFilterComposer get fundId {
    final $$FundsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fundId,
      referencedTable: $db.funds,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$FundsTableFilterComposer(
        $db: $db,
        $table: $db.funds,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }
}

class $$FundMovesTableOrderingComposer extends Composer<_$AppDatabase, $FundMovesTable> {
  $$FundMovesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get day => $composableBuilder(column: $table.day, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(column: $table.note, builder: (column) => ColumnOrderings(column));

  $$FundsTableOrderingComposer get fundId {
    final $$FundsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fundId,
      referencedTable: $db.funds,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$FundsTableOrderingComposer(
        $db: $db,
        $table: $db.funds,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }
}

class $$FundMovesTableAnnotationComposer extends Composer<_$AppDatabase, $FundMovesTable> {
  $$FundMovesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get amount => $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<int> get day => $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<String> get note => $composableBuilder(column: $table.note, builder: (column) => column);

  $$FundsTableAnnotationComposer get fundId {
    final $$FundsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fundId,
      referencedTable: $db.funds,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$FundsTableAnnotationComposer(
        $db: $db,
        $table: $db.funds,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }
}

class $$FundMovesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FundMovesTable,
          FundMove,
          $$FundMovesTableFilterComposer,
          $$FundMovesTableOrderingComposer,
          $$FundMovesTableAnnotationComposer,
          $$FundMovesTableCreateCompanionBuilder,
          $$FundMovesTableUpdateCompanionBuilder,
          (FundMove, $$FundMovesTableReferences),
          FundMove,
          PrefetchHooks Function({bool fundId})
        > {
  $$FundMovesTableTableManager(_$AppDatabase db, $FundMovesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$FundMovesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$FundMovesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$FundMovesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> fundId = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<int> day = const Value.absent(),
            Value<String?> note = const Value.absent(),
          }) => FundMovesCompanion(id: id, fundId: fundId, amount: amount, day: day, note: note),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int fundId,
            required double amount,
            required int day,
            Value<String?> note = const Value.absent(),
          }) => FundMovesCompanion.insert(id: id, fundId: fundId, amount: amount, day: day, note: note),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable<$FundMovesTable, FundMove>(table), $$FundMovesTableReferences(db, table, e))).toList(),
          prefetchHooksCallback: ({fundId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (fundId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.fundId,
                        referencedTable: $$FundMovesTableReferences._fundIdTable(db),
                        referencedColumn: $$FundMovesTableReferences._fundIdTable(db).id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FundMovesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FundMovesTable,
      FundMove,
      $$FundMovesTableFilterComposer,
      $$FundMovesTableOrderingComposer,
      $$FundMovesTableAnnotationComposer,
      $$FundMovesTableCreateCompanionBuilder,
      $$FundMovesTableUpdateCompanionBuilder,
      (FundMove, $$FundMovesTableReferences),
      FundMove,
      PrefetchHooks Function({bool fundId})
    >;
typedef $$ProgramsTableCreateCompanionBuilder = ProgramsCompanion Function({
  Value<int> id,
  required String name,
  Value<int> daysMask,
  Value<int?> reminderMinutes,
  Value<String?> note,
  Value<int?> minSets,
  Value<String?> minimumText,
  Value<bool> archived,
  Value<int> sortOrder,
});
typedef $$ProgramsTableUpdateCompanionBuilder = ProgramsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<int> daysMask,
  Value<int?> reminderMinutes,
  Value<String?> note,
  Value<int?> minSets,
  Value<String?> minimumText,
  Value<bool> archived,
  Value<int> sortOrder,
});

final class $$ProgramsTableReferences extends BaseReferences<_$AppDatabase, $ProgramsTable, Program> {
  $$ProgramsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ProgramExercisesTable, List<ProgramExercise>> _programExercisesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.programExercises, aliasName: 'programs__id__program_exercises__program_id');

  $$ProgramExercisesTableProcessedTableManager get programExercisesRefs {
    final manager = $$ProgramExercisesTableTableManager(
      $_db,
      $_db.programExercises,
    ).filter((f) => f.programId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_programExercisesRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$WorkoutSessionsTable, List<WorkoutSession>> _workoutSessionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.workoutSessions, aliasName: 'programs__id__workout_sessions__program_id');

  $$WorkoutSessionsTableProcessedTableManager get workoutSessionsRefs {
    final manager = $$WorkoutSessionsTableTableManager(
      $_db,
      $_db.workoutSessions,
    ).filter((f) => f.programId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_workoutSessionsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ProgramsTableFilterComposer extends Composer<_$AppDatabase, $ProgramsTable> {
  $$ProgramsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get daysMask => $composableBuilder(column: $table.daysMask, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reminderMinutes => $composableBuilder(column: $table.reminderMinutes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get minSets => $composableBuilder(column: $table.minSets, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get minimumText => $composableBuilder(column: $table.minimumText, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get archived => $composableBuilder(column: $table.archived, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  Expression<bool> programExercisesRefs(Expression<bool> Function($$ProgramExercisesTableFilterComposer f) f) {
    final $$ProgramExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.programExercises,
      getReferencedColumn: (t) => t.programId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$ProgramExercisesTableFilterComposer(
        $db: $db,
        $table: $db.programExercises,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return f(composer);
  }

  Expression<bool> workoutSessionsRefs(Expression<bool> Function($$WorkoutSessionsTableFilterComposer f) f) {
    final $$WorkoutSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workoutSessions,
      getReferencedColumn: (t) => t.programId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$WorkoutSessionsTableFilterComposer(
        $db: $db,
        $table: $db.workoutSessions,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return f(composer);
  }
}

class $$ProgramsTableOrderingComposer extends Composer<_$AppDatabase, $ProgramsTable> {
  $$ProgramsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get daysMask => $composableBuilder(column: $table.daysMask, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reminderMinutes =>
      $composableBuilder(column: $table.reminderMinutes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get minSets => $composableBuilder(column: $table.minSets, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get minimumText => $composableBuilder(column: $table.minimumText, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get archived => $composableBuilder(column: $table.archived, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnOrderings(column));
}

class $$ProgramsTableAnnotationComposer extends Composer<_$AppDatabase, $ProgramsTable> {
  $$ProgramsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get daysMask => $composableBuilder(column: $table.daysMask, builder: (column) => column);

  GeneratedColumn<int> get reminderMinutes => $composableBuilder(column: $table.reminderMinutes, builder: (column) => column);

  GeneratedColumn<String> get note => $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get minSets => $composableBuilder(column: $table.minSets, builder: (column) => column);

  GeneratedColumn<String> get minimumText => $composableBuilder(column: $table.minimumText, builder: (column) => column);

  GeneratedColumn<bool> get archived => $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  Expression<T> programExercisesRefs<T extends Object>(Expression<T> Function($$ProgramExercisesTableAnnotationComposer a) f) {
    final $$ProgramExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.programExercises,
      getReferencedColumn: (t) => t.programId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ProgramExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.programExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> workoutSessionsRefs<T extends Object>(Expression<T> Function($$WorkoutSessionsTableAnnotationComposer a) f) {
    final $$WorkoutSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workoutSessions,
      getReferencedColumn: (t) => t.programId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$WorkoutSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.workoutSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProgramsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProgramsTable,
          Program,
          $$ProgramsTableFilterComposer,
          $$ProgramsTableOrderingComposer,
          $$ProgramsTableAnnotationComposer,
          $$ProgramsTableCreateCompanionBuilder,
          $$ProgramsTableUpdateCompanionBuilder,
          (Program, $$ProgramsTableReferences),
          Program,
          PrefetchHooks Function({bool programExercisesRefs, bool workoutSessionsRefs})
        > {
  $$ProgramsTableTableManager(_$AppDatabase db, $ProgramsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$ProgramsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$ProgramsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$ProgramsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> daysMask = const Value.absent(),
                Value<int?> reminderMinutes = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int?> minSets = const Value.absent(),
                Value<String?> minimumText = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => ProgramsCompanion(
                id: id,
                name: name,
                daysMask: daysMask,
                reminderMinutes: reminderMinutes,
                note: note,
                minSets: minSets,
                minimumText: minimumText,
                archived: archived,
                sortOrder: sortOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<int> daysMask = const Value.absent(),
                Value<int?> reminderMinutes = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int?> minSets = const Value.absent(),
                Value<String?> minimumText = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => ProgramsCompanion.insert(
                id: id,
                name: name,
                daysMask: daysMask,
                reminderMinutes: reminderMinutes,
                note: note,
                minSets: minSets,
                minimumText: minimumText,
                archived: archived,
                sortOrder: sortOrder,
              ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable<$ProgramsTable, Program>(table), $$ProgramsTableReferences(db, table, e))).toList(),
          prefetchHooksCallback: ({programExercisesRefs = false, workoutSessionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (programExercisesRefs) db.programExercises, if (workoutSessionsRefs) db.workoutSessions],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (programExercisesRefs)
                    await $_getPrefetchedDataByColumns<Program, $ProgramsTable, ProgramExercise, $ProgramExercisesTable>(
                      currentTable: table,
                      referencedTable: $$ProgramsTableReferences._programExercisesRefsTable(db),
                      managerFromTypedResult: (p0) => $$ProgramsTableReferences(db, table, p0).programExercisesRefs,
                      currentColumn: 'id',
                      referencedColumn: 'program_id',
                      typedResults: items,
                    ),
                  if (workoutSessionsRefs)
                    await $_getPrefetchedDataByColumns<Program, $ProgramsTable, WorkoutSession, $WorkoutSessionsTable>(
                      currentTable: table,
                      referencedTable: $$ProgramsTableReferences._workoutSessionsRefsTable(db),
                      managerFromTypedResult: (p0) => $$ProgramsTableReferences(db, table, p0).workoutSessionsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'program_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ProgramsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProgramsTable,
      Program,
      $$ProgramsTableFilterComposer,
      $$ProgramsTableOrderingComposer,
      $$ProgramsTableAnnotationComposer,
      $$ProgramsTableCreateCompanionBuilder,
      $$ProgramsTableUpdateCompanionBuilder,
      (Program, $$ProgramsTableReferences),
      Program,
      PrefetchHooks Function({bool programExercisesRefs, bool workoutSessionsRefs})
    >;
typedef $$ProgramExercisesTableCreateCompanionBuilder = ProgramExercisesCompanion Function({
  Value<int> id,
  required int programId,
  required String name,
  Value<int> sets,
  Value<int> repsMin,
  Value<int> repsMax,
  Value<String> unit,
  Value<String?> note,
  Value<int> sortOrder,
});
typedef $$ProgramExercisesTableUpdateCompanionBuilder = ProgramExercisesCompanion Function({
  Value<int> id,
  Value<int> programId,
  Value<String> name,
  Value<int> sets,
  Value<int> repsMin,
  Value<int> repsMax,
  Value<String> unit,
  Value<String?> note,
  Value<int> sortOrder,
});

final class $$ProgramExercisesTableReferences extends BaseReferences<_$AppDatabase, $ProgramExercisesTable, ProgramExercise> {
  $$ProgramExercisesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProgramsTable _programIdTable(_$AppDatabase db) => db.programs.createAlias('program_exercises__program_id__programs__id');

  $$ProgramsTableProcessedTableManager get programId {
    final $_column = $_itemColumn<int>('program_id')!;

    final manager = $$ProgramsTableTableManager($_db, $_db.programs).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_programIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$SessionSetsTable, List<SessionSet>> _sessionSetsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.sessionSets, aliasName: 'program_exercises__id__session_sets__exercise_id');

  $$SessionSetsTableProcessedTableManager get sessionSetsRefs {
    final manager = $$SessionSetsTableTableManager(
      $_db,
      $_db.sessionSets,
    ).filter((f) => f.exerciseId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_sessionSetsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ProgramExercisesTableFilterComposer extends Composer<_$AppDatabase, $ProgramExercisesTable> {
  $$ProgramExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sets => $composableBuilder(column: $table.sets, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get repsMin => $composableBuilder(column: $table.repsMin, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get repsMax => $composableBuilder(column: $table.repsMax, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unit => $composableBuilder(column: $table.unit, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  $$ProgramsTableFilterComposer get programId {
    final $$ProgramsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.programId,
      referencedTable: $db.programs,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$ProgramsTableFilterComposer(
        $db: $db,
        $table: $db.programs,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }

  Expression<bool> sessionSetsRefs(Expression<bool> Function($$SessionSetsTableFilterComposer f) f) {
    final $$SessionSetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessionSets,
      getReferencedColumn: (t) => t.exerciseId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$SessionSetsTableFilterComposer(
        $db: $db,
        $table: $db.sessionSets,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return f(composer);
  }
}

class $$ProgramExercisesTableOrderingComposer extends Composer<_$AppDatabase, $ProgramExercisesTable> {
  $$ProgramExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sets => $composableBuilder(column: $table.sets, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get repsMin => $composableBuilder(column: $table.repsMin, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get repsMax => $composableBuilder(column: $table.repsMax, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unit => $composableBuilder(column: $table.unit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  $$ProgramsTableOrderingComposer get programId {
    final $$ProgramsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.programId,
      referencedTable: $db.programs,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$ProgramsTableOrderingComposer(
        $db: $db,
        $table: $db.programs,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }
}

class $$ProgramExercisesTableAnnotationComposer extends Composer<_$AppDatabase, $ProgramExercisesTable> {
  $$ProgramExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get sets => $composableBuilder(column: $table.sets, builder: (column) => column);

  GeneratedColumn<int> get repsMin => $composableBuilder(column: $table.repsMin, builder: (column) => column);

  GeneratedColumn<int> get repsMax => $composableBuilder(column: $table.repsMax, builder: (column) => column);

  GeneratedColumn<String> get unit => $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get note => $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$ProgramsTableAnnotationComposer get programId {
    final $$ProgramsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.programId,
      referencedTable: $db.programs,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$ProgramsTableAnnotationComposer(
        $db: $db,
        $table: $db.programs,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }

  Expression<T> sessionSetsRefs<T extends Object>(Expression<T> Function($$SessionSetsTableAnnotationComposer a) f) {
    final $$SessionSetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessionSets,
      getReferencedColumn: (t) => t.exerciseId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$SessionSetsTableAnnotationComposer(
        $db: $db,
        $table: $db.sessionSets,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return f(composer);
  }
}

class $$ProgramExercisesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProgramExercisesTable,
          ProgramExercise,
          $$ProgramExercisesTableFilterComposer,
          $$ProgramExercisesTableOrderingComposer,
          $$ProgramExercisesTableAnnotationComposer,
          $$ProgramExercisesTableCreateCompanionBuilder,
          $$ProgramExercisesTableUpdateCompanionBuilder,
          (ProgramExercise, $$ProgramExercisesTableReferences),
          ProgramExercise,
          PrefetchHooks Function({bool programId, bool sessionSetsRefs})
        > {
  $$ProgramExercisesTableTableManager(_$AppDatabase db, $ProgramExercisesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$ProgramExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$ProgramExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$ProgramExercisesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> programId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> sets = const Value.absent(),
                Value<int> repsMin = const Value.absent(),
                Value<int> repsMax = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => ProgramExercisesCompanion(
                id: id,
                programId: programId,
                name: name,
                sets: sets,
                repsMin: repsMin,
                repsMax: repsMax,
                unit: unit,
                note: note,
                sortOrder: sortOrder,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int programId,
                required String name,
                Value<int> sets = const Value.absent(),
                Value<int> repsMin = const Value.absent(),
                Value<int> repsMax = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
              }) => ProgramExercisesCompanion.insert(
                id: id,
                programId: programId,
                name: name,
                sets: sets,
                repsMin: repsMin,
                repsMax: repsMax,
                unit: unit,
                note: note,
                sortOrder: sortOrder,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable<$ProgramExercisesTable, ProgramExercise>(table), $$ProgramExercisesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({programId = false, sessionSetsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (sessionSetsRefs) db.sessionSets],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (programId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.programId,
                        referencedTable: $$ProgramExercisesTableReferences._programIdTable(db),
                        referencedColumn: $$ProgramExercisesTableReferences._programIdTable(db).id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (sessionSetsRefs)
                    await $_getPrefetchedDataByColumns<ProgramExercise, $ProgramExercisesTable, SessionSet, $SessionSetsTable>(
                      currentTable: table,
                      referencedTable: $$ProgramExercisesTableReferences._sessionSetsRefsTable(db),
                      managerFromTypedResult: (p0) => $$ProgramExercisesTableReferences(db, table, p0).sessionSetsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'exercise_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ProgramExercisesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProgramExercisesTable,
      ProgramExercise,
      $$ProgramExercisesTableFilterComposer,
      $$ProgramExercisesTableOrderingComposer,
      $$ProgramExercisesTableAnnotationComposer,
      $$ProgramExercisesTableCreateCompanionBuilder,
      $$ProgramExercisesTableUpdateCompanionBuilder,
      (ProgramExercise, $$ProgramExercisesTableReferences),
      ProgramExercise,
      PrefetchHooks Function({bool programId, bool sessionSetsRefs})
    >;
typedef $$WorkoutSessionsTableCreateCompanionBuilder = WorkoutSessionsCompanion Function({
  Value<int> id,
  Value<int?> programId,
  required String programName,
  required int day,
  Value<DateTime> at,
  Value<String?> note,
  Value<bool> minimum,
});
typedef $$WorkoutSessionsTableUpdateCompanionBuilder = WorkoutSessionsCompanion Function({
  Value<int> id,
  Value<int?> programId,
  Value<String> programName,
  Value<int> day,
  Value<DateTime> at,
  Value<String?> note,
  Value<bool> minimum,
});

final class $$WorkoutSessionsTableReferences extends BaseReferences<_$AppDatabase, $WorkoutSessionsTable, WorkoutSession> {
  $$WorkoutSessionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProgramsTable _programIdTable(_$AppDatabase db) => db.programs.createAlias('workout_sessions__program_id__programs__id');

  $$ProgramsTableProcessedTableManager? get programId {
    final $_column = $_itemColumn<int>('program_id');
    if ($_column == null) return null;
    final manager = $$ProgramsTableTableManager($_db, $_db.programs).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_programIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$SessionSetsTable, List<SessionSet>> _sessionSetsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.sessionSets, aliasName: 'workout_sessions__id__session_sets__session_id');

  $$SessionSetsTableProcessedTableManager get sessionSetsRefs {
    final manager = $$SessionSetsTableTableManager(
      $_db,
      $_db.sessionSets,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_sessionSetsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$WorkoutSessionsTableFilterComposer extends Composer<_$AppDatabase, $WorkoutSessionsTable> {
  $$WorkoutSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get programName => $composableBuilder(column: $table.programName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get day => $composableBuilder(column: $table.day, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get at => $composableBuilder(column: $table.at, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get minimum => $composableBuilder(column: $table.minimum, builder: (column) => ColumnFilters(column));

  $$ProgramsTableFilterComposer get programId {
    final $$ProgramsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.programId,
      referencedTable: $db.programs,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$ProgramsTableFilterComposer(
        $db: $db,
        $table: $db.programs,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }

  Expression<bool> sessionSetsRefs(Expression<bool> Function($$SessionSetsTableFilterComposer f) f) {
    final $$SessionSetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessionSets,
      getReferencedColumn: (t) => t.sessionId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$SessionSetsTableFilterComposer(
        $db: $db,
        $table: $db.sessionSets,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return f(composer);
  }
}

class $$WorkoutSessionsTableOrderingComposer extends Composer<_$AppDatabase, $WorkoutSessionsTable> {
  $$WorkoutSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get programName => $composableBuilder(column: $table.programName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get day => $composableBuilder(column: $table.day, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get at => $composableBuilder(column: $table.at, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get minimum => $composableBuilder(column: $table.minimum, builder: (column) => ColumnOrderings(column));

  $$ProgramsTableOrderingComposer get programId {
    final $$ProgramsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.programId,
      referencedTable: $db.programs,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$ProgramsTableOrderingComposer(
        $db: $db,
        $table: $db.programs,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }
}

class $$WorkoutSessionsTableAnnotationComposer extends Composer<_$AppDatabase, $WorkoutSessionsTable> {
  $$WorkoutSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get programName => $composableBuilder(column: $table.programName, builder: (column) => column);

  GeneratedColumn<int> get day => $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<DateTime> get at => $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<String> get note => $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<bool> get minimum => $composableBuilder(column: $table.minimum, builder: (column) => column);

  $$ProgramsTableAnnotationComposer get programId {
    final $$ProgramsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.programId,
      referencedTable: $db.programs,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$ProgramsTableAnnotationComposer(
        $db: $db,
        $table: $db.programs,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }

  Expression<T> sessionSetsRefs<T extends Object>(Expression<T> Function($$SessionSetsTableAnnotationComposer a) f) {
    final $$SessionSetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessionSets,
      getReferencedColumn: (t) => t.sessionId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$SessionSetsTableAnnotationComposer(
        $db: $db,
        $table: $db.sessionSets,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return f(composer);
  }
}

class $$WorkoutSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkoutSessionsTable,
          WorkoutSession,
          $$WorkoutSessionsTableFilterComposer,
          $$WorkoutSessionsTableOrderingComposer,
          $$WorkoutSessionsTableAnnotationComposer,
          $$WorkoutSessionsTableCreateCompanionBuilder,
          $$WorkoutSessionsTableUpdateCompanionBuilder,
          (WorkoutSession, $$WorkoutSessionsTableReferences),
          WorkoutSession,
          PrefetchHooks Function({bool programId, bool sessionSetsRefs})
        > {
  $$WorkoutSessionsTableTableManager(_$AppDatabase db, $WorkoutSessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$WorkoutSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$WorkoutSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$WorkoutSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> programId = const Value.absent(),
                Value<String> programName = const Value.absent(),
                Value<int> day = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<bool> minimum = const Value.absent(),
              }) => WorkoutSessionsCompanion(
                id: id,
                programId: programId,
                programName: programName,
                day: day,
                at: at,
                note: note,
                minimum: minimum,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> programId = const Value.absent(),
                required String programName,
                required int day,
                Value<DateTime> at = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<bool> minimum = const Value.absent(),
              }) => WorkoutSessionsCompanion.insert(
                id: id,
                programId: programId,
                programName: programName,
                day: day,
                at: at,
                note: note,
                minimum: minimum,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable<$WorkoutSessionsTable, WorkoutSession>(table), $$WorkoutSessionsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({programId = false, sessionSetsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (sessionSetsRefs) db.sessionSets],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (programId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.programId,
                        referencedTable: $$WorkoutSessionsTableReferences._programIdTable(db),
                        referencedColumn: $$WorkoutSessionsTableReferences._programIdTable(db).id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (sessionSetsRefs)
                    await $_getPrefetchedDataByColumns<WorkoutSession, $WorkoutSessionsTable, SessionSet, $SessionSetsTable>(
                      currentTable: table,
                      referencedTable: $$WorkoutSessionsTableReferences._sessionSetsRefsTable(db),
                      managerFromTypedResult: (p0) => $$WorkoutSessionsTableReferences(db, table, p0).sessionSetsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'session_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$WorkoutSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkoutSessionsTable,
      WorkoutSession,
      $$WorkoutSessionsTableFilterComposer,
      $$WorkoutSessionsTableOrderingComposer,
      $$WorkoutSessionsTableAnnotationComposer,
      $$WorkoutSessionsTableCreateCompanionBuilder,
      $$WorkoutSessionsTableUpdateCompanionBuilder,
      (WorkoutSession, $$WorkoutSessionsTableReferences),
      WorkoutSession,
      PrefetchHooks Function({bool programId, bool sessionSetsRefs})
    >;
typedef $$SessionSetsTableCreateCompanionBuilder = SessionSetsCompanion Function({
  Value<int> id,
  required int sessionId,
  Value<int?> exerciseId,
  required String exerciseName,
  required int setIndex,
  required int reps,
  Value<double?> weight,
});
typedef $$SessionSetsTableUpdateCompanionBuilder = SessionSetsCompanion Function({
  Value<int> id,
  Value<int> sessionId,
  Value<int?> exerciseId,
  Value<String> exerciseName,
  Value<int> setIndex,
  Value<int> reps,
  Value<double?> weight,
});

final class $$SessionSetsTableReferences extends BaseReferences<_$AppDatabase, $SessionSetsTable, SessionSet> {
  $$SessionSetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WorkoutSessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.workoutSessions.createAlias('session_sets__session_id__workout_sessions__id');

  $$WorkoutSessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<int>('session_id')!;

    final manager = $$WorkoutSessionsTableTableManager($_db, $_db.workoutSessions).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static $ProgramExercisesTable _exerciseIdTable(_$AppDatabase db) =>
      db.programExercises.createAlias('session_sets__exercise_id__program_exercises__id');

  $$ProgramExercisesTableProcessedTableManager? get exerciseId {
    final $_column = $_itemColumn<int>('exercise_id');
    if ($_column == null) return null;
    final manager = $$ProgramExercisesTableTableManager($_db, $_db.programExercises).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_exerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$SessionSetsTableFilterComposer extends Composer<_$AppDatabase, $SessionSetsTable> {
  $$SessionSetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get exerciseName => $composableBuilder(column: $table.exerciseName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get setIndex => $composableBuilder(column: $table.setIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reps => $composableBuilder(column: $table.reps, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get weight => $composableBuilder(column: $table.weight, builder: (column) => ColumnFilters(column));

  $$WorkoutSessionsTableFilterComposer get sessionId {
    final $$WorkoutSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.workoutSessions,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$WorkoutSessionsTableFilterComposer(
        $db: $db,
        $table: $db.workoutSessions,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }

  $$ProgramExercisesTableFilterComposer get exerciseId {
    final $$ProgramExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.programExercises,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$ProgramExercisesTableFilterComposer(
        $db: $db,
        $table: $db.programExercises,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }
}

class $$SessionSetsTableOrderingComposer extends Composer<_$AppDatabase, $SessionSetsTable> {
  $$SessionSetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get exerciseName => $composableBuilder(column: $table.exerciseName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get setIndex => $composableBuilder(column: $table.setIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reps => $composableBuilder(column: $table.reps, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get weight => $composableBuilder(column: $table.weight, builder: (column) => ColumnOrderings(column));

  $$WorkoutSessionsTableOrderingComposer get sessionId {
    final $$WorkoutSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.workoutSessions,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$WorkoutSessionsTableOrderingComposer(
        $db: $db,
        $table: $db.workoutSessions,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }

  $$ProgramExercisesTableOrderingComposer get exerciseId {
    final $$ProgramExercisesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.programExercises,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ProgramExercisesTableOrderingComposer(
            $db: $db,
            $table: $db.programExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionSetsTableAnnotationComposer extends Composer<_$AppDatabase, $SessionSetsTable> {
  $$SessionSetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get exerciseName => $composableBuilder(column: $table.exerciseName, builder: (column) => column);

  GeneratedColumn<int> get setIndex => $composableBuilder(column: $table.setIndex, builder: (column) => column);

  GeneratedColumn<int> get reps => $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<double> get weight => $composableBuilder(column: $table.weight, builder: (column) => column);

  $$WorkoutSessionsTableAnnotationComposer get sessionId {
    final $$WorkoutSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.workoutSessions,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$WorkoutSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.workoutSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProgramExercisesTableAnnotationComposer get exerciseId {
    final $$ProgramExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.programExercises,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ProgramExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.programExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionSetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionSetsTable,
          SessionSet,
          $$SessionSetsTableFilterComposer,
          $$SessionSetsTableOrderingComposer,
          $$SessionSetsTableAnnotationComposer,
          $$SessionSetsTableCreateCompanionBuilder,
          $$SessionSetsTableUpdateCompanionBuilder,
          (SessionSet, $$SessionSetsTableReferences),
          SessionSet,
          PrefetchHooks Function({bool sessionId, bool exerciseId})
        > {
  $$SessionSetsTableTableManager(_$AppDatabase db, $SessionSetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$SessionSetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$SessionSetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$SessionSetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> sessionId = const Value.absent(),
                Value<int?> exerciseId = const Value.absent(),
                Value<String> exerciseName = const Value.absent(),
                Value<int> setIndex = const Value.absent(),
                Value<int> reps = const Value.absent(),
                Value<double?> weight = const Value.absent(),
              }) => SessionSetsCompanion(
                id: id,
                sessionId: sessionId,
                exerciseId: exerciseId,
                exerciseName: exerciseName,
                setIndex: setIndex,
                reps: reps,
                weight: weight,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int sessionId,
                Value<int?> exerciseId = const Value.absent(),
                required String exerciseName,
                required int setIndex,
                required int reps,
                Value<double?> weight = const Value.absent(),
              }) => SessionSetsCompanion.insert(
                id: id,
                sessionId: sessionId,
                exerciseId: exerciseId,
                exerciseName: exerciseName,
                setIndex: setIndex,
                reps: reps,
                weight: weight,
              ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable<$SessionSetsTable, SessionSet>(table), $$SessionSetsTableReferences(db, table, e))).toList(),
          prefetchHooksCallback: ({sessionId = false, exerciseId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.sessionId,
                        referencedTable: $$SessionSetsTableReferences._sessionIdTable(db),
                        referencedColumn: $$SessionSetsTableReferences._sessionIdTable(db).id,
                      ) as T;
                    }
                    if (exerciseId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.exerciseId,
                        referencedTable: $$SessionSetsTableReferences._exerciseIdTable(db),
                        referencedColumn: $$SessionSetsTableReferences._exerciseIdTable(db).id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SessionSetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionSetsTable,
      SessionSet,
      $$SessionSetsTableFilterComposer,
      $$SessionSetsTableOrderingComposer,
      $$SessionSetsTableAnnotationComposer,
      $$SessionSetsTableCreateCompanionBuilder,
      $$SessionSetsTableUpdateCompanionBuilder,
      (SessionSet, $$SessionSetsTableReferences),
      SessionSet,
      PrefetchHooks Function({bool sessionId, bool exerciseId})
    >;
typedef $$JournalEntriesTableCreateCompanionBuilder = JournalEntriesCompanion Function({
  Value<int> id,
  required JournalKind kind,
  required int day,
  Value<DateTime> at,
  Value<int?> mood,
  Value<String> body,
});
typedef $$JournalEntriesTableUpdateCompanionBuilder = JournalEntriesCompanion Function({
  Value<int> id,
  Value<JournalKind> kind,
  Value<int> day,
  Value<DateTime> at,
  Value<int?> mood,
  Value<String> body,
});

class $$JournalEntriesTableFilterComposer extends Composer<_$AppDatabase, $JournalEntriesTable> {
  $$JournalEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<JournalKind, JournalKind, int> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get day => $composableBuilder(column: $table.day, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get at => $composableBuilder(column: $table.at, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get mood => $composableBuilder(column: $table.mood, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get body => $composableBuilder(column: $table.body, builder: (column) => ColumnFilters(column));
}

class $$JournalEntriesTableOrderingComposer extends Composer<_$AppDatabase, $JournalEntriesTable> {
  $$JournalEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get kind => $composableBuilder(column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get day => $composableBuilder(column: $table.day, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get at => $composableBuilder(column: $table.at, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get mood => $composableBuilder(column: $table.mood, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get body => $composableBuilder(column: $table.body, builder: (column) => ColumnOrderings(column));
}

class $$JournalEntriesTableAnnotationComposer extends Composer<_$AppDatabase, $JournalEntriesTable> {
  $$JournalEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<JournalKind, int> get kind => $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get day => $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<DateTime> get at => $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<int> get mood => $composableBuilder(column: $table.mood, builder: (column) => column);

  GeneratedColumn<String> get body => $composableBuilder(column: $table.body, builder: (column) => column);
}

class $$JournalEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $JournalEntriesTable,
          JournalEntry,
          $$JournalEntriesTableFilterComposer,
          $$JournalEntriesTableOrderingComposer,
          $$JournalEntriesTableAnnotationComposer,
          $$JournalEntriesTableCreateCompanionBuilder,
          $$JournalEntriesTableUpdateCompanionBuilder,
          (JournalEntry, BaseReferences<_$AppDatabase, $JournalEntriesTable, JournalEntry>),
          JournalEntry,
          PrefetchHooks Function()
        > {
  $$JournalEntriesTableTableManager(_$AppDatabase db, $JournalEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$JournalEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$JournalEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$JournalEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<JournalKind> kind = const Value.absent(),
            Value<int> day = const Value.absent(),
            Value<DateTime> at = const Value.absent(),
            Value<int?> mood = const Value.absent(),
            Value<String> body = const Value.absent(),
          }) => JournalEntriesCompanion(id: id, kind: kind, day: day, at: at, mood: mood, body: body),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required JournalKind kind,
            required int day,
            Value<DateTime> at = const Value.absent(),
            Value<int?> mood = const Value.absent(),
            Value<String> body = const Value.absent(),
          }) => JournalEntriesCompanion.insert(id: id, kind: kind, day: day, at: at, mood: mood, body: body),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$JournalEntriesTable, JournalEntry>(table),
                  BaseReferences<_$AppDatabase, $JournalEntriesTable, JournalEntry>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$JournalEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $JournalEntriesTable,
      JournalEntry,
      $$JournalEntriesTableFilterComposer,
      $$JournalEntriesTableOrderingComposer,
      $$JournalEntriesTableAnnotationComposer,
      $$JournalEntriesTableCreateCompanionBuilder,
      $$JournalEntriesTableUpdateCompanionBuilder,
      (JournalEntry, BaseReferences<_$AppDatabase, $JournalEntriesTable, JournalEntry>),
      JournalEntry,
      PrefetchHooks Function()
    >;
typedef $$RemindersTableCreateCompanionBuilder = RemindersCompanion Function({
  Value<int> id,
  required String title,
  Value<String?> body,
  required int minutes,
  Value<int> daysMask,
  Value<bool> enabled,
});
typedef $$RemindersTableUpdateCompanionBuilder = RemindersCompanion Function({
  Value<int> id,
  Value<String> title,
  Value<String?> body,
  Value<int> minutes,
  Value<int> daysMask,
  Value<bool> enabled,
});

class $$RemindersTableFilterComposer extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get body => $composableBuilder(column: $table.body, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get minutes => $composableBuilder(column: $table.minutes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get daysMask => $composableBuilder(column: $table.daysMask, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get enabled => $composableBuilder(column: $table.enabled, builder: (column) => ColumnFilters(column));
}

class $$RemindersTableOrderingComposer extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get body => $composableBuilder(column: $table.body, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get minutes => $composableBuilder(column: $table.minutes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get daysMask => $composableBuilder(column: $table.daysMask, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get enabled => $composableBuilder(column: $table.enabled, builder: (column) => ColumnOrderings(column));
}

class $$RemindersTableAnnotationComposer extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title => $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body => $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<int> get minutes => $composableBuilder(column: $table.minutes, builder: (column) => column);

  GeneratedColumn<int> get daysMask => $composableBuilder(column: $table.daysMask, builder: (column) => column);

  GeneratedColumn<bool> get enabled => $composableBuilder(column: $table.enabled, builder: (column) => column);
}

class $$RemindersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RemindersTable,
          Reminder,
          $$RemindersTableFilterComposer,
          $$RemindersTableOrderingComposer,
          $$RemindersTableAnnotationComposer,
          $$RemindersTableCreateCompanionBuilder,
          $$RemindersTableUpdateCompanionBuilder,
          (Reminder, BaseReferences<_$AppDatabase, $RemindersTable, Reminder>),
          Reminder,
          PrefetchHooks Function()
        > {
  $$RemindersTableTableManager(_$AppDatabase db, $RemindersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$RemindersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$RemindersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$RemindersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> body = const Value.absent(),
            Value<int> minutes = const Value.absent(),
            Value<int> daysMask = const Value.absent(),
            Value<bool> enabled = const Value.absent(),
          }) => RemindersCompanion(id: id, title: title, body: body, minutes: minutes, daysMask: daysMask, enabled: enabled),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String title,
            Value<String?> body = const Value.absent(),
            required int minutes,
            Value<int> daysMask = const Value.absent(),
            Value<bool> enabled = const Value.absent(),
          }) => RemindersCompanion.insert(id: id, title: title, body: body, minutes: minutes, daysMask: daysMask, enabled: enabled),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable<$RemindersTable, Reminder>(table), BaseReferences<_$AppDatabase, $RemindersTable, Reminder>(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RemindersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RemindersTable,
      Reminder,
      $$RemindersTableFilterComposer,
      $$RemindersTableOrderingComposer,
      $$RemindersTableAnnotationComposer,
      $$RemindersTableCreateCompanionBuilder,
      $$RemindersTableUpdateCompanionBuilder,
      (Reminder, BaseReferences<_$AppDatabase, $RemindersTable, Reminder>),
      Reminder,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({required String key, required String value, Value<int> rowid});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({Value<String> key, Value<String> value, Value<int> rowid});

class $$SettingsTableFilterComposer extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$SettingsTableOrderingComposer extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$SettingsTableAnnotationComposer extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key => $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value => $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({required String key, required String value, Value<int> rowid = const Value.absent()}) =>
              SettingsCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (e.readTable<$SettingsTable, Setting>(table), BaseReferences<_$AppDatabase, $SettingsTable, Setting>(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;
typedef $$SleepLogsTableCreateCompanionBuilder = SleepLogsCompanion Function({
  Value<int> id,
  required int day,
  required DateTime bedAt,
  required DateTime wakeAt,
  Value<int?> quality,
  Value<String?> note,
});
typedef $$SleepLogsTableUpdateCompanionBuilder = SleepLogsCompanion Function({
  Value<int> id,
  Value<int> day,
  Value<DateTime> bedAt,
  Value<DateTime> wakeAt,
  Value<int?> quality,
  Value<String?> note,
});

class $$SleepLogsTableFilterComposer extends Composer<_$AppDatabase, $SleepLogsTable> {
  $$SleepLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get day => $composableBuilder(column: $table.day, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get bedAt => $composableBuilder(column: $table.bedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get wakeAt => $composableBuilder(column: $table.wakeAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get quality => $composableBuilder(column: $table.quality, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(column: $table.note, builder: (column) => ColumnFilters(column));
}

class $$SleepLogsTableOrderingComposer extends Composer<_$AppDatabase, $SleepLogsTable> {
  $$SleepLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get day => $composableBuilder(column: $table.day, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get bedAt => $composableBuilder(column: $table.bedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get wakeAt => $composableBuilder(column: $table.wakeAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get quality => $composableBuilder(column: $table.quality, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(column: $table.note, builder: (column) => ColumnOrderings(column));
}

class $$SleepLogsTableAnnotationComposer extends Composer<_$AppDatabase, $SleepLogsTable> {
  $$SleepLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get day => $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<DateTime> get bedAt => $composableBuilder(column: $table.bedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get wakeAt => $composableBuilder(column: $table.wakeAt, builder: (column) => column);

  GeneratedColumn<int> get quality => $composableBuilder(column: $table.quality, builder: (column) => column);

  GeneratedColumn<String> get note => $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$SleepLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SleepLogsTable,
          SleepLog,
          $$SleepLogsTableFilterComposer,
          $$SleepLogsTableOrderingComposer,
          $$SleepLogsTableAnnotationComposer,
          $$SleepLogsTableCreateCompanionBuilder,
          $$SleepLogsTableUpdateCompanionBuilder,
          (SleepLog, BaseReferences<_$AppDatabase, $SleepLogsTable, SleepLog>),
          SleepLog,
          PrefetchHooks Function()
        > {
  $$SleepLogsTableTableManager(_$AppDatabase db, $SleepLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$SleepLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$SleepLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$SleepLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> day = const Value.absent(),
            Value<DateTime> bedAt = const Value.absent(),
            Value<DateTime> wakeAt = const Value.absent(),
            Value<int?> quality = const Value.absent(),
            Value<String?> note = const Value.absent(),
          }) => SleepLogsCompanion(id: id, day: day, bedAt: bedAt, wakeAt: wakeAt, quality: quality, note: note),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int day,
            required DateTime bedAt,
            required DateTime wakeAt,
            Value<int?> quality = const Value.absent(),
            Value<String?> note = const Value.absent(),
          }) => SleepLogsCompanion.insert(id: id, day: day, bedAt: bedAt, wakeAt: wakeAt, quality: quality, note: note),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable<$SleepLogsTable, SleepLog>(table), BaseReferences<_$AppDatabase, $SleepLogsTable, SleepLog>(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SleepLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SleepLogsTable,
      SleepLog,
      $$SleepLogsTableFilterComposer,
      $$SleepLogsTableOrderingComposer,
      $$SleepLogsTableAnnotationComposer,
      $$SleepLogsTableCreateCompanionBuilder,
      $$SleepLogsTableUpdateCompanionBuilder,
      (SleepLog, BaseReferences<_$AppDatabase, $SleepLogsTable, SleepLog>),
      SleepLog,
      PrefetchHooks Function()
    >;
typedef $$FoodsTableCreateCompanionBuilder = FoodsCompanion Function({
  Value<int> id,
  required String name,
  Value<String> icon,
  required double kcal,
  Value<double> protein,
  Value<double> fat,
  Value<double> carbs,
  Value<int> sortOrder,
  Value<bool> archived,
});
typedef $$FoodsTableUpdateCompanionBuilder = FoodsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> icon,
  Value<double> kcal,
  Value<double> protein,
  Value<double> fat,
  Value<double> carbs,
  Value<int> sortOrder,
  Value<bool> archived,
});

final class $$FoodsTableReferences extends BaseReferences<_$AppDatabase, $FoodsTable, Food> {
  $$FoodsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MealsTable, List<Meal>> _mealsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.meals, aliasName: 'foods__id__meals__food_id');

  $$MealsTableProcessedTableManager get mealsRefs {
    final manager = $$MealsTableTableManager($_db, $_db.meals).filter((f) => f.foodId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_mealsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$FoodsTableFilterComposer extends Composer<_$AppDatabase, $FoodsTable> {
  $$FoodsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get icon => $composableBuilder(column: $table.icon, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get kcal => $composableBuilder(column: $table.kcal, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get protein => $composableBuilder(column: $table.protein, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get fat => $composableBuilder(column: $table.fat, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get carbs => $composableBuilder(column: $table.carbs, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get archived => $composableBuilder(column: $table.archived, builder: (column) => ColumnFilters(column));

  Expression<bool> mealsRefs(Expression<bool> Function($$MealsTableFilterComposer f) f) {
    final $$MealsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.meals,
      getReferencedColumn: (t) => t.foodId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$MealsTableFilterComposer(
        $db: $db,
        $table: $db.meals,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return f(composer);
  }
}

class $$FoodsTableOrderingComposer extends Composer<_$AppDatabase, $FoodsTable> {
  $$FoodsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get icon => $composableBuilder(column: $table.icon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get kcal => $composableBuilder(column: $table.kcal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get protein => $composableBuilder(column: $table.protein, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get fat => $composableBuilder(column: $table.fat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get carbs => $composableBuilder(column: $table.carbs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get archived => $composableBuilder(column: $table.archived, builder: (column) => ColumnOrderings(column));
}

class $$FoodsTableAnnotationComposer extends Composer<_$AppDatabase, $FoodsTable> {
  $$FoodsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get icon => $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<double> get kcal => $composableBuilder(column: $table.kcal, builder: (column) => column);

  GeneratedColumn<double> get protein => $composableBuilder(column: $table.protein, builder: (column) => column);

  GeneratedColumn<double> get fat => $composableBuilder(column: $table.fat, builder: (column) => column);

  GeneratedColumn<double> get carbs => $composableBuilder(column: $table.carbs, builder: (column) => column);

  GeneratedColumn<int> get sortOrder => $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get archived => $composableBuilder(column: $table.archived, builder: (column) => column);

  Expression<T> mealsRefs<T extends Object>(Expression<T> Function($$MealsTableAnnotationComposer a) f) {
    final $$MealsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.meals,
      getReferencedColumn: (t) => t.foodId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$MealsTableAnnotationComposer(
        $db: $db,
        $table: $db.meals,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return f(composer);
  }
}

class $$FoodsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FoodsTable,
          Food,
          $$FoodsTableFilterComposer,
          $$FoodsTableOrderingComposer,
          $$FoodsTableAnnotationComposer,
          $$FoodsTableCreateCompanionBuilder,
          $$FoodsTableUpdateCompanionBuilder,
          (Food, $$FoodsTableReferences),
          Food,
          PrefetchHooks Function({bool mealsRefs})
        > {
  $$FoodsTableTableManager(_$AppDatabase db, $FoodsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$FoodsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$FoodsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$FoodsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> icon = const Value.absent(),
                Value<double> kcal = const Value.absent(),
                Value<double> protein = const Value.absent(),
                Value<double> fat = const Value.absent(),
                Value<double> carbs = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> archived = const Value.absent(),
              }) => FoodsCompanion(
                id: id,
                name: name,
                icon: icon,
                kcal: kcal,
                protein: protein,
                fat: fat,
                carbs: carbs,
                sortOrder: sortOrder,
                archived: archived,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String> icon = const Value.absent(),
                required double kcal,
                Value<double> protein = const Value.absent(),
                Value<double> fat = const Value.absent(),
                Value<double> carbs = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> archived = const Value.absent(),
              }) => FoodsCompanion.insert(
                id: id,
                name: name,
                icon: icon,
                kcal: kcal,
                protein: protein,
                fat: fat,
                carbs: carbs,
                sortOrder: sortOrder,
                archived: archived,
              ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable<$FoodsTable, Food>(table), $$FoodsTableReferences(db, table, e))).toList(),
          prefetchHooksCallback: ({mealsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (mealsRefs) db.meals],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (mealsRefs)
                    await $_getPrefetchedDataByColumns<Food, $FoodsTable, Meal, $MealsTable>(
                      currentTable: table,
                      referencedTable: $$FoodsTableReferences._mealsRefsTable(db),
                      managerFromTypedResult: (p0) => $$FoodsTableReferences(db, table, p0).mealsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'food_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$FoodsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FoodsTable,
      Food,
      $$FoodsTableFilterComposer,
      $$FoodsTableOrderingComposer,
      $$FoodsTableAnnotationComposer,
      $$FoodsTableCreateCompanionBuilder,
      $$FoodsTableUpdateCompanionBuilder,
      (Food, $$FoodsTableReferences),
      Food,
      PrefetchHooks Function({bool mealsRefs})
    >;
typedef $$MealsTableCreateCompanionBuilder = MealsCompanion Function({
  Value<int> id,
  required int day,
  Value<DateTime> at,
  required String name,
  Value<String> icon,
  required double kcal,
  Value<double> protein,
  Value<double> fat,
  Value<double> carbs,
  Value<int?> slot,
  Value<int?> foodId,
});
typedef $$MealsTableUpdateCompanionBuilder = MealsCompanion Function({
  Value<int> id,
  Value<int> day,
  Value<DateTime> at,
  Value<String> name,
  Value<String> icon,
  Value<double> kcal,
  Value<double> protein,
  Value<double> fat,
  Value<double> carbs,
  Value<int?> slot,
  Value<int?> foodId,
});

final class $$MealsTableReferences extends BaseReferences<_$AppDatabase, $MealsTable, Meal> {
  $$MealsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FoodsTable _foodIdTable(_$AppDatabase db) => db.foods.createAlias('meals__food_id__foods__id');

  $$FoodsTableProcessedTableManager? get foodId {
    final $_column = $_itemColumn<int>('food_id');
    if ($_column == null) return null;
    final manager = $$FoodsTableTableManager($_db, $_db.foods).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_foodIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$MealsTableFilterComposer extends Composer<_$AppDatabase, $MealsTable> {
  $$MealsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get day => $composableBuilder(column: $table.day, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get at => $composableBuilder(column: $table.at, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get icon => $composableBuilder(column: $table.icon, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get kcal => $composableBuilder(column: $table.kcal, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get protein => $composableBuilder(column: $table.protein, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get fat => $composableBuilder(column: $table.fat, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get carbs => $composableBuilder(column: $table.carbs, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get slot => $composableBuilder(column: $table.slot, builder: (column) => ColumnFilters(column));

  $$FoodsTableFilterComposer get foodId {
    final $$FoodsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.foodId,
      referencedTable: $db.foods,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$FoodsTableFilterComposer(
        $db: $db,
        $table: $db.foods,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }
}

class $$MealsTableOrderingComposer extends Composer<_$AppDatabase, $MealsTable> {
  $$MealsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get day => $composableBuilder(column: $table.day, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get at => $composableBuilder(column: $table.at, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get icon => $composableBuilder(column: $table.icon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get kcal => $composableBuilder(column: $table.kcal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get protein => $composableBuilder(column: $table.protein, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get fat => $composableBuilder(column: $table.fat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get carbs => $composableBuilder(column: $table.carbs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get slot => $composableBuilder(column: $table.slot, builder: (column) => ColumnOrderings(column));

  $$FoodsTableOrderingComposer get foodId {
    final $$FoodsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.foodId,
      referencedTable: $db.foods,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$FoodsTableOrderingComposer(
        $db: $db,
        $table: $db.foods,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }
}

class $$MealsTableAnnotationComposer extends Composer<_$AppDatabase, $MealsTable> {
  $$MealsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get day => $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<DateTime> get at => $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get icon => $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<double> get kcal => $composableBuilder(column: $table.kcal, builder: (column) => column);

  GeneratedColumn<double> get protein => $composableBuilder(column: $table.protein, builder: (column) => column);

  GeneratedColumn<double> get fat => $composableBuilder(column: $table.fat, builder: (column) => column);

  GeneratedColumn<double> get carbs => $composableBuilder(column: $table.carbs, builder: (column) => column);

  GeneratedColumn<int> get slot => $composableBuilder(column: $table.slot, builder: (column) => column);

  $$FoodsTableAnnotationComposer get foodId {
    final $$FoodsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.foodId,
      referencedTable: $db.foods,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$FoodsTableAnnotationComposer(
        $db: $db,
        $table: $db.foods,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }
}

class $$MealsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MealsTable,
          Meal,
          $$MealsTableFilterComposer,
          $$MealsTableOrderingComposer,
          $$MealsTableAnnotationComposer,
          $$MealsTableCreateCompanionBuilder,
          $$MealsTableUpdateCompanionBuilder,
          (Meal, $$MealsTableReferences),
          Meal,
          PrefetchHooks Function({bool foodId})
        > {
  $$MealsTableTableManager(_$AppDatabase db, $MealsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$MealsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$MealsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$MealsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> day = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> icon = const Value.absent(),
                Value<double> kcal = const Value.absent(),
                Value<double> protein = const Value.absent(),
                Value<double> fat = const Value.absent(),
                Value<double> carbs = const Value.absent(),
                Value<int?> slot = const Value.absent(),
                Value<int?> foodId = const Value.absent(),
              }) => MealsCompanion(
                id: id,
                day: day,
                at: at,
                name: name,
                icon: icon,
                kcal: kcal,
                protein: protein,
                fat: fat,
                carbs: carbs,
                slot: slot,
                foodId: foodId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int day,
                Value<DateTime> at = const Value.absent(),
                required String name,
                Value<String> icon = const Value.absent(),
                required double kcal,
                Value<double> protein = const Value.absent(),
                Value<double> fat = const Value.absent(),
                Value<double> carbs = const Value.absent(),
                Value<int?> slot = const Value.absent(),
                Value<int?> foodId = const Value.absent(),
              }) => MealsCompanion.insert(
                id: id,
                day: day,
                at: at,
                name: name,
                icon: icon,
                kcal: kcal,
                protein: protein,
                fat: fat,
                carbs: carbs,
                slot: slot,
                foodId: foodId,
              ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable<$MealsTable, Meal>(table), $$MealsTableReferences(db, table, e))).toList(),
          prefetchHooksCallback: ({foodId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (foodId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.foodId,
                        referencedTable: $$MealsTableReferences._foodIdTable(db),
                        referencedColumn: $$MealsTableReferences._foodIdTable(db).id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MealsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MealsTable,
      Meal,
      $$MealsTableFilterComposer,
      $$MealsTableOrderingComposer,
      $$MealsTableAnnotationComposer,
      $$MealsTableCreateCompanionBuilder,
      $$MealsTableUpdateCompanionBuilder,
      (Meal, $$MealsTableReferences),
      Meal,
      PrefetchHooks Function({bool foodId})
    >;
typedef $$WaterLogsTableCreateCompanionBuilder = WaterLogsCompanion Function({
  Value<int> id,
  required int day,
  Value<DateTime> at,
  required int ml,
});
typedef $$WaterLogsTableUpdateCompanionBuilder = WaterLogsCompanion Function({
  Value<int> id,
  Value<int> day,
  Value<DateTime> at,
  Value<int> ml,
});

class $$WaterLogsTableFilterComposer extends Composer<_$AppDatabase, $WaterLogsTable> {
  $$WaterLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get day => $composableBuilder(column: $table.day, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get at => $composableBuilder(column: $table.at, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get ml => $composableBuilder(column: $table.ml, builder: (column) => ColumnFilters(column));
}

class $$WaterLogsTableOrderingComposer extends Composer<_$AppDatabase, $WaterLogsTable> {
  $$WaterLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get day => $composableBuilder(column: $table.day, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get at => $composableBuilder(column: $table.at, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get ml => $composableBuilder(column: $table.ml, builder: (column) => ColumnOrderings(column));
}

class $$WaterLogsTableAnnotationComposer extends Composer<_$AppDatabase, $WaterLogsTable> {
  $$WaterLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get day => $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<DateTime> get at => $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<int> get ml => $composableBuilder(column: $table.ml, builder: (column) => column);
}

class $$WaterLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WaterLogsTable,
          WaterLog,
          $$WaterLogsTableFilterComposer,
          $$WaterLogsTableOrderingComposer,
          $$WaterLogsTableAnnotationComposer,
          $$WaterLogsTableCreateCompanionBuilder,
          $$WaterLogsTableUpdateCompanionBuilder,
          (WaterLog, BaseReferences<_$AppDatabase, $WaterLogsTable, WaterLog>),
          WaterLog,
          PrefetchHooks Function()
        > {
  $$WaterLogsTableTableManager(_$AppDatabase db, $WaterLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$WaterLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$WaterLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$WaterLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> day = const Value.absent(),
            Value<DateTime> at = const Value.absent(),
            Value<int> ml = const Value.absent(),
          }) => WaterLogsCompanion(id: id, day: day, at: at, ml: ml),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int day,
            Value<DateTime> at = const Value.absent(),
            required int ml,
          }) => WaterLogsCompanion.insert(id: id, day: day, at: at, ml: ml),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable<$WaterLogsTable, WaterLog>(table), BaseReferences<_$AppDatabase, $WaterLogsTable, WaterLog>(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WaterLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WaterLogsTable,
      WaterLog,
      $$WaterLogsTableFilterComposer,
      $$WaterLogsTableOrderingComposer,
      $$WaterLogsTableAnnotationComposer,
      $$WaterLogsTableCreateCompanionBuilder,
      $$WaterLogsTableUpdateCompanionBuilder,
      (WaterLog, BaseReferences<_$AppDatabase, $WaterLogsTable, WaterLog>),
      WaterLog,
      PrefetchHooks Function()
    >;
typedef $$HardDaysTableCreateCompanionBuilder = HardDaysCompanion Function({Value<int> day});
typedef $$HardDaysTableUpdateCompanionBuilder = HardDaysCompanion Function({Value<int> day});

class $$HardDaysTableFilterComposer extends Composer<_$AppDatabase, $HardDaysTable> {
  $$HardDaysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get day => $composableBuilder(column: $table.day, builder: (column) => ColumnFilters(column));
}

class $$HardDaysTableOrderingComposer extends Composer<_$AppDatabase, $HardDaysTable> {
  $$HardDaysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get day => $composableBuilder(column: $table.day, builder: (column) => ColumnOrderings(column));
}

class $$HardDaysTableAnnotationComposer extends Composer<_$AppDatabase, $HardDaysTable> {
  $$HardDaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get day => $composableBuilder(column: $table.day, builder: (column) => column);
}

class $$HardDaysTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HardDaysTable,
          HardDay,
          $$HardDaysTableFilterComposer,
          $$HardDaysTableOrderingComposer,
          $$HardDaysTableAnnotationComposer,
          $$HardDaysTableCreateCompanionBuilder,
          $$HardDaysTableUpdateCompanionBuilder,
          (HardDay, BaseReferences<_$AppDatabase, $HardDaysTable, HardDay>),
          HardDay,
          PrefetchHooks Function()
        > {
  $$HardDaysTableTableManager(_$AppDatabase db, $HardDaysTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$HardDaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$HardDaysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$HardDaysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({Value<int> day = const Value.absent()}) => HardDaysCompanion(day: day),
          createCompanionCallback: ({Value<int> day = const Value.absent()}) => HardDaysCompanion.insert(day: day),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (e.readTable<$HardDaysTable, HardDay>(table), BaseReferences<_$AppDatabase, $HardDaysTable, HardDay>(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HardDaysTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HardDaysTable,
      HardDay,
      $$HardDaysTableFilterComposer,
      $$HardDaysTableOrderingComposer,
      $$HardDaysTableAnnotationComposer,
      $$HardDaysTableCreateCompanionBuilder,
      $$HardDaysTableUpdateCompanionBuilder,
      (HardDay, BaseReferences<_$AppDatabase, $HardDaysTable, HardDay>),
      HardDay,
      PrefetchHooks Function()
    >;
typedef $$TimeBlocksTableCreateCompanionBuilder = TimeBlocksCompanion Function({
  Value<int> id,
  required String name,
  Value<String> icon,
  required BlockKind kind,
  required int start,
  required int end,
  Value<int> daysMask,
  Value<bool> remind,
  Value<String?> note,
});
typedef $$TimeBlocksTableUpdateCompanionBuilder = TimeBlocksCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> icon,
  Value<BlockKind> kind,
  Value<int> start,
  Value<int> end,
  Value<int> daysMask,
  Value<bool> remind,
  Value<String?> note,
});

class $$TimeBlocksTableFilterComposer extends Composer<_$AppDatabase, $TimeBlocksTable> {
  $$TimeBlocksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get icon => $composableBuilder(column: $table.icon, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<BlockKind, BlockKind, int> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get start => $composableBuilder(column: $table.start, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get end => $composableBuilder(column: $table.end, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get daysMask => $composableBuilder(column: $table.daysMask, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get remind => $composableBuilder(column: $table.remind, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(column: $table.note, builder: (column) => ColumnFilters(column));
}

class $$TimeBlocksTableOrderingComposer extends Composer<_$AppDatabase, $TimeBlocksTable> {
  $$TimeBlocksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get icon => $composableBuilder(column: $table.icon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get kind => $composableBuilder(column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get start => $composableBuilder(column: $table.start, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get end => $composableBuilder(column: $table.end, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get daysMask => $composableBuilder(column: $table.daysMask, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get remind => $composableBuilder(column: $table.remind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(column: $table.note, builder: (column) => ColumnOrderings(column));
}

class $$TimeBlocksTableAnnotationComposer extends Composer<_$AppDatabase, $TimeBlocksTable> {
  $$TimeBlocksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get icon => $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumnWithTypeConverter<BlockKind, int> get kind => $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get start => $composableBuilder(column: $table.start, builder: (column) => column);

  GeneratedColumn<int> get end => $composableBuilder(column: $table.end, builder: (column) => column);

  GeneratedColumn<int> get daysMask => $composableBuilder(column: $table.daysMask, builder: (column) => column);

  GeneratedColumn<bool> get remind => $composableBuilder(column: $table.remind, builder: (column) => column);

  GeneratedColumn<String> get note => $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$TimeBlocksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TimeBlocksTable,
          TimeBlock,
          $$TimeBlocksTableFilterComposer,
          $$TimeBlocksTableOrderingComposer,
          $$TimeBlocksTableAnnotationComposer,
          $$TimeBlocksTableCreateCompanionBuilder,
          $$TimeBlocksTableUpdateCompanionBuilder,
          (TimeBlock, BaseReferences<_$AppDatabase, $TimeBlocksTable, TimeBlock>),
          TimeBlock,
          PrefetchHooks Function()
        > {
  $$TimeBlocksTableTableManager(_$AppDatabase db, $TimeBlocksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$TimeBlocksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$TimeBlocksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$TimeBlocksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> icon = const Value.absent(),
                Value<BlockKind> kind = const Value.absent(),
                Value<int> start = const Value.absent(),
                Value<int> end = const Value.absent(),
                Value<int> daysMask = const Value.absent(),
                Value<bool> remind = const Value.absent(),
                Value<String?> note = const Value.absent(),
              }) => TimeBlocksCompanion(
                id: id,
                name: name,
                icon: icon,
                kind: kind,
                start: start,
                end: end,
                daysMask: daysMask,
                remind: remind,
                note: note,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String> icon = const Value.absent(),
                required BlockKind kind,
                required int start,
                required int end,
                Value<int> daysMask = const Value.absent(),
                Value<bool> remind = const Value.absent(),
                Value<String?> note = const Value.absent(),
              }) => TimeBlocksCompanion.insert(
                id: id,
                name: name,
                icon: icon,
                kind: kind,
                start: start,
                end: end,
                daysMask: daysMask,
                remind: remind,
                note: note,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TimeBlocksTable, TimeBlock>(table),
                  BaseReferences<_$AppDatabase, $TimeBlocksTable, TimeBlock>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TimeBlocksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TimeBlocksTable,
      TimeBlock,
      $$TimeBlocksTableFilterComposer,
      $$TimeBlocksTableOrderingComposer,
      $$TimeBlocksTableAnnotationComposer,
      $$TimeBlocksTableCreateCompanionBuilder,
      $$TimeBlocksTableUpdateCompanionBuilder,
      (TimeBlock, BaseReferences<_$AppDatabase, $TimeBlocksTable, TimeBlock>),
      TimeBlock,
      PrefetchHooks Function()
    >;
typedef $$BudgetLinesTableCreateCompanionBuilder = BudgetLinesCompanion Function({
  Value<int> id,
  required int month,
  Value<int?> categoryId,
  Value<int?> fundId,
  required double amount,
});
typedef $$BudgetLinesTableUpdateCompanionBuilder = BudgetLinesCompanion Function({
  Value<int> id,
  Value<int> month,
  Value<int?> categoryId,
  Value<int?> fundId,
  Value<double> amount,
});

final class $$BudgetLinesTableReferences extends BaseReferences<_$AppDatabase, $BudgetLinesTable, BudgetLine> {
  $$BudgetLinesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) => db.categories.createAlias('budget_lines__category_id__categories__id');

  $$CategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<int>('category_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager($_db, $_db.categories).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static $FundsTable _fundIdTable(_$AppDatabase db) => db.funds.createAlias('budget_lines__fund_id__funds__id');

  $$FundsTableProcessedTableManager? get fundId {
    final $_column = $_itemColumn<int>('fund_id');
    if ($_column == null) return null;
    final manager = $$FundsTableTableManager($_db, $_db.funds).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_fundIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$BudgetLinesTableFilterComposer extends Composer<_$AppDatabase, $BudgetLinesTable> {
  $$BudgetLinesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get month => $composableBuilder(column: $table.month, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(column: $table.amount, builder: (column) => ColumnFilters(column));

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$CategoriesTableFilterComposer(
        $db: $db,
        $table: $db.categories,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }

  $$FundsTableFilterComposer get fundId {
    final $$FundsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fundId,
      referencedTable: $db.funds,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$FundsTableFilterComposer(
        $db: $db,
        $table: $db.funds,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }
}

class $$BudgetLinesTableOrderingComposer extends Composer<_$AppDatabase, $BudgetLinesTable> {
  $$BudgetLinesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get month => $composableBuilder(column: $table.month, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(column: $table.amount, builder: (column) => ColumnOrderings(column));

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$CategoriesTableOrderingComposer(
        $db: $db,
        $table: $db.categories,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }

  $$FundsTableOrderingComposer get fundId {
    final $$FundsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fundId,
      referencedTable: $db.funds,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$FundsTableOrderingComposer(
        $db: $db,
        $table: $db.funds,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }
}

class $$BudgetLinesTableAnnotationComposer extends Composer<_$AppDatabase, $BudgetLinesTable> {
  $$BudgetLinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get month => $composableBuilder(column: $table.month, builder: (column) => column);

  GeneratedColumn<double> get amount => $composableBuilder(column: $table.amount, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$CategoriesTableAnnotationComposer(
        $db: $db,
        $table: $db.categories,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }

  $$FundsTableAnnotationComposer get fundId {
    final $$FundsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fundId,
      referencedTable: $db.funds,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) => $$FundsTableAnnotationComposer(
        $db: $db,
        $table: $db.funds,
        $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
        joinBuilder: joinBuilder,
        $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
      ),
    );
    return composer;
  }
}

class $$BudgetLinesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BudgetLinesTable,
          BudgetLine,
          $$BudgetLinesTableFilterComposer,
          $$BudgetLinesTableOrderingComposer,
          $$BudgetLinesTableAnnotationComposer,
          $$BudgetLinesTableCreateCompanionBuilder,
          $$BudgetLinesTableUpdateCompanionBuilder,
          (BudgetLine, $$BudgetLinesTableReferences),
          BudgetLine,
          PrefetchHooks Function({bool categoryId, bool fundId})
        > {
  $$BudgetLinesTableTableManager(_$AppDatabase db, $BudgetLinesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$BudgetLinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$BudgetLinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$BudgetLinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> month = const Value.absent(),
            Value<int?> categoryId = const Value.absent(),
            Value<int?> fundId = const Value.absent(),
            Value<double> amount = const Value.absent(),
          }) => BudgetLinesCompanion(id: id, month: month, categoryId: categoryId, fundId: fundId, amount: amount),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int month,
            Value<int?> categoryId = const Value.absent(),
            Value<int?> fundId = const Value.absent(),
            required double amount,
          }) => BudgetLinesCompanion.insert(id: id, month: month, categoryId: categoryId, fundId: fundId, amount: amount),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable<$BudgetLinesTable, BudgetLine>(table), $$BudgetLinesTableReferences(db, table, e))).toList(),
          prefetchHooksCallback: ({categoryId = false, fundId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (categoryId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.categoryId,
                        referencedTable: $$BudgetLinesTableReferences._categoryIdTable(db),
                        referencedColumn: $$BudgetLinesTableReferences._categoryIdTable(db).id,
                      ) as T;
                    }
                    if (fundId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.fundId,
                        referencedTable: $$BudgetLinesTableReferences._fundIdTable(db),
                        referencedColumn: $$BudgetLinesTableReferences._fundIdTable(db).id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$BudgetLinesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BudgetLinesTable,
      BudgetLine,
      $$BudgetLinesTableFilterComposer,
      $$BudgetLinesTableOrderingComposer,
      $$BudgetLinesTableAnnotationComposer,
      $$BudgetLinesTableCreateCompanionBuilder,
      $$BudgetLinesTableUpdateCompanionBuilder,
      (BudgetLine, $$BudgetLinesTableReferences),
      BudgetLine,
      PrefetchHooks Function({bool categoryId, bool fundId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TrackersTableTableManager get trackers => $$TrackersTableTableManager(_db, _db.trackers);
  $$TrackerEntriesTableTableManager get trackerEntries => $$TrackerEntriesTableTableManager(_db, _db.trackerEntries);
  $$HabitsTableTableManager get habits => $$HabitsTableTableManager(_db, _db.habits);
  $$HabitLogsTableTableManager get habitLogs => $$HabitLogsTableTableManager(_db, _db.habitLogs);
  $$FundsTableTableManager get funds => $$FundsTableTableManager(_db, _db.funds);
  $$GoalsTableTableManager get goals => $$GoalsTableTableManager(_db, _db.goals);
  $$CategoriesTableTableManager get categories => $$CategoriesTableTableManager(_db, _db.categories);
  $$TransactionsTableTableManager get transactions => $$TransactionsTableTableManager(_db, _db.transactions);
  $$FundMovesTableTableManager get fundMoves => $$FundMovesTableTableManager(_db, _db.fundMoves);
  $$ProgramsTableTableManager get programs => $$ProgramsTableTableManager(_db, _db.programs);
  $$ProgramExercisesTableTableManager get programExercises => $$ProgramExercisesTableTableManager(_db, _db.programExercises);
  $$WorkoutSessionsTableTableManager get workoutSessions => $$WorkoutSessionsTableTableManager(_db, _db.workoutSessions);
  $$SessionSetsTableTableManager get sessionSets => $$SessionSetsTableTableManager(_db, _db.sessionSets);
  $$JournalEntriesTableTableManager get journalEntries => $$JournalEntriesTableTableManager(_db, _db.journalEntries);
  $$RemindersTableTableManager get reminders => $$RemindersTableTableManager(_db, _db.reminders);
  $$SettingsTableTableManager get settings => $$SettingsTableTableManager(_db, _db.settings);
  $$SleepLogsTableTableManager get sleepLogs => $$SleepLogsTableTableManager(_db, _db.sleepLogs);
  $$FoodsTableTableManager get foods => $$FoodsTableTableManager(_db, _db.foods);
  $$MealsTableTableManager get meals => $$MealsTableTableManager(_db, _db.meals);
  $$WaterLogsTableTableManager get waterLogs => $$WaterLogsTableTableManager(_db, _db.waterLogs);
  $$HardDaysTableTableManager get hardDays => $$HardDaysTableTableManager(_db, _db.hardDays);
  $$TimeBlocksTableTableManager get timeBlocks => $$TimeBlocksTableTableManager(_db, _db.timeBlocks);
  $$BudgetLinesTableTableManager get budgetLines => $$BudgetLinesTableTableManager(_db, _db.budgetLines);
}
