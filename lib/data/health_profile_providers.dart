import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/health_goal.dart';
import 'providers.dart';

/// The user's saved health goals + conditions note. Drives the "can I eat
/// this?" verdict on snapped meals and scanned products.
final healthProfileProvider = FutureProvider<HealthProfile>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final goals = await db.getSetting(HealthProfile.goalsKey);
  final note = await db.getSetting(HealthProfile.noteKey);
  final values = {HealthProfile.goalsKey: goals, HealthProfile.noteKey: note};
  return HealthProfile.fromSettings((k) => values[k]);
});

/// Persist the profile and refresh readers.
final saveHealthProfileProvider =
    Provider<Future<void> Function(HealthProfile)>((ref) {
  return (profile) async {
    final db = ref.read(appDatabaseProvider);
    for (final e in profile.toSettings().entries) {
      await db.setSetting(e.key, e.value);
    }
    ref.invalidate(healthProfileProvider);
  };
});
