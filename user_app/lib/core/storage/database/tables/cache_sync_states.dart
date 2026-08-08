// lib/core/database/tables/cache_sync_states.dart

import 'package:drift/drift.dart';

class CacheSyncStates extends Table {
  TextColumn get resource => text()();

  TextColumn get scope => text().withDefault(const Constant('public'))();

  DateTimeColumn get lastSyncAt => dateTime().nullable()();

  TextColumn get cursor => text().nullable()();

  TextColumn get etag => text().nullable()();

  TextColumn get lastError => text().nullable()();

  DateTimeColumn get lastAttemptAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {resource, scope};
}
