import 'package:user_app/shared/models/models.dart';
import 'package:user_app/core/network/api_client.dart';
import 'package:user_app/features/consultants/data/repositories/consultant_local_repository.dart';

final class ConsultantRepository {
  ConsultantRepository(this._api, this._local);

  final BackendApiService _api;
  final ConsultantLocalRepository _local;

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
    try {
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
          if (_present(consultationType))
            'consultation_type': consultationType!,
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
      await _bestEffort(() => _local.saveConsultants(items));
      return PaginatedResponse(
        items: items,
        page: (data['page'] as num?)?.toInt() ?? page,
        perPage: (data['per_page'] as num?)?.toInt() ?? perPage,
        totalItems: (data['total_items'] as num?)?.toInt() ?? items.length,
        totalPages: (data['total_pages'] as num?)?.toInt() ?? 0,
      );
    } catch (_) {
      final cached = await _local.listConsultants(
        page: page,
        perPage: perPage,
        search: search ?? '',
        status: status ?? '',
        specialty: specialty ?? '',
        qualification: qualification ?? '',
        language: language ?? '',
        region: region ?? '',
        city: city ?? '',
        consultationType: consultationType ?? '',
        verified: verified,
        sort: sort,
        order: order,
      );
      if (cached.items.isEmpty) rethrow;
      return PaginatedResponse(
        items: cached.items,
        page: cached.page,
        perPage: cached.perPage,
        totalItems: cached.totalItems,
        totalPages: cached.totalPages,
      );
    }
  }

  Future<Consultant> get(String id) async {
    try {
      final response = await _api.requestJson(
        '/api/v2/consultants/$id',
        method: 'GET',
      );
      final data = _data(response);
      final item = data['item'];
      final consultant = Consultant.fromJson(
        item is Map ? Map<String, dynamic>.from(item) : data,
      );
      await _bestEffort(() => _local.saveConsultant(consultant));
      return consultant;
    } catch (_) {
      final cached = await _local.getConsultant(id);
      if (cached == null) rethrow;
      return cached;
    }
  }

  Future<Consultant> create(ConsultantRequest request) async {
    final consultant = _item(
      await _api.requestJson(
        '/api/v2/consultants',
        method: 'POST',
        body: request.toJson(),
      ),
    );
    await _bestEffort(() => _local.saveConsultant(consultant));
    return consultant;
  }

  Future<Consultant> update(String id, ConsultantRequest request) async {
    final consultant = _item(
      await _api.requestJson(
        '/api/v2/consultants/$id',
        method: 'PATCH',
        body: request.toJson(),
      ),
    );
    await _bestEffort(() => _local.saveConsultant(consultant));
    return consultant;
  }

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

  Future<void> _bestEffort(Future<void> Function() write) async {
    try {
      await write();
    } catch (_) {
      // Cache persistence is best effort after a successful remote read.
    }
  }
}
