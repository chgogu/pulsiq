import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/llm_contract.dart';

/// Transport for one model behind the backend proxy. No API keys in the
/// app (§0) — the proxy injects the system prompt server-side and holds
/// the provider credentials.
abstract interface class LlmBackend {
  String get name;
  Future<String> complete(String userText);

  /// Menu OCR text → top-3 energy-optimized picks (Order Hack, §3).
  Future<String> analyzeMenu(String menuText);

  /// Meal photo (base64 JPEG/PNG) → per-item nutrition JSON. [hint] is an
  /// optional user label the proxy passes alongside the image, and the only
  /// signal the on-device mock has (it can't see pixels).
  Future<String> analyzeMealImage({required String base64Image, String hint});
}

class ProxyBackend implements LlmBackend {
  ProxyBackend({
    required this.baseUrl,
    required this.model,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final String model; // 'claude' (primary) or 'gemini-flash' (fallback)
  final http.Client _client;

  @override
  String get name => model;

  @override
  Future<String> complete(String userText) => _post('/v1/coach', userText);

  @override
  Future<String> analyzeMenu(String menuText) =>
      _post('/v1/order-hack', menuText);

  @override
  Future<String> analyzeMealImage({
    required String base64Image,
    String hint = '',
  }) async {
    // Proxy runs Gemini vision server-side; the app never holds the key
    // (spec §0). Generous timeout: the proxy retries transient transport
    // failures internally, and a cold Wi-Fi radio can add seconds on top.
    final res = await _client
        .post(
          Uri.parse('$baseUrl/v1/meal-vision'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'image': base64Image, 'hint': hint}),
        )
        .timeout(const Duration(seconds: 75));
    if (res.statusCode != 200) {
      throw http.ClientException('proxy ${res.statusCode}');
    }
    return (jsonDecode(res.body) as Map<String, dynamic>)['reply'] as String;
  }

  Future<String> _post(String path, String text) async {
    final res = await _client
        .post(
          Uri.parse('$baseUrl$path'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'model': model, 'text': text}),
        )
        .timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) {
      throw http.ClientException('proxy ${res.statusCode}');
    }
    return (jsonDecode(res.body) as Map<String, dynamic>)['reply'] as String;
  }
}

/// Deterministic on-device stand-in used until the proxy is deployed (and
/// in tests). Produces contract-valid JSON from transcript keywords so the
/// entire pipeline — parse → validate → insert → rings — runs for real.
class MockLlmBackend implements LlmBackend {
  const MockLlmBackend();

  @override
  String get name => 'on-device-mock';

  static final _numberWord = {
    'a': 1, 'an': 1, 'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5,
  };

  @override
  Future<String> complete(String userText) async {
    final text = userText.toLowerCase();
    final beverages = <Map<String, dynamic>>[];
    final foods = <Map<String, dynamic>>[];
    final exercise = <Map<String, dynamic>>[];
    var hydration = 0;

    final mlMatch = RegExp(r'(\d+)\s*ml\b').firstMatch(text);
    final ozMatch = RegExp(r'(\d+)\s*(?:oz|ounce)').firstMatch(text);
    final glassMatch =
        RegExp(r'(\w+)?\s*glass(?:es)? of water').firstMatch(text);
    if (text.contains('water')) {
      if (mlMatch != null) {
        hydration = int.parse(mlMatch.group(1)!);
      } else if (ozMatch != null) {
        hydration = (int.parse(ozMatch.group(1)!) * 29.5735).round();
      } else if (glassMatch != null) {
        hydration = 250 * (_numberWord[glassMatch.group(1)] ?? 1);
      } else {
        hydration = 250;
      }
    }

    if (RegExp(r'coffee|latte|espresso|cappuccino|cold brew').hasMatch(text)) {
      final sweet = text.contains('caramel') ||
          text.contains('mocha') ||
          text.contains('syrup');
      beverages.add({
        'name': 'Coffee',
        'sugar_content_g': sweet ? 24 : 4,
        'type': 'caffeine',
      });
    }
    if (RegExp(r'\bbeer|wine|cocktail\b').hasMatch(text)) {
      beverages.add(
          {'name': 'Drink', 'sugar_content_g': 6, 'type': 'alcohol'});
    }
    if (RegExp(r'protein shake|protein drink').hasMatch(text)) {
      beverages.add(
          {'name': 'Protein shake', 'sugar_content_g': 3, 'type': 'protein'});
    }

    final dense = RegExp(
        r'pasta|pizza|burger|fries|donut|dessert|cake|rice bowl|burrito');
    final clean = RegExp(r'salad|eggs|chicken|fish|yogurt|oats|vegetables');
    final foodMention = RegExp(
            r'\b(ate|had|eating|lunch|dinner|breakfast|snack(?:ed)?)\b')
        .hasMatch(text);
    if (foodMention || dense.hasMatch(text) || clean.hasMatch(text)) {
      final denseHit = dense.firstMatch(text);
      final cleanHit = clean.firstMatch(text);
      if (denseHit != null) {
        foods.add({
          'name': denseHit.group(0)!,
          'quantity': '1 serving',
          'quality_score': 'dense',
        });
      }
      if (cleanHit != null) {
        foods.add({
          'name': cleanHit.group(0)!,
          'quantity': '1 serving',
          'quality_score': 'clean',
        });
      }
      if (denseHit == null && cleanHit == null) {
        foods.add({
          'name': 'Meal',
          'quantity': '',
          'quality_score': 'moderate',
        });
      }
    }

    // Attach macros from the same keyword table the photo mock uses, so an
    // offline voice log still feeds the day's fuel totals instead of landing
    // as a nameless row worth zero calories.
    for (final food in foods) {
      final est = _estimateMeal(food['name'] as String).first;
      for (final key in const [
        'calories',
        'protein_g',
        'fiber_g',
        'carbs_g',
        'fat_g',
      ]) {
        food[key] = est[key];
      }
    }

    final minutes =
        RegExp(r'(\d+)\s*(?:min|minute)').firstMatch(text)?.group(1);
    final move =
        RegExp(r'\b(walk(?:ed)?|run|ran|gym|workout|yoga|cycled?|swam|swim)\b')
            .firstMatch(text);
    if (move != null) {
      final vigorous = RegExp(r'run|ran|gym|workout|swim|swam').hasMatch(text);
      exercise.add({
        'activity': move.group(0)!,
        'duration_minutes': int.tryParse(minutes ?? '') ?? 20,
        'intensity': vigorous ? 'vigorous' : 'moderate',
      });
    }

    final spike = foods.any((f) => f['quality_score'] == 'dense');
    final reply = {
      'log_summary': {
        'food_items': foods,
        'beverages': beverages,
        'hydration_added_ml': hydration,
        'exercise_logged': exercise,
      },
      'energy_impact_analysis': {
        'glycemic_load_estimate': spike
            ? 'high_spike'
            : (foods.isNotEmpty || beverages.isNotEmpty ? 'steady' : 'flat'),
        'post_meal_action_required': spike,
        'recommended_walk_minutes': spike ? 12 : 0,
      },
      'coaching_message': spike
          ? "Logged! That one's carb-dense — a 12-minute walk keeps the "
              'energy curve steady instead of spiky.'
          : 'Logged! Clean fuel keeps the afternoon steady — nice.',
    };
    return jsonEncode(reply);
  }

  @override
  Future<String> analyzeMenu(String menuText) async {
    // Rank menu lines: clean/lean keywords steady, fried/sweet spike.
    final lines = menuText
        .split(RegExp(r'[\n,;]'))
        .map((l) => l.trim())
        .where((l) => l.length > 2)
        .toList();
    final spike = RegExp(
        r'fried|crispy|breaded|pasta|fries|burger|pizza|syrup|sweet|'
        r'candied|glazed|soda|shake|donut|cake|sugary',
        caseSensitive: false);
    final steady = RegExp(
        r'grilled|salad|greens|salmon|chicken|eggs|avocado|quinoa|beans|'
        r'veg|bowl|steamed|roasted|tofu|lentil|fish',
        caseSensitive: false);

    ({String name, String why, String rating}) score(String line) {
      final s = spike.hasMatch(line);
      final c = steady.hasMatch(line);
      if (c && !s) {
        return (
          name: line,
          why: 'Lean protein and fiber here mean long, steady energy — no '
              'afternoon crash.',
          rating: 'steady',
        );
      }
      if (c && s) {
        return (
          name: line,
          why: 'Solid base — ask for it grilled, not fried, to keep the '
              'energy flat.',
          rating: 'moderate',
        );
      }
      return (
        name: line,
        why: 'Tasty but carb-dense — pair it with water and a short walk '
            'after.',
        rating: 'spike',
      );
    }

    final ranked = lines.map(score).toList()
      ..sort((a, b) {
        int rank(String r) =>
            r == 'steady' ? 0 : (r == 'moderate' ? 1 : 2);
        return rank(a.rating).compareTo(rank(b.rating));
      });
    final top = ranked.take(3).toList();
    if (top.isEmpty) {
      top.add((
        name: 'Grilled protein + greens',
        why: 'When in doubt, lean protein and vegetables keep your energy '
            'steady.',
        rating: 'steady',
      ));
    }
    return jsonEncode({
      'headline': 'Top picks for long, steady energy',
      'top_picks': [
        for (final p in top)
          {'name': p.name, 'why': p.why, 'energy_rating': p.rating},
      ],
    });
  }

  @override
  Future<String> analyzeMealImage({
    required String base64Image,
    String hint = '',
  }) async {
    // The mock can't see the photo — it estimates from the user's text hint
    // (or a mixed-plate default), producing contract-valid nutrition so the
    // whole analytics pipeline runs offline / in the web preview / in tests.
    final label = hint.trim().isEmpty ? 'mixed plate' : hint.trim();
    final items = _estimateMeal(label);
    return jsonEncode({
      'confidence': hint.trim().isEmpty ? 'low' : 'medium',
      'items': items,
      'note': items.any((i) => i['quality_score'] == 'dense')
          ? 'Carb-dense plate — a short walk after keeps the energy steady.'
          : 'Balanced fuel — nice, steady energy from this one.',
    });
  }

  static List<Map<String, dynamic>> _estimateMeal(String label) {
    final text = label.toLowerCase();
    // A small keyword → per-serving macro table; anything unmatched falls
    // back to a generic balanced plate.
    const table = <String, (int, double, double, double, double, String)>{
      // name: (kcal, protein, fiber, carbs, fat, quality)
      'salad': (220, 8, 7, 18, 12, 'clean'),
      'chicken': (280, 35, 1, 4, 12, 'clean'),
      'salmon': (360, 34, 0, 0, 22, 'clean'),
      'eggs': (180, 13, 0, 2, 13, 'clean'),
      'oats': (300, 10, 8, 54, 6, 'clean'),
      'yogurt': (150, 15, 0, 12, 4, 'clean'),
      'burrito': (640, 26, 12, 78, 24, 'dense'),
      'bowl': (520, 24, 10, 62, 18, 'moderate'),
      'burger': (720, 34, 4, 46, 42, 'dense'),
      'pizza': (680, 28, 6, 76, 28, 'dense'),
      'pasta': (600, 20, 6, 88, 18, 'dense'),
      'fries': (380, 5, 5, 48, 19, 'dense'),
      'rice': (340, 7, 2, 72, 3, 'moderate'),
      'sandwich': (450, 22, 5, 44, 20, 'moderate'),
      'avocado': (240, 3, 10, 12, 22, 'clean'),
      'smoothie': (280, 12, 6, 48, 5, 'moderate'),
      'toast': (200, 7, 4, 32, 5, 'moderate'),
    };
    final matched = <Map<String, dynamic>>[];
    table.forEach((keyword, m) {
      if (text.contains(keyword)) {
        matched.add({
          'name': keyword[0].toUpperCase() + keyword.substring(1),
          'portion': '1 serving',
          'calories': m.$1,
          'protein_g': m.$2,
          'fiber_g': m.$3,
          'carbs_g': m.$4,
          'fat_g': m.$5,
          'quality_score': m.$6,
        });
      }
    });
    if (matched.isEmpty) {
      matched.add({
        'name': label.isEmpty ? 'Mixed plate' : label,
        'portion': '1 plate',
        'calories': 520,
        'protein_g': 24.0,
        'fiber_g': 8.0,
        'carbs_g': 55.0,
        'fat_g': 20.0,
        'quality_score': 'moderate',
      });
    }
    return matched;
  }
}

class CoachOutcome {
  const CoachOutcome({this.reply, required this.backendUsed, this.rawText});

  /// Parsed structured reply; null means both backends failed and the
  /// transcript should be logged as raw text (spec §1 last resort).
  final CoachReply? reply;
  final String backendUsed;
  final String? rawText;
}

/// Fallback chain (spec §0/§1): primary Claude → retry once with a
/// fix-the-JSON instruction → Gemini Flash fallback → raw-text logging.
class LlmCoach {
  LlmCoach({required this.primary, required this.fallback});

  final LlmBackend primary;
  final LlmBackend fallback;

  static const _fixInstruction =
      '\n\nYour previous reply was not valid JSON matching the contract. '
      'Reply again with ONLY the valid JSON object.';

  Future<CoachOutcome> process(String transcript) async {
    for (final backend in [primary, fallback]) {
      try {
        final first = await backend.complete(transcript);
        try {
          return CoachOutcome(
              reply: parseCoachReply(first), backendUsed: backend.name);
        } on FormatException {
          final retry =
              await backend.complete('$transcript$_fixInstruction');
          return CoachOutcome(
              reply: parseCoachReply(retry), backendUsed: backend.name);
        }
      } catch (_) {
        continue; // transport or double parse failure → next backend
      }
    }
    return CoachOutcome(
        reply: null, backendUsed: 'none', rawText: transcript);
  }

  /// Order Hack: primary → fallback, returning raw JSON for the caller to
  /// parse, or null when both backends fail.
  Future<String?> orderHack(String menuText) async {
    for (final backend in [primary, fallback]) {
      try {
        return await backend.analyzeMenu(menuText);
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  /// Meal photo → nutrition JSON, primary → fallback; null when both fail.
  Future<String?> analyzeMeal({
    required String base64Image,
    String hint = '',
  }) async {
    for (final backend in [primary, fallback]) {
      try {
        return await backend.analyzeMealImage(
            base64Image: base64Image, hint: hint);
      } catch (_) {
        continue;
      }
    }
    return null;
  }
}
