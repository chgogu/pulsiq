# PulsIQ Privacy Policy

**Effective date:** [EFFECTIVE_DATE]
**Last updated:** [LAST_UPDATED]

> **Before publishing:** fill every `[BRACKETED]` placeholder and have this
> reviewed by a lawyer for your markets. This is a thorough, accurate draft of
> how PulsIQ actually handles data — it is not legal advice, and privacy law
> varies by region.

PulsIQ ("**PulsIQ**", "**we**", "**us**") is a biometric-first wellness
companion operated by **VeeC Labs**, [ENTITY_ADDRESS]. This policy
explains what we collect, how we use it, and the rights you have. Questions:
**pulsiq.app@gmail.com**.

**PulsIQ is a wellness product, not a medical device.** Nothing in the app is
medical advice, diagnosis, or treatment.

---

## 1. The short version

- We sign you in with **Google** — no passwords, ever.
- Your **health data is encrypted on your device** before it ever reaches our
  servers. We store only ciphertext and **cannot read it** — not our staff, not
  our administrators. This is "zero-knowledge" encryption.
- Most nutrition analysis happens **on your device, offline**. We send data to
  our AI provider only for the meals our on-device tools can't resolve, and only
  the content you chose to submit (a meal photo or description).
- We **do not sell your data** and we **do not serve ads**.
- You can **export or permanently delete** everything, any time, from Settings.

## 2. Who this applies to

This policy applies to the PulsIQ mobile app on iOS and Android and its backend
services. You must be **at least 13 years old** (or the minimum age in your
country — 16 in parts of the EU) to use PulsIQ.

## 3. Data we collect

**Account data (when you sign in with Google).** Your email address and display
name from your Google account, and a unique account identifier. We never receive
your Google password.

**Health and lifestyle data you log.** Meals and nutrition, hydration,
beverages, exercise, and biometric readings (resting heart rate, heart-rate
variability, respiratory rate, sleep, steps, recovery, strain). **This data is
encrypted on your device with a key only you hold** before any backup or sync;
we store it as ciphertext we cannot decrypt.

**Connected integrations (optional, only if you connect them).** If you link a
wearable or health platform — for example **WHOOP, Apple Health, or Google
Health Connect** — PulsIQ reads the health metrics you authorize from that
provider. You control the connection and can disconnect at any time. Data pulled
from integrations is treated as health data (encrypted as above).

**Content you submit for analysis.** When you use "Snap a meal" or type/speak a
meal that our on-device tools can't resolve, the **photo or text you submit** is
sent to our AI provider to estimate nutrition. We send only what you submit for
that request; we do not attach your identity, and we do not use it to build a
profile of you.

**Minimal usage and diagnostic data.** Aggregate, non-identifying signals such
as app version, crash reports, and coarse feature usage, used to keep the app
working and improve it. This never includes your health content and is not used
for advertising.

**We do not collect** your precise location, contacts, browsing history, or
advertising identifiers.

## 4. How we use your data

- To provide the app: log your data, compute your fuel/recovery analytics, run
  nutrition estimation, and sync/back up your encrypted data across your devices.
- To authenticate you (Google Sign-In) and keep your account secure.
- To send you **transactional email** — for example a one-time welcome message
  when you first sign in, and important service or security notices. We do not
  send marketing email without your explicit opt-in, and every email has an
  unsubscribe link.
- To operate and improve the service using aggregate, non-identifying metrics
  (e.g., total user counts, crash rates). Administrators can see these
  operational metrics **but can never read any individual's health data.**
- To meet legal obligations and enforce our terms.

We rely on the following legal bases where they apply (e.g., GDPR): performance
of our contract with you (providing the app), your consent (connecting an
integration, optional recovery, marketing email), and our legitimate interests
(security, aggregate improvement).

## 5. How your data is protected

- **Zero-knowledge encryption.** Health and lifestyle data is encrypted on your
  device with AES-256-GCM. The encryption key is generated on your device and
  stored in the device's secure hardware (Apple Secure Enclave / Android
  Keystore) and **never leaves your device in a form we can read.** Our servers
  store only ciphertext.
- **Optional recovery.** You may set a recovery passphrase so you can restore
  your encrypted history on a new device. It is derived with a strong function
  (Argon2id) and used to wrap a copy of your key; we still never see the key.
  **If you lose all your devices and your recovery passphrase, your encrypted
  history cannot be recovered — by design.**
- **In transit:** all network traffic uses TLS.
- **Access control:** data is isolated per user at the database layer
  (row-level security); one user can never access another's data.
- No security is perfect, but we design so that a breach of our servers exposes
  ciphertext we ourselves cannot read.

## 6. Who we share data with (sub-processors)

We do not sell your data. We share the minimum necessary with service providers
who process it on our behalf:

| Provider | Purpose | What it receives |
|---|---|---|
| **Google (Sign-In)** | Authentication | Your Google account identity |
| **Google (Gemini AI)** | Nutrition estimation | The meal photo/text you submit for a given analysis |
| **[BACKEND_PROVIDER, e.g. Supabase]** | Encrypted storage, hosting, auth | Ciphertext + account metadata |
| **[EMAIL_PROVIDER]** | Transactional email | Your email address and message content |
| **Open Food Facts** | Barcode lookups | The product barcode you scan (no personal data) |
| **Wearable APIs you connect** (WHOOP, etc.) | Your chosen integration | Handled per that provider's own policy |

We may also disclose data if required by law or to protect rights and safety.

## 7. International transfers and data residency

We aim to store your data in a region appropriate to you (for example, EU users'
data in the EU). Where data is transferred across borders, we use lawful
transfer mechanisms such as Standard Contractual Clauses. [ADJUST_TO_YOUR_SETUP]

## 8. How long we keep data

We keep your account and encrypted data while your account is active. When you
delete your account or your data, it is removed from our live systems promptly
and from backups within [BACKUP_RETENTION_WINDOW, e.g. 30 days]. Aggregate,
non-identifying metrics may be retained.

## 9. Your rights and choices

From **Settings** in the app you can, at any time:

- **Export** everything PulsIQ holds for you.
- **Permanently delete** all your data and keys from your device and our servers.
- **Connect or disconnect** any integration.
- **Manage** your recovery passphrase and biometric app lock.

Depending on where you live, you also have rights to **access, correct, delete,
restrict, or port** your data, to **object** to certain processing, and to
**withdraw consent**. To exercise rights not available in-app, contact
**pulsiq.app@gmail.com**; we respond within the time your law requires.

- **EU/EEA/UK (GDPR/UK-GDPR):** the rights above, plus the right to lodge a
  complaint with your supervisory authority.
- **California (CCPA/CPRA):** rights to know, delete, correct, and opt out of
  "sale"/"sharing" — we do not sell or share your personal information as those
  terms are defined, and we do not discriminate for exercising your rights.
- Similar rights apply under LGPD (Brazil), PIPEDA (Canada), APPI (Japan) and
  others.

## 10. Children

PulsIQ is not directed to children under 13 (or under 16 where required). We do
not knowingly collect data from them. If you believe a child has provided us
data, contact **pulsiq.app@gmail.com** and we will delete it.

## 11. Cookies and tracking

PulsIQ is a native mobile app. We do not use advertising cookies or cross-app
tracking, and we do not use advertising identifiers.

## 12. Changes to this policy

We will update this policy as the app evolves and post the new effective date
here. For material changes we will notify you in-app or by email.

## 13. Contact

**VeeC Labs**
[ENTITY_ADDRESS]
Privacy: **pulsiq.app@gmail.com**
[DATA_PROTECTION_OFFICER_OR_EU_REP, if applicable]
