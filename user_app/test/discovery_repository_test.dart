import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/core/network/api_client.dart';
import 'package:user_app/features/discovery/data/repositories/discovery_repository.dart';

import 'helpers/test_local_store.dart';

final class _DiscoveryApi extends BackendApiService {
  bool offline = false;
  String? path;
  Map<String, String>? query;

  @override
  Future<Map<String, dynamic>> requestJson(
    String path, {
    required String method,
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool includeAuth = true,
  }) async {
    this.path = path;
    this.query = query;
    expect(method, 'GET');
    expect(includeAuth, isFalse);
    if (offline) throw StateError('offline');
    return {
      'data': {
        'items': [
          {
            'id': 'hub-1',
            'name': 'Malaria clinical care',
            'slug': 'malaria-clinical-care',
            'description': 'Approved malaria resources',
            'diseases': [
              {'id': 'disease-1', 'name': 'Malaria', 'slug': 'malaria'},
            ],
          },
          {
            'id': 'hub-2',
            'name': 'Essential clinical resources',
            'slug': 'essential-clinical-resources',
            'description': 'Cross-cutting resources',
            'diseases': <Map<String, dynamic>>[],
          },
        ],
      },
    };
  }
}

void main() {
  test('loads and caches the public content hub directory', () async {
    final api = _DiscoveryApi();
    final store = TestLocalStore();
    addTearDown(store.close);
    final repository = DiscoveryRepository(api, store.cache);

    final online = await repository.hubs();

    expect(api.path, '/api/public/hubs');
    expect(api.query, {'page': '1', 'per_page': '100'});
    expect(online.offline, isFalse);
    expect(online.value.map((hub) => hub.slug), [
      'malaria-clinical-care',
      'essential-clinical-resources',
    ]);
    expect(online.value.first.diseases.single.name, 'Malaria');

    api.offline = true;
    final cached = await repository.hubs(search: 'malaria');

    expect(cached.offline, isTrue);
    expect(cached.value.single.slug, 'malaria-clinical-care');
  });
}
