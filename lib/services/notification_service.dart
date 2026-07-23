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

  /// Returns false whenever notifications aren't usable — on web, and under
  /// the test binding where no platform implementation is registered.
  /// Reminders are best-effort: never let their absence take the app down.
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
    try {
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
      // iOS needs its own explicit grant or nothing is ever delivered.
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (_) {
      return false;
    }
    _initialized = true;
    return true;
  }

  static const walkActivityId = 7001;

  /// Ongoing walk-timer notification. On Android this is the
  /// foreground-service-style ongoing notification; on iOS it stands in for
  /// the Live Activity (spec §3 — a full ActivityKit widget is native work
  /// beyond the Flutter layer).
  Future<void> showWalkActivity({
    required String body,
    required int progressMax,
    required int progress,
  }) async {
    if (!await _ensureInitialized()) return;
    await _plugin.show(
      id: walkActivityId,
      title: 'Post-meal walk',
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'walks',
          'Walk timer',
          channelDescription: 'Active post-meal walk',
          ongoing: true,
          onlyAlertOnce: true,
          showProgress: true,
          maxProgress: progressMax,
          progress: progress,
          category: AndroidNotificationCategory.progress,
        ),
        iOS: const DarwinNotificationDetails(presentSound: false),
      ),
    );
  }

  Future<void> clearWalkActivity() async {
    if (!await _ensureInitialized()) return;
    await _plugin.cancel(id: walkActivityId);
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

  /// Notification id ranges for the standing daily reminders.
  static const waterIdBase = 200; // + hour-of-day
  static const activityId = 300;

  /// Schedules a notification that repeats **daily at this local wall-clock
  /// time**. `matchDateTimeComponents: time` is what makes the OS re-fire it
  /// every day without the app running, in whatever timezone the user is in.
  Future<void> scheduleDailyAt({
    required int id,
    required int hour,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
    int minute = 0,
  }) async {
    if (!await _ensureInitialized()) return;
    final now = tz.TZDateTime.now(tz.local);
    var when =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!when.isAfter(now)) when = when.add(const Duration(days: 1));
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: when,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelName,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // repeat daily
    );
  }

  Future<void> cancelIds(Iterable<int> ids) async {
    if (!await _ensureInitialized()) return;
    for (final id in ids) {
      await _plugin.cancel(id: id);
    }
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

  /// Settings keys for the standing daily reminders (both default ON).
  static const waterRemindersKey = 'reminders_water_hourly';
  static const activityReminderKey = 'reminders_evening_activity';

  Future<bool> waterRemindersEnabled() async =>
      (await _db.getSetting(waterRemindersKey)) != 'false';

  Future<bool> activityReminderEnabled() async =>
      (await _db.getSetting(activityReminderKey)) != 'false';

  /// Rebuilds the standing daily reminders from settings. Safe to call any
  /// time — it always cancels first, so it can't stack duplicates.
  Future<void> syncDailyReminders() async {
    final hours = ReminderRules.hourlyWaterHours();
    await _notifications.cancelIds([
      for (final h in hours) NotificationService.waterIdBase + h,
      NotificationService.activityId,
    ]);

    if (await waterRemindersEnabled()) {
      for (final h in hours) {
        await _notifications.scheduleDailyAt(
          id: NotificationService.waterIdBase + h,
          hour: h,
          title: 'Hydration',
          body: ReminderRules.waterMessage(h),
          channelId: 'hydration',
          channelName: 'Hydration reminders',
        );
      }
    }

    if (await activityReminderEnabled()) {
      final doy =
          DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
      await _notifications.scheduleDailyAt(
        id: NotificationService.activityId,
        hour: ReminderRules.activityHour,
        title: 'Time to move',
        body: ReminderRules.activityMessage(doy),
        channelId: 'activity',
        channelName: 'Activity reminders',
      );
    }
  }

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
