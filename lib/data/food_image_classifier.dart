import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

import '../domain/food_db.dart';
import '../domain/meal_vision.dart';

/// On-device photo → food, the cheapest tier for Snap-a-meal. ML Kit's base
/// image labeler runs entirely on-device ($0, offline); when it confidently
/// names a food the local table knows (a banana, a slice of pizza), we skip the
/// cloud model entirely. Complex plates label only as generic "Food" and fall
/// through to Gemini — photos are the one place a frontier model still wins.
class FoodImageClassifier {
  const FoodImageClassifier({this.minConfidence = 0.72});

  final double minConfidence;

  /// Returns a single-item meal when a confident food label resolves in the
  /// table, else null (caller escalates to the cloud vision model).
  Future<MealVisionResult?> classify(String imagePath, FoodDb db) async {
    if (kIsWeb) return null;
    final labeler =
        ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: minConfidence));
    try {
      final labels =
          await labeler.processImage(InputImage.fromFilePath(imagePath))
            ..sort((a, b) => b.confidence.compareTo(a.confidence));
      for (final l in labels) {
        final res = db.resolve(l.label);
        if (res != null) {
          return MealVisionResult(
            items: [
              MealItem(
                name: l.label,
                portion: '1 serving',
                caloriesKcal: res.caloriesKcal,
                proteinG: res.proteinG,
                fiberG: res.fiberG,
                carbsG: res.carbsG,
                fatG: res.fatG,
                qualityScore: res.quality,
              ),
            ],
            confidence: 'medium',
            note: 'Identified on your device.',
          );
        }
      }
      return null;
    } catch (_) {
      return null;
    } finally {
      await labeler.close();
    }
  }
}

final foodImageClassifierProvider =
    Provider<FoodImageClassifier>((_) => const FoodImageClassifier());
