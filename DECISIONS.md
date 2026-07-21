# PulsIQ — Decisions log

Calls made while executing the build prompt (`../pulsiq-build-prompt.md`).
Non-negotiables from §0 are not re-litigated here.

## M1 — Skeleton & design system (2026-07-21)

- **Project location:** `Reeler/pulsiq`, following the repo's one-folder-per-app
  convention.
- **Web target added** purely as a dev/preview vehicle (this machine currently
  has no full Xcode and no Android SDK). iOS and Android remain the only store
  targets.
- **Navigation:** `go_router`. A `ShellRoute` hosts the universal FAB and the
  voice-recording overlay so both persist on every screen, per spec §2.
- **Score engine implemented in M1** (`lib/domain/pulsiq_score.dart`): it is a
  mandatory test target and the dashboard hero needs real renormalization
  logic even with mock inputs. Fuel-only = no cardiac *and* no sleep data.
- **Splash always routes to onboarding in M1**; first-run persistence arrives
  with Drift in M2.
- **"Not medical advice" disclosure** (spec §4) ships on the onboarding screen
  from day one.
- **Backend pick (spec §0 says choose one):** Supabase — Postgres + RLS fits
  the encrypted-blob backup model, Edge Functions serve as the LLM proxy, and
  it doesn't drag in Firebase Analytics. Locked in for M3/M4.
## M2 — Local logging core (2026-07-21)

- **Drift everywhere, one code path:** native FFI on iOS/Android and in
  host tests; sqlite3 WASM on the web preview via the two official assets
  (`web/sqlite3.wasm` from sqlite3.dart release 3.5.0, `web/drift_worker.js`
  from drift release 2.34.2 — drift's documented web setup).
- **Weather location is IP-based (ipapi.co → Open-Meteo), no GPS** in v1:
  avoids a location permission for a coarse adjustment. Cached 3h in the DB;
  all failures degrade to cache, then to "no adjustment".
- **Hydration math:** base 2,000 ml; ≥30 °C +500 / ≥25 °C +250; +250 more
  when ≥25 °C and ≥70% humidity; +12 ml per exercise minute; 1:1 caffeine
  and alcohol offsets; rounded to 50 ml, clamped 1,500–5,000.
- **Water-type beverages mirror into hydration** so the ring reflects them;
  quick-add toast long-press upgrades the same row from 8 to 16 oz (no
  double-count).
- **Fuel quality** = mean of today's food quality scores (clean 1.0 /
  moderate 0.6 / dense 0.25); absent (renormalized out of the score) until
  something is logged.
- **Reminders:** engine is pure Dart (max 4/day, quiet 22:00–07:00, coffee
  +2h, behind-pace at 15:00); delivery via flutter_local_notifications,
  inexact scheduling, no-op on web.
- **Audit:** every log write/edit/delete appends an audit row; viewer at
  Settings → Privacy. Reads audited per session, not per stream frame.
- **Targets locked:** Android minSdk 29, iOS deployment target 16.0
  (pbxproj + Podfile).
- **Web-verified live:** entry sheet → DB write → reactive ring/feed;
  weather-adjusted target (2,500 ml on test day); IndexedDB persistence
  across reloads; returning-user splash routing. Known M7 polish item:
  SegmentedButton labels wrap on 375-wide screens — shorten or icon-only.
- **Sheets open on the root navigator** (useRootNavigator) so the shell FAB
  doesn't overdraw them.
- **Test-infra note:** drift stream cancellation schedules zero-duration
  timers; widget tests dispose the tree in-body (`disposeApp`) to satisfy
  flutter_test's pending-timer guard. Test runs are slow on this machine —
  the darwin-x64 flutter_tester runs under Rosetta.

## M3 — Auth & security (2026-07-21)

- **Encryption at rest via SQLCipher selected at build time** — sqlite3 v3
  uses build hooks, so the cipher is chosen in pubspec
  (`hooks → user_defines → sqlite3 → source: sqlcipher`), no code-side
  loader overrides. The old `sqlcipher_flutter_libs`/`sqlite3_flutter_libs`
  packages are EOL stubs under v3 and were removed (drift_flutter too — the
  connection is a plain `NativeDatabase` on an app-documents file now).
  Per-device key: 32 random bytes in Keychain/Keystore via KeyVault →
  `PRAGMA key`. Web preview stays unencrypted (plain sqlite3.wasm) — dev
  vehicle only.
- **CryptoService**: AES-256-GCM (package:cryptography), blob layout
  base64(nonce|ciphertext|mac), separate data key from the same vault —
  this is the client-side sealing layer for any future cloud backup
  (zero-knowledge posture §4). Round-trip/tamper/wrong-key tests in
  test/crypto_test.dart.
- **Auth = Google / passkey / explicit local profile; no passwords.**
  Google Sign-In code path is live but needs OAuth client IDs; passkeys
  need the Supabase relying-party deployment (apple-app-site-association +
  assetlinks.json on a real domain) — both are deployment config the repo
  can't self-provide. "Continue without an account" keeps the app fully
  functional offline; Settings offers sign-in/sign-out.
- **Biometric app lock**: local_auth behind a LockGate above the router;
  locks on cold start and after >60s backgrounded; enabled by default,
  toggle in Settings; auto-skips where biometrics don't exist (web, CI) so
  it can never lock the user out of a platform without sensors.
  MainActivity switched to FlutterFragmentActivity; USE_BIOMETRIC +
  NSFaceIDUsageDescription added.
- **Auth events audited** (sign-in method, sign-out, unlocks) in the same
  append-only table.

- **Verification gap:** M1's "runs on iOS simulator + Android emulator"
  criterion cannot be met on this machine yet — Xcode is only partially
  installed (needs App Store install + `xcodebuild -runFirstLaunch`) and there
  is no Android SDK/AVD. Verified instead with `flutter analyze`, the full
  test suite, and a live run on the web device. Rerun on both simulators once
  the toolchains are installed.
