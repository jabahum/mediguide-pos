import 'package:user_app/core/storage/local_cache_service.dart';
import 'package:user_app/shared/models/paginated_response.dart';
import 'package:user_app/core/network/api_client.dart';
import 'package:user_app/features/guidelines/data/models/reading_progress.dart';

final class ReadingProgressRepository {
  ReadingProgressRepository(this._api, this._localCacheService);

  final BackendApiService _api;
  final LocalCacheService _localCacheService;

  static const String _entityType = 'reading_progress';

  // =========================================================
  // SCOPE
  // =========================================================

  String _scope(String userId) {
    final normalized = userId.trim();

    if (normalized.isEmpty) {
      throw ArgumentError.value(userId, 'userId', 'User id is required');
    }

    return 'user:$normalized';
  }

  // =========================================================
  // ENTITY ID
  // =========================================================
  //
  // There should only ever be one reading progress record for
  // a user + guideline combination.
  //
  // Because the LocalCacheService already separates records by
  // scope, guidelineId is enough as the local entity id.
  // =========================================================

  String _entityId(String guidelineId) {
    final normalized = guidelineId.trim();

    if (normalized.isEmpty) {
      throw ArgumentError.value(
        guidelineId,
        'guidelineId',
        'Guideline id is required',
      );
    }

    return normalized;
  }

  // =========================================================
  // GET PROGRESS FOR GUIDELINE
  // =========================================================

  Future<ReadingProgress?> forGuideline(
    String userId,
    String guidelineId,
  ) async {
    final local = await _localFor(userId, guidelineId);

    // ---------------------------------------------------------
    // Try to push unsynced local changes first.
    // ---------------------------------------------------------

    if (local != null && local['pending_sync'] == true) {
      await _trySync(local);
    }

    try {
      final response = await _api.requestJson(
        '/api/v2/reading-progress/${Uri.encodeComponent(guidelineId)}',
        method: 'GET',
      );

      final record = _normalize(_data(response), userId: userId);

      await _saveRecord(record);

      return ReadingProgress.fromJson(record);
    } catch (_) {
      if (local == null) {
        return null;
      }

      return ReadingProgress.fromJson(local);
    }
  }

  // =========================================================
  // IN-PROGRESS GUIDELINES
  // =========================================================

  Future<PaginatedResponse<ReadingProgress>> inProgress(
    String userId, {
    int page = 1,
    int perPage = 20,
  }) async {
    final safePage = page < 1 ? 1 : page;
    final safePerPage = perPage < 1 ? 20 : perPage;

    // Best-effort synchronization.
    await syncPending(userId);

    try {
      final response = await _api.requestJson(
        '/api/v2/reading-progress',
        method: 'GET',
        query: {
          'page': '$safePage',
          'per_page': '$safePerPage',
          'progress_min': '0.000001',
          'progress_max': '0.999999',
          'sort': 'last_read_at',
          'order': 'desc',
        },
      );

      final data = _data(response);

      final rows = (data['items'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (value) =>
                _normalize(Map<String, dynamic>.from(value), userId: userId),
          )
          .toList(growable: false);

      // -------------------------------------------------------
      // Persist all remote progress records.
      // -------------------------------------------------------

      for (final row in rows) {
        try {
          await _saveRecord(row);
        } catch (_) {
          // Cache writes are best effort for remote responses.
        }
      }

      final items = rows.map(ReadingProgress.fromJson).toList(growable: false);

      return PaginatedResponse<ReadingProgress>(
        page: (data['page'] as num?)?.toInt() ?? safePage,
        perPage: (data['per_page'] as num?)?.toInt() ?? safePerPage,
        totalItems: (data['total_items'] as num?)?.toInt() ?? items.length,
        totalPages:
            (data['total_pages'] as num?)?.toInt() ??
            _totalPages(items.length, safePerPage),
        items: items,
      );
    } catch (_) {
      return _localInProgress(userId, page: safePage, perPage: safePerPage);
    }
  }

  // =========================================================
  // UPSERT
  // =========================================================
  //
  // IMPORTANT:
  //
  // Local persistence happens FIRST.
  //
  // This means:
  //
  // - scrolling progress works offline
  // - bookmark changes work offline
  // - completion works offline
  //
  // The record is marked pending_sync until the API confirms it.
  // =========================================================

  Future<ReadingProgress> upsert(
    String userId,
    String guidelineId,
    Map<String, dynamic> values,
  ) async {
    final normalizedGuidelineId = _entityId(guidelineId);

    final existing = await _localFor(userId, normalizedGuidelineId);

    final now = DateTime.now().toUtc().toIso8601String();

    final local = <String, dynamic>{
      ...?existing,
      ...values,

      'id': existing?['id'] ?? 'local-$normalizedGuidelineId',

      'user_id': userId,

      'guideline_id': normalizedGuidelineId,

      'guideline_document_id': normalizedGuidelineId,

      'created_at': existing?['created_at'] ?? now,

      'updated_at': now,

      'pending_sync': true,
    };

    // ---------------------------------------------------------
    // Save immediately before trying the network.
    // ---------------------------------------------------------

    await _saveRecord(local);

    // ---------------------------------------------------------
    // Best-effort remote synchronization.
    // ---------------------------------------------------------

    final synced = await _trySync(local);

    return ReadingProgress.fromJson(synced ?? local);
  }

  // =========================================================
  // SYNC PENDING
  // =========================================================

  Future<void> syncPending(String userId) async {
    final rows = await _readUserRecords(userId);

    for (final row in rows) {
      if (row['pending_sync'] == true) {
        await _trySync(row);
      }
    }
  }

  // =========================================================
  // SYNC SINGLE RECORD
  // =========================================================

  Future<Map<String, dynamic>?> _trySync(Map<String, dynamic> record) async {
    final guidelineId =
        record['guideline_document_id']?.toString().trim() ??
        record['guideline_id']?.toString().trim() ??
        '';

    final userId = record['user_id']?.toString().trim() ?? '';

    if (guidelineId.isEmpty || userId.isEmpty) {
      return null;
    }

    try {
      final payload = Map<String, dynamic>.from(record)
        ..removeWhere(
          (key, _) => {
            'id',
            'user_id',
            'guideline_id',
            'created_at',
            'updated_at',
            'pending_sync',
          }.contains(key),
        );

      final response = await _api.requestJson(
        '/api/v2/reading-progress/${Uri.encodeComponent(guidelineId)}',
        method: 'PUT',
        body: payload,
      );

      final synced = _normalize(_data(response), userId: userId);

      await _saveRecord(synced);

      return synced;
    } catch (_) {
      // -------------------------------------------------------
      // Keep pending_sync=true.
      //
      // The next:
      //
      // - app startup
      // - home load
      // - guideline open
      // - explicit sync
      //
      // can retry this record.
      // -------------------------------------------------------

      return null;
    }
  }

  // =========================================================
  // LOCAL SINGLE RECORD
  // =========================================================

  Future<Map<String, dynamic>?> _localFor(String userId, String guidelineId) {
    return _localCacheService.get(
      type: _entityType,
      id: _entityId(guidelineId),
      scope: _scope(userId),
    );
  }

  // =========================================================
  // LOCAL IN-PROGRESS
  // =========================================================

  Future<PaginatedResponse<ReadingProgress>> _localInProgress(
    String userId, {
    required int page,
    required int perPage,
  }) async {
    final rows = await _readUserRecords(userId);

    final filtered = rows.where((row) {
      final progress = (row['progress_percentage'] as num?)?.toDouble() ?? 0;

      return progress > 0 && progress < 1;
    }).toList();

    filtered.sort((a, b) {
      final aDate = _date(a['last_read_at']);

      final bDate = _date(b['last_read_at']);

      return bDate.compareTo(aDate);
    });

    final paginated = _paginate(filtered, page: page, perPage: perPage);

    final items = <ReadingProgress>[];

    for (final row in paginated) {
      try {
        items.add(ReadingProgress.fromJson(row));
      } catch (_) {
        // Ignore malformed cache records.
      }
    }

    return PaginatedResponse<ReadingProgress>(
      page: page,
      perPage: perPage,
      totalItems: filtered.length,
      totalPages: _totalPages(filtered.length, perPage),
      items: items,
    );
  }

  // =========================================================
  // READ USER RECORDS
  // =========================================================

  Future<List<Map<String, dynamic>>> _readUserRecords(String userId) {
    return _localCacheService.list(
      type: _entityType,
      scope: _scope(userId),
      limit: 1000,
      offset: 0,
    );
  }

  // =========================================================
  // SAVE RECORD
  // =========================================================

  Future<void> _saveRecord(Map<String, dynamic> record) async {
    final userId = record['user_id']?.toString().trim() ?? '';

    final guidelineId =
        record['guideline_document_id']?.toString().trim() ??
        record['guideline_id']?.toString().trim() ??
        '';

    if (userId.isEmpty || guidelineId.isEmpty) {
      return;
    }

    await _localCacheService.put(
      type: _entityType,
      id: guidelineId,
      scope: _scope(userId),
      data: record,

      searchableText: [
        guidelineId,
        record['current_section']?.toString() ?? '',
      ].where((value) => value.trim().isNotEmpty).join(' ').toLowerCase(),

      metadata: {
        'guidelineId': guidelineId,

        'currentSection': record['current_section'],

        'progress': (record['progress_percentage'] as num?)?.toDouble(),

        'completed': record['is_completed'] == true,

        'bookmarked': record['is_bookmarked'] == true,

        'pendingSync': record['pending_sync'] == true,

        'lastReadAt': record['last_read_at'],
      },

      remoteUpdatedAt: _dateOrNull(record['updated_at']),
    );
  }

  // =========================================================
  // NORMALIZE
  // =========================================================

  Map<String, dynamic> _normalize(
    Map<String, dynamic> value, {
    required String userId,
  }) {
    final guidelineId =
        value['guideline_document_id'] ?? value['guideline_id'] ?? '';

    return {
      ...value,

      'user_id': userId,

      'guideline_id': guidelineId,

      'guideline_document_id': guidelineId,

      'created_at': value['created_at'] ?? value['created'] ?? '',

      'updated_at': value['updated_at'] ?? value['updated'] ?? '',

      'pending_sync': false,
    };
  }

  // =========================================================
  // CLEAR USER DATA
  // =========================================================

  Future<void> clearUserProgress(String userId) {
    return _localCacheService.clearType(
      type: _entityType,
      scope: _scope(userId),
    );
  }

  // =========================================================
  // CACHE STATUS
  // =========================================================

  Future<bool> hasCachedProgress(String userId) {
    return _localCacheService.hasData(type: _entityType, scope: _scope(userId));
  }

  // =========================================================
  // WATCH
  // =========================================================

  Stream<List<ReadingProgress>> watchProgress(String userId) {
    return _localCacheService
        .watch(type: _entityType, scope: _scope(userId))
        .map((rows) {
          final result = <ReadingProgress>[];

          for (final row in rows) {
            try {
              result.add(ReadingProgress.fromJson(row));
            } catch (_) {
              // Ignore malformed cached rows.
            }
          }

          result.sort((a, b) => b.lastReadAt.compareTo(a.lastReadAt));

          return List<ReadingProgress>.unmodifiable(result);
        });
  }

  // =========================================================
  // HELPERS
  // =========================================================

  List<T> _paginate<T>(
    List<T> items, {
    required int page,
    required int perPage,
  }) {
    final start = (page - 1) * perPage;

    if (start >= items.length) {
      return <T>[];
    }

    final end = (start + perPage).clamp(0, items.length);

    return items.sublist(start, end);
  }

  int _totalPages(int totalItems, int perPage) {
    if (totalItems <= 0 || perPage <= 0) {
      return 0;
    }

    return (totalItems / perPage).ceil();
  }

  DateTime _date(dynamic value) {
    return _dateOrNull(value) ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  DateTime? _dateOrNull(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(value.toString());
  }
}

// ===========================================================
// USAGE / ANALYTICS
// ===========================================================
//
// Usage telemetry remains best-effort.
//
// We deliberately DO NOT make a failed usage event prevent:
// - reading guidelines
// - opening abbreviations
// - viewing consultants
// - using AI
//
// Later this repository can write events to the generic pending
// mutation queue and upload them when connectivity returns.
// ===========================================================

final class UsageRepository {
  UsageRepository(this._api);

  final BackendApiService _api;

  Future<void> guideline(String id) {
    return _record('guidelines', id);
  }

  Future<void> abbreviation(String id) {
    return _record('abbreviations', id);
  }

  Future<void> consultant(String id) {
    return _record('consultants', id);
  }

  Future<void> ai() {
    return _record('ai', null);
  }

  Future<void> _record(String type, String? resourceId) async {
    final key =
        '$type-'
        '${resourceId ?? 'interaction'}-'
        '${DateTime.now().microsecondsSinceEpoch}';

    await _api.requestJson(
      '/api/v2/usage/$type',
      method: 'POST',
      body: {
        if (resourceId != null) 'resource_id': resourceId,
        'idempotency_key': key,
      },
    );
  }
}

// ===========================================================
// API RESPONSE
// ===========================================================

Map<String, dynamic> _data(Map<String, dynamic> response) {
  final data = response['data'];

  return data is Map ? Map<String, dynamic>.from(data) : response;
}
