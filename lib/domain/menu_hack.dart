/// Order Hack contract (spec §3): menu text → top-3 energy-optimized picks,
/// each with a one-line "why". Separate from the log contract; validated
/// client-side the same way.
library;

import 'dart:convert';

class MenuPick {
  const MenuPick({
    required this.name,
    required this.why,
    required this.energyRating,
  });

  final String name;
  final String why;

  /// "steady" | "moderate" | "spike" — mirrors glycemic_load language,
  /// used to color the card without any clinical framing.
  final String energyRating;

  static const _ratings = {'steady', 'moderate', 'spike'};

  factory MenuPick.fromJson(Map<String, dynamic> json) {
    final rating = json['energy_rating'];
    if (rating is! String || !_ratings.contains(rating)) {
      throw FormatException('bad energy_rating: $rating');
    }
    final name = json['name'];
    final why = json['why'];
    if (name is! String || why is! String) {
      throw const FormatException('pick missing name/why');
    }
    return MenuPick(name: name, why: why, energyRating: rating);
  }
}

class OrderHackResult {
  const OrderHackResult({required this.picks, required this.headline});

  final List<MenuPick> picks;
  final String headline;
}

OrderHackResult parseOrderHack(String raw) {
  final json = _extractJson(raw);
  final picksRaw = json['top_picks'];
  if (picksRaw is! List) {
    throw const FormatException('missing top_picks list');
  }
  final picks = [
    for (final p in picksRaw)
      if (p is Map<String, dynamic>) MenuPick.fromJson(p),
  ];
  if (picks.isEmpty) throw const FormatException('no picks');
  final headline = json['headline'];
  return OrderHackResult(
    picks: picks.take(3).toList(),
    headline: headline is String ? headline : 'Your top picks for steady energy',
  );
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
  throw const FormatException('no JSON object in menu output');
}
