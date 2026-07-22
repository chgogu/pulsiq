#!/usr/bin/env python3
"""Merge USDA SR Legacy into PulsIQ's foods.json. Curated entries keep priority
(pri=0, hand-tuned aliases/portions); USDA adds breadth (pri=1)."""
import csv, json, re, sys

D = sys.argv[1]            # USDA csv dir
CURATED = sys.argv[2]      # existing foods.json
OUT = sys.argv[3]          # output foods.json

# nutrient ids
ENERGY = {"1008", "2047", "2048"}   # kcal (prefer 1008)
PROTEIN, FAT, CARB, FIBER = "1003", "1004", "1005", "1079"
MACRO_IDS = ENERGY | {PROTEIN, FAT, CARB, FIBER}

# measure_unit_id -> resolver measure word (only ones the app understands)
UNIT_WORD = {"1000": "cup", "1001": "tbsp", "1002": "tsp", "1004": "ml", "1009": "oz"}

QUALIFIERS = set((
    "raw cooked boiled steamed baked roasted fried grilled broiled fresh frozen "
    "canned dried dry prepared unprepared without with added salt unsalted salted "
    "sweetened unsweetened low reduced fat free light regular whole part skim "
    "nonfat lowfat drained solids liquid includes commercial ready-to-eat home "
    "recipe homemade concentrate types all and or the from in of made not enriched "
    "unenriched bleached unbleached fluid solid pieces chopped sliced ground stick "
    "flesh meat only skin edible portion new type large medium small").split())

def csv_rows(path):
    with open(path, newline="") as f:
        yield from csv.reader(f)

# --- macros per food ---
macros = {}   # fdc_id -> {nid: amount}
first = True
for row in csv_rows(f"{D}/food_nutrient.csv"):
    if first: first = False; continue
    fdc, nid, amt = row[1], row[2], row[3]
    if nid in MACRO_IDS and amt:
        try: macros.setdefault(fdc, {})[nid] = float(amt)
        except ValueError: pass

# --- portions -> unit grams + a representative serving ---
units_by = {}   # fdc_id -> {word: grams}
serving_g = {}  # fdc_id -> representative grams
first = True
for row in csv_rows(f"{D}/food_portion.csv"):
    if first: first = False; continue
    fdc, amount, mu_id, desc, modifier, gram = row[1], row[3], row[4], row[5], row[6], row[7]
    try:
        amt = float(amount) or 1.0; g = float(gram)
    except ValueError:
        continue
    if g <= 0: continue
    word = UNIT_WORD.get(mu_id)
    if word:
        units_by.setdefault(fdc, {})[word] = round(g / amt, 1)
    # a "serving" or first sensible portion becomes the default grams
    if fdc not in serving_g and (modifier.strip() == "serving" or word in ("cup",)):
        if 5 <= g <= 600: serving_g[fdc] = round(g)

def clean(s):
    return re.sub(r"[^a-z0-9%/ ]", " ", s.lower()).strip()

def derive_aliases(description):
    d = re.sub(r"\([^)]*\)", "", description.lower())
    parts = [p.strip() for p in d.split(",") if p.strip()]
    if not parts: return None, []
    category = clean(parts[0]).split()
    if not category: return None, []
    category = category[0]
    specific = None
    for p in parts[1:]:
        w = clean(p)
        if not w: continue
        head = w.split()[0]
        if head in QUALIFIERS or head[0].isdigit() or "%" in w or "/" in w:
            continue
        specific = head
        break
    aliases = set()
    if specific and specific != category:
        aliases.add(specific)
        aliases.add(f"{specific} {category}")
    else:
        aliases.add(category)
    aliases = {a for a in aliases if a and not a.isdigit() and len(a) >= 3}
    if not aliases: return None, []
    # primary display name: shortest clean alias, title-cased
    name = min(aliases, key=len)
    return name, sorted(aliases)

def quality(kcal, fat):
    if kcal <= 0: return "moderate"
    share = fat * 9 / kcal
    return "dense" if share > 0.42 else ("moderate" if share > 0.30 else "clean")

# --- curated (priority) ---
curated = json.load(open(CURATED))
foods = []
curated_aliases = set()
for e in curated["foods"]:
    e["pri"] = 0
    foods.append(e)
    for a in ([e["name"]] + e.get("aliases", [])):
        curated_aliases.add(clean(a))

# --- USDA entries ---
first = True
added = 0
seen_names = set(curated_aliases)
for row in csv_rows(f"{D}/food.csv"):
    if first: first = False; continue
    fdc, dtype, description = row[0], row[1], row[2]
    m = macros.get(fdc)
    if not m: continue
    kcal = next((m[i] for i in ("1008", "2047", "2048") if i in m), None)
    if kcal is None or kcal <= 0: continue
    name, aliases = derive_aliases(description)
    if not name: continue
    # skip if the primary alias is already covered by a curated (better) entry
    if name in seen_names: continue
    seen_names.add(name)
    fat = m.get(FAT, 0.0)
    entry = {
        "name": name,
        "aliases": aliases,
        "per100g": {
            "kcal": round(kcal, 1),
            "protein": round(m.get(PROTEIN, 0.0), 1),
            "carbs": round(m.get(CARB, 0.0), 1),
            "fat": round(fat, 1),
            "fiber": round(m.get(FIBER, 0.0), 1),
        },
        "units": units_by.get(fdc, {}),
        "defaultGrams": serving_g.get(fdc, 100),
        "quality": quality(kcal, fat),
        "pri": 1,
    }
    foods.append(entry)
    added += 1

out = {"_note": curated.get("_note", ""), "genericUnits": curated["genericUnits"], "foods": foods}
json.dump(out, open(OUT, "w"), separators=(",", ":"))
print(f"curated: {len(curated['foods'])}, usda added: {added}, total: {len(foods)}")
import os
print(f"size: {os.path.getsize(OUT)/1024/1024:.2f} MB")
