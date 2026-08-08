import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/features/guidelines/data/repositories/progress_usage_repository.dart';
import 'package:user_app/core/network/api_client.dart';
import 'helpers/test_local_store.dart';

class FakeProgressApi extends BackendApiService {
  FakeProgressApi({this.offline = false});
  final bool offline;
  String? path;
  Map<String, dynamic>? body;

  @override
  Future<Map<String, dynamic>> requestJson(
    String path, {
    required String method,
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool includeAuth = true,
  }) async {
    this.path = path;
    this.body = body;
    if (offline) throw Exception('offline');
    return {
      'data': {
        'id': 'progress-1',
        'guideline_document_id': 'guideline-1',
        'progress_percentage': body?['progress_percentage'] ?? 0.5,
        'is_bookmarked': body?['is_bookmarked'] ?? false,
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      },
    };
  }
}

void main() {
  test('reading progress is retained locally when offline', () async {
    final store = TestLocalStore();
    addTearDown(store.close);
    final repository = ReadingProgressRepository(
      FakeProgressApi(offline: true),
      store.cache,
    );
    final record = await repository.upsert('user-1', 'guideline-1', {
      'progress_percentage': 0.4,
      'current_section': 'definition',
    });
    expect(record.progressPercentage, 0.4);
    expect(record.pendingSync, isTrue);
    final cached = await repository.forGuideline('user-1', 'guideline-1');
    expect(cached, isNotNull);
  });

  test('usage writes send no client owner id', () async {
    final api = FakeProgressApi();
    await UsageRepository(api).abbreviation('abbreviation-1');
    expect(api.path, '/api/v2/usage/abbreviations');
    expect(api.body?['resource_id'], 'abbreviation-1');
    expect(api.body?.containsKey('user_id'), isFalse);
    expect(api.body?['idempotency_key'], isNotEmpty);
  });
}
