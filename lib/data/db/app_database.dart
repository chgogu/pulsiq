import 'package:drift/drift.dart';

import 'connection/connection.dart' as impl;

part 'app_database.g.dart';

enum FuelQuality { clean, moderate, dense }

enum BeverageType { water, caffeine, alcohol, protein }

enum ExerciseIntensity { low, moderate, vigorous }

class FoodEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get quantity => text().withDefault(const Constant(''))();
  TextColumn get qualityScore => textEnum<FuelQuality>()();
  DateTimeColumn get loggedAt => dateTime()();
}

class BeverageEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  IntColumn get volumeMl => integer().withDefault(const Constant(0))();
  RealColumn get sugarContentG => real().withDefault(const Constant(0))();
  TextColumn get type => textEnum<BeverageType>()();
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
  int get schemaVersion => 1;

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
