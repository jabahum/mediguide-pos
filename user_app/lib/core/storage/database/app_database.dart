// lib/core/database/app_database.dart

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:user_app/core/storage/database/tables/cache_sync_states.dart';
import 'package:user_app/core/storage/database/tables/cached_entities.dart';
import 'package:user_app/core/storage/database/tables/pending_mutations.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [CachedEntities, CacheSyncStates, PendingMutations])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
    },

    onUpgrade: (migrator, from, to) async {
      // Future database migrations go here.
    },

    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');

      await customStatement('PRAGMA journal_mode = WAL');
    },
  );

  Future<CachedEntity?> cacheEntry(String key) {
    return (select(cachedEntities)..where(
          (table) =>
              table.entityType.equals('http_response') &
              table.entityId.equals(key) &
              table.scope.equals('public') &
              table.isDeleted.equals(false),
        ))
        .getSingleOrNull();
  }

  Future<void> putCacheEntry({
    required String key,
    required String payload,
    required DateTime cachedAt,
  }) {
    return into(cachedEntities).insertOnConflictUpdate(
      CachedEntitiesCompanion.insert(
        entityType: 'http_response',
        entityId: key,
        payload: payload,
        scope: const Value('public'),
        cachedAt: cachedAt,
      ),
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();

    final file = File(p.join(directory.path, 'mediguide.sqlite'));

    return NativeDatabase.createInBackground(file);
  });
}
