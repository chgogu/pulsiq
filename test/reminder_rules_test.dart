import 'package:flutter_test/flutter_test.dart';
import 'package:pulsiq/domain/reminder_rules.dart';

void main() {
  group('ReminderRules.afterCaffeine', () {
    test('schedules 2h after the coffee', () {
      final slot = ReminderRules.afterCaffeine(
        DateTime(2026, 7, 21, 10),
        sentToday: 0,
      );
      expect(slot, DateTime(2026, 7, 21, 12));
    });

    test('skips slots inside quiet hours', () {
      expect(
        ReminderRules.afterCaffeine(DateTime(2026, 7, 21, 21), sentToday: 0),
        isNull,
      );
      expect(
        ReminderRules.afterCaffeine(DateTime(2026, 7, 21, 4), sentToday: 0),
        isNull, // 6 am is still quiet
      );
    });

    test('respects the 4/day budget', () {
      expect(
        ReminderRules.afterCaffeine(DateTime(2026, 7, 21, 10), sentToday: 4),
        isNull,
      );
    });
  });

  group('ReminderRules.behindPace', () {
    test('reminds at 3 pm when under half target', () {
      final slot = ReminderRules.behindPace(
        now: DateTime(2026, 7, 21, 14),
        consumedMl: 400,
        targetMl: 2400,
        sentToday: 0,
      );
      expect(slot, DateTime(2026, 7, 21, 15));
    });

    test('reminds immediately when already past 3 pm', () {
      final now = DateTime(2026, 7, 21, 16, 30);
      expect(
        ReminderRules.behindPace(
            now: now, consumedMl: 400, targetMl: 2400, sentToday: 0),
        now,
      );
    });

    test('silent when on pace, quiet, or budget spent', () {
      expect(
        ReminderRules.behindPace(
            now: DateTime(2026, 7, 21, 14),
            consumedMl: 1300,
            targetMl: 2400,
            sentToday: 0),
        isNull,
      );
      expect(
        ReminderRules.behindPace(
            now: DateTime(2026, 7, 21, 23),
            consumedMl: 100,
            targetMl: 2400,
            sentToday: 0),
        isNull,
      );
      expect(
        ReminderRules.behindPace(
            now: DateTime(2026, 7, 21, 14),
            consumedMl: 100,
            targetMl: 2400,
            sentToday: 4),
        isNull,
      );
    });
  });
}
