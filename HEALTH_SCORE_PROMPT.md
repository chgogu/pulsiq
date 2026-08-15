# PulsIQ — Per-source Health Score + stored history + dashboard averages

## Why
Today biometric data is fetched live and thrown away; there's one composite
PulsIQ Score and no per-source view. Users can't see "how am I doing on Apple
Health" vs "on WHOOP", there's no health-score history, and the dashboard shows
no averages. Give each connected source its own 0–100 **Health Score**,
persist a daily snapshot so history accumulates beyond the API's rolling
window, and surface **averages** on the dashboard. UX is the priority: one
honest number per source, plainly labelled, with its trend and average.

## 1. Health Score engine — `lib/domain/health_score.dart` (pure, tested)
Scores a single day's body signals against the person's own window baseline,
blended with absolute anchors. Works for both sources (different metrics
present → renormalize over what exists, same pattern as `pulsiq_score.dart`).

Components + base weights:
- recovery 0.35 — `recoveryPct/100` (WHOOP only)
- hrv 0.20 — higher-is-better, relative to window avg
- restingHr 0.15 — lower-is-better, relative to window avg
- sleep 0.20 — `sleepPerformancePct/100`, else `clamp(sleepHours/8,0..1)`
- activity 0.10 — `clamp(steps/8000,0..1)` (Apple Health), else exercise min

`_relative(value, avg, higherIsBetter, tolerance)` → 0.5 at avg, →1 when
`tolerance` better, →0 when worse; tolerance = `max(avg*frac, floor)`.

API:
- `class HealthScore { int? value; HealthBand band; Map<HealthComponent,double> parts; }`
- `enum HealthBand { excellent, good, fair, low }` (≥80 / 65 / 50 / else); `.label`.
- `HealthScore computeHealthScore(WhoopBody window, {WhoopDay? day})`
  (day defaults to `window.latest`; baseline = window averages).
- `List<({DateTime day, int score})> dailyHealthScores(WhoopBody window)`
  (each non-empty day scored vs the window baseline — for trend + history).
- `int? averageHealthScore(WhoopBody window)` (mean of daily scores).

## 2. Persistence — schema v7, `HealthScoreSnapshots`
Columns: `id` (auto), `day` (DateTime, midnight-aligned), `source` (text:
`whoop` | `appleHealth`), `score` (int), and the day's analytics so history is
self-contained: `hrvMs` real?, `restingHr` real?, `sleepHours` real?,
`recoveryPct` int?, `steps` int?. `UNIQUE(day, source)`.

Migration: `if (from < 7) await m.createTable(healthScoreSnapshots);`
(additive; existing rows untouched — pattern matches v2–v6).

DB methods:
- `Future<void> upsertHealthSnapshots(List<HealthScoreSnapshotsCompanion>)`
  via `insertOnConflictUpdate` on the (day,source) unique key.
- `Stream<List<HealthScoreSnapshot>> watchHealthSnapshotsSince(String source, DateTime since)`.

## 3. Providers — `lib/health/health_score_providers.dart`
- `class HealthScoreView { int? today; int? average; HealthBand band;
  List<({DateTime day,int score})> series; int windowDays; }`
- `whoopHealthScoreProvider` : FutureProvider<HealthScoreView?> — from
  `whoopBodyProvider`; compute view; **upsert** each day's snapshot; return view.
- `appleHealthScoreProvider` : FutureProvider<HealthScoreView?> — from
  `platformBodySignalsProvider`, source `appleHealth`.
- `avgCaloriesProvider` : reuse `logHistoryProvider` → `YearSummary` avg kcal.

## 4. UI
- **WhoopCard / PlatformHealthCard** (`whoop_card.dart`): add a headline
  **Health score** element at the top of `_Signals` — big number + band label +
  `avg NN · {windowDays}d`. For Apple Health (no recovery ring) this becomes the
  card's hero number; for WHOOP it sits above the recovery ring. Reuse the
  existing `_TrendSection` to also offer a "Health score" trend series.
- **Dashboard** (`dashboard_screen.dart`): a compact **AveragesCard** below
  "Today's log": avg kcal/day (from history) + WHOOP score avg + Apple score
  avg (each shown only when available). Taps into `/history`.

## 5. Tests
- `test/health_score_test.dart`: renormalization when metrics missing; recovery
  dominates for WHOOP; Apple-only (rhr/hrv/sleep/steps, no recovery) still
  scores; higher HRV / lower RHR raise the score; bands map correctly; empty
  window → null; `dailyHealthScores` length = non-empty days; average matches.
- `test/health_snapshot_db_test.dart`: upsert is idempotent per (day,source);
  distinct sources coexist for the same day; `watchHealthSnapshotsSince`
  filters by cutoff and source.
- Update any widget tests that pump the cards to stub the new providers.

## Acceptance
- WHOOP and Apple Health cards each show a labelled Health Score + average +
  trend, independently (turning one off never hides the other).
- Scores persist daily and accumulate history beyond the API window.
- Dashboard shows averages (kcal + both scores when present).
- `flutter analyze` clean; full suite green; builds; runs on device.
