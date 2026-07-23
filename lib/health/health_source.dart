import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

import '../domain/health_models.dart';

/// Read-only wearable telemetry (spec §0): RHR, HRV, respiratory rate,
/// sleep, steps, active minutes.
abstract interface class HealthSource {
  Future<bool> requestPermissions();
  Future<List<DailyBiometrics>> fetchDaily({
    required DateTime from,
    required DateTime to,
  });
}

/// No wearable / permission denied: the score renormalizes to fuel-only.
class EmptyHealthSource implements HealthSource {
  const EmptyHealthSource();

  @override
  Future<bool> requestPermissions() async => false;

  @override
  Future<List<DailyBiometrics>> fetchDaily({
    required DateTime from,
    required DateTime to,
  }) async =>
      const [];
}

class PlatformHealthSource implements HealthSource {
  final _health = Health();

  /// HealthKit and Health Connect expose HRV under different statistics, and
  /// the `health` plugin only maps each one on its own platform: iOS has
  /// SDNN, Android has RMSSD. Asking for the wrong one makes the whole
  /// authorization request fail, taking every other type down with it.
  static HealthDataType get hrvType =>
      defaultTargetPlatform == TargetPlatform.iOS
          ? HealthDataType.HEART_RATE_VARIABILITY_SDNN
          : HealthDataType.HEART_RATE_VARIABILITY_RMSSD;

  /// Only the types the current platform actually supports —
  /// `EXERCISE_TIME` is likewise iOS-only.
  static List<HealthDataType> get types => [
        HealthDataType.RESTING_HEART_RATE,
        hrvType,
        HealthDataType.RESPIRATORY_RATE,
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.STEPS,
        if (defaultTargetPlatform == TargetPlatform.iOS)
          HealthDataType.EXERCISE_TIME,
      ];

  /// Set when the last permission request threw, so the UI can say what
  /// actually went wrong instead of a bare "not granted".
  String? lastError;

  @override
  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    lastError = null;
    try {
      await _health.configure();
      return await _health.requestAuthorization(types);
    } catch (e) {
      // Swallowing this silently is what made a mis-declared data type look
      // like the user tapping "Don't Allow".
      lastError = '$e';
      debugPrint('PulsIQ: health authorization failed: $e');
      return false;
    }
  }

  @override
  Future<List<DailyBiometrics>> fetchDaily({
    required DateTime from,
    required DateTime to,
  }) async {
    if (kIsWeb) return const [];
    try {
      final points = await _health.getHealthDataFromTypes(
        startTime: from,
        endTime: to,
        types: types,
      );
      return _aggregate(points, from, to);
    } catch (e) {
      debugPrint('PulsIQ: health fetch failed: $e');
      return const [];
    }
  }

  List<DailyBiometrics> _aggregate(
    List<HealthDataPoint> points,
    DateTime from,
    DateTime to,
  ) {
    DateTime dayOf(DateTime t) => DateTime(t.year, t.month, t.day);
    final byDay = <DateTime, List<HealthDataPoint>>{};
    for (final p in points) {
      byDay.putIfAbsent(dayOf(p.dateFrom), () => []).add(p);
    }
    double? avgOf(List<HealthDataPoint> list, HealthDataType type) {
      final values = [
        for (final p in list)
          if (p.type == type && p.value is NumericHealthValue)
            (p.value as NumericHealthValue).numericValue.toDouble(),
      ];
      if (values.isEmpty) return null;
      return values.reduce((a, b) => a + b) / values.length;
    }

    double? sumOf(List<HealthDataPoint> list, HealthDataType type) {
      final values = [
        for (final p in list)
          if (p.type == type && p.value is NumericHealthValue)
            (p.value as NumericHealthValue).numericValue.toDouble(),
      ];
      if (values.isEmpty) return null;
      return values.reduce((a, b) => a + b);
    }

    double? sleepHoursOf(List<HealthDataPoint> list) {
      var minutes = 0.0;
      var any = false;
      for (final p in list) {
        if (p.type == HealthDataType.SLEEP_ASLEEP) {
          minutes += p.dateTo.difference(p.dateFrom).inMinutes;
          any = true;
        }
      }
      return any ? minutes / 60.0 : null;
    }

    return [
      for (final entry in byDay.entries)
        DailyBiometrics(
          day: entry.key,
          restingHr: avgOf(entry.value, HealthDataType.RESTING_HEART_RATE),
          hrvMs: avgOf(entry.value, hrvType),
          respiratoryRate:
              avgOf(entry.value, HealthDataType.RESPIRATORY_RATE),
          sleepHours: sleepHoursOf(entry.value),
          steps: sumOf(entry.value, HealthDataType.STEPS)?.round(),
          zone2Minutes:
              sumOf(entry.value, HealthDataType.EXERCISE_TIME)?.round(),
        ),
    ]..sort((a, b) => a.day.compareTo(b.day));
  }
}

/// Seeded, plausible 30-day series for the web preview and demos. Never
/// the default — enabled explicitly from Settings so the score's
/// fuel-only honesty is preserved for real users.
class DemoHealthSource implements HealthSource {
  const DemoHealthSource();

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<List<DailyBiometrics>> fetchDaily({
    required DateTime from,
    required DateTime to,
  }) async {
    final rng = Random(42);
    final days = to.difference(from).inDays;
    var rhr = 62.0, hrv = 61.0, resp = 14.6;
    return [
      for (var i = 0; i <= days; i++)
        () {
          rhr += rng.nextDouble() * 2 - 1;
          hrv += rng.nextDouble() * 4 - 2;
          resp += rng.nextDouble() * 0.4 - 0.2;
          final day = DateTime(from.year, from.month, from.day + i);
          final sleep = 6.2 + rng.nextDouble() * 2.2;
          return DailyBiometrics(
            day: day,
            restingHr: rhr.clamp(52, 74).toDouble(),
            hrvMs: hrv.clamp(38, 92).toDouble(),
            respiratoryRate: resp.clamp(12.5, 16.5).toDouble(),
            sleepHours: sleep,
            sleepEfficiencyPct: (78 + rng.nextDouble() * 16),
            steps: 4500 + rng.nextInt(7000),
            zone2Minutes: rng.nextInt(40),
          );
        }(),
    ];
  }
}
