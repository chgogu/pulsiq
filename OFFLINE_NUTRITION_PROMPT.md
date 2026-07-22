# PulsIQ offline nutrition cascade — cost-first spec

Goal: make the common case free and offline, reserve the paid frontier model
for the hard case. Every meal request falls down a cascade and stops at the
first tier that answers.

```
0. Personal cache        local   $0   "you've logged this before"
1. Barcode → OpenFoodFacts local/free  packaged food, exact
2. Local USDA food DB     local   $0   whole foods + typed meals
3. On-device model        local   $0   iOS 26+ Apple Foundation Models
                                        (splits/parses messy text; Android/older
                                        falls back to Dart rules)
4. Gemini (proxy)         cloud  ~$0.002  escalation only: ambiguous photos,
                                        unmatched multi-item meals
```

Design rule: **a database beats an LLM for nutrition** — USDA numbers are
ground truth and don't hallucinate. The model's only job is to *understand the
input* (parse text, classify a photo); the numbers come from the DB. Keep the
biometric side (recovery, HRV, averages) pure arithmetic — never an LLM.

## Platform floor

iOS 26+ **and** older iOS + Android are all supported. On-device Apple
Foundation Models are used **only** on iOS 26+ (guarded `@available`); every
other platform gets the same result through the Dart parser + USDA DB + Gemini
fallback, so behaviour degrades in cost, never in capability.

## Tier 1 — Local USDA resolver + personal cache (this milestone, C1)

- **Data**: `assets/nutrition/foods.json` — curated per-100g macros
  (kcal/protein/carbs/fat/fiber), aliases, and portion→grams hints for the most
  commonly logged foods. Structured so the full USDA FoodData Central SR
  dataset can be dropped in later without code change.
- **Resolver** (`lib/domain/food_db.dart`, pure): normalize → split a meal into
  items ("quinoa with spinach and 2 egg whites" → 3) → parse each item's
  portion (counts, cups, tbsp, ml, g, oz, slices, "half/quarter") → fuzzy-match
  to a food → macros = per100g × grams/100. Sum items. **All items must match
  locally or the whole meal escalates** (never return an undercount).
- **Personal cache** (Drift table, schema v4): normalized query → resolved
  macros. Checked before any tier; written after any successful resolve
  (including Gemini), so a repeat or previously-hard meal is $0 next time.
- **Cascade**: `MealEstimator.estimate()` becomes cache → USDA local → LLM.
  Gemini only runs when the local tiers give up.

## Tier 2 — Barcode (C2)

`mobile_scanner` reads the barcode on-device; Open Food Facts (free, no key)
returns exact per-100g nutriments → MealEstimate → cache. A "Scan barcode"
action in the log sheet.

## Tier 3 — Apple Foundation Models (C3)

Swift `MethodChannel` → `FoundationModels` `LanguageModelSession` with a
guided-generation schema returning `{items:[{name,quantity}]}`. Gated
`@available(iOS 26.0, *)`; the Dart side probes availability and falls back to
the rule parser otherwise. Feeds tier 2's DB — the model parses, the DB counts.

## Tier 4 — On-device photo classifier (C4)

On-device food classification (Core ML / ML Kit) with a confidence gate; matched
labels resolve through the USDA DB. Gemini vision runs only when on-device
confidence is low or the plate is multi-item. Photos are the one place offline
is a real accuracy downgrade today, so Gemini stays the quality path there —
just no longer the default.

## Unit economics

Target: 80–90% of food requests resolve in tiers 0–3 at $0. Per-user AI cost
falls from ~$0.30/mo toward ~$0.03–0.05/mo, and **marginal cost declines with
scale** as the personal + popular-food caches fill — the inverted cost curve
that makes the business durable.

## Verify

Pure resolver + cache are unit-tested (portion math, multi-item sum, escalation
on unmatched item, cache hit). Native tiers (Apple model, scanner) compile with
availability guards and are verified live on device.
