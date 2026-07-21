import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/nutrition_providers.dart';
import '../../theme/pulse_theme.dart';

/// Quote of the day, with the joke tucked behind a tap.
///
/// The quote is the part that carries weight, so it gets the visual real
/// estate; the joke is a reward for poking at it, not something that shouts
/// over the health content on first read.
class SparkCard extends ConsumerStatefulWidget {
  const SparkCard({super.key});

  @override
  ConsumerState<SparkCard> createState() => _SparkCardState();
}

class _SparkCardState extends ConsumerState<SparkCard> {
  bool _jokeShown = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spark = ref.watch(dailySparkProvider);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.format_quote,
                      size: 18, color: PulseColors.pulse),
                  const SizedBox(width: 8),
                  Text(
                    'Today',
                    style: theme.textTheme.labelLarge
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                spark.quote,
                style: theme.textTheme.titleMedium?.copyWith(
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (spark.attribution != null) ...[
                const SizedBox(height: 6),
                Text(
                  '— ${spark.attribution}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
              const Divider(height: 26),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 220),
                crossFadeState: _jokeShown
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _jokeShown = true),
                    icon: const Icon(Icons.sentiment_very_satisfied, size: 18),
                    label: const Text("And today's cynicism"),
                  ),
                ),
                secondChild: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.sentiment_very_satisfied,
                          size: 18, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          spark.joke,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
