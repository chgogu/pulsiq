import '../domain/health_models.dart';
import '../domain/whoop.dart';

/// Where the dashboard's body-signals card got its numbers. The card is
/// deliberately not branded after any vendor (owner's call), but the copy has
/// to be honest about what each source can and can't measure.
enum BodySignalSource { whoop, appleHealth, healthConnect, demo }

extension BodySignalSourceCopy on BodySignalSource {
  String get label => switch (this) {
        BodySignalSource.whoop => 'WHOOP',
        BodySignalSource.appleHealth => 'Apple Health',
        BodySignalSource.healthConnect => 'Health Connect',
        BodySignalSource.demo => 'Demo data',
      };

  /// Only WHOOP scores recovery and strain; only the phone platforms count
  /// steps. Driving the UI off this keeps empty rows from showing up.
  bool get hasRecoveryAndStrain => this == BodySignalSource.whoop ||
      this == BodySignalSource.demo;

  bool get hasSteps => this == BodySignalSource.appleHealth ||
      this == BodySignalSource.healthConnect ||
      this == BodySignalSource.demo;

  String? get footnote => switch (this) {
        BodySignalSource.whoop =>
          'Steps show in the WHOOP app but aren\'t in its developer API yet, '
              'so they can\'t sync here — connect Apple Health for step counts.',
        BodySignalSource.appleHealth =>
          'Recovery and strain are WHOOP scores — connect WHOOP to add them '
              'alongside these.',
        BodySignalSource.healthConnect =>
          'Recovery and strain are WHOOP scores — connect WHOOP to add them '
              'alongside these.',
        BodySignalSource.demo => null,
      };
}

/// The card's payload: a window of days plus where they came from and how far
/// back the window reaches, so the heading can say "30-day averages" honestly
/// instead of hardcoding WHOOP's 60.
class BodySignals {
  const BodySignals({
    required this.body,
    required this.source,
    required this.windowDays,
  });

  final WhoopBody body;
  final BodySignalSource source;
  final int windowDays;

  bool get isEmpty => body.isEmpty;
}

/// The headline read for a source that has no recovery score. `whoopInsight`
/// would otherwise tell an Apple Health user their "recovery score lands after
/// your next logged sleep" — a score that source will never produce.
///
/// Reads today against the window's own averages, so it says something true
/// about the user rather than restating a number already on screen.
String platformInsight(WhoopDay today, WhoopBody window) {
  final hrv = today.hrvMs;
  final avgHrv = window.average((d) => d.hrvMs);
  final rhr = today.restingHr;
  final avgRhr = window.average((d) => d.restingHr);
  final sleep = today.sleepHours;

  if (hrv != null && avgHrv != null && avgHrv > 0) {
    final delta = (hrv - avgHrv) / avgHrv;
    if (delta >= 0.10) {
      return 'HRV is running above your usual — your system is well recovered. '
          'A good day to ask more of it.';
    }
    if (delta <= -0.10) {
      return 'HRV is below your usual. Keep today steady — hydration, food on '
          'time, and an early night.';
    }
  }
  if (rhr != null && avgRhr != null && rhr - avgRhr >= 3) {
    return 'Resting heart rate is up on your average — often the first sign of '
        'a hard day, poor sleep, or something brewing.';
  }
  if (sleep != null && sleep < 6) {
    return 'Short night at ${sleep.toStringAsFixed(1)}h. Expect appetite and '
        'energy to wobble — eat on schedule today.';
  }
  if (hrv != null || rhr != null || sleep != null) {
    return 'Your signals are sitting right around your normal range.';
  }
  return 'Connected — your metrics fill in as your phone syncs health data.';
}

/// Reshapes the platform health history into the same day model the card
/// already renders. HealthKit and Health Connect have no recovery score and no
/// strain, so those stay null and the card hides those rows; in exchange they
/// carry steps and exercise minutes, which WHOOP's API doesn't expose.
WhoopBody bodyFromBiometrics(List<DailyBiometrics> days) => WhoopBody([
      for (final d in days)
        WhoopDay(
          day: d.day,
          hrvMs: d.hrvMs,
          restingHr: d.restingHr,
          respiratoryRate: d.respiratoryRate,
          sleepHours: d.sleepHours,
          sleepPerformancePct: d.sleepEfficiencyPct,
          steps: d.steps,
          exerciseMinutes: d.zone2Minutes,
        ),
    ]);
