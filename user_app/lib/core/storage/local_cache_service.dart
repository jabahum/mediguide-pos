// lib/core/database/services/local_cache_service.dart

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_app/core/storage/database/app_database.dart';

final localCacheServiceProvider = Provider<LocalCacheService>((ref) {
  return LocalCacheService(ref.watch(appDatabaseProvider));
});

class LocalCacheService {
  LocalCacheService(this._database);

  final AppDatabase _database;

  // =========================================================
  // WRITE
  // =========================================================

  Future<void> put({
    required String type,
    required String id,
    required Map<String, dynamic> data,
    String scope = 'public',
    String searchableText = '',
    Map<String, dynamic>? metadata,
    String? version,
    DateTime? remoteUpdatedAt,
    Duration? ttl,
  }) async {
    final now = DateTime.now().toUtc();

    await _database
        .into(_database.cachedEntities)
        .insertOnConflictUpdate(
          CachedEntitiesCompanion.insert(
            entityType: type,
            entityId: id,
            payload: jsonEncode(data),
            searchableText: Value(searchableText.toLowerCase()),
            metadata: Value(metadata == null ? null : jsonEncode(metadata)),
            scope: Value(scope),
            version: Value(version),
            remoteUpdatedAt: Value(remoteUpdatedAt),
            cachedAt: now,
            expiresAt: Value(ttl == null ? null : now.add(ttl)),
            isDeleted: const Value(false),
          ),
        );
  }

  // =========================================================
  // WRITE MANY
  // =========================================================

  Future<void> putMany({
    required String type,
    required Iterable<CachedEntityInput> entities,
    String scope = 'public',
    Duration? ttl,
  }) async {
    final now = DateTime.now().toUtc();
    final expiresAt = ttl == null ? null : now.add(ttl);

    await _database.batch((batch) {
      for (final entity in entities) {
        batch.insert(
          _database.cachedEntities,
          CachedEntitiesCompanion.insert(
            entityType: type,
            entityId: entity.id,
            payload: jsonEncode(entity.data),
            searchableText: Value(entity.searchableText.toLowerCase()),
            metadata: Value(
              entity.metadata == null ? null : jsonEncode(entity.metadata),
            ),
            scope: Value(scope),
            version: Value(entity.version),
            remoteUpdatedAt: Value(entity.remoteUpdatedAt),
            cachedAt: now,
            expiresAt: Value(expiresAt),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  // =========================================================
  // GET ONE
  // =========================================================

  Future<Map<String, dynamic>?> get({
    required String type,
    required String id,
    String scope = 'public',
  }) async {
    final query = _database.select(_database.cachedEntities)
      ..where(
        (table) =>
            table.entityType.equals(type) &
            table.entityId.equals(id) &
            table.scope.equals(scope) &
            table.isDeleted.equals(false),
      );

    final row = await query.getSingleOrNull();

    if (row == null) {
      return null;
    }

    return _decode(row.payload);
  }

  // =========================================================
  // LIST
  // =========================================================

  Future<List<Map<String, dynamic>>> list({
    required String type,
    String scope = 'public',
    String? search,
    int limit = 30,
    int offset = 0,
  }) async {
    final query = _database.select(_database.cachedEntities)
      ..where(
        (table) =>
            table.entityType.equals(type) &
            table.scope.equals(scope) &
            table.isDeleted.equals(false),
      );

    final searchValue = search?.trim().toLowerCase() ?? '';

    if (searchValue.isNotEmpty) {
      query.where((table) => table.searchableText.like('%$searchValue%'));
    }

    query
      ..orderBy([
        (table) => OrderingTerm.desc(table.remoteUpdatedAt),
        (table) => OrderingTerm.desc(table.cachedAt),
      ])
      ..limit(limit, offset: offset);

    final rows = await query.get();

    return rows
        .map((row) => _decode(row.payload))
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

  // =========================================================
  // WATCH
  // =========================================================

  Stream<List<Map<String, dynamic>>> watch({
    required String type,
    String scope = 'public',
  }) {
    final query = _database.select(_database.cachedEntities)
      ..where(
        (table) =>
            table.entityType.equals(type) &
            table.scope.equals(scope) &
            table.isDeleted.equals(false),
      );

    return query.watch().map((rows) {
      return rows
          .map((row) => _decode(row.payload))
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
    });
  }

  // =========================================================
  // DELETE
  // =========================================================

  Future<void> remove({
    required String type,
    required String id,
    String scope = 'public',
  }) async {
    await (_database.delete(_database.cachedEntities)..where(
          (table) =>
              table.entityType.equals(type) &
              table.entityId.equals(id) &
              table.scope.equals(scope),
        ))
        .go();
  }

  // =========================================================
  // DELETE TYPE
  // =========================================================

  Future<void> clearType({
    required String type,
    String scope = 'public',
  }) async {
    await (_database.delete(_database.cachedEntities)..where(
          (table) => table.entityType.equals(type) & table.scope.equals(scope),
        ))
        .go();
  }

  // =========================================================
  // CACHE EXISTS
  // =========================================================

  Future<bool> hasData({required String type, String scope = 'public'}) async {
    final query = _database.selectOnly(_database.cachedEntities)
      ..addColumns([_database.cachedEntities.entityId])
      ..where(
        _database.cachedEntities.entityType.equals(type) &
            _database.cachedEntities.scope.equals(scope) &
            _database.cachedEntities.isDeleted.equals(false),
      )
      ..limit(1);

    final result = await query.getSingleOrNull();

    return result != null;
  }

  // =========================================================
  // STALENESS
  // =========================================================

  Future<bool> isStale({
    required String type,
    String scope = 'public',
    Duration maxAge = const Duration(hours: 24),
  }) async {
    final query = _database.select(_database.cachedEntities)
      ..where(
        (table) => table.entityType.equals(type) & table.scope.equals(scope),
      )
      ..orderBy([(table) => OrderingTerm.desc(table.cachedAt)])
      ..limit(1);

    final row = await query.getSingleOrNull();

    if (row == null) {
      return true;
    }

    return DateTime.now().toUtc().difference(row.cachedAt) > maxAge;
  }

  // =========================================================
  // UTIL
  // =========================================================

  Map<String, dynamic>? _decode(String value) {
    try {
      final decoded = jsonDecode(value);

      if (decoded is! Map) {
        return null;
      }

      return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return null;
    }
  }
}

class CachedEntityInput {
  const CachedEntityInput({
    required this.id,
    required this.data,
    this.searchableText = '',
    this.metadata,
    this.version,
    this.remoteUpdatedAt,
  });

  final String id;
  final Map<String, dynamic> data;
  final String searchableText;
  final Map<String, dynamic>? metadata;
  final String? version;
  final DateTime? remoteUpdatedAt;
}
