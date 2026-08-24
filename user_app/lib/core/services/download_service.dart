import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'package:user_app/core/storage/local_cache_service.dart';
import 'package:user_app/features/downloads/data/models/offline_download.dart';
import 'package:user_app/features/guidelines/data/models/guideline_publication.dart';

typedef DownloadDirectoryProvider = Future<Directory> Function();

final class DownloadIntegrityException implements Exception {
  const DownloadIntegrityException(this.message);
  final String message;
  @override
  String toString() => message;
}

final class GuidelineDownloadService {
  GuidelineDownloadService(
    this._dio,
    this._cache, {
    DownloadDirectoryProvider? directoryProvider,
  }) : _directoryProvider =
           directoryProvider ?? getApplicationDocumentsDirectory;

  static const _cacheType = 'offline_guideline_download';
  final Dio _dio;
  final LocalCacheService _cache;
  final DownloadDirectoryProvider _directoryProvider;
  final Map<String, CancelToken> _cancelTokens = {};
  final StreamController<OfflineDownload> _changes =
      StreamController<OfflineDownload>.broadcast();

  Stream<OfflineDownload> get changes => _changes.stream;

  Future<OfflineDownload> download({
    required String guidelineId,
    required String title,
    required String version,
    required String assetType,
    required GuidelineAsset asset,
    required String scope,
  }) async {
    final id = _recordID(guidelineId, assetType);
    _validateScope(scope);
    final uri = Uri.tryParse(asset.url);
    if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) {
      throw ArgumentError.value(asset.url, 'asset.url', 'must be HTTP(S)');
    }
    if (asset.expiresAt != null &&
        !asset.expiresAt!.isAfter(DateTime.now().toUtc())) {
      throw const DownloadIntegrityException(
        'The signed download URL has expired. Refresh it before retrying.',
      );
    }
    final existing = await get(scope: scope, id: id);
    final queued = OfflineDownload(
      id: id,
      guidelineId: guidelineId,
      title: title,
      version: version,
      assetType: assetType,
      checksum: asset.checksum,
      sizeBytes: asset.sizeBytes,
      status: OfflineDownloadStatus.queued,
      localPath: existing?.localPath ?? '',
      scope: scope,
      updatedAt: DateTime.now().toUtc(),
    );
    await _save(queued);

    final root = await _directoryProvider();
    final directory = Directory(
      path.join(
        root.path,
        'offline_guidelines',
        _safeSegment(scope),
        _safeSegment(guidelineId),
      ),
    );
    await directory.create(recursive: true);
    final extension = _extension(asset.originalFilename, asset.mimeType);
    final finalFile = File(path.join(directory.path, '$assetType$extension'));
    final partialFile = File('${finalFile.path}.part');
    final stagedFile = File('${finalFile.path}.new');
    final backupFile = File('${finalFile.path}.backup');
    await _deleteIfExists(partialFile);
    await _deleteIfExists(stagedFile);

    final cancelToken = CancelToken();
    _cancelTokens[id] = cancelToken;
    var lastProgress = -1.0;
    try {
      await _save(
        queued.copyWith(
          status: OfflineDownloadStatus.downloading,
          updatedAt: DateTime.now().toUtc(),
        ),
      );
      await _dio.download(
        uri.toString(),
        partialFile.path,
        cancelToken: cancelToken,
        deleteOnError: true,
        onReceiveProgress: (received, total) {
          final progress = total <= 0 ? 0.0 : received / total;
          if ((progress - lastProgress).abs() < 0.01 && progress < 1) return;
          lastProgress = progress;
          _emit(
            queued.copyWith(
              status: OfflineDownloadStatus.downloading,
              progress: progress.clamp(0, 1),
              updatedAt: DateTime.now().toUtc(),
            ),
          );
        },
      );
      final actualChecksum = await _sha256(partialFile);
      final expectedChecksum = _normalizeChecksum(asset.checksum);
      if (expectedChecksum.isNotEmpty && actualChecksum != expectedChecksum) {
        await _deleteIfExists(partialFile);
        final corrupted = queued.copyWith(
          status: OfflineDownloadStatus.corrupted,
          error: 'Checksum verification failed.',
          updatedAt: DateTime.now().toUtc(),
        );
        await _save(corrupted);
        throw const DownloadIntegrityException(
          'Downloaded package failed checksum verification.',
        );
      }

      await partialFile.rename(stagedFile.path);
      var backedUp = false;
      if (await finalFile.exists()) {
        await _deleteIfExists(backupFile);
        await finalFile.rename(backupFile.path);
        backedUp = true;
      }
      try {
        await stagedFile.rename(finalFile.path);
        await _deleteIfExists(backupFile);
      } catch (_) {
        await _deleteIfExists(stagedFile);
        if (backedUp && await backupFile.exists()) {
          await backupFile.rename(finalFile.path);
        }
        rethrow;
      }
      await File('${finalFile.path}.json').writeAsString(
        jsonEncode({
          'guideline_id': guidelineId,
          'asset_type': assetType,
          'version': version,
          'checksum': actualChecksum,
          'size_bytes': await finalFile.length(),
          'downloaded_at': DateTime.now().toUtc().toIso8601String(),
        }),
        flush: true,
      );
      final ready = queued.copyWith(
        checksum: actualChecksum,
        sizeBytes: await finalFile.length(),
        status: OfflineDownloadStatus.ready,
        progress: 1,
        localPath: finalFile.path,
        error: '',
        updatedAt: DateTime.now().toUtc(),
      );
      await _save(ready);
      return ready;
    } on DioException catch (error) {
      await _deleteIfExists(partialFile);
      if (CancelToken.isCancel(error)) {
        final canceled = queued.copyWith(
          status: OfflineDownloadStatus.canceled,
          error: 'Download canceled.',
          updatedAt: DateTime.now().toUtc(),
        );
        await _save(canceled);
        return canceled;
      }
      final failed = queued.copyWith(
        status: OfflineDownloadStatus.failed,
        error: 'Download failed. The previous valid package was preserved.',
        updatedAt: DateTime.now().toUtc(),
      );
      await _save(failed);
      rethrow;
    } on DownloadIntegrityException {
      rethrow;
    } catch (_) {
      await _deleteIfExists(partialFile);
      await _deleteIfExists(stagedFile);
      final failed = queued.copyWith(
        status: OfflineDownloadStatus.failed,
        error: 'Download failed. The previous valid package was preserved.',
        updatedAt: DateTime.now().toUtc(),
      );
      await _save(failed);
      rethrow;
    } finally {
      _cancelTokens.remove(id);
    }
  }

  void cancel(String guidelineId, String assetType) {
    _cancelTokens[_recordID(guidelineId, assetType)]?.cancel('User canceled');
  }

  Future<List<OfflineDownload>> list(String scope) async {
    _validateScope(scope);
    final rows = await _cache.list(type: _cacheType, scope: scope, limit: 1000);
    final result = <OfflineDownload>[];
    for (final row in rows) {
      try {
        var item = OfflineDownload.fromJson(row);
        if (item.status == OfflineDownloadStatus.ready &&
            (item.localPath.isEmpty || !await File(item.localPath).exists())) {
          item = item.copyWith(
            status: OfflineDownloadStatus.failed,
            error: 'Downloaded file is missing.',
          );
          await _save(item);
        }
        result.add(item);
      } catch (_) {
        // Ignore malformed local metadata.
      }
    }
    result.sort(
      (a, b) => (b.updatedAt ?? DateTime(1970)).compareTo(
        a.updatedAt ?? DateTime(1970),
      ),
    );
    return result;
  }

  Future<OfflineDownload?> get({
    required String scope,
    required String id,
  }) async {
    final row = await _cache.get(type: _cacheType, id: id, scope: scope);
    return row == null ? null : OfflineDownload.fromJson(row);
  }

  Future<int> storageUsage(String scope) async => (await list(scope)).fold<int>(
    0,
    (total, item) =>
        total +
        (item.status == OfflineDownloadStatus.ready ? item.sizeBytes : 0),
  );

  Future<void> remove(OfflineDownload item) async {
    _validateScope(item.scope);
    cancel(item.guidelineId, item.assetType);
    if (item.localPath.isNotEmpty) {
      await _deleteIfExists(File(item.localPath));
      await _deleteIfExists(File('${item.localPath}.json'));
      await _deleteIfExists(File('${item.localPath}.part'));
      await _deleteIfExists(File('${item.localPath}.new'));
      await _deleteIfExists(File('${item.localPath}.backup'));
    }
    await _cache.remove(type: _cacheType, id: item.id, scope: item.scope);
    _emit(
      item.copyWith(
        status: OfflineDownloadStatus.canceled,
        localPath: '',
        progress: 0,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<void> markUpdateAvailable({
    required String scope,
    required String guidelineId,
    required String assetType,
    required String latestVersion,
  }) async {
    final item = await get(scope: scope, id: _recordID(guidelineId, assetType));
    if (item == null || item.version == latestVersion) return;
    await _save(
      item.copyWith(
        status: OfflineDownloadStatus.updateAvailable,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  }

  /// Reconciles public outbreak downloads only after a complete unfiltered
  /// sync. Revoked files are removed and newer versions are flagged without
  /// replacing the last checksum-verified copy.
  Future<void> reconcileOutbreakDocuments(
    Map<String, String> publishedVersions,
  ) async {
    final downloads = await list('public');
    for (final item in downloads.where(
      (value) => value.assetType == 'outbreak_document',
    )) {
      final currentVersion = publishedVersions[item.guidelineId];
      if (currentVersion == null) {
        await remove(item);
      } else if (currentVersion != item.version) {
        await markUpdateAvailable(
          scope: 'public',
          guidelineId: item.guidelineId,
          assetType: item.assetType,
          latestVersion: currentVersion,
        );
      }
    }
  }

  Future<void> _save(OfflineDownload item) async {
    await _cache.put(
      type: _cacheType,
      id: item.id,
      scope: item.scope,
      data: item.toJson(),
      searchableText: '${item.title} ${item.guidelineId} ${item.assetType}',
      metadata: {
        'status': item.status.name,
        'progress': item.progress,
        'version': item.version,
      },
      remoteUpdatedAt: item.updatedAt,
    );
    if (!_changes.isClosed) _changes.add(item);
  }

  void _emit(OfflineDownload item) {
    if (!_changes.isClosed) _changes.add(item);
  }

  Future<String> _sha256(File file) async =>
      (await sha256.bind(file.openRead()).first).toString().toLowerCase();

  String _normalizeChecksum(String value) =>
      value.trim().toLowerCase().replaceFirst(RegExp(r'^sha256[:-]?'), '');

  String _recordID(String guidelineId, String assetType) =>
      '${guidelineId.trim()}:${assetType.trim()}';

  String _safeSegment(String value) =>
      value.replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_');

  String _extension(String filename, String mimeType) {
    final extension = path.extension(filename).toLowerCase();
    if (RegExp(r'^\.[a-z0-9]{1,8}$').hasMatch(extension)) return extension;
    if (mimeType == 'application/pdf') return '.pdf';
    if (mimeType.contains('zip')) return '.zip';
    return '.bin';
  }

  void _validateScope(String scope) {
    if (scope != 'public' && !scope.startsWith('user:')) {
      throw ArgumentError.value(scope, 'scope', 'must be public or user:<id>');
    }
  }

  Future<void> _deleteIfExists(File file) async {
    if (await file.exists()) await file.delete();
  }

  Future<void> dispose() => _changes.close();
}
