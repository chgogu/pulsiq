/**
 * PulsIQ API — the Gemini + WHOOP proxy, on Cloudflare Workers.
 *
 * This is the hosted replacement for tools/proxy/server.mjs, which only ever
 * ran on a Mac on the user's LAN. A shipped app can't reach that, so every
 * AI and WHOOP feature was dead outside the developer's own Wi-Fi.
 *
 * Same contract as the Node proxy, route for route, so the Flutter client
 * needed no changes beyond its base URL and an auth header. Secrets live in
 * Worker secrets and never reach the app (spec §0: no API keys in the client).
 */
import SYSTEM_PROMPT from './system_prompt.txt';

const GEMINI_API = 'https://generativelanguage.googleapis.com/v1beta/models';
const DEFAULT_MODEL = 'gemini-3.6-flash';

const WHOOP_TOKEN_URL = 'https://api.prod.whoop.com/oauth/oauth2/token';
const WHOOP_AUTH_URL = 'https://api.prod.whoop.com/oauth/oauth2/auth';
// v2 — v1 was fully deprecated in Oct 2025.
const WHOOP_API = 'https://api.prod.whoop.com/developer/v2';
const WHOOP_REDIRECT = 'pulsiq://whoop-callback';
// `offline` is what makes WHOOP mint a refresh token; without it access dies
// in ~1h with no renewal.
const WHOOP_SCOPES =
  'offline read:recovery read:cycles read:sleep read:workout ' +
  'read:profile read:body_measurement';
const WHOOP_RESOURCES = new Set([
  'recovery',
  'cycle',
  'activity/sleep',
  'activity/workout',
]);

// ---------------------------------------------------------------- schemas --
// Gemini responseSchema guarantees schema-valid JSON, so the Flutter client
// never has to cope with a malformed estimate.

const MEAL_SCHEMA = {
  type: 'OBJECT',
  properties: {
    confidence: { type: 'STRING', enum: ['high', 'medium', 'low'] },
    items: {
      type: 'ARRAY',
      items: {
        type: 'OBJECT',
        properties: {
          name: { type: 'STRING' },
          portion: { type: 'STRING' },
          calories: { type: 'NUMBER' },
          protein_g: { type: 'NUMBER' },
          fiber_g: { type: 'NUMBER' },
          carbs_g: { type: 'NUMBER' },
          fat_g: { type: 'NUMBER' },
          quality_score: {
            type: 'STRING',
            enum: ['clean', 'moderate', 'dense'],
          },
        },
        required: [
          'name', 'portion', 'calories', 'protein_g',
          'fiber_g', 'carbs_g', 'fat_g', 'quality_score',
        ],
      },
    },
    note: { type: 'STRING' },
  },
  required: ['confidence', 'items', 'note'],
};

const ORDER_HACK_SCHEMA = {
  type: 'OBJECT',
  properties: {
    headline: { type: 'STRING' },
    top_picks: {
      type: 'ARRAY',
      items: {
        type: 'OBJECT',
        properties: {
          name: { type: 'STRING' },
          why: { type: 'STRING' },
          energy_rating: {
            type: 'STRING',
            enum: ['steady', 'moderate', 'spike'],
          },
        },
        required: ['name', 'why', 'energy_rating'],
      },
    },
  },
  required: ['headline', 'top_picks'],
};

const COACH_SCHEMA = {
  type: 'OBJECT',
  properties: {
    log_summary: {
      type: 'OBJECT',
      properties: {
        food_items: {
          type: 'ARRAY',
          items: {
            type: 'OBJECT',
            properties: {
              name: { type: 'STRING' },
              quantity: { type: 'STRING' },
              quality_score: {
                type: 'STRING',
                enum: ['clean', 'moderate', 'dense'],
              },
              // Required so a spoken log feeds the same fuel analytics a
              // photographed one does.
              calories: { type: 'NUMBER' },
              protein_g: { type: 'NUMBER' },
              fiber_g: { type: 'NUMBER' },
              carbs_g: { type: 'NUMBER' },
              fat_g: { type: 'NUMBER' },
            },
            required: [
              'name', 'quantity', 'quality_score', 'calories',
              'protein_g', 'fiber_g', 'carbs_g', 'fat_g',
            ],
          },
        },
        beverages: {
          type: 'ARRAY',
          items: {
            type: 'OBJECT',
            properties: {
              name: { type: 'STRING' },
              sugar_content_g: { type: 'NUMBER' },
              type: {
                type: 'STRING',
                enum: ['water', 'caffeine', 'alcohol', 'protein'],
              },
            },
            required: ['name', 'sugar_content_g', 'type'],
          },
        },
        hydration_added_ml: { type: 'NUMBER' },
        exercise_logged: {
          type: 'ARRAY',
          items: {
            type: 'OBJECT',
            properties: {
              activity: { type: 'STRING' },
              duration_minutes: { type: 'NUMBER' },
              intensity: {
                type: 'STRING',
                enum: ['low', 'moderate', 'vigorous'],
              },
            },
            required: ['activity', 'duration_minutes', 'intensity'],
          },
        },
      },
      required: [
        'food_items', 'beverages', 'hydration_added_ml', 'exercise_logged',
      ],
    },
    energy_impact_analysis: {
      type: 'OBJECT',
      properties: {
        glycemic_load_estimate: {
          type: 'STRING',
          enum: ['flat', 'steady', 'high_spike'],
        },
        post_meal_action_required: { type: 'BOOLEAN' },
        recommended_walk_minutes: { type: 'NUMBER' },
      },
      required: [
        'glycemic_load_estimate',
        'post_meal_action_required',
        'recommended_walk_minutes',
      ],
    },
    coaching_message: { type: 'STRING' },
  },
  required: ['log_summary', 'energy_impact_analysis', 'coaching_message'],
};

// ----------------------------------------------------------------- gemini --

function mediaTypeOf(b64) {
  if (b64.startsWith('/9j/')) return 'image/jpeg';
  if (b64.startsWith('iVBOR')) return 'image/png';
  if (b64.startsWith('R0lGOD')) return 'image/gif';
  if (b64.startsWith('UklGR')) return 'image/webp';
  return 'image/jpeg';
}

/**
 * Calls Gemini's REST API directly rather than through @google/genai — the SDK
 * pulls in Node built-ins that don't exist on Workers.
 *
 * Retries transient transport failures: a single dropped socket shouldn't cost
 * the user their photo.
 */
async function generate(env, { parts, schema, attempts = 3 }) {
  const model = env.GEMINI_MODEL || DEFAULT_MODEL;
  const url = `${GEMINI_API}/${model}:generateContent`;
  const body = JSON.stringify({
    contents: [{ role: 'user', parts }],
    systemInstruction: { parts: [{ text: SYSTEM_PROMPT }] },
    generationConfig: {
      responseMimeType: 'application/json',
      responseSchema: schema,
    },
  });

  let lastErr;
  for (let i = 1; i <= attempts; i++) {
    try {
      const res = await fetch(url, {
        method: 'POST',
        headers: {
          'content-type': 'application/json',
          'x-goog-api-key': env.GEMINI_API_KEY,
        },
        body,
      });
      const json = await res.json();
      if (!res.ok) {
        // A 4xx is our bug or a bad key — retrying just burns time.
        const message = json?.error?.message ?? `HTTP ${res.status}`;
        if (res.status < 500) throw new Error(`gemini: ${message}`);
        lastErr = new Error(`gemini ${res.status}: ${message}`);
      } else {
        const text = json?.candidates?.[0]?.content?.parts
          ?.map((p) => p.text ?? '')
          .join('');
        if (text) return text;
        // A response with no text usually means a safety block or a hit
        // token ceiling; surface the reason rather than an empty string.
        const reason = json?.candidates?.[0]?.finishReason ?? 'no_content';
        throw new Error(`gemini returned no content (${reason})`);
      }
    } catch (err) {
      lastErr = err;
      if (String(err.message).startsWith('gemini:')) throw err;
    }
    if (i < attempts) await new Promise((r) => setTimeout(r, 1200 * i));
  }
  throw lastErr ?? new Error('gemini: exhausted retries');
}

async function mealVision(env, { image, hint }) {
  const parts = [];
  if (image) {
    parts.push({ inlineData: { mimeType: mediaTypeOf(image), data: image } });
  }
  // Two modes: a photo to read, or a written description to estimate from.
  // The contract is identical so the app treats both the same way.
  parts.push({
    text: image
      ? 'Identify every distinct food item in this meal and estimate its ' +
        'nutrition. Judge portion size from visual cues (plate, utensil, ' +
        'and hand scale). Give realistic, usable numbers rather than hedged ' +
        'ones. Use confidence "low" only if the image is genuinely unclear.' +
        (hint ? `\n\nThe user says this is: ${hint}` : '')
      : 'Estimate the nutrition of this described meal. Break it into its ' +
        'distinct components and give one item per food, with realistic ' +
        'portions inferred from any amounts stated (e.g. "2 egg whites", ' +
        '"half avocado") or typical serving sizes otherwise. Give usable ' +
        'numbers, not zeros. Set confidence by how specific the ' +
        `description is.\n\nThe meal: ${hint}`,
  });
  return generate(env, { parts, schema: MEAL_SCHEMA });
}

async function coach(env, { text }) {
  return generate(env, {
    parts: [
      {
        text:
          'Parse this voice log into the structured JSON contract and write ' +
          'a short, energy-framed coaching message. Estimate realistic ' +
          'nutrition for every food item from typical portions — the app ' +
          "adds these into the day's totals, so give usable numbers rather " +
          `than zeros.\n\n${text}`,
      },
    ],
    schema: COACH_SCHEMA,
  });
}

async function orderHack(env, { text }) {
  return generate(env, {
    parts: [
      {
        text:
          'Here is a menu. Return the top 3 picks that maximize long, ' +
          `steady energy, each with a one-line reason.\n\n${text}`,
      },
    ],
    schema: ORDER_HACK_SCHEMA,
  });
}

const ROUTES = {
  '/v1/meal-vision': mealVision,
  '/v1/coach': coach,
  '/v1/order-hack': orderHack,
};

// ------------------------------------------------------------------ whoop --

async function whoopToken(env, params) {
  const body = new URLSearchParams({
    client_id: env.WHOOP_CLIENT_ID,
    client_secret: env.WHOOP_CLIENT_SECRET,
    ...params,
  });
  const res = await fetch(WHOOP_TOKEN_URL, {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body,
  });
  const text = await res.text();
  let json;
  try {
    json = JSON.parse(text);
  } catch {
    json = { error: 'non_json_response', detail: text.slice(0, 200) };
  }
  return { status: res.status, json };
}

async function whoopFetch({ accessToken, resource, start, end, nextToken }) {
  const qs = new URLSearchParams({ limit: '25' });
  if (start) qs.set('start', start);
  if (end) qs.set('end', end);
  if (nextToken) qs.set('nextToken', nextToken);
  const res = await fetch(`${WHOOP_API}/${resource}?${qs}`, {
    headers: { authorization: `Bearer ${accessToken}` },
  });
  const text = await res.text();
  let json;
  try {
    json = JSON.parse(text);
  } catch {
    json = { records: [], _parse_error: text.slice(0, 120) };
  }
  return { status: res.status, json };
}

// ----------------------------------------------------------------- router --

const json = (status, obj) =>
  new Response(JSON.stringify(obj), {
    status,
    headers: { 'content-type': 'application/json' },
  });

/**
 * The Worker is a public URL in front of a metered API key, so an unauthorized
 * caller would be spending the owner's Gemini quota. A shared token shipped in
 * the app is not real authentication — it can be pulled out of the binary —
 * but it stops drive-by and scripted abuse. Per-IP rate limiting in the
 * Cloudflare dashboard is the second layer; see workers/api/README.md.
 */
function authorized(request, env) {
  if (!env.PULSIQ_APP_TOKEN) return true; // unset = open, for local dev only
  const header = request.headers.get('authorization') ?? '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : '';
  if (token.length !== env.PULSIQ_APP_TOKEN.length) return false;
  // Constant-time-ish compare: don't leak the token through timing.
  let diff = 0;
  for (let i = 0; i < token.length; i++) {
    diff |= token.charCodeAt(i) ^ env.PULSIQ_APP_TOKEN.charCodeAt(i);
  }
  return diff === 0;
}

/**
 * Per-IP rate limit. The AI routes get the tighter bucket because each call is
 * a metered Gemini request; WHOOP routes are cheap passthroughs and only need
 * to be stopped from being hammered.
 *
 * Fails open on purpose: if the limiter itself is unavailable, a real user
 * losing their meal photo is worse than an attacker getting a burst through.
 */
// Per IP, per minute. Deliberately well under the *account-wide* Gemini
// ceiling (the free tier allows 20 requests/minute across the whole key), so
// one heavy user can't starve everyone else. A real session peaks around 5:
// a meal snap, a re-snap, a voice log, a menu scan.
const AI_LIMIT = 10;
const API_LIMIT = 120; // per minute, per IP — cheap passthroughs

/**
 * Counts requests per IP per minute in the colo cache.
 *
 * This is the layer that actually enforces. Cloudflare's Rate Limiting
 * *binding* is also wired below, but on this account it never returned
 * `success: false` — 12 sequential calls against a limit of 5 all passed — so
 * relying on it alone would have shipped a limiter that does nothing.
 *
 * The cache is per-colo, which is the right granularity anyway: a single
 * abusive IP lands in one colo, so its counter is the one that matters.
 * Read-modify-write can lose a few increments under heavy concurrency; that
 * costs a handful of extra requests, not the bound.
 */
async function cacheCounterExceeded(ip, path, limit) {
  const window = Math.floor(Date.now() / 60000);
  // Must be a real URL for the Cache API, and one that can't collide with a
  // route we actually serve.
  const key = new Request(
    `https://ratelimit.pulsiq.internal/${encodeURIComponent(ip)}/${window}/${
      limit === AI_LIMIT ? 'ai' : 'api'
    }`,
  );
  const cache = caches.default;
  const hit = await cache.match(key);
  const count = hit ? Number(await hit.text()) || 0 : 0;
  if (count >= limit) return true;
  await cache.put(
    key,
    new Response(String(count + 1), {
      // Expire with the window, so counters can't accumulate forever.
      headers: { 'cache-control': 'max-age=60' },
    }),
  );
  return false;
}

/**
 * Per-IP rate limit. AI routes get the tighter bucket because each call is a
 * metered Gemini request; WHOOP routes are cheap passthroughs.
 *
 * Fails open on purpose: if the limiter itself breaks, a real user losing
 * their meal photo is worse than an attacker getting a burst through.
 */
async function rateLimited(request, env, path) {
  const isAi = Boolean(ROUTES[path]);
  const ip = request.headers.get('cf-connecting-ip') ?? 'unknown';
  const limit = isAi ? AI_LIMIT : API_LIMIT;

  try {
    if (await cacheCounterExceeded(ip, path, limit)) return true;
  } catch {
    // fall through to the binding
  }

  // Defence in depth: costs nothing, and takes over properly if the binding
  // starts enforcing on this account.
  const binding = isAi ? env.AI_LIMITER : env.API_LIMITER;
  if (!binding) return false;
  try {
    const { success } = await binding.limit({ key: `${ip}:${isAi ? 'ai' : 'api'}` });
    return !success;
  } catch {
    return false;
  }
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const path = url.pathname;
    const method = request.method;

    if (method === 'GET' && path === '/health') {
      return json(200, {
        ok: true,
        provider: 'gemini',
        model: env.GEMINI_MODEL || DEFAULT_MODEL,
        whoop: env.WHOOP_CLIENT_ID ? 'configured' : 'not_configured',
        runtime: 'cloudflare-workers',
      });
    }

    if (!authorized(request, env)) return json(401, { error: 'unauthorized' });

    if (await rateLimited(request, env, path)) {
      return new Response(
        JSON.stringify({ error: 'rate_limited' }),
        {
          status: 429,
          headers: { 'content-type': 'application/json', 'retry-after': '60' },
        },
      );
    }

    // Non-secret WHOOP client config so the app can build the authorize URL
    // (client_id is public in OAuth; only the secret stays server-side).
    if (method === 'GET' && path === '/v1/whoop/config') {
      if (!env.WHOOP_CLIENT_ID) return json(503, { error: 'whoop_not_configured' });
      return json(200, {
        client_id: env.WHOOP_CLIENT_ID,
        redirect_uri: env.WHOOP_REDIRECT_URI || WHOOP_REDIRECT,
        authorize_url: WHOOP_AUTH_URL,
        scopes: WHOOP_SCOPES,
      });
    }

    if (method === 'POST' && path === '/v1/whoop/fetch') {
      try {
        const p = await request.json();
        if (!p.access_token || !WHOOP_RESOURCES.has(p.resource)) {
          return json(400, { error: 'bad_request' });
        }
        const { status, json: body } = await whoopFetch({
          accessToken: p.access_token,
          resource: p.resource,
          start: p.start,
          end: p.end,
          nextToken: p.next_token,
        });
        return json(status === 200 ? 200 : 502, body);
      } catch (err) {
        return json(502, { error: String(err?.message ?? err) });
      }
    }

    const grant =
      method === 'POST' && path === '/v1/whoop/exchange'
        ? 'authorization_code'
        : method === 'POST' && path === '/v1/whoop/refresh'
          ? 'refresh_token'
          : null;
    if (grant) {
      if (!env.WHOOP_CLIENT_ID || !env.WHOOP_CLIENT_SECRET) {
        return json(503, { error: 'whoop_not_configured' });
      }
      try {
        const p = await request.json();
        const params =
          grant === 'authorization_code'
            ? {
                grant_type: 'authorization_code',
                code: p.code,
                redirect_uri:
                  p.redirect_uri ?? env.WHOOP_REDIRECT_URI ?? WHOOP_REDIRECT,
              }
            : {
                grant_type: 'refresh_token',
                refresh_token: p.refresh_token,
                scope: WHOOP_SCOPES,
              };
        const { status, json: body } = await whoopToken(env, params);
        // Pass WHOOP's status through so the app can tell "bad code" from
        // "network down".
        return json(status === 200 ? 200 : 502, body);
      } catch (err) {
        return json(502, { error: String(err?.message ?? err) });
      }
    }

    const handler = ROUTES[path];
    if (method !== 'POST' || !handler) return json(404, { error: 'no route' });

    if (!env.GEMINI_API_KEY) return json(503, { error: 'gemini_not_configured' });
    try {
      const payload = await request.json();
      const reply = await handler(env, payload);
      return json(200, { reply });
    } catch (err) {
      return json(502, { error: String(err?.message ?? err) });
    }
  },
};
