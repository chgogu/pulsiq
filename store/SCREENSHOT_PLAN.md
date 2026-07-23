# Screenshot plan

Three captures are in `store/screenshots/` and all pass App Store Connect's
size check (1290x2796, accepted for the 6.9" slot). They are technically
uploadable. They also undersell the app, and it's worth one more pass.

## What the current three show

| File | Screen | Problem |
|---|---|---|
| `01.png` | Dashboard — score 64, fuel ring, "Today's read", hydration | Strongest of the three. But the score badge reads **"Fuel-only"** and fiber/carbs/fat all read **0/…**, so it reads as a barely-used app. |
| `02.png` | Pulse card, quote, today's log | The top third is **"No wearable data yet. Connect Apple Health"**. The first thing a browser sees is a feature that isn't on. |
| `03.png` | "Log something" sheet | Good feature showcase (snap, barcode, food/drink/water/move), but every field is empty and the dimmed card behind it is *again* "No wearable data yet". |

Two of three lead with an empty-state prompt to connect a health app. The
product's actual argument — food and biometrics on one screen — does not
appear anywhere.

## Reshoot with integrations on

Turning Apple Health back on is the single change that fixes most of this. It
replaces the "No wearable data" card with real HRV, resting HR, sleep and
steps, clears the "Fuel-only" badge, and unlocks the analytics card and trend
chart, which is the most visually distinctive screen in the app.

Also log a couple of meals first, so the macro bars aren't zeros.

Shoot in this order:

1. **Dashboard, populated** — score without the "Fuel-only" badge, fuel ring
   with real macros. This is the hero; App Store shows it first.
2. **Health analytics card + trend chart** — scroll so the 30-day chart and
   the metric chips are both visible. Nothing else in the category looks like
   this.
3. **Snap a meal → result** — the estimate with per-item calories and macros,
   *after* analysis, not the empty capture screen. This is the headline
   feature and it currently isn't shown at all.
4. **Nutrition detail** — the day's fuel breakdown.
5. **Log something sheet** — current `03.png` is fine, but grab it over a
   populated dashboard rather than the empty-state card.
6. **Integrations** — Apple Health and WHOOP connected, showing the app is a
   hub rather than another silo.

Then:

```bash
./tools/store/prepare_screenshots.sh ~/Downloads
```

## If you'd rather ship these three

They will pass review — nothing here is a rejection risk. Order them
`01` (dashboard), `03` (log sheet), `02` (log list), because leading with the
"No wearable data" card is the weakest possible opening frame.
