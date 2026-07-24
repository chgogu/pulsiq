import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../billing/subscription_service.dart';

/// Whether meal analysis may use the cloud model (Gemini) for things the
/// on-device path can't resolve well.
///
/// This is now the **PulsIQ Plus** entitlement. Free users get the on-device
/// model (Apple Intelligence, iOS 26+) and the bundled food table — fully
/// functional, $0, private. Plus ($2/mo) adds cloud Gemini for sharper
/// estimates and photo snap-a-meal, whose small per-call cost the subscription
/// funds. The cloud path is otherwise identical, so nothing downstream changes.
final aiAssistEnabledProvider = Provider<bool>((ref) {
  return ref.watch(isPlusProvider);
});

/// Synchronous gate for code paths that can't watch a provider (the meal
/// estimator reads it before deciding whether to make a network call).
bool aiAssistEnabled(Ref ref) => ref.read(isPlusProvider);
