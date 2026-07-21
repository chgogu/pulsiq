import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsiq/app.dart';
import 'package:pulsiq/data/db/app_database.dart';
import 'package:pulsiq/data/providers.dart';
import 'package:pulsiq/features/logging/entry_sheet.dart';

const _fab = ValueKey('universal-fab');

/// Splash auto-forwards after 1.8s; pumps use explicit durations because the
/// pulse-wave motif animates continuously (pumpAndSettle would never settle).
Future<AppDatabase> pumpApp(WidgetTester tester) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(db.close);
  await tester.pumpWidget(ProviderScope(
    overrides: [appDatabaseProvider.overrideWithValue(db)],
    child: const PulsIQApp(),
  ));
  return db;
}

/// Drift stream subscriptions schedule zero-duration timers when cancelled.
/// Dispose the tree inside the test body and flush them, or the pending-timer
/// guard fails the test during teardown.
Future<void> disposeApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  // Drift chains several zero-duration cleanup timers; flush them all.
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

/// Drift work completes on the real event loop; alternate real-async yields
/// with fake-async pumps until [finder] appears (or give up and let the
/// caller's expect fail with a useful message).
Future<void> pumpUntil(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 20 && finder.evaluate().isEmpty; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> pumpToDashboard(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 1900)); // splash timer
  await pumpUntil(tester, find.text('Get started')); // async settings read
  await tester.tap(find.text('Get started'));
  await tester.pump(const Duration(milliseconds: 400));
  await pumpUntil(tester, find.text('PulsIQ Score')); // async write + route
  await tester.pump(const Duration(milliseconds: 400)); // transition done
}

void main() {
  testWidgets('splash shows tagline, onboarding shows disclosure, '
      'Get started lands on dashboard with FAB', (tester) async {
    await pumpApp(tester);
    expect(find.text('Biometric intelligence in real time'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1900));
    await pumpUntil(tester, find.text('Get started'));
    expect(find.text('Get started'), findsOneWidget);
    expect(find.textContaining('not a medical device'), findsOneWidget);

    await tester.tap(find.text('Get started'));
    await tester.pump(const Duration(milliseconds: 400));
    await pumpUntil(tester, find.text('PulsIQ Score'));
    expect(find.text('PulsIQ Score'), findsOneWidget);
    expect(find.byKey(_fab), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('returning user skips onboarding after splash',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.setSetting('onboarded', 'true');
    await tester.pumpWidget(ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: const PulsIQApp(),
    ));
    await tester.pump(const Duration(milliseconds: 1900));
    await pumpUntil(tester, find.text('PulsIQ Score'));
    expect(find.text('PulsIQ Score'), findsOneWidget);
    expect(find.text('Get started'), findsNothing);
    await disposeApp(tester);
  });

  testWidgets('FAB tap logs water and the hydration ring updates',
      (tester) async {
    await pumpApp(tester);
    await pumpToDashboard(tester);
    await pumpUntil(tester, find.text('0 / 2000 ml'));
    expect(find.text('0 / 2000 ml'), findsOneWidget);

    await tester.tap(find.byKey(_fab));
    await tester.pump();
    await pumpUntil(tester, find.text('237 / 2000 ml'));
    expect(find.textContaining('+8 oz water logged'), findsOneWidget);
    expect(find.text('237 / 2000 ml'), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('entry sheet saves a food into the local DB', (tester) async {
    // Pumped directly (not via the bottom-sheet route): the route's
    // geometry on the desktop-shaped test surface puts the button
    // off-screen, which is orthogonal to what this verifies — field input,
    // validation, and the DB write.
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await tester.pumpWidget(ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: const MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: EntrySheet())),
      ),
    ));
    await tester.pump();

    await tester.enterText(
        find.widgetWithText(TextField, 'What did you eat?'), 'Oats');
    await tester.pump();
    await tester.tap(find.text('Add to log'));
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 50));
    }

    final foods = await tester.runAsync(() => db.watchTodayFoods().first);
    expect(foods!.single.name, 'Oats');
    expect(foods.single.qualityScore, FuelQuality.clean);
    await disposeApp(tester);
  });

  testWidgets('FAB hold shows recording overlay, release submits',
      (tester) async {
    await pumpApp(tester);
    await pumpToDashboard(tester);
    final gesture =
        await tester.startGesture(tester.getCenter(find.byKey(_fab)));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('Release to submit'), findsOneWidget);

    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Release to submit'), findsNothing);
    expect(find.textContaining('Voice note captured'), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('FAB swipe up opens the Order Hack stub', (tester) async {
    await pumpApp(tester);
    await pumpToDashboard(tester);
    await tester.drag(find.byKey(_fab), const Offset(0, -80));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Order Hack lens'), findsOneWidget);
    expect(find.byKey(_fab), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('score hero opens the breakdown sheet on tap', (tester) async {
    await pumpApp(tester);
    await pumpToDashboard(tester);
    await tester.tap(find.text('PulsIQ Score'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Score breakdown'), findsOneWidget);
    expect(find.text('Cardiac recovery'), findsOneWidget);
    await disposeApp(tester);
  });
}
