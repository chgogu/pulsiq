# Nutrition dataset build

`assets/nutrition/foods.json` = curated common foods (pri 0, hand-tuned aliases
+ portions) merged with USDA FoodData Central SR Legacy generic foods (pri 1).
Curated entries win match ties.

## Regenerate / expand

1. Download SR Legacy CSV from https://fdc.nal.usda.gov/download-datasets
   (FoodData_Central_sr_legacy_food_csv_*.zip) and unzip.
2. Keep the current curated file as the priority source, then merge:

   python3 tools/nutrition/build_foods.py \
     <usda_csv_dir> assets/nutrition/foods.json /tmp/foods_merged.json
   cp /tmp/foods_merged.json assets/nutrition/foods.json

The script pulls per-100g macros (energy/protein/carbs/fat/fiber), derives a
clean short alias per food, extracts cup/tbsp/tsp/ml/oz portion weights, and
tags USDA rows pri=1. Foods whose primary alias already exists in the curated
set are skipped so hand-tuned entries stay authoritative.
