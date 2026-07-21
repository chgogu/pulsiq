// PulsIQ LLM proxy — Gemini backend.
//
// Holds the Google AI Studio API key server-side so the app never does
// (spec §0: no API keys in the app). Runs locally on the dev Mac for
// on-device testing; the same handlers port to a Supabase Edge Function.
//
//   GEMINI_API_KEY=... node server.mjs
//
// Binds 0.0.0.0 so the iPhone can reach it over the LAN.

import { createServer } from 'node:http';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { GoogleGenAI } from '@google/genai';

const PORT = Number(process.env.PORT ?? 8790);
// Vision-capable, fast, and current. Override with GEMINI_MODEL if needed;
// `node list-models.mjs` prints what the key can actually reach.
const MODEL = process.env.GEMINI_MODEL ?? 'gemini-3.6-flash';

const here = dirname(fileURLToPath(import.meta.url));
const SYSTEM_PROMPT = readFileSync(
  join(here, '../../assets/pulsiq_system_prompt.txt'),
  'utf8',
);

const apiKey = process.env.GEMINI_API_KEY ?? process.env.GOOGLE_API_KEY;
if (!apiKey) {
  console.error(
    'Missing GEMINI_API_KEY. Get one free at https://aistudio.google.com/apikey\n' +
      'Then run:  GEMINI_API_KEY=your_key npm start',
  );
  process.exit(1);
}
const ai = new GoogleGenAI({ apiKey });

// Gemini responseSchema — guarantees schema-valid nutrition JSON, so the
// Flutter client never has to cope with a malformed estimate.
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

function mediaTypeOf(b64) {
  if (b64.startsWith('/9j/')) return 'image/jpeg';
  if (b64.startsWith('iVBOR')) return 'image/png';
  if (b64.startsWith('R0lGOD')) return 'image/gif';
  if (b64.startsWith('UklGR')) return 'image/webp';
  return 'image/jpeg';
}

// Transient transport failures to the Gemini endpoint ("fetch failed") are
// retried — a single dropped socket shouldn't cost the user their photo.
async function generate({ parts, schema, attempts = 3 }) {
  let lastErr;
  for (let i = 1; i <= attempts; i++) {
    try {
      const response = await ai.models.generateContent({
        model: MODEL,
        contents: [{ role: 'user', parts }],
        config: {
          systemInstruction: SYSTEM_PROMPT,
          responseMimeType: 'application/json',
          responseSchema: schema,
        },
      });
      if (i > 1) console.log(`  (succeeded on attempt ${i})`);
      return response.text;
    } catch (err) {
      lastErr = err;
      const cause = err?.cause;
      console.warn(
        `  attempt ${i}/${attempts} failed: ${err?.message ?? err}` +
          (cause ? ` | cause: ${cause.code ?? ''} ${cause.message ?? ''}` : ''),
      );
      if (i < attempts) await new Promise((r) => setTimeout(r, 1200 * i));
    }
  }
  throw lastErr;
}

async function mealVision({ image, hint }) {
  const parts = [];
  if (image) {
    const mimeType = mediaTypeOf(image);
    console.log(
      `  image: ${(image.length / 1024 / 1024).toFixed(2)} MB base64, ` +
        `${mimeType}${hint ? `, hint="${hint}"` : ''}`,
    );
    parts.push({ inlineData: { mimeType, data: image } });
  } else {
    console.log(`  no image${hint ? `, hint="${hint}"` : ''}`);
  }
  parts.push({
    text:
      'Identify every distinct food item in this meal and estimate its ' +
      'nutrition. Judge portion size from visual cues (plate, utensil, and ' +
      'hand scale). Give realistic, usable numbers rather than hedged ones. ' +
      'Use confidence "low" only if the image is genuinely unclear.' +
      (hint ? `\n\nThe user says this is: ${hint}` : ''),
  });
  return generate({ parts, schema: MEAL_SCHEMA });
}

async function coach({ text }) {
  return generate({
    parts: [
      {
        text:
          'Parse this voice log into the structured JSON contract and write ' +
          'a short, energy-framed coaching message. Estimate realistic ' +
          'nutrition for every food item from typical portions — the app ' +
          'adds these into the day\'s totals, so give usable numbers rather ' +
          `than zeros.\n\n${text}`,
      },
    ],
    schema: COACH_SCHEMA,
  });
}

async function orderHack({ text }) {
  return generate({
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

createServer((req, res) => {
  const send = (code, obj) => {
    const body = JSON.stringify(obj);
    res.writeHead(code, {
      'content-type': 'application/json',
      'content-length': Buffer.byteLength(body),
    });
    res.end(body);
  };

  if (req.method === 'GET' && req.url === '/health') {
    return send(200, { ok: true, provider: 'gemini', model: MODEL });
  }
  const handler = ROUTES[req.url ?? ''];
  if (req.method !== 'POST' || !handler) return send(404, { error: 'no route' });

  const chunks = [];
  req.on('data', (c) => chunks.push(c));
  req.on('end', async () => {
    const started = Date.now();
    try {
      const payload = JSON.parse(Buffer.concat(chunks).toString('utf8'));
      const reply = await handler(payload);
      console.log(`${req.url} ok in ${Date.now() - started}ms`);
      send(200, { reply });
    } catch (err) {
      // `fetch failed` hides the real reason in .cause — surface it.
      const cause = err?.cause;
      console.error(
        `${req.url} FAILED after ${Date.now() - started}ms:`,
        err?.message ?? err,
        cause ? `| cause: ${cause.code ?? ''} ${cause.message ?? cause}` : '',
      );
      send(502, { error: String(err?.message ?? err) });
    }
  });
}).listen(PORT, '0.0.0.0', () => {
  console.log(`PulsIQ proxy (Gemini) on http://0.0.0.0:${PORT}`);
  console.log(`Model: ${MODEL}`);
  console.log('Routes: /v1/meal-vision  /v1/coach  /v1/order-hack  /health');
});
