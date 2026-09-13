import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_app/features/ai_assistant/data/models/rag_answer.dart';
import 'package:user_app/features/ai_assistant/data/repositories/rag_repository.dart';
import 'package:user_app/core/network/api_client.dart';

final class RagApi extends BackendApiService {
  final List<Map<String, dynamic>> requests = [];
  Object? error;

  @override
  Future<Map<String, dynamic>> requestJson(
    String path, {
    required String method,
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool includeAuth = true,
  }) async {
    final failure = error;
    if (failure != null) throw failure;
    requests.add({
      'path': path,
      'method': method,
      'body': body,
      'includeAuth': includeAuth,
    });
    return {
      'success': true,
      'data': {
        'answer': 'Use the malaria treatment guideline.',
        'session_id': 'session-1',
        'search_scope': 'current_published_reviewed_content',
        'coverage_notice':
            'Only approved content in current published guideline versions was searched.',
        'citations': [
          {
            'chunk_id': 'chunk-1',
            'guideline_id': 'guideline-1',
            'guideline_version_id': 'version-1',
            'section_id': 'section-2',
            'content_type': 'guideline',
            'route': '/guidelines/guideline-1',
            'title': 'Uganda Clinical Guidelines',
            'source_name': 'Ministry of Health',
            'source_version': '2023',
            'page_start': 120,
            'page_end': 122,
            'diseases': [
              {'id': 'malaria-id', 'name': 'Malaria', 'slug': 'malaria'},
            ],
            'metadata': {'review_state': 'approved'},
          },
        ],
      },
    };
  }

  @override
  Future<Map<String, dynamic>> requestJsonWithTimeout(
    String path, {
    required String method,
    required Duration receiveTimeout,
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool includeAuth = true,
  }) async {
    final response = await requestJson(
      path,
      method: method,
      body: body,
      query: query,
      includeAuth: includeAuth,
    );
    requests.last['receiveTimeout'] = receiveTimeout;
    return response;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'language': 'sw'});
    preferences = await SharedPreferences.getInstance();
  });

  test('uses the typed RAG endpoint and maps grounded citations', () async {
    final api = RagApi();
    final repository = RagRepository(api, preferences);

    final answer = await repository.ask(
      question: 'How is malaria treated?',
      country: 'Uganda',
      programArea: 'malaria',
      authenticated: true,
    );

    expect(api.requests.single['path'], '/api/v2/chat/ask');
    expect(api.requests.single['method'], 'POST');
    expect(api.requests.single['includeAuth'], isTrue);
    expect(api.requests.single['receiveTimeout'], const Duration(seconds: 130));
    expect(api.requests.single['body'], {
      'question': 'How is malaria treated?',
      'language': 'sw',
      'country': 'UG',
      'program_area': 'malaria',
    });
    expect(answer.answer, contains('malaria'));
    expect(answer.citations.single.chunkId, 'chunk-1');
    expect(answer.citations.single.guidelineId, 'guideline-1');
    expect(answer.citations.single.guidelineVersionId, 'version-1');
    expect(answer.citations.single.contentType, 'guideline');
    expect(answer.citations.single.route, '/guidelines/guideline-1');
    expect(answer.citations.single.diseases.single['slug'], 'malaria');
    expect(answer.citations.single.metadata['review_state'], 'approved');
    expect(answer.citations.single.sectionId, 'section-2');
    expect(answer.answerWithSources, contains('pages 120–122'));
    expect(answer.searchScope, 'current_published_reviewed_content');
    expect(answer.answerWithSources, contains('Only approved content'));
    expect(
      RagAnswer.fromJson(answer.toJson()),
      answer,
      reason: 'Freezed RAG values must survive generated JSON round trips',
    );
    expect(answer.copyWith(answer: 'Updated').sessionId, 'session-1');
  });

  test('uses the public general assistant without auth for guests', () async {
    final api = RagApi();
    final repository = RagRepository(api, preferences);

    await repository.ask(question: 'What is diabetes?');

    expect(api.requests.single['path'], '/api/public/assistant/ask');
    expect(api.requests.single['includeAuth'], isFalse);
  });

  test('reuses the server-issued session for conversational context', () async {
    final api = RagApi();
    final repository = RagRepository(api, preferences);

    await repository.ask(question: 'Tell me about malaria');
    await repository.ask(question: 'What about severe disease?');

    expect(api.requests.last['body'], containsPair('session_id', 'session-1'));
    repository.resetSession();
    expect(repository.sessionId, isNull);
  });

  test('preserves backend rate-limit errors for the UI', () async {
    final api = RagApi()
      ..error = BackendApiException(
        'Too many requests.',
        statusCode: 429,
        retryAfter: const Duration(seconds: 30),
      );
    final repository = RagRepository(api, preferences);

    await expectLater(
      repository.ask(question: 'A question'),
      throwsA(
        isA<BackendApiException>()
            .having((error) => error.isRateLimited, 'isRateLimited', isTrue)
            .having(
              (error) => error.retryAfter,
              'retryAfter',
              const Duration(seconds: 30),
            ),
      ),
    );
  });
}
