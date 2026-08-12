import 'package:freezed_annotation/freezed_annotation.dart';

part 'offline_download.freezed.dart';
part 'offline_download.g.dart';

enum OfflineDownloadStatus {
  queued,
  downloading,
  ready,
  failed,
  canceled,
  corrupted,
  updateAvailable,
}

@freezed
abstract class OfflineDownload with _$OfflineDownload {
  const factory OfflineDownload({
    required String id,
    @JsonKey(name: 'guideline_id') required String guidelineId,
    @JsonKey(name: 'asset_type') required String assetType,
    @Default('') String title,
    @Default('') String version,
    @Default('') String checksum,
    @JsonKey(name: 'size_bytes') @Default(0) int sizeBytes,
    @Default(OfflineDownloadStatus.queued) OfflineDownloadStatus status,
    @Default(0) double progress,
    @JsonKey(name: 'local_path') @Default('') String localPath,
    @Default('') String error,
    required String scope,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _OfflineDownload;
  factory OfflineDownload.fromJson(Map<String, dynamic> json) =>
      _$OfflineDownloadFromJson(json);
}
