import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulsiq/data/db/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  HealthScoreSnapshotsCompanion row(DateTime day, String source, int score) =>
      HealthScoreSnapshotsCompanion.insert(
        day: DateTime(day.year, day.month, day.day),
        source: source,
        score: score,
        hrvMs: const Value(60),
      );

  test('upsert is idempotent per (day, source)', () async {
    final day = DateTime(2026, 8, 15);
    await db.upsertHealthSnapshots([row(day, 'whoop', 70)]);
    await db.upsertHealthSnapshots([row(day, 'whoop', 85)]); // same key, new score
    final rows =
        await db.watchHealthSnapshotsSince('whoop', DateTime(2026, 1, 1)).first;
    expect(rows.length, 1);
    expect(rows.single.score, 85); // updated, not duplicated
  });

  test('distinct sources coexist for the same day', () async {
    final day = DateTime(2026, 8, 15);
    await db.upsertHealthSnapshots([
      row(day, 'whoop', 70),
      row(day, 'appleHealth', 66),
    ]);
    final whoop =
        await db.watchHealthSnapshotsSince('whoop', DateTime(2026, 1, 1)).first;
    final apple = await db
        .watchHealthSnapshotsSince('appleHealth', DateTime(2026, 1, 1))
        .first;
    expect(whoop.single.score, 70);
    expect(apple.single.score, 66);
  });

  test('watchHealthSnapshotsSince filters by cutoff and source', () async {
    await db.upsertHealthSnapshots([
      row(DateTime(2026, 8, 1), 'whoop', 60),
      row(DateTime(2026, 8, 10), 'whoop', 70),
      row(DateTime(2026, 8, 10), 'appleHealth', 55),
    ]);
    final since =
        await db.watchHealthSnapshotsSince('whoop', DateTime(2026, 8, 5)).first;
    expect(since.length, 1);
    expect(since.single.score, 70);
  });
}
