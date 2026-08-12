import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:user_app/features/downloads/data/models/offline_download.dart';
import 'package:user_app/features/guidelines/data/models/guideline_publication.dart';

part 'guideline_downloads_controller.g.dart';

@riverpod
class GuidelineDownloadsController extends _$GuidelineDownloadsController {
  late String _scope;

  @override
  Future<List<OfflineDownload>> build() async {
    final user = ref.watch(authControllerProvider).valueOrNull?.user;
    _scope = user == null ? 'public' : 'user:${user.id}';
    final service = ref.watch(guidelineDownloadServiceProvider);
    final subscription = service.changes.listen((item) {
      if (item.scope != _scope || !state.hasValue) return;
      final items = [...state.requireValue];
      final index = items.indexWhere((value) => value.id == item.id);
      if (item.localPath.isEmpty && item.progress == 0) {
        if (index >= 0) items.removeAt(index);
      } else if (index >= 0) {
        items[index] = item;
      } else {
        items.insert(0, item);
      }
      state = AsyncData(items);
    });
    ref.onDispose(subscription.cancel);
    final items = await service.list(_scope);
    unawaited(_checkForUpdates(items));
    return items;
  }

  Future<OfflineDownload> download(
    GuidelinePublicationContent content, {
    bool originalDocument = false,
  }) async {
    final assetType = originalDocument ? 'original_pdf' : 'offline_package';
    final repository = ref.read(guidelinePublicationRepositoryProvider);
    final asset = originalDocument
        ? await repository.originalDocument(content.publication.id)
        : await repository.offlinePackage(content.publication.id);
    if (asset == null || asset.url.trim().isEmpty) {
      throw StateError(
        originalDocument
            ? 'The original document is not available for download.'
            : 'An offline package is not available for this guideline.',
      );
    }
    final result = await ref
        .read(guidelineDownloadServiceProvider)
        .download(
          guidelineId: content.publication.id,
          title: content.publication.title,
          version: content.manifest.version,
          assetType: assetType,
          asset: asset,
          scope: _scope,
        );
    final user = ref.read(authControllerProvider).valueOrNull?.user;
    if (result.status == OfflineDownloadStatus.ready && user != null) {
      try {
        await ref
            .read(guidelineLibraryRepositoryProvider)
            .recordDownload(
              guidelineId: content.publication.id,
              assetType: assetType,
            );
      } catch (_) {
        // The verified local package remains valid if history synchronization
        // is temporarily unavailable. A later library refresh reconciles it.
      }
    }
    return result;
  }

  void cancel(OfflineDownload item) => ref
      .read(guidelineDownloadServiceProvider)
      .cancel(item.guidelineId, item.assetType);

  Future<void> retry(OfflineDownload item) async {
    final content = await ref
        .read(guidelinePublicationRepositoryProvider)
        .content(item.guidelineId);
    await download(content, originalDocument: item.assetType == 'original_pdf');
  }

  Future<void> remove(OfflineDownload item) async {
    await ref.read(guidelineDownloadServiceProvider).remove(item);
    ref.invalidateSelf();
  }

  Future<int> storageUsage() =>
      ref.read(guidelineDownloadServiceProvider).storageUsage(_scope);

  Future<void> _checkForUpdates(List<OfflineDownload> items) async {
    final service = ref.read(guidelineDownloadServiceProvider);
    for (final item in items.where(
      (value) => value.status == OfflineDownloadStatus.ready,
    )) {
      try {
        final content = await ref
            .read(guidelinePublicationRepositoryProvider)
            .content(item.guidelineId);
        await service.markUpdateAvailable(
          scope: _scope,
          guidelineId: item.guidelineId,
          assetType: item.assetType,
          latestVersion: content.manifest.version,
        );
      } catch (_) {
        // A failed update check must not invalidate the verified local copy.
      }
    }
  }
}
