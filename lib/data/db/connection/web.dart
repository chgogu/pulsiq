import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

/// Web (dev-preview vehicle only): drift over sqlite3 WASM, persisted in
/// IndexedDB/OPFS. Assets live in web/sqlite3.wasm and web/drift_worker.js.
QueryExecutor openConnection() {
  return DatabaseConnection.delayed(Future(() async {
    final result = await WasmDatabase.open(
      databaseName: 'pulsiq',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
    );
    return result.resolvedExecutor;
  }));
}
