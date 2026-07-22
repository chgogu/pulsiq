import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Apple's on-device foundation model (iOS 26+), via a platform channel. Free,
/// private, offline — used to parse messy meal text into clean items the local
/// USDA table can resolve, before ever reaching the cloud model. Reports
/// unavailable everywhere else, so the cascade simply skips this tier.
class FoundationModel {
  const FoundationModel();

  static const _channel = MethodChannel('pulsiq/foundation_model');

  Future<bool> available() async {
    if (kIsWeb || !Platform.isIOS) return false;
    try {
      return await _channel.invokeMethod<bool>('available') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Parse a description into a comma-joined "quantity food" list the food DB
  /// can resolve. Null when unavailable or nothing usable comes back.
  Future<String?> parseToItems(String description) async {
    if (kIsWeb || !Platform.isIOS) return null;
    try {
      final raw = await _channel.invokeMethod<String>('parseMeal', description);
      return raw == null ? null : itemsFromModelJson(raw);
    } catch (_) {
      return null;
    }
  }
}

/// Pure: pull `{"items":[{"name","quantity"}]}` out of the model's reply and
/// flatten it to "quantity name, quantity name". Tolerates prose around the
/// JSON. Null when there's nothing usable.
String? itemsFromModelJson(String raw) {
  final start = raw.indexOf('{');
  final end = raw.lastIndexOf('}');
  if (start < 0 || end <= start) return null;
  try {
    final json = jsonDecode(raw.substring(start, end + 1)) as Map<String, dynamic>;
    final items = json['items'];
    if (items is! List) return null;
    final parts = <String>[];
    for (final it in items) {
      if (it is! Map) continue;
      final name = (it['name'] as String?)?.trim() ?? '';
      if (name.isEmpty) continue;
      final qty = (it['quantity'] as String?)?.trim() ?? '';
      // "1 serving" / "a serving" add no portion signal — let the DB default.
      final q = (qty.isEmpty || qty.toLowerCase().contains('serving')) ? '' : qty;
      parts.add(q.isEmpty ? name : '$q $name');
    }
    return parts.isEmpty ? null : parts.join(', ');
  } catch (_) {
    return null;
  }
}

final foundationModelProvider =
    Provider<FoundationModel>((_) => const FoundationModel());
