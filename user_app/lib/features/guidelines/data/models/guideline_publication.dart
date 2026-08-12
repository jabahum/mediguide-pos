import 'package:freezed_annotation/freezed_annotation.dart';

part 'guideline_publication.freezed.dart';
part 'guideline_publication.g.dart';

enum GuidelineReaderMode {
  @JsonValue('structured')
  structured,
  @JsonValue('partial')
  partial,
  @JsonValue('original_document')
  originalDocument,
}

@freezed
abstract class GuidelinePublication with _$GuidelinePublication {
  const factory GuidelinePublication({
    required String id,
    @Default('') String slug,
    @Default('') String title,
    @Default('') String description,
    @Default('') String country,
    @JsonKey(name: 'source_org') @Default('') String sourceOrganization,
    @JsonKey(name: 'program_area') @Default('') String programArea,
    @Default('') String language,
    @JsonKey(name: 'publication_date') @Default('') String publicationDate,
    @JsonKey(name: 'review_date') @Default('') String reviewDate,
    @Default('') String version,
    @JsonKey(name: 'last_updated') DateTime? lastUpdated,
    @JsonKey(name: 'intended_population')
    @Default('')
    String intendedPopulation,
    @JsonKey(name: 'healthcare_level') @Default('') String healthcareLevel,
  }) = _GuidelinePublication;

  factory GuidelinePublication.fromJson(Map<String, dynamic> json) =>
      _$GuidelinePublicationFromJson(json);
}

@freezed
abstract class GuidelineVersionSummary with _$GuidelineVersionSummary {
  const factory GuidelineVersionSummary({
    required String id,
    required String version,
    @JsonKey(name: 'publication_date') @Default('') String publicationDate,
    @JsonKey(name: 'review_date') @Default('') String reviewDate,
  }) = _GuidelineVersionSummary;

  factory GuidelineVersionSummary.fromJson(Map<String, dynamic> json) =>
      _$GuidelineVersionSummaryFromJson(json);
}

@freezed
abstract class GuidelineManifest with _$GuidelineManifest {
  const factory GuidelineManifest({
    @JsonKey(name: 'guideline_id') required String guidelineId,
    @JsonKey(name: 'version_id') required String versionId,
    @Default('') String version,
    @JsonKey(name: 'schema_version') @Default(1) int schemaVersion,
    @JsonKey(name: 'package_version') @Default(1) int packageVersion,
    @JsonKey(name: 'extraction_quality')
    @Default('unreviewed')
    String extractionQuality,
    @JsonKey(name: 'recommended_mode')
    @Default(GuidelineReaderMode.originalDocument)
    GuidelineReaderMode recommendedMode,
    @JsonKey(name: 'has_chapters') @Default(false) bool hasChapters,
    @JsonKey(name: 'has_key_points') @Default(false) bool hasKeyPoints,
    @JsonKey(name: 'has_tables') @Default(false) bool hasTables,
    @JsonKey(name: 'has_figures') @Default(false) bool hasFigures,
    @JsonKey(name: 'has_algorithms') @Default(false) bool hasAlgorithms,
    @JsonKey(name: 'has_original_pdf') @Default(false) bool hasOriginalPdf,
    @JsonKey(name: 'has_offline_package')
    @Default(false)
    bool hasOfflinePackage,
    @JsonKey(name: 'section_count') @Default(0) int sectionCount,
    @JsonKey(name: 'block_count') @Default(0) int blockCount,
    @JsonKey(name: 'table_count') @Default(0) int tableCount,
    @JsonKey(name: 'figure_count') @Default(0) int figureCount,
    @JsonKey(name: 'algorithm_count') @Default(0) int algorithmCount,
    @Default('') String checksum,
    @Default('') String etag,
    @JsonKey(name: 'generated_at') DateTime? generatedAt,
  }) = _GuidelineManifest;

  factory GuidelineManifest.fromJson(Map<String, dynamic> json) =>
      _$GuidelineManifestFromJson(json);
}

@freezed
abstract class PublicationSection with _$PublicationSection {
  const PublicationSection._();

  const factory PublicationSection({
    required String id,
    @JsonKey(name: 'parent_id') String? parentId,
    @Default('') String title,
    @Default('') String slug,
    @Default(1) int level,
    @JsonKey(name: 'page_start') int? pageStart,
    @JsonKey(name: 'page_end') int? pageEnd,
    @JsonKey(name: 'sort_order') @Default(0) int sortOrder,
  }) = _PublicationSection;

  factory PublicationSection.fromJson(Map<String, dynamic> json) =>
      _$PublicationSectionFromJson(json);

  String get pageLabel => pageStart == null
      ? ''
      : pageEnd == null || pageEnd == pageStart
      ? 'Page $pageStart'
      : 'Pages $pageStart–$pageEnd';
}

@freezed
abstract class GuidelineTablePayload with _$GuidelineTablePayload {
  const factory GuidelineTablePayload({
    @Default('') String title,
    @Default(<String>[]) List<String> columns,
    @Default(<List<String>>[]) List<List<String>> rows,
    @Default(<String>[]) List<String> footnotes,
  }) = _GuidelineTablePayload;

  factory GuidelineTablePayload.fromJson(Map<String, dynamic> json) =>
      _$GuidelineTablePayloadFromJson(json);
}

@freezed
abstract class GuidelineFigurePayload with _$GuidelineFigurePayload {
  const factory GuidelineFigurePayload({
    @JsonKey(name: 'asset_id') required String assetId,
    @Default('') String caption,
    @JsonKey(name: 'alternative_text')
    @Default('Clinical figure')
    String alternativeText,
  }) = _GuidelineFigurePayload;

  factory GuidelineFigurePayload.fromJson(Map<String, dynamic> json) =>
      _$GuidelineFigurePayloadFromJson(json);
}

@freezed
abstract class GuidelineCalloutPayload with _$GuidelineCalloutPayload {
  const factory GuidelineCalloutPayload({
    @Default('') String title,
    @Default('') String content,
    @Default('standard') String severity,
    @JsonKey(name: 'evidence_grade') @Default('') String evidenceGrade,
    @Default('') String source,
  }) = _GuidelineCalloutPayload;

  factory GuidelineCalloutPayload.fromJson(Map<String, dynamic> json) =>
      _$GuidelineCalloutPayloadFromJson(json);
}

@freezed
abstract class GuidelineAlgorithmNode with _$GuidelineAlgorithmNode {
  const factory GuidelineAlgorithmNode({
    required String id,
    @Default('') String label,
    @Default('') String kind,
    @Default(<String>[]) List<String> next,
  }) = _GuidelineAlgorithmNode;

  factory GuidelineAlgorithmNode.fromJson(Map<String, dynamic> json) =>
      _$GuidelineAlgorithmNodeFromJson(json);
}

@freezed
abstract class GuidelineAlgorithmPayload with _$GuidelineAlgorithmPayload {
  const factory GuidelineAlgorithmPayload({
    @Default('') String title,
    @Default(<GuidelineAlgorithmNode>[]) List<GuidelineAlgorithmNode> nodes,
  }) = _GuidelineAlgorithmPayload;

  factory GuidelineAlgorithmPayload.fromJson(Map<String, dynamic> json) =>
      _$GuidelineAlgorithmPayloadFromJson(json);
}

@freezed
abstract class GuidelineAsset with _$GuidelineAsset {
  const factory GuidelineAsset({
    @JsonKey(name: 'asset_id') String? id,
    @Default('') String type,
    @JsonKey(name: 'mime_type') @Default('') String mimeType,
    @Default('') String checksum,
    @JsonKey(name: 'size_bytes') @Default(0) int sizeBytes,
    @JsonKey(name: 'original_filename') @Default('') String originalFilename,
    @Default('') String url,
    @JsonKey(name: 'expires_at') DateTime? expiresAt,
  }) = _GuidelineAsset;

  factory GuidelineAsset.fromJson(Map<String, dynamic> json) =>
      _$GuidelineAssetFromJson(json);
}

@freezed
abstract class OfflinePackageManifest with _$OfflinePackageManifest {
  const factory OfflinePackageManifest({
    @JsonKey(name: 'guideline_id') required String guidelineId,
    @JsonKey(name: 'version_id') required String versionId,
    @JsonKey(name: 'package_version') required int packageVersion,
    required String checksum,
    @JsonKey(name: 'size_bytes') @Default(0) int sizeBytes,
    @Default(<String, String>{}) Map<String, String> checksums,
  }) = _OfflinePackageManifest;

  factory OfflinePackageManifest.fromJson(Map<String, dynamic> json) =>
      _$OfflinePackageManifestFromJson(json);
}

@Freezed(unionKey: 'kind', fallbackUnion: 'unknown')
sealed class GuidelineBlock with _$GuidelineBlock {
  const GuidelineBlock._();

  const factory GuidelineBlock.paragraph({
    required String id,
    String? sectionId,
    required int sortOrder,
    required String text,
    int? pageStart,
    int? pageEnd,
  }) = ParagraphGuidelineBlock;

  const factory GuidelineBlock.heading({
    required String id,
    String? sectionId,
    required int sortOrder,
    required String text,
    required int level,
    int? pageStart,
    int? pageEnd,
  }) = HeadingGuidelineBlock;

  const factory GuidelineBlock.orderedList({
    required String id,
    String? sectionId,
    required int sortOrder,
    required List<String> items,
    int? pageStart,
    int? pageEnd,
  }) = OrderedListGuidelineBlock;

  const factory GuidelineBlock.unorderedList({
    required String id,
    String? sectionId,
    required int sortOrder,
    required List<String> items,
    int? pageStart,
    int? pageEnd,
  }) = UnorderedListGuidelineBlock;

  const factory GuidelineBlock.table({
    required String id,
    String? sectionId,
    required int sortOrder,
    required GuidelineTablePayload payload,
    int? pageStart,
    int? pageEnd,
  }) = TableGuidelineBlock;

  const factory GuidelineBlock.figure({
    required String id,
    String? sectionId,
    required int sortOrder,
    required GuidelineFigurePayload payload,
    GuidelineAsset? asset,
    int? pageStart,
    int? pageEnd,
  }) = FigureGuidelineBlock;

  const factory GuidelineBlock.callout({
    required String id,
    String? sectionId,
    required int sortOrder,
    required String blockType,
    required GuidelineCalloutPayload payload,
    int? pageStart,
    int? pageEnd,
  }) = CalloutGuidelineBlock;

  const factory GuidelineBlock.algorithm({
    required String id,
    String? sectionId,
    required int sortOrder,
    required GuidelineAlgorithmPayload payload,
    int? pageStart,
    int? pageEnd,
  }) = AlgorithmGuidelineBlock;

  const factory GuidelineBlock.reference({
    required String id,
    String? sectionId,
    required int sortOrder,
    required String citation,
    @Default('') String url,
    int? pageStart,
    int? pageEnd,
  }) = ReferenceGuidelineBlock;

  const factory GuidelineBlock.pageBreak({
    required String id,
    String? sectionId,
    required int sortOrder,
    required int page,
    int? pageStart,
    int? pageEnd,
  }) = PageBreakGuidelineBlock;

  const factory GuidelineBlock.unknown({
    required String id,
    String? sectionId,
    required int sortOrder,
    @Default('unknown') String rawType,
    @Default(<String, dynamic>{}) Map<String, dynamic> raw,
    int? pageStart,
    int? pageEnd,
  }) = UnknownGuidelineBlock;

  factory GuidelineBlock.fromJson(Map<String, dynamic> json) =>
      _$GuidelineBlockFromJson(json);
}

final class GuidelinePublicationContent {
  const GuidelinePublicationContent({
    required this.publication,
    required this.manifest,
    required this.sections,
    required this.blocks,
  });

  final GuidelinePublication publication;
  final GuidelineManifest manifest;
  final List<PublicationSection> sections;
  final List<GuidelineBlock> blocks;

  List<GuidelineBlock> blocksFor(String sectionId) =>
      blocks
          .where((block) => block.sectionId == sectionId)
          .toList(growable: false)
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
}
