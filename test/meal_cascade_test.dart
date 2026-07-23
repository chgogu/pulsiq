import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsiq/data/db/app_database.dart';
import 'package:pulsiq/data/log_repository.dart';
import 'package:pulsiq/data/meal_estimator.dart';
import 'package:pulsiq/domain/food_db.dart';
import 'package:pulsiq/llm/llm_client.dart';

/// Backend that fails the test if the LLM is ever reached — proves the local
/// tiers served the request at $0.
class _NeverCalledBackend implements LlmBackend {
  @override
  String get name => 'never';
  @override
  Future<String> analyzeMealImage(
          {required String base64Image, String hint = ''}) async =>
      throw StateError('LLM must not be called for a locally-known food');
  @override
  Future<String> complete(String userText) async => throw StateError('no');
  @override
  Future<String> analyzeMenu(String menuText) async => throw StateError('no');
}

/// Counts LLM calls and returns a canned estimate.
class _CountingBackend implements LlmBackend {
  int calls = 0;
  @override
  String get name => 'counting';
  @override
  Future<String> analyzeMealImage(
      {required String base64Image, String hint = ''}) async {
    calls++;
    return '{"confidence":"high","note":"","items":[{"name":"Mystery dish",'
        '"portion":"1","calories":600,"protein_g":20,"fiber_g":5,"carbs_g":70,'
        '"fat_g":25,"quality_score":"dense"}]}';
  }

  @override
  Future<String> complete(String userText) async => throw StateError('no');
  @override
  Future<String> analyzeMenu(String menuText) async => throw StateError('no');
}

void main() {
  late AppDatabase db;
  late FoodDb foodDb;

  setUpAll(() {
    foodDb = FoodDb.parse(File('assets/nutrition/foods.json').readAsStringSync());
  });
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  // aiEnabled defaults false now (offline-only), so tests exercising the LLM
  // escalation opt in explicitly — which documents that escalation is gated.
  MealEstimator estimator(LlmBackend backend, {bool ai = true}) =>
      MealEstimator(
        LlmCoach(primary: backend, fallback: backend),
        LogRepository(db),
        db,
        Future.value(foodDb),
        aiEnabled: () async => ai,
      );

  test('a locally-known food resolves without touching the LLM', () async {
    final est = await estimator(_NeverCalledBackend()).estimate('2 eggs');
    expect(est, isNotNull);
    expect(est!.caloriesKcal, closeTo(143, 3)); // from the table, not a model
  });

  test('an unknown food escalates to the LLM exactly once, then caches',
      () async {
    final backend = _CountingBackend();
    final est = estimator(backend);

    final first = await est.estimate('szechuan mapo explosion');
    expect(first, isNotNull);
    expect(first!.caloriesKcal, 600);
    expect(backend.calls, 1); // escalated

    // Second identical log is served from the cache — no second LLM call.
    final second = await est.estimate('szechuan mapo explosion');
    expect(second!.caloriesKcal, 600);
    expect(backend.calls, 1, reason: 'cache should prevent a repeat call');
  });

  test('with AI off, an unknown food never touches the network', () async {
    // The shipping default: nutrition is a lookup, and an unresolved food
    // means "log it manually", not a metered API call.
    final backend = _CountingBackend();
    final est = await estimator(backend, ai: false)
        .estimate('szechuan mapo explosion');
    expect(est, isNull);
    expect(backend.calls, 0);
  });

  test('with AI off, a locally-known food still resolves', () async {
    final est = await estimator(_NeverCalledBackend(), ai: false)
        .estimate('2 eggs');
    expect(est, isNotNull);
    expect(est!.caloriesKcal, closeTo(143, 3));
  });

  test('the local resolve is cached too, so a repeat stays free', () async {
    await estimator(_NeverCalledBackend()).estimate('1 cup rice');
    final cached = await db.getMealCache('1 cup rice');
    expect(cached, isNotNull);
    expect(cached!.hitCount, greaterThanOrEqualTo(1));
  });
}
