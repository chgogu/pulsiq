/// Dynamic hydration target (spec §3).
///
/// Base 2,000 ml, adjusted by:
///  (a) weather — heat and humidity raise the target,
///  (b) logged exercise minutes (~12 ml per minute ≈ 350 ml per 30 min),
///  (c) 1:1 ml offset for caffeine and alcohol volumes.
/// Result is rounded to 50 ml and clamped to a sane 1,500–5,000 ml band.
library;

class HydrationTargetInput {
  const HydrationTargetInput({
    this.tempC,
    this.humidityPct,
    this.exerciseMinutes = 0,
    this.caffeineMl = 0,
    this.alcoholMl = 0,
  });

  final double? tempC;
  final double? humidityPct;
  final int exerciseMinutes;
  final int caffeineMl;
  final int alcoholMl;
}

const baseHydrationMl = 2000;

int computeHydrationTargetMl(HydrationTargetInput input) {
  var target = baseHydrationMl.toDouble();
  final temp = input.tempC;
  if (temp != null) {
    if (temp >= 30) {
      target += 500;
    } else if (temp >= 25) {
      target += 250;
    }
    if (temp >= 25 && (input.humidityPct ?? 0) >= 70) target += 250;
  }
  target += input.exerciseMinutes * 12;
  target += input.caffeineMl + input.alcoholMl;
  final rounded = (target / 50).round() * 50;
  return rounded.clamp(1500, 5000);
}
