import 'package:drift/drift.dart';

import '../../domain/nutrition.dart';
import 'connection/connection.dart' as impl;

export '../../domain/nutrition.dart' show MacroTotals, DayMacros;

part 'app_database.g.dart';

enum FuelQuality { clean, moderate, dense }

enum BeverageType { water, caffeine, alcohol, protein }

enum ExerciseIntensity { low, moderate, vigorous }

class FoodEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get quantity => text().withDefault(const Constant(''))();
  TextColumn get qualityScore => textEnum<FuelQuality>()();
  // Nutrition estimate (nullable — voice/manual entries may lack it; photo
  // and detailed logs fill it in). Schema v2.
  IntColumn get caloriesKcal => integer().nullable()();
  RealColumn get proteinG => real().nullable()();
  RealColumn get fiberG => real().nullable()();
  RealColumn get carbsG => real().nullable()();
  RealColumn get fatG => real().nullable()();
  TextColumn get source => text().withDefault(const Constant('manual'))();
  DateTimeColumn get loggedAt => dateTime()();
}

class BeverageEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  IntColumn get volumeMl => integer().withDefault(const Constant(0))();
  RealColumn get sugarContentG => real().withDefault(const Constant(0))();
  TextColumn get type => textEnum<BeverageType>()();
  // Estimated calories so caloric drinks (juice, latte, soda) count toward
  // the day's intake. Null until estimated; a plain tea/coffee resolves ~0.
  IntColumn get caloriesKcal => integer().nullable()();
  DateTimeColumn get loggedAt => dateTime()();
}

class HydrationEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get amountMl => integer()();
  TextColumn get source => text().withDefault(const Constant('manual'))();
  DateTimeColumn get loggedAt => dateTime()();
}

class ExerciseEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get activity => text().withLength(min: 1, max: 200)();
  IntColumn get durationMinutes => integer()();
  TextColumn get intensity => textEnum<ExerciseIntensity>()();
  DateTimeColumn get loggedAt => dateTime()();
}

class WalkSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get targetMinutes => integer()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get source => text().withDefault(const Constant('manual'))();
}

/// Append-only: the app never exposes update/delete for audit rows (§4).
class AuditEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get at => dateTime()();
  TextColumn get action => text()(); // read | write | delete
  TextColumn get dataType => text()();
  TextColumn get source => text()();
  TextColumn get purpose => text()();
}

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

class WeatherCacheRows extends Table {
  IntColumn get id => integer()(); // always 0 — single-row cache
  DateTimeColumn get fetchedAt => dateTime()();
  RealColumn get tempC => real()();
  RealColumn get humidityPct => real()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    FoodEntries,
    BeverageEntries,
    HydrationEntries,
    ExerciseEntries,
    WalkSessions,
    AuditEvents,
    AppSettings,
    WeatherCacheRows,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(impl.openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // v2: nutrition macros on food entries (all additive & nullable).
          if (from < 2) {
            await m.addColumn(foodEntries, foodEntries.caloriesKcal);
            await m.addColumn(foodEntries, foodEntries.proteinG);
            await m.addColumn(foodEntries, foodEntries.fiberG);
            await m.addColumn(foodEntries, foodEntries.carbsG);
            await m.addColumn(foodEntries, foodEntries.fatG);
            await m.addColumn(foodEntries, foodEntries.source);
          }
          // v3: calories on beverages so drinks join the day's intake.
          if (from < 3) {
            await m.addColumn(beverageEntries, beverageEntries.caloriesKcal);
          }
        },
      );

  static DateTime startOfToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Future<void> logAudit({
    required String action,
    required String dataType,
    required String source,
    required String purpose,
  }) {
    return into(auditEvents).insert(
      AuditEventsCompanion.insert(
        at: DateTime.now(),
        action: action,
        dataType: dataType,
        source: source,
        purpose: purpose,
      ),
    );
  }

  Stream<List<AuditEvent>> watchAudit({int limit = 200}) {
    return (select(auditEvents)
          ..orderBy([
            (t) => OrderingTerm.desc(t.at),
            (t) => OrderingTerm.desc(t.id),
          ])
          ..limit(limit))
        .watch();
  }

  // ---- Today streams -------------------------------------------------

  Stream<List<FoodEntry>> watchTodayFoods() => (select(foodEntries)
        ..where((t) => t.loggedAt.isBiggerOrEqualValue(startOfToday()))
        ..orderBy([(t) => OrderingTerm.desc(t.loggedAt)]))
      .watch();

  Stream<List<BeverageEntry>> watchTodayBeverages() => (select(beverageEntries)
        ..where((t) => t.loggedAt.isBiggerOrEqualValue(startOfToday()))
        ..orderBy([(t) => OrderingTerm.desc(t.loggedAt)]))
      .watch();

  Stream<List<HydrationEntry>> watchTodayHydration() =>
      (select(hydrationEntries)
            ..where((t) => t.loggedAt.isBiggerOrEqualValue(startOfToday()))
            ..orderBy([(t) => OrderingTerm.desc(t.loggedAt)]))
          .watch();

  Stream<List<ExerciseEntry>> watchTodayExercise() => (select(exerciseEntries)
        ..where((t) => t.loggedAt.isBiggerOrEqualValue(startOfToday()))
        ..orderBy([(t) => OrderingTerm.desc(t.loggedAt)]))
      .watch();

  Stream<int> watchTodayHydrationMl() {
    final sum = hydrationEntries.amountMl.sum();
    final q = selectOnly(hydrationEntries)
      ..addColumns([sum])
      ..where(hydrationEntries.loggedAt.isBiggerOrEqualValue(startOfToday()));
    return q.watchSingle().map((row) => row.read(sum) ?? 0);
  }

  Stream<int> watchTodayExerciseMinutes() {
    final sum = exerciseEntries.durationMinutes.sum();
    final q = selectOnly(exerciseEntries)
      ..addColumns([sum])
      ..where(exerciseEntries.loggedAt.isBiggerOrEqualValue(startOfToday()));
    return q.watchSingle().map((row) => row.read(sum) ?? 0);
  }

  /// Sum of today's food macros, since a given day-start.
  Stream<MacroTotals> watchMacroTotals({DateTime? since}) {
    final start = since ?? startOfToday();
    final cal = foodEntries.caloriesKcal.sum();
    final protein = foodEntries.proteinG.sum();
    final fiber = foodEntries.fiberG.sum();
    final carbs = foodEntries.carbsG.sum();
    final fat = foodEntries.fatG.sum();
    final q = selectOnly(foodEntries)
      ..addColumns([cal, protein, fiber, carbs, fat])
      ..where(foodEntries.loggedAt.isBiggerOrEqualValue(start));
    return q.watchSingle().map((row) => MacroTotals(
          calories: (row.read(cal) ?? 0).round(),
          proteinG: row.read(protein) ?? 0,
          fiberG: row.read(fiber) ?? 0,
          carbsG: row.read(carbs) ?? 0,
          fatG: row.read(fat) ?? 0,
        ));
  }

  /// Today's caloric + sugar contribution from beverages, so drinks join the
  /// day's intake alongside food.
  Stream<({int calories, double sugarG})> watchTodayBeverageContribution() {
    final start = startOfToday();
    final cal = beverageEntries.caloriesKcal.sum();
    final sugar = beverageEntries.sugarContentG.sum();
    final q = selectOnly(beverageEntries)
      ..addColumns([cal, sugar])
      ..where(beverageEntries.loggedAt.isBiggerOrEqualValue(start));
    return q.watchSingle().map((row) => (
          calories: (row.read(cal) ?? 0).round(),
          sugarG: row.read(sugar) ?? 0.0,
        ));
  }

  /// Per-day macro totals across a window, oldest first (for trends).
  Future<List<DayMacros>> macrosByDay(int days) async {
    final since = startOfToday().subtract(Duration(days: days - 1));
    final rows = await (select(foodEntries)
          ..where((t) => t.loggedAt.isBiggerOrEqualValue(since)))
        .get();
    final byDay = <DateTime, MacroTotals>{};
    for (final f in rows) {
      final d = DateTime(f.loggedAt.year, f.loggedAt.month, f.loggedAt.day);
      final prev = byDay[d] ?? const MacroTotals.zero();
      byDay[d] = prev.plus(MacroTotals(
        calories: f.caloriesKcal ?? 0,
        proteinG: f.proteinG ?? 0,
        fiberG: f.fiberG ?? 0,
        carbsG: f.carbsG ?? 0,
        fatG: f.fatG ?? 0,
      ));
    }
    return [
      for (var i = 0; i < days; i++)
        () {
          final d = since.add(Duration(days: i));
          return DayMacros(d, byDay[d] ?? const MacroTotals.zero());
        }(),
    ];
  }

  Future<void> markWalkComplete(int id) async {
    await (update(walkSessions)..where((t) => t.id.equals(id)))
        .write(WalkSessionsCompanion(completedAt: Value(DateTime.now())));
    await logAudit(
      action: 'write',
      dataType: 'walk',
      source: 'walk_timer',
      purpose: 'completed',
    );
  }

  /// Completed walk minutes today — folded into active minutes for the
  /// hydration target and PulsIQ Score.
  Future<int> completedWalkMinutesToday() async {
    final rows = await (select(walkSessions)
          ..where((t) => t.completedAt.isNotNull() &
              t.startedAt.isBiggerOrEqualValue(startOfToday())))
        .get();
    return rows.fold<int>(0, (sum, w) => sum + w.targetMinutes);
  }

  /// (caffeineMl, alcoholMl) logged today — offsets the hydration target 1:1.
  Stream<(int, int)> watchTodayDiureticMl() {
    final sum = beverageEntries.volumeMl.sum();
    final q = selectOnly(beverageEntries)
      ..addColumns([beverageEntries.type, sum])
      ..where(beverageEntries.loggedAt.isBiggerOrEqualValue(startOfToday()))
      ..groupBy([beverageEntries.type]);
    return q.watch().map((rows) {
      var caffeine = 0, alcohol = 0;
      for (final row in rows) {
        final type = row.read(beverageEntries.type);
        final total = row.read(sum) ?? 0;
        if (type == BeverageType.caffeine.name) caffeine = total;
        if (type == BeverageType.alcohol.name) alcohol = total;
      }
      return (caffeine, alcohol);
    });
  }

  // ---- Settings & weather cache --------------------------------------

  Future<String?> getSetting(String key) async {
    final row = await (select(appSettings)..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> setSetting(String key, String value) =>
      into(appSettings).insertOnConflictUpdate(
          AppSettingsCompanion.insert(key: key, value: value));

  Future<WeatherCacheRow?> getWeatherCache() =>
      (select(weatherCacheRows)..where((t) => t.id.equals(0)))
          .getSingleOrNull();

  Future<void> upsertWeatherCache({
    required DateTime fetchedAt,
    required double tempC,
    required double humidityPct,
    required double latitude,
    required double longitude,
  }) {
    return into(weatherCacheRows).insertOnConflictUpdate(
      WeatherCacheRowsCompanion.insert(
        id: const Value(0),
        fetchedAt: fetchedAt,
        tempC: tempC,
        humidityPct: humidityPct,
        latitude: latitude,
        longitude: longitude,
      ),
    );
  }
}
