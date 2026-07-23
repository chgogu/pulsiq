import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

/// Whether meal analysis may escalate to the cloud model (Gemini) for things
/// the on-device path can't resolve.
///
/// Default **off**: nutrition is a lookup, not a reasoning problem. Identifying
/// a food and summing its intake is what the bundled USDA table and the
/// on-device parser already do — at $0, offline, with no hallucinated numbers.
/// Gemini is a convenience for messy multi-item plates, not a dependency, so
/// it stays opt-in. Off also means no metered API quota to exhaust and nothing
/// leaves the device for a meal log.
const aiAssistSettingKey = 'ai_assist_enabled';

final aiAssistEnabledProvider = FutureProvider<bool>((ref) async {
  final v = await ref.watch(appDatabaseProvider).getSetting(aiAssistSettingKey);
  return v == 'true'; // absent → false → offline only
});

/// Synchronous gate for code paths that can't await a provider (the meal
/// estimator reads it before deciding whether to make a network call). Reads
/// the same setting directly.
Future<bool> aiAssistEnabled(Ref ref) async {
  final v = await ref.read(appDatabaseProvider).getSetting(aiAssistSettingKey);
  return v == 'true';
}
