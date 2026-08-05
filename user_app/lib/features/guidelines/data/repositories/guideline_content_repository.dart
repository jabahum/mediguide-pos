import 'package:user_app/shared/models/models.dart';
import 'package:user_app/core/network/api_client.dart';

final class GuidelineContentRepository {
  GuidelineContentRepository(this._api);

  final BackendApiService _api;

  Future<PagedResult<ApiRecord>> guidelines({
    int page = 1,
    int perPage = 30,
    String? search,
    String? status,
    String? categoryId,
    String? tagId,
    String? indexId,
    String? priority,
    String? healthcareLevel,
    String? targetPopulation,
    bool? published,
    String sort = 'updated_at',
    String order = 'desc',
  }) => _list(
    '/api/v2/medical-guidelines',
    Guideline.collection,
    page: page,
    perPage: perPage,
    query: {
      if (_present(search)) 'search': search!.trim(),
      if (_present(status)) 'status': status!,
      if (_present(categoryId)) 'category_id': categoryId!,
      if (_present(tagId)) 'tag_id': tagId!,
      if (_present(indexId)) 'parent_id': indexId!,
      if (_present(priority)) 'priority': priority!,
      if (_present(healthcareLevel)) 'healthcare_level': healthcareLevel!,
      if (_present(targetPopulation)) 'target_population': targetPopulation!,
      if (published != null) 'is_published': '$published',
      'sort': sort,
      'order': order,
    },
  );

  Future<ApiRecord> guideline(String id) =>
      _get('/api/v2/medical-guidelines/$id', Guideline.collection);

  Future<PagedResult<GuidelineCategory>> categories({
    int page = 1,
    int perPage = 100,
    String? search,
    String? status = 'active',
    String? parentId,
    bool rootOnly = false,
  }) => _typedList(
    '/api/v2/guideline-categories',
    GuidelineCategory.fromJson,
    page: page,
    perPage: perPage,
    query: {
      if (_present(search)) 'search': search!.trim(),
      if (_present(status)) 'status': status!,
      if (_present(parentId)) 'parent_id': parentId!,
      if (rootOnly) 'root_only': 'true',
      'sort': 'sort_order',
      'order': 'asc',
    },
  );

  Future<PagedResult<GuidelineTag>> tags({
    int page = 1,
    int perPage = 100,
    String? search,
  }) => _typedList(
    '/api/v2/guideline-tags',
    GuidelineTag.fromJson,
    page: page,
    perPage: perPage,
    query: {
      if (_present(search)) 'search': search!.trim(),
      'sort': 'name',
      'order': 'asc',
    },
  );

  Future<PagedResult<GuidelineIndex>> index({
    int page = 1,
    int perPage = 100,
    String? search,
    String? parentId,
    int? level,
  }) => _typedList(
    '/api/v2/guideline-index',
    GuidelineIndex.fromJson,
    page: page,
    perPage: perPage,
    query: {
      if (_present(search)) 'search': search!.trim(),
      if (_present(parentId)) 'parent_id': parentId!,
      if (level != null) 'level': '$level',
      'sort': 'sort_order',
      'order': 'asc',
    },
  );

  Future<PagedResult<GuidelineIndex>> indexChildren(
    String id, {
    int page = 1,
    int perPage = 100,
  }) => _typedList(
    '/api/v2/guideline-index/$id/children',
    GuidelineIndex.fromJson,
    page: page,
    perPage: perPage,
  );

  Future<PagedResult<ApiRecord>> abbreviations({
    int page = 1,
    int perPage = 30,
    String? search,
    bool? commonUsage,
    String? categoryId,
    String? tagId,
  }) => _list(
    '/api/v2/abbreviations',
    Abbreviation.collection,
    page: page,
    perPage: perPage,
    query: {
      if (_present(search)) 'search': search!.trim(),
      if (commonUsage != null) 'common_usage': '$commonUsage',
      if (_present(categoryId)) 'category_id': categoryId!,
      if (_present(tagId)) 'tag_id': tagId!,
      'sort': 'abbreviation',
      'order': 'asc',
    },
  );

  Future<ApiRecord> abbreviation(String id) =>
      _get('/api/v2/abbreviations/$id', Abbreviation.collection);

  Future<PagedResult<T>> _typedList<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson, {
    int page = 1,
    int perPage = 100,
    Map<String, String> query = const {},
  }) async {
    final response = await _api.requestJson(
      path,
      method: 'GET',
      query: {'page': '$page', 'per_page': '$perPage', ...query},
    );
    final data = _data(response);
    final items = (data['items'] as List? ?? const [])
        .whereType<Map>()
        .map((value) => fromJson(Map<String, dynamic>.from(value)))
        .toList(growable: false);
    return PagedResult(
      page: (data['page'] as num?)?.toInt() ?? page,
      perPage: (data['per_page'] as num?)?.toInt() ?? perPage,
      totalItems: (data['total_items'] as num?)?.toInt() ?? items.length,
      totalPages: (data['total_pages'] as num?)?.toInt() ?? 0,
      items: items,
    );
  }

  Future<PagedResult<ApiRecord>> _list(
    String path,
    String collectionName, {
    int page = 1,
    int perPage = 100,
    Map<String, String> query = const {},
  }) async {
    final response = await _api.requestJson(
      path,
      method: 'GET',
      query: {'page': '$page', 'per_page': '$perPage', ...query},
    );
    final data = _data(response);
    final items = (data['items'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (value) => ApiRecord(
            _normalize(Map<String, dynamic>.from(value), collectionName),
          ),
        )
        .toList();
    return PagedResult(
      page: (data['page'] as num?)?.toInt() ?? page,
      perPage: (data['per_page'] as num?)?.toInt() ?? perPage,
      totalItems: (data['total_items'] as num?)?.toInt() ?? items.length,
      totalPages: (data['total_pages'] as num?)?.toInt() ?? 0,
      items: items,
    );
  }

  Future<ApiRecord> _get(String path, String collectionName) async {
    final response = await _api.requestJson(path, method: 'GET');
    return ApiRecord(_normalize(_data(response), collectionName));
  }

  Map<String, dynamic> _data(Map<String, dynamic> response) {
    final data = response['data'];
    return data is Map ? Map<String, dynamic>.from(data) : response;
  }

  Map<String, dynamic> _normalize(
    Map<String, dynamic> raw,
    String collectionName,
  ) {
    final value = <String, dynamic>{
      ...raw,
      'collectionName': collectionName,
      'collectionId': collectionName,
      'created': raw['created_at']?.toString() ?? '',
      'updated': raw['updated_at']?.toString() ?? '',
    };
    switch (collectionName) {
      case Guideline.collection:
        value['index_item'] = raw['index_item_id']?.toString() ?? '';
        value['usageCount'] = (raw['usage_count'] as num?)?.toInt() ?? 0;
        break;
      case Abbreviation.collection:
        final categories = (raw['categories'] as List? ?? const [])
            .map((e) => e.toString())
            .toList();
        value['category'] = categories.isEmpty ? '' : categories.first;
        value['usageCount'] = (raw['usage_count'] as num?)?.toInt() ?? 0;
        break;
    }
    return value;
  }

  static bool _present(String? value) => value?.trim().isNotEmpty == true;
}
