import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsiq/app.dart';

const _fab = ValueKey('universal-fab');

/// Splash auto-forwards after 1.8s; pumps use explicit durations because the
/// pulse-wave motif animates continuously (pumpAndSettle would never settle).
Future<void> pumpToDashboard(WidgetTester tester) async {
  await tester.pumpWidget(const ProviderScope(child: PulsIQApp()));
  await tester.pump(const Duration(milliseconds: 1900));
  await tester.pump(const Duration(milliseconds: 400));
  await tester.tap(find.text('Get started'));
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('splash shows tagline, onboarding shows disclosure, '
      'Get started lands on dashboard with FAB', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PulsIQApp()));
    expect(find.text('Biometric intelligence in real time'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1900));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Get started'), findsOneWidget);
    expect(find.textContaining('not a medical device'), findsOneWidget);

    await tester.tap(find.text('Get started'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('PulsIQ Score'), findsOneWidget);
    expect(find.byKey(_fab), findsOneWidget);
  });

  testWidgets('FAB tap quick-adds water with a toast', (tester) async {
    await pumpToDashboard(tester);
    await tester.tap(find.byKey(_fab));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.textContaining('+8 oz water logged'), findsOneWidget);
  });

  testWidgets('FAB hold shows recording overlay, release submits',
      (tester) async {
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
  });

  testWidgets('FAB swipe up opens the Order Hack stub', (tester) async {
    await pumpToDashboard(tester);
    await tester.drag(find.byKey(_fab), const Offset(0, -80));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Order Hack lens'), findsOneWidget);
    // The universal FAB persists on every screen inside the shell.
    expect(find.byKey(_fab), findsOneWidget);
  });

  testWidgets('score hero opens the breakdown sheet on tap', (tester) async {
    await pumpToDashboard(tester);
    await tester.tap(find.text('PulsIQ Score'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Score breakdown'), findsOneWidget);
    expect(find.text('Cardiac recovery'), findsOneWidget);
  });
}
