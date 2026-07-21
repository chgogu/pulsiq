/// Evening forecast (spec §3): at 7pm, synthesize the day's fuel + movement
/// + current biometric trend into a predicted sleep-quality line that cites
/// its strongest signal, keeping the "biometric intelligence" promise
/// concrete. Pure logic; the card and notification consume it.
library;

import 'baseline_engine.dart';

class ForecastInput {
  const ForecastInput({
    required this.rhr,
    required this.hrv,
    this.exerciseMinutes = 0,
    this.denseFuelCount = 0,
    this.lateCaffeine = false,
    this.hydrationProgress = 0,
  });

  final BaselineResult rhr;
  final BaselineResult hrv;
  final int exerciseMinutes;
  final int denseFuelCount;
  final bool lateCaffeine;
  final double hydrationProgress; // 0..1
}

class Forecast {
  const Forecast({required this.headline, required this.signal});

  /// e.g. "Tonight looks like a solid recovery night".
  final String headline;

  /// The strongest cited signal, e.g. "your HRV has been climbing all
  /// afternoon".
  final String signal;
}

Forecast computeForecast(ForecastInput input) {
  // Score positive/negative signals; the largest-magnitude one is cited.
  final signals = <({double weight, String text, bool positive})>[];

  // Biometric signals dominate lifestyle inputs — a real ±20% HRV swing or
  // a hot RHR should out-weigh "you walked" (keeps the biometric-first
  // promise concrete).
  final hrvDelta = input.hrv.delta7;
  if (hrvDelta != null && input.hrv.avg7 != null) {
    final rel = hrvDelta / input.hrv.avg7!;
    if (rel > 0.05) {
      signals.add((
        weight: rel * 3,
        text: 'your HRV has been riding over baseline all day',
        positive: true,
      ));
    } else if (rel < -0.05) {
      signals.add((
        weight: -rel * 3,
        text: 'your HRV dipped under baseline today',
        positive: false,
      ));
    }
  }

  final rhrDelta = input.rhr.delta7;
  if (rhrDelta != null) {
    if (rhrDelta > 3) {
      signals.add((
        weight: rhrDelta / 8,
        text: 'your resting heart rate is running '
            '${rhrDelta.round()} over baseline',
        positive: false,
      ));
    } else if (rhrDelta < -2) {
      signals.add((
        weight: rhrDelta.abs() / 8,
        text: 'your heart has been calmer than usual',
        positive: true,
      ));
    }
  }

  if (input.exerciseMinutes >= 20) {
    signals.add((
      weight: 0.4,
      text: 'you moved for ${input.exerciseMinutes} minutes today',
      positive: true,
    ));
  }
  if (input.denseFuelCount >= 2) {
    signals.add((
      weight: 0.35,
      text: 'a couple of carb-dense meals are still settling',
      positive: false,
    ));
  }
  if (input.lateCaffeine) {
    signals.add((
      weight: 0.3,
      text: 'that late caffeine may keep your system revved',
      positive: false,
    ));
  }

  if (signals.isEmpty) {
    return const Forecast(
      headline: 'Tonight looks steady',
      signal: 'nothing today is pulling your recovery in either direction',
    );
  }

  signals.sort((a, b) => b.weight.compareTo(a.weight));
  final strongest = signals.first;
  final positiveScore = signals
      .where((s) => s.positive)
      .fold(0.0, (sum, s) => sum + s.weight);
  final negativeScore = signals
      .where((s) => !s.positive)
      .fold(0.0, (sum, s) => sum + s.weight);

  final String headline;
  if (positiveScore - negativeScore > 0.3) {
    headline = 'Tonight looks like a solid recovery night';
  } else if (negativeScore - positiveScore > 0.3) {
    headline = 'Tonight might run a little restless';
  } else {
    headline = 'Tonight looks like a steady, ordinary night';
  }
  return Forecast(headline: headline, signal: strongest.text);
}
