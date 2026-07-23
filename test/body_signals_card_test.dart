import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsiq/domain/health_models.dart';
import 'package:pulsiq/features/dashboard/whoop_card.dart';
import 'package:pulsiq/health/body_signals.dart';
import 'package:pulsiq/health/health_providers.dart';

/// Apple Health gets its own card, fed by its own provider. It used to have
/// no data path at all — the dashboard's only analytics card was WHOOP's, so
/// connecting Apple Health showed nothing. These pump the platform card with
/// no WHOOP override in scope, proving it stands alone.
Widget _host(BodySignals? signals) => ProviderScope(
      overrides: [
        platformBodySignalsProvider.overrideWith((ref) async => signals),
      ],
      child: const MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: PlatformHealthCard())),
      ),
    );

BodySignals _appleHealth() {
  final now = DateTime.now();
  return BodySignals(
    source: BodySignalSource.appleHealth,
    windowDays: 30,
    body: bodyFromBiometrics([
      for (var i = 29; i >= 1; i--)
        DailyBiometrics(
          day: now.subtract(Duration(days: i)),
          hrvMs: 50,
          restingHr: 60,
          sleepHours: 7.0,
          steps: 8000,
        ),
      DailyBiometrics(
        day: now,
        hrvMs: 64,
        restingHr: 57,
        sleepHours: 7.8,
        steps: 11200,
      ),
    ]),
  );
}

void main() {
  testWidgets('renders Apple Health metrics without any WHOOP connection',
      (tester) async {
    await tester.pumpWidget(_host(_appleHealth()));
    await tester.pumpAndSettle();

    expect(find.text('Apple Health analytics'), findsOneWidget);
    expect(find.text('HRV'), findsOneWidget);
    expect(find.text('Resting HR'), findsOneWidget);
    expect(find.text('Sleep'), findsOneWidget);
    expect(find.text('Steps'), findsOneWidget);
  });

  testWidgets('heading names the real window and source', (tester) async {
    await tester.pumpWidget(_host(_appleHealth()));
    await tester.pumpAndSettle();

    // Not the hardcoded "60-day averages" the WHOOP-only card always showed.
    expect(find.text('30-day averages · Apple Health'), findsOneWidget);
    expect(find.textContaining('60-day'), findsNothing);
  });

  testWidgets('hides recovery and strain, which Apple Health cannot measure',
      (tester) async {
    await tester.pumpWidget(_host(_appleHealth()));
    await tester.pumpAndSettle();

    expect(find.text('Day strain'), findsNothing);
    expect(find.text('Recovery'), findsNothing);
    expect(find.text('Strain'), findsNothing);
  });

  testWidgets('does not promise a recovery score that will never arrive',
      (tester) async {
    await tester.pumpWidget(_host(_appleHealth()));
    await tester.pumpAndSettle();

    expect(find.textContaining('recovery score'), findsNothing);
  });

  testWidgets('offers WHOOP as the way to add recovery', (tester) async {
    await tester.pumpWidget(_host(_appleHealth()));
    await tester.pumpAndSettle();

    expect(find.textContaining('connect WHOOP'), findsOneWidget);
  });

  testWidgets('stays hidden when nothing is connected', (tester) async {
    await tester.pumpWidget(_host(null));
    await tester.pumpAndSettle();

    expect(find.textContaining('analytics'), findsNothing);
  });
}
