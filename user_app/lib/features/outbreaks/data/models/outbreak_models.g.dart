// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'outbreak_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OutbreakMetric _$OutbreakMetricFromJson(Map<String, dynamic> json) =>
    _OutbreakMetric(
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? '',
      value: json['value'] as String? ?? '',
      unit: json['unit'] as String? ?? '',
    );

Map<String, dynamic> _$OutbreakMetricToJson(_OutbreakMetric instance) =>
    <String, dynamic>{
      'key': instance.key,
      'label': instance.label,
      'value': instance.value,
      'unit': instance.unit,
    };

_PublicOutbreak _$PublicOutbreakFromJson(Map<String, dynamic> json) =>
    _PublicOutbreak(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      diseaseType: json['disease_type'] as String? ?? '',
      status: json['status'] as String? ?? '',
      geographicArea: json['geographic_area'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      startDate: json['start_date'] == null
          ? null
          : DateTime.parse(json['start_date'] as String),
      lastUpdate: json['last_update'] == null
          ? null
          : DateTime.parse(json['last_update'] as String),
      visualTone: json['visual_tone'] as String? ?? 'warning',
      sourceOrganization: json['source_organization'] as String? ?? '',
      publishedAt: json['published_at'] == null
          ? null
          : DateTime.parse(json['published_at'] as String),
      metrics:
          (json['metrics'] as List<dynamic>?)
              ?.map((e) => OutbreakMetric.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <OutbreakMetric>[],
    );

Map<String, dynamic> _$PublicOutbreakToJson(_PublicOutbreak instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'disease_type': instance.diseaseType,
      'status': instance.status,
      'geographic_area': instance.geographicArea,
      'summary': instance.summary,
      'start_date': instance.startDate?.toIso8601String(),
      'last_update': instance.lastUpdate?.toIso8601String(),
      'visual_tone': instance.visualTone,
      'source_organization': instance.sourceOrganization,
      'published_at': instance.publishedAt?.toIso8601String(),
      'metrics': instance.metrics,
    };

_PublicOutbreakUpdate _$PublicOutbreakUpdateFromJson(
  Map<String, dynamic> json,
) => _PublicOutbreakUpdate(
  id: json['id'] as String,
  outbreakId: json['outbreak_id'] as String,
  title: json['title'] as String? ?? '',
  summary: json['summary'] as String? ?? '',
  publishedAt: json['published_at'] == null
      ? null
      : DateTime.parse(json['published_at'] as String),
);

Map<String, dynamic> _$PublicOutbreakUpdateToJson(
  _PublicOutbreakUpdate instance,
) => <String, dynamic>{
  'id': instance.id,
  'outbreak_id': instance.outbreakId,
  'title': instance.title,
  'summary': instance.summary,
  'published_at': instance.publishedAt?.toIso8601String(),
};

_PublicOutbreakResource _$PublicOutbreakResourceFromJson(
  Map<String, dynamic> json,
) => _PublicOutbreakResource(
  id: json['id'] as String,
  outbreakId: json['outbreak_id'] as String,
  title: json['title'] as String? ?? '',
  resourceType: json['resource_type'] as String? ?? 'link',
  url: json['url'] as String? ?? '',
  assetUrl: json['asset_url'] as String? ?? '',
  sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$PublicOutbreakResourceToJson(
  _PublicOutbreakResource instance,
) => <String, dynamic>{
  'id': instance.id,
  'outbreak_id': instance.outbreakId,
  'title': instance.title,
  'resource_type': instance.resourceType,
  'url': instance.url,
  'asset_url': instance.assetUrl,
  'sort_order': instance.sortOrder,
};

_PublicSituationReport _$PublicSituationReportFromJson(
  Map<String, dynamic> json,
) => _PublicSituationReport(
  id: json['id'] as String,
  outbreakId: json['outbreak_id'] as String?,
  title: json['title'] as String? ?? '',
  geographicArea: json['geographic_area'] as String? ?? '',
  summary: json['summary'] as String? ?? '',
  sourceOrganization: json['source_organization'] as String? ?? '',
  publicationDate: json['publication_date'] == null
      ? null
      : DateTime.parse(json['publication_date'] as String),
  status: json['status'] as String? ?? 'published',
  reportAssetUrl: json['report_asset_url'] as String? ?? '',
  keyHighlights:
      (json['key_highlights'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  metrics:
      (json['metrics'] as List<dynamic>?)
          ?.map((e) => OutbreakMetric.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <OutbreakMetric>[],
);

Map<String, dynamic> _$PublicSituationReportToJson(
  _PublicSituationReport instance,
) => <String, dynamic>{
  'id': instance.id,
  'outbreak_id': instance.outbreakId,
  'title': instance.title,
  'geographic_area': instance.geographicArea,
  'summary': instance.summary,
  'source_organization': instance.sourceOrganization,
  'publication_date': instance.publicationDate?.toIso8601String(),
  'status': instance.status,
  'report_asset_url': instance.reportAssetUrl,
  'key_highlights': instance.keyHighlights,
  'metrics': instance.metrics,
};
