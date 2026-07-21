import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/db/app_database.dart';
import '../data/providers.dart';
import '../domain/reminder_rules.dart';

final notificationServiceProvider =
    Provider<NotificationService>((_) => NotificationService());

/// Local notifications only — no push, no third parties (§4). No-op on web.
class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<bool> _ensureInitialized() async {
    if (kIsWeb) return false;
    if (_initialized) return true;
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // Fall back to the bundled default (UTC) rather than failing.
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _initialized = true;
    return true;
  }

  Future<void> scheduleAt({
    required int id,
    required DateTime at,
    required String body,
  }) async {
    if (!await _ensureInitialized()) return;
    await _plugin.zonedSchedule(
      id: id,
      title: 'PulsIQ',
      body: body,
      scheduledDate: tz.TZDateTime.from(at, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'hydration',
          'Hydration reminders',
          channelDescription: 'Contextual hydration nudges',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }
}

/// Applies [ReminderRules] (max 4/day, quiet hours) and tracks the daily
/// budget in app settings.
class ReminderScheduler {
  ReminderScheduler(this._db, this._notifications);

  final AppDatabase _db;
  final NotificationService _notifications;

  static String _todayKey() {
    final now = DateTime.now();
    return 'reminders_sent_${now.year}-${now.month}-${now.day}';
  }

  Future<int> _sentToday() async =>
      int.tryParse(await _db.getSetting(_todayKey()) ?? '0') ?? 0;

  Future<void> onCaffeineLogged() async {
    final sent = await _sentToday();
    final slot = ReminderRules.afterCaffeine(DateTime.now(), sentToday: sent);
    if (slot == null) return;
    await _notifications.scheduleAt(
      id: 100 + sent,
      at: slot,
      body: 'Coffee two hours ago — a glass of water keeps the energy '
          'steady.',
    );
    await _db.setSetting(_todayKey(), '${sent + 1}');
  }
}

final reminderSchedulerProvider = Provider<ReminderScheduler>(
  (ref) => ReminderScheduler(
    ref.watch(appDatabaseProvider),
    ref.watch(notificationServiceProvider),
  ),
);
