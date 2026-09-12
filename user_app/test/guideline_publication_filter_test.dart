import 'package:flutter_test/flutter_test.dart';

import 'package:user_app/core/network/api_client.dart';
import 'package:user_app/features/guidelines/data/repositories/guideline_publication_repository.dart';

import 'helpers/test_local_store.dart';

final class _PublicationApi extends BackendApiService {
  Map<String, String>? query;

  @override
  Future<Map<String, dynamic>> requestJson(
    String path, {
    required String method,
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool includeAuth = true,
  }) async {
    this.query = query;
    return {
      'data': {
        'items': [
          {
            'id': 'malaria-1',
            'title': 'Malaria treatment guideline',
            'program_area': 'Malaria',
            'version': '1',
            'categories': [
              {'id': 'category-malaria', 'name': 'Communicable diseases'},
            ],
          },
        ],
        'page': 1,
        'per_page': 100,
        'total_items': 1,
        'total_pages': 1,
      },
    };
  }
}

void main() {
  test('publications sends the selected programme-area filter', () async {
    final store = TestLocalStore();
    addTearDown(store.close);
    final api = _PublicationApi();
    final repository = GuidelinePublicationRepository(api, store.cache);

    final page = await repository.publications(
      programArea: 'Malaria',
      perPage: 100,
    );

    expect(api.query?['program_area'], 'Malaria');
    expect(page.items, hasLength(1));
    expect(page.items.single.programArea, 'Malaria');
  });

  test('publications sends and parses the canonical category filter', () async {
    final store = TestLocalStore();
    addTearDown(store.close);
    final api = _PublicationApi();
    final repository = GuidelinePublicationRepository(api, store.cache);

    final page = await repository.publications(
      categoryId: 'category-malaria',
      perPage: 100,
    );

    expect(api.query?['category_id'], 'category-malaria');
    expect(page.items.single.categories.single.name, 'Communicable diseases');
  });
}
