import 'package:user_app/core/network/contracts/generated/backend_contracts.dart';

final class GuidelineCollectionSummary {
  const GuidelineCollectionSummary({
    required this.id,
    required this.name,
    required this.description,
    required this.itemCount,
    this.updatedAt,
  });

  factory GuidelineCollectionSummary.fromContract(
    ServicesGuidelineCollectionDTO value,
  ) => GuidelineCollectionSummary(
    id: value.id ?? '',
    name: value.name ?? '',
    description: value.description ?? '',
    itemCount: value.itemCount ?? 0,
    updatedAt: DateTime.tryParse(value.updatedAt ?? ''),
  );

  factory GuidelineCollectionSummary.fromJson(Map<String, dynamic> value) =>
      GuidelineCollectionSummary(
        id: value['id']?.toString() ?? '',
        name: value['name']?.toString() ?? '',
        description: value['description']?.toString() ?? '',
        itemCount: (value['item_count'] as num?)?.toInt() ?? 0,
        updatedAt: DateTime.tryParse(value['updated_at']?.toString() ?? ''),
      );

  final String id;
  final String name;
  final String description;
  final int itemCount;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'item_count': itemCount,
    'updated_at': updatedAt?.toIso8601String(),
  };
}

final class GuidelineDownloadRecord {
  const GuidelineDownloadRecord({
    required this.id,
    required this.guidelineId,
    required this.versionId,
    required this.assetType,
    this.downloadedAt,
  });

  factory GuidelineDownloadRecord.fromContract(
    ServicesGuidelineDownloadDTO value,
  ) => GuidelineDownloadRecord(
    id: value.id ?? '',
    guidelineId: value.guidelineId ?? '',
    versionId: value.versionId ?? '',
    assetType: value.assetType ?? '',
    downloadedAt: DateTime.tryParse(value.downloadedAt ?? ''),
  );

  factory GuidelineDownloadRecord.fromJson(Map<String, dynamic> value) =>
      GuidelineDownloadRecord(
        id: value['id']?.toString() ?? '',
        guidelineId: value['guideline_id']?.toString() ?? '',
        versionId: value['version_id']?.toString() ?? '',
        assetType: value['asset_type']?.toString() ?? '',
        downloadedAt: DateTime.tryParse(
          value['downloaded_at']?.toString() ?? '',
        ),
      );

  final String id;
  final String guidelineId;
  final String versionId;
  final String assetType;
  final DateTime? downloadedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'guideline_id': guidelineId,
    'version_id': versionId,
    'asset_type': assetType,
    'downloaded_at': downloadedAt?.toIso8601String(),
  };
}
