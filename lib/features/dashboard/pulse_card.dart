import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../health/health_providers.dart';

/// One Pulse-card row: today's value with its vs-baseline delta and a
/// plain-language one-liner (spec §2: never raw jargon alone).
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

class PulseCard extends ConsumerWidget {
  const PulseCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final rows = ref.watch(pulseCardProvider);
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
            if (rows == null)
              _ConnectPrompt(theme: theme)
            else
              for (final b in rows) _BiometricRow(b: b),
          ],
        ),
      ),
    );
  }
}

class _ConnectPrompt extends ConsumerWidget {
  const _ConnectPrompt({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No wearable data yet. Connect Apple Health or Health Connect '
            'and your pulse leads this dashboard — until then the score '
            'runs fuel-only.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          if (kIsWeb)
            Text(
              'On this preview: Settings → "Demo biometrics" shows the '
              'full experience with generated data.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            )
          else
            OutlinedButton.icon(
              icon: const Icon(Icons.favorite_outline, size: 18),
              label: const Text('Connect health data'),
              onPressed: () async {
                final granted =
                    await ref.read(healthConnectorProvider)();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(
                    content: Text(granted
                        ? 'Connected — pulling your telemetry now.'
                        : 'No permission granted — the score stays '
                            'fuel-only for now.'),
                  ));
              },
            ),
        ],
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
    return Semantics(
      label: '${b.label}: ${b.todayText}, ${b.deltaText}. ${b.insight}',
      container: true,
      child: Padding(
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
    ),
    );
  }
}
