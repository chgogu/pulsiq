import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock_data.dart';
import 'hydration_card.dart';
import 'log_tile.dart';
import 'pulse_card.dart';
import 'score_hero.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final score = ref.watch(scoreResultProvider);
    final biometrics = ref.watch(biometricsProvider);
    final hydration = ref.watch(hydrationProvider);
    final log = ref.watch(logFeedProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          Row(
            children: [
              Text(
                'PulsIQ',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Text(
                _todayLabel(),
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ScoreHero(result: score),
          const SizedBox(height: 16),
          PulseCard(biometrics: biometrics),
          const SizedBox(height: 16),
          HydrationCard(hydration: hydration),
          const SizedBox(height: 24),
          Text("Today's log", style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final entry in log) LogTile(entry: entry),
        ],
      ),
    );
  }

  static String _todayLabel() {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final now = DateTime.now();
    return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }
}
