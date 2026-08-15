import 'package:flutter_test/flutter_test.dart';
import 'package:pulsiq/data/db/app_database.dart';
import 'package:pulsiq/data/log_repository.dart';
import 'package:pulsiq/features/history/day_log.dart';

LogItem _food(DateTime at, {int? kcal, String name = 'meal'}) => LogItem(
      kind: LogKind.food,
      id: at.microsecondsSinceEpoch % 100000,
      title: name,
      detail: '',
      loggedAt: at,
      entity: FoodEntry(
        id: at.microsecondsSinceEpoch % 100000,
        name: name,
        quantity: '',
        qualityScore: FuelQuality.clean,
        caloriesKcal: kcal,
        source: 'manual',
        loggedAt: at,
      ),
    );

LogItem _water(DateTime at, int ml) => LogItem(
      kind: LogKind.hydration,
      id: at.microsecondsSinceEpoch % 100000,
      title: 'Water',
      detail: '',
      loggedAt: at,
      entity: HydrationEntry(
        id: at.microsecondsSinceEpoch % 100000,
        amountMl: ml,
        source: 'quick_add',
        loggedAt: at,
      ),
    );

LogItem _exercise(DateTime at, int minutes) => LogItem(
      kind: LogKind.exercise,
      id: at.microsecondsSinceEpoch % 100000,
      title: 'Walk',
      detail: '',
      loggedAt: at,
      entity: ExerciseEntry(
        id: at.microsecondsSinceEpoch % 100000,
        activity: 'Walk',
        durationMinutes: minutes,
        intensity: ExerciseIntensity.moderate,
        loggedAt: at,
      ),
    );

void main() {
  test('buckets mixed-kind items into distinct days, newest first', () {
    final d1 = DateTime(2026, 8, 15, 9);
    final d2 = DateTime(2026, 8, 14, 20);
    final d3 = DateTime(2026, 8, 12, 7);
    final days = groupIntoDays([
      _food(d1, kcal: 500),
      _water(d2, 500),
      _food(d3, kcal: 300),
    ]);
    expect(days.length, 3);
    expect(days[0].day, DateTime(2026, 8, 15));
    expect(days[1].day, DateTime(2026, 8, 14));
    expect(days[2].day, DateTime(2026, 8, 12));
  });

  test('per-day totals sum calories, water, exercise and food count', () {
    final day = DateTime(2026, 8, 15);
    final result = groupIntoDays([
      _food(day.add(const Duration(hours: 8)), kcal: 400),
      _food(day.add(const Duration(hours: 13)), kcal: 650),
      _water(day.add(const Duration(hours: 9)), 750),
      _exercise(day.add(const Duration(hours: 18)), 30),
    ]);
    expect(result.length, 1);
    final d = result.single;
    expect(d.calories, 1050);
    expect(d.waterMl, 750);
    expect(d.exerciseMinutes, 30);
    expect(d.foodCount, 2);
  });

  test('same-day items stay in one bucket, newest-first', () {
    final day = DateTime(2026, 8, 15);
    final early = _food(day.add(const Duration(hours: 8)), name: 'breakfast');
    final late = _food(day.add(const Duration(hours: 19)), name: 'dinner');
    final d = groupIntoDays([early, late]).single;
    expect(d.items.length, 2);
    expect(d.items.first.title, 'dinner'); // newest first
    expect(d.items.last.title, 'breakfast');
  });

  test('YearSummary averages kcal only over days with food', () {
    final days = groupIntoDays([
      _food(DateTime(2026, 8, 15, 9), kcal: 2000),
      _food(DateTime(2026, 8, 14, 9), kcal: 1000),
      _water(DateTime(2026, 8, 13, 9), 500), // water-only day: no food
    ]);
    final summary = YearSummary.from(days);
    expect(summary.daysLogged, 3);
    expect(summary.totalItems, 3);
    expect(summary.avgKcalOnLoggedDays, 1500); // (2000+1000)/2, ignores the water day
  });

  test('empty feed yields no days and a zeroed summary', () {
    final days = groupIntoDays([]);
    expect(days, isEmpty);
    final summary = YearSummary.from(days);
    expect(summary.daysLogged, 0);
    expect(summary.avgKcalOnLoggedDays, 0);
  });
}
