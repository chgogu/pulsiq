import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsiq/domain/health_models.dart';
import 'package:pulsiq/features/dashboard/whoop_card.dart';
import 'package:pulsiq/health/body_signals.dart';
import 'package:pulsiq/health/health_providers.dart';
import 'package:pulsiq/theme/pulse_theme.dart';

/// The default test surface is 800px wide — wider than any phone — so layout
/// overflows hide from ordinary widget tests. These pump at real iPhone width
/// in both themes, which is how the card's title row and loading row were
/// caught overflowing by 55px and 199px.
BodySignals _signals({bool withHrv = true}) {
  final now = DateTime.now();
  final rnd = Random(7);
  return BodySignals(
    source: BodySignalSource.appleHealth,
    windowDays: 30,
    body: bodyFromBiometrics([
      for (var i = 29; i >= 0; i--)
        DailyBiometrics(
          day: now.subtract(Duration(days: i)),
          // A deliberate gap, so the chart's break-on-missing-days path runs.
          hrvMs: !withHrv || (i > 12 && i < 17)
              ? null
              : 45 + rnd.nextDouble() * 25,
          restingHr: 54 + rnd.nextDouble() * 8,
          sleepHours: 6 + rnd.nextDouble() * 2.5,
          steps: 5000 + rnd.nextInt(9000),
        ),
    ]),
  );
}

Future<void> _pumpAtPhoneWidth(
  WidgetTester tester, {
  required BodySignals? signals,
  required Brightness brightness,
}) async {
  tester.view.physicalSize = const Size(1170, 2532); // iPhone 15 Pro
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(ProviderScope(
    overrides: [
      platformBodySignalsProvider.overrideWith((ref) async => signals),
    ],
    child: MaterialApp(
      theme: pulsiqTheme(brightness),
      home: const Scaffold(
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: PlatformHealthCard(),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  for (final brightness in [Brightness.light, Brightness.dark]) {
    testWidgets('card lays out at phone width in ${brightness.name} mode',
        (tester) async {
      await _pumpAtPhoneWidth(tester,
          signals: _signals(), brightness: brightness);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('loading state lays out at phone width', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        // Never completes — holds the card in its loading state.
        platformBodySignalsProvider
            .overrideWith((ref) => Completer<BodySignals?>().future),
      ],
      child: MaterialApp(
        theme: pulsiqTheme(Brightness.light),
        home: const Scaffold(body: PlatformHealthCard()),
      ),
    ));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('lays out with a metric missing entirely', (tester) async {
    await _pumpAtPhoneWidth(tester,
        signals: _signals(withHrv: false), brightness: Brightness.light);
    expect(tester.takeException(), isNull);
    expect(find.text('HRV'), findsNothing);
  });
}
