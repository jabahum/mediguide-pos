import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'package:user_app/core/storage/database/app_database.dart';

void main() {
  test('version 1 cache and mutations migrate without unsafe replay', () async {
    final connection = sqlite.sqlite3.openInMemory();
    connection.execute('''
      CREATE TABLE cache_entries (
        key TEXT NOT NULL PRIMARY KEY,
        payload TEXT NOT NULL,
        cached_at INTEGER NOT NULL
      )
    ''');
    connection.execute('''
      CREATE TABLE pending_sync_operations (
        id TEXT NOT NULL PRIMARY KEY,
        resource_type TEXT NOT NULL,
        resource_id TEXT,
        operation TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        attempts INTEGER NOT NULL DEFAULT 0
      )
    ''');
    connection.execute(
      "INSERT INTO cache_entries VALUES "
      "('languages', '{\"items\":[\"English\"]}', 1786579200)",
    );
    connection.execute(
      "INSERT INTO pending_sync_operations VALUES "
      "('legacy-1', 'reading_progress', 'progress-1', 'update', "
      "'{\"progress\":0.5}', 1786579200, 2)",
    );
    connection.execute('PRAGMA user_version = 1');

    final database = AppDatabase.forTesting(NativeDatabase.opened(connection));
    addTearDown(database.close);

    final cached = await database.cacheEntry('languages');
    expect(cached?.payload, '{"items":["English"]}');

    final mutations = await database.select(database.pendingMutations).get();
    expect(mutations, hasLength(1));
    expect(mutations.single.entityType, 'reading_progress');
    expect(mutations.single.scope, 'legacy');
    expect(mutations.single.status, 'blocked');
    expect(mutations.single.attempts, 2);

    expect(
      await _tableNames(database),
      containsAll(<String>{
        'cached_entities',
        'cache_sync_states',
        'pending_mutations',
      }),
    );
    expect(await _tableNames(database), isNot(contains('cache_entries')));
    expect(
      await _tableNames(database),
      isNot(contains('pending_sync_operations')),
    );
    expect(await _userVersion(database), 2);
  });

  test(
    'incomplete version 1 database repairs missing current tables',
    () async {
      final connection = sqlite.sqlite3.openInMemory()
        ..execute('PRAGMA user_version = 1');
      final database = AppDatabase.forTesting(
        NativeDatabase.opened(connection),
      );
      addTearDown(database.close);

      await database.putCacheEntry(
        key: 'guideline:test',
        payload: '{"id":"test"}',
        cachedAt: DateTime.utc(2026, 8, 13),
      );

      expect(await database.cacheEntry('guideline:test'), isNotNull);
      expect(
        await _tableNames(database),
        containsAll(<String>{
          'cached_entities',
          'cache_sync_states',
          'pending_mutations',
        }),
      );
      expect(await _userVersion(database), 2);
    },
  );
}

Future<Set<String>> _tableNames(AppDatabase database) async {
  final rows = await database
      .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
      .get();
  return rows.map((row) => row.read<String>('name')).toSet();
}

Future<int> _userVersion(AppDatabase database) async {
  final row = await database.customSelect('PRAGMA user_version').getSingle();
  return row.read<int>('user_version');
}
