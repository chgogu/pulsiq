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
- **Verification gap:** M1's "runs on iOS simulator + Android emulator"
  criterion cannot be met on this machine yet — Xcode is only partially
  installed (needs App Store install + `xcodebuild -runFirstLaunch`) and there
  is no Android SDK/AVD. Verified instead with `flutter analyze`, the full
  test suite, and a live run on the web device. Rerun on both simulators once
  the toolchains are installed.
