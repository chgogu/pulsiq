# PulsIQ — Landing Page Prompt for Lovable

**Biometric intelligence in real time.**

Build a marketing landing page for **PulsIQ**, a biometric-first, voice-first AI energy coach app for iOS and Android. This is a pre-launch landing page: the goal is to establish the domain (**pulsiq.app**), collect early-access signups, and host our privacy policy. There is no live app link yet — every CTA goes to an email-capture form.

## Brand

- **Name:** PulsIQ (always this capitalization — never "Pulsiq" or "PULSIQ")
- **Tagline:** "Biometric intelligence in real time"
- **One-line positioning:** Your pulse, interpreted intelligently — nutrition and hydration are inputs that explain what your biometrics show, not the main event.
- **Tone:** calm, confident, clinical-but-warm. No hype, no exclamation points, no "revolutionary AI" language. Think Oura/Whoop-adjacent — quiet competence, not a supplement-ad.
- **Positioning against the category:** most health apps make you log everything and guess what it means. PulsIQ reads your body first (HRV, resting heart rate, recovery, sleep) and explains your day through that lens — food and hydration are context, not the whole story.

## Visual identity — use these exact values

- **Primary accent ("pulse"):** `#FF3B5C`
- **Deep accent (pressed/hover states):** `#D91E44`
- **Dark surface:** `#0B1220` (near-black navy, not pure black)
- **Dark card surface:** `#151F31`
- **Light surface:** `#F6F8FB` (soft mist white, not pure white)
- Default to **dark mode as the primary/hero look** (navy `#0B1220` background, white text, the pulse red `#FF3B5C` as the one accent color — buttons, the logo mark, key numbers). Support a light mode toggle using the mist/white surfaces above, same accent.
- Rounded corners throughout (large radius, ~20px on cards) — soft, not sharp. No hard shadows; flat elevation, like Material 3 with elevation removed.
- Typography: a clean geometric sans (Inter, Manrope, or similar). Large, confident numbers for stats (e.g., a hero stat like "62 bpm" or "41ms HRV") in bold weight.
- Motif: a subtle heartbeat/pulse waveform line (like an ECG trace) as a recurring graphic element — in the hero background, section dividers, or behind the logo. Should feel organic, not a literal medical monitor.

## Page structure

1. **Hero**
   - Headline: "PulsIQ" (wordmark) + tagline "Biometric intelligence in real time"
   - Subhead: one or two sentences — your heart rate and recovery, read intelligently every day; nutrition and hydration explain what the numbers show.
   - Primary CTA: email input + "Get early access" button (no app store links — not live yet)
   - Secondary link: "How it works" (scrolls down)
   - Background: dark navy with a faint animated or static pulse-wave line graphic

2. **The problem** (brief, one short section)
   - Most health apps ask you to log everything and interpret nothing. PulsIQ flips that: your biometrics lead, everything else is context.

3. **How it works / core features** (3–4 cards, icon + short headline + 1-2 lines each)
   - **Biometric-first score** — a daily score built from your resting heart rate and HRV against your own baseline, not a generic target.
   - **Snap a meal** — photograph or describe what you ate; nutrition is estimated automatically, most of it entirely on your device at no cost to your privacy.
   - **Voice logging** — hold a button, say what you ate or how you feel, done.
   - **Connect your wearable** — works with WHOOP, Apple Health, and Google Health Connect; your pulse data flows in from what you already wear.

4. **Privacy section** (important — make this prominent, not buried)
   - Headline like "Your health data is yours. Literally."
   - Explain plainly: health data is encrypted on your device before it's ever backed up; even we can't read it. No ads, no selling data.
   - Small trust badges/icons: "End-to-end encrypted", "No ads", "You can delete everything, anytime"

5. **Early access / waitlist section**
   - Repeat the email capture with a slightly longer pitch: "Be first to try PulsIQ" + email input + button
   - Optional: a field for "iOS or Android?" as a dropdown (nice-to-have, not required)

6. **Footer**
   - PulsIQ wordmark
   - Links: Privacy Policy (placeholder link, page can be a simple stub for now), Contact (mailto: privacy@pulsiq.app)
   - Small print: "PulsIQ is a wellness companion, not a medical device."
   - Copyright: "© [current year] VeeC Labs"

## Functional requirements

- Fully responsive (mobile-first — most visitors will be on phones)
- Email capture form should actually store submissions (use whatever backend/waitlist mechanism Lovable supports — Supabase table, or a simple form service) so signups aren't lost
- Fast, minimal — no heavy animation libraries; a single subtle hero animation (pulse line, or a gently animating heartbeat graphic) is enough
- Include basic SEO meta tags: title "PulsIQ — Biometric intelligence in real time", meta description using the one-line positioning above, and an Open Graph image (can be a simple dark-navy card with the wordmark + tagline)
- Do not include: pricing, app store badges/links, testimonials, or any specific numeric health claims (no "improve HRV by X%" — we make no clinical claims)

## What NOT to do

- Don't invent features not listed above (no social feed, no leaderboard, no marketplace)
- Don't use stock photography of people exercising — prefer abstract/data-visualization style graphics consistent with the pulse-wave motif
- Don't make it feel like a supplement or crypto landing page (no countdown timers, no fake scarcity, no "limited spots")
