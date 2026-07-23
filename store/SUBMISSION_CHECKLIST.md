# App Store submission checklist

Status as of the Cloudflare Workers migration. Items marked **YOU** need a
decision or an account action that can't be done from the repo.

## Done

- **Backend is hosted.** `https://api.pulsiqapp.com` (Cloudflare Worker,
  `workers/api`). No LAN dependency, HTTPS only.
- **No API keys in the app.** Gemini and WHOOP credentials are Worker secrets.
- **Local Network permission removed.** `NSLocalNetworkUsageDescription` and
  `NSAppTransportSecurity/NSAllowsLocalNetworking` are gone — they existed only
  for the old Mac proxy. Shipping them would have prompted users for local
  network access with no honest reason, which reviewers flag.
- **ATS is at its default**, HTTPS-only, with no exceptions.
- **Version reads from the bundle.** Settings › About showed a hardcoded
  "0.1.0" while the app shipped as 1.0.0; it now reads `PackageInfo`.
- **Dev toggles removed** — "Demo biometrics" and "Preview evening forecast".
  Synthetic health data in a health app is a review risk.
- **Privacy manifest** (`ios/Runner/PrivacyInfo.xcprivacy`) declares
  HealthFitness + AudioData, no tracking, and reasons for UserDefaults and
  file-timestamp APIs.
- **Usage strings** present and specific for Camera, Face ID, HealthKit,
  Microphone, Photos, Speech.
- **HealthKit is read-only** — no `NSHealthUpdateUsageDescription`, no
  `UIBackgroundModes`, matching what the app actually does.
- **Privacy policy** at `store/PRIVACY_POLICY.md`, contact
  `pulsiq.app@gmail.com`, live site at pulsiqapp.com.
- **Rate limiting is live and verified.** Per-IP, per-minute: 10 on the AI
  routes, 120 on the cheap ones, returning 429 with `retry-after`. Verified in
  production — 21 calls through, then 429s.

  Note: Cloudflare's Rate Limiting *binding* is configured but **did not
  enforce** on this account (12 sequential calls against a limit of 5 all
  passed). The enforcing layer is a per-colo cache counter in
  `workers/api/src/index.js`; the binding is kept as defence in depth and will
  take over if it starts working.

## Before you upload

- **YOU — CONFIRM export compliance.** `ITSAppUsesNonExemptEncryption` is now
  set to `false` in `ios/Runner/Info.plist`, which stops App Store Connect
  asking on every upload. That declares the app uses only *exempt* encryption:
  HTTPS for transport and SQLCipher (AES) purely to protect the user's own
  data at rest on their own device. That is the standard position for this
  profile, but it is a legal declaration about your product — read it and
  confirm you agree. Flip it to `true` (and file the annual self-classification
  report) if you disagree.

- **YOU — GEMINI BILLING. This is the launch blocker.** The API key is on the
  free tier, which allows **20 requests per minute across the entire key** —
  not per user. Testing exhausted it in one burst. With real users the app will
  return errors constantly. Enable billing on the Gemini API key before launch.

- **YOU — App Review demo account.** Review needs to exercise the app without
  a WHOOP account or your Apple Health data. Either supply a test account in
  App Review notes, or explain that core features (manual/photo logging,
  nutrition) work with no integration connected.

- **YOU — screenshots and listing copy** for the required device sizes.
  `store/STORE_LISTING.md` has the copy; screenshots aren't captured yet.

- **YOU — App Privacy answers** in App Store Connect must match
  `PrivacyInfo.xcprivacy`: Health & Fitness and Audio collected, not linked to
  identity for tracking, not used for tracking.

## Known limits worth stating in review notes

- WHOOP's developer API exposes no step count; steps come from Apple Health or
  Health Connect. The app says so in-product.
- Recovery and strain are WHOOP-only scores and are hidden when reading from
  Apple Health, rather than shown empty.
