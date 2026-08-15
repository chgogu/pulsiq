import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../data/providers.dart';
import '../domain/health_score.dart';
import '../domain/whoop.dart';
import 'health_providers.dart';
import 'whoop/whoop_providers.dart';

/// Source keys used in the snapshot store.
const whoopSourceKey = 'whoop';
const appleHealthSourceKey = 'appleHealth';

/// The dashboard's per-source Health Score payload: today's score, the window
/// average, its band, and the daily series behind the trend.
class HealthScoreView {
  const HealthScoreView({
    required this.today,
    required this.average,
    required this.series,
    required this.windowDays,
  });

  final int? today;
  final int? average;
  final List<({DateTime day, int score})> series;
  final int windowDays;

  HealthBand? get band => today == null ? null : HealthBand.of(today!);
  bool get hasScore => today != null;
}

DateTime _dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

/// Builds the view from a body window and persists each day's snapshot so
/// history accumulates past the API's rolling window.
Future<HealthScoreView?> _viewFrom(
  Ref ref,
  WhoopBody body,
  String sourceKey,
  int windowDays,
) async {
  if (body.isEmpty) return null;
  final series = dailyHealthScores(body);
  if (series.isEmpty) return null;

  final byDay = {for (final d in body.days) _dayOf(d.day): d};
  final rows = <HealthScoreSnapshotsCompanion>[
    for (final s in series)
      HealthScoreSnapshotsCompanion.insert(
        day: _dayOf(s.day),
        source: sourceKey,
        score: s.score,
        hrvMs: Value(byDay[_dayOf(s.day)]?.hrvMs),
        restingHr: Value(byDay[_dayOf(s.day)]?.restingHr),
        sleepHours: Value(byDay[_dayOf(s.day)]?.sleepHours),
        recoveryPct: Value(byDay[_dayOf(s.day)]?.recoveryPct),
        steps: Value(byDay[_dayOf(s.day)]?.steps),
      ),
  ];
  await ref.read(appDatabaseProvider).upsertHealthSnapshots(rows);

  return HealthScoreView(
    today: computeHealthScore(body).value,
    average: averageHealthScore(body),
    series: series,
    windowDays: windowDays,
  );
}

/// WHOOP Health Score — null when WHOOP isn't linked or has no scored data.
final whoopHealthScoreProvider =
    FutureProvider<HealthScoreView?>((ref) async {
  final result = await ref.watch(whoopBodyProvider.future);
  final body = result?.body;
  if (body == null) return null;
  return _viewFrom(ref, body, whoopSourceKey, 60);
});

/// Apple Health / Health Connect Health Score — its own number, independent of
/// WHOOP so turning one off never hides the other.
final appleHealthScoreProvider =
    FutureProvider<HealthScoreView?>((ref) async {
  final signals = await ref.watch(platformBodySignalsProvider.future);
  if (signals == null) return null;
  return _viewFrom(ref, signals.body, appleHealthSourceKey, signals.windowDays);
});

/// Average calories per logged day over the last year — the food half of the
/// dashboard averages strip.
final avgCaloriesPerDayProvider = Provider<int?>((ref) {
  final items = ref.watch(logHistoryProvider).value;
  if (items == null) return null;
  final byDay = <DateTime, int>{};
  for (final item in items) {
    if (item.entity is FoodEntry) {
      final e = item.entity as FoodEntry;
      byDay.update(_dayOf(item.loggedAt), (v) => v + (e.caloriesKcal ?? 0),
          ifAbsent: () => e.caloriesKcal ?? 0);
    }
  }
  final withFood = byDay.values.where((v) => v > 0).toList();
  if (withFood.isEmpty) return null;
  return (withFood.fold<int>(0, (s, v) => s + v) / withFood.length).round();
});
