/// Photo → nutrition contract (NUTRITION_VISION_PROMPT §2). The backend
/// proxy runs the latest Claude vision model (Opus 4.8) and returns this
/// JSON; the app re-validates client-side so malformed macros never reach
/// the DB.
library;

import 'dart:convert';

class MealItem {
  const MealItem({
    required this.name,
    required this.portion,
    required this.caloriesKcal,
    required this.proteinG,
    required this.fiberG,
    required this.carbsG,
    required this.fatG,
    required this.qualityScore,
  });

  final String name;
  final String portion;
  final int caloriesKcal;
  final double proteinG;
  final double fiberG;
  final double carbsG;
  final double fatG;
  final String qualityScore; // clean | moderate | dense

  static const _qualities = {'clean', 'moderate', 'dense'};

  factory MealItem.fromJson(Map<String, dynamic> json) {
    final quality = json['quality_score'];
    if (quality is! String || !_qualities.contains(quality)) {
      throw FormatException('bad quality_score: $quality');
    }
    final name = json['name'];
    if (name is! String || name.trim().isEmpty) {
      throw const FormatException('item missing name');
    }
    return MealItem(
      name: name,
      portion: json['portion'] is String ? json['portion'] as String : '',
      caloriesKcal: _num(json, 'calories').round(),
      proteinG: _num(json, 'protein_g'),
      fiberG: _num(json, 'fiber_g'),
      carbsG: _num(json, 'carbs_g'),
      fatG: _num(json, 'fat_g'),
      qualityScore: quality,
    );
  }

  MealItem copyWith({
    String? name,
    int? caloriesKcal,
    double? proteinG,
    double? fiberG,
    double? carbsG,
    double? fatG,
    String? qualityScore,
  }) =>
      MealItem(
        name: name ?? this.name,
        portion: portion,
        caloriesKcal: caloriesKcal ?? this.caloriesKcal,
        proteinG: proteinG ?? this.proteinG,
        fiberG: fiberG ?? this.fiberG,
        carbsG: carbsG ?? this.carbsG,
        fatG: fatG ?? this.fatG,
        qualityScore: qualityScore ?? this.qualityScore,
      );
}

class MealVisionResult {
  const MealVisionResult({
    required this.items,
    required this.confidence,
    required this.note,
  });

  final List<MealItem> items;
  final String confidence; // high | medium | low
  final String note;

  int get totalCalories =>
      items.fold(0, (sum, i) => sum + i.caloriesKcal);
  double get totalProtein => items.fold(0.0, (sum, i) => sum + i.proteinG);
  double get totalFiber => items.fold(0.0, (sum, i) => sum + i.fiberG);
  double get totalCarbs => items.fold(0.0, (sum, i) => sum + i.carbsG);
  double get totalFat => items.fold(0.0, (sum, i) => sum + i.fatG);

  /// A single quality label for a multi-item plate: the least-clean item
  /// sets the tone, since one dense component defines how the meal eats.
  String get overallQuality {
    const rank = {'clean': 0, 'moderate': 1, 'dense': 2};
    return items
        .map((i) => i.qualityScore)
        .reduce((a, b) => (rank[a] ?? 1) >= (rank[b] ?? 1) ? a : b);
  }

  bool get lowConfidence => confidence == 'low';
}

MealVisionResult parseMealVision(String raw) {
  final json = _extractJson(raw);
  final itemsRaw = json['items'];
  if (itemsRaw is! List) throw const FormatException('missing items list');
  final items = [
    for (final i in itemsRaw)
      if (i is Map<String, dynamic>) MealItem.fromJson(i),
  ];
  if (items.isEmpty) throw const FormatException('no items in meal');
  final confidence = json['confidence'];
  return MealVisionResult(
    items: items,
    confidence: confidence is String &&
            {'high', 'medium', 'low'}.contains(confidence)
        ? confidence
        : 'medium',
    note: json['note'] is String ? json['note'] as String : '',
  );
}

double _num(Map<String, dynamic> json, String key) {
  final v = json[key];
  if (v is! num) throw FormatException('missing number $key');
  if (v < 0) throw FormatException('$key is negative');
  return v.toDouble();
}

Map<String, dynamic> _extractJson(String raw) {
  final fence = RegExp(r'```(?:json)?\s*([\s\S]*?)```').firstMatch(raw);
  for (final candidate in [if (fence != null) fence.group(1)!, raw]) {
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
      if (c == '}' && --depth == 0) {
        final decoded = jsonDecode(candidate.substring(start, i + 1));
        if (decoded is Map<String, dynamic>) return decoded;
        break;
      }
    }
  }
  throw const FormatException('no JSON object in meal-vision output');
}
