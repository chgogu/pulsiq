// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $FoodEntriesTable extends FoodEntries
    with TableInfo<$FoodEntriesTable, FoodEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoodEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<String> quantity = GeneratedColumn<String>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  late final GeneratedColumnWithTypeConverter<FuelQuality, String>
  qualityScore = GeneratedColumn<String>(
    'quality_score',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<FuelQuality>($FoodEntriesTable.$converterqualityScore);
  static const VerificationMeta _caloriesKcalMeta = const VerificationMeta(
    'caloriesKcal',
  );
  @override
  late final GeneratedColumn<int> caloriesKcal = GeneratedColumn<int>(
    'calories_kcal',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _proteinGMeta = const VerificationMeta(
    'proteinG',
  );
  @override
  late final GeneratedColumn<double> proteinG = GeneratedColumn<double>(
    'protein_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fiberGMeta = const VerificationMeta('fiberG');
  @override
  late final GeneratedColumn<double> fiberG = GeneratedColumn<double>(
    'fiber_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _carbsGMeta = const VerificationMeta('carbsG');
  @override
  late final GeneratedColumn<double> carbsG = GeneratedColumn<double>(
    'carbs_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fatGMeta = const VerificationMeta('fatG');
  @override
  late final GeneratedColumn<double> fatG = GeneratedColumn<double>(
    'fat_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('manual'),
  );
  static const VerificationMeta _loggedAtMeta = const VerificationMeta(
    'loggedAt',
  );
  @override
  late final GeneratedColumn<DateTime> loggedAt = GeneratedColumn<DateTime>(
    'logged_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    quantity,
    qualityScore,
    caloriesKcal,
    proteinG,
    fiberG,
    carbsG,
    fatG,
    source,
    loggedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'food_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<FoodEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    }
    if (data.containsKey('calories_kcal')) {
      context.handle(
        _caloriesKcalMeta,
        caloriesKcal.isAcceptableOrUnknown(
          data['calories_kcal']!,
          _caloriesKcalMeta,
        ),
      );
    }
    if (data.containsKey('protein_g')) {
      context.handle(
        _proteinGMeta,
        proteinG.isAcceptableOrUnknown(data['protein_g']!, _proteinGMeta),
      );
    }
    if (data.containsKey('fiber_g')) {
      context.handle(
        _fiberGMeta,
        fiberG.isAcceptableOrUnknown(data['fiber_g']!, _fiberGMeta),
      );
    }
    if (data.containsKey('carbs_g')) {
      context.handle(
        _carbsGMeta,
        carbsG.isAcceptableOrUnknown(data['carbs_g']!, _carbsGMeta),
      );
    }
    if (data.containsKey('fat_g')) {
      context.handle(
        _fatGMeta,
        fatG.isAcceptableOrUnknown(data['fat_g']!, _fatGMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('logged_at')) {
      context.handle(
        _loggedAtMeta,
        loggedAt.isAcceptableOrUnknown(data['logged_at']!, _loggedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_loggedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FoodEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FoodEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quantity'],
      )!,
      qualityScore: $FoodEntriesTable.$converterqualityScore.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}quality_score'],
        )!,
      ),
      caloriesKcal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}calories_kcal'],
      ),
      proteinG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein_g'],
      ),
      fiberG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fiber_g'],
      ),
      carbsG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carbs_g'],
      ),
      fatG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat_g'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      loggedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}logged_at'],
      )!,
    );
  }

  @override
  $FoodEntriesTable createAlias(String alias) {
    return $FoodEntriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<FuelQuality, String, String>
  $converterqualityScore = const EnumNameConverter<FuelQuality>(
    FuelQuality.values,
  );
}

class FoodEntry extends DataClass implements Insertable<FoodEntry> {
  final int id;
  final String name;
  final String quantity;
  final FuelQuality qualityScore;
  final int? caloriesKcal;
  final double? proteinG;
  final double? fiberG;
  final double? carbsG;
  final double? fatG;
  final String source;
  final DateTime loggedAt;
  const FoodEntry({
    required this.id,
    required this.name,
    required this.quantity,
    required this.qualityScore,
    this.caloriesKcal,
    this.proteinG,
    this.fiberG,
    this.carbsG,
    this.fatG,
    required this.source,
    required this.loggedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['quantity'] = Variable<String>(quantity);
    {
      map['quality_score'] = Variable<String>(
        $FoodEntriesTable.$converterqualityScore.toSql(qualityScore),
      );
    }
    if (!nullToAbsent || caloriesKcal != null) {
      map['calories_kcal'] = Variable<int>(caloriesKcal);
    }
    if (!nullToAbsent || proteinG != null) {
      map['protein_g'] = Variable<double>(proteinG);
    }
    if (!nullToAbsent || fiberG != null) {
      map['fiber_g'] = Variable<double>(fiberG);
    }
    if (!nullToAbsent || carbsG != null) {
      map['carbs_g'] = Variable<double>(carbsG);
    }
    if (!nullToAbsent || fatG != null) {
      map['fat_g'] = Variable<double>(fatG);
    }
    map['source'] = Variable<String>(source);
    map['logged_at'] = Variable<DateTime>(loggedAt);
    return map;
  }

  FoodEntriesCompanion toCompanion(bool nullToAbsent) {
    return FoodEntriesCompanion(
      id: Value(id),
      name: Value(name),
      quantity: Value(quantity),
      qualityScore: Value(qualityScore),
      caloriesKcal: caloriesKcal == null && nullToAbsent
          ? const Value.absent()
          : Value(caloriesKcal),
      proteinG: proteinG == null && nullToAbsent
          ? const Value.absent()
          : Value(proteinG),
      fiberG: fiberG == null && nullToAbsent
          ? const Value.absent()
          : Value(fiberG),
      carbsG: carbsG == null && nullToAbsent
          ? const Value.absent()
          : Value(carbsG),
      fatG: fatG == null && nullToAbsent ? const Value.absent() : Value(fatG),
      source: Value(source),
      loggedAt: Value(loggedAt),
    );
  }

  factory FoodEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FoodEntry(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      quantity: serializer.fromJson<String>(json['quantity']),
      qualityScore: $FoodEntriesTable.$converterqualityScore.fromJson(
        serializer.fromJson<String>(json['qualityScore']),
      ),
      caloriesKcal: serializer.fromJson<int?>(json['caloriesKcal']),
      proteinG: serializer.fromJson<double?>(json['proteinG']),
      fiberG: serializer.fromJson<double?>(json['fiberG']),
      carbsG: serializer.fromJson<double?>(json['carbsG']),
      fatG: serializer.fromJson<double?>(json['fatG']),
      source: serializer.fromJson<String>(json['source']),
      loggedAt: serializer.fromJson<DateTime>(json['loggedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'quantity': serializer.toJson<String>(quantity),
      'qualityScore': serializer.toJson<String>(
        $FoodEntriesTable.$converterqualityScore.toJson(qualityScore),
      ),
      'caloriesKcal': serializer.toJson<int?>(caloriesKcal),
      'proteinG': serializer.toJson<double?>(proteinG),
      'fiberG': serializer.toJson<double?>(fiberG),
      'carbsG': serializer.toJson<double?>(carbsG),
      'fatG': serializer.toJson<double?>(fatG),
      'source': serializer.toJson<String>(source),
      'loggedAt': serializer.toJson<DateTime>(loggedAt),
    };
  }

  FoodEntry copyWith({
    int? id,
    String? name,
    String? quantity,
    FuelQuality? qualityScore,
    Value<int?> caloriesKcal = const Value.absent(),
    Value<double?> proteinG = const Value.absent(),
    Value<double?> fiberG = const Value.absent(),
    Value<double?> carbsG = const Value.absent(),
    Value<double?> fatG = const Value.absent(),
    String? source,
    DateTime? loggedAt,
  }) => FoodEntry(
    id: id ?? this.id,
    name: name ?? this.name,
    quantity: quantity ?? this.quantity,
    qualityScore: qualityScore ?? this.qualityScore,
    caloriesKcal: caloriesKcal.present ? caloriesKcal.value : this.caloriesKcal,
    proteinG: proteinG.present ? proteinG.value : this.proteinG,
    fiberG: fiberG.present ? fiberG.value : this.fiberG,
    carbsG: carbsG.present ? carbsG.value : this.carbsG,
    fatG: fatG.present ? fatG.value : this.fatG,
    source: source ?? this.source,
    loggedAt: loggedAt ?? this.loggedAt,
  );
  FoodEntry copyWithCompanion(FoodEntriesCompanion data) {
    return FoodEntry(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      qualityScore: data.qualityScore.present
          ? data.qualityScore.value
          : this.qualityScore,
      caloriesKcal: data.caloriesKcal.present
          ? data.caloriesKcal.value
          : this.caloriesKcal,
      proteinG: data.proteinG.present ? data.proteinG.value : this.proteinG,
      fiberG: data.fiberG.present ? data.fiberG.value : this.fiberG,
      carbsG: data.carbsG.present ? data.carbsG.value : this.carbsG,
      fatG: data.fatG.present ? data.fatG.value : this.fatG,
      source: data.source.present ? data.source.value : this.source,
      loggedAt: data.loggedAt.present ? data.loggedAt.value : this.loggedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FoodEntry(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('quantity: $quantity, ')
          ..write('qualityScore: $qualityScore, ')
          ..write('caloriesKcal: $caloriesKcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('fiberG: $fiberG, ')
          ..write('carbsG: $carbsG, ')
          ..write('fatG: $fatG, ')
          ..write('source: $source, ')
          ..write('loggedAt: $loggedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    quantity,
    qualityScore,
    caloriesKcal,
    proteinG,
    fiberG,
    carbsG,
    fatG,
    source,
    loggedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FoodEntry &&
          other.id == this.id &&
          other.name == this.name &&
          other.quantity == this.quantity &&
          other.qualityScore == this.qualityScore &&
          other.caloriesKcal == this.caloriesKcal &&
          other.proteinG == this.proteinG &&
          other.fiberG == this.fiberG &&
          other.carbsG == this.carbsG &&
          other.fatG == this.fatG &&
          other.source == this.source &&
          other.loggedAt == this.loggedAt);
}

class FoodEntriesCompanion extends UpdateCompanion<FoodEntry> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> quantity;
  final Value<FuelQuality> qualityScore;
  final Value<int?> caloriesKcal;
  final Value<double?> proteinG;
  final Value<double?> fiberG;
  final Value<double?> carbsG;
  final Value<double?> fatG;
  final Value<String> source;
  final Value<DateTime> loggedAt;
  const FoodEntriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.quantity = const Value.absent(),
    this.qualityScore = const Value.absent(),
    this.caloriesKcal = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.fiberG = const Value.absent(),
    this.carbsG = const Value.absent(),
    this.fatG = const Value.absent(),
    this.source = const Value.absent(),
    this.loggedAt = const Value.absent(),
  });
  FoodEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.quantity = const Value.absent(),
    required FuelQuality qualityScore,
    this.caloriesKcal = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.fiberG = const Value.absent(),
    this.carbsG = const Value.absent(),
    this.fatG = const Value.absent(),
    this.source = const Value.absent(),
    required DateTime loggedAt,
  }) : name = Value(name),
       qualityScore = Value(qualityScore),
       loggedAt = Value(loggedAt);
  static Insertable<FoodEntry> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? quantity,
    Expression<String>? qualityScore,
    Expression<int>? caloriesKcal,
    Expression<double>? proteinG,
    Expression<double>? fiberG,
    Expression<double>? carbsG,
    Expression<double>? fatG,
    Expression<String>? source,
    Expression<DateTime>? loggedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (quantity != null) 'quantity': quantity,
      if (qualityScore != null) 'quality_score': qualityScore,
      if (caloriesKcal != null) 'calories_kcal': caloriesKcal,
      if (proteinG != null) 'protein_g': proteinG,
      if (fiberG != null) 'fiber_g': fiberG,
      if (carbsG != null) 'carbs_g': carbsG,
      if (fatG != null) 'fat_g': fatG,
      if (source != null) 'source': source,
      if (loggedAt != null) 'logged_at': loggedAt,
    });
  }

  FoodEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? quantity,
    Value<FuelQuality>? qualityScore,
    Value<int?>? caloriesKcal,
    Value<double?>? proteinG,
    Value<double?>? fiberG,
    Value<double?>? carbsG,
    Value<double?>? fatG,
    Value<String>? source,
    Value<DateTime>? loggedAt,
  }) {
    return FoodEntriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      qualityScore: qualityScore ?? this.qualityScore,
      caloriesKcal: caloriesKcal ?? this.caloriesKcal,
      proteinG: proteinG ?? this.proteinG,
      fiberG: fiberG ?? this.fiberG,
      carbsG: carbsG ?? this.carbsG,
      fatG: fatG ?? this.fatG,
      source: source ?? this.source,
      loggedAt: loggedAt ?? this.loggedAt,
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
    if (quantity.present) {
      map['quantity'] = Variable<String>(quantity.value);
    }
    if (qualityScore.present) {
      map['quality_score'] = Variable<String>(
        $FoodEntriesTable.$converterqualityScore.toSql(qualityScore.value),
      );
    }
    if (caloriesKcal.present) {
      map['calories_kcal'] = Variable<int>(caloriesKcal.value);
    }
    if (proteinG.present) {
      map['protein_g'] = Variable<double>(proteinG.value);
    }
    if (fiberG.present) {
      map['fiber_g'] = Variable<double>(fiberG.value);
    }
    if (carbsG.present) {
      map['carbs_g'] = Variable<double>(carbsG.value);
    }
    if (fatG.present) {
      map['fat_g'] = Variable<double>(fatG.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (loggedAt.present) {
      map['logged_at'] = Variable<DateTime>(loggedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoodEntriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('quantity: $quantity, ')
          ..write('qualityScore: $qualityScore, ')
          ..write('caloriesKcal: $caloriesKcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('fiberG: $fiberG, ')
          ..write('carbsG: $carbsG, ')
          ..write('fatG: $fatG, ')
          ..write('source: $source, ')
          ..write('loggedAt: $loggedAt')
          ..write(')'))
        .toString();
  }
}

class $BeverageEntriesTable extends BeverageEntries
    with TableInfo<$BeverageEntriesTable, BeverageEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BeverageEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _volumeMlMeta = const VerificationMeta(
    'volumeMl',
  );
  @override
  late final GeneratedColumn<int> volumeMl = GeneratedColumn<int>(
    'volume_ml',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sugarContentGMeta = const VerificationMeta(
    'sugarContentG',
  );
  @override
  late final GeneratedColumn<double> sugarContentG = GeneratedColumn<double>(
    'sugar_content_g',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  late final GeneratedColumnWithTypeConverter<BeverageType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<BeverageType>($BeverageEntriesTable.$convertertype);
  static const VerificationMeta _loggedAtMeta = const VerificationMeta(
    'loggedAt',
  );
  @override
  late final GeneratedColumn<DateTime> loggedAt = GeneratedColumn<DateTime>(
    'logged_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    volumeMl,
    sugarContentG,
    type,
    loggedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'beverage_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<BeverageEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('volume_ml')) {
      context.handle(
        _volumeMlMeta,
        volumeMl.isAcceptableOrUnknown(data['volume_ml']!, _volumeMlMeta),
      );
    }
    if (data.containsKey('sugar_content_g')) {
      context.handle(
        _sugarContentGMeta,
        sugarContentG.isAcceptableOrUnknown(
          data['sugar_content_g']!,
          _sugarContentGMeta,
        ),
      );
    }
    if (data.containsKey('logged_at')) {
      context.handle(
        _loggedAtMeta,
        loggedAt.isAcceptableOrUnknown(data['logged_at']!, _loggedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_loggedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BeverageEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BeverageEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      volumeMl: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}volume_ml'],
      )!,
      sugarContentG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sugar_content_g'],
      )!,
      type: $BeverageEntriesTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      loggedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}logged_at'],
      )!,
    );
  }

  @override
  $BeverageEntriesTable createAlias(String alias) {
    return $BeverageEntriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<BeverageType, String, String> $convertertype =
      const EnumNameConverter<BeverageType>(BeverageType.values);
}

class BeverageEntry extends DataClass implements Insertable<BeverageEntry> {
  final int id;
  final String name;
  final int volumeMl;
  final double sugarContentG;
  final BeverageType type;
  final DateTime loggedAt;
  const BeverageEntry({
    required this.id,
    required this.name,
    required this.volumeMl,
    required this.sugarContentG,
    required this.type,
    required this.loggedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['volume_ml'] = Variable<int>(volumeMl);
    map['sugar_content_g'] = Variable<double>(sugarContentG);
    {
      map['type'] = Variable<String>(
        $BeverageEntriesTable.$convertertype.toSql(type),
      );
    }
    map['logged_at'] = Variable<DateTime>(loggedAt);
    return map;
  }

  BeverageEntriesCompanion toCompanion(bool nullToAbsent) {
    return BeverageEntriesCompanion(
      id: Value(id),
      name: Value(name),
      volumeMl: Value(volumeMl),
      sugarContentG: Value(sugarContentG),
      type: Value(type),
      loggedAt: Value(loggedAt),
    );
  }

  factory BeverageEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BeverageEntry(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      volumeMl: serializer.fromJson<int>(json['volumeMl']),
      sugarContentG: serializer.fromJson<double>(json['sugarContentG']),
      type: $BeverageEntriesTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      loggedAt: serializer.fromJson<DateTime>(json['loggedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'volumeMl': serializer.toJson<int>(volumeMl),
      'sugarContentG': serializer.toJson<double>(sugarContentG),
      'type': serializer.toJson<String>(
        $BeverageEntriesTable.$convertertype.toJson(type),
      ),
      'loggedAt': serializer.toJson<DateTime>(loggedAt),
    };
  }

  BeverageEntry copyWith({
    int? id,
    String? name,
    int? volumeMl,
    double? sugarContentG,
    BeverageType? type,
    DateTime? loggedAt,
  }) => BeverageEntry(
    id: id ?? this.id,
    name: name ?? this.name,
    volumeMl: volumeMl ?? this.volumeMl,
    sugarContentG: sugarContentG ?? this.sugarContentG,
    type: type ?? this.type,
    loggedAt: loggedAt ?? this.loggedAt,
  );
  BeverageEntry copyWithCompanion(BeverageEntriesCompanion data) {
    return BeverageEntry(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      volumeMl: data.volumeMl.present ? data.volumeMl.value : this.volumeMl,
      sugarContentG: data.sugarContentG.present
          ? data.sugarContentG.value
          : this.sugarContentG,
      type: data.type.present ? data.type.value : this.type,
      loggedAt: data.loggedAt.present ? data.loggedAt.value : this.loggedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BeverageEntry(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('volumeMl: $volumeMl, ')
          ..write('sugarContentG: $sugarContentG, ')
          ..write('type: $type, ')
          ..write('loggedAt: $loggedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, volumeMl, sugarContentG, type, loggedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BeverageEntry &&
          other.id == this.id &&
          other.name == this.name &&
          other.volumeMl == this.volumeMl &&
          other.sugarContentG == this.sugarContentG &&
          other.type == this.type &&
          other.loggedAt == this.loggedAt);
}

class BeverageEntriesCompanion extends UpdateCompanion<BeverageEntry> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> volumeMl;
  final Value<double> sugarContentG;
  final Value<BeverageType> type;
  final Value<DateTime> loggedAt;
  const BeverageEntriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.volumeMl = const Value.absent(),
    this.sugarContentG = const Value.absent(),
    this.type = const Value.absent(),
    this.loggedAt = const Value.absent(),
  });
  BeverageEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.volumeMl = const Value.absent(),
    this.sugarContentG = const Value.absent(),
    required BeverageType type,
    required DateTime loggedAt,
  }) : name = Value(name),
       type = Value(type),
       loggedAt = Value(loggedAt);
  static Insertable<BeverageEntry> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? volumeMl,
    Expression<double>? sugarContentG,
    Expression<String>? type,
    Expression<DateTime>? loggedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (volumeMl != null) 'volume_ml': volumeMl,
      if (sugarContentG != null) 'sugar_content_g': sugarContentG,
      if (type != null) 'type': type,
      if (loggedAt != null) 'logged_at': loggedAt,
    });
  }

  BeverageEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? volumeMl,
    Value<double>? sugarContentG,
    Value<BeverageType>? type,
    Value<DateTime>? loggedAt,
  }) {
    return BeverageEntriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      volumeMl: volumeMl ?? this.volumeMl,
      sugarContentG: sugarContentG ?? this.sugarContentG,
      type: type ?? this.type,
      loggedAt: loggedAt ?? this.loggedAt,
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
    if (volumeMl.present) {
      map['volume_ml'] = Variable<int>(volumeMl.value);
    }
    if (sugarContentG.present) {
      map['sugar_content_g'] = Variable<double>(sugarContentG.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $BeverageEntriesTable.$convertertype.toSql(type.value),
      );
    }
    if (loggedAt.present) {
      map['logged_at'] = Variable<DateTime>(loggedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BeverageEntriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('volumeMl: $volumeMl, ')
          ..write('sugarContentG: $sugarContentG, ')
          ..write('type: $type, ')
          ..write('loggedAt: $loggedAt')
          ..write(')'))
        .toString();
  }
}

class $HydrationEntriesTable extends HydrationEntries
    with TableInfo<$HydrationEntriesTable, HydrationEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HydrationEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _amountMlMeta = const VerificationMeta(
    'amountMl',
  );
  @override
  late final GeneratedColumn<int> amountMl = GeneratedColumn<int>(
    'amount_ml',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('manual'),
  );
  static const VerificationMeta _loggedAtMeta = const VerificationMeta(
    'loggedAt',
  );
  @override
  late final GeneratedColumn<DateTime> loggedAt = GeneratedColumn<DateTime>(
    'logged_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, amountMl, source, loggedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hydration_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<HydrationEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('amount_ml')) {
      context.handle(
        _amountMlMeta,
        amountMl.isAcceptableOrUnknown(data['amount_ml']!, _amountMlMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMlMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('logged_at')) {
      context.handle(
        _loggedAtMeta,
        loggedAt.isAcceptableOrUnknown(data['logged_at']!, _loggedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_loggedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HydrationEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HydrationEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      amountMl: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_ml'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      loggedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}logged_at'],
      )!,
    );
  }

  @override
  $HydrationEntriesTable createAlias(String alias) {
    return $HydrationEntriesTable(attachedDatabase, alias);
  }
}

class HydrationEntry extends DataClass implements Insertable<HydrationEntry> {
  final int id;
  final int amountMl;
  final String source;
  final DateTime loggedAt;
  const HydrationEntry({
    required this.id,
    required this.amountMl,
    required this.source,
    required this.loggedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['amount_ml'] = Variable<int>(amountMl);
    map['source'] = Variable<String>(source);
    map['logged_at'] = Variable<DateTime>(loggedAt);
    return map;
  }

  HydrationEntriesCompanion toCompanion(bool nullToAbsent) {
    return HydrationEntriesCompanion(
      id: Value(id),
      amountMl: Value(amountMl),
      source: Value(source),
      loggedAt: Value(loggedAt),
    );
  }

  factory HydrationEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HydrationEntry(
      id: serializer.fromJson<int>(json['id']),
      amountMl: serializer.fromJson<int>(json['amountMl']),
      source: serializer.fromJson<String>(json['source']),
      loggedAt: serializer.fromJson<DateTime>(json['loggedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'amountMl': serializer.toJson<int>(amountMl),
      'source': serializer.toJson<String>(source),
      'loggedAt': serializer.toJson<DateTime>(loggedAt),
    };
  }

  HydrationEntry copyWith({
    int? id,
    int? amountMl,
    String? source,
    DateTime? loggedAt,
  }) => HydrationEntry(
    id: id ?? this.id,
    amountMl: amountMl ?? this.amountMl,
    source: source ?? this.source,
    loggedAt: loggedAt ?? this.loggedAt,
  );
  HydrationEntry copyWithCompanion(HydrationEntriesCompanion data) {
    return HydrationEntry(
      id: data.id.present ? data.id.value : this.id,
      amountMl: data.amountMl.present ? data.amountMl.value : this.amountMl,
      source: data.source.present ? data.source.value : this.source,
      loggedAt: data.loggedAt.present ? data.loggedAt.value : this.loggedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HydrationEntry(')
          ..write('id: $id, ')
          ..write('amountMl: $amountMl, ')
          ..write('source: $source, ')
          ..write('loggedAt: $loggedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, amountMl, source, loggedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HydrationEntry &&
          other.id == this.id &&
          other.amountMl == this.amountMl &&
          other.source == this.source &&
          other.loggedAt == this.loggedAt);
}

class HydrationEntriesCompanion extends UpdateCompanion<HydrationEntry> {
  final Value<int> id;
  final Value<int> amountMl;
  final Value<String> source;
  final Value<DateTime> loggedAt;
  const HydrationEntriesCompanion({
    this.id = const Value.absent(),
    this.amountMl = const Value.absent(),
    this.source = const Value.absent(),
    this.loggedAt = const Value.absent(),
  });
  HydrationEntriesCompanion.insert({
    this.id = const Value.absent(),
    required int amountMl,
    this.source = const Value.absent(),
    required DateTime loggedAt,
  }) : amountMl = Value(amountMl),
       loggedAt = Value(loggedAt);
  static Insertable<HydrationEntry> custom({
    Expression<int>? id,
    Expression<int>? amountMl,
    Expression<String>? source,
    Expression<DateTime>? loggedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (amountMl != null) 'amount_ml': amountMl,
      if (source != null) 'source': source,
      if (loggedAt != null) 'logged_at': loggedAt,
    });
  }

  HydrationEntriesCompanion copyWith({
    Value<int>? id,
    Value<int>? amountMl,
    Value<String>? source,
    Value<DateTime>? loggedAt,
  }) {
    return HydrationEntriesCompanion(
      id: id ?? this.id,
      amountMl: amountMl ?? this.amountMl,
      source: source ?? this.source,
      loggedAt: loggedAt ?? this.loggedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (amountMl.present) {
      map['amount_ml'] = Variable<int>(amountMl.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (loggedAt.present) {
      map['logged_at'] = Variable<DateTime>(loggedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HydrationEntriesCompanion(')
          ..write('id: $id, ')
          ..write('amountMl: $amountMl, ')
          ..write('source: $source, ')
          ..write('loggedAt: $loggedAt')
          ..write(')'))
        .toString();
  }
}

class $ExerciseEntriesTable extends ExerciseEntries
    with TableInfo<$ExerciseEntriesTable, ExerciseEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExerciseEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _activityMeta = const VerificationMeta(
    'activity',
  );
  @override
  late final GeneratedColumn<String> activity = GeneratedColumn<String>(
    'activity',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMinutesMeta = const VerificationMeta(
    'durationMinutes',
  );
  @override
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
    'duration_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ExerciseIntensity, String>
  intensity = GeneratedColumn<String>(
    'intensity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<ExerciseIntensity>($ExerciseEntriesTable.$converterintensity);
  static const VerificationMeta _loggedAtMeta = const VerificationMeta(
    'loggedAt',
  );
  @override
  late final GeneratedColumn<DateTime> loggedAt = GeneratedColumn<DateTime>(
    'logged_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    activity,
    durationMinutes,
    intensity,
    loggedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercise_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExerciseEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('activity')) {
      context.handle(
        _activityMeta,
        activity.isAcceptableOrUnknown(data['activity']!, _activityMeta),
      );
    } else if (isInserting) {
      context.missing(_activityMeta);
    }
    if (data.containsKey('duration_minutes')) {
      context.handle(
        _durationMinutesMeta,
        durationMinutes.isAcceptableOrUnknown(
          data['duration_minutes']!,
          _durationMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationMinutesMeta);
    }
    if (data.containsKey('logged_at')) {
      context.handle(
        _loggedAtMeta,
        loggedAt.isAcceptableOrUnknown(data['logged_at']!, _loggedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_loggedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExerciseEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExerciseEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      activity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activity'],
      )!,
      durationMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_minutes'],
      )!,
      intensity: $ExerciseEntriesTable.$converterintensity.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}intensity'],
        )!,
      ),
      loggedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}logged_at'],
      )!,
    );
  }

  @override
  $ExerciseEntriesTable createAlias(String alias) {
    return $ExerciseEntriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ExerciseIntensity, String, String>
  $converterintensity = const EnumNameConverter<ExerciseIntensity>(
    ExerciseIntensity.values,
  );
}

class ExerciseEntry extends DataClass implements Insertable<ExerciseEntry> {
  final int id;
  final String activity;
  final int durationMinutes;
  final ExerciseIntensity intensity;
  final DateTime loggedAt;
  const ExerciseEntry({
    required this.id,
    required this.activity,
    required this.durationMinutes,
    required this.intensity,
    required this.loggedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['activity'] = Variable<String>(activity);
    map['duration_minutes'] = Variable<int>(durationMinutes);
    {
      map['intensity'] = Variable<String>(
        $ExerciseEntriesTable.$converterintensity.toSql(intensity),
      );
    }
    map['logged_at'] = Variable<DateTime>(loggedAt);
    return map;
  }

  ExerciseEntriesCompanion toCompanion(bool nullToAbsent) {
    return ExerciseEntriesCompanion(
      id: Value(id),
      activity: Value(activity),
      durationMinutes: Value(durationMinutes),
      intensity: Value(intensity),
      loggedAt: Value(loggedAt),
    );
  }

  factory ExerciseEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExerciseEntry(
      id: serializer.fromJson<int>(json['id']),
      activity: serializer.fromJson<String>(json['activity']),
      durationMinutes: serializer.fromJson<int>(json['durationMinutes']),
      intensity: $ExerciseEntriesTable.$converterintensity.fromJson(
        serializer.fromJson<String>(json['intensity']),
      ),
      loggedAt: serializer.fromJson<DateTime>(json['loggedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'activity': serializer.toJson<String>(activity),
      'durationMinutes': serializer.toJson<int>(durationMinutes),
      'intensity': serializer.toJson<String>(
        $ExerciseEntriesTable.$converterintensity.toJson(intensity),
      ),
      'loggedAt': serializer.toJson<DateTime>(loggedAt),
    };
  }

  ExerciseEntry copyWith({
    int? id,
    String? activity,
    int? durationMinutes,
    ExerciseIntensity? intensity,
    DateTime? loggedAt,
  }) => ExerciseEntry(
    id: id ?? this.id,
    activity: activity ?? this.activity,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    intensity: intensity ?? this.intensity,
    loggedAt: loggedAt ?? this.loggedAt,
  );
  ExerciseEntry copyWithCompanion(ExerciseEntriesCompanion data) {
    return ExerciseEntry(
      id: data.id.present ? data.id.value : this.id,
      activity: data.activity.present ? data.activity.value : this.activity,
      durationMinutes: data.durationMinutes.present
          ? data.durationMinutes.value
          : this.durationMinutes,
      intensity: data.intensity.present ? data.intensity.value : this.intensity,
      loggedAt: data.loggedAt.present ? data.loggedAt.value : this.loggedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseEntry(')
          ..write('id: $id, ')
          ..write('activity: $activity, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('intensity: $intensity, ')
          ..write('loggedAt: $loggedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, activity, durationMinutes, intensity, loggedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExerciseEntry &&
          other.id == this.id &&
          other.activity == this.activity &&
          other.durationMinutes == this.durationMinutes &&
          other.intensity == this.intensity &&
          other.loggedAt == this.loggedAt);
}

class ExerciseEntriesCompanion extends UpdateCompanion<ExerciseEntry> {
  final Value<int> id;
  final Value<String> activity;
  final Value<int> durationMinutes;
  final Value<ExerciseIntensity> intensity;
  final Value<DateTime> loggedAt;
  const ExerciseEntriesCompanion({
    this.id = const Value.absent(),
    this.activity = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.intensity = const Value.absent(),
    this.loggedAt = const Value.absent(),
  });
  ExerciseEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String activity,
    required int durationMinutes,
    required ExerciseIntensity intensity,
    required DateTime loggedAt,
  }) : activity = Value(activity),
       durationMinutes = Value(durationMinutes),
       intensity = Value(intensity),
       loggedAt = Value(loggedAt);
  static Insertable<ExerciseEntry> custom({
    Expression<int>? id,
    Expression<String>? activity,
    Expression<int>? durationMinutes,
    Expression<String>? intensity,
    Expression<DateTime>? loggedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (activity != null) 'activity': activity,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (intensity != null) 'intensity': intensity,
      if (loggedAt != null) 'logged_at': loggedAt,
    });
  }

  ExerciseEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? activity,
    Value<int>? durationMinutes,
    Value<ExerciseIntensity>? intensity,
    Value<DateTime>? loggedAt,
  }) {
    return ExerciseEntriesCompanion(
      id: id ?? this.id,
      activity: activity ?? this.activity,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      intensity: intensity ?? this.intensity,
      loggedAt: loggedAt ?? this.loggedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (activity.present) {
      map['activity'] = Variable<String>(activity.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
    }
    if (intensity.present) {
      map['intensity'] = Variable<String>(
        $ExerciseEntriesTable.$converterintensity.toSql(intensity.value),
      );
    }
    if (loggedAt.present) {
      map['logged_at'] = Variable<DateTime>(loggedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseEntriesCompanion(')
          ..write('id: $id, ')
          ..write('activity: $activity, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('intensity: $intensity, ')
          ..write('loggedAt: $loggedAt')
          ..write(')'))
        .toString();
  }
}

class $WalkSessionsTable extends WalkSessions
    with TableInfo<$WalkSessionsTable, WalkSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WalkSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _targetMinutesMeta = const VerificationMeta(
    'targetMinutes',
  );
  @override
  late final GeneratedColumn<int> targetMinutes = GeneratedColumn<int>(
    'target_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('manual'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    targetMinutes,
    startedAt,
    completedAt,
    source,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'walk_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<WalkSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('target_minutes')) {
      context.handle(
        _targetMinutesMeta,
        targetMinutes.isAcceptableOrUnknown(
          data['target_minutes']!,
          _targetMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetMinutesMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WalkSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WalkSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      targetMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_minutes'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
    );
  }

  @override
  $WalkSessionsTable createAlias(String alias) {
    return $WalkSessionsTable(attachedDatabase, alias);
  }
}

class WalkSession extends DataClass implements Insertable<WalkSession> {
  final int id;
  final int targetMinutes;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String source;
  const WalkSession({
    required this.id,
    required this.targetMinutes,
    required this.startedAt,
    this.completedAt,
    required this.source,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['target_minutes'] = Variable<int>(targetMinutes);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    map['source'] = Variable<String>(source);
    return map;
  }

  WalkSessionsCompanion toCompanion(bool nullToAbsent) {
    return WalkSessionsCompanion(
      id: Value(id),
      targetMinutes: Value(targetMinutes),
      startedAt: Value(startedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      source: Value(source),
    );
  }

  factory WalkSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WalkSession(
      id: serializer.fromJson<int>(json['id']),
      targetMinutes: serializer.fromJson<int>(json['targetMinutes']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      source: serializer.fromJson<String>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'targetMinutes': serializer.toJson<int>(targetMinutes),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'source': serializer.toJson<String>(source),
    };
  }

  WalkSession copyWith({
    int? id,
    int? targetMinutes,
    DateTime? startedAt,
    Value<DateTime?> completedAt = const Value.absent(),
    String? source,
  }) => WalkSession(
    id: id ?? this.id,
    targetMinutes: targetMinutes ?? this.targetMinutes,
    startedAt: startedAt ?? this.startedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    source: source ?? this.source,
  );
  WalkSession copyWithCompanion(WalkSessionsCompanion data) {
    return WalkSession(
      id: data.id.present ? data.id.value : this.id,
      targetMinutes: data.targetMinutes.present
          ? data.targetMinutes.value
          : this.targetMinutes,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WalkSession(')
          ..write('id: $id, ')
          ..write('targetMinutes: $targetMinutes, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, targetMinutes, startedAt, completedAt, source);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WalkSession &&
          other.id == this.id &&
          other.targetMinutes == this.targetMinutes &&
          other.startedAt == this.startedAt &&
          other.completedAt == this.completedAt &&
          other.source == this.source);
}

class WalkSessionsCompanion extends UpdateCompanion<WalkSession> {
  final Value<int> id;
  final Value<int> targetMinutes;
  final Value<DateTime> startedAt;
  final Value<DateTime?> completedAt;
  final Value<String> source;
  const WalkSessionsCompanion({
    this.id = const Value.absent(),
    this.targetMinutes = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.source = const Value.absent(),
  });
  WalkSessionsCompanion.insert({
    this.id = const Value.absent(),
    required int targetMinutes,
    required DateTime startedAt,
    this.completedAt = const Value.absent(),
    this.source = const Value.absent(),
  }) : targetMinutes = Value(targetMinutes),
       startedAt = Value(startedAt);
  static Insertable<WalkSession> custom({
    Expression<int>? id,
    Expression<int>? targetMinutes,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? completedAt,
    Expression<String>? source,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (targetMinutes != null) 'target_minutes': targetMinutes,
      if (startedAt != null) 'started_at': startedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (source != null) 'source': source,
    });
  }

  WalkSessionsCompanion copyWith({
    Value<int>? id,
    Value<int>? targetMinutes,
    Value<DateTime>? startedAt,
    Value<DateTime?>? completedAt,
    Value<String>? source,
  }) {
    return WalkSessionsCompanion(
      id: id ?? this.id,
      targetMinutes: targetMinutes ?? this.targetMinutes,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      source: source ?? this.source,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (targetMinutes.present) {
      map['target_minutes'] = Variable<int>(targetMinutes.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WalkSessionsCompanion(')
          ..write('id: $id, ')
          ..write('targetMinutes: $targetMinutes, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }
}

class $AuditEventsTable extends AuditEvents
    with TableInfo<$AuditEventsTable, AuditEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AuditEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataTypeMeta = const VerificationMeta(
    'dataType',
  );
  @override
  late final GeneratedColumn<String> dataType = GeneratedColumn<String>(
    'data_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _purposeMeta = const VerificationMeta(
    'purpose',
  );
  @override
  late final GeneratedColumn<String> purpose = GeneratedColumn<String>(
    'purpose',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    at,
    action,
    dataType,
    source,
    purpose,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audit_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<AuditEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('data_type')) {
      context.handle(
        _dataTypeMeta,
        dataType.isAcceptableOrUnknown(data['data_type']!, _dataTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_dataTypeMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('purpose')) {
      context.handle(
        _purposeMeta,
        purpose.isAcceptableOrUnknown(data['purpose']!, _purposeMeta),
      );
    } else if (isInserting) {
      context.missing(_purposeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AuditEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AuditEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      dataType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data_type'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      purpose: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}purpose'],
      )!,
    );
  }

  @override
  $AuditEventsTable createAlias(String alias) {
    return $AuditEventsTable(attachedDatabase, alias);
  }
}

class AuditEvent extends DataClass implements Insertable<AuditEvent> {
  final int id;
  final DateTime at;
  final String action;
  final String dataType;
  final String source;
  final String purpose;
  const AuditEvent({
    required this.id,
    required this.at,
    required this.action,
    required this.dataType,
    required this.source,
    required this.purpose,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['at'] = Variable<DateTime>(at);
    map['action'] = Variable<String>(action);
    map['data_type'] = Variable<String>(dataType);
    map['source'] = Variable<String>(source);
    map['purpose'] = Variable<String>(purpose);
    return map;
  }

  AuditEventsCompanion toCompanion(bool nullToAbsent) {
    return AuditEventsCompanion(
      id: Value(id),
      at: Value(at),
      action: Value(action),
      dataType: Value(dataType),
      source: Value(source),
      purpose: Value(purpose),
    );
  }

  factory AuditEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AuditEvent(
      id: serializer.fromJson<int>(json['id']),
      at: serializer.fromJson<DateTime>(json['at']),
      action: serializer.fromJson<String>(json['action']),
      dataType: serializer.fromJson<String>(json['dataType']),
      source: serializer.fromJson<String>(json['source']),
      purpose: serializer.fromJson<String>(json['purpose']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'at': serializer.toJson<DateTime>(at),
      'action': serializer.toJson<String>(action),
      'dataType': serializer.toJson<String>(dataType),
      'source': serializer.toJson<String>(source),
      'purpose': serializer.toJson<String>(purpose),
    };
  }

  AuditEvent copyWith({
    int? id,
    DateTime? at,
    String? action,
    String? dataType,
    String? source,
    String? purpose,
  }) => AuditEvent(
    id: id ?? this.id,
    at: at ?? this.at,
    action: action ?? this.action,
    dataType: dataType ?? this.dataType,
    source: source ?? this.source,
    purpose: purpose ?? this.purpose,
  );
  AuditEvent copyWithCompanion(AuditEventsCompanion data) {
    return AuditEvent(
      id: data.id.present ? data.id.value : this.id,
      at: data.at.present ? data.at.value : this.at,
      action: data.action.present ? data.action.value : this.action,
      dataType: data.dataType.present ? data.dataType.value : this.dataType,
      source: data.source.present ? data.source.value : this.source,
      purpose: data.purpose.present ? data.purpose.value : this.purpose,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AuditEvent(')
          ..write('id: $id, ')
          ..write('at: $at, ')
          ..write('action: $action, ')
          ..write('dataType: $dataType, ')
          ..write('source: $source, ')
          ..write('purpose: $purpose')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, at, action, dataType, source, purpose);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuditEvent &&
          other.id == this.id &&
          other.at == this.at &&
          other.action == this.action &&
          other.dataType == this.dataType &&
          other.source == this.source &&
          other.purpose == this.purpose);
}

class AuditEventsCompanion extends UpdateCompanion<AuditEvent> {
  final Value<int> id;
  final Value<DateTime> at;
  final Value<String> action;
  final Value<String> dataType;
  final Value<String> source;
  final Value<String> purpose;
  const AuditEventsCompanion({
    this.id = const Value.absent(),
    this.at = const Value.absent(),
    this.action = const Value.absent(),
    this.dataType = const Value.absent(),
    this.source = const Value.absent(),
    this.purpose = const Value.absent(),
  });
  AuditEventsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime at,
    required String action,
    required String dataType,
    required String source,
    required String purpose,
  }) : at = Value(at),
       action = Value(action),
       dataType = Value(dataType),
       source = Value(source),
       purpose = Value(purpose);
  static Insertable<AuditEvent> custom({
    Expression<int>? id,
    Expression<DateTime>? at,
    Expression<String>? action,
    Expression<String>? dataType,
    Expression<String>? source,
    Expression<String>? purpose,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (at != null) 'at': at,
      if (action != null) 'action': action,
      if (dataType != null) 'data_type': dataType,
      if (source != null) 'source': source,
      if (purpose != null) 'purpose': purpose,
    });
  }

  AuditEventsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? at,
    Value<String>? action,
    Value<String>? dataType,
    Value<String>? source,
    Value<String>? purpose,
  }) {
    return AuditEventsCompanion(
      id: id ?? this.id,
      at: at ?? this.at,
      action: action ?? this.action,
      dataType: dataType ?? this.dataType,
      source: source ?? this.source,
      purpose: purpose ?? this.purpose,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (dataType.present) {
      map['data_type'] = Variable<String>(dataType.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (purpose.present) {
      map['purpose'] = Variable<String>(purpose.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AuditEventsCompanion(')
          ..write('id: $id, ')
          ..write('at: $at, ')
          ..write('action: $action, ')
          ..write('dataType: $dataType, ')
          ..write('source: $source, ')
          ..write('purpose: $purpose')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
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
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String value;
  const AppSetting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppSetting copyWith({String? key, String? value}) =>
      AppSetting(key: key ?? this.key, value: value ?? this.value);
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
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
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WeatherCacheRowsTable extends WeatherCacheRows
    with TableInfo<$WeatherCacheRowsTable, WeatherCacheRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeatherCacheRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tempCMeta = const VerificationMeta('tempC');
  @override
  late final GeneratedColumn<double> tempC = GeneratedColumn<double>(
    'temp_c',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _humidityPctMeta = const VerificationMeta(
    'humidityPct',
  );
  @override
  late final GeneratedColumn<double> humidityPct = GeneratedColumn<double>(
    'humidity_pct',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    fetchedAt,
    tempC,
    humidityPct,
    latitude,
    longitude,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weather_cache_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<WeatherCacheRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    if (data.containsKey('temp_c')) {
      context.handle(
        _tempCMeta,
        tempC.isAcceptableOrUnknown(data['temp_c']!, _tempCMeta),
      );
    } else if (isInserting) {
      context.missing(_tempCMeta);
    }
    if (data.containsKey('humidity_pct')) {
      context.handle(
        _humidityPctMeta,
        humidityPct.isAcceptableOrUnknown(
          data['humidity_pct']!,
          _humidityPctMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_humidityPctMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WeatherCacheRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeatherCacheRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
      tempC: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}temp_c'],
      )!,
      humidityPct: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}humidity_pct'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      )!,
    );
  }

  @override
  $WeatherCacheRowsTable createAlias(String alias) {
    return $WeatherCacheRowsTable(attachedDatabase, alias);
  }
}

class WeatherCacheRow extends DataClass implements Insertable<WeatherCacheRow> {
  final int id;
  final DateTime fetchedAt;
  final double tempC;
  final double humidityPct;
  final double latitude;
  final double longitude;
  const WeatherCacheRow({
    required this.id,
    required this.fetchedAt,
    required this.tempC,
    required this.humidityPct,
    required this.latitude,
    required this.longitude,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    map['temp_c'] = Variable<double>(tempC);
    map['humidity_pct'] = Variable<double>(humidityPct);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    return map;
  }

  WeatherCacheRowsCompanion toCompanion(bool nullToAbsent) {
    return WeatherCacheRowsCompanion(
      id: Value(id),
      fetchedAt: Value(fetchedAt),
      tempC: Value(tempC),
      humidityPct: Value(humidityPct),
      latitude: Value(latitude),
      longitude: Value(longitude),
    );
  }

  factory WeatherCacheRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeatherCacheRow(
      id: serializer.fromJson<int>(json['id']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
      tempC: serializer.fromJson<double>(json['tempC']),
      humidityPct: serializer.fromJson<double>(json['humidityPct']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
      'tempC': serializer.toJson<double>(tempC),
      'humidityPct': serializer.toJson<double>(humidityPct),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
    };
  }

  WeatherCacheRow copyWith({
    int? id,
    DateTime? fetchedAt,
    double? tempC,
    double? humidityPct,
    double? latitude,
    double? longitude,
  }) => WeatherCacheRow(
    id: id ?? this.id,
    fetchedAt: fetchedAt ?? this.fetchedAt,
    tempC: tempC ?? this.tempC,
    humidityPct: humidityPct ?? this.humidityPct,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
  );
  WeatherCacheRow copyWithCompanion(WeatherCacheRowsCompanion data) {
    return WeatherCacheRow(
      id: data.id.present ? data.id.value : this.id,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
      tempC: data.tempC.present ? data.tempC.value : this.tempC,
      humidityPct: data.humidityPct.present
          ? data.humidityPct.value
          : this.humidityPct,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeatherCacheRow(')
          ..write('id: $id, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('tempC: $tempC, ')
          ..write('humidityPct: $humidityPct, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, fetchedAt, tempC, humidityPct, latitude, longitude);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeatherCacheRow &&
          other.id == this.id &&
          other.fetchedAt == this.fetchedAt &&
          other.tempC == this.tempC &&
          other.humidityPct == this.humidityPct &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude);
}

class WeatherCacheRowsCompanion extends UpdateCompanion<WeatherCacheRow> {
  final Value<int> id;
  final Value<DateTime> fetchedAt;
  final Value<double> tempC;
  final Value<double> humidityPct;
  final Value<double> latitude;
  final Value<double> longitude;
  const WeatherCacheRowsCompanion({
    this.id = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.tempC = const Value.absent(),
    this.humidityPct = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
  });
  WeatherCacheRowsCompanion.insert({
    this.id = const Value.absent(),
    required DateTime fetchedAt,
    required double tempC,
    required double humidityPct,
    required double latitude,
    required double longitude,
  }) : fetchedAt = Value(fetchedAt),
       tempC = Value(tempC),
       humidityPct = Value(humidityPct),
       latitude = Value(latitude),
       longitude = Value(longitude);
  static Insertable<WeatherCacheRow> custom({
    Expression<int>? id,
    Expression<DateTime>? fetchedAt,
    Expression<double>? tempC,
    Expression<double>? humidityPct,
    Expression<double>? latitude,
    Expression<double>? longitude,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (tempC != null) 'temp_c': tempC,
      if (humidityPct != null) 'humidity_pct': humidityPct,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    });
  }

  WeatherCacheRowsCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? fetchedAt,
    Value<double>? tempC,
    Value<double>? humidityPct,
    Value<double>? latitude,
    Value<double>? longitude,
  }) {
    return WeatherCacheRowsCompanion(
      id: id ?? this.id,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      tempC: tempC ?? this.tempC,
      humidityPct: humidityPct ?? this.humidityPct,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (tempC.present) {
      map['temp_c'] = Variable<double>(tempC.value);
    }
    if (humidityPct.present) {
      map['humidity_pct'] = Variable<double>(humidityPct.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeatherCacheRowsCompanion(')
          ..write('id: $id, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('tempC: $tempC, ')
          ..write('humidityPct: $humidityPct, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $FoodEntriesTable foodEntries = $FoodEntriesTable(this);
  late final $BeverageEntriesTable beverageEntries = $BeverageEntriesTable(
    this,
  );
  late final $HydrationEntriesTable hydrationEntries = $HydrationEntriesTable(
    this,
  );
  late final $ExerciseEntriesTable exerciseEntries = $ExerciseEntriesTable(
    this,
  );
  late final $WalkSessionsTable walkSessions = $WalkSessionsTable(this);
  late final $AuditEventsTable auditEvents = $AuditEventsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $WeatherCacheRowsTable weatherCacheRows = $WeatherCacheRowsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    foodEntries,
    beverageEntries,
    hydrationEntries,
    exerciseEntries,
    walkSessions,
    auditEvents,
    appSettings,
    weatherCacheRows,
  ];
}

typedef $$FoodEntriesTableCreateCompanionBuilder =
    FoodEntriesCompanion Function({
      Value<int> id,
      required String name,
      Value<String> quantity,
      required FuelQuality qualityScore,
      Value<int?> caloriesKcal,
      Value<double?> proteinG,
      Value<double?> fiberG,
      Value<double?> carbsG,
      Value<double?> fatG,
      Value<String> source,
      required DateTime loggedAt,
    });
typedef $$FoodEntriesTableUpdateCompanionBuilder =
    FoodEntriesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> quantity,
      Value<FuelQuality> qualityScore,
      Value<int?> caloriesKcal,
      Value<double?> proteinG,
      Value<double?> fiberG,
      Value<double?> carbsG,
      Value<double?> fatG,
      Value<String> source,
      Value<DateTime> loggedAt,
    });

class $$FoodEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $FoodEntriesTable> {
  $$FoodEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<FuelQuality, FuelQuality, String>
  get qualityScore => $composableBuilder(
    column: $table.qualityScore,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get caloriesKcal => $composableBuilder(
    column: $table.caloriesKcal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get proteinG => $composableBuilder(
    column: $table.proteinG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fiberG => $composableBuilder(
    column: $table.fiberG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carbsG => $composableBuilder(
    column: $table.carbsG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fatG => $composableBuilder(
    column: $table.fatG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get loggedAt => $composableBuilder(
    column: $table.loggedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FoodEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $FoodEntriesTable> {
  $$FoodEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get qualityScore => $composableBuilder(
    column: $table.qualityScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get caloriesKcal => $composableBuilder(
    column: $table.caloriesKcal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get proteinG => $composableBuilder(
    column: $table.proteinG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fiberG => $composableBuilder(
    column: $table.fiberG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carbsG => $composableBuilder(
    column: $table.carbsG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fatG => $composableBuilder(
    column: $table.fatG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get loggedAt => $composableBuilder(
    column: $table.loggedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FoodEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FoodEntriesTable> {
  $$FoodEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumnWithTypeConverter<FuelQuality, String> get qualityScore =>
      $composableBuilder(
        column: $table.qualityScore,
        builder: (column) => column,
      );

  GeneratedColumn<int> get caloriesKcal => $composableBuilder(
    column: $table.caloriesKcal,
    builder: (column) => column,
  );

  GeneratedColumn<double> get proteinG =>
      $composableBuilder(column: $table.proteinG, builder: (column) => column);

  GeneratedColumn<double> get fiberG =>
      $composableBuilder(column: $table.fiberG, builder: (column) => column);

  GeneratedColumn<double> get carbsG =>
      $composableBuilder(column: $table.carbsG, builder: (column) => column);

  GeneratedColumn<double> get fatG =>
      $composableBuilder(column: $table.fatG, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get loggedAt =>
      $composableBuilder(column: $table.loggedAt, builder: (column) => column);
}

class $$FoodEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FoodEntriesTable,
          FoodEntry,
          $$FoodEntriesTableFilterComposer,
          $$FoodEntriesTableOrderingComposer,
          $$FoodEntriesTableAnnotationComposer,
          $$FoodEntriesTableCreateCompanionBuilder,
          $$FoodEntriesTableUpdateCompanionBuilder,
          (
            FoodEntry,
            BaseReferences<_$AppDatabase, $FoodEntriesTable, FoodEntry>,
          ),
          FoodEntry,
          PrefetchHooks Function()
        > {
  $$FoodEntriesTableTableManager(_$AppDatabase db, $FoodEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FoodEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FoodEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FoodEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> quantity = const Value.absent(),
                Value<FuelQuality> qualityScore = const Value.absent(),
                Value<int?> caloriesKcal = const Value.absent(),
                Value<double?> proteinG = const Value.absent(),
                Value<double?> fiberG = const Value.absent(),
                Value<double?> carbsG = const Value.absent(),
                Value<double?> fatG = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<DateTime> loggedAt = const Value.absent(),
              }) => FoodEntriesCompanion(
                id: id,
                name: name,
                quantity: quantity,
                qualityScore: qualityScore,
                caloriesKcal: caloriesKcal,
                proteinG: proteinG,
                fiberG: fiberG,
                carbsG: carbsG,
                fatG: fatG,
                source: source,
                loggedAt: loggedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String> quantity = const Value.absent(),
                required FuelQuality qualityScore,
                Value<int?> caloriesKcal = const Value.absent(),
                Value<double?> proteinG = const Value.absent(),
                Value<double?> fiberG = const Value.absent(),
                Value<double?> carbsG = const Value.absent(),
                Value<double?> fatG = const Value.absent(),
                Value<String> source = const Value.absent(),
                required DateTime loggedAt,
              }) => FoodEntriesCompanion.insert(
                id: id,
                name: name,
                quantity: quantity,
                qualityScore: qualityScore,
                caloriesKcal: caloriesKcal,
                proteinG: proteinG,
                fiberG: fiberG,
                carbsG: carbsG,
                fatG: fatG,
                source: source,
                loggedAt: loggedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FoodEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FoodEntriesTable,
      FoodEntry,
      $$FoodEntriesTableFilterComposer,
      $$FoodEntriesTableOrderingComposer,
      $$FoodEntriesTableAnnotationComposer,
      $$FoodEntriesTableCreateCompanionBuilder,
      $$FoodEntriesTableUpdateCompanionBuilder,
      (FoodEntry, BaseReferences<_$AppDatabase, $FoodEntriesTable, FoodEntry>),
      FoodEntry,
      PrefetchHooks Function()
    >;
typedef $$BeverageEntriesTableCreateCompanionBuilder =
    BeverageEntriesCompanion Function({
      Value<int> id,
      required String name,
      Value<int> volumeMl,
      Value<double> sugarContentG,
      required BeverageType type,
      required DateTime loggedAt,
    });
typedef $$BeverageEntriesTableUpdateCompanionBuilder =
    BeverageEntriesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int> volumeMl,
      Value<double> sugarContentG,
      Value<BeverageType> type,
      Value<DateTime> loggedAt,
    });

class $$BeverageEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $BeverageEntriesTable> {
  $$BeverageEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get volumeMl => $composableBuilder(
    column: $table.volumeMl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sugarContentG => $composableBuilder(
    column: $table.sugarContentG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<BeverageType, BeverageType, String> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get loggedAt => $composableBuilder(
    column: $table.loggedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BeverageEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $BeverageEntriesTable> {
  $$BeverageEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get volumeMl => $composableBuilder(
    column: $table.volumeMl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sugarContentG => $composableBuilder(
    column: $table.sugarContentG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get loggedAt => $composableBuilder(
    column: $table.loggedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BeverageEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BeverageEntriesTable> {
  $$BeverageEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get volumeMl =>
      $composableBuilder(column: $table.volumeMl, builder: (column) => column);

  GeneratedColumn<double> get sugarContentG => $composableBuilder(
    column: $table.sugarContentG,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<BeverageType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<DateTime> get loggedAt =>
      $composableBuilder(column: $table.loggedAt, builder: (column) => column);
}

class $$BeverageEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BeverageEntriesTable,
          BeverageEntry,
          $$BeverageEntriesTableFilterComposer,
          $$BeverageEntriesTableOrderingComposer,
          $$BeverageEntriesTableAnnotationComposer,
          $$BeverageEntriesTableCreateCompanionBuilder,
          $$BeverageEntriesTableUpdateCompanionBuilder,
          (
            BeverageEntry,
            BaseReferences<_$AppDatabase, $BeverageEntriesTable, BeverageEntry>,
          ),
          BeverageEntry,
          PrefetchHooks Function()
        > {
  $$BeverageEntriesTableTableManager(
    _$AppDatabase db,
    $BeverageEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BeverageEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BeverageEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BeverageEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> volumeMl = const Value.absent(),
                Value<double> sugarContentG = const Value.absent(),
                Value<BeverageType> type = const Value.absent(),
                Value<DateTime> loggedAt = const Value.absent(),
              }) => BeverageEntriesCompanion(
                id: id,
                name: name,
                volumeMl: volumeMl,
                sugarContentG: sugarContentG,
                type: type,
                loggedAt: loggedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<int> volumeMl = const Value.absent(),
                Value<double> sugarContentG = const Value.absent(),
                required BeverageType type,
                required DateTime loggedAt,
              }) => BeverageEntriesCompanion.insert(
                id: id,
                name: name,
                volumeMl: volumeMl,
                sugarContentG: sugarContentG,
                type: type,
                loggedAt: loggedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BeverageEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BeverageEntriesTable,
      BeverageEntry,
      $$BeverageEntriesTableFilterComposer,
      $$BeverageEntriesTableOrderingComposer,
      $$BeverageEntriesTableAnnotationComposer,
      $$BeverageEntriesTableCreateCompanionBuilder,
      $$BeverageEntriesTableUpdateCompanionBuilder,
      (
        BeverageEntry,
        BaseReferences<_$AppDatabase, $BeverageEntriesTable, BeverageEntry>,
      ),
      BeverageEntry,
      PrefetchHooks Function()
    >;
typedef $$HydrationEntriesTableCreateCompanionBuilder =
    HydrationEntriesCompanion Function({
      Value<int> id,
      required int amountMl,
      Value<String> source,
      required DateTime loggedAt,
    });
typedef $$HydrationEntriesTableUpdateCompanionBuilder =
    HydrationEntriesCompanion Function({
      Value<int> id,
      Value<int> amountMl,
      Value<String> source,
      Value<DateTime> loggedAt,
    });

class $$HydrationEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $HydrationEntriesTable> {
  $$HydrationEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountMl => $composableBuilder(
    column: $table.amountMl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get loggedAt => $composableBuilder(
    column: $table.loggedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HydrationEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $HydrationEntriesTable> {
  $$HydrationEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountMl => $composableBuilder(
    column: $table.amountMl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get loggedAt => $composableBuilder(
    column: $table.loggedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HydrationEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $HydrationEntriesTable> {
  $$HydrationEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get amountMl =>
      $composableBuilder(column: $table.amountMl, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get loggedAt =>
      $composableBuilder(column: $table.loggedAt, builder: (column) => column);
}

class $$HydrationEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HydrationEntriesTable,
          HydrationEntry,
          $$HydrationEntriesTableFilterComposer,
          $$HydrationEntriesTableOrderingComposer,
          $$HydrationEntriesTableAnnotationComposer,
          $$HydrationEntriesTableCreateCompanionBuilder,
          $$HydrationEntriesTableUpdateCompanionBuilder,
          (
            HydrationEntry,
            BaseReferences<
              _$AppDatabase,
              $HydrationEntriesTable,
              HydrationEntry
            >,
          ),
          HydrationEntry,
          PrefetchHooks Function()
        > {
  $$HydrationEntriesTableTableManager(
    _$AppDatabase db,
    $HydrationEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HydrationEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HydrationEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HydrationEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> amountMl = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<DateTime> loggedAt = const Value.absent(),
              }) => HydrationEntriesCompanion(
                id: id,
                amountMl: amountMl,
                source: source,
                loggedAt: loggedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int amountMl,
                Value<String> source = const Value.absent(),
                required DateTime loggedAt,
              }) => HydrationEntriesCompanion.insert(
                id: id,
                amountMl: amountMl,
                source: source,
                loggedAt: loggedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HydrationEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HydrationEntriesTable,
      HydrationEntry,
      $$HydrationEntriesTableFilterComposer,
      $$HydrationEntriesTableOrderingComposer,
      $$HydrationEntriesTableAnnotationComposer,
      $$HydrationEntriesTableCreateCompanionBuilder,
      $$HydrationEntriesTableUpdateCompanionBuilder,
      (
        HydrationEntry,
        BaseReferences<_$AppDatabase, $HydrationEntriesTable, HydrationEntry>,
      ),
      HydrationEntry,
      PrefetchHooks Function()
    >;
typedef $$ExerciseEntriesTableCreateCompanionBuilder =
    ExerciseEntriesCompanion Function({
      Value<int> id,
      required String activity,
      required int durationMinutes,
      required ExerciseIntensity intensity,
      required DateTime loggedAt,
    });
typedef $$ExerciseEntriesTableUpdateCompanionBuilder =
    ExerciseEntriesCompanion Function({
      Value<int> id,
      Value<String> activity,
      Value<int> durationMinutes,
      Value<ExerciseIntensity> intensity,
      Value<DateTime> loggedAt,
    });

class $$ExerciseEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $ExerciseEntriesTable> {
  $$ExerciseEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activity => $composableBuilder(
    column: $table.activity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ExerciseIntensity, ExerciseIntensity, String>
  get intensity => $composableBuilder(
    column: $table.intensity,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get loggedAt => $composableBuilder(
    column: $table.loggedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExerciseEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExerciseEntriesTable> {
  $$ExerciseEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activity => $composableBuilder(
    column: $table.activity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get intensity => $composableBuilder(
    column: $table.intensity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get loggedAt => $composableBuilder(
    column: $table.loggedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExerciseEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExerciseEntriesTable> {
  $$ExerciseEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get activity =>
      $composableBuilder(column: $table.activity, builder: (column) => column);

  GeneratedColumn<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<ExerciseIntensity, String> get intensity =>
      $composableBuilder(column: $table.intensity, builder: (column) => column);

  GeneratedColumn<DateTime> get loggedAt =>
      $composableBuilder(column: $table.loggedAt, builder: (column) => column);
}

class $$ExerciseEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExerciseEntriesTable,
          ExerciseEntry,
          $$ExerciseEntriesTableFilterComposer,
          $$ExerciseEntriesTableOrderingComposer,
          $$ExerciseEntriesTableAnnotationComposer,
          $$ExerciseEntriesTableCreateCompanionBuilder,
          $$ExerciseEntriesTableUpdateCompanionBuilder,
          (
            ExerciseEntry,
            BaseReferences<_$AppDatabase, $ExerciseEntriesTable, ExerciseEntry>,
          ),
          ExerciseEntry,
          PrefetchHooks Function()
        > {
  $$ExerciseEntriesTableTableManager(
    _$AppDatabase db,
    $ExerciseEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExerciseEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExerciseEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExerciseEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> activity = const Value.absent(),
                Value<int> durationMinutes = const Value.absent(),
                Value<ExerciseIntensity> intensity = const Value.absent(),
                Value<DateTime> loggedAt = const Value.absent(),
              }) => ExerciseEntriesCompanion(
                id: id,
                activity: activity,
                durationMinutes: durationMinutes,
                intensity: intensity,
                loggedAt: loggedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String activity,
                required int durationMinutes,
                required ExerciseIntensity intensity,
                required DateTime loggedAt,
              }) => ExerciseEntriesCompanion.insert(
                id: id,
                activity: activity,
                durationMinutes: durationMinutes,
                intensity: intensity,
                loggedAt: loggedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExerciseEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExerciseEntriesTable,
      ExerciseEntry,
      $$ExerciseEntriesTableFilterComposer,
      $$ExerciseEntriesTableOrderingComposer,
      $$ExerciseEntriesTableAnnotationComposer,
      $$ExerciseEntriesTableCreateCompanionBuilder,
      $$ExerciseEntriesTableUpdateCompanionBuilder,
      (
        ExerciseEntry,
        BaseReferences<_$AppDatabase, $ExerciseEntriesTable, ExerciseEntry>,
      ),
      ExerciseEntry,
      PrefetchHooks Function()
    >;
typedef $$WalkSessionsTableCreateCompanionBuilder =
    WalkSessionsCompanion Function({
      Value<int> id,
      required int targetMinutes,
      required DateTime startedAt,
      Value<DateTime?> completedAt,
      Value<String> source,
    });
typedef $$WalkSessionsTableUpdateCompanionBuilder =
    WalkSessionsCompanion Function({
      Value<int> id,
      Value<int> targetMinutes,
      Value<DateTime> startedAt,
      Value<DateTime?> completedAt,
      Value<String> source,
    });

class $$WalkSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $WalkSessionsTable> {
  $$WalkSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetMinutes => $composableBuilder(
    column: $table.targetMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WalkSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $WalkSessionsTable> {
  $$WalkSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetMinutes => $composableBuilder(
    column: $table.targetMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WalkSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WalkSessionsTable> {
  $$WalkSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get targetMinutes => $composableBuilder(
    column: $table.targetMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);
}

class $$WalkSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WalkSessionsTable,
          WalkSession,
          $$WalkSessionsTableFilterComposer,
          $$WalkSessionsTableOrderingComposer,
          $$WalkSessionsTableAnnotationComposer,
          $$WalkSessionsTableCreateCompanionBuilder,
          $$WalkSessionsTableUpdateCompanionBuilder,
          (
            WalkSession,
            BaseReferences<_$AppDatabase, $WalkSessionsTable, WalkSession>,
          ),
          WalkSession,
          PrefetchHooks Function()
        > {
  $$WalkSessionsTableTableManager(_$AppDatabase db, $WalkSessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WalkSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WalkSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WalkSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> targetMinutes = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String> source = const Value.absent(),
              }) => WalkSessionsCompanion(
                id: id,
                targetMinutes: targetMinutes,
                startedAt: startedAt,
                completedAt: completedAt,
                source: source,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int targetMinutes,
                required DateTime startedAt,
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String> source = const Value.absent(),
              }) => WalkSessionsCompanion.insert(
                id: id,
                targetMinutes: targetMinutes,
                startedAt: startedAt,
                completedAt: completedAt,
                source: source,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WalkSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WalkSessionsTable,
      WalkSession,
      $$WalkSessionsTableFilterComposer,
      $$WalkSessionsTableOrderingComposer,
      $$WalkSessionsTableAnnotationComposer,
      $$WalkSessionsTableCreateCompanionBuilder,
      $$WalkSessionsTableUpdateCompanionBuilder,
      (
        WalkSession,
        BaseReferences<_$AppDatabase, $WalkSessionsTable, WalkSession>,
      ),
      WalkSession,
      PrefetchHooks Function()
    >;
typedef $$AuditEventsTableCreateCompanionBuilder =
    AuditEventsCompanion Function({
      Value<int> id,
      required DateTime at,
      required String action,
      required String dataType,
      required String source,
      required String purpose,
    });
typedef $$AuditEventsTableUpdateCompanionBuilder =
    AuditEventsCompanion Function({
      Value<int> id,
      Value<DateTime> at,
      Value<String> action,
      Value<String> dataType,
      Value<String> source,
      Value<String> purpose,
    });

class $$AuditEventsTableFilterComposer
    extends Composer<_$AppDatabase, $AuditEventsTable> {
  $$AuditEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dataType => $composableBuilder(
    column: $table.dataType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get purpose => $composableBuilder(
    column: $table.purpose,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AuditEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $AuditEventsTable> {
  $$AuditEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dataType => $composableBuilder(
    column: $table.dataType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get purpose => $composableBuilder(
    column: $table.purpose,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AuditEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AuditEventsTable> {
  $$AuditEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get dataType =>
      $composableBuilder(column: $table.dataType, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get purpose =>
      $composableBuilder(column: $table.purpose, builder: (column) => column);
}

class $$AuditEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AuditEventsTable,
          AuditEvent,
          $$AuditEventsTableFilterComposer,
          $$AuditEventsTableOrderingComposer,
          $$AuditEventsTableAnnotationComposer,
          $$AuditEventsTableCreateCompanionBuilder,
          $$AuditEventsTableUpdateCompanionBuilder,
          (
            AuditEvent,
            BaseReferences<_$AppDatabase, $AuditEventsTable, AuditEvent>,
          ),
          AuditEvent,
          PrefetchHooks Function()
        > {
  $$AuditEventsTableTableManager(_$AppDatabase db, $AuditEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AuditEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AuditEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AuditEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<String> dataType = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> purpose = const Value.absent(),
              }) => AuditEventsCompanion(
                id: id,
                at: at,
                action: action,
                dataType: dataType,
                source: source,
                purpose: purpose,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime at,
                required String action,
                required String dataType,
                required String source,
                required String purpose,
              }) => AuditEventsCompanion.insert(
                id: id,
                at: at,
                action: action,
                dataType: dataType,
                source: source,
                purpose: purpose,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AuditEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AuditEventsTable,
      AuditEvent,
      $$AuditEventsTableFilterComposer,
      $$AuditEventsTableOrderingComposer,
      $$AuditEventsTableAnnotationComposer,
      $$AuditEventsTableCreateCompanionBuilder,
      $$AuditEventsTableUpdateCompanionBuilder,
      (
        AuditEvent,
        BaseReferences<_$AppDatabase, $AuditEventsTable, AuditEvent>,
      ),
      AuditEvent,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;
typedef $$WeatherCacheRowsTableCreateCompanionBuilder =
    WeatherCacheRowsCompanion Function({
      Value<int> id,
      required DateTime fetchedAt,
      required double tempC,
      required double humidityPct,
      required double latitude,
      required double longitude,
    });
typedef $$WeatherCacheRowsTableUpdateCompanionBuilder =
    WeatherCacheRowsCompanion Function({
      Value<int> id,
      Value<DateTime> fetchedAt,
      Value<double> tempC,
      Value<double> humidityPct,
      Value<double> latitude,
      Value<double> longitude,
    });

class $$WeatherCacheRowsTableFilterComposer
    extends Composer<_$AppDatabase, $WeatherCacheRowsTable> {
  $$WeatherCacheRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get tempC => $composableBuilder(
    column: $table.tempC,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get humidityPct => $composableBuilder(
    column: $table.humidityPct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WeatherCacheRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $WeatherCacheRowsTable> {
  $$WeatherCacheRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get tempC => $composableBuilder(
    column: $table.tempC,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get humidityPct => $composableBuilder(
    column: $table.humidityPct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WeatherCacheRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WeatherCacheRowsTable> {
  $$WeatherCacheRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);

  GeneratedColumn<double> get tempC =>
      $composableBuilder(column: $table.tempC, builder: (column) => column);

  GeneratedColumn<double> get humidityPct => $composableBuilder(
    column: $table.humidityPct,
    builder: (column) => column,
  );

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);
}

class $$WeatherCacheRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WeatherCacheRowsTable,
          WeatherCacheRow,
          $$WeatherCacheRowsTableFilterComposer,
          $$WeatherCacheRowsTableOrderingComposer,
          $$WeatherCacheRowsTableAnnotationComposer,
          $$WeatherCacheRowsTableCreateCompanionBuilder,
          $$WeatherCacheRowsTableUpdateCompanionBuilder,
          (
            WeatherCacheRow,
            BaseReferences<
              _$AppDatabase,
              $WeatherCacheRowsTable,
              WeatherCacheRow
            >,
          ),
          WeatherCacheRow,
          PrefetchHooks Function()
        > {
  $$WeatherCacheRowsTableTableManager(
    _$AppDatabase db,
    $WeatherCacheRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeatherCacheRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeatherCacheRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeatherCacheRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<double> tempC = const Value.absent(),
                Value<double> humidityPct = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
              }) => WeatherCacheRowsCompanion(
                id: id,
                fetchedAt: fetchedAt,
                tempC: tempC,
                humidityPct: humidityPct,
                latitude: latitude,
                longitude: longitude,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime fetchedAt,
                required double tempC,
                required double humidityPct,
                required double latitude,
                required double longitude,
              }) => WeatherCacheRowsCompanion.insert(
                id: id,
                fetchedAt: fetchedAt,
                tempC: tempC,
                humidityPct: humidityPct,
                latitude: latitude,
                longitude: longitude,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WeatherCacheRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WeatherCacheRowsTable,
      WeatherCacheRow,
      $$WeatherCacheRowsTableFilterComposer,
      $$WeatherCacheRowsTableOrderingComposer,
      $$WeatherCacheRowsTableAnnotationComposer,
      $$WeatherCacheRowsTableCreateCompanionBuilder,
      $$WeatherCacheRowsTableUpdateCompanionBuilder,
      (
        WeatherCacheRow,
        BaseReferences<_$AppDatabase, $WeatherCacheRowsTable, WeatherCacheRow>,
      ),
      WeatherCacheRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$FoodEntriesTableTableManager get foodEntries =>
      $$FoodEntriesTableTableManager(_db, _db.foodEntries);
  $$BeverageEntriesTableTableManager get beverageEntries =>
      $$BeverageEntriesTableTableManager(_db, _db.beverageEntries);
  $$HydrationEntriesTableTableManager get hydrationEntries =>
      $$HydrationEntriesTableTableManager(_db, _db.hydrationEntries);
  $$ExerciseEntriesTableTableManager get exerciseEntries =>
      $$ExerciseEntriesTableTableManager(_db, _db.exerciseEntries);
  $$WalkSessionsTableTableManager get walkSessions =>
      $$WalkSessionsTableTableManager(_db, _db.walkSessions);
  $$AuditEventsTableTableManager get auditEvents =>
      $$AuditEventsTableTableManager(_db, _db.auditEvents);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$WeatherCacheRowsTableTableManager get weatherCacheRows =>
      $$WeatherCacheRowsTableTableManager(_db, _db.weatherCacheRows);
}
