import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsiq/billing/subscription_service.dart';
import 'package:pulsiq/data/ai_settings.dart';
import 'package:pulsiq/data/db/app_database.dart';
import 'package:pulsiq/data/providers.dart';

void main() {
  late AppDatabase db;
  late SubscriptionService service;

  ProviderContainer container() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    service = SubscriptionService(db);
    final c = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      subscriptionServiceProvider.overrideWithValue(service),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  test('a fresh install is free — cloud AI is off', () {
    final c = container();
    expect(c.read(isPlusProvider), isFalse);
    expect(c.read(aiAssistEnabledProvider), isFalse);
  });

  test('cloud AI turns on with the Plus entitlement, and off again', () {
    final c = container();
    // The same path a completed StoreKit purchase takes: the service's
    // entitlement flips, and the gate follows.
    service.debugSetEntitled(true);
    expect(c.read(isPlusProvider), isTrue);
    expect(c.read(aiAssistEnabledProvider), isTrue);

    service.debugSetEntitled(false);
    expect(c.read(isPlusProvider), isFalse);
    expect(c.read(aiAssistEnabledProvider), isFalse);
  });
}
