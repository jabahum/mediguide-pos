import 'package:user_app/core/network/api_client.dart';
import 'package:user_app/core/storage/local_cache_service.dart';
import 'package:user_app/features/discovery/data/models/discovery_models.dart';

final class DiscoveryRepository {
  DiscoveryRepository(this._api, this._cache);
  final BackendApiService _api;
  final LocalCacheService _cache;
  static const _scope = 'public';
  static const _ttl = Duration(hours: 6);

  Future<DiscoveryValue<List<DiscoveryDisease>>> diseases({
    String search = '',
  }) async {
    const cacheId = 'directory';
    try {
      final response = await _api.requestJson(
        '/api/public/diseases',
        method: 'GET',
        includeAuth: false,
        query: {
          'page': '1',
          'per_page': '100',
          if (search.trim().isNotEmpty) 'search': search.trim(),
        },
      );
      final data = _data(response);
      final values = _maps(
        data['items'],
      ).map(DiscoveryDisease.fromJson).toList();
      if (search.trim().isEmpty) {
        await _cache.put(
          type: 'public_disease_directory',
          id: cacheId,
          scope: _scope,
          ttl: _ttl,
          data: {'items': values.map((e) => e.toJson()).toList()},
        );
      }
      return DiscoveryValue(values);
    } catch (_) {
      final cached = await _cache.get(
        type: 'public_disease_directory',
        id: cacheId,
        scope: _scope,
      );
      if (cached == null) rethrow;
      final all = _maps(
        cached['items'],
      ).map(DiscoveryDisease.fromJson).toList();
      final needle = search.trim().toLowerCase();
      return DiscoveryValue(
        needle.isEmpty
            ? all
            : all
                  .where(
                    (item) => '${item.name} ${item.aliases.join(' ')}'
                        .toLowerCase()
                        .contains(needle),
                  )
                  .toList(),
        offline: true,
      );
    }
  }

  Future<DiscoveryValue<DiscoveryDisease>> disease(String slug) => _detail(
    slug,
    'public_disease',
    '/api/public/diseases/$slug',
    DiscoveryDisease.fromJson,
    (value) => value.toJson(),
  );
  Future<DiscoveryValue<DiscoveryHub>> hub(String slug) => _detail(
    slug,
    'public_content_hub',
    '/api/public/hubs/$slug',
    DiscoveryHub.fromJson,
    (value) => value.toJson(),
  );

  Future<DiscoveryValue<T>> _detail<T>(
    String slug,
    String type,
    String path,
    T Function(Map<String, dynamic>) parse,
    Map<String, dynamic> Function(T) encode,
  ) async {
    final id = Uri.encodeComponent(slug.trim());
    try {
      final value = parse(
        _data(
          await _api.requestJson(
            path.replaceFirst(slug, id),
            method: 'GET',
            includeAuth: false,
          ),
        ),
      );
      await _cache.put(
        type: type,
        id: slug,
        scope: _scope,
        ttl: _ttl,
        data: encode(value),
      );
      return DiscoveryValue(value);
    } catch (_) {
      final cached = await _cache.get(type: type, id: slug, scope: _scope);
      if (cached == null) rethrow;
      return DiscoveryValue(parse(cached), offline: true);
    }
  }

  Map<String, dynamic> _data(Map<String, dynamic> response) =>
      response['data'] is Map
      ? Map<String, dynamic>.from(response['data'] as Map)
      : response;
  List<Map<String, dynamic>> _maps(dynamic value) =>
      (value as List? ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
}
