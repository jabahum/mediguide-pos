// lib/core/database/services/local_cache_service.dart

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_app/core/storage/database/app_database.dart';
import 'package:user_app/core/storage/database/database_provider.dart';

final localCacheServiceProvider = Provider<LocalCacheService>((ref) {
  return LocalCacheService(ref.watch(appDatabaseProvider));
});

class LocalCacheService {
  LocalCacheService(this._database);

  final AppDatabase _database;

  /// Atomically stores a complete server snapshot and optionally tombstones
  /// records that disappeared from the canonical, unfiltered response.
  Future<void> replaceSnapshot({
    required String type,
    required String snapshotType,
    required String snapshotId,
    required Iterable<CachedEntityInput> entities,
    String scope = 'public',
    Duration? ttl,
    bool reconcileMissing = false,
    Map<String, dynamic> snapshotData = const <String, dynamic>{},
  }) async {
    final rows = entities.toList(growable: false);
    final now = DateTime.now().toUtc();
    final expiresAt = ttl == null ? null : now.add(ttl);
    final ids = rows.map((row) => row.id).toSet();

    await _database.transaction(() async {
      await _database.batch((batch) {
        for (final entity in rows) {
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
              isDeleted: const Value(false),
            ),
            mode: InsertMode.insertOrReplace,
          );
        }
        batch.insert(
          _database.cachedEntities,
          CachedEntitiesCompanion.insert(
            entityType: snapshotType,
            entityId: snapshotId,
            payload: jsonEncode({
              ...snapshotData,
              'ids': ids.toList(growable: false),
            }),
            scope: Value(scope),
            cachedAt: now,
            expiresAt: Value(expiresAt),
            isDeleted: const Value(false),
          ),
          mode: InsertMode.insertOrReplace,
        );
      });

      if (reconcileMissing) {
        final update = _database.update(_database.cachedEntities)
          ..where(
            (table) =>
                table.entityType.equals(type) &
                table.scope.equals(scope) &
                table.isDeleted.equals(false) &
                (ids.isEmpty
                    ? const Constant(true)
                    : table.entityId.isNotIn(ids)),
          );
        await update.write(
          const CachedEntitiesCompanion(isDeleted: Value(true)),
        );
      }
    });
  }

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

  Future<CachedEntityValue?> getEntry({
    required String type,
    required String id,
    String scope = 'public',
    bool includeDeleted = false,
  }) async {
    final query = _database.select(_database.cachedEntities)
      ..where(
        (table) =>
            table.entityType.equals(type) &
            table.entityId.equals(id) &
            table.scope.equals(scope) &
            (includeDeleted
                ? const Constant(true)
                : table.isDeleted.equals(false)),
      );
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    final data = _decode(row.payload);
    if (data == null) return null;
    return CachedEntityValue(
      data: data,
      cachedAt: row.cachedAt,
      expiresAt: row.expiresAt,
      remoteUpdatedAt: row.remoteUpdatedAt,
      isDeleted: row.isDeleted,
    );
  }

  Future<void> tombstone({
    required String type,
    required String id,
    String scope = 'public',
  }) async {
    await (_database.update(_database.cachedEntities)..where(
          (table) =>
              table.entityType.equals(type) &
              table.entityId.equals(id) &
              table.scope.equals(scope),
        ))
        .write(const CachedEntitiesCompanion(isDeleted: Value(true)));
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

  /// Deletes every cache, synchronization record and queued mutation owned by
  /// one authenticated scope. Public content is intentionally retained.
  Future<void> clearPrivateScope(String userId) async {
    final normalized = userId.trim();
    if (normalized.isEmpty) return;
    final scope = 'user:$normalized';
    await _database.transaction(() async {
      await (_database.delete(
        _database.cachedEntities,
      )..where((table) => table.scope.equals(scope))).go();
      await (_database.delete(
        _database.cacheSyncStates,
      )..where((table) => table.scope.equals(scope))).go();
      await (_database.delete(
        _database.pendingMutations,
      )..where((table) => table.scope.equals(scope))).go();
    });
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

final class CachedEntityValue {
  const CachedEntityValue({
    required this.data,
    required this.cachedAt,
    required this.isDeleted,
    this.expiresAt,
    this.remoteUpdatedAt,
  });

  final Map<String, dynamic> data;
  final DateTime cachedAt;
  final DateTime? expiresAt;
  final DateTime? remoteUpdatedAt;
  final bool isDeleted;
}
