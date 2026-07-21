import 'package:drift/drift.dart';

import 'db/app_database.dart';

enum LogKind { food, beverage, hydration, exercise }

/// One feed row, regardless of which table it came from.
class LogItem {
  const LogItem({
    required this.kind,
    required this.id,
    required this.title,
    required this.detail,
    required this.loggedAt,
    required this.entity,
  });

  final LogKind kind;
  final int id;
  final String title;
  final String detail;
  final DateTime loggedAt;
  final Object entity;
}

const ozToMl = 29.5735;

int ouncesToMl(int oz) => (oz * ozToMl).round();

/// Every write goes through here so the audit trail (§4) stays complete.
class LogRepository {
  LogRepository(this._db);

  final AppDatabase _db;

  Future<void> _audit(String action, String dataType, String source) =>
      _db.logAudit(
        action: action,
        dataType: dataType,
        source: source,
        purpose: 'user_log',
      );

  Future<int> quickAddWater(int oz) async {
    final id = await _db.into(_db.hydrationEntries).insert(
          HydrationEntriesCompanion.insert(
            amountMl: ouncesToMl(oz),
            source: const Value('quick_add'),
            loggedAt: DateTime.now(),
          ),
        );
    await _audit('write', 'hydration', 'fab_quick_add');
    return id;
  }

  /// Long-pressing the quick-add toast upgrades the same entry to 16 oz.
  Future<void> upgradeWater(int id, int oz) async {
    await (_db.update(_db.hydrationEntries)..where((t) => t.id.equals(id)))
        .write(HydrationEntriesCompanion(amountMl: Value(ouncesToMl(oz))));
    await _audit('write', 'hydration', 'fab_quick_add');
  }

  Future<void> addFood({
    required String name,
    required String quantity,
    required FuelQuality quality,
    DateTime? at,
  }) async {
    await _db.into(_db.foodEntries).insert(FoodEntriesCompanion.insert(
          name: name,
          quantity: Value(quantity),
          qualityScore: quality,
          loggedAt: at ?? DateTime.now(),
        ));
    await _audit('write', 'food', 'manual_entry');
  }

  /// Water-type beverages also count toward hydration.
  Future<void> addBeverage({
    required String name,
    required int volumeMl,
    required double sugarContentG,
    required BeverageType type,
    DateTime? at,
  }) async {
    final when = at ?? DateTime.now();
    await _db.into(_db.beverageEntries).insert(BeverageEntriesCompanion.insert(
          name: name,
          volumeMl: Value(volumeMl),
          sugarContentG: Value(sugarContentG),
          type: type,
          loggedAt: when,
        ));
    if (type == BeverageType.water && volumeMl > 0) {
      await _db.into(_db.hydrationEntries).insert(
            HydrationEntriesCompanion.insert(
              amountMl: volumeMl,
              source: const Value('beverage'),
              loggedAt: when,
            ),
          );
    }
    await _audit('write', 'beverage', 'manual_entry');
  }

  Future<void> addHydration({required int amountMl, DateTime? at}) async {
    await _db.into(_db.hydrationEntries).insert(
          HydrationEntriesCompanion.insert(
            amountMl: amountMl,
            loggedAt: at ?? DateTime.now(),
          ),
        );
    await _audit('write', 'hydration', 'manual_entry');
  }

  Future<void> addExercise({
    required String activity,
    required int durationMinutes,
    required ExerciseIntensity intensity,
    DateTime? at,
  }) async {
    await _db.into(_db.exerciseEntries).insert(
          ExerciseEntriesCompanion.insert(
            activity: activity,
            durationMinutes: durationMinutes,
            intensity: intensity,
            loggedAt: at ?? DateTime.now(),
          ),
        );
    await _audit('write', 'exercise', 'manual_entry');
  }

  Future<void> updateFood(FoodEntry entry) async {
    await _db.update(_db.foodEntries).replace(entry);
    await _audit('write', 'food', 'manual_edit');
  }

  Future<void> updateBeverage(BeverageEntry entry) async {
    await _db.update(_db.beverageEntries).replace(entry);
    await _audit('write', 'beverage', 'manual_edit');
  }

  Future<void> updateHydration(HydrationEntry entry) async {
    await _db.update(_db.hydrationEntries).replace(entry);
    await _audit('write', 'hydration', 'manual_edit');
  }

  Future<void> updateExercise(ExerciseEntry entry) async {
    await _db.update(_db.exerciseEntries).replace(entry);
    await _audit('write', 'exercise', 'manual_edit');
  }

  Future<void> deleteItem(LogItem item) async {
    switch (item.kind) {
      case LogKind.food:
        await (_db.delete(_db.foodEntries)
              ..where((t) => t.id.equals(item.id)))
            .go();
      case LogKind.beverage:
        await (_db.delete(_db.beverageEntries)
              ..where((t) => t.id.equals(item.id)))
            .go();
      case LogKind.hydration:
        await (_db.delete(_db.hydrationEntries)
              ..where((t) => t.id.equals(item.id)))
            .go();
      case LogKind.exercise:
        await (_db.delete(_db.exerciseEntries)
              ..where((t) => t.id.equals(item.id)))
            .go();
    }
    await _audit('delete', item.kind.name, 'log_feed');
  }
}

// ---- Feed mapping -----------------------------------------------------

LogItem foodToItem(FoodEntry e) => LogItem(
      kind: LogKind.food,
      id: e.id,
      title: e.name,
      detail: [
        if (e.quantity.isNotEmpty) e.quantity,
        '${e.qualityScore.name} fuel',
      ].join(' · '),
      loggedAt: e.loggedAt,
      entity: e,
    );

LogItem beverageToItem(BeverageEntry e) => LogItem(
      kind: LogKind.beverage,
      id: e.id,
      title: e.name,
      detail: [
        e.type.name,
        if (e.volumeMl > 0) '${e.volumeMl} ml',
        if (e.sugarContentG > 0) '${e.sugarContentG.toStringAsFixed(0)} g sugar',
      ].join(' · '),
      loggedAt: e.loggedAt,
      entity: e,
    );

LogItem hydrationToItem(HydrationEntry e) => LogItem(
      kind: LogKind.hydration,
      id: e.id,
      title: 'Water',
      detail: '+${e.amountMl} ml',
      loggedAt: e.loggedAt,
      entity: e,
    );

LogItem exerciseToItem(ExerciseEntry e) => LogItem(
      kind: LogKind.exercise,
      id: e.id,
      title: e.activity,
      detail: '${e.durationMinutes} min · ${e.intensity.name}',
      loggedAt: e.loggedAt,
      entity: e,
    );
