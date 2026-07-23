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

## Before you upload

- **YOU — export compliance.** `ITSAppUsesNonExemptEncryption` is not set, so
  App Store Connect asks on every upload. The app uses HTTPS and SQLCipher for
  local storage. Most apps in this position qualify for the exemption and
  declare `false`, but it's a legal declaration about *your* product, so make
  it deliberately rather than letting a tool answer for you. Add it to
  `ios/Runner/Info.plist` once decided, and the prompt stops.

- **YOU — rate limiting.** `api.pulsiqapp.com` is a public endpoint in front of
  a metered Gemini key. The bearer token ships inside the IPA and can be
  extracted. Add a Cloudflare Rate Limiting rule on `/v1/*` (≈60 req/min per
  IP) before you have real users. See `workers/api/README.md`.

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
