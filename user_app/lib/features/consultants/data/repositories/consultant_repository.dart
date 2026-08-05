import 'package:user_app/shared/models/models.dart';
import 'package:user_app/core/network/api_client.dart';

final class ConsultantRepository {
  ConsultantRepository(this._api);

  final BackendApiService _api;

  Future<PaginatedResponse<Consultant>> list({
    int page = 1,
    int perPage = 20,
    String? search,
    String? status,
    String? specialty,
    String? qualification,
    String? language,
    String? region,
    String? city,
    String? consultationType,
    bool? verified,
    String sort = 'rating',
    String order = 'desc',
  }) async {
    final response = await _api.requestJson(
      '/api/v2/consultants',
      method: 'GET',
      query: {
        'page': '$page',
        'per_page': '$perPage',
        if (_present(search)) 'search': search!.trim(),
        if (_present(status)) 'status': status!,
        if (_present(specialty)) 'specialty': specialty!,
        if (_present(qualification)) 'qualification': qualification!,
        if (_present(language)) 'language': language!,
        if (_present(region)) 'region': region!,
        if (_present(city)) 'city': city!,
        if (_present(consultationType)) 'consultation_type': consultationType!,
        if (verified != null) 'verified': '$verified',
        'sort': sort,
        'order': order,
      },
    );
    final data = _data(response);
    final items = (data['items'] as List? ?? const [])
        .whereType<Map>()
        .map((value) => Consultant.fromJson(Map<String, dynamic>.from(value)))
        .toList();
    return PaginatedResponse(
      items: items,
      page: (data['page'] as num?)?.toInt() ?? page,
      perPage: (data['per_page'] as num?)?.toInt() ?? perPage,
      totalItems: (data['total_items'] as num?)?.toInt() ?? items.length,
      totalPages: (data['total_pages'] as num?)?.toInt() ?? 0,
    );
  }

  Future<Consultant> get(String id) async {
    final response = await _api.requestJson(
      '/api/v2/consultants/$id',
      method: 'GET',
    );
    final data = _data(response);
    final item = data['item'];
    return Consultant.fromJson(
      item is Map ? Map<String, dynamic>.from(item) : data,
    );
  }

  Future<Consultant> create(ConsultantRequest request) async => _item(
    await _api.requestJson(
      '/api/v2/consultants',
      method: 'POST',
      body: request.toJson(),
    ),
  );

  Future<Consultant> update(String id, ConsultantRequest request) async =>
      _item(
        await _api.requestJson(
          '/api/v2/consultants/$id',
          method: 'PATCH',
          body: request.toJson(),
        ),
      );

  Future<void> recordUsage(String id) async {
    await _api.requestJson('/api/v2/consultants/$id/usage', method: 'POST');
  }

  Consultant _item(Map<String, dynamic> response) {
    final data = _data(response);
    final item = data['item'];
    return Consultant.fromJson(
      item is Map ? Map<String, dynamic>.from(item) : data,
    );
  }

  Map<String, dynamic> _data(Map<String, dynamic> response) {
    final data = response['data'];
    return data is Map ? Map<String, dynamic>.from(data) : response;
  }

  static bool _present(String? value) => value?.trim().isNotEmpty == true;
}
