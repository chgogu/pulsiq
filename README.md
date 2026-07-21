# PulsIQ

**Biometric intelligence in real time.** A biometric-first, voice-first AI
energy coach for iOS and Android — one Flutter codebase, two stores.

Heart-rate telemetry (RHR, HRV) is the product's identity: every feature reads
as "your pulse, interpreted intelligently," with nutrition and hydration as
inputs that explain what the biometrics show.

## Status

Milestones M1–M7 complete (see [`DECISIONS.md`](DECISIONS.md) for the calls
made along the way). Verified via `flutter analyze`, the full test suite, and
a live web run. The one outstanding item is running on an iOS simulator and
Android emulator — blocked on a full Xcode install and the Android SDK on the
current machine.

## Architecture

- **Framework:** Flutter (stable), iOS 16+ / Android 10+ (API 29+).
- **State:** Riverpod, local-first optimistic updates.
- **Storage:** Drift over SQLCipher (native) / sqlite3 WASM (web preview),
  `flutter_secure_storage` + `KeyVault` for keys.
- **Auth:** Google Sign-In + passkeys + local profile; no passwords.
  Biometric app lock via `local_auth`.
- **LLM:** provider-agnostic `LlmCoach` (Claude → Gemini fallback) behind a
  backend proxy; a deterministic on-device mock runs until the proxy URL is set.
- **Speech:** on-device `speech_to_text`.
- **Health:** `health` package (HealthKit / Health Connect), read-only.

## Running

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # Drift codegen

flutter run                       # on a connected device / simulator
flutter test                      # full suite

# Web preview (dev vehicle used for verification on this machine):
flutter build web --release && \
  python3 -m http.server 8087 --bind 127.0.0.1 --directory build/web
```

Point the app at a real backend with `--dart-define=PULSIQ_PROXY_URL=https://…`.
Without it, the voice/menu pipelines use the on-device mock backend.

### Preview-only toggles (Settings)
- **Demo biometrics** — seeded 30-day wearable series so the Pulse card and
  score's cardiac/sleep components show without a real wearable. Off by
  default so the score stays honestly "fuel-only" for real users.
- **Preview evening forecast** — show the 7pm forecast card any time.

## Store assets

`store/` holds the Play Data Safety answers and store-listing copy;
`ios/Runner/PrivacyInfo.xcprivacy` is the iOS privacy manifest. App icon and
splash are generated from `assets/branding/icon.png`.

## Regenerating icons / splash

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

PulsIQ is a wellness product, not a medical device. Nothing in the app is
medical advice.
