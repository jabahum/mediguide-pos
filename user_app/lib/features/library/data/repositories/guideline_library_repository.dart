import 'package:user_app/core/network/api_client.dart';
import 'package:user_app/core/network/contracts/generated/backend_contracts.dart';
import 'package:user_app/core/storage/local_cache_service.dart';
import 'package:user_app/features/library/data/models/guideline_library_models.dart';

final class GuidelineLibraryRepository {
  GuidelineLibraryRepository(this._api, this._cache);

  static const _collectionsType = 'guideline_library_collection';
  static const _downloadsType = 'guideline_library_download';
  final BackendApiService _api;
  final LocalCacheService _cache;

  String _scope(String userId) {
    final id = userId.trim();
    if (id.isEmpty) throw ArgumentError.value(userId, 'userId', 'is required');
    return 'user:$id';
  }

  Future<List<GuidelineCollectionSummary>> collections(String userId) async {
    final scope = _scope(userId);
    try {
      final response = await _api.requestJson(
        '/api/v2/library/collections',
        method: 'GET',
        query: const {
          'page': '1',
          'per_page': '100',
          'sort': 'updated_at',
          'order': 'desc',
        },
      );
      final data = _data(response);
      final items = _maps(data['items'])
          .map(ServicesGuidelineCollectionDTO.fromJson)
          .map(GuidelineCollectionSummary.fromContract)
          .toList(growable: false);
      await _cache.putMany(
        type: _collectionsType,
        scope: scope,
        entities: items.map(
          (item) => CachedEntityInput(
            id: item.id,
            data: item.toJson(),
            searchableText: '${item.name} ${item.description}',
            remoteUpdatedAt: item.updatedAt,
          ),
        ),
      );
      return items;
    } catch (_) {
      final cached = await _cache.list(
        type: _collectionsType,
        scope: scope,
        limit: 100,
      );
      if (cached.isEmpty) rethrow;
      return cached.map(GuidelineCollectionSummary.fromJson).toList();
    }
  }

  Future<List<GuidelineDownloadRecord>> downloads(String userId) async {
    final scope = _scope(userId);
    try {
      final response = await _api.requestJson(
        '/api/v2/library/downloads',
        method: 'GET',
        query: const {
          'page': '1',
          'per_page': '100',
          'sort': 'downloaded_at',
          'order': 'desc',
        },
      );
      final data = _data(response);
      final items = _maps(data['items'])
          .map(ServicesGuidelineDownloadDTO.fromJson)
          .map(GuidelineDownloadRecord.fromContract)
          .toList(growable: false);
      await _cache.putMany(
        type: _downloadsType,
        scope: scope,
        entities: items.map(
          (item) => CachedEntityInput(
            id: item.id,
            data: item.toJson(),
            searchableText: '${item.guidelineId} ${item.assetType}',
            remoteUpdatedAt: item.downloadedAt,
          ),
        ),
      );
      return items;
    } catch (_) {
      final cached = await _cache.list(
        type: _downloadsType,
        scope: scope,
        limit: 100,
      );
      if (cached.isEmpty) rethrow;
      return cached.map(GuidelineDownloadRecord.fromJson).toList();
    }
  }

  Future<GuidelineDownloadRecord> recordDownload({
    required String guidelineId,
    required String assetType,
  }) async {
    final response = await _api.requestJson(
      '/api/v2/library/downloads',
      method: 'POST',
      body: ServicesGuidelineDownloadInput.fromJson({
        'guideline_id': guidelineId,
        'asset_type': assetType,
      }).toJson(),
    );
    return GuidelineDownloadRecord.fromContract(
      ServicesGuidelineDownloadDTO.fromJson(_data(response)),
    );
  }

  Map<String, dynamic> _data(Map<String, dynamic> response) {
    final value = response['data'];
    return value is Map ? Map<String, dynamic>.from(value) : response;
  }

  List<Map<String, dynamic>> _maps(dynamic value) =>
      (value as List? ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
}
