import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:user_app/shared/models/api_record.dart';
import 'package:user_app/shared/models/paginated_response.dart';
import 'package:user_app/core/network/api_client.dart';

final class ReadingProgressRepository {
  ReadingProgressRepository(this._api, {SharedPreferences? preferences})
    : _preferences = preferences;

  static const _cacheKey = 'local_reading_progress_records';
  final BackendApiService _api;
  SharedPreferences? _preferences;

  Future<ApiRecord?> forGuideline(String userId, String guidelineId) async {
    final local = await _localFor(userId, guidelineId);
    if (local != null && local['pending_sync'] == true) {
      await _trySync(local);
    }
    try {
      final response = await _api.requestJson(
        '/api/v2/reading-progress/$guidelineId',
        method: 'GET',
      );
      final record = _normalize(_data(response), userId: userId);
      await _saveRecord(record);
      return ApiRecord(record);
    } catch (_) {
      return local == null ? null : ApiRecord(local);
    }
  }

  Future<PaginatedResponse<ApiRecord>> inProgress(
    String userId, {
    int page = 1,
    int perPage = 20,
  }) async {
    await syncPending(userId);
    try {
      final response = await _api.requestJson(
        '/api/v2/reading-progress',
        method: 'GET',
        query: {
          'page': '$page',
          'per_page': '$perPage',
          'progress_min': '0.000001',
          'progress_max': '0.999999',
          'sort': 'last_read_at',
          'order': 'desc',
        },
      );
      final data = _data(response);
      final items = (data['items'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (value) =>
                _normalize(Map<String, dynamic>.from(value), userId: userId),
          )
          .toList();
      for (final item in items) {
        await _saveRecord(item);
      }
      return PaginatedResponse(
        page: (data['page'] as num?)?.toInt() ?? page,
        perPage: (data['per_page'] as num?)?.toInt() ?? perPage,
        totalItems: (data['total_items'] as num?)?.toInt() ?? items.length,
        totalPages: (data['total_pages'] as num?)?.toInt() ?? 0,
        items: items.map(ApiRecord.new).toList(),
      );
    } catch (_) {
      final rows =
          (await _read()).where((row) => row['user_id'] == userId).where((row) {
            final progress =
                (row['progress_percentage'] as num?)?.toDouble() ?? 0;
            return progress > 0 && progress < 1;
          }).toList()..sort(
            (a, b) => '${b['last_read_at']}'.compareTo('${a['last_read_at']}'),
          );
      final items = rows.take(perPage).map(ApiRecord.new).toList();
      return PaginatedResponse(
        page: 1,
        perPage: perPage,
        totalItems: rows.length,
        totalPages: rows.isEmpty ? 0 : (rows.length / perPage).ceil(),
        items: items,
      );
    }
  }

  Future<ApiRecord> upsert(
    String userId,
    String guidelineId,
    Map<String, dynamic> values,
  ) async {
    final existing = await _localFor(userId, guidelineId);
    final now = DateTime.now().toUtc().toIso8601String();
    final local = <String, dynamic>{
      ...?existing,
      ...values,
      'id': existing?['id'] ?? 'local-$guidelineId',
      'user_id': userId,
      'guideline_id': guidelineId,
      'guideline_document_id': guidelineId,
      'created': existing?['created'] ?? now,
      'updated': now,
      'pending_sync': true,
      'collectionId': 'reading_progress',
      'collectionName': 'reading_progress',
    };
    await _saveRecord(local);
    final synced = await _trySync(local);
    return ApiRecord(synced ?? local);
  }

  Future<void> syncPending(String userId) async {
    for (final row in await _read()) {
      if (row['user_id'] == userId && row['pending_sync'] == true) {
        await _trySync(row);
      }
    }
  }

  Future<Map<String, dynamic>?> _trySync(Map<String, dynamic> record) async {
    final guidelineId =
        record['guideline_document_id']?.toString() ??
        record['guideline_id']?.toString() ??
        '';
    if (guidelineId.isEmpty) return null;
    try {
      final payload = Map<String, dynamic>.from(record)
        ..removeWhere(
          (key, _) => {
            'id',
            'user_id',
            'guideline_id',
            'created',
            'updated',
            'pending_sync',
            'collectionId',
            'collectionName',
          }.contains(key),
        );
      final response = await _api.requestJson(
        '/api/v2/reading-progress/$guidelineId',
        method: 'PUT',
        body: payload,
      );
      final synced = _normalize(
        _data(response),
        userId: record['user_id']?.toString() ?? '',
      );
      await _saveRecord(synced);
      return synced;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _localFor(
    String userId,
    String guidelineId,
  ) async {
    for (final row in await _read()) {
      if (row['user_id'] == userId &&
          (row['guideline_document_id'] == guidelineId ||
              row['guideline_id'] == guidelineId)) {
        return row;
      }
    }
    return null;
  }

  Map<String, dynamic> _normalize(
    Map<String, dynamic> value, {
    required String userId,
  }) => {
    ...value,
    'user_id': userId,
    'guideline_id':
        value['guideline_document_id'] ?? value['guideline_id'] ?? '',
    'created': value['created_at'] ?? value['created'] ?? '',
    'updated': value['updated_at'] ?? value['updated'] ?? '',
    'pending_sync': false,
    'collectionId': 'reading_progress',
    'collectionName': 'reading_progress',
  };

  Future<SharedPreferences> get _prefs async =>
      _preferences ??= await SharedPreferences.getInstance();
  Future<List<Map<String, dynamic>>> _read() async {
    final raw = (await _prefs).getString(_cacheKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    return decoded is List
        ? decoded
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
        : [];
  }

  Future<void> _saveRecord(Map<String, dynamic> record) async {
    final rows = await _read();
    final index = rows.indexWhere(
      (row) =>
          row['user_id'] == record['user_id'] &&
          row['guideline_document_id'] == record['guideline_document_id'],
    );
    if (index < 0) {
      rows.add(record);
    } else {
      rows[index] = record;
    }
    await (await _prefs).setString(_cacheKey, jsonEncode(rows));
  }
}

final class UsageRepository {
  UsageRepository(this._api);
  final BackendApiService _api;

  Future<void> guideline(String id) => _record('guidelines', id);
  Future<void> abbreviation(String id) => _record('abbreviations', id);
  Future<void> consultant(String id) => _record('consultants', id);
  Future<void> ai() => _record('ai', null);

  Future<void> _record(String type, String? resourceId) async {
    final key =
        '$type-${resourceId ?? 'interaction'}-${DateTime.now().microsecondsSinceEpoch}';
    await _api.requestJson(
      '/api/v2/usage/$type',
      method: 'POST',
      body: {'resource_id': ?resourceId, 'idempotency_key': key},
    );
  }
}

Map<String, dynamic> _data(Map<String, dynamic> response) {
  final data = response['data'];
  return data is Map ? Map<String, dynamic>.from(data) : response;
}
