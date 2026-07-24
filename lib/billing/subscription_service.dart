import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../data/db/app_database.dart';
import '../data/providers.dart';

/// The one auto-renewable subscription. This id must match the product created
/// in App Store Connect (Subscription Group → PulsIQ Plus).
const kPlusProductId = 'com.pulsiq.pulsiq.plus.monthly';

/// Cached entitlement, so the app knows the user is Plus at launch before the
/// (async) StoreKit query returns. StoreKit remains the source of truth; this
/// only avoids a flash of the free state.
const _plusCacheKey = 'plus_active';

/// Owns the StoreKit subscription lifecycle: product query, purchase, restore,
/// and the running entitlement state.
///
/// Verification is StoreKit's own (the platform validates the receipt before a
/// purchase reaches the stream). That's acceptable for a v1 whose only "unlock"
/// is cheaper cloud inference; server-side receipt validation is the hardening
/// step once it's worth the complexity (see billing/README.md).
class SubscriptionService {
  SubscriptionService(this._db, {InAppPurchase? iap}) : _iapOverride = iap;

  final AppDatabase _db;

  // Resolved lazily: `InAppPurchase.instance` registers platform plugins on
  // first access, which needs the Flutter binding — constructing the service
  // (in a test, or just to read the cached entitlement) must not trigger that.
  final InAppPurchase? _iapOverride;
  InAppPurchase? _iapCached;
  InAppPurchase get _iap => _iapCached ??= (_iapOverride ?? InAppPurchase.instance);

  final _isPlus = ValueNotifier<bool>(false);
  ValueListenable<bool> get isPlus => _isPlus;

  ProductDetails? _product;
  ProductDetails? get product => _product;

  /// Human-readable price from the store (localized, correct currency), or a
  /// sensible default before the query returns.
  String get priceLabel => _product?.price ?? '\$2/mo';

  StreamSubscription<List<PurchaseDetails>>? _sub;

  bool _initialized = false;

  /// Best-effort — never throws. StoreKit being unreachable (simulator without
  /// a signed-in sandbox account, the test binding, a transient failure) must
  /// not take the app down; the user simply stays on the last-known
  /// entitlement, which for a fresh install is free.
  Future<void> init() async {
    if (kIsWeb || _initialized) return;
    _initialized = true;
    try {
      // Seed from cache so a returning subscriber isn't shown the paywall while
      // StoreKit is still answering.
      _isPlus.value = (await _db.getSetting(_plusCacheKey)) == 'true';

      if (!await _iap.isAvailable()) return;
      _sub = _iap.purchaseStream.listen(
        _onPurchases,
        onError: (_) {/* transient; entitlement stays as last known */},
      );

      final resp = await _iap.queryProductDetails({kPlusProductId});
      if (resp.productDetails.isNotEmpty) {
        _product = resp.productDetails.first;
      }
      // Replay owned purchases so a reinstall restores Plus.
      await _iap.restorePurchases();
    } catch (_) {
      // No store here — free tier, no crash.
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    var active = _isPlus.value;
    for (final p in purchases) {
      if (p.productID != kPlusProductId) continue;
      switch (p.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          active = true;
        case PurchaseStatus.error:
        case PurchaseStatus.canceled:
          // A failed/cancelled attempt doesn't revoke an existing entitlement.
          break;
        case PurchaseStatus.pending:
          break;
      }
      if (p.pendingCompletePurchase) {
        await _iap.completePurchase(p);
      }
    }
    await _setPlus(active);
  }

  Future<void> _setPlus(bool value) async {
    _isPlus.value = value;
    await _db.setSetting(_plusCacheKey, value ? 'true' : 'false');
  }

  /// Flip the entitlement without a real purchase — tests and previews only.
  @visibleForTesting
  void debugSetEntitled(bool value) => _isPlus.value = value;

  /// Starts the purchase sheet. The result arrives on [isPlus] via the stream.
  /// Returns false when the store isn't ready or the product didn't load.
  Future<bool> buy() async {
    final product = _product;
    if (product == null) return false;
    return _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
  }

  /// Re-applies a subscription bought on another device or before a reinstall.
  Future<void> restore() => _iap.restorePurchases();

  void dispose() {
    _sub?.cancel();
    _isPlus.dispose();
  }
}

final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  final service = SubscriptionService(ref.watch(appDatabaseProvider));
  ref.onDispose(service.dispose);
  return service;
});

/// Whether the user currently has PulsIQ Plus. This is the single entitlement
/// gate: cloud AI (Gemini) is on for Plus, on-device only for free.
final isPlusProvider = NotifierProvider<PlusEntitlement, bool>(
  PlusEntitlement.new,
);

class PlusEntitlement extends Notifier<bool> {
  @override
  bool build() {
    final service = ref.watch(subscriptionServiceProvider);
    void listener() => state = service.isPlus.value;
    service.isPlus.addListener(listener);
    ref.onDispose(() => service.isPlus.removeListener(listener));
    return service.isPlus.value;
  }
}
