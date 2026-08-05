import 'package:user_app/shared/models/models.dart';
import 'package:user_app/core/network/api_client.dart';

final class ConsultantRepository {
  ConsultantRepository(this._api);

  final BackendApiService _api;

  Future<PagedResult<ApiRecord>> list({
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
        .map((value) => ApiRecord(_normalize(Map<String, dynamic>.from(value))))
        .toList();
    return PagedResult(
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
    return Consultant.fromRecord(ApiRecord(_normalize(_data(response))));
  }

  Future<void> recordUsage(String id) async {
    await _api.requestJson('/api/v2/consultants/$id/usage', method: 'POST');
  }

  Map<String, dynamic> _normalize(Map<String, dynamic> raw) {
    final user = raw['user'];
    return {
      ...raw,
      'collectionName': Consultant.collection,
      'collectionId': Consultant.collection,
      'created': raw['created_at']?.toString() ?? '',
      'updated': raw['updated_at']?.toString() ?? '',
      'user': raw['user_id']?.toString() ?? '',
      'alternativePhone': raw['alternative_phone'] ?? '',
      'profilePicture': _assetValue(raw['profile_picture']),
      'avatar': _assetValue(raw['avatar']),
      'licenseNumber': raw['license_number'] ?? '',
      'yearsOfExperience': raw['years_of_experience'] ?? 0,
      'postalCode': raw['postal_code'] ?? '',
      'preferredLanguage': raw['preferred_language'] ?? '',
      'consultationTypes': raw['consultation_types'] ?? const <String>[],
      'isVerified': raw['is_verified'] ?? false,
      'totalConsultations': raw['total_consultations'] ?? 0,
      'availability': raw['availability'] ?? const <String, dynamic>{},
      'expand': {if (user is Map) 'user': Map<String, dynamic>.from(user)},
    };
  }

  dynamic _assetValue(dynamic value) {
    if (value is String) return value;
    if (value is Map) {
      return value['url'] ?? value['path'] ?? value['name'] ?? '';
    }
    return '';
  }

  Map<String, dynamic> _data(Map<String, dynamic> response) {
    final data = response['data'];
    return data is Map ? Map<String, dynamic>.from(data) : response;
  }

  static bool _present(String? value) => value?.trim().isNotEmpty == true;
}
