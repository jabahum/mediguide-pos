import '../services/backend_api_service.dart';

final class DrugReferenceRepository {
  DrugReferenceRepository(this._api);
  final BackendApiService _api;

  Future<List<String>> categoryNames() => _names('/api/v2/drug-categories');
  Future<List<String>> tagNames() => _names('/api/v2/drug-tags');

  Future<List<String>> _names(String path) async {
    final response = await _api.requestJson(
      path,
      method: 'GET',
      query: const {
        'page': '1',
        'per_page': '100',
        'sort': 'name',
        'order': 'asc',
      },
    );
    final value = response['data'] is Map ? response['data'] : response;
    final items = value is Map ? value['items'] : null;
    return (items as List? ?? const [])
        .whereType<Map>()
        .map((item) => item['name']?.toString() ?? '')
        .where((name) => name.isNotEmpty)
        .toList();
  }
}
