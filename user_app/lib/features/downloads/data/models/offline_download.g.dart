// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_download.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OfflineDownload _$OfflineDownloadFromJson(Map<String, dynamic> json) =>
    _OfflineDownload(
      id: json['id'] as String,
      guidelineId: json['guideline_id'] as String,
      assetType: json['asset_type'] as String,
      title: json['title'] as String? ?? '',
      version: json['version'] as String? ?? '',
      checksum: json['checksum'] as String? ?? '',
      sizeBytes: (json['size_bytes'] as num?)?.toInt() ?? 0,
      status:
          $enumDecodeNullable(_$OfflineDownloadStatusEnumMap, json['status']) ??
          OfflineDownloadStatus.queued,
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      localPath: json['local_path'] as String? ?? '',
      error: json['error'] as String? ?? '',
      scope: json['scope'] as String,
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$OfflineDownloadToJson(_OfflineDownload instance) =>
    <String, dynamic>{
      'id': instance.id,
      'guideline_id': instance.guidelineId,
      'asset_type': instance.assetType,
      'title': instance.title,
      'version': instance.version,
      'checksum': instance.checksum,
      'size_bytes': instance.sizeBytes,
      'status': _$OfflineDownloadStatusEnumMap[instance.status]!,
      'progress': instance.progress,
      'local_path': instance.localPath,
      'error': instance.error,
      'scope': instance.scope,
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

const _$OfflineDownloadStatusEnumMap = {
  OfflineDownloadStatus.queued: 'queued',
  OfflineDownloadStatus.downloading: 'downloading',
  OfflineDownloadStatus.ready: 'ready',
  OfflineDownloadStatus.failed: 'failed',
  OfflineDownloadStatus.canceled: 'canceled',
  OfflineDownloadStatus.corrupted: 'corrupted',
  OfflineDownloadStatus.updateAvailable: 'updateAvailable',
};
