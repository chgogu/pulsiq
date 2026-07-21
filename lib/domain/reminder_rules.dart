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
}
