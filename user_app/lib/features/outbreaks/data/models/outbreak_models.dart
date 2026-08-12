import 'package:freezed_annotation/freezed_annotation.dart';

part 'outbreak_models.freezed.dart';
part 'outbreak_models.g.dart';

@freezed
abstract class OutbreakMetric with _$OutbreakMetric {
  const factory OutbreakMetric({
    @Default('') String key,
    @Default('') String label,
    @Default('') String value,
    @Default('') String unit,
  }) = _OutbreakMetric;
  factory OutbreakMetric.fromJson(Map<String, dynamic> json) =>
      _$OutbreakMetricFromJson(json);
}

@freezed
abstract class PublicOutbreak with _$PublicOutbreak {
  const factory PublicOutbreak({
    required String id,
    @Default('') String title,
    @JsonKey(name: 'disease_type') @Default('') String diseaseType,
    @Default('') String status,
    @JsonKey(name: 'geographic_area') @Default('') String geographicArea,
    @Default('') String summary,
    @JsonKey(name: 'start_date') DateTime? startDate,
    @JsonKey(name: 'last_update') DateTime? lastUpdate,
    @JsonKey(name: 'visual_tone') @Default('warning') String visualTone,
    @JsonKey(name: 'source_organization')
    @Default('')
    String sourceOrganization,
    @JsonKey(name: 'published_at') DateTime? publishedAt,
    @Default(<OutbreakMetric>[]) List<OutbreakMetric> metrics,
  }) = _PublicOutbreak;
  factory PublicOutbreak.fromJson(Map<String, dynamic> json) =>
      _$PublicOutbreakFromJson(json);
}

@freezed
abstract class PublicOutbreakUpdate with _$PublicOutbreakUpdate {
  const factory PublicOutbreakUpdate({
    required String id,
    @JsonKey(name: 'outbreak_id') required String outbreakId,
    @Default('') String title,
    @Default('') String summary,
    @JsonKey(name: 'published_at') DateTime? publishedAt,
  }) = _PublicOutbreakUpdate;
  factory PublicOutbreakUpdate.fromJson(Map<String, dynamic> json) =>
      _$PublicOutbreakUpdateFromJson(json);
}

@freezed
abstract class PublicOutbreakResource with _$PublicOutbreakResource {
  const factory PublicOutbreakResource({
    required String id,
    @JsonKey(name: 'outbreak_id') required String outbreakId,
    @Default('') String title,
    @JsonKey(name: 'resource_type') @Default('link') String resourceType,
    @Default('') String url,
    @JsonKey(name: 'asset_url') @Default('') String assetUrl,
    @JsonKey(name: 'sort_order') @Default(0) int sortOrder,
  }) = _PublicOutbreakResource;
  factory PublicOutbreakResource.fromJson(Map<String, dynamic> json) =>
      _$PublicOutbreakResourceFromJson(json);
}

@freezed
abstract class PublicSituationReport with _$PublicSituationReport {
  const factory PublicSituationReport({
    required String id,
    @JsonKey(name: 'outbreak_id') String? outbreakId,
    @Default('') String title,
    @JsonKey(name: 'geographic_area') @Default('') String geographicArea,
    @Default('') String summary,
    @JsonKey(name: 'source_organization')
    @Default('')
    String sourceOrganization,
    @JsonKey(name: 'publication_date') DateTime? publicationDate,
    @Default('published') String status,
    @JsonKey(name: 'report_asset_url') @Default('') String reportAssetUrl,
    @JsonKey(name: 'key_highlights')
    @Default(<String>[])
    List<String> keyHighlights,
    @Default(<OutbreakMetric>[]) List<OutbreakMetric> metrics,
  }) = _PublicSituationReport;
  factory PublicSituationReport.fromJson(Map<String, dynamic> json) =>
      _$PublicSituationReportFromJson(json);
}

@freezed
abstract class PublicOutbreakDetail with _$PublicOutbreakDetail {
  const factory PublicOutbreakDetail({
    required PublicOutbreak outbreak,
    @Default(<PublicOutbreakUpdate>[]) List<PublicOutbreakUpdate> updates,
    @Default(<PublicOutbreakResource>[]) List<PublicOutbreakResource> resources,
    @Default(<PublicSituationReport>[]) List<PublicSituationReport> reports,
  }) = _PublicOutbreakDetail;
}
