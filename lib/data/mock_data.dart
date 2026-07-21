import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/pulsiq_score.dart';

/// M1 mock data. Drift-backed providers replace these in M2, and
/// HealthKit/Health Connect feeds the biometrics in M5.

class BiometricDelta {
  const BiometricDelta({
    required this.label,
    required this.todayText,
    required this.delta,
    required this.deltaText,
    required this.insight,
    required this.icon,
    this.higherIsBetter = true,
  });

  final String label;
  final String todayText;
  final double delta;
  final String deltaText;
  final String insight;
  final IconData icon;
  final bool higherIsBetter;

  bool get improving => higherIsBetter ? delta >= 0 : delta <= 0;
}

class HydrationState {
  const HydrationState({required this.consumedMl, required this.targetMl});

  final int consumedMl;
  final int targetMl;

  double get progress => (consumedMl / targetMl).clamp(0.0, 1.0);
}

enum LogKind { food, beverage, hydration, exercise }

class LogEntry {
  const LogEntry({
    required this.kind,
    required this.time,
    required this.title,
    required this.detail,
  });

  final LogKind kind;
  final String time;
  final String title;
  final String detail;
}

final scoreInputProvider = Provider(
  (_) => const PulsIQScoreInput(
    cardiacRecovery: 0.82,
    sleepQuality: 0.76,
    fuelQuality: 0.64,
    hydrationProgress: 0.47,
  ),
);

final scoreResultProvider =
    Provider((ref) => computePulsIQScore(ref.watch(scoreInputProvider)));

final biometricsProvider = Provider(
  (_) => const [
    BiometricDelta(
      label: 'Resting HR',
      todayText: '58 bpm',
      delta: -4,
      deltaText: '4 under baseline',
      insight: "Your heart's running 4 beats calmer than usual.",
      icon: Icons.favorite_outline,
      higherIsBetter: false,
    ),
    BiometricDelta(
      label: 'HRV',
      todayText: '72 ms',
      delta: 11,
      deltaText: '11 over baseline',
      insight: 'Recovery is trending up — solid night for your system.',
      icon: Icons.monitor_heart_outlined,
    ),
    BiometricDelta(
      label: 'Respiratory rate',
      todayText: '14.1 /min',
      delta: -0.5,
      deltaText: '0.5 under baseline',
      insight: 'Breathing is settled and steady.',
      icon: Icons.air,
      higherIsBetter: false,
    ),
    BiometricDelta(
      label: 'Sleep efficiency',
      todayText: '91%',
      delta: 3,
      deltaText: '3 over baseline',
      insight: 'More of last night went to actual sleep.',
      icon: Icons.bedtime_outlined,
    ),
  ],
);

final hydrationProvider =
    Provider((_) => const HydrationState(consumedMl: 1150, targetMl: 2450));

final logFeedProvider = Provider(
  (_) => const [
    LogEntry(
      kind: LogKind.exercise,
      time: '4:10 PM',
      title: 'Zone-2 walk',
      detail: '25 min · moderate',
    ),
    LogEntry(
      kind: LogKind.hydration,
      time: '2:35 PM',
      title: 'Water',
      detail: '+475 ml',
    ),
    LogEntry(
      kind: LogKind.food,
      time: '12:40 PM',
      title: 'Chicken burrito bowl',
      detail: 'clean fuel · steady energy',
    ),
    LogEntry(
      kind: LogKind.beverage,
      time: '8:05 AM',
      title: 'Oat-milk latte',
      detail: 'caffeine · 9 g sugar',
    ),
  ],
);
