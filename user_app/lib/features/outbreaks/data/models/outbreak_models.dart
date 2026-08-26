import 'package:freezed_annotation/freezed_annotation.dart';

part 'outbreak_models.freezed.dart';
part 'outbreak_models.g.dart';

Object? _readDocumentId(Map<dynamic, dynamic> json, String key) =>
    json[key] ?? json['id'];

Object? _readDocumentFormat(Map<dynamic, dynamic> json, String key) =>
    json[key] ?? json['content_format'];

@freezed
abstract class OutbreakMetric with _$OutbreakMetric {
  const factory OutbreakMetric({
    @Default('') String key,
    @Default('') String label,
    @Default('') String value,
    @Default('') String unit,
    @JsonKey(name: 'numeric_value') double? numericValue,
    @JsonKey(name: 'as_of') DateTime? asOf,
    @JsonKey(name: 'source_reference') @Default('') String sourceReference,
    @JsonKey(name: 'sort_order') @Default(0) int sortOrder,
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
    @JsonKey(name: 'effective_at') DateTime? effectiveAt,
    @JsonKey(name: 'data_as_of') DateTime? dataAsOf,
    @JsonKey(name: 'last_verified_at') DateTime? lastVerifiedAt,
    @JsonKey(name: 'source_reference') @Default('') String sourceReference,
    @JsonKey(name: 'source_url') @Default('') String sourceUrl,
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
    @JsonKey(name: 'outbreak_title') @Default('') String outbreakTitle,
    @Default('') String title,
    @Default('') String description,
    @JsonKey(name: 'issuing_organization')
    @Default('')
    String issuingOrganization,
    @JsonKey(name: 'resource_type') @Default('link') String resourceType,
    @JsonKey(name: 'target_type') @Default('') String targetType,
    @JsonKey(name: 'target_url') @Default('') String targetUrl,
    @Default('') String url,
    @JsonKey(name: 'asset_url') @Default('') String assetUrl,
    @JsonKey(name: 'sort_order') @Default(0) int sortOrder,
    @JsonKey(name: 'publication_date') DateTime? publicationDate,
    @JsonKey(name: 'published_at') DateTime? publishedAt,
    @JsonKey(name: 'reader_capability') @Default('') String readerCapability,
    @JsonKey(name: 'download_capability')
    @Default(false)
    bool downloadCapability,
  }) = _PublicOutbreakResource;
  factory PublicOutbreakResource.fromJson(Map<String, dynamic> json) =>
      _$PublicOutbreakResourceFromJson(json);
}

@freezed
abstract class PublicOutbreakDocument with _$PublicOutbreakDocument {
  const factory PublicOutbreakDocument({
    required String id,
    @JsonKey(name: 'outbreak_id') required String outbreakId,
    @Default('') String title,
    @Default('') String description,
    @JsonKey(name: 'document_kind') @Default('other') String documentKind,
    @JsonKey(name: 'issuing_authority') @Default('') String issuingAuthority,
    @JsonKey(name: 'document_number') @Default('') String documentNumber,
    @Default('') String version,
    @Default('en') String language,
    @Default('') String audience,
    @JsonKey(name: 'effective_date') DateTime? effectiveDate,
    @JsonKey(name: 'review_date') DateTime? reviewDate,
    @JsonKey(name: 'expires_at') DateTime? expiresAt,
    @JsonKey(name: 'original_filename') @Default('') String originalFilename,
    @JsonKey(name: 'mime_type') @Default('') String mimeType,
    @JsonKey(name: 'file_size') @Default(0) int fileSize,
    @JsonKey(name: 'checksum_sha256') @Default('') String checksumSha256,
    @JsonKey(name: 'page_count') int? pageCount,
    @JsonKey(name: 'download_url') @Default('') String downloadUrl,
    @JsonKey(name: 'published_at') DateTime? publishedAt,
    @JsonKey(name: 'outbreak_title') @Default('') String outbreakTitle,
    @JsonKey(name: 'outbreak_disease') @Default('') String outbreakDisease,
    @JsonKey(name: 'outbreak_area') @Default('') String outbreakArea,
    @JsonKey(name: 'search_snippet') @Default('') String searchSnippet,
    @JsonKey(name: 'matching_heading') @Default('') String matchingHeading,
    @JsonKey(name: 'matching_section_id') @Default('') String matchingSectionId,
    @JsonKey(name: 'matching_pdf_page') int? matchingPdfPage,
    @JsonKey(name: 'search_relevance_score')
    @Default(0)
    double searchRelevanceScore,
    @JsonKey(name: 'reader_url') @Default('') String readerUrl,
    @JsonKey(name: 'content_url') @Default('') String contentUrl,
    @JsonKey(name: 'content_format') @Default('') String contentFormat,
    @JsonKey(name: 'supports_inline') @Default(false) bool supportsInline,
    @JsonKey(name: 'supports_offline_download')
    @Default(false)
    bool supportsOfflineDownload,
  }) = _PublicOutbreakDocument;
  factory PublicOutbreakDocument.fromJson(Map<String, dynamic> json) =>
      _$PublicOutbreakDocumentFromJson(json);
}

@freezed
abstract class OutbreakDocumentSection with _$OutbreakDocumentSection {
  const factory OutbreakDocumentSection({
    required String id,
    @Default('') String heading,
    @Default(1) int level,
    @Default('') String text,
    int? page,
  }) = _OutbreakDocumentSection;
  factory OutbreakDocumentSection.fromJson(Map<String, dynamic> json) =>
      _$OutbreakDocumentSectionFromJson(json);
}

@freezed
abstract class OutbreakDocumentContent with _$OutbreakDocumentContent {
  const factory OutbreakDocumentContent({
    @JsonKey(name: 'document_id', readValue: _readDocumentId)
    required String documentId,
    @JsonKey(name: 'outbreak_id') required String outbreakId,
    @Default('') String title,
    @Default('') String content,
    @JsonKey(name: 'format', readValue: _readDocumentFormat)
    @Default('plain_text')
    String contentFormat,
    @JsonKey(name: 'mime_type') @Default('') String mimeType,
    @Default(<OutbreakDocumentSection>[])
    List<OutbreakDocumentSection> sections,
    @JsonKey(name: 'checksum_sha256') @Default('') String checksumSha256,
    @JsonKey(name: 'published_at') DateTime? publishedAt,
    @JsonKey(name: 'effective_date') DateTime? effectiveDate,
    @JsonKey(name: 'review_date') DateTime? reviewDate,
    @JsonKey(name: 'expires_at') DateTime? expiresAt,
    @JsonKey(name: 'download_url') @Default('') String downloadUrl,
    @JsonKey(name: 'original_available') @Default(false) bool originalAvailable,
    @JsonKey(name: 'can_read_inline') @Default(false) bool canReadInline,
  }) = _OutbreakDocumentContent;
  factory OutbreakDocumentContent.fromJson(Map<String, dynamic> json) =>
      _$OutbreakDocumentContentFromJson(json);
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
    @JsonKey(name: 'effective_at') DateTime? effectiveAt,
    @JsonKey(name: 'data_as_of') DateTime? dataAsOf,
    @JsonKey(name: 'last_verified_at') DateTime? lastVerifiedAt,
    @JsonKey(name: 'source_reference') @Default('') String sourceReference,
    @JsonKey(name: 'source_url') @Default('') String sourceUrl,
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
    @Default(<PublicOutbreakDocument>[]) List<PublicOutbreakDocument> documents,
    @Default(<PublicSituationReport>[]) List<PublicSituationReport> reports,
  }) = _PublicOutbreakDetail;
}

final class PublicCacheMetadata {
  const PublicCacheMetadata({
    required this.cachedAt,
    required this.lastVerifiedAt,
    required this.isStale,
    required this.isWithdrawn,
    required this.isOffline,
  });

  const PublicCacheMetadata.online({this.lastVerifiedAt})
    : cachedAt = null,
      isStale = false,
      isWithdrawn = false,
      isOffline = false;

  final DateTime? cachedAt;
  final DateTime? lastVerifiedAt;
  final bool isStale;
  final bool isWithdrawn;
  final bool isOffline;
}

final class PublicContent<T> {
  const PublicContent({
    required this.value,
    required this.cache,
    this.partialFailures = const <String>[],
  });

  final T value;
  final PublicCacheMetadata cache;
  final List<String> partialFailures;
}

final class PublicPage<T> {
  const PublicPage({
    required this.items,
    required this.page,
    required this.perPage,
    required this.totalItems,
    required this.totalPages,
    required this.cache,
  });

  final List<T> items;
  final int page;
  final int perPage;
  final int totalItems;
  final int totalPages;
  final PublicCacheMetadata cache;

  bool get hasMore => page < totalPages;
}

final class PublicContentUnavailableException implements Exception {
  const PublicContentUnavailableException(
    this.message, {
    this.isWithdrawn = false,
  });

  final String message;
  final bool isWithdrawn;

  @override
  String toString() => message;
}
