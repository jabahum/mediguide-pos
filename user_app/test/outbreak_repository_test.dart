import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/core/network/api_client.dart';
import 'package:user_app/core/storage/local_cache_service.dart';
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
    if (path == '/api/public/outbreak-resources') {
      return {
        'data': {
          'items': [
            {
              'id': 'resource-1',
              'outbreak_id': 'outbreak-1',
              'outbreak_title': 'Ebola response',
              'title': 'Official response statement',
              'description': 'Verified Ministry of Health announcement',
              'issuing_organization': 'Ministry of Health',
              'resource_type': 'official_statement',
              'target_type': 'external_url',
              'target_url': 'https://health.go.ug/response',
              'reader_capability': 'external_browser',
              'download_capability': false,
            },
          ],
          'page': 1,
          'per_page': 10,
          'total_items': 1,
          'total_pages': 1,
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
    if (path.endsWith('/documents/document-1')) {
      return {
        'data': {
          'id': 'document-1',
          'outbreak_id': 'outbreak-1',
          'title': 'Ebola response SOP',
          'description': 'Isolation and notification procedure',
          'document_kind': 'sop',
          'issuing_authority': 'Ministry of Health',
          'document_number': 'SOP-001',
          'version': '2.0',
          'language': 'en',
          'mime_type': 'application/pdf',
          'published_at': '2026-08-01T00:00:00Z',
        },
      };
    }
    if (path == '/api/public/outbreak-documents/document-1/content') {
      return {
        'data': {
          'document_id': 'document-1',
          'outbreak_id': 'outbreak-1',
          'title': 'Ebola response SOP',
          'content':
              '# Isolation\n\nNotify the surveillance team. Use the contact tracing cadence.',
          'format': 'markdown',
          'mime_type': 'text/markdown',
          'sections': [
            {
              'id': 'isolation',
              'heading': 'Isolation',
              'level': 1,
              'text': 'Notify the surveillance team.',
            },
          ],
          'checksum_sha256':
              'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
          'download_url':
              '/api/public/outbreaks/outbreak-1/documents/document-1/download',
          'original_available': true,
          'can_read_inline': true,
        },
      };
    }
    if (path == '/api/public/outbreak-documents') {
      return {
        'data': {
          'items': [
            {
              'id': 'document-1',
              'outbreak_id': 'outbreak-1',
              'outbreak_title': 'Ebola response',
              'outbreak_disease': 'EVD',
              'outbreak_area': 'Kampala',
              'title': 'Ebola response SOP',
              'description': 'Isolation and notification procedure',
              'search_snippet': 'Notify the surveillance team.',
              'matching_heading': 'Isolation',
              'matching_section_id': 'isolation',
              'search_relevance_score': 2.75,
              'reader_url': '/api/public/outbreak-documents/document-1/content',
              'document_kind': 'sop',
              'issuing_authority': 'Ministry of Health',
              'version': '2.0',
              'language': 'en',
              'mime_type': 'text/markdown',
              'effective_date': '2026-08-01T00:00:00Z',
              'content_url':
                  '/api/public/outbreak-documents/document-1/content',
              'content_format': 'markdown',
              'supports_inline': true,
              'supports_offline_download': true,
              'published_at': '2026-08-01T00:00:00Z',
            },
          ],
          'page': 1,
          'per_page': 10,
          'total_items': 1,
          'total_pages': 1,
        },
      };
    }
    if (path.endsWith('/documents')) {
      return {
        'data': {
          'items': [
            {
              'id': 'document-1',
              'outbreak_id': 'outbreak-1',
              'title': 'Ebola response SOP',
              'document_kind': 'sop',
              'issuing_authority': 'Ministry of Health',
              'version': '2.0',
              'language': 'en',
              'mime_type': 'application/pdf',
              'file_size': 4096,
              'checksum_sha256':
                  'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
              'download_url':
                  '/api/public/outbreaks/outbreak-1/documents/document-1/download',
              'published_at': '2026-08-01T00:00:00Z',
            },
          ],
          'page': 1,
          'per_page': 20,
          'total_items': 1,
          'total_pages': 1,
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
  test('default outbreak document query uses the server safe sort', () {
    final defaultQuery = const OutbreakDocumentQuery(search: 'ebola').toQuery();
    final explicitQuery = const OutbreakDocumentQuery(
      sort: 'sort_order',
    ).toQuery();

    expect(defaultQuery['search'], 'ebola');
    expect(defaultQuery, isNot(contains('sort')));
    expect(explicitQuery['sort'], 'sort_order');
  });

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
    expect(detail.value.documents.single.title, 'Ebola response SOP');
    expect(detail.value.documents.single.documentKind, 'sop');
    expect(detail.value.reports.single.title, 'Situation report');
    expect(api.calls, contains('/api/public/outbreaks/outbreak-1/updates'));
    expect(api.calls, contains('/api/public/outbreaks/outbreak-1/resources'));
    expect(api.calls, contains('/api/public/outbreaks/outbreak-1/documents'));
  });

  test('quick-resource discovery preserves safe target metadata', () async {
    final store = TestLocalStore();
    addTearDown(store.close);
    final api = FakeOutbreakApi();
    final result = await OutbreakRepository(
      api,
      store.cache,
    ).quickResources(search: 'verified');

    expect(api.calls.single, '/api/public/outbreak-resources');
    expect(api.queries.single?['search'], 'verified');
    expect(result.items.single.outbreakTitle, 'Ebola response');
    expect(result.items.single.targetType, 'external_url');
    expect(result.items.single.readerCapability, 'external_browser');
    expect(result.items.single.targetUrl, 'https://health.go.ug/response');
    expect(result.items.single.downloadCapability, isFalse);
  });

  test('document list and detail remain searchable offline', () async {
    final store = TestLocalStore();
    addTearDown(store.close);
    final api = FakeOutbreakApi();
    final repository = OutbreakRepository(api, store.cache);

    final online = await repository.refreshDocuments('outbreak-1');
    expect(online.items.single.documentKind, 'sop');
    final detail = await repository.document('outbreak-1', 'document-1');
    expect(detail.value.documentNumber, 'SOP-001');

    api.offline = true;
    final cached = await repository.documents(
      'outbreak-1',
      query: const OutbreakDocumentQuery(
        search: 'Ministry',
        documentKind: 'sop',
      ),
    );
    expect(cached.items.single.id, 'document-1');
    expect(cached.cache.isOffline, isTrue);
    final cachedDetail = await repository.document('outbreak-1', 'document-1');
    expect(cachedDetail.cache.isOffline, isTrue);
  });

  test('full document sync reconciles published offline versions', () async {
    final store = TestLocalStore();
    addTearDown(store.close);
    final versions = <Map<String, String>>[];
    final repository = OutbreakRepository(
      FakeOutbreakApi(),
      store.cache,
      reconcileDocumentDownloads: (value) async => versions.add(value),
    );
    await repository.refreshDocuments('outbreak-1');
    expect(versions.single, {'document-1': '2.0'});
  });

  test('global document discovery and readable content work offline', () async {
    final store = TestLocalStore();
    addTearDown(store.close);
    final api = FakeOutbreakApi();
    final repository = OutbreakRepository(api, store.cache);

    final online = await repository.searchDocuments(
      query: const OutbreakDocumentQuery(search: 'surveillance'),
    );
    expect(online.items.single.outbreakTitle, 'Ebola response');
    expect(online.items.single.supportsInline, isTrue);
    expect(online.items.single.matchingSectionId, 'isolation');
    expect(online.items.single.searchRelevanceScore, 2.75);
    expect(online.items.single.supportsOfflineDownload, isTrue);
    final content = await repository.documentContent('document-1');
    expect(content.value.content, contains('Notify'));
    expect(content.value.documentId, 'document-1');
    expect(content.value.sections.single.id, 'isolation');
    expect(content.value.originalAvailable, isTrue);
    expect(content.value.canReadInline, isTrue);

    api.offline = true;
    final cached = await repository.searchDocuments(
      query: const OutbreakDocumentQuery(search: 'surveillance'),
    );
    expect(cached.items.single.id, 'document-1');
    expect(cached.cache.isOffline, isTrue);
    final cachedContent = await repository.documentContent('document-1');
    expect(cachedContent.cache.isOffline, isTrue);
    expect(cachedContent.value.contentFormat, 'markdown');
  });

  test(
    'approved body content enriches ranked offline document search',
    () async {
      final store = TestLocalStore();
      addTearDown(store.close);
      final api = FakeOutbreakApi();
      final repository = OutbreakRepository(
        api,
        store.cache,
        clock: () => DateTime.utc(2026, 8, 10),
      );

      await repository.searchDocuments(
        query: const OutbreakDocumentQuery(search: 'surveillance'),
      );
      await repository.documentContent('document-1');
      api.offline = true;

      final result = await repository.searchDocuments(
        query: OutbreakDocumentQuery(
          search: 'contact tracing cadence',
          outbreakId: 'outbreak-1',
          documentKind: 'sop',
          authority: 'Ministry of Health',
          language: 'en',
          mimeType: 'text/markdown',
          effectiveFrom: DateTime.utc(2026, 7, 1),
          effectiveTo: DateTime.utc(2026, 9, 1),
        ),
      );

      expect(result.items.single.id, 'document-1');
      expect(result.cache.isOffline, isTrue);
      expect(result.cache.isStale, isTrue);
    },
  );

  test(
    'offline search ranks titles above headings and excludes old cache',
    () async {
      final store = TestLocalStore();
      addTearDown(store.close);
      final now = DateTime.utc(2026, 8, 10);
      final repository = OutbreakRepository(
        FakeOutbreakApi(),
        store.cache,
        clock: () => now,
      );
      Map<String, dynamic> cachedDocument(
        String id,
        String title, {
        List<String> headings = const <String>[],
        DateTime? verifiedAt,
      }) => {
        'id': id,
        'outbreak_id': 'outbreak-1',
        'title': title,
        'document_kind': 'sop',
        'language': 'en',
        '_cache_verified_at': (verifiedAt ?? now).toIso8601String(),
        '_cache_metadata_text': title.toLowerCase(),
        '_cache_headings': headings,
        '_cache_body_text': '',
      };
      await store.cache.putMany(
        type: 'public_outbreak_document',
        entities: [
          CachedEntityInput(
            id: 'title-match',
            data: cachedDocument('title-match', 'Isolation protocol'),
          ),
          CachedEntityInput(
            id: 'heading-match',
            data: cachedDocument(
              'heading-match',
              'Ebola SOP',
              headings: const ['Isolation protocol'],
            ),
          ),
          CachedEntityInput(
            id: 'expired-cache',
            data: cachedDocument(
              'expired-cache',
              'Isolation archive',
              verifiedAt: now.subtract(const Duration(days: 8)),
            ),
          ),
        ],
      );

      final result = await repository.searchCachedDocuments(
        query: const OutbreakDocumentQuery(search: 'isolation'),
      );

      expect(result.items.map((item) => item.id), [
        'title-match',
        'heading-match',
      ]);
    },
  );

  test('document reconciliation is isolated to its parent outbreak', () async {
    final store = TestLocalStore();
    addTearDown(store.close);
    final now = DateTime.utc(2026, 8, 10);
    final repository = OutbreakRepository(
      FakeOutbreakApi(),
      store.cache,
      clock: () => now,
    );
    await store.cache.putMany(
      type: 'public_outbreak_document',
      entities: [
        CachedEntityInput(
          id: 'old-outbreak-1',
          data: {
            'id': 'old-outbreak-1',
            'outbreak_id': 'outbreak-1',
            'title': 'Withdrawn old SOP',
            '_cache_verified_at': now.toIso8601String(),
          },
        ),
        CachedEntityInput(
          id: 'outbreak-2-document',
          data: {
            'id': 'outbreak-2-document',
            'outbreak_id': 'outbreak-2',
            'title': 'Independent response SOP',
            '_cache_verified_at': now.toIso8601String(),
          },
        ),
      ],
    );

    await repository.refreshDocuments('outbreak-1');
    final cached = await repository.searchCachedDocuments();
    final ids = cached.items.map((item) => item.id).toSet();

    expect(ids, containsAll(<String>{'document-1', 'outbreak-2-document'}));
    expect(ids, isNot(contains('old-outbreak-1')));
  });

  test(
    'unverified cached document content is not served indefinitely',
    () async {
      final store = TestLocalStore();
      addTearDown(store.close);
      final api = FakeOutbreakApi();
      var now = DateTime.now().toUtc();
      final repository = OutbreakRepository(api, store.cache, clock: () => now);
      await repository.searchDocuments();
      await repository.documentContent('document-1');

      api.offline = true;
      now = now.add(const Duration(days: 8));

      await expectLater(
        repository.documentContent('document-1'),
        throwsA(isA<PublicContentUnavailableException>()),
      );
      expect((await repository.searchCachedDocuments()).items, isEmpty);
    },
  );

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
      final metrics = <(String, Map<String, Object>)>[];
      final repository = OutbreakRepository(
        api,
        store.cache,
        clock: () => now,
        recordMetric: (name, parameters) async {
          metrics.add((name, parameters));
        },
      );
      await repository.outbreaks();
      now = now.add(const Duration(hours: 1));
      api.offline = true;
      final cached = await repository.outbreaks();
      expect(cached.cache.isOffline, isTrue);
      expect(cached.cache.isStale, isTrue);
      expect(metrics.first.$1, 'outbreak_cache_access');
      expect(metrics.first.$2, {
        'content_type': 'outbreak_list',
        'result': 'hit',
        'stale': 1,
      });
      expect(metrics.last.$1, 'outbreak_offline_content_used');
      expect(metrics.last.$2, {'content_type': 'outbreak_list', 'stale': 1});
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
    'published documents remain discoverable from cached outbreak detail',
    () async {
      final store = TestLocalStore();
      addTearDown(store.close);
      final api = FakeOutbreakApi();
      final repository = OutbreakRepository(api, store.cache);
      await repository.outbreak('outbreak-1');
      api.offline = true;

      final cached = await repository.outbreak('outbreak-1');

      expect(cached.cache.isOffline, isTrue);
      expect(cached.value.documents.single.id, 'document-1');
      expect(
        cached.value.documents.single.checksumSha256,
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      );
    },
  );

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
