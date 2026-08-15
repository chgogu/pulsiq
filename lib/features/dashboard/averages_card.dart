import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../health/health_score_providers.dart';

/// A compact "your averages" strip on the dashboard: average calories per
/// logged day plus each connected source's average Health Score. Hidden until
/// there's at least one average to show. Tapping opens the full history.
class AveragesCard extends ConsumerWidget {
  const AveragesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final kcal = ref.watch(avgCaloriesPerDayProvider);
    final whoop = ref.watch(whoopHealthScoreProvider).value?.average;
    final apple = ref.watch(appleHealthScoreProvider).value?.average;

    final tiles = <({String label, String value})>[
      if (kcal != null) (label: 'kcal / day', value: _thousands(kcal)),
      if (whoop != null) (label: 'WHOOP score', value: '$whoop'),
      if (apple != null) (label: 'Apple score', value: '$apple'),
    ];
    if (tiles.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/history'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.insights_outlined,
                        size: 18, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Text('Your averages',
                        style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            letterSpacing: 0.3)),
                    const Spacer(),
                    Icon(Icons.chevron_right,
                        size: 18, color: theme.colorScheme.onSurfaceVariant),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (final (i, t) in tiles.indexed) ...[
                      if (i > 0)
                        Container(
                          width: 1,
                          height: 34,
                          color: theme.dividerColor.withValues(alpha: 0.4),
                        ),
                      Expanded(child: _AvgTile(label: t.label, value: t.value)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AvgTile extends StatelessWidget {
  const _AvgTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(value,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

String _thousands(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}
