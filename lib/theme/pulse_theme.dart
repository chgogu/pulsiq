import 'package:flutter/material.dart';

/// PulsIQ palette — the same brand values the pulsiqapp.com landing page
/// uses, so the app and the site read as one product.
abstract final class PulseColors {
  /// Landing-page `--coral`: the primary brand accent.
  static const pulse = Color(0xFFF2593E);

  /// Deeper coral for pressed/contrast states.
  static const pulseDeep = Color(0xFFD1401F);

  /// Landing-page `--gold`: the far end of the logo gradient.
  static const gold = Color(0xFFF0A63C);

  static const deepNight = Color(0xFF0B1220);
  static const nightCard = Color(0xFF151F31);
  static const mist = Color(0xFFF6F8FB);

  /// The logo gradient, coral → gold, matching the site's `#lg` linear
  /// gradient. Used by [PulsIQMark] and anywhere the brand mark is drawn.
  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [pulse, gold],
  );
}

/// The brand typeface, bundled from `assets/fonts` (see pubspec).
const pulsiqFontFamily = 'Bricolage';

ThemeData pulsiqTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: PulseColors.pulse,
    brightness: brightness,
  ).copyWith(surface: dark ? PulseColors.deepNight : PulseColors.mist);

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: pulsiqFontFamily,
  );
  return base.copyWith(
    scaffoldBackgroundColor: scheme.surface,
    // The site sets display type at 800 with tight tracking; mirror that so
    // headings carry the same voice here.
    textTheme: base.textTheme.copyWith(
      displayLarge: _display(base.textTheme.displayLarge),
      displayMedium: _display(base.textTheme.displayMedium),
      displaySmall: _display(base.textTheme.displaySmall),
      headlineLarge: _display(base.textTheme.headlineLarge),
      headlineMedium: _display(base.textTheme.headlineMedium),
      headlineSmall: _display(base.textTheme.headlineSmall),
      titleLarge: _display(base.textTheme.titleLarge, weight: FontWeight.w700),
    ),
    cardTheme: base.cardTheme.copyWith(
      elevation: 0,
      color: dark ? PulseColors.nightCard : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.zero,
    ),
    snackBarTheme: base.snackBarTheme.copyWith(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}

TextStyle? _display(TextStyle? s, {FontWeight weight = FontWeight.w800}) =>
    s?.copyWith(fontWeight: weight, letterSpacing: -0.5);
