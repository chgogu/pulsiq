import '../../data/db/app_database.dart';
import '../../data/log_repository.dart';

/// One calendar day's worth of logged items plus its rolled-up totals.
/// Pure data — no Flutter, so the grouping stays unit-testable.
class DayLog {
  DayLog({
    required this.day,
    required this.items,
    required this.calories,
    required this.waterMl,
    required this.exerciseMinutes,
    required this.foodCount,
  });

  final DateTime day; // midnight-aligned local day
  final List<LogItem> items; // newest-first within the day
  final int calories;
  final int waterMl;
  final int exerciseMinutes;
  final int foodCount;

  bool get hasFood => foodCount > 0;
}

DateTime _dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

/// Buckets a flat, newest-first feed into per-day groups (newest day first),
/// summing calories / water / exercise off the underlying drift entities.
List<DayLog> groupIntoDays(List<LogItem> items) {
  final buckets = <DateTime, List<LogItem>>{};
  for (final item in items) {
    (buckets[_dayOf(item.loggedAt)] ??= <LogItem>[]).add(item);
  }

  final days = buckets.keys.toList()..sort((a, b) => b.compareTo(a));
  return [
    for (final day in days)
      _summarise(day, buckets[day]!..sort((a, b) => b.loggedAt.compareTo(a.loggedAt))),
  ];
}

DayLog _summarise(DateTime day, List<LogItem> dayItems) {
  var calories = 0;
  var waterMl = 0;
  var exerciseMinutes = 0;
  var foodCount = 0;
  for (final item in dayItems) {
    switch (item.kind) {
      case LogKind.food:
        foodCount++;
        final e = item.entity as FoodEntry;
        calories += e.caloriesKcal ?? 0;
      case LogKind.hydration:
        waterMl += (item.entity as HydrationEntry).amountMl;
      case LogKind.beverage:
        break;
      case LogKind.exercise:
        exerciseMinutes += (item.entity as ExerciseEntry).durationMinutes;
    }
  }
  return DayLog(
    day: day,
    items: dayItems,
    calories: calories,
    waterMl: waterMl,
    exerciseMinutes: exerciseMinutes,
    foodCount: foodCount,
  );
}

/// Year-level rollup shown at the top of the History screen.
class YearSummary {
  const YearSummary({
    required this.daysLogged,
    required this.avgKcalOnLoggedDays,
    required this.totalItems,
  });

  final int daysLogged;
  final int avgKcalOnLoggedDays;
  final int totalItems;

  factory YearSummary.from(List<DayLog> days) {
    final withFood = days.where((d) => d.hasFood).toList();
    final avg = withFood.isEmpty
        ? 0
        : (withFood.fold<int>(0, (s, d) => s + d.calories) / withFood.length)
            .round();
    return YearSummary(
      daysLogged: days.length,
      avgKcalOnLoggedDays: avg,
      totalItems: days.fold<int>(0, (s, d) => s + d.items.length),
    );
  }
}
