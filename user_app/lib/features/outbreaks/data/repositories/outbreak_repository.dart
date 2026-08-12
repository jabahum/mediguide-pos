import 'package:user_app/core/network/api_client.dart';
import 'package:user_app/core/network/contracts/generated/backend_contracts.dart';
import 'package:user_app/core/storage/local_cache_service.dart';
import 'package:user_app/features/outbreaks/data/models/outbreak_models.dart';

final class OutbreakRepository {
  OutbreakRepository(this._api, this._cache);

  static const _outbreakType = 'public_outbreak';
  static const _detailType = 'public_outbreak_detail';
  static const _reportType = 'public_situation_report';
  static const _ttl = Duration(hours: 2);
  final BackendApiService _api;
  final LocalCacheService _cache;

  Future<List<PublicOutbreak>> outbreaks({
    String search = '',
    String status = '',
  }) async {
    try {
      final response = await _public(
        '/api/public/outbreaks',
        query: {
          'page': '1',
          'per_page': '100',
          if (search.trim().isNotEmpty) 'search': search.trim(),
          if (status.trim().isNotEmpty) 'status': status.trim(),
          'sort': 'last_update',
          'order': 'desc',
        },
      );
      final items = _maps(_data(response)['items'])
          .map(ModelsOutbreak.fromJson)
          .map((value) => PublicOutbreak.fromJson(value.toJson()))
          .toList(growable: false);
      await _cache.putMany(
        type: _outbreakType,
        scope: 'public',
        ttl: _ttl,
        entities: items.map(
          (item) => CachedEntityInput(
            id: item.id,
            data: item.toJson(),
            searchableText:
                '${item.title} ${item.summary} ${item.diseaseType} ${item.geographicArea}',
            remoteUpdatedAt: item.lastUpdate,
          ),
        ),
      );
      return items;
    } catch (_) {
      final cached = await _cache.list(
        type: _outbreakType,
        scope: 'public',
        search: search,
        limit: 100,
      );
      if (cached.isEmpty) rethrow;
      return cached
          .map(PublicOutbreak.fromJson)
          .where((item) => status.isEmpty || item.status == status)
          .toList(growable: false);
    }
  }

  Future<PublicOutbreakDetail> outbreak(String id) async {
    final normalized = _id(id);
    try {
      final responses = await Future.wait([
        _public('/api/public/outbreaks/$normalized'),
        _public(
          '/api/public/outbreaks/$normalized/updates',
          query: const {'page': '1', 'per_page': '100'},
        ),
        _public(
          '/api/public/outbreaks/$normalized/resources',
          query: const {'page': '1', 'per_page': '100'},
        ),
        _public(
          '/api/public/situation-reports',
          query: {'page': '1', 'per_page': '100', 'outbreak_id': normalized},
        ),
      ]);
      final value = PublicOutbreakDetail(
        outbreak: PublicOutbreak.fromJson(
          ModelsOutbreak.fromJson(_data(responses[0])).toJson(),
        ),
        updates: _maps(_data(responses[1])['items'])
            .map(ModelsOutbreakUpdate.fromJson)
            .map((item) => PublicOutbreakUpdate.fromJson(item.toJson()))
            .toList(),
        resources: _maps(_data(responses[2])['items'])
            .map(ModelsOutbreakResource.fromJson)
            .map((item) => PublicOutbreakResource.fromJson(item.toJson()))
            .toList(),
        reports: _maps(_data(responses[3])['items'])
            .map(ModelsSituationReport.fromJson)
            .map((item) => PublicSituationReport.fromJson(item.toJson()))
            .toList(),
      );
      await _cache.put(
        type: _detailType,
        id: normalized,
        scope: 'public',
        ttl: _ttl,
        data: {
          'outbreak': value.outbreak.toJson(),
          'updates': value.updates.map((item) => item.toJson()).toList(),
          'resources': value.resources.map((item) => item.toJson()).toList(),
          'reports': value.reports.map((item) => item.toJson()).toList(),
        },
        searchableText: value.outbreak.title,
        remoteUpdatedAt: value.outbreak.lastUpdate,
      );
      return value;
    } catch (_) {
      final cached = await _cache.get(
        type: _detailType,
        id: normalized,
        scope: 'public',
      );
      if (cached == null) rethrow;
      return PublicOutbreakDetail(
        outbreak: PublicOutbreak.fromJson(_map(cached['outbreak'])),
        updates: _maps(
          cached['updates'],
        ).map(PublicOutbreakUpdate.fromJson).toList(),
        resources: _maps(
          cached['resources'],
        ).map(PublicOutbreakResource.fromJson).toList(),
        reports: _maps(
          cached['reports'],
        ).map(PublicSituationReport.fromJson).toList(),
      );
    }
  }

  Future<List<PublicSituationReport>> reports({String search = ''}) async {
    try {
      final response = await _public(
        '/api/public/situation-reports',
        query: {
          'page': '1',
          'per_page': '100',
          if (search.trim().isNotEmpty) 'search': search.trim(),
          'sort': 'publication_date',
          'order': 'desc',
        },
      );
      final items = _maps(_data(response)['items'])
          .map(ModelsSituationReport.fromJson)
          .map((value) => PublicSituationReport.fromJson(value.toJson()))
          .toList(growable: false);
      await _cache.putMany(
        type: _reportType,
        scope: 'public',
        ttl: _ttl,
        entities: items.map(
          (item) => CachedEntityInput(
            id: item.id,
            data: item.toJson(),
            searchableText:
                '${item.title} ${item.summary} ${item.geographicArea}',
            remoteUpdatedAt: item.publicationDate,
          ),
        ),
      );
      return items;
    } catch (_) {
      final cached = await _cache.list(
        type: _reportType,
        scope: 'public',
        search: search,
        limit: 100,
      );
      if (cached.isEmpty) rethrow;
      return cached.map(PublicSituationReport.fromJson).toList();
    }
  }

  Future<PublicSituationReport> report(String id) async {
    final normalized = _id(id);
    try {
      final response = await _public(
        '/api/public/situation-reports/$normalized',
      );
      final value = PublicSituationReport.fromJson(
        ModelsSituationReport.fromJson(_data(response)).toJson(),
      );
      await _cache.put(
        type: _reportType,
        id: normalized,
        scope: 'public',
        ttl: _ttl,
        data: value.toJson(),
        searchableText: '${value.title} ${value.summary}',
        remoteUpdatedAt: value.publicationDate,
      );
      return value;
    } catch (_) {
      final cached = await _cache.get(
        type: _reportType,
        id: normalized,
        scope: 'public',
      );
      if (cached == null) rethrow;
      return PublicSituationReport.fromJson(cached);
    }
  }

  Future<Map<String, dynamic>> _public(
    String path, {
    Map<String, String>? query,
  }) => _api.requestJson(path, method: 'GET', includeAuth: false, query: query);

  String _id(String value) {
    final id = value.trim();
    if (id.isEmpty) throw ArgumentError.value(value, 'id', 'is required');
    return Uri.encodeComponent(id);
  }

  Map<String, dynamic> _data(Map<String, dynamic> response) =>
      response['data'] is Map ? _map(response['data']) : response;
  Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
  List<Map<String, dynamic>> _maps(dynamic value) =>
      (value as List? ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
}
