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
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
    },

    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await _migrateVersionOneToTwo(migrator);
      }
    },

    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');

      await customStatement('PRAGMA journal_mode = WAL');

      // Repair databases left partially initialized by development builds.
      // Normal upgrades are handled above; this only creates a current table
      // when the file metadata exists but the table itself is absent.
      await _ensureCurrentTables(createMigrator());
    },
  );

  Future<void> _migrateVersionOneToTwo(Migrator migrator) async {
    await _ensureCurrentTables(migrator);

    if (await _tableExists('cache_entries')) {
      await customStatement('''
        INSERT OR IGNORE INTO cached_entities (
          entity_type,
          entity_id,
          payload,
          searchable_text,
          scope,
          cached_at,
          is_deleted
        )
        SELECT
          'http_response',
          key,
          payload,
          '',
          'public',
          cached_at,
          0
        FROM cache_entries
      ''');
      await migrator.deleteTable('cache_entries');
    }

    if (await _tableExists('pending_sync_operations')) {
      // Version 1 did not store an authenticated owner scope and used generic
      // resource routes. Preserve these records for diagnostics, but mark
      // them blocked so they cannot be replayed under the wrong user.
      await customStatement('''
        INSERT INTO pending_mutations (
          entity_type,
          entity_id,
          operation,
          payload,
          scope,
          status,
          attempts,
          last_error,
          created_at,
          updated_at
        )
        SELECT
          resource_type,
          resource_id,
          operation,
          payload,
          'legacy',
          'blocked',
          attempts,
          'Migrated from the unscoped version 1 queue; manual retry is required',
          created_at,
          created_at
        FROM pending_sync_operations
      ''');
      await migrator.deleteTable('pending_sync_operations');
    }
  }

  Future<void> _ensureCurrentTables(Migrator migrator) async {
    if (!await _tableExists('cached_entities')) {
      await migrator.createTable(cachedEntities);
    }
    if (!await _tableExists('cache_sync_states')) {
      await migrator.createTable(cacheSyncStates);
    }
    if (!await _tableExists('pending_mutations')) {
      await migrator.createTable(pendingMutations);
    }
  }

  Future<bool> _tableExists(String name) async {
    final row = await customSelect(
      'SELECT 1 AS present FROM sqlite_master '
      'WHERE type = ? AND name = ? LIMIT 1',
      variables: [Variable.withString('table'), Variable.withString(name)],
    ).getSingleOrNull();
    return row != null;
  }

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
