import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsiq/data/db/app_database.dart';
import 'package:pulsiq/data/log_repository.dart';

void main() {
  late AppDatabase db;
  late LogRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LogRepository(db);
  });

  tearDown(() => db.close());

  test('oz→ml conversion is exact enough', () {
    expect(ouncesToMl(8), 237);
    expect(ouncesToMl(16), 473);
  });

  test('quick-add water sums into today total and upgrades in place',
      () async {
    final id = await repo.quickAddWater(8);
    expect(await db.watchTodayHydrationMl().first, 237);

    await repo.upgradeWater(id, 16);
    expect(await db.watchTodayHydrationMl().first, 473);

    // Still one entry — the upgrade replaced, not appended.
    expect((await db.watchTodayHydration().first).length, 1);
  });

  test('every write appends to the audit trail', () async {
    await repo.addFood(
        name: 'Oats', quantity: '1 bowl', quality: FuelQuality.clean);
    await repo.quickAddWater(8);
    final audit = await db.watchAudit().first;
    expect(audit.length, 2);
    expect(audit.every((e) => e.action == 'write'), isTrue);
    expect(audit.map((e) => e.dataType).toSet(), {'food', 'hydration'});
  });

  test('water beverages mirror into hydration; diuretics sum by type',
      () async {
    await repo.addBeverage(
        name: 'Water bottle',
        volumeMl: 500,
        sugarContentG: 0,
        type: BeverageType.water);
    await repo.addBeverage(
        name: 'Latte',
        volumeMl: 350,
        sugarContentG: 9,
        type: BeverageType.caffeine);
    await repo.addBeverage(
        name: 'Beer',
        volumeMl: 330,
        sugarContentG: 3,
        type: BeverageType.alcohol);

    expect(await db.watchTodayHydrationMl().first, 500);
    expect(await db.watchTodayDiureticMl().first, (350, 330));
  });

  test('beverage calories + sugar join today intake', () async {
    // Green tea: no calories → contributes nothing but is still tracked.
    final tea = await repo.addBeverage(
        name: 'Green tea',
        volumeMl: 200,
        sugarContentG: 0,
        type: BeverageType.caffeine);
    // A caloric drink patched after an estimate.
    final juice = await repo.addBeverage(
        name: 'Orange juice',
        volumeMl: 250,
        sugarContentG: 24,
        type: BeverageType.caffeine);
    await repo.patchBeverageCalories(juice, 110);
    await repo.patchBeverageCalories(tea, 2);

    final contrib = await db.watchTodayBeverageContribution().first;
    expect(contrib.calories, 112); // 2 + 110
    expect(contrib.sugarG, 24);
  });

  test('deleteItem removes the row and audits the deletion', () async {
    await repo.addExercise(
        activity: 'Run',
        durationMinutes: 20,
        intensity: ExerciseIntensity.vigorous);
    final entry = (await db.watchTodayExercise().first).single;
    await repo.deleteItem(exerciseToItem(entry));

    expect(await db.watchTodayExercise().first, isEmpty);
    final audit = await db.watchAudit().first;
    expect(audit.first.action, 'delete');
  });

  test('edits persist through update methods', () async {
    await repo.addFood(
        name: 'Pasta', quantity: '', quality: FuelQuality.dense);
    final entry = (await db.watchTodayFoods().first).single;
    await repo.updateFood(
        entry.copyWith(name: 'Pasta + salad', qualityScore: FuelQuality.moderate));
    final updated = (await db.watchTodayFoods().first).single;
    expect(updated.name, 'Pasta + salad');
    expect(updated.qualityScore, FuelQuality.moderate);
  });

  test('settings and weather cache round-trip', () async {
    await db.setSetting('onboarded', 'true');
    expect(await db.getSetting('onboarded'), 'true');
    await db.setSetting('onboarded', 'false');
    expect(await db.getSetting('onboarded'), 'false');

    final now = DateTime(2026, 7, 21, 9);
    await db.upsertWeatherCache(
        fetchedAt: now,
        tempC: 28.5,
        humidityPct: 60,
        latitude: 37.7,
        longitude: -122.4);
    final cached = await db.getWeatherCache();
    expect(cached!.tempC, 28.5);
    expect(cached.fetchedAt, now);
  });
}
