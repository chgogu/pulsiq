# PulsIQ ↔ WHOOP integration spec

Connect WHOOP as a biometric source so the PulsIQ Score runs on real HRV,
resting HR, recovery, strain, and sleep — **without** Apple HealthKit (and so
without the paid Apple Developer Program). WHOOP is a network API, not a
HealthKit provider, so it lights up the score on a free-signed build.

## OAuth model (from WHOOP docs)

- **Confidential client, no PKCE** → the `client_secret` is required and the
  token exchange MUST run server-side. Fits the existing proxy (§0: no secrets
  in the app).
- Authorization URL: `https://api.prod.whoop.com/oauth/oauth2/auth`
- Token URL: `https://api.prod.whoop.com/oauth/oauth2/token`
- Scopes: `read:recovery read:cycles read:sleep read:workout
  read:body_measurement` **plus `offline`** — `offline` is what makes WHOOP
  return a refresh token. Without it, access dies in ~1 hour with no renewal.
- `state`: ≥8 chars, random, checked on return (CSRF guard).
- Access token is short-lived (`expires_in`); refresh invalidates the old one.

## Credentials & secret handling

- Live only in `~/.pulsiq_whoop.env` (mode 600): `WHOOP_CLIENT_ID`,
  `WHOOP_CLIENT_SECRET`. Loaded by the proxy, never compiled into the app,
  never printed. Same discipline as `~/.pulsiq_gemini_key`.
- **Refresh token is user data** → stored encrypted on device via KeyVault,
  not in the proxy. The proxy is stateless; it only ever *uses* the secret to
  exchange/refresh, and hands tokens back to the app.

## Redirect

- Register **`pulsiq://whoop-callback`** in the WHOOP dashboard (custom schemes
  are allowed per the docs — `whoop://example/redirect` form). The current
  `https://whoop.com` placeholder must be changed to this before any login can
  complete.
- App side: `flutter_web_auth_2` opens `ASWebAuthenticationSession` (iOS) /
  Custom Tab (Android) and returns the callback URL with `?code=&state=`.
  Register the scheme in `Info.plist` (CFBundleURLTypes) and the Android
  manifest intent-filter.

## Flow

1. App builds the auth URL (client_id, redirect, scope incl. `offline`, random
   `state`) and opens it via `flutter_web_auth_2`.
2. User approves in WHOOP; callback returns to `pulsiq://whoop-callback?code=…`.
   App verifies `state`, extracts `code`.
3. App POSTs `{code}` to proxy **`/v1/whoop/exchange`**. Proxy calls the token
   URL with client_id/secret/redirect_uri/`grant_type=authorization_code`,
   returns `{access_token, expires_in, refresh_token}`.
4. App stores the refresh token in KeyVault; keeps the access token in memory.
5. **Data calls go app-direct** to WHOOP with the Bearer access token (data
   endpoints need no secret). On 401/expiry, app POSTs the refresh token to
   proxy **`/v1/whoop/refresh`** → new tokens.

Proxy gains exactly two secret-bearing routes: `/v1/whoop/exchange` and
`/v1/whoop/refresh`. Nothing else server-side.

## WHOOP data → app model

Fetch and map into the existing `HealthSample` (lib/domain/health_models.dart):

| WHOOP | endpoint | → app field |
|---|---|---|
| recovery.score.hrv_rmssd_milli | `/v1/recovery` | `hrvMs` |
| recovery.score.resting_heart_rate | `/v1/recovery` | `restingHr` |
| recovery.score.recovery_score | `/v1/recovery` | new `recoveryPct` (score signal) |
| cycle.score.strain / avg_heart_rate | `/v1/cycle` | day strain, avg HR |
| sleep duration | `/v1/activity/sleep` | `sleepHours` |
| workout (type, strain) | `/v1/activity/workout` | exercise minutes/intensity |
| body_measurement (height/weight/max_hr) | `/v1/user/measurement/body` | seed the body profile |

`body_measurement` is a nice tie-in: it can pre-fill the height/weight in the
body-profile screen we just built.

## Where it plugs in

- New `WhoopHealthSource` implementing the same interface as
  `PlatformHealthSource` / `EmptyHealthSource`. When WHOOP is connected it
  becomes the biometric source the baseline engine and PulsIQ Score consume —
  the score stops being "fuel-only".
- Settings gains a "Connect WHOOP" row (connect / disconnect / last-synced).
  Source priority: WHOOP > Apple Health (if ever enabled) > Demo > Empty.

## Verify

- Unit tests: token-response parsing, each WHOOP payload → HealthSample
  mapping, `state` mismatch rejection, refresh-on-401.
- Manual: real OAuth on the phone, confirm the score leaves "fuel-only" and the
  Pulse card shows WHOOP HRV/RHR.

## What the owner must do (can't be automated)

1. Paste `client_id` + `client_secret` into `~/.pulsiq_whoop.env` (not chat).
2. In the WHOOP dashboard, change the redirect from `https://whoop.com` to
   `pulsiq://whoop-callback`.
3. Do the one-time login on the phone when the build is ready.
