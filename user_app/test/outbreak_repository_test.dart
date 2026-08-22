import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/core/network/api_client.dart';
import 'package:user_app/features/outbreaks/data/models/outbreak_models.dart';
import 'package:user_app/features/outbreaks/data/repositories/outbreak_repository.dart';
import 'helpers/test_local_store.dart';

class FakeOutbreakApi extends BackendApiService {
  bool offline = false;
  bool malformed = false;
  bool missingDetail = false;
  final failedPaths = <String>{};
  final calls = <String>[];
  final queries = <Map<String, String>?>[];

  @override
  Future<Map<String, dynamic>> requestJson(
    String path, {
    required String method,
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool includeAuth = true,
  }) async {
    calls.add(path);
    queries.add(query);
    expect(includeAuth, isFalse);
    if (offline) {
      throw const BackendApiException('offline', statusCode: 503);
    }
    if (failedPaths.contains(path)) {
      throw const BackendApiException('temporary', statusCode: 503);
    }
    if (missingDetail && path == '/api/public/outbreaks/outbreak-1') {
      throw const BackendApiException('missing', statusCode: 404);
    }
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
        {'key': 'confirmed', 'label': 'Confirmed', 'value': 4},
      ],
    };
    if (path == '/api/public/outbreaks') {
      if (malformed) {
        return {
          'data': {'items': 'invalid'},
        };
      }
      return {
        'data': {
          'items': [outbreak],
          'page': 1,
          'per_page': 20,
          'total_items': 1,
          'total_pages': 1,
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

      final online = await repository.outbreaks(
        query: const OutbreakQuery(status: 'active'),
      );
      expect(online.items.single.title, 'Published response');
      expect(online.items.single.metrics.single.label, 'Confirmed');
      expect(online.items.single.metrics.single.value, '4');
      expect(api.calls.single, '/api/public/outbreaks');
      expect(api.queries.single?['per_page'], '20');
      expect(api.queries.single?['status'], 'active');

      api.offline = true;
      final offline = await repository.outbreaks(
        query: const OutbreakQuery(status: 'active'),
      );
      expect(offline.items.single.id, 'outbreak-1');
      expect(offline.cache.isOffline, isTrue);
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

    expect(detail.value.updates.single.title, 'Published update');
    expect(detail.value.resources.single.title, 'Clinical guidance');
    expect(detail.value.reports.single.title, 'Situation report');
    expect(api.calls, contains('/api/public/outbreaks/outbreak-1/updates'));
    expect(api.calls, contains('/api/public/outbreaks/outbreak-1/resources'));
  });

  test('malformed server payload is not hidden by a cached response', () async {
    final store = TestLocalStore();
    addTearDown(store.close);
    final api = FakeOutbreakApi();
    final repository = OutbreakRepository(api, store.cache);
    await repository.outbreaks();
    api.malformed = true;
    await expectLater(repository.outbreaks(), throwsA(isA<TypeError>()));
  });

  test(
    'cached active critical content reports stale offline metadata',
    () async {
      final store = TestLocalStore();
      addTearDown(store.close);
      var now = DateTime.now().toUtc();
      final api = FakeOutbreakApi();
      final repository = OutbreakRepository(api, store.cache, clock: () => now);
      await repository.outbreaks();
      now = now.add(const Duration(hours: 1));
      api.offline = true;
      final cached = await repository.outbreaks();
      expect(cached.cache.isOffline, isTrue);
      expect(cached.cache.isStale, isTrue);
    },
  );

  test('offline fallback applies typed filters to canonical cache', () async {
    final store = TestLocalStore();
    addTearDown(store.close);
    final api = FakeOutbreakApi();
    final repository = OutbreakRepository(api, store.cache);
    await repository.outbreaks();
    api.offline = true;
    final matching = await repository.outbreaks(
      query: const OutbreakQuery(search: 'Published response'),
    );
    final missing = await repository.outbreaks(
      query: const OutbreakQuery(search: 'not in cache'),
    );
    expect(matching.items.single.id, 'outbreak-1');
    expect(missing.items, isEmpty);
  });

  test('detail child failures retain independently cached sections', () async {
    final store = TestLocalStore();
    addTearDown(store.close);
    final api = FakeOutbreakApi();
    final repository = OutbreakRepository(api, store.cache);
    await repository.outbreak('outbreak-1');
    api.failedPaths.add('/api/public/outbreaks/outbreak-1/resources');
    final partial = await repository.outbreak('outbreak-1');
    expect(partial.partialFailures, contains('resources'));
    expect(partial.value.resources.single.title, 'Clinical guidance');
  });

  test(
    'withdrawn details are tombstoned and never served as active cache',
    () async {
      final store = TestLocalStore();
      addTearDown(store.close);
      final api = FakeOutbreakApi();
      final repository = OutbreakRepository(api, store.cache);
      await repository.outbreak('outbreak-1');
      api.missingDetail = true;
      await expectLater(
        repository.outbreak('outbreak-1'),
        throwsA(
          isA<PublicContentUnavailableException>().having(
            (error) => error.isWithdrawn,
            'isWithdrawn',
            isTrue,
          ),
        ),
      );
    },
  );
}
