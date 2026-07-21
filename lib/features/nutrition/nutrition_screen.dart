import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/nutrition_providers.dart';
import '../../data/providers.dart';
import '../../domain/nutrition.dart';
import '../../theme/macro_colors.dart';
import '../../theme/pulse_theme.dart';
import 'cut_down_card.dart';
import 'macro_trend_chart.dart';

/// Nutrition detail: per-macro progress, a 7-day calorie trend, the cut-down
/// advice, and today's meal breakdown. Reachable from the fuel card.
class NutritionScreen extends ConsumerWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final totals =
        ref.watch(macroTotalsProvider).value ?? const MacroTotals.zero();
    final targets =
        ref.watch(nutritionTargetsProvider).value ?? const NutritionTargets();
    final foods = ref.watch(todayFoodsProvider).value ?? const [];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Nutrition'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Edit targets',
            icon: const Icon(Icons.tune),
            onPressed: () => _editTargets(context, ref, targets),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          const CutDownCard(),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Today vs targets',
                      style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 12),
                  _MacroRow(
                    kind: MacroKind.calories,
                    value: totals.calories.toDouble(),
                    target: targets.calories.toDouble(),
                    unit: 'kcal',
                    color: PulseColors.pulse,
                  ),
                  _MacroRow(
                    kind: MacroKind.protein,
                    value: totals.proteinG,
                    target: targets.proteinG,
                    unit: 'g',
                    color: MacroColors.of(MacroKind.protein, theme.brightness),
                  ),
                  _MacroRow(
                    kind: MacroKind.fiber,
                    value: totals.fiberG,
                    target: targets.fiberG,
                    unit: 'g',
                    color: MacroColors.of(MacroKind.fiber, theme.brightness),
                  ),
                  _MacroRow(
                    kind: MacroKind.carbs,
                    value: totals.carbsG,
                    target: targets.carbsG,
                    unit: 'g',
                    color: MacroColors.of(MacroKind.carbs, theme.brightness),
                  ),
                  _MacroRow(
                    kind: MacroKind.fat,
                    value: totals.fatG,
                    target: targets.fatG,
                    unit: 'g',
                    color: MacroColors.of(MacroKind.fat, theme.brightness),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _BasisCard(targets: targets),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('7-day calories',
                      style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 12),
                  MacroTrendChart(targetCalories: targets.calories),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text("Today's meals", style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (foods.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('No meals logged yet today.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
            )
          else
            for (final f in foods)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(f.name),
                  subtitle: Text([
                    if (f.caloriesKcal != null) '${f.caloriesKcal} kcal',
                    if (f.proteinG != null) '${f.proteinG!.round()}g protein',
                    if (f.fiberG != null) '${f.fiberG!.round()}g fiber',
                  ].join(' · ')),
                  trailing: Text(f.qualityScore.name,
                      style: theme.textTheme.labelSmall),
                ),
              ),
        ],
      ),
    );
  }

  Future<void> _editTargets(
      BuildContext context, WidgetRef ref, NutritionTargets current) async {
    final calCtl = TextEditingController(text: '${current.calories}');
    final proCtl = TextEditingController(text: '${current.proteinG.round()}');
    final fibCtl = TextEditingController(text: '${current.fiberG.round()}');
    final saved = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Daily targets',
                style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('Sensible starting points — not medical prescriptions.',
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            TextField(
              controller: calCtl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Calories (kcal)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: proCtl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Protein (g)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: fibCtl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Fiber (g)'),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, 'manual'),
              child: const Text('Save targets'),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'auto'),
              child: const Text('Recompute from my body profile'),
            ),
          ],
        ),
      ),
    );
    if (saved == null) return;
    final db = ref.read(appDatabaseProvider);
    if (saved == 'auto') {
      await db.setSetting(targetsModeKey, 'auto');
      ref.invalidate(nutritionTargetsProvider);
      return;
    }
    // Carbs and fat aren't in the sheet; carry them through so a manual
    // calorie edit doesn't silently drop them back to defaults.
    final next = current.copyWith(
      calories: int.tryParse(calCtl.text) ?? current.calories,
      proteinG: double.tryParse(proCtl.text) ?? current.proteinG,
      fiberG: double.tryParse(fibCtl.text) ?? current.fiberG,
    );
    for (final entry in next.toSettings().entries) {
      await db.setSetting(entry.key, entry.value);
    }
    await db.setSetting(targetsModeKey, 'manual');
    ref.invalidate(nutritionTargetsProvider);
  }
}

/// Explains where today's targets came from, and routes to the body profile
/// when there isn't one yet — the main discovery path for personalization.
class _BasisCard extends ConsumerWidget {
  const _BasisCard({required this.targets});

  final NutritionTargets targets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final body = ref.watch(bodyProfileProvider).value;

    final (icon, title, detail) = switch (targets.source) {
      TargetSource.derived when body != null => (
          Icons.auto_awesome,
          'Personalized to your body',
          '${body.activity.label.toLowerCase()} · ${body.goal.label.toLowerCase()} · '
              'resting burn ${body.bmr.round()} kcal, daily burn '
              '${body.tdee.round()} kcal',
        ),
      TargetSource.manual => (
          Icons.edit_outlined,
          'Targets set by hand',
          'Tap the tune icon to edit, or recompute from your body profile.',
        ),
      _ => (
          Icons.person_add_alt,
          'Using general defaults',
          'Add your height and weight to get targets sized to your body.',
        ),
    };

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/settings/body'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Row(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(detail,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  size: 20, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  const _MacroRow({
    required this.kind,
    required this.value,
    required this.target,
    required this.unit,
    required this.color,
  });

  final MacroKind kind;
  final double value;
  final double? target;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fraction = target == null || target == 0
        ? 0.0
        : (value / target!).clamp(0.0, 1.0).toDouble();
    final over = target != null && value > target!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(MacroColors.label(kind), style: theme.textTheme.bodyMedium),
              const Spacer(),
              Text(
                target == null
                    ? '${value.round()} $unit'
                    : '${value.round()} / ${target!.round()} $unit',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: over ? Colors.orange.shade700 : null,
                ),
              ),
            ],
          ),
          if (target != null) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 6,
                child: Stack(children: [
                  Container(color: theme.colorScheme.surfaceContainerHighest),
                  FractionallySizedBox(
                    widthFactor: fraction,
                    child: Container(color: color),
                  ),
                ]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
