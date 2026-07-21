import 'package:drift/native.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsiq/data/db/app_database.dart';
import 'package:pulsiq/data/providers.dart';
import 'package:pulsiq/features/walk/walk_controller.dart';
import 'package:pulsiq/services/notification_service.dart';

/// No-op notifications so the controller runs headless.
class SilentNotifications extends NotificationService {
  @override
  Future<void> showWalkActivity({
    required String body,
    required int progressMax,
    required int progress,
  }) async {}

  @override
  Future<void> clearWalkActivity() async {}
}

void main() {
  late AppDatabase db;

  ProviderContainer makeContainer() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final c = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      notificationServiceProvider.overrideWithValue(SilentNotifications()),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  test('starting a walk records a session and ticks down', () async {
    final c = makeContainer();
    final walk = c.read(walkControllerProvider.notifier);
    await walk.start(targetMinutes: 1, source: 'test');

    var state = c.read(walkControllerProvider);
    expect(state.active, isTrue);
    expect(state.targetMinutes, 1);
    expect(state.sessionId, isNotNull);

    // The WalkSessions row exists but is not yet complete.
    final open = await db.completedWalkMinutesToday();
    expect(open, 0);
  });

  test('completing a walk marks the session and counts its minutes',
      () async {
    final c = makeContainer();
    final walk = c.read(walkControllerProvider.notifier);
    await walk.start(targetMinutes: 10, source: 'test');
    await walk.complete();

    expect(c.read(walkControllerProvider).active, isFalse);
    expect(await db.completedWalkMinutesToday(), 10);
  });

  test('cancel stops the walk without counting minutes', () async {
    final c = makeContainer();
    final walk = c.read(walkControllerProvider.notifier);
    await walk.start(targetMinutes: 10, source: 'test');
    await walk.cancel();

    expect(c.read(walkControllerProvider).active, isFalse);
    expect(await db.completedWalkMinutesToday(), 0);
  });

  test('timer auto-completes at the target', () {
    fakeAsync((async) {
      final c = makeContainer();
      final walk = c.read(walkControllerProvider.notifier);
      walk.start(targetMinutes: 1, source: 'test');
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 61));
      expect(c.read(walkControllerProvider).active, isFalse);
    });
  });
}
