import 'package:flutter/material.dart';

import '../domain/nutrition.dart';

/// Macro categorical palette — the first four slots of the validated
/// data-viz reference palette (CVD-safe all-pairs in light and dark). Every
/// bar that uses these is also directly labeled, so identity never rests on
/// color alone.
abstract final class MacroColors {
  static const _protein = (Color(0xFF2A78D6), Color(0xFF3987E5)); // blue
  static const _carbs = (Color(0xFFEDA100), Color(0xFFC98500)); // yellow
  static const _fat = (Color(0xFFE87BA4), Color(0xFFD55181)); // magenta
  static const _fiber = (Color(0xFF008300), Color(0xFF008300)); // green

  static Color of(MacroKind kind, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final pair = switch (kind) {
      MacroKind.protein => _protein,
      MacroKind.carbs => _carbs,
      MacroKind.fat => _fat,
      MacroKind.fiber => _fiber,
      MacroKind.calories => _protein, // unused; calories use the brand hue
    };
    return dark ? pair.$2 : pair.$1;
  }

  static String label(MacroKind kind) => switch (kind) {
        MacroKind.calories => 'Calories',
        MacroKind.protein => 'Protein',
        MacroKind.fiber => 'Fiber',
        MacroKind.carbs => 'Carbs',
        MacroKind.fat => 'Fat',
      };
}
