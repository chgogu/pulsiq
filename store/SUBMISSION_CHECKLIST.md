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

- **Cloud AI is off — no Gemini billing needed to launch.** Nutrition resolves
  on-device (bundled USDA table + on-device parser); voice logs and menu scans
  use the on-device keyword parser. Nothing calls Gemini in the shipping
  configuration, so its free-tier quota is irrelevant. The Worker still runs,
  but only its WHOOP routes are used, and those don't touch Gemini. Bring-your-
  own-key AI is a planned post-launch addition (see below).

- **YOU — App Review demo account.** Review needs to exercise the app without
  a WHOOP account or your Apple Health data. Either supply a test account in
  App Review notes, or explain that core features (manual/photo logging,
  nutrition) work with no integration connected.

- **Screenshots — DONE.** Five curated frames in `store/screenshots/`
  (01–05), all 1290x2796, shot with WHOOP and Apple Health connected: the
  body-signals hero, the 60-day trend chart, the Apple Health card, the fuel +
  insights view, and the daily read. Order and captions in
  `store/SCREENSHOT_PLAN.md`.

- **YOU — create the App Store distribution build.** The archive builds clean
  (`1.0.0 (1)`), but there's no Apple Distribution certificate yet, and only
  Xcode's Organizer can create one interactively (the command line reports
  "No Accounts / No signing certificate"). Steps:
  1. In App Store Connect, create the app record for bundle id
     `com.pulsiq.pulsiq` (name, primary language, category: Health & Fitness).
  2. `open build/ios/archive/Runner.xcarchive` — or re-archive from Xcode
     (Product → Archive) so it's the newest.
  3. In Organizer: **Distribute App → App Store Connect → Upload**, automatic
     signing. Xcode creates the distribution cert + provisioning profile.
  4. Fill in App Privacy (Health & Fitness + Audio, not used for tracking),
     attach the screenshots, set the description from `store/STORE_LISTING.md`,
     add the privacy-policy URL (pulsiqapp.com), and submit for review.

## Planned, not blocking launch

- **Bring-your-own-key AI.** Users can't currently connect their own model.
  When added, it will be an API key (OpenRouter or per-provider) that bills the
  user's own API account — NOT a "sign in with Google to use your ChatGPT/
  Claude subscription" flow, which is impossible: those consumer subscriptions
  expose no API, and no Google login grants a third-party app access to them.

## Known limits worth stating in review notes

- WHOOP's developer API exposes no step count; steps come from Apple Health or
  Health Connect. The app says so in-product.
- Recovery and strain are WHOOP-only scores and are hidden when reading from
  Apple Health, rather than shown empty.
