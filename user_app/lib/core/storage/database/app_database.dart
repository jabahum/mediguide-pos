import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class CacheEntries extends Table {
  TextColumn get key => text()();
  TextColumn get payload => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

class PendingSyncOperations extends Table {
  TextColumn get id => text()();
  TextColumn get resourceType => text()();
  TextColumn get resourceId => text().nullable()();
  TextColumn get operation => text()();
  TextColumn get payload => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [CacheEntries, PendingSyncOperations])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  Future<CacheEntry?> cacheEntry(String key) => (select(
    cacheEntries,
  )..where((row) => row.key.equals(key))).getSingleOrNull();

  Future<void> putCacheEntry({
    required String key,
    required String payload,
    required DateTime cachedAt,
  }) => into(cacheEntries).insertOnConflictUpdate(
    CacheEntriesCompanion.insert(
      key: key,
      payload: payload,
      cachedAt: cachedAt,
    ),
  );
}

LazyDatabase _openConnection() => LazyDatabase(() async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File(path.join(directory.path, 'mediguide.sqlite'));
  return NativeDatabase.createInBackground(file);
});
