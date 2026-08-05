import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/features/support/data/repositories/help_content_repository.dart';
import 'package:user_app/core/network/api_client.dart';

class FakeHelpContentApi extends BackendApiService {
  String? path;
  String? method;
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
    this.method = method;
    this.query = query;
    final item = path == '/api/v2/faqs'
        ? {
            'id': 'faq-1',
            'question': 'How do I reset my password?',
            'answer': 'Use the reset form.',
            'status': 'published',
            'priority': 'normal',
            'created_at': '2026-01-01T00:00:00Z',
            'updated_at': '2026-01-02T00:00:00Z',
          }
        : {
            'id': 'doc-1',
            'title': 'Account help',
            'content': 'Help content',
            'status': 'published',
            'created_at': '2026-01-01T00:00:00Z',
            'updated_at': '2026-01-02T00:00:00Z',
          };
    return {
      'data': {
        'items': [item],
        'page': 1,
        'per_page': 20,
        'total_items': 1,
        'total_pages': 1,
      },
    };
  }
}

void main() {
  test('HelpContentRepository uses typed FAQ query parameters', () async {
    final api = FakeHelpContentApi();
    final result = await HelpContentRepository(
      api,
    ).listFAQs(search: 'password reset', featured: true);

    expect(api.path, '/api/v2/faqs');
    expect(api.method, 'GET');
    expect(api.query?['search'], 'password reset');
    expect(api.query?['is_featured'], 'true');
    expect(api.query?.containsKey('filter'), isFalse);
    expect(result.items.single.question, 'How do I reset my password?');
  });

  test('HelpContentRepository uses the typed documentation endpoint', () async {
    final api = FakeHelpContentApi();
    final result = await HelpContentRepository(
      api,
    ).listDocumentation(search: 'account', category: 'getting-started');

    expect(api.path, '/api/v2/documentation');
    expect(api.query?['search'], 'account');
    expect(api.query?['category'], 'getting-started');
    expect(result.items.single.id, 'doc-1');
  });
}
