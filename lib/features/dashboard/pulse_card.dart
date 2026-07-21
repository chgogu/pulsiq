import 'package:flutter/material.dart';

import '../../data/mock_data.dart';

class PulseCard extends StatelessWidget {
  const PulseCard({super.key, required this.biometrics});

  final List<BiometricDelta> biometrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pulse',
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            for (final b in biometrics) _BiometricRow(b: b),
          ],
        ),
      ),
    );
  }
}

class _BiometricRow extends StatelessWidget {
  const _BiometricRow({required this.b});

  final BiometricDelta b;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trendColor = b.improving
        ? (theme.brightness == Brightness.dark
            ? Colors.greenAccent.shade200
            : Colors.green.shade700)
        : Colors.orange.shade700;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(b.icon, size: 20, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b.label, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 2),
                Text(
                  b.insight,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                b.todayText,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    b.delta >= 0 ? Icons.trending_up : Icons.trending_down,
                    size: 14,
                    color: trendColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    b.deltaText,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: trendColor),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
