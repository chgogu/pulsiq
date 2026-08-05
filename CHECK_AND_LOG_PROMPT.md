# Spec: separate "Check" from "Log", and lift Today's log to the top

Two problems, one change set.

## 1. Today's log is buried

On open, the log sits at the very bottom of the dashboard — past WHOOP, Apple
Health, fuel, insights, hydration, walk, forecast, pulse, and spark cards. A
user who opens the app to log breakfast has to scroll the whole way down.

**Change:** move the "Today's log" section (header + Add + entries) to directly
below the PulsIQ Score hero, above the analytics cards. Logging is the daily
job; analytics are the reward for having logged. Order becomes:

1. Header (date, settings)
2. Morning reset (when due)
3. PulsIQ Score hero
4. **Quick actions row + Today's log** ← moved up
5. WHOOP / Apple Health cards
6. Fuel, insights, cut-down
7. Hydration, walk, forecast, pulse, spark

## 2. "Check" and "Log" are tangled

Today, Snap-a-meal and Scan-a-barcode always **log** the food, and also happen
to show a Yes/No verdict. But there are two distinct intents:

- **"Can I eat this?"** — at the store, before buying: scan/snap, get a straight
  Yes/No against my goals, walk away. I do **not** want it in my diary.
- **"Log what I ate"** — after eating: snap/scan/type, it goes in the diary and
  feeds my totals.

Mixing them confuses both. A store check shouldn't pollute the day's calories; a
log shouldn't make me hunt for a verdict.

**Change:** two clearly separate entry points.

### Log food (existing, unchanged in intent)
The current entry sheet → snap / scan / type / voice → review → **confirm to
diary**. The verdict banner may still appear as secondary context, but the
primary action is logging. Reached from the "Log food" button by Today's log.

### Can I eat this? (new — check only)
A dedicated `/check-food` screen focused on the decision:
- Two ways in: **Scan a barcode** (the store case) and **Take/choose a photo**.
- Runs the same recognition (Open Food Facts for barcode; on-device classifier
  / estimator for photo) but its output is the **verdict**, not a log:
  - Big **Yes / No** + one neutral one-liner (reuse `SafetyBanner` /
    `assessFood`).
  - The food name and a couple of key facts (calories, sugar).
  - Two actions: **Log it** (only now does it enter the diary) and **Check
    another**.
- If no health goals are set, it explains that a Yes/No needs goals and links to
  Settings → Health goals (the verdict is goal-based; without goals there's no
  answer).
- Nothing is written to the diary unless the user taps **Log it**.

Reached from a "Can I eat this?" button by Today's log, and from the Log sheet
as a distinct choice.

## Guardrails
- The verdict stays goal-based and neutral, and keeps the "general guidance, not
  medical advice" line (unchanged from the current banner).
- Offline-first: barcode uses Open Food Facts, photo uses the on-device path;
  no dependency on the paid tier for the check itself.
- Tests: dashboard shows Today's log above the analytics cards; the check flow
  computes a verdict and does not log until "Log it" is tapped.
