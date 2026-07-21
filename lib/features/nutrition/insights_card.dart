import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/nutrition_providers.dart';
import '../../domain/daily_insights.dart';

/// "Today's read" — what the day's log actually says, plus what the rest of
/// the day has room for. Sits directly under the fuel card so the numbers
/// and their interpretation are adjacent.
class InsightsCard extends ConsumerWidget {
  const InsightsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final insights = ref.watch(dailyInsightsProvider);
    if (insights.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Today's read",
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 4),
              for (var i = 0; i < insights.length; i++) ...[
                if (i > 0) const Divider(height: 20),
                _InsightRow(insight: insights[i]),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({required this.insight});

  final DailyInsight insight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (insight.tone) {
      InsightTone.good => Colors.green.shade600,
      InsightTone.watch => Colors.orange.shade700,
      InsightTone.info => theme.colorScheme.primary,
    };
    return Semantics(
      container: true,
      label: '${insight.headline}. ${insight.detail}',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icon(insight.icon), size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.headline,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  insight.detail,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static IconData _icon(InsightIcon icon) => switch (icon) {
        InsightIcon.pace => Icons.speed,
        InsightIcon.protein => Icons.egg_alt_outlined,
        InsightIcon.fiber => Icons.grass,
        InsightIcon.water => Icons.water_drop_outlined,
        InsightIcon.balance => Icons.balance,
        InsightIcon.move => Icons.directions_walk,
        InsightIcon.quality => Icons.eco_outlined,
        InsightIcon.plan => Icons.restaurant_menu,
      };
}
