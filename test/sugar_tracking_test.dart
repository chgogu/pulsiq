import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsiq/data/db/app_database.dart';
import 'package:pulsiq/data/log_repository.dart';
import 'package:pulsiq/domain/llm_contract.dart';
import 'package:pulsiq/domain/meal_vision.dart';

void main() {
  test('food sugar is stored and summed into the day total', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = LogRepository(db);

    await repo.addFood(
      name: 'Gulab jamun',
      quantity: '2 pieces',
      quality: FuelQuality.dense,
      caloriesKcal: 300,
      proteinG: 4,
      fiberG: 1,
      carbsG: 50,
      fatG: 10,
      sugarG: 40,
    );
    await repo.addFood(
      name: 'Apple',
      quantity: '1',
      quality: FuelQuality.clean,
      caloriesKcal: 95,
      proteinG: 0,
      fiberG: 4,
      carbsG: 25,
      fatG: 0,
      sugarG: 19,
    );

    final totals = await db.watchMacroTotals().first;
    expect(totals.sugarG, 59);
  });

  test('a voice reply carries sugar per food item', () {
    const json = '{"log_summary":{"food_items":[{"name":"Soda-braised pork",'
        '"quantity":"1 bowl","quality_score":"dense","calories":500,'
        '"protein_g":30,"fiber_g":2,"carbs_g":40,"fat_g":22,"sugar_g":28}],'
        '"beverages":[],"hydration_added_ml":0,"exercise_logged":[]},'
        '"energy_impact_analysis":{"glycemic_load_estimate":"high_spike",'
        '"post_meal_action_required":true,"recommended_walk_minutes":12},'
        '"coaching_message":"Logged."}';
    final reply = parseCoachReply(json);
    expect(reply.logSummary.foodItems.single.sugarG, 28);
  });

  test('a meal-vision reply sums sugar across items', () {
    const json = '{"confidence":"high","note":"",'
        '"items":[{"name":"Cake","portion":"1 slice","calories":350,'
        '"protein_g":4,"fiber_g":1,"carbs_g":50,"fat_g":16,"sugar_g":35,'
        '"quality_score":"dense"},'
        '{"name":"Latte","portion":"1","calories":150,"protein_g":8,'
        '"fiber_g":0,"carbs_g":18,"fat_g":6,"sugar_g":16,'
        '"quality_score":"moderate"}]}';
    expect(parseMealVision(json).totalSugar, 51);
  });

  test('a reply without sugar fields still parses (defaults to 0)', () {
    const json = '{"confidence":"medium","note":"",'
        '"items":[{"name":"Rice","portion":"1 cup","calories":200,'
        '"protein_g":4,"fiber_g":1,"carbs_g":45,"fat_g":0,'
        '"quality_score":"moderate"}]}';
    final r = parseMealVision(json);
    expect(r.items.single.sugarG, 0);
    expect(r.totalSugar, 0);
  });
}
