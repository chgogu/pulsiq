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
    if (!verdict.hasOpinion) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    final (color, icon) = switch (verdict.level) {
      SafetyLevel.good => (
          dark ? const Color(0xFF34D399) : const Color(0xFF059669),
          Icons.check_circle_outline,
        ),
      SafetyLevel.caution => (
          dark ? const Color(0xFFEAB308) : const Color(0xFFCA8A04),
          Icons.info_outline,
        ),
      SafetyLevel.avoid => (
          dark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
          Icons.do_not_disturb_on_outlined,
        ),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: dark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(verdict.headline,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800, color: color)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final r in verdict.reasons)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${r.goal.label}: ',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  Expanded(
                    child: Text(r.text, style: theme.textTheme.bodySmall),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Text(
            'General guidance from your goals — not medical advice.',
            style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}
