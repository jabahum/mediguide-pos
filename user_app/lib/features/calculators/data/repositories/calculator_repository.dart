import 'package:user_app/core/constants/app_constants.dart';
import 'package:user_app/shared/models/models.dart';
import 'package:user_app/core/network/api_client.dart';

final class CalculatorRepository {
  CalculatorRepository(this._api);
  final BackendApiService _api;

  Future<PaginatedResponse<Calculator>> list({
    int page = 1,
    int perPage = 30,
    String? search,
    List<String> types = const [],
    List<String> statuses = const [],
    bool? featured,
    String sort = 'created_at',
    String order = 'desc',
  }) async {
    final response = await _api.requestJson(
      '/api/v2/calculators',
      method: 'GET',
      query: {
        'page': '$page',
        'per_page': '$perPage',
        if (_present(search)) 'search': search!.trim(),
        if (types.isNotEmpty) 'type': types.join(','),
        if (statuses.isNotEmpty) 'status': statuses.join(','),
        if (featured != null) 'featured': '$featured',
        'sort': sort,
        'order': order,
      },
    );
    final data = _data(response);
    final items = (data['items'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => Calculator.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
    return PaginatedResponse(
      items: items,
      page: (data['page'] as num?)?.toInt() ?? page,
      perPage: (data['per_page'] as num?)?.toInt() ?? perPage,
      totalItems: (data['total_items'] as num?)?.toInt() ?? items.length,
      totalPages: (data['total_pages'] as num?)?.toInt() ?? 0,
    );
  }

  Future<String> content(String id) =>
      _api.requestText('/api/v2/calculators/$id/content');

  Future<Calculator> get(String id) async {
    final response = await _api.requestJson(
      '/api/v2/calculators/$id',
      method: 'GET',
    );
    return Calculator.fromJson(_itemData(response));
  }

  String contentUrl(String id) =>
      '$mediguideApiBaseUrl/api/v2/calculators/$id/content';

  Future<CalculatorUsageLog> startUsage({
    required String calculatorId,
    required String sessionStart,
    required String calculatorType,
  }) async {
    final response = await _api.requestJson(
      '/api/v2/calculators/$calculatorId/usage',
      method: 'POST',
      body: {'session_start': sessionStart, 'calculator_type': calculatorType},
    );
    return CalculatorUsageLog.fromJson(_itemData(response));
  }

  Future<CalculatorUsageLog> finishUsage({
    required String usageId,
    required String sessionEnd,
  }) async {
    final response = await _api.requestJson(
      '/api/v2/calculator-usage/$usageId',
      method: 'PATCH',
      body: {'session_end': sessionEnd},
    );
    return CalculatorUsageLog.fromJson(_itemData(response));
  }
}

final class DrugRepository {
  DrugRepository(this._api);
  final BackendApiService _api;

  Future<PaginatedResponse<ApiRecord>> list({
    int page = 1,
    int perPage = 30,
    String? search,
    String? status,
    String? reviewStatus,
    String? drugClassId,
    String? therapeuticCategoryId,
    String? route,
    String? pregnancyCategory,
    bool? whoEml,
    bool? antimicrobial,
    String sort = 'name',
    String order = 'asc',
  }) async {
    final response = await _api.requestJson(
      '/api/v2/drugs',
      method: 'GET',
      query: {
        'page': '$page',
        'per_page': '$perPage',
        if (_present(search)) 'search': search!.trim(),
        if (_present(status)) 'status': status!,
        if (_present(reviewStatus)) 'review_status': reviewStatus!,
        if (_present(drugClassId)) 'drug_class_id': drugClassId!,
        if (_present(therapeuticCategoryId))
          'therapeutic_category_id': therapeuticCategoryId!,
        if (_present(route)) 'route': route!,
        if (_present(pregnancyCategory))
          'pregnancy_category': pregnancyCategory!,
        if (whoEml != null) 'who_eml': '$whoEml',
        if (antimicrobial != null) 'antimicrobial': '$antimicrobial',
        'sort': sort,
        'order': order,
      },
    );
    return _page(response, Drug.collection, page, perPage);
  }

  Future<ApiRecord?> get(String id) async {
    try {
      final response = await _api.requestJson(
        '/api/v2/drugs/$id',
        method: 'GET',
      );
      return ApiRecord(_normalize(_data(response), Drug.collection));
    } catch (_) {
      return null;
    }
  }

  Future<void> recordUsage(String id) async {
    await _api.requestJson('/api/v2/drugs/$id/usage', method: 'POST');
  }
}

PaginatedResponse<ApiRecord> _page(
  Map<String, dynamic> response,
  String kind,
  int page,
  int perPage,
) {
  final data = _data(response);
  final items = (data['items'] as List? ?? const [])
      .whereType<Map>()
      .map(
        (item) => ApiRecord(_normalize(Map<String, dynamic>.from(item), kind)),
      )
      .toList();
  return PaginatedResponse(
    items: items,
    page: (data['page'] as num?)?.toInt() ?? page,
    perPage: (data['per_page'] as num?)?.toInt() ?? perPage,
    totalItems: (data['total_items'] as num?)?.toInt() ?? items.length,
    totalPages: (data['total_pages'] as num?)?.toInt() ?? 0,
  );
}

Map<String, dynamic> _normalize(Map<String, dynamic> raw, String kind) {
  final result = <String, dynamic>{
    ...raw,
    'collectionName': kind,
    'collectionId': kind,
    'created': raw['created_at']?.toString() ?? '',
    'updated': raw['updated_at']?.toString() ?? '',
  };
  for (final entry in raw.entries) {
    final key = entry.key;
    if (key.contains('_')) result[_camel(key)] = entry.value;
    if (key.endsWith('_json')) {
      final alias = key.substring(0, key.length - 5);
      result[alias] = entry.value;
      result[_camel(alias)] = entry.value;
    }
  }
  if (kind == Drug.collection) {
    result['drug_class'] = raw['drug_class_id']?.toString() ?? '';
    result['therapeutic_category'] =
        raw['therapeutic_category_id']?.toString() ?? '';
    result['categories'] =
        raw['categories'] ?? raw['categories_json'] ?? const [];
    result['tags'] = raw['tags'] ?? raw['tags_json'] ?? const [];
    result['expand'] = {
      if (raw['drug_class_id'] != null)
        'drug_class': {
          'id': raw['drug_class_id'],
          'name': raw['drug_class_name'] ?? '',
        },
      if (raw['therapeutic_category_id'] != null)
        'therapeutic_category': {
          'id': raw['therapeutic_category_id'],
          'name': raw['therapeutic_category_name'] ?? '',
        },
    };
  }
  return result;
}

Map<String, dynamic> _data(Map<String, dynamic> response) =>
    response['data'] is Map
    ? Map<String, dynamic>.from(response['data'] as Map)
    : response;

Map<String, dynamic> _itemData(Map<String, dynamic> response) {
  final data = _data(response);
  final item = data['item'];
  return item is Map ? Map<String, dynamic>.from(item) : data;
}

String _camel(String value) {
  final parts = value.split('_');
  return parts.first +
      parts
          .skip(1)
          .map(
            (part) =>
                part.isEmpty ? '' : part[0].toUpperCase() + part.substring(1),
          )
          .join();
}

bool _present(String? value) => value?.trim().isNotEmpty == true;
