import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/features/content/data/repositories/content_reference_repository.dart';
import 'package:user_app/core/network/api_client.dart';
import 'package:user_app/features/content/data/repositories/generic_page_local_repository.dart';
import 'helpers/test_local_store.dart';

class FakeContentReferenceApi extends BackendApiService {
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
    if (path == '/api/v2/languages') {
      return {
        'data': {
          'items': [
            {
              'id': 'language-1',
              'code': 'lg',
              'name': 'Luganda',
              'native_name': 'Luganda',
              'is_active': true,
              'is_default': false,
              'enabled_for_users': true,
              'translations_json': {'hello': 'Gyebale'},
              'created_at': '2026-01-01T00:00:00Z',
              'updated_at': '2026-01-01T00:00:00Z',
            },
          ],
        },
      };
    }
    return {
      'data': {
        'items': [
          {
            'id': 'page-1',
            'key': 'about',
            'title': 'About',
            'content': {'intro': 'Welcome'},
            'created_at': '2026-01-01T00:00:00Z',
            'updated_at': '2026-01-01T00:00:00Z',
          },
        ],
        'page': 1,
        'per_page': 50,
        'total_items': 1,
        'total_pages': 1,
      },
    };
  }
}

void main() {
  test('GenericPageRepository uses typed search parameters', () async {
    final api = FakeContentReferenceApi();
    final store = TestLocalStore();
    addTearDown(store.close);
    final result = await GenericPageRepository(
      api,
      GenericPageLocalRepository(store.cache),
    ).list(search: 'about');
    expect(api.path, '/api/v2/pages');
    expect(api.query?['search'], 'about');
    expect(api.query?.containsKey('filter'), isFalse);
    expect(result.items.single.key, 'about');
  });

  test('LanguageRepository requests explicitly available languages', () async {
    final api = FakeContentReferenceApi();
    final languages = await LanguageRepository(api).available();
    expect(api.query?['is_active'], 'true');
    expect(api.query?['enabled_for_users'], 'true');
    expect(languages.single.translations['hello'], 'Gyebale');
  });
}
