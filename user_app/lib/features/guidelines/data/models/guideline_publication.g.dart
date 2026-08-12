// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'guideline_publication.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GuidelinePublication _$GuidelinePublicationFromJson(
  Map<String, dynamic> json,
) => _GuidelinePublication(
  id: json['id'] as String,
  slug: json['slug'] as String? ?? '',
  title: json['title'] as String? ?? '',
  description: json['description'] as String? ?? '',
  country: json['country'] as String? ?? '',
  sourceOrganization: json['source_org'] as String? ?? '',
  programArea: json['program_area'] as String? ?? '',
  language: json['language'] as String? ?? '',
  publicationDate: json['publication_date'] as String? ?? '',
  reviewDate: json['review_date'] as String? ?? '',
  version: json['version'] as String? ?? '',
  lastUpdated: json['last_updated'] == null
      ? null
      : DateTime.parse(json['last_updated'] as String),
  intendedPopulation: json['intended_population'] as String? ?? '',
  healthcareLevel: json['healthcare_level'] as String? ?? '',
);

Map<String, dynamic> _$GuidelinePublicationToJson(
  _GuidelinePublication instance,
) => <String, dynamic>{
  'id': instance.id,
  'slug': instance.slug,
  'title': instance.title,
  'description': instance.description,
  'country': instance.country,
  'source_org': instance.sourceOrganization,
  'program_area': instance.programArea,
  'language': instance.language,
  'publication_date': instance.publicationDate,
  'review_date': instance.reviewDate,
  'version': instance.version,
  'last_updated': instance.lastUpdated?.toIso8601String(),
  'intended_population': instance.intendedPopulation,
  'healthcare_level': instance.healthcareLevel,
};

_GuidelineVersionSummary _$GuidelineVersionSummaryFromJson(
  Map<String, dynamic> json,
) => _GuidelineVersionSummary(
  id: json['id'] as String,
  version: json['version'] as String,
  publicationDate: json['publication_date'] as String? ?? '',
  reviewDate: json['review_date'] as String? ?? '',
);

Map<String, dynamic> _$GuidelineVersionSummaryToJson(
  _GuidelineVersionSummary instance,
) => <String, dynamic>{
  'id': instance.id,
  'version': instance.version,
  'publication_date': instance.publicationDate,
  'review_date': instance.reviewDate,
};

_GuidelineManifest _$GuidelineManifestFromJson(Map<String, dynamic> json) =>
    _GuidelineManifest(
      guidelineId: json['guideline_id'] as String,
      versionId: json['version_id'] as String,
      version: json['version'] as String? ?? '',
      schemaVersion: (json['schema_version'] as num?)?.toInt() ?? 1,
      packageVersion: (json['package_version'] as num?)?.toInt() ?? 1,
      extractionQuality: json['extraction_quality'] as String? ?? 'unreviewed',
      recommendedMode:
          $enumDecodeNullable(
            _$GuidelineReaderModeEnumMap,
            json['recommended_mode'],
          ) ??
          GuidelineReaderMode.originalDocument,
      hasChapters: json['has_chapters'] as bool? ?? false,
      hasKeyPoints: json['has_key_points'] as bool? ?? false,
      hasTables: json['has_tables'] as bool? ?? false,
      hasFigures: json['has_figures'] as bool? ?? false,
      hasAlgorithms: json['has_algorithms'] as bool? ?? false,
      hasOriginalPdf: json['has_original_pdf'] as bool? ?? false,
      hasOfflinePackage: json['has_offline_package'] as bool? ?? false,
      sectionCount: (json['section_count'] as num?)?.toInt() ?? 0,
      blockCount: (json['block_count'] as num?)?.toInt() ?? 0,
      tableCount: (json['table_count'] as num?)?.toInt() ?? 0,
      figureCount: (json['figure_count'] as num?)?.toInt() ?? 0,
      algorithmCount: (json['algorithm_count'] as num?)?.toInt() ?? 0,
      checksum: json['checksum'] as String? ?? '',
      etag: json['etag'] as String? ?? '',
      generatedAt: json['generated_at'] == null
          ? null
          : DateTime.parse(json['generated_at'] as String),
    );

Map<String, dynamic> _$GuidelineManifestToJson(
  _GuidelineManifest instance,
) => <String, dynamic>{
  'guideline_id': instance.guidelineId,
  'version_id': instance.versionId,
  'version': instance.version,
  'schema_version': instance.schemaVersion,
  'package_version': instance.packageVersion,
  'extraction_quality': instance.extractionQuality,
  'recommended_mode': _$GuidelineReaderModeEnumMap[instance.recommendedMode]!,
  'has_chapters': instance.hasChapters,
  'has_key_points': instance.hasKeyPoints,
  'has_tables': instance.hasTables,
  'has_figures': instance.hasFigures,
  'has_algorithms': instance.hasAlgorithms,
  'has_original_pdf': instance.hasOriginalPdf,
  'has_offline_package': instance.hasOfflinePackage,
  'section_count': instance.sectionCount,
  'block_count': instance.blockCount,
  'table_count': instance.tableCount,
  'figure_count': instance.figureCount,
  'algorithm_count': instance.algorithmCount,
  'checksum': instance.checksum,
  'etag': instance.etag,
  'generated_at': instance.generatedAt?.toIso8601String(),
};

const _$GuidelineReaderModeEnumMap = {
  GuidelineReaderMode.structured: 'structured',
  GuidelineReaderMode.partial: 'partial',
  GuidelineReaderMode.originalDocument: 'original_document',
};

_PublicationSection _$PublicationSectionFromJson(Map<String, dynamic> json) =>
    _PublicationSection(
      id: json['id'] as String,
      parentId: json['parent_id'] as String?,
      title: json['title'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      level: (json['level'] as num?)?.toInt() ?? 1,
      pageStart: (json['page_start'] as num?)?.toInt(),
      pageEnd: (json['page_end'] as num?)?.toInt(),
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$PublicationSectionToJson(_PublicationSection instance) =>
    <String, dynamic>{
      'id': instance.id,
      'parent_id': instance.parentId,
      'title': instance.title,
      'slug': instance.slug,
      'level': instance.level,
      'page_start': instance.pageStart,
      'page_end': instance.pageEnd,
      'sort_order': instance.sortOrder,
    };

_GuidelineTablePayload _$GuidelineTablePayloadFromJson(
  Map<String, dynamic> json,
) => _GuidelineTablePayload(
  title: json['title'] as String? ?? '',
  columns:
      (json['columns'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  rows:
      (json['rows'] as List<dynamic>?)
          ?.map((e) => (e as List<dynamic>).map((e) => e as String).toList())
          .toList() ??
      const <List<String>>[],
  footnotes:
      (json['footnotes'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
);

Map<String, dynamic> _$GuidelineTablePayloadToJson(
  _GuidelineTablePayload instance,
) => <String, dynamic>{
  'title': instance.title,
  'columns': instance.columns,
  'rows': instance.rows,
  'footnotes': instance.footnotes,
};

_GuidelineFigurePayload _$GuidelineFigurePayloadFromJson(
  Map<String, dynamic> json,
) => _GuidelineFigurePayload(
  assetId: json['asset_id'] as String,
  caption: json['caption'] as String? ?? '',
  alternativeText: json['alternative_text'] as String? ?? 'Clinical figure',
);

Map<String, dynamic> _$GuidelineFigurePayloadToJson(
  _GuidelineFigurePayload instance,
) => <String, dynamic>{
  'asset_id': instance.assetId,
  'caption': instance.caption,
  'alternative_text': instance.alternativeText,
};

_GuidelineCalloutPayload _$GuidelineCalloutPayloadFromJson(
  Map<String, dynamic> json,
) => _GuidelineCalloutPayload(
  title: json['title'] as String? ?? '',
  content: json['content'] as String? ?? '',
  severity: json['severity'] as String? ?? 'standard',
  evidenceGrade: json['evidence_grade'] as String? ?? '',
  source: json['source'] as String? ?? '',
);

Map<String, dynamic> _$GuidelineCalloutPayloadToJson(
  _GuidelineCalloutPayload instance,
) => <String, dynamic>{
  'title': instance.title,
  'content': instance.content,
  'severity': instance.severity,
  'evidence_grade': instance.evidenceGrade,
  'source': instance.source,
};

_GuidelineAlgorithmNode _$GuidelineAlgorithmNodeFromJson(
  Map<String, dynamic> json,
) => _GuidelineAlgorithmNode(
  id: json['id'] as String,
  label: json['label'] as String? ?? '',
  kind: json['kind'] as String? ?? '',
  next:
      (json['next'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
);

Map<String, dynamic> _$GuidelineAlgorithmNodeToJson(
  _GuidelineAlgorithmNode instance,
) => <String, dynamic>{
  'id': instance.id,
  'label': instance.label,
  'kind': instance.kind,
  'next': instance.next,
};

_GuidelineAlgorithmPayload _$GuidelineAlgorithmPayloadFromJson(
  Map<String, dynamic> json,
) => _GuidelineAlgorithmPayload(
  title: json['title'] as String? ?? '',
  nodes:
      (json['nodes'] as List<dynamic>?)
          ?.map(
            (e) => GuidelineAlgorithmNode.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const <GuidelineAlgorithmNode>[],
);

Map<String, dynamic> _$GuidelineAlgorithmPayloadToJson(
  _GuidelineAlgorithmPayload instance,
) => <String, dynamic>{'title': instance.title, 'nodes': instance.nodes};

_GuidelineAsset _$GuidelineAssetFromJson(Map<String, dynamic> json) =>
    _GuidelineAsset(
      id: json['asset_id'] as String?,
      type: json['type'] as String? ?? '',
      mimeType: json['mime_type'] as String? ?? '',
      checksum: json['checksum'] as String? ?? '',
      sizeBytes: (json['size_bytes'] as num?)?.toInt() ?? 0,
      originalFilename: json['original_filename'] as String? ?? '',
      url: json['url'] as String? ?? '',
      expiresAt: json['expires_at'] == null
          ? null
          : DateTime.parse(json['expires_at'] as String),
    );

Map<String, dynamic> _$GuidelineAssetToJson(_GuidelineAsset instance) =>
    <String, dynamic>{
      'asset_id': instance.id,
      'type': instance.type,
      'mime_type': instance.mimeType,
      'checksum': instance.checksum,
      'size_bytes': instance.sizeBytes,
      'original_filename': instance.originalFilename,
      'url': instance.url,
      'expires_at': instance.expiresAt?.toIso8601String(),
    };

_OfflinePackageManifest _$OfflinePackageManifestFromJson(
  Map<String, dynamic> json,
) => _OfflinePackageManifest(
  guidelineId: json['guideline_id'] as String,
  versionId: json['version_id'] as String,
  packageVersion: (json['package_version'] as num).toInt(),
  checksum: json['checksum'] as String,
  sizeBytes: (json['size_bytes'] as num?)?.toInt() ?? 0,
  checksums:
      (json['checksums'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ) ??
      const <String, String>{},
);

Map<String, dynamic> _$OfflinePackageManifestToJson(
  _OfflinePackageManifest instance,
) => <String, dynamic>{
  'guideline_id': instance.guidelineId,
  'version_id': instance.versionId,
  'package_version': instance.packageVersion,
  'checksum': instance.checksum,
  'size_bytes': instance.sizeBytes,
  'checksums': instance.checksums,
};

ParagraphGuidelineBlock _$ParagraphGuidelineBlockFromJson(
  Map<String, dynamic> json,
) => ParagraphGuidelineBlock(
  id: json['id'] as String,
  sectionId: json['sectionId'] as String?,
  sortOrder: (json['sortOrder'] as num).toInt(),
  text: json['text'] as String,
  pageStart: (json['pageStart'] as num?)?.toInt(),
  pageEnd: (json['pageEnd'] as num?)?.toInt(),
  $type: json['kind'] as String?,
);

Map<String, dynamic> _$ParagraphGuidelineBlockToJson(
  ParagraphGuidelineBlock instance,
) => <String, dynamic>{
  'id': instance.id,
  'sectionId': instance.sectionId,
  'sortOrder': instance.sortOrder,
  'text': instance.text,
  'pageStart': instance.pageStart,
  'pageEnd': instance.pageEnd,
  'kind': instance.$type,
};

HeadingGuidelineBlock _$HeadingGuidelineBlockFromJson(
  Map<String, dynamic> json,
) => HeadingGuidelineBlock(
  id: json['id'] as String,
  sectionId: json['sectionId'] as String?,
  sortOrder: (json['sortOrder'] as num).toInt(),
  text: json['text'] as String,
  level: (json['level'] as num).toInt(),
  pageStart: (json['pageStart'] as num?)?.toInt(),
  pageEnd: (json['pageEnd'] as num?)?.toInt(),
  $type: json['kind'] as String?,
);

Map<String, dynamic> _$HeadingGuidelineBlockToJson(
  HeadingGuidelineBlock instance,
) => <String, dynamic>{
  'id': instance.id,
  'sectionId': instance.sectionId,
  'sortOrder': instance.sortOrder,
  'text': instance.text,
  'level': instance.level,
  'pageStart': instance.pageStart,
  'pageEnd': instance.pageEnd,
  'kind': instance.$type,
};

OrderedListGuidelineBlock _$OrderedListGuidelineBlockFromJson(
  Map<String, dynamic> json,
) => OrderedListGuidelineBlock(
  id: json['id'] as String,
  sectionId: json['sectionId'] as String?,
  sortOrder: (json['sortOrder'] as num).toInt(),
  items: (json['items'] as List<dynamic>).map((e) => e as String).toList(),
  pageStart: (json['pageStart'] as num?)?.toInt(),
  pageEnd: (json['pageEnd'] as num?)?.toInt(),
  $type: json['kind'] as String?,
);

Map<String, dynamic> _$OrderedListGuidelineBlockToJson(
  OrderedListGuidelineBlock instance,
) => <String, dynamic>{
  'id': instance.id,
  'sectionId': instance.sectionId,
  'sortOrder': instance.sortOrder,
  'items': instance.items,
  'pageStart': instance.pageStart,
  'pageEnd': instance.pageEnd,
  'kind': instance.$type,
};

UnorderedListGuidelineBlock _$UnorderedListGuidelineBlockFromJson(
  Map<String, dynamic> json,
) => UnorderedListGuidelineBlock(
  id: json['id'] as String,
  sectionId: json['sectionId'] as String?,
  sortOrder: (json['sortOrder'] as num).toInt(),
  items: (json['items'] as List<dynamic>).map((e) => e as String).toList(),
  pageStart: (json['pageStart'] as num?)?.toInt(),
  pageEnd: (json['pageEnd'] as num?)?.toInt(),
  $type: json['kind'] as String?,
);

Map<String, dynamic> _$UnorderedListGuidelineBlockToJson(
  UnorderedListGuidelineBlock instance,
) => <String, dynamic>{
  'id': instance.id,
  'sectionId': instance.sectionId,
  'sortOrder': instance.sortOrder,
  'items': instance.items,
  'pageStart': instance.pageStart,
  'pageEnd': instance.pageEnd,
  'kind': instance.$type,
};

TableGuidelineBlock _$TableGuidelineBlockFromJson(Map<String, dynamic> json) =>
    TableGuidelineBlock(
      id: json['id'] as String,
      sectionId: json['sectionId'] as String?,
      sortOrder: (json['sortOrder'] as num).toInt(),
      payload: GuidelineTablePayload.fromJson(
        json['payload'] as Map<String, dynamic>,
      ),
      pageStart: (json['pageStart'] as num?)?.toInt(),
      pageEnd: (json['pageEnd'] as num?)?.toInt(),
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$TableGuidelineBlockToJson(
  TableGuidelineBlock instance,
) => <String, dynamic>{
  'id': instance.id,
  'sectionId': instance.sectionId,
  'sortOrder': instance.sortOrder,
  'payload': instance.payload,
  'pageStart': instance.pageStart,
  'pageEnd': instance.pageEnd,
  'kind': instance.$type,
};

FigureGuidelineBlock _$FigureGuidelineBlockFromJson(
  Map<String, dynamic> json,
) => FigureGuidelineBlock(
  id: json['id'] as String,
  sectionId: json['sectionId'] as String?,
  sortOrder: (json['sortOrder'] as num).toInt(),
  payload: GuidelineFigurePayload.fromJson(
    json['payload'] as Map<String, dynamic>,
  ),
  asset: json['asset'] == null
      ? null
      : GuidelineAsset.fromJson(json['asset'] as Map<String, dynamic>),
  pageStart: (json['pageStart'] as num?)?.toInt(),
  pageEnd: (json['pageEnd'] as num?)?.toInt(),
  $type: json['kind'] as String?,
);

Map<String, dynamic> _$FigureGuidelineBlockToJson(
  FigureGuidelineBlock instance,
) => <String, dynamic>{
  'id': instance.id,
  'sectionId': instance.sectionId,
  'sortOrder': instance.sortOrder,
  'payload': instance.payload,
  'asset': instance.asset,
  'pageStart': instance.pageStart,
  'pageEnd': instance.pageEnd,
  'kind': instance.$type,
};

CalloutGuidelineBlock _$CalloutGuidelineBlockFromJson(
  Map<String, dynamic> json,
) => CalloutGuidelineBlock(
  id: json['id'] as String,
  sectionId: json['sectionId'] as String?,
  sortOrder: (json['sortOrder'] as num).toInt(),
  blockType: json['blockType'] as String,
  payload: GuidelineCalloutPayload.fromJson(
    json['payload'] as Map<String, dynamic>,
  ),
  pageStart: (json['pageStart'] as num?)?.toInt(),
  pageEnd: (json['pageEnd'] as num?)?.toInt(),
  $type: json['kind'] as String?,
);

Map<String, dynamic> _$CalloutGuidelineBlockToJson(
  CalloutGuidelineBlock instance,
) => <String, dynamic>{
  'id': instance.id,
  'sectionId': instance.sectionId,
  'sortOrder': instance.sortOrder,
  'blockType': instance.blockType,
  'payload': instance.payload,
  'pageStart': instance.pageStart,
  'pageEnd': instance.pageEnd,
  'kind': instance.$type,
};

AlgorithmGuidelineBlock _$AlgorithmGuidelineBlockFromJson(
  Map<String, dynamic> json,
) => AlgorithmGuidelineBlock(
  id: json['id'] as String,
  sectionId: json['sectionId'] as String?,
  sortOrder: (json['sortOrder'] as num).toInt(),
  payload: GuidelineAlgorithmPayload.fromJson(
    json['payload'] as Map<String, dynamic>,
  ),
  pageStart: (json['pageStart'] as num?)?.toInt(),
  pageEnd: (json['pageEnd'] as num?)?.toInt(),
  $type: json['kind'] as String?,
);

Map<String, dynamic> _$AlgorithmGuidelineBlockToJson(
  AlgorithmGuidelineBlock instance,
) => <String, dynamic>{
  'id': instance.id,
  'sectionId': instance.sectionId,
  'sortOrder': instance.sortOrder,
  'payload': instance.payload,
  'pageStart': instance.pageStart,
  'pageEnd': instance.pageEnd,
  'kind': instance.$type,
};

ReferenceGuidelineBlock _$ReferenceGuidelineBlockFromJson(
  Map<String, dynamic> json,
) => ReferenceGuidelineBlock(
  id: json['id'] as String,
  sectionId: json['sectionId'] as String?,
  sortOrder: (json['sortOrder'] as num).toInt(),
  citation: json['citation'] as String,
  url: json['url'] as String? ?? '',
  pageStart: (json['pageStart'] as num?)?.toInt(),
  pageEnd: (json['pageEnd'] as num?)?.toInt(),
  $type: json['kind'] as String?,
);

Map<String, dynamic> _$ReferenceGuidelineBlockToJson(
  ReferenceGuidelineBlock instance,
) => <String, dynamic>{
  'id': instance.id,
  'sectionId': instance.sectionId,
  'sortOrder': instance.sortOrder,
  'citation': instance.citation,
  'url': instance.url,
  'pageStart': instance.pageStart,
  'pageEnd': instance.pageEnd,
  'kind': instance.$type,
};

PageBreakGuidelineBlock _$PageBreakGuidelineBlockFromJson(
  Map<String, dynamic> json,
) => PageBreakGuidelineBlock(
  id: json['id'] as String,
  sectionId: json['sectionId'] as String?,
  sortOrder: (json['sortOrder'] as num).toInt(),
  page: (json['page'] as num).toInt(),
  pageStart: (json['pageStart'] as num?)?.toInt(),
  pageEnd: (json['pageEnd'] as num?)?.toInt(),
  $type: json['kind'] as String?,
);

Map<String, dynamic> _$PageBreakGuidelineBlockToJson(
  PageBreakGuidelineBlock instance,
) => <String, dynamic>{
  'id': instance.id,
  'sectionId': instance.sectionId,
  'sortOrder': instance.sortOrder,
  'page': instance.page,
  'pageStart': instance.pageStart,
  'pageEnd': instance.pageEnd,
  'kind': instance.$type,
};

UnknownGuidelineBlock _$UnknownGuidelineBlockFromJson(
  Map<String, dynamic> json,
) => UnknownGuidelineBlock(
  id: json['id'] as String,
  sectionId: json['sectionId'] as String?,
  sortOrder: (json['sortOrder'] as num).toInt(),
  rawType: json['rawType'] as String? ?? 'unknown',
  raw: json['raw'] as Map<String, dynamic>? ?? const <String, dynamic>{},
  pageStart: (json['pageStart'] as num?)?.toInt(),
  pageEnd: (json['pageEnd'] as num?)?.toInt(),
  $type: json['kind'] as String?,
);

Map<String, dynamic> _$UnknownGuidelineBlockToJson(
  UnknownGuidelineBlock instance,
) => <String, dynamic>{
  'id': instance.id,
  'sectionId': instance.sectionId,
  'sortOrder': instance.sortOrder,
  'rawType': instance.rawType,
  'raw': instance.raw,
  'pageStart': instance.pageStart,
  'pageEnd': instance.pageEnd,
  'kind': instance.$type,
};
