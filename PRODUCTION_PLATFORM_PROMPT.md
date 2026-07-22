# PulsIQ → global platform build prompt

Turn PulsIQ from a solid local-first personal app into a **billion-user, global,
multi-tenant platform**: cloud accounts, role-based access, a pluggable
integrations hub, zero-knowledge encrypted sync, transactional email, an admin
plane, and worldwide compliance — without losing the offline-first,
privacy-first, cost-disciplined foundation already built.

Ship in milestones P1–P8. Keep the app runnable and offline-capable at every
commit. Verify each milestone before starting the next.

---

## §0 — Non-negotiables (decisions locked; do not re-litigate)

- **Backend: Supabase** (Postgres + Auth + Edge Functions + Storage + Realtime).
  Already the locked pick (DECISIONS.md). The dev Mac proxy is retired in P1 in
  favour of Supabase Edge Functions for the LLM/vision/WHOOP proxy so the app
  works off-LAN, worldwide.
- **Auth: Google Sign-In only.** No passwords anywhere. Passkeys/biometric
  unlock stay as the local device gate. Sign-in is mandatory to sync; a local
  "continue without account" mode still works fully offline (no cloud).
- **Data isolation: Postgres Row-Level Security (RLS)** keyed on `auth.uid()`.
  Every user-owned row is scoped so one user can never read another's data — at
  the database layer, not just app code.
- **Encryption: zero-knowledge for health data.** Health logs, meals, and
  biometrics are encrypted **client-side** (AES-256-GCM, `CryptoService` +
  `KeyVault` already built) before any upload; the backend stores **ciphertext
  only** and can never read them — not even an admin. Keys live in the Secure
  Enclave / Android Keystore and never leave the device. TLS 1.3 in transit.
- **Offline-first preserved.** Cloud is for auth, cross-device sync, encrypted
  backup, the LLM proxy, and integrations. Everything else runs on-device; the
  offline nutrition cascade (cache → USDA → on-device model → Gemini) stays the
  default.
- **No PII in URLs, query strings, logs, or analytics events.**
- **Admin ≠ data access.** An admin can see operational metrics (counts, health
  of the system) but **never** individual users' health data — zero-knowledge
  holds for everyone, including the owner acting as admin.

## §0.1 — Decisions

**Locked (owner-confirmed):**
1. **Admin = metrics only.** An admin sees operational metrics/counts, never any
   individual's health data. Zero-knowledge encryption is absolute for everyone.
2. **Key recovery = opt-in recovery passphrase.** Argon2id-derived key wraps a
   copy of the data key so a user can restore on a new device; the backend never
   holds the key. Lose device AND passphrase = unrecoverable (documented).

**Still open (recommendation given; not blocking):**
3. **Email provider** — Resend (recommended, simple), SendGrid, or Supabase SMTP.
4. **China** — PIPL + Great Firewall + Gemini/Google unavailability make China a
   separate track. **Recommend excluding China at launch**; revisit with a local
   partner.

---

## §1 — Accounts, Google Sign-In, and user count

- Google Sign-In is the only cloud auth path (Supabase Auth Google provider).
  On success the app holds a Supabase session (JWT with a `role` claim).
- **First sign-in provisioning** (Supabase Auth hook / Edge Function on user
  create), atomic:
  1. Insert a `profiles` row: `id = auth.uid()`, `email`, `display_name`,
     `created_at`, `region`, `role = 'end_user'` (default).
  2. Increment the global signup counter (see §8).
  3. Enqueue the welcome email (§5).
- The existing "continue without account" local mode remains; connecting an
  account later migrates local data up (encrypted) on first sync.
- **Sign-up = a new `profiles` row.** User count is `count(profiles)`; DAU/MAU
  come from a lightweight `last_active_at` touch (no per-action tracking).

## §2 — Roles & access management (RBAC)

- **Roles: `admin`, `end_user`.** Stored on `profiles.role`, surfaced as a
  custom JWT claim so RLS and Edge Functions can enforce it.
- **Everyone who downloads the app is `end_user` by default.**
- **The owner is seeded `admin`** (by matching the owner's Google email in a
  server-side allowlist — never a client flag).
- **Owner's two profiles (personas), one Google account:**
  - **End-user persona** — the owner's own health data, identical to any user.
  - **Admin persona** — the platform admin plane (§8): metrics only.
  - A **profile switcher** in the app toggles personas. Switching to admin never
    exposes any user's health data (including the owner's own is shown only in
    the end-user persona). This is a *view* switch on one account, not two logins.
- **Enforcement, defense-in-depth:** RLS policies (`auth.uid()` for own data;
  `role = 'admin'` for the metrics views) **and** Edge Function role checks
  **and** client-side gating. The database is the source of truth.

## §3 — Integrations hub (Settings → Integrations)

- Replace the single "WHOOP" Settings row with an **"Integrations"** screen.
- A **provider registry** drives a list of tiles, each with: name, icon, what
  data it contributes, connection state (connected / not connected / needs
  reconnect), last-synced, and connect/disconnect. All providers implement the
  existing `HealthSource` seam.
- Launch tiles: **WHOOP** (built), **Apple Health** (§4), **Google Health
  Connect** (Android, permissions already declared). Registry is extensible for
  **Oura, Garmin, Fitbit, Samsung Health** later without UI rewrites.
- Source-priority resolution stays (Demo > a connected provider > none), now
  surfaced as which integration is "leading" your biometrics.

## §4 — Apple Health: payment & enablement plan

1. **Enroll in the Apple Developer Program** — $99/yr, **Individual** entity
   (not Organization; Organization needs a D-U-N-S number). developer.apple.com/
   programs/enroll with the owner's Apple ID. Identity verification is minutes to
   ~48 h. This is a **per-developer-account** fee, not per user; users pay $0.
2. Re-add the `com.apple.developer.healthkit` entitlement + HealthKit capability
   (documented, ready to restore), rebuild with paid signing — which also ends
   the 7-day free-provisioning expiry.
3. HealthKit read scope (v1): steps, resting HR, HRV, respiratory rate, sleep,
   active energy. Usage strings already present.
4. Ship prerequisites: App Store review (health apps get extra scrutiny),
   privacy nutrition labels, the privacy policy (§9). No writing to HealthKit in
   v1 (read-only).

## §5 — Welcome email on first sign-in

- Triggered once, on account creation (§1), via an Edge Function → email
  provider (§0.1). Idempotent (never twice per user).
- **Content — genuine, not marketing:** a warm welcome; a short, real piece of
  health content (e.g., what resting HR / HRV actually tell you, why steady
  fuel beats crash diets); an invitation to set one goal in-app; a plain list of
  what PulsIQ gives them (biometric intelligence, snap-a-meal that works offline
  and free, integrations with their wearable, private-by-design). A one-line
  "wellness companion, not medical advice" disclaimer. A footer with the privacy
  policy link and an unsubscribe (CAN-SPAM / GDPR compliant). Transactional only
  — no marketing blasts without explicit opt-in.
- Localized to the user's region/language where available (§7).

## §6 — Zero-knowledge encrypted cloud sync

- Per-user **data-encryption key (DEK)**, generated on-device, wraps every
  health record (AES-256-GCM; reuse `CryptoService`). The DEK is itself wrapped
  by a **key-encryption-key (KEK)** held in the Secure Enclave / Keystore.
- Sync uploads **ciphertext blobs + non-sensitive metadata** (timestamps, type
  for ordering) to Supabase; RLS scopes them to the owner. The server never sees
  plaintext or keys.
- **Recovery (per §0.1 decision):** if opt-in recovery is chosen, an
  Argon2id-derived key from a user passphrase wraps a copy of the DEK, stored as
  ciphertext — so a new device can restore without the backend ever holding the
  key. Losing both device and passphrase = unrecoverable (documented, by design).
- Conflict handling: last-writer-wins per record with a vector of `updated_at`;
  local-first optimistic, background reconcile.

## §7 — Global scale & compliance (billion users)

- **i18n/l10n:** Flutter `intl` + ARB message catalogs, RTL support, locale-aware
  numbers/dates, metric/imperial per region. Prioritize top languages first.
- **Regional privacy law:** GDPR (EU), UK-GDPR, CCPA/CPRA (California), LGPD
  (Brazil), PIPEDA (Canada), APPI (Japan), etc. Provide the rights all of them
  share: **access, export, delete** (export + delete already built), consent
  records, and a data-processing basis. Cookie/consent not applicable (native
  app, no tracking cookies).
- **Data residency:** EU users' data in an EU Supabase region; US in US; add
  regions as markets open. Route by `profiles.region`.
- **Scale/infra:** Edge Functions autoscale; Postgres connection pooling
  (Supavisor); read replicas; CDN for static; per-user + global **rate limiting**
  and bot protection on sign-up. The **offline cost cascade is the moat** — at a
  billion users, keeping ~85%+ of nutrition requests at $0 is what makes unit
  economics survive; Gemini spend stays in the tail.
- **Observability:** Sentry (crash/error), privacy-respecting product analytics
  (no health data, no PII), uptime + cost dashboards.
- **Abuse:** rate limits, anomaly detection on signup spikes, App Check /
  Play Integrity to blunt fake accounts inflating the user count.

## §8 — Admin plane

- Admin persona (§2) sees **operational metrics only**, from RLS-guarded
  aggregate views: total users, new signups over time, DAU/MAU, retention,
  integration-connection rates, regional distribution, backend cost, error
  rates. **Never** any individual's health data or decrypted content.
- Realtime user-count tile (the owner's explicit ask), backed by `count(profiles)`
  + a signups-per-day series.
- Admin actions are **audited** (who, what, when) in an append-only log.

## §9 — Privacy policy (deliverable)

Produce a real, hosted privacy policy covering: data collected (Google email +
name; health logs and biometrics — **encrypted, zero-knowledge**; integration
data; minimal usage analytics); how each is used; that health data is encrypted
client-side and unreadable by us; sub-processors (Google Sign-In, Google Gemini
for meal analysis of photos/text the user submits, Open Food Facts, and the
wearable APIs the user connects); retention; the user's rights (access, export,
delete) and how to exercise them; regional rights (GDPR/CCPA/…); 13+ age gate;
security posture; and contact. Host it at a stable HTTPS URL (needed for the App
Store, Google OAuth consent, and the integrations). Link it from onboarding, the
welcome email, and Settings.

---

## §10 — Milestones

- **P1 — Cloud foundation.** Supabase project; migrate the proxy to Edge
  Functions (LLM/vision/WHOOP off-LAN); Google Sign-In → Supabase session;
  `profiles` table + RLS; first-sign-in provisioning; signup counter.
- **P2 — RBAC & admin persona.** Roles + JWT claim; owner admin seed; profile
  switcher; RLS/Edge role enforcement; admin audit log.
- **P3 — Integrations hub.** Settings → Integrations screen; provider registry;
  WHOOP tile migrated; Google Health Connect tile.
- **P4 — Apple Health.** (After enrollment.) Entitlement restored; HealthKit
  read; Apple Health tile; paid signing (no more 7-day expiry).
- **P5 — Welcome email.** Edge Function + provider; genuine content; idempotent;
  localized; unsubscribe.
- **P6 — Zero-knowledge sync.** DEK/KEK envelope; encrypted backup/restore;
  optional recovery passphrase; conflict reconcile.
- **P7 — Global.** i18n/l10n; data residency routing; regional-rights flows;
  rate limiting, App Check/Play Integrity, observability.
- **P8 — Admin dashboard + launch prep.** Metrics views + user-count UI; privacy
  policy hosted; App Store / Play data-safety; cost + scale hardening.

## §11 — What NOT to build

- Don't break offline-first or make the app require an account to function
  locally.
- Don't let **any** role (admin included) read users' health data — zero-
  knowledge is absolute.
- Don't add password auth. Google Sign-In only.
- Don't put roles or entitlements on the client as the source of truth — server
  decides.
- Don't over-engineer regions/languages before launch; ship GDPR+CCPA-clean
  globally, add residency and locales as markets open.
- Don't send marketing email — welcome/transactional only, with unsubscribe.
- Don't inflate scope with a web app or social features yet.

## §12 — Verify

Pure logic unit-tested (RBAC decisions, provisioning, encryption round-trips,
email-trigger idempotency). RLS policies tested with per-role Postgres sessions.
Edge Functions integration-tested. i18n snapshot-tested. Manual: real Google
sign-in on device, admin/end-user persona switch, an integration connect, a
welcome email received, encrypted round-trip to a second device.
