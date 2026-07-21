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

## M4 — Voice pipeline (2026-07-21)

- **System prompt bundled verbatim** at assets/pulsiq_system_prompt.txt
  (spec §1); the deployed proxy injects its own copy server-side.
- **Until the proxy URL exists** (`--dart-define=PULSIQ_PROXY_URL=…`), both
  slots of the Claude→Gemini fallback chain run a deterministic on-device
  mock that emits contract-valid JSON from transcript keywords, so the full
  pipeline (STT → parse → validate → insert → rings) runs offline today.
- **Contract validation client-side too** — the backend validates per spec,
  but the app re-validates because malformed rows must never hit the DB.
  Parser accepts bare JSON, fenced JSON, or JSON embedded in prose; one
  fix-the-JSON retry per backend; final fallback logs the raw transcript
  as a "Voice note (unparsed)" entry.
- **Beverages in the contract carry no volume**; hydration arrives
  separately in hydration_added_ml. Water-type beverages therefore insert
  with volume 0 (no double count) and diuretics get typical serving
  volumes (caffeine 240 ml / alcohol 330 ml / protein 300 ml) for the 1:1
  hydration-target offset.
- **STT**: on-device speech_to_text with partial results streaming into
  the hold-to-record overlay; confidence floor 0.5 marks where the Whisper
  API fallback will route once the proxy exists. Caffeine parsed from a
  voice note schedules the same +2h reminder as manual logging.
- **"PulsIQ is thinking" chip** floats above the FAB and never blocks
  further logging — the LLM round-trip runs detached.

## M5 — Health integration & baselines (2026-07-21)

- **health pinned to ^13.2** — unconstrained `pub add health` silently
  resolved to 3.0.6 (a 2021 release) due to a transitive conflict;
  pinning forced the modern API (device_info dropped from the graph).
- **No fake biometric confidence:** the default health source is *empty*
  (score renormalizes to fuel-only with a visible chip + connect CTA).
  The seeded DemoHealthSource is an explicit Settings toggle for
  previews/dev only. Real telemetry activates via the Pulse-card connect
  button (permission grant persisted + audited).
- **Baseline engine:** 7/30-day rolling averages exclude today and need
  ≥3 samples per window; every displayed metric is delta-vs-baseline.
- **Score components:** cardiac = mean of HRV-above-baseline and
  RHR-below-baseline scores, ±20% off baseline spans the 0..1 range around
  0.5. Sleep = 60% duration (8h ideal) + 40% efficiency, duration-only
  fallback. Both null (renormalized away) until baselines exist.
- **Morning Recovery Reset:** trigger rule in the pure engine (<11am and
  sleep <6.5h or RHR >baseline+5), card actions: +500 ml goal boost
  (feeds the live hydration target), protein-breakfast nudge, 10-min walk
  start (WalkSessions row; live timer card lands in M6). Dismiss/complete
  persists per-day.
- **Correlation notes** (hot RHR > short sleep > HRV climb > calm RHR
  precedence) are appended to voice-coach replies; same rules will feed
  the M6 evening forecast.
- **Platform:** HealthKit entitlement + usage string wired into the Xcode
  project; Health Connect read permissions + permission-usage
  activity-alias in the Android manifest.

## M6 — Signature features (2026-07-21)

- **Order Hack:** camera/gallery via image_picker → on-device ML Kit OCR
  (native only, conditional import; web offers manual menu-text paste) →
  LLM `analyzeMenu` (separate proxy endpoint, own contract validator) →
  top-3 cards with a one-line why + steady/moderate/spike rating. Mock
  backend ranks menu lines by lean/fried keywords until the proxy deploys.
- **Post-carb walk timer:** when a voice log returns high_spike or
  post_meal_action_required, the coach snackbar carries a "Start N-min
  walk" action; the WalkController runs an in-app timer card plus an
  ongoing notification (Android foreground-service style / iOS Live
  Activity stand-in — a full ActivityKit widget is native work past the
  Flutter layer). Completing marks the WalkSessions row done and folds its
  minutes into today's active minutes → PulsIQ Score.
- **Evening forecast:** pure engine scores positive/negative signals
  (HRV/RHR deltas, movement, dense fuel, late caffeine) and cites the
  strongest one; card shows from 7pm (Settings toggle forces it for
  preview). Same signal precedence as the correlation notes.
- **Sweetness adjuster:** >15 g sugar (or user-flagged) → dilution hack,
  appended to voice-coach messages and shown as a snackbar on manual
  beverage logging.
- **PulsIQ Score v1** completed in M5 (baseline-driven cardiac + fuel-only
  renormalization); M6 adds completed-walk minutes as an input.

## Nutrition & meal-photo analysis (post-M7 feature, 2026-07-21)

Owner-requested extension (spec at `NUTRITION_VISION_PROMPT.md`). Deliberate
product change from the original "energy-only, no raw numbers" framing — the
owner wants explicit macro tracking. We surface the numbers but keep the warm
energy-first coaching voice and the not-medical-advice stance.

- **Model:** meal-photo vision runs on **Claude Opus 4.8** (`claude-opus-4-8`)
  — Anthropic's most capable generally-available model with high-res vision,
  the right default for food-macro estimation (Fable 5 is above-Opus pricing
  and gated for dual-use, unnecessary here). It runs **server-side on the
  Supabase proxy** — no API keys in the app (§0 unchanged); the app POSTs
  base64 image + optional hint to `/v1/meal-vision`.
- **Schema v2** (additive migration): FoodEntries gains calories/protein/
  fiber/carbs/fat (nullable) + a `source`. Daily aggregation + 7-day history
  queries; targets (cal 2000 / protein 100 / fiber 30) editable in Settings.
- **Offline/web/test fallback:** the on-device mock can't see pixels, so it
  estimates from the user's text hint via a keyword→macro table (mixed-plate
  default at low confidence). Keeps the full analytics pipeline runnable
  without the proxy. Real vision activates with the proxy URL.
- **Capture flow:** photo (camera/gallery, image_picker) → "reading your
  plate" → editable per-item review (correct any macro before it commits) →
  food entries with `source: photo`. Low-confidence results prompt a fix.
- **Analytics UI:** dashboard "Today's fuel" card (calorie ring in the brand
  hue + protein/fiber/carbs/fat bars vs target) → Nutrition detail (per-macro
  progress, 7-day calorie trend, meal breakdown, targets editor). Charts
  follow the dataviz reference palette: macro categorical colors are the first
  four validated CVD-safe slots (protein=blue, carbs=amber, fat=magenta,
  fiber=green), each bar also directly labeled so identity never rests on
  color alone; single-series calorie ring/trend use the brand hue (one axis,
  no dual-scale).
- **Cut-down engine** (pure, unit-tested): appears after ≥2 meals; ranks the
  largest over-target macro, always pairs a cut with a concrete swap,
  time-of-day aware, wellness-framed. Also on the dashboard.
- **iPhone testing:** web build now served on the LAN (0.0.0.0:8087) so the
  owner opens it in iPhone Safari immediately — camera/photo + full nutrition
  UI work there. Native build (HealthKit/STT) prerequisites documented in
  `store/IPHONE_BUILD.md`; blocked on the owner installing full Xcode +
  CocoaPods + an Apple ID for signing — the same toolchain gap noted below.

## M7 — Hardening & store prep (2026-07-21)

- **Data export + delete-all** (§4): Settings → one tile each (≤3 taps
  incl. the delete confirmation). Export is pretty JSON of every table
  (keys deliberately excluded); share sheet on device, clipboard on web.
  Delete wipes all tables + KeyVault, signs out, returns to onboarding.
  Round-trip + wipe covered in test/data_manager_test.dart.
- **Privacy manifests:** ios/Runner/PrivacyInfo.xcprivacy (health + audio,
  not linked, not tracking; UserDefaults + file-timestamp reason codes);
  Play Data Safety answers + store listing copy under `store/`.
- **App icon + splash:** programmatic pulse-wave-on-deep-night source
  (`assets/branding/icon.png`) run through flutter_launcher_icons +
  flutter_native_splash for both platforms (incl. Android 12).
- **Accessibility:** Semantics labels on the score hero, hydration ring,
  and each Pulse row (decorative waveforms ExcludeSemantics'd); the FAB
  already carried its gesture label. Dynamic type works via default Text
  scaling — no fixed-height text containers that would clip.
- **Perf posture:** local-first optimistic updates mean every tap reflects
  from local state immediately; the LLM round-trip is always detached.
  Cold-start/tap budgets (§2) need on-device profiling once the toolchains
  are installed.

- **Verification gap (carried through all milestones):** the spec's "runs
  on an iOS simulator and Android emulator" check cannot be met on this
  machine — Xcode is only partially installed (needs App Store install +
  `xcodebuild -runFirstLaunch` + CocoaPods) and there is no Android
  SDK/AVD. Every milestone was instead verified with `flutter analyze`,
  the full test suite, and a live release run on the web device (which
  exercises the real Drift/Riverpod/router/UI stack). Rerun on both
  simulators, plus TestFlight/Play internal builds, once the toolchains
  are installed — this is the only outstanding item.
