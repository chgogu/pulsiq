import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsiq/domain/health_models.dart';
import 'package:pulsiq/domain/whoop.dart';
import 'package:pulsiq/features/dashboard/whoop_card.dart';
import 'package:pulsiq/health/body_signals.dart';
import 'package:pulsiq/health/health_providers.dart';
import 'package:pulsiq/health/whoop/whoop_client.dart';
import 'package:pulsiq/health/whoop/whoop_providers.dart';

/// Turning one source off must never hide the other's analytics. Both cards
/// are pumped together so each combination is exercised as the dashboard
/// actually renders it.
Widget _host({WhoopFetchResult? whoop, BodySignals? platform}) => ProviderScope(
      overrides: [
        whoopBodyProvider.overrideWith((ref) async => whoop),
        platformBodySignalsProvider.overrideWith((ref) async => platform),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(children: [WhoopCard(), PlatformHealthCard()]),
          ),
        ),
      ),
    );

WhoopFetchResult _whoopOk() => WhoopFetchResult(
      WhoopFetchStatus.ok,
      body: WhoopBody([
        WhoopDay(
          day: DateTime.now(),
          recoveryPct: 72,
          hrvMs: 68,
          restingHr: 52,
          strain: 11.4,
          sleepHours: 7.6,
        ),
      ]),
    );

BodySignals _appleOk() => BodySignals(
      source: BodySignalSource.appleHealth,
      windowDays: 30,
      body: bodyFromBiometrics([
        DailyBiometrics(
          day: DateTime.now(),
          hrvMs: 64,
          restingHr: 57,
          sleepHours: 7.8,
          steps: 11200,
        ),
      ]),
    );

void main() {
  testWidgets('both cards show when both sources are connected',
      (tester) async {
    await tester.pumpWidget(_host(whoop: _whoopOk(), platform: _appleOk()));
    await tester.pumpAndSettle();

    expect(find.text('Body signals'), findsOneWidget);
    expect(find.text('Apple Health analytics'), findsOneWidget);
    expect(find.text('60-day averages · WHOOP'), findsOneWidget);
    expect(find.text('30-day averages · Apple Health'), findsOneWidget);
  });

  testWidgets('WHOOP off still leaves Apple Health readable', (tester) async {
    await tester.pumpWidget(_host(whoop: null, platform: _appleOk()));
    await tester.pumpAndSettle();

    expect(find.text('Body signals'), findsNothing);
    expect(find.text('Apple Health analytics'), findsOneWidget);
    // Metric row plus its trend-chart chip.
    expect(find.text('Steps'), findsNWidgets(2));
  });

  testWidgets('Apple Health off still leaves WHOOP readable', (tester) async {
    await tester.pumpWidget(_host(whoop: _whoopOk(), platform: null));
    await tester.pumpAndSettle();

    expect(find.text('Apple Health analytics'), findsNothing);
    expect(find.text('Body signals'), findsOneWidget);
    expect(find.text('Day strain'), findsNWidgets(2));
  });

  testWidgets('WHOOP card drops the steps caveat and the history footer',
      (tester) async {
    await tester.pumpWidget(_host(whoop: _whoopOk(), platform: null));
    await tester.pumpAndSettle();

    expect(find.textContaining('developer API'), findsNothing);
    expect(find.textContaining('connect Apple Health for step'), findsNothing);
    expect(find.textContaining('days of history'), findsNothing);
    expect(find.textContaining('As of'), findsNothing);
  });

  testWidgets('neither connected shows no analytics cards', (tester) async {
    await tester.pumpWidget(_host(whoop: null, platform: null));
    await tester.pumpAndSettle();

    expect(find.text('Body signals'), findsNothing);
    expect(find.textContaining('analytics'), findsNothing);
  });
}
