import 'package:flutter_test/flutter_test.dart';
import 'package:pulsiq/domain/reminder_rules.dart';

void main() {
  group('hourly water reminders', () {
    test('covers every waking hour, inclusive of both ends', () {
      final hours = ReminderRules.hourlyWaterHours();
      expect(hours.first, ReminderRules.waterStartHour);
      expect(hours.last, ReminderRules.waterEndHour);
      expect(
        hours.length,
        ReminderRules.waterEndHour - ReminderRules.waterStartHour + 1,
      );
    });

    test('never schedules inside quiet hours', () {
      for (final h in ReminderRules.hourlyWaterHours()) {
        expect(
          ReminderRules.isQuietTime(DateTime(2026, 1, 1, h)),
          isFalse,
          reason: '$h:00 falls in quiet hours',
        );
      }
    });

    test('hours are strictly increasing and one apart', () {
      final hours = ReminderRules.hourlyWaterHours();
      for (var i = 1; i < hours.length; i++) {
        expect(hours[i] - hours[i - 1], 1);
      }
    });

    test('copy rotates rather than repeating the same line all day', () {
      final hours = ReminderRules.hourlyWaterHours();
      final messages = {for (final h in hours) ReminderRules.waterMessage(h)};
      expect(messages.length, greaterThan(1));
      for (final m in messages) {
        expect(m.trim(), isNotEmpty);
      }
    });
  });

  group('evening activity reminder', () {
    test('fires at 6 pm, outside quiet hours', () {
      expect(ReminderRules.activityHour, 18);
      expect(
        ReminderRules.isQuietTime(
            DateTime(2026, 1, 1, ReminderRules.activityHour)),
        isFalse,
      );
    });

    test('message varies across the year and is never empty', () {
      final seen = {
        for (var doy = 0; doy < 366; doy++) ReminderRules.activityMessage(doy)
      };
      expect(seen.length, greaterThan(1));
      for (final m in seen) {
        expect(m.trim(), isNotEmpty);
      }
    });

    test('any day of year maps to a message without going out of range', () {
      for (var doy = 0; doy < 366; doy++) {
        expect(ReminderRules.activityMessage(doy), isNotEmpty);
      }
    });
  });

  test('standing reminders do not consume the contextual daily budget', () {
    // The hourly/evening schedule is independent of maxPerDay, which governs
    // only the contextual nudges.
    expect(ReminderRules.hourlyWaterHours().length,
        greaterThan(ReminderRules.maxPerDay));
    expect(
      ReminderRules.afterCaffeine(DateTime(2026, 1, 1, 10), sentToday: 0),
      isNotNull,
    );
  });
}
