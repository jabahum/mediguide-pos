import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/core/network/api_client.dart';
import 'package:user_app/features/calculators/data/repositories/calculator_review_repository.dart';

import 'helpers/test_local_store.dart';

class FakeCalculatorReviewApi extends BackendApiService {
  bool offline = false;
  String? path;
  String? method;
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
    this.method = method;
    this.body = body;
    if (offline) throw const SocketException('offline');
    if (method == 'POST') return {'success': true};
    return {
      'data': {
        'tool_name': 'BMI review',
        'review_evidence_status': 'source_controlled_review_required',
        'version': {
          'id': 'version-1',
          'calculator_id': 'calculator-1',
          'semantic_version': '1.0.0',
          'status': 'pending_review',
          'definition_checksum': 'checksum-1',
          'definition': {
            'schema_version': '1.0',
            'tool_type': 'calculator',
            'title': 'BMI review',
            'version': '1.0.0',
            'locale': 'en',
            'inputs': [],
            'sections': [],
            'calculation': [],
            'rules': [],
            'outputs': [],
            'interpretations': [],
            'warnings': [],
            'citations': [],
            'completion': {'mode': 'none', 'reset_confirmation': true},
          },
        },
      },
    };
  }
}

void main() {
  test(
    'authorized reviewer preview is cached only in reviewer scope',
    () async {
      final api = FakeCalculatorReviewApi();
      final store = TestLocalStore();
      addTearDown(store.close);
      final repository = CalculatorReviewRepository(
        api,
        store.cache,
        reviewerId: 'reviewer-1',
      );

      final online = await repository.preview('version-1');
      expect(online.definition.title, 'BMI review');
      expect(api.path, '/api/v2/calculator-versions/version-1/preview');

      api.offline = true;
      final offline = await repository.preview('version-1');
      expect(offline.definitionChecksum, 'checksum-1');

      final otherReviewer = CalculatorReviewRepository(
        api,
        store.cache,
        reviewerId: 'reviewer-2',
      );
      await expectLater(
        otherReviewer.preview('version-1'),
        throwsA(isA<SocketException>()),
      );
    },
  );

  test(
    'expired reviewer preview is removed instead of served offline',
    () async {
      final api = FakeCalculatorReviewApi();
      final store = TestLocalStore();
      addTearDown(store.close);
      final repository = CalculatorReviewRepository(
        api,
        store.cache,
        reviewerId: 'reviewer-1',
        cacheTtl: Duration.zero,
      );
      await repository.preview('version-1');
      api.offline = true;
      await expectLater(
        repository.preview('version-1'),
        throwsA(isA<SocketException>()),
      );
    },
  );

  test('review comment uses the protected version endpoint', () async {
    final api = FakeCalculatorReviewApi();
    final store = TestLocalStore();
    addTearDown(store.close);
    final repository = CalculatorReviewRepository(
      api,
      store.cache,
      reviewerId: 'reviewer-1',
    );
    await repository.addComment('version-1', 'Boundary wording needs review.');
    expect(api.path, '/api/v2/calculator-versions/version-1/review-comments');
    expect(api.method, 'POST');
    expect(api.body, {'comment': 'Boundary wording needs review.'});
  });

  test('review route is not part of the public calculator catalog', () {
    // The protected backend route is intentionally not the published
    // /calculators/:id/definition endpoint and cannot alter the active version.
    expect(
      '/api/v2/calculator-versions/version-1/preview',
      isNot(contains('/calculators/')),
    );
  });
}
