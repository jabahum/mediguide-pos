import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/features/guidelines/data/repositories/guideline_content_repository.dart';
import 'package:user_app/core/network/api_client.dart';
import 'package:user_app/features/abbreviations/data/repositories/abbreviation_local_repository.dart';
import 'package:user_app/features/guidelines/data/repositories/guildline_content_local_repository.dart';
import 'helpers/test_local_store.dart';

class FakeGuidelineContentApi extends BackendApiService {
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
    return {
      'data': {
        'items': [
          {
            'id': 'item-1',
            'condition_name': 'Hypertension',
            'status': 'published',
            'is_published': true,
            'created_at': '2026-01-01T00:00:00Z',
            'updated_at': '2026-01-02T00:00:00Z',
          },
        ],
        'page': 1,
        'per_page': 20,
        'total_items': 1,
        'total_pages': 1,
      },
    };
  }
}

void main() {
  test(
    'GuidelineContentRepository sends typed publication and taxonomy filters',
    () async {
      final api = FakeGuidelineContentApi();
      final store = TestLocalStore();
      addTearDown(store.close);
      final repository = GuidelineContentRepository(
        api,
        GuidelineContentLocalRepository(store.cache),
        AbbreviationLocalRepository(store.cache),
      );
      final result = await repository.guidelines(
        search: 'blood pressure',
        categoryId: 'category-1',
        tagId: 'tag-1',
        published: true,
        status: 'published',
      );
      expect(api.path, '/api/v2/medical-guidelines');
      expect(api.query?['search'], 'blood pressure');
      expect(api.query?['category_id'], 'category-1');
      expect(api.query?['tag_id'], 'tag-1');
      expect(api.query?['is_published'], 'true');
      expect(api.query?.containsKey('filter'), isFalse);
      expect(result.items.single.conditionName, 'Hypertension');
    },
  );

  test('GuidelineContentRepository uses an explicit hierarchy query', () async {
    final api = FakeGuidelineContentApi();
    final store = TestLocalStore();
    addTearDown(store.close);
    final repository = GuidelineContentRepository(
      api,
      GuidelineContentLocalRepository(store.cache),
      AbbreviationLocalRepository(store.cache),
    );
    await repository.categories(parentId: 'parent-1');
    expect(api.path, '/api/v2/guideline-categories');
    expect(api.query?['parent_id'], 'parent-1');
    expect(api.query?.containsKey('filter'), isFalse);
  });
}
