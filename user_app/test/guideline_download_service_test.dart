import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/core/services/download_service.dart';
import 'package:user_app/features/downloads/data/models/offline_download.dart';
import 'package:user_app/features/guidelines/data/models/guideline_publication.dart';

import 'helpers/test_local_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestLocalStore store;
  late Directory directory;
  late List<int> payload;
  late GuidelineDownloadService service;

  setUp(() async {
    store = TestLocalStore();
    directory = await Directory.systemTemp.createTemp('mediguide_download_');
    payload = utf8.encode('verified guideline package');
    final dio = Dio()..httpClientAdapter = _BytesAdapter(() => payload);
    service = GuidelineDownloadService(
      dio,
      store.cache,
      directoryProvider: () async => directory,
    );
  });

  tearDown(() async {
    await service.dispose();
    await store.close();
    await directory.delete(recursive: true);
  });

  GuidelineAsset asset({String? checksum}) => GuidelineAsset(
    type: 'offline_package',
    mimeType: 'application/zip',
    checksum: checksum ?? sha256.convert(payload).toString(),
    sizeBytes: payload.length,
    originalFilename: 'package.zip',
    url: 'https://downloads.example.test/package',
    expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 5)),
  );

  test('verifies, stores, lists and removes an offline package', () async {
    final result = await service.download(
      guidelineId: 'guideline-1',
      title: 'Clinical guideline',
      version: '2',
      assetType: 'offline_package',
      asset: asset(),
      scope: 'public',
    );

    expect(result.status, OfflineDownloadStatus.ready);
    expect(await File(result.localPath).readAsBytes(), payload);
    expect(await service.storageUsage('public'), payload.length);
    expect((await service.list('public')).single.guidelineId, 'guideline-1');

    await service.remove(result);
    expect(await File(result.localPath).exists(), isFalse);
    expect(await service.list('public'), isEmpty);
  });

  test('rejects corrupt content and never leaves a partial package', () async {
    await expectLater(
      service.download(
        guidelineId: 'guideline-2',
        title: 'Clinical guideline',
        version: '1',
        assetType: 'offline_package',
        asset: asset(checksum: List.filled(64, '0').join()),
        scope: 'public',
      ),
      throwsA(isA<DownloadIntegrityException>()),
    );

    final item = (await service.list('public')).single;
    expect(item.status, OfflineDownloadStatus.corrupted);
    expect(item.localPath, isEmpty);
    expect(
      directory
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.part')),
      isEmpty,
    );
  });

  test('keeps public and authenticated metadata in separate scopes', () async {
    await service.download(
      guidelineId: 'guideline-3',
      title: 'Public copy',
      version: '1',
      assetType: 'offline_package',
      asset: asset(),
      scope: 'public',
    );
    await service.download(
      guidelineId: 'guideline-3',
      title: 'Private metadata',
      version: '1',
      assetType: 'offline_package',
      asset: asset(),
      scope: 'user:user-1',
    );

    expect((await service.list('public')).single.title, 'Public copy');
    expect(
      (await service.list('user:user-1')).single.title,
      'Private metadata',
    );
  });

  test(
    'outbreak reconciliation flags updates and removes revoked files',
    () async {
      final current = await service.download(
        guidelineId: 'document-current',
        title: 'Current SOP',
        version: '1',
        assetType: 'outbreak_document',
        asset: asset(),
        scope: 'public',
      );
      final revoked = await service.download(
        guidelineId: 'document-revoked',
        title: 'Revoked SOP',
        version: '1',
        assetType: 'outbreak_document',
        asset: asset(),
        scope: 'public',
      );

      await service.reconcileOutbreakDocuments({'document-current': '2'});

      final rows = await service.list('public');
      expect(rows.single.guidelineId, 'document-current');
      expect(rows.single.status, OfflineDownloadStatus.updateAvailable);
      expect(await File(current.localPath).exists(), isTrue);
      expect(await File(revoked.localPath).exists(), isFalse);
    },
  );
}

final class _BytesAdapter implements HttpClientAdapter {
  _BytesAdapter(this.bytes);
  final List<int> Function() bytes;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromBytes(
    bytes(),
    200,
    headers: {
      Headers.contentTypeHeader: ['application/octet-stream'],
      Headers.contentLengthHeader: ['${bytes().length}'],
    },
  );

  @override
  void close({bool force = false}) {}
}
