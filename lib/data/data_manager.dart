import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../security/key_vault.dart';
import '../security/secret_store.dart';
import 'db/app_database.dart';
import 'providers.dart';

/// In-app data export + full deletion (spec §4), each reachable in ≤3 taps
/// from Settings.
class DataManager {
  DataManager(this._db, {SecretStore? secretStore})
      : _secretStore = secretStore ?? const PlatformSecretStore();

  final AppDatabase _db;
  final SecretStore _secretStore;

  /// Full local export as pretty JSON. Health logs only — the encryption
  /// keys are deliberately excluded (exporting them would defeat the
  /// zero-knowledge posture).
  Future<String> exportJson() async {
    await _db.logAudit(
      action: 'read',
      dataType: 'all',
      source: 'data_export',
      purpose: 'user_export',
    );
    final data = {
      'exported_at': DateTime.now().toIso8601String(),
      'app': 'PulsIQ',
      'schema_version': _db.schemaVersion,
      'foods': [
        for (final f in await _db.select(_db.foodEntries).get())
          {
            'name': f.name,
            'quantity': f.quantity,
            'quality': f.qualityScore.name,
            'logged_at': f.loggedAt.toIso8601String(),
          }
      ],
      'beverages': [
        for (final b in await _db.select(_db.beverageEntries).get())
          {
            'name': b.name,
            'volume_ml': b.volumeMl,
            'sugar_g': b.sugarContentG,
            'type': b.type.name,
            'logged_at': b.loggedAt.toIso8601String(),
          }
      ],
      'hydration': [
        for (final h in await _db.select(_db.hydrationEntries).get())
          {
            'amount_ml': h.amountMl,
            'source': h.source,
            'logged_at': h.loggedAt.toIso8601String(),
          }
      ],
      'exercise': [
        for (final e in await _db.select(_db.exerciseEntries).get())
          {
            'activity': e.activity,
            'minutes': e.durationMinutes,
            'intensity': e.intensity.name,
            'logged_at': e.loggedAt.toIso8601String(),
          }
      ],
      'walks': [
        for (final w in await _db.select(_db.walkSessions).get())
          {
            'target_minutes': w.targetMinutes,
            'started_at': w.startedAt.toIso8601String(),
            'completed_at': w.completedAt?.toIso8601String(),
            'source': w.source,
          }
      ],
      'audit': [
        for (final a in await _db.select(_db.auditEvents).get())
          {
            'at': a.at.toIso8601String(),
            'action': a.action,
            'data_type': a.dataType,
            'source': a.source,
            'purpose': a.purpose,
          }
      ],
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Irreversible: clears every table and the device-held keys. After this
  /// the app is a fresh install (losing all devices means losing backup —
  /// documented in onboarding, §4).
  Future<void> deleteEverything() async {
    await _db.transaction(() async {
      for (final table in _db.allTables) {
        await _db.delete(table).go();
      }
    });
    await KeyVault(_secretStore).wipe();
  }
}

final dataManagerProvider =
    Provider<DataManager>((ref) => DataManager(ref.watch(appDatabaseProvider)));
