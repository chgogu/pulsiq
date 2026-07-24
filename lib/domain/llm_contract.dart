/// The structured-output contract from spec §1, with a strict validator.
/// The backend proxy validates too; the client re-validates because it must
/// never insert malformed rows, whatever the transport claims.
library;

import 'dart:convert';

class FoodItem {
  const FoodItem({
    required this.name,
    required this.quantity,
    required this.qualityScore,
    this.caloriesKcal,
    this.proteinG,
    this.fiberG,
    this.carbsG,
    this.fatG,
    this.sugarG,
  });

  final String name;
  final String quantity;
  final String qualityScore; // clean | moderate | dense

  /// Macros are optional so an older backend (or a model that declines to
  /// guess) still parses. Absent macros mean the entry is logged but can't
  /// contribute to the day's fuel totals.
  final int? caloriesKcal;
  final double? proteinG;
  final double? fiberG;
  final double? carbsG;
  final double? fatG;
  final double? sugarG;

  bool get hasMacros => caloriesKcal != null;

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      name: _string(json, 'name'),
      quantity: json['quantity'] is String ? json['quantity'] as String : '',
      // A model naming quality "healthy" or "high" must not sink the whole
      // meal — coerce to the nearest bucket, default moderate.
      qualityScore: _quality(json['quality_score']),
      caloriesKcal: _optionalNum(json, 'calories')?.round(),
      proteinG: _optionalNum(json, 'protein_g'),
      fiberG: _optionalNum(json, 'fiber_g'),
      carbsG: _optionalNum(json, 'carbs_g'),
      fatG: _optionalNum(json, 'fat_g'),
      sugarG: _optionalNum(json, 'sugar_g'),
    );
  }

  static String _quality(Object? v) {
    final s = v is String ? v.toLowerCase() : '';
    if (s.contains('clean') || s.contains('healthy') || s.contains('light')) {
      return 'clean';
    }
    if (s.contains('dense') ||
        s.contains('heavy') ||
        s.contains('high') ||
        s.contains('junk') ||
        s.contains('fried')) {
      return 'dense';
    }
    return 'moderate';
  }
}

/// Reads a non-negative number, or null when the field is missing or junk.
/// Negative values are rejected rather than clamped — a negative macro means
/// the model misunderstood, and silently storing 0 would hide that.
double? _optionalNum(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! num) return null;
  final d = value.toDouble();
  if (d.isNaN || d.isInfinite || d < 0) return null;
  return d;
}

class BeverageItem {
  const BeverageItem({
    required this.name,
    required this.sugarContentG,
    required this.type,
  });

  final String name;
  final double sugarContentG;
  final String type; // water | caffeine | alcohol | protein

  factory BeverageItem.fromJson(Map<String, dynamic> json) {
    return BeverageItem(
      name: _string(json, 'name'),
      sugarContentG: _optionalNum(json, 'sugar_content_g') ?? 0,
      type: _bevType(json['type'], _string(json, 'name')),
    );
  }

  /// Coerce to one of the four buckets. Unknown drinks (juice, soda) map to
  /// `water` volume-wise — harmless for hydration and caffeine reminders —
  /// while their sugar still counts toward the day.
  static String _bevType(Object? v, String name) {
    final s = '${v is String ? v : ''} $name'.toLowerCase();
    if (RegExp(r'coffee|espresso|latte|tea|cola|soda|energy|matcha|caffeine')
        .hasMatch(s)) {
      return 'caffeine';
    }
    if (RegExp(r'beer|wine|liquor|cocktail|whiskey|vodka|alcohol')
        .hasMatch(s)) {
      return 'alcohol';
    }
    if (RegExp(r'protein|whey|shake').hasMatch(s)) return 'protein';
    return 'water';
  }
}

class ExerciseItem {
  const ExerciseItem({
    required this.activity,
    required this.durationMinutes,
    required this.intensity,
  });

  final String activity;
  final int durationMinutes;
  final String intensity; // low | moderate | vigorous

  factory ExerciseItem.fromJson(Map<String, dynamic> json) {
    return ExerciseItem(
      activity: _string(json, 'activity'),
      durationMinutes: (_optionalNum(json, 'duration_minutes') ?? 0).round(),
      intensity: _intensity(json['intensity']),
    );
  }

  static String _intensity(Object? v) {
    final s = v is String ? v.toLowerCase() : '';
    if (s.contains('low') || s.contains('light') || s.contains('easy')) {
      return 'low';
    }
    if (s.contains('vig') ||
        s.contains('high') ||
        s.contains('hard') ||
        s.contains('intense')) {
      return 'vigorous';
    }
    return 'moderate';
  }
}

class LogSummary {
  const LogSummary({
    required this.foodItems,
    required this.beverages,
    required this.hydrationAddedMl,
    required this.exerciseLogged,
  });

  final List<FoodItem> foodItems;
  final List<BeverageItem> beverages;
  final int hydrationAddedMl;
  final List<ExerciseItem> exerciseLogged;

  factory LogSummary.fromJson(Map<String, dynamic> json) {
    return LogSummary(
      foodItems: _list(json, 'food_items', FoodItem.fromJson),
      beverages: _list(json, 'beverages', BeverageItem.fromJson),
      hydrationAddedMl: (_optionalNum(json, 'hydration_added_ml') ?? 0).round(),
      exerciseLogged: _list(json, 'exercise_logged', ExerciseItem.fromJson),
    );
  }
}

class EnergyImpactAnalysis {
  const EnergyImpactAnalysis({
    required this.glycemicLoadEstimate,
    required this.postMealActionRequired,
    required this.recommendedWalkMinutes,
  });

  final String glycemicLoadEstimate; // flat | steady | high_spike
  final bool postMealActionRequired;
  final int recommendedWalkMinutes;

  factory EnergyImpactAnalysis.fromJson(Map<String, dynamic> json) {
    return EnergyImpactAnalysis(
      glycemicLoadEstimate: _load(json['glycemic_load_estimate']),
      postMealActionRequired: json['post_meal_action_required'] == true,
      recommendedWalkMinutes:
          (_optionalNum(json, 'recommended_walk_minutes') ?? 0).round(),
    );
  }

  static String _load(Object? v) {
    final s = v is String ? v.toLowerCase() : '';
    if (s.contains('flat')) return 'flat';
    if (s.contains('spike') || s.contains('high')) return 'high_spike';
    return 'steady';
  }
}

class CoachReply {
  const CoachReply({
    required this.logSummary,
    required this.energyImpact,
    required this.coachingMessage,
  });

  final LogSummary logSummary;
  final EnergyImpactAnalysis energyImpact;
  final String coachingMessage;

  factory CoachReply.fromJson(Map<String, dynamic> json) {
    final summary = json['log_summary'];
    if (summary is! Map<String, dynamic>) {
      throw const FormatException('missing log_summary');
    }
    final impact = json['energy_impact_analysis'];
    return CoachReply(
      logSummary: LogSummary.fromJson(summary),
      // The energy analysis is advisory — a missing or malformed block
      // shouldn't discard a valid food log. Default to a neutral read.
      energyImpact: impact is Map<String, dynamic>
          ? EnergyImpactAnalysis.fromJson(impact)
          : const EnergyImpactAnalysis(
              glycemicLoadEstimate: 'steady',
              postMealActionRequired: false,
              recommendedWalkMinutes: 0,
            ),
      coachingMessage:
          json['coaching_message'] is String ? json['coaching_message'] as String : '',
    );
  }

  bool get isEmpty =>
      logSummary.foodItems.isEmpty &&
      logSummary.beverages.isEmpty &&
      logSummary.hydrationAddedMl <= 0 &&
      logSummary.exerciseLogged.isEmpty;
}

/// Accepts raw model output: bare JSON, JSON inside ```fences```, or JSON
/// embedded in prose (first balanced top-level object).
CoachReply parseCoachReply(String raw) {
  final json = _extractJsonObject(raw);
  return CoachReply.fromJson(json);
}

Map<String, dynamic> _extractJsonObject(String raw) {
  final fence = RegExp(r'```(?:json)?\s*([\s\S]*?)```').firstMatch(raw);
  final candidates = <String>[
    if (fence != null) fence.group(1)!,
    raw,
  ];
  for (final candidate in candidates) {
    final start = candidate.indexOf('{');
    if (start < 0) continue;
    var depth = 0;
    var inString = false;
    for (var i = start; i < candidate.length; i++) {
      final c = candidate[i];
      if (inString) {
        if (c == r'\') {
          i++;
        } else if (c == '"') {
          inString = false;
        }
        continue;
      }
      if (c == '"') inString = true;
      if (c == '{') depth++;
      if (c == '}') {
        depth--;
        if (depth == 0) {
          final slice = candidate.substring(start, i + 1);
          final decoded = jsonDecode(slice);
          if (decoded is Map<String, dynamic>) return decoded;
          break;
        }
      }
    }
  }
  throw const FormatException('no JSON object found in model output');
}

String _string(Map<String, dynamic> json, String key) {
  final v = json[key];
  if (v is! String) throw FormatException('missing string $key');
  return v;
}

List<T> _list<T>(
  Map<String, dynamic> json,
  String key,
  T Function(Map<String, dynamic>) fromJson,
) {
  final v = json[key];
  if (v == null) return const [];
  if (v is! List) throw FormatException('$key is not a list');
  return [
    for (final item in v)
      if (item is Map<String, dynamic>) fromJson(item)
      else throw FormatException('$key contains a non-object'),
  ];
}
