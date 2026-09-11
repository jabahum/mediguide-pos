import 'package:user_app/core/network/api_client.dart';
import 'package:user_app/core/network/contracts/generated/backend_contracts.dart';
import 'package:user_app/core/config/app_config.dart';
import 'package:user_app/core/storage/local_cache_service.dart';
import 'package:user_app/features/guidelines/data/models/guideline_publication.dart';
import 'package:user_app/shared/models/paginated_response.dart';

final class GuidelinePublicationRepository {
  GuidelinePublicationRepository(this._api, this._cache);

  static const _publicationType = 'guideline_publication';
  static const _contentType = 'guideline_publication_content';
  static const _contentIndexType = 'guideline_publication_content_index';
  static const _ttl = Duration(hours: 24);

  final BackendApiService _api;
  final LocalCacheService _cache;

  String get _cacheScope =>
      'public:${Uri.parse(AppConfig.current.apiBaseUrl).normalizePath().toString().toLowerCase()}';

  Future<PaginatedResponse<GuidelinePublication>> publications({
    int page = 1,
    int perPage = 20,
    String search = '',
    String programArea = '',
    String categoryId = '',
  }) async {
    try {
      final response = await _api.requestJson(
        '/api/public/guidelines',
        method: 'GET',
        includeAuth: false,
        query: <String, String>{
          'page': '$page',
          'per_page': '$perPage',
          if (search.trim().isNotEmpty) 'search': search.trim(),
          if (programArea.trim().isNotEmpty) 'program_area': programArea.trim(),
          if (categoryId.trim().isNotEmpty) 'category_id': categoryId.trim(),
        },
      );
      final data = _data(response);
      final items = _maps(
        data['items'],
      ).map(_publicationFromContract).toList(growable: false);
      await _bestEffortCache(
        () => _cache.putMany(
          type: _publicationType,
          scope: _cacheScope,
          ttl: _ttl,
          entities: items.map(
            (item) => CachedEntityInput(
              id: item.id,
              data: item.toJson(),
              searchableText:
                  '${item.title} ${item.description} ${item.programArea} ${item.categories.map((category) => category.name).join(' ')}',
              version: item.version,
              remoteUpdatedAt: item.lastUpdated,
            ),
          ),
        ),
      );
      return PaginatedResponse<GuidelinePublication>(
        items: items,
        page: _integer(data['page'], page),
        perPage: _integer(data['per_page'], perPage),
        totalItems: _integer(data['total_items'], items.length),
        totalPages: _integer(data['total_pages'], 1),
      );
    } catch (_) {
      final cached = await _cache.list(
        type: _publicationType,
        scope: _cacheScope,
        search: search.trim().isNotEmpty ? search : programArea,
        limit: programArea.trim().isEmpty && categoryId.trim().isEmpty ? perPage : 1000,
        offset: programArea.trim().isEmpty && categoryId.trim().isEmpty
            ? (page - 1).clamp(0, 1 << 30) * perPage
            : 0,
      );
      if (cached.isEmpty) rethrow;
      final normalizedArea = programArea.trim().toLowerCase();
      final normalizedCategory = categoryId.trim().toLowerCase();
      final filtered = cached
          .map(GuidelinePublication.fromJson)
          .where(
            (item) =>
                normalizedArea.isEmpty ||
                item.programArea.trim().toLowerCase() == normalizedArea,
          )
          .where((item) => normalizedCategory.isEmpty || item.categories.any((category) => category.id.toLowerCase() == normalizedCategory))
          .toList(growable: false);
      final items = filtered
          .skip((page - 1).clamp(0, 1 << 30) * perPage)
          .take(perPage)
          .toList(growable: false);
      return PaginatedResponse<GuidelinePublication>(
        items: items,
        page: page,
        perPage: perPage,
        totalItems: filtered.length,
        totalPages: filtered.isEmpty ? 1 : (filtered.length / perPage).ceil(),
      );
    }
  }

  Future<GuidelinePublicationContent> content(String guidelineId) async {
    final id = guidelineId.trim();
    if (id.isEmpty) {
      throw ArgumentError.value(guidelineId, 'guidelineId', 'is required');
    }

    GuidelineManifest? requestedManifest;
    try {
      var manifestResponse = await _public(
        '/api/public/guidelines/$id/manifest',
      );
      var manifest = _manifestFromContract(_data(manifestResponse));
      requestedManifest = manifest;
      final results = await Future.wait<Map<String, dynamic>>([
        _public('/api/public/guidelines/$id'),
        _structuredContent(id),
        _public(
          '/api/public/guidelines/$id/figures',
          query: {'page': '1', 'per_page': '500'},
        ),
      ]);
      final publication = _publicationFromContract(_data(results[0]));
      final structured = _data(results[1]);
      _verifyContentIdentity(structured, manifest);
      manifestResponse = await _public('/api/public/guidelines/$id/manifest');
      final currentManifest = _manifestFromContract(_data(manifestResponse));
      if (_publicationIdentity(currentManifest) !=
          _publicationIdentity(manifest)) {
        throw const GuidelinePublicationVersionMismatch();
      }
      manifest = currentManifest;
      requestedManifest = manifest;
      final sections =
          _maps(
              structured['sections'],
            ).map(_sectionFromContract).toList(growable: false)
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      final figureAssets = <String, GuidelineAsset>{};
      for (final row in _maps(_data(results[2])['items'])) {
        final blockId = row['id']?.toString() ?? '';
        final asset = _map(row['asset']);
        if (blockId.isNotEmpty && asset.isNotEmpty) {
          figureAssets[blockId] = _assetFromContract(asset);
        }
      }

      final blocks = _maps(structured['blocks'])
          .map(
            (row) => _block(
              ServicesPublicGuidelineBlock.fromJson(row),
              figureAssets[row['id']?.toString()],
            ),
          )
          .toList();
      blocks.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      final value = GuidelinePublicationContent(
        publication: publication,
        manifest: manifest,
        sections: sections,
        blocks: blocks,
      );
      final cacheId = _publicationIdentity(manifest);
      await _cache.put(
        type: _contentType,
        id: cacheId,
        scope: _cacheScope,
        ttl: _ttl,
        version: manifest.version,
        data: <String, dynamic>{
          'publication': publication.toJson(),
          'manifest': manifest.toJson(),
          'sections': sections.map((item) => item.toJson()).toList(),
          'blocks': blocks.map((item) => item.toJson()).toList(),
        },
        searchableText: [
          publication.title,
          publication.description,
          ...sections.map((item) => item.title),
          ...blocks.map(_blockText),
        ].join(' '),
      );
      await _cache.put(
        type: _contentIndexType,
        id: id,
        scope: _cacheScope,
        ttl: _ttl,
        version: manifest.version,
        data: {'cache_id': cacheId},
      );
      return value;
    } on GuidelinePublicationVersionMismatch {
      rethrow;
    } catch (_) {
      final index = await _cache.get(
        type: _contentIndexType,
        id: id,
        scope: _cacheScope,
      );
      final cacheId = index?['cache_id']?.toString() ?? '';
      if (cacheId.isEmpty) rethrow;
      if (requestedManifest != null &&
          cacheId != _publicationIdentity(requestedManifest)) {
        throw const GuidelinePublicationVersionMismatch();
      }
      final cached = await _cache.get(
        type: _contentType,
        id: cacheId,
        scope: _cacheScope,
      );
      if (cached == null) rethrow;
      return GuidelinePublicationContent(
        publication: GuidelinePublication.fromJson(_map(cached['publication'])),
        manifest: GuidelineManifest.fromJson(_map(cached['manifest'])),
        sections: _maps(
          cached['sections'],
        ).map(PublicationSection.fromJson).toList(),
        blocks: _maps(cached['blocks']).map(GuidelineBlock.fromJson).toList(),
      );
    }
  }

  Future<GuidelineAsset?> originalDocument(String guidelineId) =>
      _asset('/api/public/guidelines/$guidelineId/original');

  Future<GuidelineAsset?> offlinePackage(String guidelineId) =>
      _asset('/api/public/guidelines/$guidelineId/offline-package');

  Future<List<GuidelineContentSearchResult>> searchContent(
    String query, {
    int limit = 20,
  }) async {
    final normalized = query.trim();
    try {
      final response = await _public(
        '/api/public/search',
        query: {'q': normalized, 'limit': '$limit'},
      );
      final data = response['data'];
      final rows = data is List ? data : const [];
      return rows
          .whereType<Map>()
          .map(
            (row) =>
                ServicesSearchResult.fromJson(Map<String, dynamic>.from(row)),
          )
          .map(GuidelineContentSearchResult.fromContract)
          .toList(growable: false);
    } catch (_) {
      final cached = await _cache.list(
        type: _contentType,
        scope: _cacheScope,
        search: normalized,
        limit: 100,
      );
      if (cached.isEmpty) rethrow;
      final needle = normalized.toLowerCase();
      final results = <GuidelineContentSearchResult>[];
      for (final row in cached) {
        final publication = GuidelinePublication.fromJson(
          _map(row['publication']),
        );
        final sections = _maps(
          row['sections'],
        ).map(PublicationSection.fromJson).toList();
        final sectionTitles = {
          for (final item in sections) item.id: item.title,
        };
        for (final block in _maps(row['blocks']).map(GuidelineBlock.fromJson)) {
          final text = _blockText(block);
          final sectionTitle = sectionTitles[block.sectionId] ?? '';
          if (!text.toLowerCase().contains(needle) &&
              !sectionTitle.toLowerCase().contains(needle)) {
            continue;
          }
          results.add(
            GuidelineContentSearchResult(
              id: block.id,
              guidelineId: publication.id,
              sectionId: block.sectionId ?? '',
              blockId: block.id,
              contentType: _blockType(block),
              title: sectionTitle,
              snippet: text,
              sourceName: publication.sourceOrganization,
              sourceVersion: publication.version,
              pageStart: block.pageStart,
              pageEnd: block.pageEnd,
            ),
          );
          if (results.length >= limit) return results;
        }
      }
      return results;
    }
  }

  Future<GuidelineAsset?> _asset(String path) async {
    final response = await _public(path);
    final data = _data(response);
    return data.isEmpty ? null : _assetFromContract(data);
  }

  Future<Map<String, dynamic>> _structuredContent(String guidelineId) =>
      _public('/api/public/guidelines/$guidelineId/content');

  Future<Map<String, dynamic>> _public(
    String path, {
    Map<String, String>? query,
  }) => _api.requestJson(path, method: 'GET', query: query, includeAuth: false);
}

final class GuidelinePublicationVersionMismatch implements Exception {
  const GuidelinePublicationVersionMismatch();

  @override
  String toString() =>
      'The guideline publication changed while content was loading. Retry to load the current version.';
}

String _publicationIdentity(GuidelineManifest manifest) => [
  manifest.guidelineId,
  manifest.versionId,
  manifest.packageVersion,
  manifest.checksum,
].join(':');

void _verifyContentIdentity(
  Map<String, dynamic> content,
  GuidelineManifest manifest,
) {
  if (content['guideline_id']?.toString() != manifest.guidelineId ||
      content['version_id']?.toString() != manifest.versionId ||
      _integer(content['package_version'], -1) != manifest.packageVersion ||
      content['checksum']?.toString() != manifest.checksum) {
    throw const GuidelinePublicationVersionMismatch();
  }
}

Future<void> _bestEffortCache(Future<void> Function() write) async {
  try {
    await write();
  } catch (_) {
    // A cache migration or storage failure must not discard valid remote data.
  }
}

final class GuidelineContentSearchResult {
  const GuidelineContentSearchResult({
    required this.id,
    required this.guidelineId,
    required this.sectionId,
    required this.blockId,
    required this.contentType,
    required this.title,
    required this.snippet,
    required this.sourceName,
    required this.sourceVersion,
    this.pageStart,
    this.pageEnd,
  });

  factory GuidelineContentSearchResult.fromContract(ServicesSearchResult dto) =>
      GuidelineContentSearchResult(
        id: dto.id ?? '',
        guidelineId: dto.guidelineId ?? '',
        sectionId: dto.sectionId ?? '',
        blockId: dto.blockId ?? '',
        contentType: dto.contentType ?? 'section',
        title: dto.title ?? '',
        snippet: dto.snippet ?? '',
        sourceName: dto.sourceName ?? '',
        sourceVersion: dto.sourceVersion ?? '',
        pageStart: dto.pageStart,
        pageEnd: dto.pageEnd,
      );

  final String id;
  final String guidelineId;
  final String sectionId;
  final String blockId;
  final String contentType;
  final String title;
  final String snippet;
  final String sourceName;
  final String sourceVersion;
  final int? pageStart;
  final int? pageEnd;
}

GuidelinePublication _publicationFromContract(Map<String, dynamic> json) {
  final dto = ServicesPublicGuideline.fromJson(json);
  return GuidelinePublication(
    id: dto.id ?? '',
    slug: dto.slug ?? '',
    title: dto.title ?? '',
    description: dto.description ?? '',
    country: dto.country ?? '',
    sourceOrganization: dto.sourceOrg ?? '',
    programArea: dto.programArea ?? '',
    language: dto.language ?? '',
    publicationDate: dto.publicationDate ?? '',
    reviewDate: dto.reviewDate ?? '',
    version: dto.version ?? '',
    lastUpdated: DateTime.tryParse(dto.lastUpdated ?? ''),
    intendedPopulation: dto.intendedPopulation ?? '',
    healthcareLevel: dto.healthcareLevel ?? '',
    categories: _maps(json['categories'])
        .map(PublicationCategory.fromJson)
        .toList(growable: false),
  );
}

GuidelineManifest _manifestFromContract(Map<String, dynamic> json) {
  final dto = ServicesPublicGuidelineManifest.fromJson(json);
  final mode = switch (dto.recommendedMode) {
    'structured' => GuidelineReaderMode.structured,
    'partial' => GuidelineReaderMode.partial,
    _ => GuidelineReaderMode.originalDocument,
  };
  return GuidelineManifest(
    guidelineId: dto.guidelineId ?? '',
    versionId: dto.versionId ?? '',
    version: dto.version ?? '',
    schemaVersion: dto.schemaVersion ?? 1,
    packageVersion: dto.packageVersion ?? 1,
    extractionQuality: dto.extractionQuality ?? 'unreviewed',
    recommendedMode: mode,
    hasChapters: dto.hasChapters ?? false,
    hasKeyPoints: dto.hasKeyPoints ?? false,
    hasTables: dto.hasTables ?? false,
    hasFigures: dto.hasFigures ?? false,
    hasAlgorithms: dto.hasAlgorithms ?? false,
    hasOriginalPdf: dto.hasOriginalPdf ?? false,
    hasOfflinePackage: dto.hasOfflinePackage ?? false,
    sectionCount: dto.sectionCount ?? 0,
    reviewedSectionCount: dto.reviewedSectionCount ?? 0,
    leafSectionCount: dto.leafSectionCount ?? 0,
    reviewedLeafSectionCount: dto.reviewedLeafSectionCount ?? 0,
    emptyLeafSectionCount: dto.emptyLeafSectionCount ?? 0,
    blockCount: dto.blockCount ?? 0,
    reviewedParagraphCount: dto.reviewedParagraphCount ?? 0,
    tableCount: dto.tableCount ?? 0,
    figureCount: dto.figureCount ?? 0,
    algorithmCount: dto.algorithmCount ?? 0,
    checksum: dto.checksum ?? '',
    etag: dto.etag ?? '',
    generatedAt: DateTime.tryParse(dto.generatedAt ?? ''),
  );
}

PublicationSection _sectionFromContract(Map<String, dynamic> json) {
  final dto = ServicesPublicGuidelineSection.fromJson(json);
  return PublicationSection(
    id: dto.id ?? '',
    parentId: dto.parentId,
    title: dto.title ?? '',
    slug: dto.slug ?? '',
    level: dto.level ?? 1,
    pageStart: dto.pageStart,
    pageEnd: dto.pageEnd,
    sortOrder: dto.sortOrder ?? 0,
  );
}

GuidelineAsset _assetFromContract(Map<String, dynamic> json) {
  final dto = ServicesPublicGuidelineAssetLink.fromJson(json);
  final rawUrl = dto.url?.trim() ?? '';
  final parsed = Uri.tryParse(rawUrl);
  final resolvedUrl =
      parsed != null && !parsed.hasScheme && !parsed.hasAuthority
      ? Uri.parse(
          '${AppConfig.current.apiBaseUrl}/',
        ).resolveUri(parsed).toString()
      : rawUrl;
  return GuidelineAsset(
    id: dto.assetId,
    type: dto.type ?? '',
    mimeType: dto.mimeType ?? '',
    checksum: dto.checksum ?? '',
    sizeBytes: dto.sizeBytes ?? 0,
    originalFilename: dto.originalFilename ?? '',
    url: resolvedUrl,
    expiresAt: DateTime.tryParse(dto.expiresAt ?? ''),
  );
}

GuidelineBlock _block(ServicesPublicGuidelineBlock dto, GuidelineAsset? asset) {
  final id = dto.id ?? '';
  final sectionId = dto.sectionId;
  final sortOrder = dto.sortOrder ?? 0;
  final pageStart = dto.pageStart;
  final pageEnd = dto.pageEnd;
  final type = dto.type ?? 'unknown';
  final content = dto.content;
  switch (type) {
    case 'paragraph':
    case 'definition':
      return GuidelineBlock.paragraph(
        id: id,
        sectionId: sectionId,
        sortOrder: sortOrder,
        text: content['text']?.toString() ?? '',
        pageStart: pageStart,
        pageEnd: pageEnd,
      );
    case 'heading':
      return GuidelineBlock.heading(
        id: id,
        sectionId: sectionId,
        sortOrder: sortOrder,
        text: content['text']?.toString() ?? '',
        level: _integer(content['level'], 2),
        pageStart: pageStart,
        pageEnd: pageEnd,
      );
    case 'ordered_list':
    case 'unordered_list':
      final items = _strings(content['items']);
      return type == 'ordered_list'
          ? GuidelineBlock.orderedList(
              id: id,
              sectionId: sectionId,
              sortOrder: sortOrder,
              items: items,
              pageStart: pageStart,
              pageEnd: pageEnd,
            )
          : GuidelineBlock.unorderedList(
              id: id,
              sectionId: sectionId,
              sortOrder: sortOrder,
              items: items,
              pageStart: pageStart,
              pageEnd: pageEnd,
            );
    case 'table':
      return GuidelineBlock.table(
        id: id,
        sectionId: sectionId,
        sortOrder: sortOrder,
        payload: GuidelineTablePayload.fromJson(content),
        pageStart: pageStart,
        pageEnd: pageEnd,
      );
    case 'figure':
      return GuidelineBlock.figure(
        id: id,
        sectionId: sectionId,
        sortOrder: sortOrder,
        payload: GuidelineFigurePayload.fromJson(content),
        asset: asset,
        pageStart: pageStart,
        pageEnd: pageEnd,
      );
    case 'algorithm':
      return GuidelineBlock.algorithm(
        id: id,
        sectionId: sectionId,
        sortOrder: sortOrder,
        payload: GuidelineAlgorithmPayload.fromJson(content),
        pageStart: pageStart,
        pageEnd: pageEnd,
      );
    case 'reference':
      return GuidelineBlock.reference(
        id: id,
        sectionId: sectionId,
        sortOrder: sortOrder,
        citation: content['citation']?.toString() ?? '',
        url: content['url']?.toString() ?? '',
        pageStart: pageStart,
        pageEnd: pageEnd,
      );
    case 'page_break':
      return GuidelineBlock.pageBreak(
        id: id,
        sectionId: sectionId,
        sortOrder: sortOrder,
        page: _integer(content['page'], pageStart ?? 0),
        pageStart: pageStart,
        pageEnd: pageEnd,
      );
    case 'recommendation':
    case 'warning':
    case 'caution':
    case 'key_point':
    case 'contraindication':
    case 'dosage':
    case 'evidence':
    case 'procedure':
    case 'clinical_note':
    case 'referral_criteria':
    case 'algorithm_reference':
      return GuidelineBlock.callout(
        id: id,
        sectionId: sectionId,
        sortOrder: sortOrder,
        blockType: type,
        payload: GuidelineCalloutPayload.fromJson(content),
        pageStart: pageStart,
        pageEnd: pageEnd,
      );
    default:
      return GuidelineBlock.unknown(
        id: id,
        sectionId: sectionId,
        sortOrder: sortOrder,
        rawType: type,
        raw: dto.toJson(),
        pageStart: pageStart,
        pageEnd: pageEnd,
      );
  }
}

Map<String, dynamic> _data(Map<String, dynamic> response) =>
    _map(response['data']).isEmpty ? response : _map(response['data']);
Map<String, dynamic> _map(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : const <String, dynamic>{};
List<Map<String, dynamic>> _maps(Object? value) => value is List
    ? value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList()
    : const <Map<String, dynamic>>[];
List<String> _strings(Object? value) =>
    value is List ? value.map((item) => item.toString()).toList() : const [];
int _integer(Object? value, int fallback) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? fallback;

String _blockType(GuidelineBlock block) => switch (block) {
  TableGuidelineBlock() => 'table',
  AlgorithmGuidelineBlock() => 'algorithm',
  FigureGuidelineBlock() => 'figure',
  _ => 'section',
};

String _blockText(GuidelineBlock block) => switch (block) {
  ParagraphGuidelineBlock(:final text) => text,
  HeadingGuidelineBlock(:final text) => text,
  OrderedListGuidelineBlock(:final items) => items.join(' '),
  UnorderedListGuidelineBlock(:final items) => items.join(' '),
  TableGuidelineBlock(:final payload) => [
    payload.title,
    ...payload.columns,
    ...payload.rows.expand((row) => row),
  ].join(' '),
  FigureGuidelineBlock(:final payload) =>
    '${payload.caption} ${payload.alternativeText}',
  CalloutGuidelineBlock(:final payload) =>
    '${payload.title} ${payload.content}',
  AlgorithmGuidelineBlock(:final payload) => [
    payload.title,
    ...payload.nodes.map((item) => item.label),
  ].join(' '),
  ReferenceGuidelineBlock(:final citation) => citation,
  PageBreakGuidelineBlock(:final page) => 'Page $page',
  UnknownGuidelineBlock() => '',
};
