import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Biometric mocks only — replaced by HealthKit/Health Connect in M5.
/// Everything else on the dashboard is live from the local DB since M2.

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
