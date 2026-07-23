/// Hydration reminder planning (spec §3): contextual, max 4/day, quiet
/// hours respected. Pure logic — the notification plugin consumes this.
library;

class ReminderRules {
  static const maxPerDay = 4;
  static const quietStartHour = 22; // 10 pm
  static const quietEndHour = 7; // 7 am

  static bool isQuietTime(DateTime t) =>
      t.hour >= quietStartHour || t.hour < quietEndHour;

  /// 2h after a logged coffee (spec example). Returns null when the slot
  /// falls in quiet hours or the daily budget is spent.
  static DateTime? afterCaffeine(DateTime loggedAt, {required int sentToday}) {
    if (sentToday >= maxPerDay) return null;
    final slot = loggedAt.add(const Duration(hours: 2));
    if (isQuietTime(slot)) return null;
    return slot;
  }

  /// Behind-pace nudge: if under half the target by 3 pm, remind at 3 pm
  /// (or now, if it's already past). Null once caught up, quiet, or spent.
  static DateTime? behindPace({
    required DateTime now,
    required int consumedMl,
    required int targetMl,
    required int sentToday,
  }) {
    if (sentToday >= maxPerDay) return null;
    if (targetMl <= 0 || consumedMl * 2 >= targetMl) return null;
    final threePm = DateTime(now.year, now.month, now.day, 15);
    final slot = now.isAfter(threePm) ? now : threePm;
    if (isQuietTime(slot)) return null;
    return slot;
  }

  // ---------------------------------------------------------------------
  // Standing daily reminders (owner-requested): hourly hydration through the
  // waking day, and one evening nudge to move. These repeat daily on the
  // device's own clock, so they fire in the user's local time even when the
  // app isn't running — and they deliberately sit outside the [maxPerDay]
  // budget above, which governs the *contextual* nudges.
  // ---------------------------------------------------------------------

  /// First and last hourly hydration reminder (inclusive), kept inside waking
  /// hours so nobody is pinged at 3 am.
  static const waterStartHour = 8;
  static const waterEndHour = 21;

  /// Evening activity nudge — 6 pm local.
  static const activityHour = 18;

  /// Every hour of the waking window, quiet hours excluded.
  static List<int> hourlyWaterHours() => [
        for (var h = waterStartHour; h <= waterEndHour; h++)
          if (!isQuietTime(DateTime(2000, 1, 1, h))) h,
      ];

  /// Rotating hydration copy so 14 daily reminders don't read identically.
  static String waterMessage(int hour) {
    const lines = [
      'Time for a glass of water.',
      'Hydration check — a few sips now keeps the afternoon steady.',
      'Water break. Your energy curve will thank you.',
      'Another glass? Steady hydration beats catching up later.',
      'Quick sip — dehydration shows up as tiredness long before thirst.',
      'Top up your water.',
    ];
    return lines[hour % lines.length];
  }

  /// Evening nudge to move — varied so it stays motivating, not nagging.
  static String activityMessage(int dayOfYear) {
    const lines = [
      'Evening moment — a 10-minute walk now pays off in tonight\'s recovery.',
      'Got 15 minutes? A quick workout or walk steadies your evening energy.',
      'Time to move. Even a short walk lifts tomorrow\'s recovery score.',
      'A little movement now — your heart rate and sleep both benefit.',
      'Wind down by moving first: a brisk walk, a stretch, anything counts.',
    ];
    return lines[dayOfYear % lines.length];
  }
}
