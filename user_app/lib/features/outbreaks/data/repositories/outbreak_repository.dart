import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:user_app/core/network/api_client.dart';
import 'package:user_app/core/network/contracts/generated/backend_contracts.dart';
import 'package:user_app/core/storage/local_cache_service.dart';
import 'package:user_app/features/outbreaks/data/models/outbreak_models.dart';

final class OutbreakQuery {
  const OutbreakQuery({
    this.search = '',
    this.status = '',
    this.disease = '',
    this.area = '',
    this.regionId = '',
    this.sort = 'last_update',
    this.order = 'desc',
  });

  final String search;
  final String status;
  final String disease;
  final String area;
  final String regionId;
  final String sort;
  final String order;

  Map<String, String> toQuery() => {
    if (search.trim().isNotEmpty) 'search': search.trim(),
    if (status.trim().isNotEmpty) 'status': status.trim(),
    if (disease.trim().isNotEmpty) 'disease': disease.trim(),
    if (area.trim().isNotEmpty) 'area': area.trim(),
    if (regionId.trim().isNotEmpty) 'region_id': regionId.trim(),
    'sort': sort,
    'order': order,
  };

  String get identity {
    final entries = toQuery().entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    return entries
        .map(
          (entry) =>
              '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}',
        )
        .join('&');
  }

  bool matches(PublicOutbreak item) {
    bool contains(String source, String value) =>
        value.trim().isEmpty ||
        source.toLowerCase().contains(value.trim().toLowerCase());
    return (status.trim().isEmpty || item.status == status.trim()) &&
        contains(
          '${item.title} ${item.summary} ${item.diseaseType} ${item.geographicArea} ${item.sourceOrganization} ${item.sourceReference}',
          search,
        ) &&
        contains(item.diseaseType, disease) &&
        contains(item.geographicArea, area);
  }
}

final class SituationReportQuery {
  const SituationReportQuery({
    this.search = '',
    this.outbreakId = '',
    this.sort = 'publication_date',
    this.order = 'desc',
  });

  final String search;
  final String outbreakId;
  final String sort;
  final String order;

  Map<String, String> toQuery() => {
    if (search.trim().isNotEmpty) 'search': search.trim(),
    if (outbreakId.trim().isNotEmpty) 'outbreak_id': outbreakId.trim(),
    'sort': sort,
    'order': order,
  };

  String get identity {
    final entries = toQuery().entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    return entries
        .map(
          (entry) =>
              '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}',
        )
        .join('&');
  }

  bool matches(PublicSituationReport item) {
    final needle = search.trim().toLowerCase();
    final searchable =
        '${item.title} ${item.summary} ${item.geographicArea} ${item.sourceOrganization} ${item.sourceReference} ${item.keyHighlights.join(' ')}'
            .toLowerCase();
    return (needle.isEmpty || searchable.contains(needle)) &&
        (outbreakId.trim().isEmpty || item.outbreakId == outbreakId.trim());
  }
}

final class OutbreakDocumentQuery {
  const OutbreakDocumentQuery({
    this.search = '',
    this.outbreakId = '',
    this.documentKind = '',
    this.authority = '',
    this.language = '',
    this.audience = '',
    this.mimeType = '',
    this.effectiveFrom,
    this.effectiveTo,
    this.sort = 'sort_order',
    this.order = 'asc',
  });

  final String search;
  final String outbreakId;
  final String documentKind;
  final String authority;
  final String language;
  final String audience;
  final String mimeType;
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;
  final String sort;
  final String order;

  Map<String, String> toQuery() => {
    if (search.trim().isNotEmpty) 'search': search.trim(),
    if (outbreakId.trim().isNotEmpty) 'outbreak_id': outbreakId.trim(),
    if (documentKind.trim().isNotEmpty) 'document_kind': documentKind.trim(),
    if (authority.trim().isNotEmpty) 'issuing_authority': authority.trim(),
    if (language.trim().isNotEmpty) 'language': language.trim(),
    if (audience.trim().isNotEmpty) 'audience': audience.trim(),
    if (mimeType.trim().isNotEmpty) 'mime_type': mimeType.trim(),
    if (effectiveFrom != null)
      'effective_from': effectiveFrom!.toUtc().toIso8601String(),
    if (effectiveTo != null)
      'effective_to': effectiveTo!.toUtc().toIso8601String(),
    'sort': sort,
    'order': order,
  };

  String get identity {
    final entries = toQuery().entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    return entries
        .map(
          (entry) =>
              '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}',
        )
        .join('&');
  }

  bool matches(PublicOutbreakDocument item) {
    final needle = search.trim().toLowerCase();
    final searchable =
        '${item.title} ${item.description} ${item.documentNumber} ${item.issuingAuthority} ${item.documentKind} ${item.audience} ${item.outbreakTitle} ${item.outbreakDisease} ${item.outbreakArea} ${item.searchSnippet}'
            .toLowerCase();
    return (needle.isEmpty || searchable.contains(needle)) &&
        (outbreakId.trim().isEmpty || item.outbreakId == outbreakId.trim()) &&
        (documentKind.trim().isEmpty ||
            item.documentKind == documentKind.trim()) &&
        (authority.trim().isEmpty ||
            item.issuingAuthority.toLowerCase() ==
                authority.trim().toLowerCase()) &&
        (language.trim().isEmpty ||
            item.language.toLowerCase() == language.trim().toLowerCase()) &&
        (audience.trim().isEmpty ||
            item.audience.toLowerCase() == audience.trim().toLowerCase()) &&
        (mimeType.trim().isEmpty ||
            item.mimeType.toLowerCase() == mimeType.trim().toLowerCase()) &&
        (effectiveFrom == null ||
            (item.effectiveDate != null &&
                !item.effectiveDate!.isBefore(effectiveFrom!))) &&
        (effectiveTo == null ||
            (item.effectiveDate != null &&
                !item.effectiveDate!.isAfter(effectiveTo!)));
  }
}

final class OutbreakRepository {
  OutbreakRepository(
    this._api,
    this._cache, {
    DateTime Function()? clock,
    Future<void> Function(String, Map<String, Object>)? recordMetric,
    Future<void> Function(Map<String, String>)? reconcileDocumentDownloads,
  }) : _clock = clock ?? DateTime.now,
       _recordMetric = recordMetric,
       _reconcileDocumentDownloads = reconcileDocumentDownloads;

  static const _scope = 'public';
  static const _outbreakType = 'public_outbreak';
  static const _outbreakSnapshotType = 'public_outbreak_snapshot';
  static const _detailType = 'public_outbreak_detail';
  static const _reportType = 'public_situation_report';
  static const _reportSnapshotType = 'public_situation_report_snapshot';
  static const _documentType = 'public_outbreak_document';
  static const _documentSnapshotType = 'public_outbreak_document_snapshot';
  static const _documentContentType = 'public_outbreak_document_content';
  static const _ttl = Duration(hours: 6);
  static const _offlineRetention = Duration(days: 7);
  static const _pageSize = 20;

  final BackendApiService _api;
  final LocalCacheService _cache;
  final DateTime Function() _clock;
  final Future<void> Function(String, Map<String, Object>)? _recordMetric;
  final Future<void> Function(Map<String, String>)? _reconcileDocumentDownloads;

  Future<PublicPage<PublicOutbreakDocument>> documents(
    String outbreakId, {
    int page = 1,
    int perPage = _pageSize,
    OutbreakDocumentQuery query = const OutbreakDocumentQuery(),
  }) async {
    final parent = _id(outbreakId);
    final safePage = page < 1 ? 1 : page;
    final safePerPage = perPage.clamp(1, 50);
    final snapshotId =
        '$parent|${query.identity}|page=$safePage|per_page=$safePerPage';
    try {
      final result = await _remoteDocumentPage(
        parent,
        safePage,
        safePerPage,
        query,
      );
      await _bestEffortCache(
        () => _cache.replaceSnapshot(
          type: _documentType,
          snapshotType: _documentSnapshotType,
          snapshotId: snapshotId,
          scope: _scope,
          ttl: _ttl,
          entities: result.items.map(_documentCacheInput),
          snapshotData: _pageMetadata(result),
        ),
      );
      return result;
    } catch (error, stackTrace) {
      if (!_canUseCache(error)) {
        _recordMalformed('outbreak-document-list', error, stackTrace);
        rethrow;
      }
      final cached = await _cachedDocumentPage(
        parent,
        snapshotId,
        safePage,
        safePerPage,
        query,
      );
      if (cached == null) {
        _observeCacheMiss('outbreak_document_list');
        rethrow;
      }
      _observeCacheUse('outbreak_document_list', cached.cache);
      return cached;
    }
  }

  /// Discovers documents across every public outbreak. Successful responses
  /// enrich the same cache used by nested outbreak screens, so global search
  /// remains useful offline without duplicating document records.
  Future<PublicPage<PublicOutbreakDocument>> searchDocuments({
    int page = 1,
    int perPage = 10,
    OutbreakDocumentQuery query = const OutbreakDocumentQuery(),
  }) async {
    final safePage = page < 1 ? 1 : page;
    final safePerPage = perPage.clamp(1, 50);
    try {
      final response = await _public(
        '/api/public/outbreak-documents',
        query: {
          'page': '$safePage',
          'per_page': '$safePerPage',
          ...query.toQuery(),
        },
      );
      final data = _data(response);
      final items = _maps(data['items']).map(_parseDocument).toList();
      await _bestEffortCache(
        () => _cache.putMany(
          type: _documentType,
          scope: _scope,
          ttl: _ttl,
          entities: items.map(_documentCacheInput),
        ),
      );
      return PublicPage(
        items: items,
        page: _integer(data['page'], safePage),
        perPage: _integer(data['per_page'], safePerPage),
        totalItems: _integer(data['total_items'], items.length),
        totalPages: _integer(data['total_pages'], items.isEmpty ? 0 : 1),
        cache: const PublicCacheMetadata.online(),
      );
    } catch (error) {
      if (!_canUseCache(error)) rethrow;
      return searchCachedDocuments(
        page: safePage,
        perPage: safePerPage,
        query: query,
      );
    }
  }

  /// Searches only published quick resources with a backend-validated target.
  /// Managed clinical documents remain in [searchDocuments] so external links
  /// can never be mistaken for reviewed in-app clinical content.
  Future<PublicPage<PublicOutbreakResource>> quickResources({
    int page = 1,
    int perPage = 10,
    String search = '',
    String targetType = '',
  }) async {
    final safePage = page < 1 ? 1 : page;
    final safePerPage = perPage.clamp(1, 50);
    final response = await _public(
      '/api/public/outbreak-resources',
      query: {
        'page': '$safePage',
        'per_page': '$safePerPage',
        if (search.trim().isNotEmpty) 'search': search.trim(),
        if (targetType.trim().isNotEmpty) 'target_type': targetType.trim(),
      },
    );
    final data = _data(response);
    final items = _maps(
      data['items'],
    ).map(PublicOutbreakResource.fromJson).toList(growable: false);
    return PublicPage(
      items: items,
      page: _integer(data['page'], safePage),
      perPage: _integer(data['per_page'], safePerPage),
      totalItems: _integer(data['total_items'], items.length),
      totalPages: _integer(data['total_pages'], items.isEmpty ? 0 : 1),
      cache: const PublicCacheMetadata.online(),
    );
  }

  /// Searches approved public outbreak documents already held in the local
  /// cache. Cache-only fields are never deserialized into the public model or
  /// sent back to the API.
  Future<PublicPage<PublicOutbreakDocument>> searchCachedDocuments({
    int page = 1,
    int perPage = 10,
    OutbreakDocumentQuery query = const OutbreakDocumentQuery(),
  }) async {
    final safePage = page < 1 ? 1 : page;
    final safePerPage = perPage.clamp(1, 50);
    final now = _clock().toUtc();
    final cached = await _cache.list(
      type: _documentType,
      scope: _scope,
      limit: 1000,
    );
    final ranked = <({PublicOutbreakDocument item, double score})>[];
    for (final data in cached) {
      final verifiedAt = DateTime.tryParse(
        data['_cache_verified_at']?.toString() ?? '',
      );
      if (verifiedAt == null ||
          now.difference(verifiedAt.toUtc()) > _offlineRetention) {
        continue;
      }
      final item = PublicOutbreakDocument.fromJson(data);
      if (item.expiresAt != null && !item.expiresAt!.isAfter(now)) continue;
      if (!_matchesCachedDocument(data, item, query)) continue;
      ranked.add((
        item: item,
        score: _cachedDocumentScore(data, item, query.search),
      ));
    }
    ranked.sort((left, right) {
      final relevance = right.score.compareTo(left.score);
      if (relevance != 0) return relevance;
      final title = left.item.title.toLowerCase().compareTo(
        right.item.title.toLowerCase(),
      );
      return title != 0 ? title : left.item.id.compareTo(right.item.id);
    });
    final offset = (safePage - 1) * safePerPage;
    final items = offset >= ranked.length
        ? const <PublicOutbreakDocument>[]
        : ranked
              .skip(offset)
              .take(safePerPage)
              .map((entry) => entry.item)
              .toList(growable: false);
    return PublicPage(
      items: items,
      page: safePage,
      perPage: safePerPage,
      totalItems: ranked.length,
      totalPages: ranked.isEmpty ? 0 : (ranked.length / safePerPage).ceil(),
      cache: PublicCacheMetadata(
        cachedAt: now,
        lastVerifiedAt: null,
        isStale: true,
        isWithdrawn: false,
        isOffline: true,
      ),
    );
  }

  Future<PublicContent<OutbreakDocumentContent>> documentContent(
    String documentId,
  ) async {
    final id = _id(documentId);
    try {
      final value = OutbreakDocumentContent.fromJson(
        _data(await _public('/api/public/outbreak-documents/$id/content')),
      );
      await _bestEffortCache(
        () => _cache.put(
          type: _documentContentType,
          id: id,
          scope: _scope,
          ttl: _ttl,
          data: value.toJson(),
          searchableText: value.content,
          version: value.checksumSha256,
        ),
      );
      await _bestEffortCache(() => _enrichDocumentSearchCache(value));
      return PublicContent(
        value: value,
        cache: const PublicCacheMetadata.online(),
      );
    } catch (error) {
      if (error is BackendApiException && error.statusCode == 404) {
        await _bestEffortCache(() async {
          await _cache.tombstone(type: _documentType, id: id, scope: _scope);
          await _cache.tombstone(
            type: _documentContentType,
            id: id,
            scope: _scope,
          );
        });
        throw const PublicContentUnavailableException(
          'This document was withdrawn, expired, or is no longer public.',
          isWithdrawn: true,
        );
      }
      if (!_canUseCache(error)) rethrow;
      final cached = await _cache.getEntry(
        type: _documentContentType,
        id: id,
        scope: _scope,
      );
      if (cached == null || cached.isDeleted) rethrow;
      final value = OutbreakDocumentContent.fromJson(cached.data);
      final now = _clock().toUtc();
      if ((value.expiresAt != null && !value.expiresAt!.isAfter(now)) ||
          now.difference(cached.cachedAt.toUtc()) > _offlineRetention) {
        await _bestEffortCache(() async {
          await _cache.tombstone(
            type: _documentContentType,
            id: id,
            scope: _scope,
          );
          await _cache.tombstone(type: _documentType, id: id, scope: _scope);
        });
        throw const PublicContentUnavailableException(
          'This cached document can no longer be verified for clinical use.',
          isWithdrawn: true,
        );
      }
      return PublicContent(
        value: value,
        cache: _cacheMetadata(cached, maxAge: _ttl),
      );
    }
  }

  Future<PublicPage<PublicOutbreakDocument>> refreshDocuments(
    String outbreakId, {
    OutbreakDocumentQuery query = const OutbreakDocumentQuery(),
    int perPage = _pageSize,
  }) async {
    final parent = _id(outbreakId);
    final safePerPage = perPage.clamp(1, 50);
    final first = await _remoteDocumentPage(parent, 1, safePerPage, query);
    final all = <PublicOutbreakDocument>[...first.items];
    for (var page = 2; page <= first.totalPages; page++) {
      all.addAll(
        (await _remoteDocumentPage(parent, page, safePerPage, query)).items,
      );
    }
    await _cache.replaceSnapshot(
      type: _documentType,
      snapshotType: _documentSnapshotType,
      snapshotId: '$parent|${query.identity}|full',
      scope: _scope,
      ttl: _ttl,
      entities: all.map(_documentCacheInput),
      reconcileMissing: false,
    );
    if (query.identity == const OutbreakDocumentQuery().identity) {
      await _reconcileDocumentMetadata(
        outbreakId: parent,
        activeIds: all.map((document) => document.id).toSet(),
      );
      await _reconcileDocumentContent(
        outbreakId: parent,
        activeIds: all.map((document) => document.id).toSet(),
      );
      await _reconcileDocumentDownloads?.call({
        for (final document in all) document.id: document.version,
      });
    }
    return first;
  }

  Future<PublicContent<PublicOutbreakDocument>> document(
    String outbreakId,
    String documentId,
  ) async {
    final parent = _id(outbreakId);
    final id = _id(documentId);
    try {
      final response = await _public(
        '/api/public/outbreaks/$parent/documents/$id',
      );
      final value = _parseDocument(_data(response));
      final cacheInput = _documentCacheInput(value);
      await _bestEffortCache(
        () => _cache.put(
          type: _documentType,
          id: id,
          scope: _scope,
          ttl: _ttl,
          data: cacheInput.data,
          searchableText: cacheInput.searchableText,
          remoteUpdatedAt: cacheInput.remoteUpdatedAt,
        ),
      );
      return PublicContent(
        value: value,
        cache: const PublicCacheMetadata.online(),
      );
    } catch (error, stackTrace) {
      if (error is BackendApiException && error.statusCode == 404) {
        await _bestEffortCache(() async {
          await _cache.tombstone(type: _documentType, id: id, scope: _scope);
          await _cache.tombstone(
            type: _documentContentType,
            id: id,
            scope: _scope,
          );
        });
        throw const PublicContentUnavailableException(
          'This document was withdrawn, expired, or is no longer public.',
          isWithdrawn: true,
        );
      }
      if (!_canUseCache(error)) {
        _recordMalformed('outbreak-document-detail', error, stackTrace);
        rethrow;
      }
      final cached = await _cache.getEntry(
        type: _documentType,
        id: id,
        scope: _scope,
      );
      if (cached == null || cached.isDeleted) rethrow;
      final value = PublicOutbreakDocument.fromJson(cached.data);
      final now = _clock().toUtc();
      if ((value.expiresAt != null && !value.expiresAt!.isAfter(now)) ||
          now.difference(cached.cachedAt.toUtc()) > _offlineRetention) {
        await _bestEffortCache(() async {
          await _cache.tombstone(type: _documentType, id: id, scope: _scope);
          await _cache.tombstone(
            type: _documentContentType,
            id: id,
            scope: _scope,
          );
        });
        throw const PublicContentUnavailableException(
          'This cached document can no longer be verified for clinical use.',
          isWithdrawn: true,
        );
      }
      return PublicContent(
        value: value,
        cache: _cacheMetadata(cached, maxAge: _ttl),
      );
    }
  }

  Future<PublicPage<PublicOutbreak>> outbreaks({
    int page = 1,
    int perPage = _pageSize,
    OutbreakQuery query = const OutbreakQuery(),
  }) async {
    final safePage = page < 1 ? 1 : page;
    final safePerPage = perPage.clamp(1, 50);
    final snapshotId = '${query.identity}|page=$safePage|per_page=$safePerPage';
    try {
      final result = await _remoteOutbreakPage(safePage, safePerPage, query);
      await _bestEffortCache(
        () => _cache.replaceSnapshot(
          type: _outbreakType,
          snapshotType: _outbreakSnapshotType,
          snapshotId: snapshotId,
          scope: _scope,
          ttl: _ttl,
          entities: result.items.map(_outbreakCacheInput),
          snapshotData: _pageMetadata(result),
        ),
      );
      return result;
    } catch (error, stackTrace) {
      if (!_canUseCache(error)) {
        _recordMalformed('outbreak-list', error, stackTrace);
        rethrow;
      }
      final cached = await _cachedOutbreakPage(
        snapshotId,
        safePage,
        safePerPage,
        query,
      );
      if (cached == null) {
        _observeCacheMiss('outbreak_list');
        rethrow;
      }
      _observeCacheUse('outbreak_list', cached.cache);
      return cached;
    }
  }

  /// Fetches every bounded page before atomically reconciling the canonical
  /// unfiltered snapshot. Explicit refreshes use this path.
  Future<PublicPage<PublicOutbreak>> refreshOutbreaks({
    OutbreakQuery query = const OutbreakQuery(),
    int perPage = _pageSize,
  }) async {
    final safePerPage = perPage.clamp(1, 50);
    final first = await _remoteOutbreakPage(1, safePerPage, query);
    final all = <PublicOutbreak>[...first.items];
    for (var page = 2; page <= first.totalPages; page++) {
      all.addAll((await _remoteOutbreakPage(page, safePerPage, query)).items);
    }
    await _cache.replaceSnapshot(
      type: _outbreakType,
      snapshotType: _outbreakSnapshotType,
      snapshotId: '${query.identity}|full',
      scope: _scope,
      ttl: _ttl,
      entities: all.map(_outbreakCacheInput),
      reconcileMissing: query.identity == const OutbreakQuery().identity,
    );
    await _cache.replaceSnapshot(
      type: _outbreakType,
      snapshotType: _outbreakSnapshotType,
      snapshotId: '${query.identity}|page=1|per_page=$safePerPage',
      scope: _scope,
      ttl: _ttl,
      entities: first.items.map(_outbreakCacheInput),
      snapshotData: _pageMetadata(first),
    );
    return first;
  }

  Future<PublicContent<PublicOutbreakDetail>> outbreak(String id) async {
    final normalized = _id(id);
    CachedEntityValue? cached;
    try {
      cached = await _cache.getEntry(
        type: _detailType,
        id: normalized,
        scope: _scope,
      );
    } catch (_) {}

    PublicOutbreak outbreak;
    try {
      final response = await _public('/api/public/outbreaks/$normalized');
      outbreak = _parseOutbreak(_data(response));
    } catch (error, stackTrace) {
      if (error is BackendApiException && error.statusCode == 404) {
        await _bestEffortCache(() async {
          await _cache.tombstone(
            type: _outbreakType,
            id: normalized,
            scope: _scope,
          );
          await _cache.tombstone(
            type: _detailType,
            id: normalized,
            scope: _scope,
          );
        });
        throw const PublicContentUnavailableException(
          'This outbreak is no longer publicly available.',
          isWithdrawn: true,
        );
      }
      if (!_canUseCache(error) || cached == null) {
        if (!_canUseCache(error)) {
          _recordMalformed('outbreak-detail', error, stackTrace);
        }
        rethrow;
      }
      final detail = _detailFromCache(cached.data);
      return PublicContent(
        value: detail,
        cache: _cacheMetadata(
          cached,
          lastVerifiedAt: detail.outbreak.lastVerifiedAt,
          maxAge: _freshnessFor(detail.outbreak),
        ),
      );
    }

    final cachedDetail = cached == null ? null : _detailFromCache(cached.data);
    var updates = cachedDetail?.updates ?? const <PublicOutbreakUpdate>[];
    var resources = cachedDetail?.resources ?? const <PublicOutbreakResource>[];
    var documents = cachedDetail?.documents ?? const <PublicOutbreakDocument>[];
    var reports = cachedDetail?.reports ?? const <PublicSituationReport>[];
    final failures = <String>[];

    try {
      updates = await _allUpdates(normalized);
    } catch (error, stackTrace) {
      if (!_canUseCache(error)) {
        _recordMalformed('outbreak-updates', error, stackTrace);
        rethrow;
      }
      failures.add('updates');
    }
    try {
      resources = await _allResources(normalized);
    } catch (error, stackTrace) {
      if (!_canUseCache(error)) {
        _recordMalformed('outbreak-resources', error, stackTrace);
        rethrow;
      }
      failures.add('resources');
    }
    try {
      documents = await _allDocuments(normalized);
      await _bestEffortCache(
        () => _cache.replaceSnapshot(
          type: _documentType,
          snapshotType: _documentSnapshotType,
          snapshotId:
              '$normalized|${const OutbreakDocumentQuery().identity}|full',
          scope: _scope,
          ttl: _ttl,
          entities: documents.map(_documentCacheInput),
          reconcileMissing: false,
        ),
      );
      await _bestEffortCache(
        () => _reconcileDocumentMetadata(
          outbreakId: normalized,
          activeIds: documents.map((document) => document.id).toSet(),
        ),
      );
      await _bestEffortCache(
        () => _reconcileDocumentContent(
          outbreakId: normalized,
          activeIds: documents.map((document) => document.id).toSet(),
        ),
      );
      await _bestEffortCache(() async {
        await _reconcileDocumentDownloads?.call({
          for (final document in documents) document.id: document.version,
        });
      });
    } catch (error, stackTrace) {
      if (!_canUseCache(error)) {
        _recordMalformed('outbreak-documents', error, stackTrace);
        rethrow;
      }
      failures.add('documents');
    }
    try {
      reports = await _allReports(
        SituationReportQuery(outbreakId: normalized),
        maxPages: 5,
      );
    } catch (error, stackTrace) {
      if (!_canUseCache(error)) {
        _recordMalformed('outbreak-reports', error, stackTrace);
        rethrow;
      }
      failures.add('reports');
    }

    final detail = PublicOutbreakDetail(
      outbreak: outbreak,
      updates: updates,
      resources: resources,
      documents: documents,
      reports: reports,
    );
    await _bestEffortCache(
      () => _cache.put(
        type: _detailType,
        id: normalized,
        scope: _scope,
        ttl: _freshnessFor(outbreak),
        data: _detailToJson(detail),
        searchableText:
            '${outbreak.title} ${outbreak.summary} ${outbreak.diseaseType} ${outbreak.geographicArea} ${outbreak.sourceOrganization} ${outbreak.sourceReference}',
        remoteUpdatedAt: outbreak.lastUpdate,
      ),
    );
    return PublicContent(
      value: detail,
      cache: PublicCacheMetadata.online(
        lastVerifiedAt: outbreak.lastVerifiedAt,
      ),
      partialFailures: failures,
    );
  }

  Future<PublicPage<PublicSituationReport>> reports({
    int page = 1,
    int perPage = _pageSize,
    SituationReportQuery query = const SituationReportQuery(),
  }) async {
    final safePage = page < 1 ? 1 : page;
    final safePerPage = perPage.clamp(1, 50);
    final snapshotId = '${query.identity}|page=$safePage|per_page=$safePerPage';
    try {
      final result = await _remoteReportPage(safePage, safePerPage, query);
      await _bestEffortCache(
        () => _cache.replaceSnapshot(
          type: _reportType,
          snapshotType: _reportSnapshotType,
          snapshotId: snapshotId,
          scope: _scope,
          ttl: _ttl,
          entities: result.items.map(_reportCacheInput),
          snapshotData: _pageMetadata(result),
        ),
      );
      return result;
    } catch (error, stackTrace) {
      if (!_canUseCache(error)) {
        _recordMalformed('report-list', error, stackTrace);
        rethrow;
      }
      final cached = await _cachedReportPage(
        snapshotId,
        safePage,
        safePerPage,
        query,
      );
      if (cached == null) {
        _observeCacheMiss('situation_report_list');
        rethrow;
      }
      _observeCacheUse('situation_report_list', cached.cache);
      return cached;
    }
  }

  Future<PublicPage<PublicSituationReport>> refreshReports({
    SituationReportQuery query = const SituationReportQuery(),
    int perPage = _pageSize,
  }) async {
    final safePerPage = perPage.clamp(1, 50);
    final first = await _remoteReportPage(1, safePerPage, query);
    final all = <PublicSituationReport>[...first.items];
    for (var page = 2; page <= first.totalPages; page++) {
      all.addAll((await _remoteReportPage(page, safePerPage, query)).items);
    }
    await _cache.replaceSnapshot(
      type: _reportType,
      snapshotType: _reportSnapshotType,
      snapshotId: '${query.identity}|full',
      scope: _scope,
      ttl: _ttl,
      entities: all.map(_reportCacheInput),
      reconcileMissing: query.identity == const SituationReportQuery().identity,
    );
    await _cache.replaceSnapshot(
      type: _reportType,
      snapshotType: _reportSnapshotType,
      snapshotId: '${query.identity}|page=1|per_page=$safePerPage',
      scope: _scope,
      ttl: _ttl,
      entities: first.items.map(_reportCacheInput),
      snapshotData: _pageMetadata(first),
    );
    return first;
  }

  Future<PublicContent<PublicSituationReport>> report(String id) async {
    final normalized = _id(id);
    try {
      final response = await _public(
        '/api/public/situation-reports/$normalized',
      );
      final value = _parseReport(_data(response));
      await _bestEffortCache(
        () => _cache.put(
          type: _reportType,
          id: normalized,
          scope: _scope,
          ttl: _ttl,
          data: value.toJson(),
          searchableText:
              '${value.title} ${value.summary} ${value.geographicArea} ${value.sourceOrganization}',
          remoteUpdatedAt: value.publicationDate,
        ),
      );
      return PublicContent(
        value: value,
        cache: PublicCacheMetadata.online(lastVerifiedAt: value.lastVerifiedAt),
      );
    } catch (error, stackTrace) {
      if (error is BackendApiException && error.statusCode == 404) {
        await _bestEffortCache(
          () => _cache.tombstone(
            type: _reportType,
            id: normalized,
            scope: _scope,
          ),
        );
        throw const PublicContentUnavailableException(
          'This situation report is no longer publicly available.',
          isWithdrawn: true,
        );
      }
      if (!_canUseCache(error)) {
        _recordMalformed('report-detail', error, stackTrace);
        rethrow;
      }
      final cached = await _cache.getEntry(
        type: _reportType,
        id: normalized,
        scope: _scope,
      );
      if (cached == null || cached.isDeleted) rethrow;
      final value = PublicSituationReport.fromJson(cached.data);
      return PublicContent(
        value: value,
        cache: _cacheMetadata(
          cached,
          lastVerifiedAt: value.lastVerifiedAt,
          maxAge: _ttl,
        ),
      );
    }
  }

  Future<PublicPage<PublicOutbreak>> _remoteOutbreakPage(
    int page,
    int perPage,
    OutbreakQuery query,
  ) async {
    final response = await _public(
      '/api/public/outbreaks',
      query: {'page': '$page', 'per_page': '$perPage', ...query.toQuery()},
    );
    final data = _data(response);
    final items = _maps(
      data['items'],
    ).map(_parseOutbreak).toList(growable: false);
    return PublicPage(
      items: items,
      page: _integer(data['page'], page),
      perPage: _integer(data['per_page'], perPage),
      totalItems: _integer(data['total_items'], items.length),
      totalPages: _integer(data['total_pages'], items.isEmpty ? 0 : 1),
      cache: const PublicCacheMetadata.online(),
    );
  }

  Future<PublicPage<PublicSituationReport>> _remoteReportPage(
    int page,
    int perPage,
    SituationReportQuery query,
  ) async {
    final response = await _public(
      '/api/public/situation-reports',
      query: {'page': '$page', 'per_page': '$perPage', ...query.toQuery()},
    );
    final data = _data(response);
    final items = _maps(
      data['items'],
    ).map(_parseReport).toList(growable: false);
    return PublicPage(
      items: items,
      page: _integer(data['page'], page),
      perPage: _integer(data['per_page'], perPage),
      totalItems: _integer(data['total_items'], items.length),
      totalPages: _integer(data['total_pages'], items.isEmpty ? 0 : 1),
      cache: const PublicCacheMetadata.online(),
    );
  }

  Future<PublicPage<PublicOutbreakDocument>> _remoteDocumentPage(
    String outbreakId,
    int page,
    int perPage,
    OutbreakDocumentQuery query,
  ) async {
    final response = await _public(
      '/api/public/outbreaks/$outbreakId/documents',
      query: {'page': '$page', 'per_page': '$perPage', ...query.toQuery()},
    );
    final data = _data(response);
    final items = _maps(
      data['items'],
    ).map(_parseDocument).toList(growable: false);
    return PublicPage(
      items: items,
      page: _integer(data['page'], page),
      perPage: _integer(data['per_page'], perPage),
      totalItems: _integer(data['total_items'], items.length),
      totalPages: _integer(data['total_pages'], items.isEmpty ? 0 : 1),
      cache: const PublicCacheMetadata.online(),
    );
  }

  Future<List<PublicOutbreakUpdate>> _allUpdates(String id) => _allChildPages(
    '/api/public/outbreaks/$id/updates',
    (map) => PublicOutbreakUpdate.fromJson(
      ServicesPublicOutbreakUpdate.fromJson(map).toJson(),
    ),
  );

  Future<List<PublicOutbreakResource>> _allResources(String id) =>
      _allChildPages(
        '/api/public/outbreaks/$id/resources',
        (map) => PublicOutbreakResource.fromJson(
          ServicesPublicOutbreakResource.fromJson(map).toJson(),
        ),
      );

  Future<List<PublicOutbreakDocument>> _allDocuments(String id) =>
      _allChildPages(
        '/api/public/outbreaks/$id/documents',
        (map) => PublicOutbreakDocument.fromJson(
          ServicesPublicOutbreakDocument.fromJson(map).toJson(),
        ),
      );

  Future<List<T>> _allChildPages<T>(
    String path,
    T Function(Map<String, dynamic>) parse,
  ) async {
    final result = <T>[];
    var page = 1;
    var totalPages = 1;
    do {
      final data = _data(
        await _public(path, query: {'page': '$page', 'per_page': '20'}),
      );
      result.addAll(_maps(data['items']).map(parse));
      totalPages = _integer(data['total_pages'], 1).clamp(0, 5);
      page++;
    } while (page <= totalPages);
    return result;
  }

  Future<List<PublicSituationReport>> _allReports(
    SituationReportQuery query, {
    int maxPages = 5,
  }) async {
    final first = await _remoteReportPage(1, _pageSize, query);
    final result = <PublicSituationReport>[...first.items];
    final pages = first.totalPages.clamp(0, maxPages);
    for (var page = 2; page <= pages; page++) {
      result.addAll((await _remoteReportPage(page, _pageSize, query)).items);
    }
    return result;
  }

  Future<PublicPage<PublicOutbreak>?> _cachedOutbreakPage(
    String snapshotId,
    int page,
    int perPage,
    OutbreakQuery query,
  ) async {
    var exact = true;
    var snapshot = await _cache.getEntry(
      type: _outbreakSnapshotType,
      id: snapshotId,
      scope: _scope,
    );
    if (snapshot == null) {
      exact = false;
      snapshot = await _cache.getEntry(
        type: _outbreakSnapshotType,
        id: '${const OutbreakQuery().identity}|full',
        scope: _scope,
      );
      snapshot ??= await _cache.getEntry(
        type: _outbreakSnapshotType,
        id: '${const OutbreakQuery().identity}|page=1|per_page=$perPage',
        scope: _scope,
      );
    }
    final entries = snapshot == null
        ? <CachedEntityValue>[]
        : await _entriesForSnapshot(_outbreakType, snapshot);
    final filtered = entries
        .map((entry) => _parseOutbreak(entry.data))
        .where(query.matches)
        .toList(growable: false);
    if (snapshot == null) return null;
    final offset = exact ? 0 : (page - 1) * perPage;
    final values = offset >= filtered.length
        ? const <PublicOutbreak>[]
        : filtered.skip(offset).take(perPage).toList(growable: false);
    final cachedAt = snapshot.cachedAt;
    final totalItems = exact
        ? _integer(snapshot.data['total_items'], filtered.length)
        : filtered.length;
    return PublicPage(
      items: values,
      page: page,
      perPage: perPage,
      totalItems: totalItems,
      totalPages: exact
          ? _integer(snapshot.data['total_pages'], values.isEmpty ? 0 : 1)
          : (totalItems == 0 ? 0 : (totalItems / perPage).ceil()),
      cache: PublicCacheMetadata(
        cachedAt: cachedAt,
        lastVerifiedAt: _latest(values.map((item) => item.lastVerifiedAt)),
        isStale: values.any(
          (item) =>
              _clock().toUtc().difference(cachedAt.toUtc()) >
              _freshnessFor(item),
        ),
        isWithdrawn: false,
        isOffline: true,
      ),
    );
  }

  Future<PublicPage<PublicSituationReport>?> _cachedReportPage(
    String snapshotId,
    int page,
    int perPage,
    SituationReportQuery query,
  ) async {
    var exact = true;
    var snapshot = await _cache.getEntry(
      type: _reportSnapshotType,
      id: snapshotId,
      scope: _scope,
    );
    if (snapshot == null) {
      exact = false;
      snapshot = await _cache.getEntry(
        type: _reportSnapshotType,
        id: '${const SituationReportQuery().identity}|full',
        scope: _scope,
      );
      snapshot ??= await _cache.getEntry(
        type: _reportSnapshotType,
        id: '${const SituationReportQuery().identity}|page=1|per_page=$perPage',
        scope: _scope,
      );
    }
    final entries = snapshot == null
        ? <CachedEntityValue>[]
        : await _entriesForSnapshot(_reportType, snapshot);
    final filtered = entries
        .map((entry) => _parseReport(entry.data))
        .where(query.matches)
        .toList(growable: false);
    if (snapshot == null) return null;
    final offset = exact ? 0 : (page - 1) * perPage;
    final values = offset >= filtered.length
        ? const <PublicSituationReport>[]
        : filtered.skip(offset).take(perPage).toList(growable: false);
    final cachedAt = snapshot.cachedAt;
    final totalItems = exact
        ? _integer(snapshot.data['total_items'], filtered.length)
        : filtered.length;
    return PublicPage(
      items: values,
      page: page,
      perPage: perPage,
      totalItems: totalItems,
      totalPages: exact
          ? _integer(snapshot.data['total_pages'], values.isEmpty ? 0 : 1)
          : (totalItems == 0 ? 0 : (totalItems / perPage).ceil()),
      cache: PublicCacheMetadata(
        cachedAt: cachedAt,
        lastVerifiedAt: _latest(values.map((item) => item.lastVerifiedAt)),
        isStale: _clock().toUtc().difference(cachedAt.toUtc()) > _ttl,
        isWithdrawn: false,
        isOffline: true,
      ),
    );
  }

  Future<PublicPage<PublicOutbreakDocument>?> _cachedDocumentPage(
    String outbreakId,
    String snapshotId,
    int page,
    int perPage,
    OutbreakDocumentQuery query,
  ) async {
    var exact = true;
    var snapshot = await _cache.getEntry(
      type: _documentSnapshotType,
      id: snapshotId,
      scope: _scope,
    );
    if (snapshot == null) {
      exact = false;
      snapshot = await _cache.getEntry(
        type: _documentSnapshotType,
        id: '$outbreakId|${const OutbreakDocumentQuery().identity}|full',
        scope: _scope,
      );
    }
    if (snapshot == null) return null;
    final entries = await _entriesForSnapshot(_documentType, snapshot);
    final filtered = entries
        .map((entry) => PublicOutbreakDocument.fromJson(entry.data))
        .where((item) => item.outbreakId == outbreakId && query.matches(item))
        .toList(growable: false);
    final offset = exact ? 0 : (page - 1) * perPage;
    final values = offset >= filtered.length
        ? const <PublicOutbreakDocument>[]
        : filtered.skip(offset).take(perPage).toList(growable: false);
    final totalItems = exact
        ? _integer(snapshot.data['total_items'], filtered.length)
        : filtered.length;
    return PublicPage(
      items: values,
      page: page,
      perPage: perPage,
      totalItems: totalItems,
      totalPages: exact
          ? _integer(snapshot.data['total_pages'], values.isEmpty ? 0 : 1)
          : (totalItems == 0 ? 0 : (totalItems / perPage).ceil()),
      cache: PublicCacheMetadata(
        cachedAt: snapshot.cachedAt,
        lastVerifiedAt: null,
        isStale: _clock().toUtc().difference(snapshot.cachedAt.toUtc()) > _ttl,
        isWithdrawn: false,
        isOffline: true,
      ),
    );
  }

  Future<List<CachedEntityValue>> _entriesForSnapshot(
    String type,
    CachedEntityValue snapshot,
  ) async {
    final ids = (snapshot.data['ids'] as List? ?? const []).map(
      (value) => value.toString(),
    );
    final result = <CachedEntityValue>[];
    for (final id in ids) {
      final value = await _cache.getEntry(type: type, id: id, scope: _scope);
      if (value != null && !value.isDeleted) result.add(value);
    }
    return result;
  }

  CachedEntityInput _outbreakCacheInput(
    PublicOutbreak item,
  ) => CachedEntityInput(
    id: item.id,
    data: item.toJson(),
    searchableText:
        '${item.title} ${item.summary} ${item.diseaseType} ${item.geographicArea} ${item.sourceOrganization} ${item.sourceReference}',
    remoteUpdatedAt: item.lastUpdate,
  );

  CachedEntityInput _reportCacheInput(
    PublicSituationReport item,
  ) => CachedEntityInput(
    id: item.id,
    data: item.toJson(),
    searchableText:
        '${item.title} ${item.summary} ${item.geographicArea} ${item.sourceOrganization} ${item.sourceReference} ${item.keyHighlights.join(' ')}',
    remoteUpdatedAt: item.publicationDate,
  );

  CachedEntityInput _documentCacheInput(PublicOutbreakDocument item) =>
      CachedEntityInput(
        id: item.id,
        data: {
          ...item.toJson(),
          '_cache_verified_at': _clock().toUtc().toIso8601String(),
          '_cache_metadata_text': _documentSearchText(item),
        },
        searchableText: _documentSearchText(item),
        remoteUpdatedAt: item.publishedAt,
      );

  String _documentSearchText(
    PublicOutbreakDocument item,
  ) => _normalizeSearchText(
    '${item.title} ${item.description} ${item.documentNumber} ${item.issuingAuthority} ${item.documentKind} ${item.audience} ${item.outbreakTitle} ${item.outbreakDisease} ${item.outbreakArea} ${item.searchSnippet} ${item.matchingHeading}',
  );

  Future<void> _enrichDocumentSearchCache(
    OutbreakDocumentContent content,
  ) async {
    final existing = await _cache.getEntry(
      type: _documentType,
      id: content.documentId,
      scope: _scope,
    );
    if (existing == null || existing.isDeleted) return;
    final headings = content.sections
        .map((section) => section.heading.trim())
        .where((heading) => heading.isNotEmpty)
        .toList(growable: false);
    final body = _normalizeSearchText(
      '${content.content} ${content.sections.map((section) => section.text).join(' ')}',
    );
    final data = <String, dynamic>{
      ...existing.data,
      '_cache_verified_at': _clock().toUtc().toIso8601String(),
      '_cache_headings': headings,
      '_cache_body_text': body,
    };
    await _cache.put(
      type: _documentType,
      id: content.documentId,
      scope: _scope,
      ttl: _ttl,
      data: data,
      searchableText:
          '${data['_cache_metadata_text'] ?? ''} ${headings.join(' ')} $body',
      version: content.checksumSha256,
      remoteUpdatedAt: content.publishedAt,
    );
  }

  Future<void> _reconcileDocumentContent({
    required String outbreakId,
    required Set<String> activeIds,
  }) async {
    final cached = await _cache.list(
      type: _documentContentType,
      scope: _scope,
      limit: 1000,
    );
    for (final data in cached) {
      final content = OutbreakDocumentContent.fromJson(data);
      if (content.outbreakId == outbreakId &&
          !activeIds.contains(content.documentId)) {
        await _cache.tombstone(
          type: _documentContentType,
          id: content.documentId,
          scope: _scope,
        );
      }
    }
  }

  Future<void> _reconcileDocumentMetadata({
    required String outbreakId,
    required Set<String> activeIds,
  }) async {
    final cached = await _cache.list(
      type: _documentType,
      scope: _scope,
      limit: 1000,
    );
    for (final data in cached) {
      final document = PublicOutbreakDocument.fromJson(data);
      if (document.outbreakId == outbreakId &&
          !activeIds.contains(document.id)) {
        await _cache.tombstone(
          type: _documentType,
          id: document.id,
          scope: _scope,
        );
      }
    }
  }

  bool _matchesCachedDocument(
    Map<String, dynamic> data,
    PublicOutbreakDocument item,
    OutbreakDocumentQuery query,
  ) {
    final withoutSearch = OutbreakDocumentQuery(
      outbreakId: query.outbreakId,
      documentKind: query.documentKind,
      authority: query.authority,
      language: query.language,
      audience: query.audience,
      mimeType: query.mimeType,
      effectiveFrom: query.effectiveFrom,
      effectiveTo: query.effectiveTo,
      sort: query.sort,
      order: query.order,
    );
    if (!withoutSearch.matches(item)) return false;
    final needle = _normalizeSearchText(query.search);
    if (needle.isEmpty) return true;
    return _cachedSearchText(data, item).contains(needle);
  }

  double _cachedDocumentScore(
    Map<String, dynamic> data,
    PublicOutbreakDocument item,
    String search,
  ) {
    final needle = _normalizeSearchText(search);
    if (needle.isEmpty) return item.searchRelevanceScore;
    final title = _normalizeSearchText(item.title);
    final headings = _normalizeSearchText(
      (data['_cache_headings'] as List? ?? const <Object>[]).join(' '),
    );
    final metadata = _normalizeSearchText(
      data['_cache_metadata_text']?.toString() ?? _documentSearchText(item),
    );
    final body = _normalizeSearchText(
      data['_cache_body_text']?.toString() ?? '',
    );
    var score = item.searchRelevanceScore;
    if (title == needle) {
      score += 400;
    } else if (title.startsWith(needle)) {
      score += 300;
    } else if (title.contains(needle)) {
      score += 250;
    }
    if (headings.contains(needle)) score += 175;
    if (metadata.contains(needle)) score += 100;
    if (body.contains(needle)) score += 50;
    return score;
  }

  String _cachedSearchText(
    Map<String, dynamic> data,
    PublicOutbreakDocument item,
  ) => _normalizeSearchText(
    '${data['_cache_metadata_text'] ?? _documentSearchText(item)} ${(data['_cache_headings'] as List? ?? const <Object>[]).join(' ')} ${data['_cache_body_text'] ?? ''}',
  );

  String _normalizeSearchText(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');

  PublicOutbreak _parseOutbreak(Map<String, dynamic> value) =>
      PublicOutbreak.fromJson(
        _normalizeMetrics(ServicesPublicOutbreak.fromJson(value).toJson()),
      );

  PublicSituationReport _parseReport(Map<String, dynamic> value) =>
      PublicSituationReport.fromJson(
        _normalizeMetrics(
          ServicesPublicSituationReport.fromJson(value).toJson(),
        ),
      );

  PublicOutbreakDocument _parseDocument(Map<String, dynamic> value) =>
      PublicOutbreakDocument.fromJson(value);

  PublicOutbreakDetail _detailFromCache(Map<String, dynamic> cached) =>
      PublicOutbreakDetail(
        outbreak: PublicOutbreak.fromJson(_map(cached['outbreak'])),
        updates: _maps(
          cached['updates'],
        ).map(PublicOutbreakUpdate.fromJson).toList(),
        resources: _maps(
          cached['resources'],
        ).map(PublicOutbreakResource.fromJson).toList(),
        documents: _maps(
          cached['documents'],
        ).map(PublicOutbreakDocument.fromJson).toList(),
        reports: _maps(
          cached['reports'],
        ).map(PublicSituationReport.fromJson).toList(),
      );

  Map<String, dynamic> _detailToJson(PublicOutbreakDetail value) => {
    'outbreak': value.outbreak.toJson(),
    'updates': value.updates.map((item) => item.toJson()).toList(),
    'resources': value.resources.map((item) => item.toJson()).toList(),
    'documents': value.documents.map((item) => item.toJson()).toList(),
    'reports': value.reports.map((item) => item.toJson()).toList(),
  };

  PublicCacheMetadata _cacheMetadata(
    CachedEntityValue entry, {
    required Duration maxAge,
    DateTime? lastVerifiedAt,
  }) => PublicCacheMetadata(
    cachedAt: entry.cachedAt,
    lastVerifiedAt: lastVerifiedAt,
    isStale: _clock().toUtc().difference(entry.cachedAt.toUtc()) > maxAge,
    isWithdrawn: entry.isDeleted,
    isOffline: true,
  );

  Duration _freshnessFor(PublicOutbreak value) {
    if (value.status == 'active' && value.visualTone == 'critical') {
      return const Duration(minutes: 30);
    }
    if (value.status == 'active') return const Duration(hours: 1);
    if (value.status == 'monitoring') return const Duration(hours: 2);
    return _ttl;
  }

  bool _canUseCache(Object error) =>
      error is BackendApiException &&
      (error.statusCode == 0 ||
          error.statusCode == 408 ||
          error.statusCode == 429 ||
          error.statusCode >= 500);

  void _recordMalformed(String route, Object error, StackTrace stackTrace) {
    debugPrint(
      '[outbreak_payload_invalid] route=$route error_type=${error.runtimeType}',
    );
  }

  Future<Map<String, dynamic>> _public(
    String path, {
    Map<String, String>? query,
  }) => _api.requestJson(path, method: 'GET', includeAuth: false, query: query);

  String _id(String value) {
    final id = value.trim();
    if (id.isEmpty) throw ArgumentError.value(value, 'id', 'is required');
    return Uri.encodeComponent(id);
  }

  Map<String, dynamic> _data(Map<String, dynamic> response) =>
      response['data'] is Map ? _map(response['data']) : response;
  Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
  List<Map<String, dynamic>> _maps(dynamic value) =>
      (value as List? ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
  int _integer(dynamic value, int fallback) =>
      (value as num?)?.toInt() ?? fallback;
  DateTime? _latest(Iterable<DateTime?> values) {
    DateTime? latest;
    for (final value in values.whereType<DateTime>()) {
      if (latest == null || value.isAfter(latest)) latest = value;
    }
    return latest;
  }

  void _observeCacheUse(String contentType, PublicCacheMetadata cache) {
    final recorder = _recordMetric;
    if (recorder == null || !cache.isOffline) return;
    unawaited(
      recorder('outbreak_cache_access', <String, Object>{
        'content_type': contentType,
        'result': 'hit',
        'stale': cache.isStale ? 1 : 0,
      }),
    );
    unawaited(
      recorder('outbreak_offline_content_used', <String, Object>{
        'content_type': contentType,
        'stale': cache.isStale ? 1 : 0,
      }),
    );
  }

  void _observeCacheMiss(String contentType) {
    final metric = _recordMetric?.call(
      'outbreak_cache_access',
      <String, Object>{
        'content_type': contentType,
        'result': 'miss',
        'stale': 0,
      },
    );
    if (metric != null) unawaited(metric);
  }

  Map<String, dynamic> _pageMetadata<T>(PublicPage<T> page) => {
    'page': page.page,
    'per_page': page.perPage,
    'total_items': page.totalItems,
    'total_pages': page.totalPages,
  };
}

Map<String, dynamic> _normalizeMetrics(Map<String, dynamic> value) {
  final normalized = Map<String, dynamic>.from(value);
  final metrics = normalized['metrics'];
  if (metrics is List) {
    normalized['metrics'] = metrics
        .whereType<Map>()
        .map((metric) {
          final row = Map<String, dynamic>.from(metric);
          row['value'] = row['value']?.toString() ?? '';
          return row;
        })
        .toList(growable: false);
  }
  return normalized;
}

Future<void> _bestEffortCache(Future<void> Function() write) async {
  try {
    await write();
  } catch (_) {
    // Cache failures do not discard a valid remote response.
  }
}
