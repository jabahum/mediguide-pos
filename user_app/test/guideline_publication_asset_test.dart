import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/core/network/api_client.dart';
import 'package:user_app/features/guidelines/data/repositories/guideline_publication_repository.dart';

import 'helpers/test_local_store.dart';

void main() {
  test(
    'resolves same-origin guideline download routes for the mobile client',
    () async {
      final store = TestLocalStore();
      addTearDown(store.close);
      final repository = GuidelinePublicationRepository(
        _GuidelineAssetApi(),
        store.cache,
      );

      final asset = await repository.offlinePackage('guideline-1');

      expect(asset, isNotNull);
      final uri = Uri.parse(asset!.url);
      expect(uri.hasScheme, isTrue);
      expect(uri.host, isNot('minio'));
      expect(
        uri.path,
        '/api/public/guidelines/guideline-1/offline-package/download',
      );
    },
  );
}

final class _GuidelineAssetApi extends BackendApiService {
  @override
  Future<Map<String, dynamic>> requestJson(
    String path, {
    required String method,
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool includeAuth = true,
  }) async => {
    'data': {
      'type': 'offline_package',
      'mime_type': 'application/zip',
      'url': '/api/public/guidelines/guideline-1/offline-package/download',
      'expires_at': DateTime.now()
          .toUtc()
          .add(const Duration(minutes: 10))
          .toIso8601String(),
    },
  };
}
