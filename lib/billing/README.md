# PulsIQ Plus — subscription setup

The **code is done**: `SubscriptionService` (StoreKit via `in_app_purchase`),
the paywall (`/plus`), the Settings row, and the entitlement gate
(`isPlusProvider` → `aiAssistEnabledProvider` → cloud Gemini). What remains is
account/store setup, which is tied to the owner's Apple identity and banking
and can't be done from code.

## The product

| | |
|---|---|
| Product ID | `com.pulsiq.pulsiq.plus.monthly` (must match `kPlusProductId`) |
| Type | Auto-renewable subscription |
| Subscription group | `PulsIQ Plus` |
| Price | $2.00 / month |
| Unlocks | Cloud Gemini estimates + photo snap-a-meal |

## Test the purchase now, without App Store Connect

`ios/PulsIQ.storekit` is a local StoreKit configuration wired into the Runner
scheme. Launching **from Xcode** (Product → Run) uses it, so the paywall's buy
flow works against a fake local product — no App Store Connect, no agreement,
no real charge.

```
open ios/Runner.xcworkspace
# Product → Run (⌘R). Open Settings → PulsIQ Plus → Get Plus.
```

The purchase completes locally, `isPlus` flips true, and cloud AI turns on.
(A `devicectl`-installed release build does **not** use this file — StoreKit
testing only applies to Xcode-launched runs.)

## Go live — owner steps (needs your Apple account)

1. **Paid Apps Agreement.** App Store Connect → Business → Agreements. Accept
   the Paid Applications agreement and enter banking + tax info. Nothing sells
   until this is active. *(This needs your banking details — it's yours to do.)*
2. **Create the subscription.** App Store Connect → your app → Monetization →
   Subscriptions:
   - New Subscription Group: `PulsIQ Plus`.
   - New Subscription: Reference name `PulsIQ Plus Monthly`, Product ID
     **exactly** `com.pulsiq.pulsiq.plus.monthly`, duration 1 month, price
     $1.99 (the tier nearest $2).
   - Add a localized display name ("PulsIQ Plus") and description, and a
     review screenshot of the paywall.
3. **Sandbox tester.** App Store Connect → Users and Access → Sandbox → add a
   test Apple ID. On the iPhone, sign into it under Settings → App Store →
   Sandbox Account, then the real buy flow works on a `devicectl` build too.
4. **Submit for review** with the subscription attached to the build.

## Hardening later: server-side receipt validation

Verification is currently StoreKit's own (the platform validates before a
purchase reaches the app). That's fine for a v1 whose only unlock is cheaper
inference. When it's worth it, validate the receipt on the Worker
(`workers/api`) against Apple's `verifyReceipt` / App Store Server API, and
have the Worker gate the Gemini routes on a validated entitlement rather than
trusting the client. That also enables real per-user metering.
