import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsiq/data/data_manager.dart';
import 'package:pulsiq/data/db/app_database.dart';
import 'package:pulsiq/data/log_repository.dart';
import 'package:pulsiq/security/secret_store.dart';

void main() {
  late AppDatabase db;
  late LogRepository repo;
  late DataManager manager;
  late InMemorySecretStore secrets;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LogRepository(db);
    secrets = InMemorySecretStore();
    manager = DataManager(db, secretStore: secrets);
  });

  tearDown(() => db.close());

  test('export produces valid JSON containing every logged entry', () async {
    await repo.addFood(
        name: 'Oats', quantity: '1 bowl', quality: FuelQuality.clean);
    await repo.addBeverage(
        name: 'Latte',
        volumeMl: 240,
        sugarContentG: 9,
        type: BeverageType.caffeine);
    await repo.quickAddWater(8);

    final json = jsonDecode(await manager.exportJson()) as Map<String, dynamic>;
    expect(json['app'], 'PulsIQ');
    expect((json['foods'] as List).single['name'], 'Oats');
    expect((json['beverages'] as List).single['type'], 'caffeine');
    expect((json['hydration'] as List), isNotEmpty);
    // The export itself is an audited read.
    expect(
      (json['audit'] as List).any((e) => e['source'] == 'data_export'),
      isTrue,
    );
  });

  test('deleteEverything clears all tables and wipes keys', () async {
    await repo.addFood(
        name: 'Pasta', quantity: '', quality: FuelQuality.dense);
    await db.setSetting('onboarded', 'true');
    // Seed a key so we can prove it is wiped.
    await secrets.write('pulsiq.db_key.v1', 'deadbeef');

    await manager.deleteEverything();

    expect(await db.watchTodayFoods().first, isEmpty);
    expect(await db.getSetting('onboarded'), isNull);
    expect(await db.watchAudit().first, isEmpty);
    expect(await secrets.read('pulsiq.db_key.v1'), isNull);
  });
}
