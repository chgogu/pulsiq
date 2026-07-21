/// One day of wearable telemetry (read-only v1 scope, spec §0).
class DailyBiometrics {
  const DailyBiometrics({
    required this.day,
    this.restingHr,
    this.hrvMs,
    this.respiratoryRate,
    this.sleepHours,
    this.sleepEfficiencyPct,
    this.steps,
    this.zone2Minutes,
  });

  final DateTime day;
  final double? restingHr;
  final double? hrvMs;
  final double? respiratoryRate;
  final double? sleepHours;
  final double? sleepEfficiencyPct; // 0–100
  final int? steps;
  final int? zone2Minutes;
}
