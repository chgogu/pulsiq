# PulsIQ — Landing Page Prompt for Lovable (v2 — active/live page)

Completely rebuild this as an **active, live product landing page** — not a pre-launch/waitlist page. PulsIQ is available now. Remove all "early access," "waitlist," and "coming soon" framing entirely. Every primary CTA should be "Get PulsIQ" / "Download for iOS" style language, not "get early access."

**Platform focus for this version: iOS only.** Do not add or mention Android or Google Play anywhere on the page yet — no Android badges, no "coming to Android" teasers, nothing. iOS-only messaging and an App Store-style CTA (the actual App Store link/badge can be a placeholder for now since the app isn't listed yet, but the page should read and function as if iOS is the one and only platform).

## The core pitch — get this exactly right

PulsIQ is the **one place to track your entire health picture** — not another app you add to a pile of apps. The core idea:

1. **Snap a photo of your meal** → PulsIQ tells you the calories and nutrition instantly.
2. That nutrition and hydration data is then **combined in real time with your heart rate, HRV, recovery, and sleep** — pulled in from whatever you already use: WHOOP, Apple Health, or Google Health Connect.
3. The result: **one single dashboard** that connects what you eat and drink to what your body is actually doing — instead of a separate nutrition app, a separate WHOOP app, a separate Apple Health app that never talk to each other.

This "one stop, not app-hopping" idea is the single most important message on the page — it should come through clearly in the hero and get its own dedicated section, not just a line item in a features list. The contrast to draw: today people bounce between 3-4 different apps to piece together their health picture; PulsIQ is the one place all of it lives together, connected.

## Brand — open to reinvention, but keep it premium

You are free to **redesign the logo, the color palette, and the overall visual direction** — the previous dark-navy-and-red direction should be replaced. Requirements for the new direction:

- **No black or near-black backgrounds.** The page should feel light, warm, and inviting to open — not clinical or heavy. Think a calm, premium wellness brand (Oura's website, Whoop's lighter marketing pages, Headspace's calm-but-premium feel) rather than a dark "biohacker dashboard" look.
- **Soft, subtle, good-to-look-at colors** — gentle gradients or a warm neutral base (soft creams, warm off-whites, soft sage/blue/coral accent tones) rather than saturated red-on-black. The palette should feel calming and make someone want to linger, not feel like a warning system.
- Still premium and "billion-user" in production quality — generous whitespace, confident large typography, smooth scroll-triggered motion, a polished animated product visualization in the hero (since there's no real app video yet, build a beautiful animated mockup: a phone frame showing a meal photo turning into a nutrition card, then flowing into a heart-rate/recovery ring animation, visually showing the "meal → biometrics, connected" story).
- Keep the name **PulsIQ** and the tagline concept of biometric intelligence, but the logo mark and full color system should be freshly designed to fit the new, softer direction. Propose a clean wordmark plus a simple icon (a pulse/heartbeat line integrated into an "S" or a simple radial/ring mark both work well) in the new palette.
- Rounded, soft UI throughout — large corner radii, no hard shadows, gentle elevation.

## Page structure (active-product framing)

1. **Hero** — PulsIQ wordmark, a confident headline built around the "one place for your whole health picture" idea (not a generic tagline), a short subhead explaining snap-a-meal + real-time biometrics in one sentence, a primary CTA "Download for iOS" (App Store badge/link placeholder), and the animated meal→biometrics phone mockup as the visual centerpiece. Soft warm background, no black.
2. **The problem** — brief, confident: today your nutrition app, your WHOOP app, and your Apple Health app don't talk to each other, so you never see the full picture. Reframe as "stop switching apps."
3. **The one-stop dashboard** (its own dedicated, prominent section — this is the heart of the pitch) — show how a meal photo becomes calories/macros, and how that connects immediately to your heart rate, HRV, recovery, and sleep pulled from your connected wearable, all in one view. This should feel like the visual and narrative climax of the page.
4. **Core features** (cards, each visually distinct):
   - Snap a meal — photograph or describe food, calories and full nutrition estimated instantly, most of it processed on-device
   - Real-time biometrics — heart rate, HRV, recovery, and sleep, always current
   - Connect once, see everything — works with WHOOP, Apple Health, and Google Health Connect (mention these as data sources the app reads from — this is not an Android feature callout, just naming the integrations available to an iOS user, e.g. Apple Health is native and Google Health Connect data can still be viewed by an iOS-using household/traveler if relevant — keep this light and factual, not a platform promise)
   - Voice logging — hold a button, say what you ate or how you feel, done
5. **Privacy section** — prominent. Health data is encrypted on your device before it's ever backed up; even we can't read it. No ads, no selling data. Trust badges: "End-to-end encrypted", "No ads, ever", "Delete everything, anytime".
6. **Final CTA section** — a strong, simple "Download PulsIQ for iOS" repeat of the App Store CTA. No email capture, no waitlist form anywhere on the page.
7. **Footer** — PulsIQ wordmark, Privacy Policy link (stub page), Contact (mailto: privacy@pulsiq.app), small print "PulsIQ is a wellness companion, not a medical device.", copyright "© 2026 VeeC Labs".

## Explicitly remove from the previous version

- All "early access," "waitlist," "be first to try," and email-capture forms/sections — delete entirely.
- Any Supabase waitlist table wiring tied to email capture — remove that logic since there's no signup form anymore.
- The black/near-black dark-mode-only hero background and the red/navy palette.
- Any Android or Google Play mention.

## Functional requirements

- Fully responsive, mobile-first.
- Fast load; the hero animation should feel premium but not bloat load time — lazy-load below-the-fold motion.
- SEO meta tags: title "PulsIQ — Your whole health picture, in one place", meta description built around the snap-a-meal + real-time biometrics + one-dashboard pitch, Open Graph image using the new palette.
- Do not include: pricing, Android/Play Store references, testimonials, countdown timers, fake scarcity, or specific numeric health claims (no "improve HRV by X%").
