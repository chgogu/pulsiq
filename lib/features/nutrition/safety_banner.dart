import 'package:flutter/material.dart';

import '../../domain/food_safety.dart';

/// "Can I eat this?" banner for a snapped meal or scanned product, judged
/// against the user's health goals. Renders nothing when there's no opinion.
///
/// Framed as general guidance — the fine print says it's not medical advice,
/// which matters for the diabetes/pregnancy paths.
class SafetyBanner extends StatelessWidget {
  const SafetyBanner({super.key, required this.verdict});

  final SafetyVerdict verdict;

  @override
  Widget build(BuildContext context) {
    // No goals set → no basis for a Yes/No, so show nothing.
    if (!verdict.hasAnswer) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final yes = verdict.canEat;

    final color = yes
        ? (dark ? const Color(0xFF34D399) : const Color(0xFF059669))
        : (dark ? const Color(0xFFF87171) : const Color(0xFFDC2626));
    final icon = yes ? Icons.check_circle : Icons.cancel;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: dark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(width: 12),
              // The one thing the user is here for: a straight answer.
              Text(verdict.answer,
                  style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800, color: color)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(verdict.oneLiner,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurface)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Based on your goals · general guidance, not medical advice.',
            style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}
