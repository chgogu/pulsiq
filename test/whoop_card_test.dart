import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsiq/domain/whoop.dart';
import 'package:pulsiq/features/dashboard/whoop_card.dart';
import 'package:pulsiq/health/whoop/whoop_client.dart';
import 'package:pulsiq/health/whoop/whoop_providers.dart';

Widget _host(WhoopFetchResult? result) => ProviderScope(
      overrides: [
        whoopSnapshotProvider.overrideWith((ref) async => result),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: WhoopCard()),
        ),
      ),
    );

void main() {
  testWidgets('renders the recovery ring, metrics, and insight', (tester) async {
    final snap = WhoopSnapshot(
      day: DateTime.now(),
      recoveryPct: 72,
      hrvMs: 68,
      restingHr: 52,
      strain: 11.4,
      sleepHours: 7.6,
      daysOfData: 9,
    );
    await tester.pumpWidget(_host(WhoopFetchResult(WhoopFetchStatus.ok, snapshot: snap)));
    await tester.pumpAndSettle();

    expect(find.text('72%'), findsOneWidget);
    expect(find.text('Primed'), findsOneWidget);
    expect(find.text('HRV'), findsOneWidget);
    expect(find.text('Day strain'), findsOneWidget);
    // Smart insight rendered (primed → mentions load/push).
    expect(find.textContaining('primed', findRichText: true), findsWidgets);
    // No red overflow stripes.
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows a waiting note when connected but no data', (tester) async {
    await tester
        .pumpWidget(_host(const WhoopFetchResult(WhoopFetchStatus.empty)));
    await tester.pumpAndSettle();
    expect(find.textContaining('waiting for your next WHOOP sync'),
        findsOneWidget);
  });

  testWidgets('hides entirely when WHOOP is not linked', (tester) async {
    await tester.pumpWidget(_host(null));
    await tester.pumpAndSettle();
    expect(find.byType(Card), findsNothing);
    expect(find.text('WHOOP'), findsNothing);
  });
}
