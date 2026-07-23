/// Where the app's server-side AI and WHOOP calls go, and how they're
/// authorized.
///
/// Everything that needs a provider credential goes through this API — the
/// app itself holds no keys (spec §0). It used to be a Node process on the
/// developer's Mac, reachable only over the LAN; it's now a Cloudflare Worker
/// (`workers/api`) so a shipped build works anywhere.
library;

/// Production API. Overridable with `--dart-define=PULSIQ_PROXY_URL=...` for
/// pointing at a local `tools/proxy/server.mjs` during development.
///
/// This has a default on purpose: when it was `String.fromEnvironment` with no
/// fallback, a release built without the define compiled in an empty string
/// and silently broke WHOOP, voice logging, and meal photos with no error
/// anywhere.
const apiBaseUrl = String.fromEnvironment(
  'PULSIQ_PROXY_URL',
  defaultValue: 'https://api.pulsiqapp.com',
);

/// Shared token proving the caller is the app, compiled in via
/// `--dart-define=PULSIQ_APP_TOKEN=...`.
///
/// This is deliberately not treated as real authentication — anything shipped
/// in a binary can be extracted from it. It exists so the API isn't an open
/// relay in front of a metered Gemini key; per-IP rate limiting at the
/// Cloudflare edge is the layer that actually bounds abuse.
const apiAppToken = String.fromEnvironment('PULSIQ_APP_TOKEN');

/// Headers for a JSON request to the API.
Map<String, String> apiHeaders({bool json = true}) => {
      if (json) 'content-type': 'application/json',
      if (apiAppToken.isNotEmpty) 'authorization': 'Bearer $apiAppToken',
    };
