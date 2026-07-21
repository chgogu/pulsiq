# FEATURE PROMPT — Photo Nutrition Analysis & Daily Analytics (PulsIQ)

Owner request (2026-07-21): "Every user able to calculate what they ate using
a picture; the app adds all calories, protein, fiber, and other food
analytics, shows the calculated totals, and provides recommendations on what
to cut down every day. Use the best health AI model. Best app UI design.
Need an iPhone-testable version."

This extends the shipped M1–M7 app. It is a deliberate product change: the
original build prompt (§1 language boundaries, §6 "no food-database UI") kept
nutrition energy-framed and hid raw numbers. The owner now wants explicit
macro tracking. We keep the warm, energy-first coaching **voice** but surface
the hard numbers and daily targets. The "not medical advice" disclosure stays.

## 1. The model
- **Vision analysis runs on the latest Claude vision model** (Claude 5 family)
  through the existing backend proxy — no API keys in the app (§0 unchanged).
  The proxy adds the system prompt and holds credentials.
- Fallback chain unchanged in spirit: primary Claude vision → Gemini vision
  fallback → on-device heuristic estimate (so the feature works offline / in
  the web preview and in tests).

## 2. Capture → estimate
- New "Snap a meal" path on the Universal FAB long-press menu and the Add
  sheet: camera or gallery photo → send image to proxy `/v1/meal-vision`.
- Model returns validated JSON (per-item name, portion, calories, protein_g,
  fiber_g, carbs_g, fat_g, quality_score) plus a confidence and a one-line
  energy-framed note.
- On low confidence, the user can tap any item to correct the estimate before
  it commits (optimistic insert first, editable after).

## 3. Data
- FoodEntries gains: caloriesKcal, proteinG, fiberG, carbsG, fatG (all
  nullable — older/voice entries may lack them), plus a `source`
  (photo|voice|manual). Schema v2 with an additive migration.
- Daily targets (editable in Settings, sensible defaults): calories 2000,
  protein 100 g, fiber 30 g. Stored in app settings.

## 4. Analytics (new dashboard section + a Nutrition detail screen)
- **Today's fuel card** on the dashboard: calorie ring (consumed vs target),
  and protein / fiber / carbs / fat mini-bars, each vs its target.
- **Nutrition detail screen**: per-macro progress, a 7-day trend, and the
  meal-by-meal breakdown for the day. Charts follow the `dataviz` design
  system (categorical macro palette, accessible in light + dark).
- Every number shown with context, never bare — consistent with the app's
  "vs target / vs baseline" language.

## 5. Daily "cut down" recommendations
- A pure engine (fully unit-tested) that, from today's totals vs targets,
  produces 1–3 specific, actionable suggestions: e.g. "You're 480 kcal over
  and short on fiber — swap the afternoon pastry for Greek yogurt + berries."
- Prioritize the largest over-target macro; always pair a "cut" with a
  concrete swap. Stays wellness-framed, never diagnostic.
- Surfaced as a dashboard card (after 2+ meals logged) and folded into the
  evening forecast.

## 6. UI design ("best app UI design")
- Elevate the visual system: refined type scale, spacing rhythm, macro
  color-coding, tactile rings/bars, smooth micro-interactions — while keeping
  the pulse-waveform identity. Charts via the `dataviz` skill.

## 7. Testing on iPhone
- Immediate: serve the release web build on the LAN (0.0.0.0:8087) so the
  owner opens `http://<mac-ip>:8087` in iPhone Safari. Camera photo works via
  Safari; HealthKit/native STT do not (Demo biometrics covers the former).
- Native: documented prerequisites (full Xcode + CocoaPods + Apple signing)
  in `store/IPHONE_BUILD.md`; once present, `flutter build ipa` / device run.

## 8. Verify
- Unit tests: nutrition JSON contract + validation, daily macro aggregation,
  recommendation engine, schema-v2 migration. Widget test: photo → analytics
  update. `flutter analyze` + full suite + web run, then commit.
