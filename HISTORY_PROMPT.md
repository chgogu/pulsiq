# PulsIQ — Log History (past 1 year)

## Why
Today the app only shows **today's** log (every query filters at
`startOfToday()`). Users can't look back, so there's no sense of progress or
pattern. Add a browsable **1-year history** of everything logged, grouped by
day, with lightweight per-day and full-range insight — so "what did I eat last
Tuesday / how have I been trending" is answerable.

## Scope (v1)
- Read-only browsing of all four log kinds (food, beverage, hydration,
  exercise) over the last 365 days.
- Grouped by calendar day (local time), newest day first.
- Per-day summary: total calories, water, exercise minutes, item count.
- A top range-summary: days logged in the year + average kcal on logged days.
- Reachable from the dashboard header.
- Editing/deleting reuses the existing log tile behaviour (swipe to delete,
  tap to edit) — no new write paths.

Out of scope: charts/graphs (the dashboard analytics already cover trends),
export changes, cloud sync.

## Data layer (`app_database.dart`)
Add range queries mirroring the existing `watchToday*` ones but taking a
`since` cutoff (do NOT change the today queries):
- `watchFoodsSince(DateTime since)`
- `watchBeveragesSince(DateTime since)`
- `watchHydrationSince(DateTime since)`
- `watchExerciseSince(DateTime since)`
Each: `where(loggedAt >= since)`, `orderBy(loggedAt desc)`.

No schema change, no migration — this is pure query. All existing data is
already dated via `loggedAt`, so history "just works" retroactively.

## Providers (`providers.dart`)
- `historyCutoffProvider` → `DateTime.now() - 365 days` (day-aligned).
- Four `*SinceProvider` StreamProviders bound to the cutoff.
- `logHistoryProvider` → combines the four into `List<LogItem>` sorted desc,
  reusing `foodToItem`/`beverageToItem`/`hydrationToItem`/`exerciseToItem`.
  Same error/loading collapsing pattern as `logFeedProvider`.

## Grouping (`lib/features/history/day_log.dart`, pure + tested)
- `class DayLog { DateTime day; List<LogItem> items; int calories; int waterMl;
  int exerciseMinutes; int foodCount; }`
- `List<DayLog> groupIntoDays(List<LogItem>)`:
  - bucket by `DateTime(y,m,d)` of each item's `loggedAt`
  - within a day keep newest-first
  - days sorted newest-first
  - calories = sum of food entities' `caloriesKcal`
  - waterMl = sum of hydration `amountMl`
  - exerciseMinutes = sum of exercise `durationMinutes`
  - foodCount = number of food items
- `class YearSummary { int daysLogged; int avgKcalOnLoggedDays; int totalItems; }`
  `YearSummary.from(List<DayLog>)` — avg over days that have ≥1 food entry.

## UI (`lib/features/history/history_screen.dart`, route `/history`)
- AppBar "History".
- Top: a compact `YearSummary` strip ("N days logged this year · ~X kcal/day").
- Body: for each `DayLog`, a day header — friendly label ("Today",
  "Yesterday", else "EEE, MMM d") + a muted summary line
  ("1,840 kcal · 5 items · 1.5 L · 30 min", omit zero parts) — followed by the
  day's `LogTile`s (reuse the existing widget).
- Empty state when no history: "Your logged days will appear here."
- Loading / error states like the dashboard.

## Entry point (`dashboard_screen.dart`)
- Add a **History** `IconButton` (`Icons.history`) in the top row, left of the
  Settings gear → `context.push('/history')`.

## Tests (`test/history_grouping_test.dart`)
- groups mixed-kind items across 3 distinct days into 3 buckets, newest first.
- per-day calories/water/exercise/foodCount sums are correct.
- `YearSummary` averages kcal only over days with food, ignores empty days.
- items on the same day but different times stay in one bucket, newest-first.

## Acceptance
- Dashboard history icon opens a screen listing prior days, newest first.
- Each day shows its entries and a correct summary line.
- Editing/deleting from history works (reused tile) and reflects on return.
- `flutter analyze` clean; full test suite green.
