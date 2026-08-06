import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Apple's on-device foundation model (iOS 26+), via a platform channel. Free,
/// private, offline — it estimates nutrition and parses voice logs for any
/// food, including ones no bundled table would know. Reports unavailable
/// everywhere else, so the app falls back to its Dart parser (and the cloud
/// model, if the user has opted into it).
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

  /// A meal description → per-item nutrition JSON, the same MEAL_SCHEMA shape a
  /// cloud estimate uses (so [parseMealVision] reads it unchanged). Null when
  /// the model is unavailable or errors.
  Future<String?> estimateMeal(String description) async {
    if (kIsWeb || !Platform.isIOS) return null;
    try {
      // Bound the wait: the on-device model can take a few seconds and, if the
      // system is busy or the model is still loading, could otherwise hang the
      // "Estimate" button indefinitely. On timeout we fall through to manual
      // entry rather than spin forever.
      return await _channel
          .invokeMethod<String>('estimateMeal', description)
          .timeout(const Duration(seconds: 12), onTimeout: () => null);
    } catch (_) {
      return null;
    }
  }

  /// A spoken health log → the COACH_SCHEMA JSON [parseCoachReply] expects:
  /// foods (with macros), beverages, hydration, exercise, and a coaching line.
  /// Null when unavailable or on error.
  Future<String?> parseVoiceLog(String transcript) async {
    if (kIsWeb || !Platform.isIOS) return null;
    try {
      return await _channel
          .invokeMethod<String>('parseVoiceLog', transcript)
          .timeout(const Duration(seconds: 12), onTimeout: () => null);
    } catch (_) {
      return null;
    }
  }
}

final foundationModelProvider =
    Provider<FoundationModel>((_) => const FoundationModel());
