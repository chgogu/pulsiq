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

/// Where a set of targets came from — drives how the UI explains itself.
enum TargetSource {
  /// Flat population defaults; no body profile on file yet.
  defaults,

  /// Computed from the user's height/weight/age/activity/goal.
  derived,

  /// Typed in by hand, which always wins over derivation.
  manual,
}

/// Daily targets. Derived from the body profile when one exists, otherwise
/// flat defaults; either way overridable by hand. Starting points, not
/// medical prescriptions.
class NutritionTargets {
  const NutritionTargets({
    this.calories = 2000,
    this.proteinG = 100,
    this.fiberG = 30,
    this.carbsG = 250,
    this.fatG = 67,
    this.source = TargetSource.defaults,
  });

  final int calories;
  final double proteinG;
  final double fiberG;
  final double carbsG;
  final double fatG;
  final TargetSource source;

  NutritionTargets copyWith({
    int? calories,
    double? proteinG,
    double? fiberG,
    double? carbsG,
    double? fatG,
    TargetSource? source,
  }) =>
      NutritionTargets(
        calories: calories ?? this.calories,
        proteinG: proteinG ?? this.proteinG,
        fiberG: fiberG ?? this.fiberG,
        carbsG: carbsG ?? this.carbsG,
        fatG: fatG ?? this.fatG,
        source: source ?? this.source,
      );

  Map<String, String> toSettings() => {
        'target_calories': '$calories',
        'target_protein_g': '$proteinG',
        'target_fiber_g': '$fiberG',
        'target_carbs_g': '$carbsG',
        'target_fat_g': '$fatG',
      };

  static NutritionTargets fromSettings(String? Function(String) get) {
    final d = const NutritionTargets();
    return NutritionTargets(
      calories: int.tryParse(get('target_calories') ?? '') ?? d.calories,
      proteinG: double.tryParse(get('target_protein_g') ?? '') ?? d.proteinG,
      fiberG: double.tryParse(get('target_fiber_g') ?? '') ?? d.fiberG,
      carbsG: double.tryParse(get('target_carbs_g') ?? '') ?? d.carbsG,
      fatG: double.tryParse(get('target_fat_g') ?? '') ?? d.fatG,
      source: TargetSource.manual,
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
