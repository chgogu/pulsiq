/// Local nutrition resolver — the cheapest tier (OFFLINE_NUTRITION_PROMPT §1).
///
/// A curated per-100g food table (USDA-derived) plus a portion parser and a
/// greedy multi-food matcher. Resolves typed meals to macros at $0, offline,
/// and — because the numbers come from a table, not a model — without the
/// hallucination risk an LLM carries. Returns null when any item can't be
/// matched, so the caller escalates the *whole* meal rather than under-count.
library;

import 'dart:convert';

/// One food's per-100g macros and portion hints.
class FoodDbEntry {
  const FoodDbEntry({
    required this.name,
    required this.aliases,
    required this.kcal100,
    required this.protein100,
    required this.carbs100,
    required this.fat100,
    required this.fiber100,
    required this.units,
    required this.defaultGrams,
    required this.quality,
    this.pri = 0,
  });

  final String name;
  final List<String> aliases; // includes name; each may be multi-word
  final double kcal100;
  final double protein100;
  final double carbs100;
  final double fat100;
  final double fiber100;
  final Map<String, double> units; // portion word → grams, for this food
  final double defaultGrams; // one natural unit / serving
  final String quality; // clean | moderate | dense

  /// Match priority: 0 = curated (hand-tuned aliases/portions), 1 = bulk USDA.
  /// Curated wins ties so common foods resolve to their good defaults.
  final int pri;
}

/// The macros a local resolve produced. Pure — the caller maps it to whatever
/// app type it needs.
class FoodResolution {
  const FoodResolution({
    required this.caloriesKcal,
    required this.proteinG,
    required this.fiberG,
    required this.carbsG,
    required this.fatG,
    required this.quality,
    required this.itemCount,
  });

  final int caloriesKcal;
  final double proteinG;
  final double fiberG;
  final double carbsG;
  final double fatG;
  final String quality;
  final int itemCount;
}

const _fillerWords = {
  'a', 'an', 'the', 'of', 'some', 'with', 'and', 'plus', 'in', 'on', 'my',
  'topped', 'side', 'served', 'cooked', 'raw', 'fresh', 'grilled', 'roasted',
  'steamed', 'sauteed', 'sautéed', 'boiled', 'baked', 'fried', 'plain', 'hot',
  'iced', 'cold', 'warm', 'homemade', 'organic', 'lightly',
};

const _fractionWords = {
  'half': 0.5, 'quarter': 0.25, 'third': 0.33, 'a': 1.0, 'an': 1.0,
  'one': 1.0, 'two': 2.0, 'three': 3.0, 'four': 4.0, 'five': 5.0,
  'couple': 2.0, 'few': 3.0,
};

/// Genuine measure words only — never food names. (A food's own name can also
/// be a per-food unit key, e.g. "banana": 118; those must NOT count as units,
/// or "banana" alone would be consumed as a unit and match nothing.)
const _measureWords = {
  'cup', 'cups', 'tbsp', 'tablespoon', 'tablespoons', 'tsp', 'teaspoon',
  'teaspoons', 'slice', 'slices', 'piece', 'pieces', 'bowl', 'bowls', 'glass',
  'glasses', 'can', 'cans', 'bottle', 'bottles', 'handful', 'handfuls',
  'scoop', 'scoops', 'cob', 'pint', 'pints', 'mug', 'mugs', 'grande',
  'container', 'serving', 'servings', 'square', 'squares', 'shot', 'shots',
  'medium', 'large', 'small', 'whole',
};

class FoodDb {
  FoodDb._(this.foods, this.genericUnits) {
    for (final e in foods) {
      for (final alias in e.aliases) {
        _aliasIndex.add((entry: e, tokens: _tokenize(alias)));
      }
    }
    // Longest aliases first so "toor dal" wins over "dal", and multi-word
    // dishes win over their component words. Curated (pri 0) breaks ties so a
    // common food resolves to its hand-tuned entry, not a bulk USDA one.
    _aliasIndex.sort((a, b) {
      final byLen = b.tokens.length.compareTo(a.tokens.length);
      return byLen != 0 ? byLen : a.entry.pri.compareTo(b.entry.pri);
    });
    _unitWords = {...genericUnits.keys, ..._measureWords};
  }

  final List<FoodDbEntry> foods;
  final Map<String, double> genericUnits;
  final List<({FoodDbEntry entry, List<String> tokens})> _aliasIndex = [];
  late final Set<String> _unitWords;

  static FoodDb parse(String jsonStr) {
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    final generic = <String, double>{
      for (final e in (json['genericUnits'] as Map<String, dynamic>).entries)
        e.key: (e.value as num).toDouble(),
    };
    final foods = <FoodDbEntry>[];
    for (final f in json['foods'] as List) {
      final m = f as Map<String, dynamic>;
      final per = m['per100g'] as Map<String, dynamic>;
      final name = m['name'] as String;
      final aliases = <String>{
        name,
        ...((m['aliases'] as List?)?.cast<String>() ?? const []),
      }.toList();
      foods.add(FoodDbEntry(
        name: name,
        aliases: aliases,
        kcal100: (per['kcal'] as num).toDouble(),
        protein100: (per['protein'] as num).toDouble(),
        carbs100: (per['carbs'] as num).toDouble(),
        fat100: (per['fat'] as num).toDouble(),
        fiber100: (per['fiber'] as num).toDouble(),
        units: {
          for (final e in ((m['units'] as Map<String, dynamic>?) ?? {}).entries)
            e.key: (e.value as num).toDouble(),
        },
        defaultGrams: (m['defaultGrams'] as num).toDouble(),
        quality: m['quality'] as String? ?? 'moderate',
        pri: (m['pri'] as num?)?.toInt() ?? 0,
      ));
    }
    return FoodDb._(foods, generic);
  }

  /// Resolve a full meal description, or null if any part can't be matched.
  FoodResolution? resolve(String description) {
    final chunks = _splitItems(description);
    if (chunks.isEmpty) return null;

    var kcal = 0.0, protein = 0.0, carbs = 0.0, fat = 0.0, fiber = 0.0;
    var items = 0;
    const rank = {'clean': 0, 'moderate': 1, 'dense': 2};
    var worst = 'clean';

    for (final chunk in chunks) {
      final resolved = _resolveChunk(chunk);
      if (resolved == null) return null; // unknown → escalate whole meal
      for (final m in resolved) {
        final g = m.grams / 100.0;
        kcal += m.entry.kcal100 * g;
        protein += m.entry.protein100 * g;
        carbs += m.entry.carbs100 * g;
        fat += m.entry.fat100 * g;
        fiber += m.entry.fiber100 * g;
        items++;
        if ((rank[m.entry.quality] ?? 1) > (rank[worst] ?? 1)) {
          worst = m.entry.quality;
        }
      }
    }
    if (items == 0) return null;

    return FoodResolution(
      caloriesKcal: kcal.round(),
      proteinG: double.parse(protein.toStringAsFixed(1)),
      fiberG: double.parse(fiber.toStringAsFixed(1)),
      carbsG: double.parse(carbs.toStringAsFixed(1)),
      fatG: double.parse(fat.toStringAsFixed(1)),
      quality: worst,
      itemCount: items,
    );
  }

  /// Split a meal into items on explicit separators. Space-separated foods
  /// inside one chunk are handled later by greedy matching.
  List<String> _splitItems(String description) => description
      .toLowerCase()
      .replaceAll(RegExp(r'\btopped with\b'), ',')
      .replaceAll(RegExp(r'\b(with|and|plus)\b'), ',')
      .split(RegExp(r'[,;+&/]|\bwith\b'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  List<({FoodDbEntry entry, double grams})>? _resolveChunk(String chunk) {
    var tokens = _tokenize(chunk);
    if (tokens.isEmpty) return const [];

    // Portion: a leading quantity and optional unit apply to the first food.
    final (count, unit, rest) = _parsePortion(tokens);
    tokens = rest;

    // Greedily match foods, longest alias first, consuming tokens.
    final remaining = [...tokens];
    final matched = <FoodDbEntry>[];
    var changed = true;
    while (changed && remaining.isNotEmpty) {
      changed = false;
      for (final a in _aliasIndex) {
        if (_containsAll(remaining, a.tokens)) {
          matched.add(a.entry);
          _removeAll(remaining, a.tokens);
          changed = true;
          break;
        }
      }
    }

    // Anything left that isn't filler is an unknown food → escalate.
    if (remaining.any((t) => !_fillerWords.contains(t))) return null;
    if (matched.isEmpty) return null;

    return [
      for (var i = 0; i < matched.length; i++)
        (
          entry: matched[i],
          // The parsed portion applies to the first food; the rest default.
          grams: i == 0
              ? _grams(matched[i], count, unit)
              : matched[i].defaultGrams,
        ),
    ];
  }

  double _grams(FoodDbEntry entry, double count, String? unit) {
    if (unit != null) {
      final per = entry.units[unit] ?? genericUnits[unit] ?? entry.defaultGrams;
      return count * per;
    }
    return count * entry.defaultGrams;
  }

  /// (count, unit, remainingTokens). count defaults to 1.
  (double, String?, List<String>) _parsePortion(List<String> tokens) {
    var count = 1.0;
    var unit = <String?>[null][0];
    var i = 0;

    // Leading glued quantity+unit, e.g. "200ml".
    final glued = RegExp(r'^(\d+(?:\.\d+)?)([a-z]+)$').firstMatch(tokens[0]);
    if (glued != null && _unitWords.contains(glued.group(2))) {
      return (double.parse(glued.group(1)!), glued.group(2), tokens.sublist(1));
    }

    final first = tokens[0];
    final frac = RegExp(r'^(\d+)/(\d+)$').firstMatch(first);
    if (frac != null) {
      count = int.parse(frac.group(1)!) / int.parse(frac.group(2)!);
      i = 1;
    } else if (double.tryParse(first) != null) {
      count = double.parse(first);
      i = 1;
    } else if (_fractionWords.containsKey(first)) {
      count = _fractionWords[first]!;
      i = 1;
    }

    if (i < tokens.length && _unitWords.contains(tokens[i])) {
      unit = tokens[i];
      i++;
    }
    return (count, unit, tokens.sublist(i));
  }

  static List<String> _tokenize(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9/. ]'), ' ')
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty)
      .toList();

  /// Every token in [needle] is present in [haystack] (multiset-aware).
  static bool _containsAll(List<String> haystack, List<String> needle) {
    final pool = [...haystack];
    for (final t in needle) {
      if (!pool.remove(t)) return false;
    }
    return true;
  }

  static void _removeAll(List<String> haystack, List<String> needle) {
    for (final t in needle) {
      haystack.remove(t);
    }
  }
}
