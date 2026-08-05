import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    requests.add({'path': path, 'method': method, 'body': body});
    return {
      'success': true,
      'data': {
        'answer': 'Use the malaria treatment guideline.',
        'session_id': 'session-1',
        'citations': [
          {
            'chunk_id': 'chunk-1',
            'title': 'Uganda Clinical Guidelines',
            'source_name': 'Ministry of Health',
            'source_version': '2023',
            'page_start': 120,
            'page_end': 122,
          },
        ],
      },
    };
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
    );

    expect(api.requests.single['path'], '/api/v2/chat/ask');
    expect(api.requests.single['method'], 'POST');
    expect(api.requests.single['body'], {
      'question': 'How is malaria treated?',
      'language': 'sw',
      'country': 'UG',
      'program_area': 'malaria',
    });
    expect(answer.answer, contains('malaria'));
    expect(answer.citations.single.chunkId, 'chunk-1');
    expect(answer.answerWithSources, contains('pages 120–122'));
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
