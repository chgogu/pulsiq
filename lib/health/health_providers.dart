import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import '../features/dashboard/pulse_card.dart' show BiometricDelta;
import '../domain/baseline_engine.dart';
import '../domain/health_models.dart';
import 'body_signals.dart';
import 'health_source.dart';
import 'whoop/whoop_client.dart';
import 'whoop/whoop_providers.dart';

const demoHealthSettingKey = 'demo_biometrics';
const healthConnectedSettingKey = 'health_connected';

final demoHealthEnabledProvider = FutureProvider<bool>((ref) async {
  final v =
      await ref.watch(appDatabaseProvider).getSetting(demoHealthSettingKey);
  return v == 'true';
});

/// True once the user has granted Apple Health (iOS) / Health Connect
/// (Android) access. Public so the Integrations screen can show its state.
final platformHealthConnectedProvider = FutureProvider<bool>((ref) async {
  final v = await ref
      .watch(appDatabaseProvider)
      .getSetting(healthConnectedSettingKey);
  return v == 'true';
});

/// Source priority: Demo (explicit dev toggle) > WHOOP > Apple Health /
/// Health Connect > none. WHOOP outranks the platform source because it works
/// on a free-signed build without the paid HealthKit entitlement.
final healthSourceProvider = Provider<HealthSource>((ref) {
  if (ref.watch(demoHealthEnabledProvider).value ?? false) {
    return const DemoHealthSource();
  }
  if (ref.watch(whoopConnectedProvider).value ?? false) {
    return WhoopHealthSource(ref.read(whoopAuthProvider));
  }
  if (ref.watch(platformHealthConnectedProvider).value ?? false) {
    return PlatformHealthSource();
  }
  return const EmptyHealthSource();
});

/// Why the last connect attempt failed, or null if it was a plain refusal.
/// Lets the Integrations screen distinguish "you tapped Don't Allow" from
/// "the request itself errored".
class HealthConnectError extends Notifier<String?> {
  @override
  String? build() => null;
  @override
  set state(String? value) => super.state = value;
}

final healthConnectErrorProvider =
    NotifierProvider<HealthConnectError, String?>(HealthConnectError.new);

/// One-tap connect from the Pulse card. Persists the grant so the source
/// activates on every launch; audited like every health-data access.
final healthConnectorProvider = Provider<Future<bool> Function()>((ref) {
  return () async {
    final source = PlatformHealthSource();
    final granted = await source.requestPermissions();
    ref.read(healthConnectErrorProvider.notifier).state =
        granted ? null : source.lastError;
    final db = ref.read(appDatabaseProvider);
    await db.logAudit(
      action: 'read',
      dataType: 'health_permissions',
      source: 'health_kit_or_connect',
      purpose: granted
          ? 'granted'
          : (source.lastError == null ? 'denied' : 'error'),
    );
    if (granted) {
      await db.setSetting(healthConnectedSettingKey, 'true');
      ref.invalidate(platformHealthConnectedProvider);
    }
    return granted;
  };
});

/// Stops PulsIQ reading Apple Health / Health Connect. The OS-level grant is
/// revoked in the system Health app — this clears our side so the source stops
/// being used immediately.
final healthDisconnectProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    final db = ref.read(appDatabaseProvider);
    await db.setSetting(healthConnectedSettingKey, 'false');
    await db.logAudit(
      action: 'delete',
      dataType: 'health_permissions',
      source: 'health_kit_or_connect',
      purpose: 'disconnected',
    );
    ref.invalidate(platformHealthConnectedProvider);
  };
});

/// How far back the platform-health card looks. 30 days ending today.
const platformHealthWindowDays = 30;

/// Apple Health / Health Connect signals for their own dashboard card — 30
/// days ending today. Deliberately independent of WHOOP: each source gets its
/// own card, so turning one off never hides the other.
final platformBodySignalsProvider = FutureProvider<BodySignals?>((ref) async {
  final demo = ref.watch(demoHealthEnabledProvider).value ?? false;
  final platform = ref.watch(platformHealthConnectedProvider).value ?? false;
  if (!demo && !platform) return null;

  final now = DateTime.now();
  final source = demo
      ? const DemoHealthSource()
      : PlatformHealthSource() as HealthSource;
  final days = await source.fetchDaily(
    from: now.subtract(const Duration(days: platformHealthWindowDays)),
    to: now,
  );
  if (days.isEmpty) return null;

  await ref.read(appDatabaseProvider).logAudit(
        action: 'read',
        dataType: 'biometrics',
        source: demo ? 'demo' : 'health_kit_or_connect',
        purpose: 'body_signals_card',
      );

  return BodySignals(
    body: bodyFromBiometrics(days),
    source: demo
        ? BodySignalSource.demo
        : defaultTargetPlatform == TargetPlatform.iOS
            ? BodySignalSource.appleHealth
            : BodySignalSource.healthConnect,
    windowDays: platformHealthWindowDays,
  );
});

final biometricHistoryProvider =
    FutureProvider<List<DailyBiometrics>>((ref) async {
  final source = ref.watch(healthSourceProvider);
  if (source is EmptyHealthSource) return const [];
  final now = DateTime.now();
  final data = await source.fetchDaily(
    from: now.subtract(const Duration(days: 31)),
    to: now,
  );
  await ref.read(appDatabaseProvider).logAudit(
        action: 'read',
        dataType: 'biometrics',
        source: switch (source) {
          DemoHealthSource() => 'demo',
          WhoopHealthSource() => 'whoop',
          _ => 'wearable',
        },
        purpose: 'baseline_sync',
      );
  return data;
});

class MetricBaselines {
  const MetricBaselines({
    required this.rhr,
    required this.hrv,
    required this.respiratoryRate,
    required this.sleepHours,
    this.lastNightSleepHours,
    this.lastNightEfficiencyPct,
  });

  final BaselineResult rhr;
  final BaselineResult hrv;
  final BaselineResult respiratoryRate;
  final BaselineResult sleepHours;
  final double? lastNightSleepHours;
  final double? lastNightEfficiencyPct;

  bool get hasAny =>
      rhr.today != null || hrv.today != null || sleepHours.today != null;
}

final baselinesProvider = Provider<MetricBaselines?>((ref) {
  final history = ref.watch(biometricHistoryProvider).value;
  if (history == null || history.isEmpty) return null;
  final today = DateTime.now();
  List<({DateTime day, double? value})> series(
          double? Function(DailyBiometrics) pick) =>
      [for (final d in history) (day: d.day, value: pick(d))];

  final latest = history.last;
  return MetricBaselines(
    rhr: computeBaseline(series((d) => d.restingHr), today),
    hrv: computeBaseline(series((d) => d.hrvMs), today),
    respiratoryRate:
        computeBaseline(series((d) => d.respiratoryRate), today),
    sleepHours: computeBaseline(series((d) => d.sleepHours), today),
    lastNightSleepHours: latest.sleepHours,
    lastNightEfficiencyPct: latest.sleepEfficiencyPct,
  );
});

/// Pulse card rows built from real baselines — delta + trend + plain
/// language, never a bare number (spec §3). Null → card shows connect CTA.
final pulseCardProvider = Provider<List<BiometricDelta>?>((ref) {
  final b = ref.watch(baselinesProvider);
  if (b == null || !b.hasAny) return null;
  final rows = <BiometricDelta>[];

  void add({
    required String label,
    required BaselineResult r,
    required String unit,
    required IconData icon,
    required bool higherIsBetter,
    required String Function(double delta) insight,
    int decimals = 0,
  }) {
    final today = r.today;
    if (today == null) return;
    final delta = r.delta7;
    rows.add(BiometricDelta(
      label: label,
      todayText: '${today.toStringAsFixed(decimals)} $unit',
      delta: delta ?? 0,
      deltaText: delta == null
          ? 'building baseline'
          : '${delta.abs().toStringAsFixed(decimals)} '
              '${delta >= 0 ? 'over' : 'under'} baseline',
      insight: delta == null
          ? 'A few more days of data firms up your baseline.'
          : insight(delta),
      icon: icon,
      higherIsBetter: higherIsBetter,
    ));
  }

  add(
    label: 'Resting HR',
    r: b.rhr,
    unit: 'bpm',
    icon: Icons.favorite_outline,
    higherIsBetter: false,
    insight: (d) => d <= -2
        ? "Your heart's running ${d.abs().round()} beats calmer than usual."
        : d >= 2
            ? 'Running ${d.round()} beats hot — go easy on the caffeine.'
            : 'Right on your usual rhythm.',
  );
  add(
    label: 'HRV',
    r: b.hrv,
    unit: 'ms',
    icon: Icons.monitor_heart_outlined,
    higherIsBetter: true,
    insight: (d) => d >= 3
        ? 'Recovery is trending up — solid night for your system.'
        : d <= -3
            ? 'Recovery dipped — a calm day pays off tomorrow.'
            : 'Holding steady on recovery.',
  );
  add(
    label: 'Respiratory rate',
    r: b.respiratoryRate,
    unit: '/min',
    icon: Icons.air,
    higherIsBetter: false,
    decimals: 1,
    insight: (d) => d.abs() < 0.5
        ? 'Breathing is settled and steady.'
        : d > 0
            ? 'Breathing a touch faster than usual.'
            : 'Breathing slower and calmer than usual.',
  );
  add(
    label: 'Sleep',
    r: b.sleepHours,
    unit: 'h',
    icon: Icons.bedtime_outlined,
    higherIsBetter: true,
    decimals: 1,
    insight: (d) => d >= 0.5
        ? 'More sleep than your average — recovery banked.'
        : d <= -0.5
            ? 'Shorter night than usual — steady fuel today.'
            : 'Right around your usual night.',
  );
  return rows.isEmpty ? null : rows;
});

final cardiacRecoveryProvider = Provider<double?>((ref) {
  final b = ref.watch(baselinesProvider);
  if (b == null) return null;
  return cardiacRecoveryComponent(hrv: b.hrv, rhr: b.rhr);
});

final sleepQualityProvider = Provider<double?>((ref) {
  final b = ref.watch(baselinesProvider);
  if (b == null) return null;
  return sleepQualityComponent(
    lastNightHours: b.lastNightSleepHours,
    efficiencyPct: b.lastNightEfficiencyPct,
  );
});

final morningResetDueProvider = Provider<bool>((ref) {
  final b = ref.watch(baselinesProvider);
  if (b == null) return false;
  return morningResetDue(
    now: DateTime.now(),
    lastNightSleepHours: b.lastNightSleepHours,
    rhr: b.rhr,
  );
});

final correlationNoteProvider = Provider<String?>((ref) {
  final b = ref.watch(baselinesProvider);
  if (b == null) return null;
  return correlationNote(
    rhr: b.rhr,
    hrv: b.hrv,
    lastNightSleepHours: b.lastNightSleepHours,
  );
});
