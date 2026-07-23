import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:pulsiq/health/health_source.dart';

/// HealthKit and Health Connect disagree about which types exist. Requesting
/// one the current platform doesn't map makes `requestAuthorization` fail for
/// the *entire* set — which is what stopped Apple Health connecting at all.
/// These assertions are against the plugin's own platform tables, so they
/// catch the mismatch rather than restating our list back to us.
void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('every requested type is supported on iOS', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    for (final t in PlatformHealthSource.types) {
      expect(dataTypeKeysIOS, contains(t),
          reason: '$t is not a HealthKit type');
    }
  });

  test('every requested type is supported on Android', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    for (final t in PlatformHealthSource.types) {
      expect(dataTypeKeysAndroid, contains(t),
          reason: '$t is not a Health Connect type');
    }
  });

  test('HRV uses SDNN on iOS and RMSSD on Android', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(PlatformHealthSource.hrvType,
        HealthDataType.HEART_RATE_VARIABILITY_SDNN);

    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(PlatformHealthSource.hrvType,
        HealthDataType.HEART_RATE_VARIABILITY_RMSSD);
  });

  test('the metrics the dashboard needs are requested on both platforms', () {
    for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
      debugDefaultTargetPlatformOverride = platform;
      final types = PlatformHealthSource.types;
      expect(types, contains(HealthDataType.RESTING_HEART_RATE));
      expect(types, contains(HealthDataType.RESPIRATORY_RATE));
      expect(types, contains(HealthDataType.SLEEP_ASLEEP));
      expect(types, contains(HealthDataType.STEPS));
      expect(types, contains(PlatformHealthSource.hrvType));
    }
  });
}
