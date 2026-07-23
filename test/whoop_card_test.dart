import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsiq/domain/whoop.dart';
import 'package:pulsiq/features/dashboard/whoop_card.dart';
import 'package:pulsiq/health/whoop/whoop_client.dart';
import 'package:pulsiq/health/whoop/whoop_providers.dart';

Widget _host(WhoopFetchResult? result) => ProviderScope(
      overrides: [
        whoopBodyProvider.overrideWith((ref) async => result),
      ],
      child: const MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: WhoopCard())),
      ),
    );

WhoopBody _body() => WhoopBody([
      WhoopDay(
        day: DateTime.now().subtract(const Duration(days: 1)),
        recoveryPct: 60,
        hrvMs: 58,
        restingHr: 55,
        strain: 9.0,
        sleepHours: 7.0,
      ),
      WhoopDay(
        day: DateTime.now(),
        recoveryPct: 72,
        hrvMs: 68,
        restingHr: 52,
        strain: 11.4,
        sleepHours: 7.6,
      ),
    ]);

void main() {
  testWidgets('renders recovery ring, latest metrics, averages, and insight',
      (tester) async {
    await tester.pumpWidget(
        _host(WhoopFetchResult(WhoopFetchStatus.ok, body: _body())));
    await tester.pumpAndSettle();

    expect(find.text('Body signals'), findsOneWidget); // not "WHOOP"
    expect(find.text('72%'), findsOneWidget); // latest recovery
    expect(find.text('Primed'), findsOneWidget);
    expect(find.text('68 ms'), findsOneWidget); // latest HRV
    // The heading now names its source, since Apple Health gets its own card
    // with a different window.
    expect(find.text('60-day averages · WHOOP'), findsOneWidget);
    // Average HRV = (58+68)/2 = 63.
    expect(find.textContaining('63'), findsWidgets);
    // Steps honesty note (WHOOP app has steps, but not via its API).
    expect(find.textContaining("aren't in its developer API"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('waiting state when connected but no scored data', (tester) async {
    await tester
        .pumpWidget(_host(const WhoopFetchResult(WhoopFetchStatus.empty)));
    await tester.pumpAndSettle();
    expect(find.textContaining('waiting for your next sync'), findsOneWidget);
  });

  testWidgets('hides entirely when not linked', (tester) async {
    await tester.pumpWidget(_host(null));
    await tester.pumpAndSettle();
    expect(find.byType(Card), findsNothing);
  });
}
