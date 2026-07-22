import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../domain/food_db.dart';

/// A packaged product resolved from a barcode.
class ScannedFood {
  const ScannedFood({required this.name, required this.macros, this.brand});

  final String name;
  final String? brand;
  final FoodResolution macros;

  String get label {
    final b = brand?.trim();
    if (b == null || b.isEmpty) return name;
    // Avoid "Nutella Nutella" when the brand already leads the name.
    if (name.toLowerCase().contains(b.toLowerCase())) return name;
    return '$b $name';
  }
}

/// Open Food Facts lookup — a free, key-less public database of packaged foods.
/// Barcode → macros at $0 (just a network call; no proxy, no LLM).
class OpenFoodFacts {
  OpenFoodFacts({
    http.Client? client,
    this.baseUrl = 'https://world.openfoodfacts.org',
  }) : _http = client ?? http.Client();

  final http.Client _http;
  final String baseUrl;

  Future<ScannedFood?> lookup(String barcode) async {
    final code = barcode.trim();
    if (code.isEmpty) return null;
    try {
      final res = await _http.get(
        Uri.parse('$baseUrl/api/v2/product/$code.json'
            '?fields=product_name,brands,nutriments,serving_quantity'),
        // OFF asks apps to identify themselves.
        headers: {'user-agent': 'PulsIQ/1.0 (personal health app)'},
      ).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return null;
      return parseOffProduct(
          jsonDecode(res.body) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}

/// Pure parser for an Open Food Facts product response. Prefers per-serving
/// nutriments, falling back to per-100g scaled by the serving size (or a flat
/// 100 g). Null when the product carries no usable energy value.
ScannedFood? parseOffProduct(Map<String, dynamic> json) {
  if (json['status'] == 0) return null;
  final product = json['product'];
  if (product is! Map<String, dynamic>) return null;
  final n = product['nutriments'];
  if (n is! Map<String, dynamic>) return null;

  double? num_(String k) => (n[k] as num?)?.toDouble();

  double kcal, protein, carbs, fat, fiber;
  if (num_('energy-kcal_serving') != null) {
    kcal = num_('energy-kcal_serving')!;
    protein = num_('proteins_serving') ?? 0;
    carbs = num_('carbohydrates_serving') ?? 0;
    fat = num_('fat_serving') ?? 0;
    fiber = num_('fiber_serving') ?? 0;
  } else {
    // Per-100g scaled to the stated serving grams, or one 100 g portion.
    final servingG = (product['serving_quantity'] as num?)?.toDouble();
    final f = (servingG != null && servingG > 0) ? servingG / 100.0 : 1.0;
    kcal = (num_('energy-kcal_100g') ?? 0) * f;
    protein = (num_('proteins_100g') ?? 0) * f;
    carbs = (num_('carbohydrates_100g') ?? 0) * f;
    fat = (num_('fat_100g') ?? 0) * f;
    fiber = (num_('fiber_100g') ?? 0) * f;
  }

  if (kcal <= 0 && protein <= 0 && carbs <= 0 && fat <= 0) return null;

  // Quality heuristic from macro density: mostly-fat/sugar reads dense.
  final fatShare = kcal > 0 ? fat * 9 / kcal : 0;
  final quality = fatShare > 0.42 ? 'dense' : (fatShare > 0.30 ? 'moderate' : 'clean');

  final name = (product['product_name'] as String?)?.trim();
  final brand = (product['brands'] as String?)?.split(',').first.trim();
  return ScannedFood(
    name: name == null || name.isEmpty ? 'Scanned item' : name,
    brand: brand,
    macros: FoodResolution(
      caloriesKcal: kcal.round(),
      proteinG: double.parse(protein.toStringAsFixed(1)),
      fiberG: double.parse(fiber.toStringAsFixed(1)),
      carbsG: double.parse(carbs.toStringAsFixed(1)),
      fatG: double.parse(fat.toStringAsFixed(1)),
      quality: quality,
      itemCount: 1,
    ),
  );
}

final openFoodFactsProvider = Provider<OpenFoodFacts>((_) => OpenFoodFacts());
