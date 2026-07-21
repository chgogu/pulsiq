/// Nutrition analytics domain — daily macro totals, targets, and progress.
/// Pure and testable; the DB aggregates into [MacroTotals], the UI renders
/// [MacroProgress] against [NutritionTargets].
library;

class MacroTotals {
  const MacroTotals({
    required this.calories,
    required this.proteinG,
    required this.fiberG,
    required this.carbsG,
    required this.fatG,
  });

  const MacroTotals.zero()
      : calories = 0,
        proteinG = 0,
        fiberG = 0,
        carbsG = 0,
        fatG = 0;

  final int calories;
  final double proteinG;
  final double fiberG;
  final double carbsG;
  final double fatG;

  bool get isEmpty =>
      calories == 0 && proteinG == 0 && fiberG == 0 && carbsG == 0 && fatG == 0;

  MacroTotals plus(MacroTotals other) => MacroTotals(
        calories: calories + other.calories,
        proteinG: proteinG + other.proteinG,
        fiberG: fiberG + other.fiberG,
        carbsG: carbsG + other.carbsG,
        fatG: fatG + other.fatG,
      );
}

class DayMacros {
  const DayMacros(this.day, this.totals);

  final DateTime day;
  final MacroTotals totals;
}

/// Daily targets. Owner-editable in Settings; defaults are the app's
/// sensible starting point, not medical prescriptions.
class NutritionTargets {
  const NutritionTargets({
    this.calories = 2000,
    this.proteinG = 100,
    this.fiberG = 30,
  });

  final int calories;
  final double proteinG;
  final double fiberG;

  NutritionTargets copyWith({int? calories, double? proteinG, double? fiberG}) =>
      NutritionTargets(
        calories: calories ?? this.calories,
        proteinG: proteinG ?? this.proteinG,
        fiberG: fiberG ?? this.fiberG,
      );

  Map<String, String> toSettings() => {
        'target_calories': '$calories',
        'target_protein_g': '$proteinG',
        'target_fiber_g': '$fiberG',
      };

  static NutritionTargets fromSettings(String? Function(String) get) {
    final d = const NutritionTargets();
    return NutritionTargets(
      calories: int.tryParse(get('target_calories') ?? '') ?? d.calories,
      proteinG: double.tryParse(get('target_protein_g') ?? '') ?? d.proteinG,
      fiberG: double.tryParse(get('target_fiber_g') ?? '') ?? d.fiberG,
    );
  }
}

enum MacroKind { calories, protein, fiber, carbs, fat }

class MacroProgress {
  const MacroProgress({
    required this.kind,
    required this.value,
    required this.target,
    required this.unit,
  });

  final MacroKind kind;
  final double value;
  final double? target; // carbs/fat have no fixed target
  final String unit;

  /// 0..1 fraction of target (clamped for the ring; may exceed 1 logically).
  double get fraction =>
      (target == null || target == 0) ? 0 : (value / target!).clamp(0.0, 1.0);

  double get rawFraction =>
      (target == null || target == 0) ? 0 : value / target!;

  bool get over => target != null && value > target!;
}
