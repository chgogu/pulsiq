import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import '../../data/score_providers.dart';
import '../nutrition/cut_down_card.dart';
import '../nutrition/fuel_card.dart';
import '../nutrition/insights_card.dart';
import '../walk/walk_timer_card.dart';
import '../logging/entry_sheet.dart';
import 'evening_forecast_card.dart';
import 'hydration_card.dart';
import 'log_tile.dart';
import 'morning_reset_card.dart';
import 'pulse_card.dart';
import 'score_hero.dart';
import 'spark_card.dart';
import 'whoop_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final score = ref.watch(scoreResultProvider);
    final consumedMl = ref.watch(todayHydrationMlProvider).value ?? 0;
    final targetMl = ref.watch(hydrationTargetProvider);
    final feed = ref.watch(logFeedProvider);

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
              IconButton(
                tooltip: 'Settings',
                onPressed: () => context.push('/settings'),
                icon: const Icon(Icons.settings_outlined, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const MorningResetCard(),
          ScoreHero(result: score),
          const SizedBox(height: 16),
          // Two clearly separate actions, right under the score so logging
          // never needs a scroll: LOG what you ate (goes in the diary) vs
          // CHECK whether you can eat something (a verdict, no diary entry).
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => showEntrySheet(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Log food'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/check-food'),
                  icon: const Icon(Icons.fact_check_outlined, size: 18),
                  label: const Text('Can I eat this?'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Today's log sits directly below the score — the daily job, above
          // the analytics that reward it.
          Text("Today's log", style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          switch (feed) {
            AsyncData(value: final items) when items.isEmpty => Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Nothing logged yet today. Tap the pulse button for '
                  'water, or Add for anything else.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            AsyncData(value: final items) => Column(
                children: [for (final item in items) LogTile(item: item)],
              ),
            AsyncError() => Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text("Couldn't load today's log.",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium),
              ),
            _ => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
          },
          const SizedBox(height: 20),
          // Analytics follow the log — the reward for having logged, not the
          // wall between the user and the log.
          const WhoopCard(),
          const PlatformHealthCard(),
          const FuelCard(),
          const InsightsCard(),
          const CutDownCard(),
          HydrationCard(consumedMl: consumedMl, targetMl: targetMl),
          const SizedBox(height: 16),
          const WalkTimerCard(),
          const EveningForecastCard(),
          const PulseCard(),
          const SizedBox(height: 16),
          const SparkCard(),
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
