import '../models/models.dart';
import '../services/backend_api_service.dart';

final class HelpContentRepository {
  HelpContentRepository(this._api);
  final BackendApiService _api;

  Future<PagedResult<FAQ>> listFAQs({
    int page = 1,
    int perPage = 10,
    String? search,
    bool? featured,
  }) async {
    final response = await _api.requestJson(
      '/api/v2/faqs',
      method: 'GET',
      query: {
        'page': '$page',
        'per_page': '$perPage',
        'sort': 'sort_order',
        'order': 'asc',
        if (search?.trim().isNotEmpty == true) 'search': search!.trim(),
        if (featured != null) 'is_featured': '$featured',
      },
    );
    final data = _data(response);
    final items = (data['items'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (v) => FAQ.fromJson(_normalize(Map<String, dynamic>.from(v), 'faqs')),
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

  Future<FAQ> getFAQ(String id) async {
    final response = await _api.requestJson('/api/v2/faqs/$id', method: 'GET');
    return FAQ.fromJson(_normalize(_data(response), 'faqs'));
  }

  Future<PagedResult<ApiRecord>> listDocumentation({
    int page = 1,
    int perPage = 20,
    String? search,
    String? category,
  }) async {
    final response = await _api.requestJson(
      '/api/v2/documentation',
      method: 'GET',
      query: {
        'page': '$page',
        'per_page': '$perPage',
        if (search?.trim().isNotEmpty == true) 'search': search!.trim(),
        if (category?.trim().isNotEmpty == true) 'category': category!.trim(),
      },
    );
    final data = _data(response);
    final items = (data['items'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (v) => ApiRecord(
            _normalize(Map<String, dynamic>.from(v), 'documentation'),
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

  Map<String, dynamic> _data(Map<String, dynamic> response) {
    final data = response['data'];
    return data is Map ? Map<String, dynamic>.from(data) : response;
  }

  Map<String, dynamic> _normalize(
    Map<String, dynamic> raw,
    String collection,
  ) => {
    ...raw,
    if (raw['author'] == null && raw['author_id'] != null)
      'author': raw['author_id'],
    if (raw['reviewer'] == null && raw['reviewer_id'] != null)
      'reviewer': raw['reviewer_id'],
    'collectionName': collection,
    'collectionId': collection,
    'created': raw['created_at']?.toString() ?? '',
    'updated': raw['updated_at']?.toString() ?? '',
  };
}
