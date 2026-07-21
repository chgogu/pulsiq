import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import '../../data/score_providers.dart';
import '../nutrition/cut_down_card.dart';
import '../nutrition/fuel_card.dart';
import '../walk/walk_timer_card.dart';
import '../logging/entry_sheet.dart';
import 'evening_forecast_card.dart';
import 'hydration_card.dart';
import 'log_tile.dart';
import 'morning_reset_card.dart';
import 'pulse_card.dart';
import 'score_hero.dart';

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
          const WalkTimerCard(),
          const EveningForecastCard(),
          const PulseCard(),
          const SizedBox(height: 16),
          const CutDownCard(),
          const FuelCard(),
          HydrationCard(consumedMl: consumedMl, targetMl: targetMl),
          const SizedBox(height: 24),
          Row(
            children: [
              Text("Today's log", style: theme.textTheme.titleMedium),
              const Spacer(),
              TextButton.icon(
                onPressed: () => showEntrySheet(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
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
