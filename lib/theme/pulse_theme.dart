import 'package:flutter/material.dart';

/// PulsIQ palette: one warm "pulse" accent over calm, near-neutral surfaces.
abstract final class PulseColors {
  static const pulse = Color(0xFFFF3B5C);
  static const pulseDeep = Color(0xFFD91E44);
  static const deepNight = Color(0xFF0B1220);
  static const nightCard = Color(0xFF151F31);
  static const mist = Color(0xFFF6F8FB);
}

ThemeData pulsiqTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: PulseColors.pulse,
    brightness: brightness,
  ).copyWith(surface: dark ? PulseColors.deepNight : PulseColors.mist);

  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  return base.copyWith(
    scaffoldBackgroundColor: scheme.surface,
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
