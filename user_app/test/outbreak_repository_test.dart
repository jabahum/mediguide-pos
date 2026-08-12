import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/core/network/api_client.dart';
import 'package:user_app/features/outbreaks/data/repositories/outbreak_repository.dart';
import 'helpers/test_local_store.dart';

class FakeOutbreakApi extends BackendApiService {
  bool offline = false;
  final calls = <String>[];

  @override
  Future<Map<String, dynamic>> requestJson(
    String path, {
    required String method,
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool includeAuth = true,
  }) async {
    calls.add(path);
    expect(includeAuth, isFalse);
    if (offline) throw const BackendApiException('offline', statusCode: 503);
    if (path.endsWith('/updates')) {
      return {
        'data': {
          'items': [
            {
              'id': 'update-1',
              'outbreak_id': 'outbreak-1',
              'title': 'Published update',
              'published_at': '2026-08-01T00:00:00Z',
            },
          ],
        },
      };
    }
    if (path.endsWith('/resources')) {
      return {
        'data': {
          'items': [
            {
              'id': 'resource-1',
              'outbreak_id': 'outbreak-1',
              'title': 'Clinical guidance',
              'url': 'https://example.test/guidance',
            },
          ],
        },
      };
    }
    if (path == '/api/public/situation-reports') {
      return {
        'data': {
          'items': [
            {
              'id': 'report-1',
              'outbreak_id': 'outbreak-1',
              'title': 'Situation report',
              'publication_date': '2026-08-02T00:00:00Z',
              'status': 'published',
            },
          ],
        },
      };
    }
    final outbreak = {
      'id': 'outbreak-1',
      'title': 'Published response',
      'status': 'active',
      'last_update': '2026-08-03T00:00:00Z',
      'visual_tone': 'critical',
      'metrics': [
        {'key': 'confirmed', 'label': 'Confirmed', 'value': '4'},
      ],
    };
    if (path == '/api/public/outbreaks') {
      return {
        'data': {
          'items': [outbreak],
        },
      };
    }
    if (path == '/api/public/outbreaks/outbreak-1') {
      return {'data': outbreak};
    }
    if (path == '/api/public/situation-reports/report-1') {
      return {
        'data': {
          'id': 'report-1',
          'title': 'Situation report',
          'publication_date': '2026-08-02T00:00:00Z',
          'status': 'published',
        },
      };
    }
    throw StateError(path);
  }
}

void main() {
  test(
    'outbreak repository uses public typed routes and public cache',
    () async {
      final store = TestLocalStore();
      addTearDown(store.close);
      final api = FakeOutbreakApi();
      final repository = OutbreakRepository(api, store.cache);

      final online = await repository.outbreaks(status: 'active');
      expect(online.single.title, 'Published response');
      expect(online.single.metrics.single.label, 'Confirmed');
      expect(api.calls.single, '/api/public/outbreaks');

      api.offline = true;
      final offline = await repository.outbreaks(status: 'active');
      expect(offline.single.id, 'outbreak-1');
    },
  );

  test('outbreak detail combines deterministic typed child routes', () async {
    final store = TestLocalStore();
    addTearDown(store.close);
    final api = FakeOutbreakApi();
    final detail = await OutbreakRepository(
      api,
      store.cache,
    ).outbreak('outbreak-1');

    expect(detail.updates.single.title, 'Published update');
    expect(detail.resources.single.title, 'Clinical guidance');
    expect(detail.reports.single.title, 'Situation report');
    expect(api.calls, contains('/api/public/outbreaks/outbreak-1/updates'));
    expect(api.calls, contains('/api/public/outbreaks/outbreak-1/resources'));
  });
}
