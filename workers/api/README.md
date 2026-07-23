# PulsIQ API (Cloudflare Worker)

`https://api.pulsiqapp.com` — the Gemini and WHOOP proxy the app talks to.

This replaces `tools/proxy/server.mjs`, which only ever ran on a Mac on the
developer's LAN. A shipped app can't reach that, so every AI and WHOOP feature
was dead for anyone who wasn't on that Wi-Fi — and App Transport Security would
have rejected cleartext HTTP to a private IP anyway. The Node proxy is kept for
local development; point a build at it with
`--dart-define=PULSIQ_PROXY_URL=http://<mac-ip>:8790`.

## Routes

| Route | Method | Purpose |
|---|---|---|
| `/health` | GET | Liveness + which model and whether WHOOP is configured. No auth. |
| `/v1/meal-vision` | POST | Meal photo *or* text description → per-item nutrition JSON |
| `/v1/coach` | POST | Voice-log text → structured log + coaching message |
| `/v1/order-hack` | POST | Menu text → top 3 steady-energy picks |
| `/v1/whoop/config` | GET | Non-secret OAuth client config for building the authorize URL |
| `/v1/whoop/exchange` | POST | Auth code → tokens (holds the client secret) |
| `/v1/whoop/refresh` | POST | Refresh token → new tokens |
| `/v1/whoop/fetch` | POST | Proxied WHOOP **v2** collection read |

Everything except `/health` requires `Authorization: Bearer <PULSIQ_APP_TOKEN>`.

## Secrets

Set with `wrangler secret put` — never committed, never printed.

| Secret | Source |
|---|---|
| `GEMINI_API_KEY` | `~/.pulsiq_gemini_key` |
| `WHOOP_CLIENT_ID` | `~/.pulsiq_whoop.env` |
| `WHOOP_CLIENT_SECRET` | `~/.pulsiq_whoop.env` |
| `PULSIQ_APP_TOKEN` | `~/.pulsiq_app_token` (also compiled into the app) |

```bash
cd workers/api
npx wrangler secret put GEMINI_API_KEY < ~/.pulsiq_gemini_key
```

## Deploy

```bash
./build_worker.sh && npx wrangler deploy
```

`build_worker.sh` copies `assets/pulsiq_system_prompt.txt` into `src/` as a
text module — a Worker has no filesystem, so the prompt is bundled rather than
read at boot. It's generated, so it's gitignored; run the script after changing
the prompt.

This Worker is **separate** from the marketing site Worker (`../../wrangler.jsonc`,
name `pulsiq`). Two names, two configs — deploying one must never overwrite the
other.

## On the app token

`PULSIQ_APP_TOKEN` is **not** real authentication. It ships inside the iOS
binary and anyone willing to unpack an IPA can read it. Its job is narrower:
stop this endpoint being a trivially discoverable open relay in front of a
metered Gemini key.

The layer that actually bounds abuse is the per-IP rate limit, which **is**
live: 10 requests/minute on the AI routes and 120 on the cheap ones, returning
429 with `retry-after`.

Note which mechanism enforces it. Cloudflare's Rate Limiting *binding* is
configured (`ratelimits` in wrangler.jsonc) but never returned
`success: false` on this account — 12 sequential calls against a limit of 5 all
passed. Shipping that alone would have been a limiter that does nothing, so the
enforcing layer is a per-colo cache counter in `src/index.js`. The binding is
kept as defence in depth and takes over cleanly if it starts working.

Both fail open: if the limiter breaks, a real user losing their meal photo is
worse than an attacker getting a burst through.

## Gemini quota is the real ceiling

The free tier allows **20 requests per minute across the whole key**, not per
user — one burst of testing exhausted it. The per-IP AI limit is deliberately
set to 10 so a single heavy user can't starve everyone, but that only rations a
ceiling that is far too low for a shipped app. **Enable billing on the Gemini
API key before launch.**

Proper per-user auth would mean issuing a token per account at sign-in and
verifying it here. That's the right end state once accounts exist.
