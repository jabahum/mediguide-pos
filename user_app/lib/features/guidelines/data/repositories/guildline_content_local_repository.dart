import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:user_app/core/storage/local_cache_service.dart';

import 'package:user_app/features/guidelines/data/models/guideline.dart';
import 'package:user_app/features/guidelines/data/models/guideline_category.dart';
import 'package:user_app/features/guidelines/data/models/guideline_tag.dart';
import 'package:user_app/features/guidelines/data/models/guideline_index.dart';

final guidelineContentLocalRepositoryProvider =
    Provider<GuidelineContentLocalRepository>((ref) {
      return GuidelineContentLocalRepository(
        ref.watch(localCacheServiceProvider),
      );
    });

final class GuidelineContentLocalRepository {
  GuidelineContentLocalRepository(this._localCacheService);

  final LocalCacheService _localCacheService;

  static const String _scope = 'public';

  static const String _guidelineType = 'medical_guideline';
  static const String _categoryType = 'guideline_category';
  static const String _tagType = 'guideline_tag';
  static const String _indexType = 'guideline_index';

  // =========================================================
  // GUIDELINES
  // =========================================================

  Future<void> saveGuideline(Guideline guideline) async {
    await _localCacheService.put(
      type: _guidelineType,
      id: guideline.id,
      scope: _scope,
      data: guideline.toJson(),
      searchableText: _guidelineSearchableText(guideline),
      metadata: _guidelineMetadata(guideline),
      remoteUpdatedAt: guideline.updatedDate,
    );
  }

  Future<void> saveGuidelines(Iterable<Guideline> guidelines) async {
    if (guidelines.isEmpty) return;

    await _localCacheService.putMany(
      type: _guidelineType,
      scope: _scope,
      entities: guidelines.map((guideline) {
        return CachedEntityInput(
          id: guideline.id,
          data: guideline.toJson(),
          searchableText: _guidelineSearchableText(guideline),
          metadata: _guidelineMetadata(guideline),
          remoteUpdatedAt: guideline.updatedDate,
        );
      }),
    );
  }

  Future<Guideline?> getGuideline(String id) async {
    final normalizedId = id.trim();

    if (normalizedId.isEmpty) {
      return null;
    }

    final data = await _localCacheService.get(
      type: _guidelineType,
      id: normalizedId,
      scope: _scope,
    );

    if (data == null) {
      return null;
    }

    try {
      return Guideline.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<List<Guideline>> getGuidelines({
    int page = 1,
    int perPage = 30,
    String search = '',
    String status = '',
    List<String> categoryIds = const [],
    List<String> tagIds = const [],
    String indexId = '',
    String priority = '',
    String healthcareLevel = '',
    String targetPopulation = '',
    bool? published,
  }) async {
    final safePage = page < 1 ? 1 : page;
    final safePerPage = perPage < 1 ? 30 : perPage;

    //
    // We intentionally fetch a wider candidate set because LocalCacheService
    // currently only performs generic text search at storage level.
    //
    // Once metadata-level SQL filtering is added, this can paginate directly.
    //
    final rows = await _localCacheService.list(
      type: _guidelineType,
      scope: _scope,
      search: search.trim(),
      limit: safePerPage * 10,
      offset: 0,
    );

    final guidelines = <Guideline>[];

    for (final row in rows) {
      try {
        final guideline = Guideline.fromJson(row);

        if (!_matchesGuidelineFilters(
          guideline,
          status: status,
          categoryIds: categoryIds,
          tagIds: tagIds,
          indexId: indexId,
          priority: priority,
          healthcareLevel: healthcareLevel,
          targetPopulation: targetPopulation,
          published: published,
        )) {
          continue;
        }

        guidelines.add(guideline);
      } catch (_) {
        // Skip malformed local cache rows.
      }
    }

    guidelines.sort(_sortGuidelines);

    return _paginate(guidelines, page: safePage, perPage: safePerPage);
  }

  // =========================================================
  // CATEGORIES
  // =========================================================

  Future<void> saveCategory(GuidelineCategory category) async {
    await _localCacheService.put(
      type: _categoryType,
      id: category.id,
      scope: _scope,
      data: category.toJson(),
      searchableText: _categorySearchableText(category),
      metadata: _categoryMetadata(category),
    );
  }

  Future<void> saveCategories(Iterable<GuidelineCategory> categories) async {
    if (categories.isEmpty) return;

    await _localCacheService.putMany(
      type: _categoryType,
      scope: _scope,
      entities: categories.map((category) {
        return CachedEntityInput(
          id: category.id,
          data: category.toJson(),
          searchableText: _categorySearchableText(category),
          metadata: _categoryMetadata(category),
        );
      }),
    );
  }

  Future<GuidelineCategory?> getCategory(String id) async {
    final normalizedId = id.trim();

    if (normalizedId.isEmpty) {
      return null;
    }

    final data = await _localCacheService.get(
      type: _categoryType,
      id: normalizedId,
      scope: _scope,
    );

    if (data == null) {
      return null;
    }

    try {
      return GuidelineCategory.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<List<GuidelineCategory>> getCategories({
    int page = 1,
    int perPage = 100,
    String search = '',
    String status = '',
    String parentId = '',
    bool rootOnly = false,
  }) async {
    final safePage = page < 1 ? 1 : page;
    final safePerPage = perPage < 1 ? 100 : perPage;

    final rows = await _localCacheService.list(
      type: _categoryType,
      scope: _scope,
      search: search.trim(),
      limit: safePerPage * 10,
      offset: 0,
    );

    final categories = <GuidelineCategory>[];

    for (final row in rows) {
      try {
        final category = GuidelineCategory.fromJson(row);

        if (!_matchesCategoryFilters(
          category,
          status: status,
          parentId: parentId,
          rootOnly: rootOnly,
        )) {
          continue;
        }

        categories.add(category);
      } catch (_) {
        // Ignore malformed cache rows.
      }
    }

    categories.sort(_sortCategories);

    return _paginate(categories, page: safePage, perPage: safePerPage);
  }

  // =========================================================
  // TAGS
  // =========================================================

  Future<void> saveTag(GuidelineTag tag) async {
    await _localCacheService.put(
      type: _tagType,
      id: tag.id,
      scope: _scope,
      data: tag.toJson(),
      searchableText: _tagSearchableText(tag),
      metadata: _tagMetadata(tag),
    );
  }

  Future<void> saveTags(Iterable<GuidelineTag> tags) async {
    if (tags.isEmpty) return;

    await _localCacheService.putMany(
      type: _tagType,
      scope: _scope,
      entities: tags.map((tag) {
        return CachedEntityInput(
          id: tag.id,
          data: tag.toJson(),
          searchableText: _tagSearchableText(tag),
          metadata: _tagMetadata(tag),
        );
      }),
    );
  }

  Future<GuidelineTag?> getTag(String id) async {
    final normalizedId = id.trim();

    if (normalizedId.isEmpty) {
      return null;
    }

    final data = await _localCacheService.get(
      type: _tagType,
      id: normalizedId,
      scope: _scope,
    );

    if (data == null) {
      return null;
    }

    try {
      return GuidelineTag.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<List<GuidelineTag>> getTags({
    int page = 1,
    int perPage = 100,
    String search = '',
  }) async {
    final safePage = page < 1 ? 1 : page;
    final safePerPage = perPage < 1 ? 100 : perPage;

    final rows = await _localCacheService.list(
      type: _tagType,
      scope: _scope,
      search: search.trim(),
      limit: safePerPage,
      offset: (safePage - 1) * safePerPage,
    );

    final tags = <GuidelineTag>[];

    for (final row in rows) {
      try {
        tags.add(GuidelineTag.fromJson(row));
      } catch (_) {
        // Skip malformed records.
      }
    }

    tags.sort(_sortTags);

    return tags;
  }

  // =========================================================
  // INDEX
  // =========================================================

  Future<void> saveIndexItem(GuidelineIndex item) async {
    await _localCacheService.put(
      type: _indexType,
      id: item.id,
      scope: _scope,
      data: item.toJson(),
      searchableText: _indexSearchableText(item),
      metadata: _indexMetadata(item),
    );
  }

  Future<void> saveIndexItems(Iterable<GuidelineIndex> items) async {
    if (items.isEmpty) return;

    await _localCacheService.putMany(
      type: _indexType,
      scope: _scope,
      entities: items.map((item) {
        return CachedEntityInput(
          id: item.id,
          data: item.toJson(),
          searchableText: _indexSearchableText(item),
          metadata: _indexMetadata(item),
        );
      }),
    );
  }

  Future<GuidelineIndex?> getIndexItem(String id) async {
    final normalizedId = id.trim();

    if (normalizedId.isEmpty) {
      return null;
    }

    final data = await _localCacheService.get(
      type: _indexType,
      id: normalizedId,
      scope: _scope,
    );

    if (data == null) {
      return null;
    }

    try {
      return GuidelineIndex.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<List<GuidelineIndex>> getIndexItems({
    int page = 1,
    int perPage = 100,
    String search = '',
    String parentId = '',
    int? level,
  }) async {
    final safePage = page < 1 ? 1 : page;
    final safePerPage = perPage < 1 ? 100 : perPage;

    final rows = await _localCacheService.list(
      type: _indexType,
      scope: _scope,
      search: search.trim(),
      limit: safePerPage * 10,
      offset: 0,
    );

    final items = <GuidelineIndex>[];

    for (final row in rows) {
      try {
        final item = GuidelineIndex.fromJson(row);

        if (!_matchesIndexFilters(item, parentId: parentId, level: level)) {
          continue;
        }

        items.add(item);
      } catch (_) {
        // Ignore malformed cache rows.
      }
    }

    items.sort(_sortIndexItems);

    return _paginate(items, page: safePage, perPage: safePerPage);
  }

  // =========================================================
  // CACHE STATE
  // =========================================================

  Future<bool> hasCachedGuidelines() {
    return _localCacheService.hasData(type: _guidelineType, scope: _scope);
  }

  Future<bool> hasCachedCategories() {
    return _localCacheService.hasData(type: _categoryType, scope: _scope);
  }

  Future<bool> hasCachedTags() {
    return _localCacheService.hasData(type: _tagType, scope: _scope);
  }

  Future<bool> hasCachedIndex() {
    return _localCacheService.hasData(type: _indexType, scope: _scope);
  }

  Future<bool> isGuidelineCacheStale({
    Duration maxAge = const Duration(hours: 24),
  }) {
    return _localCacheService.isStale(
      type: _guidelineType,
      scope: _scope,
      maxAge: maxAge,
    );
  }

  Future<bool> isReferenceCacheStale({
    Duration maxAge = const Duration(days: 7),
  }) async {
    final results = await Future.wait([
      _localCacheService.isStale(
        type: _categoryType,
        scope: _scope,
        maxAge: maxAge,
      ),
      _localCacheService.isStale(type: _tagType, scope: _scope, maxAge: maxAge),
      _localCacheService.isStale(
        type: _indexType,
        scope: _scope,
        maxAge: maxAge,
      ),
    ]);

    return results.any((value) => value);
  }

  // =========================================================
  // CLEAR
  // =========================================================

  Future<void> clearGuidelines() {
    return _localCacheService.clearType(type: _guidelineType, scope: _scope);
  }

  Future<void> clearCategories() {
    return _localCacheService.clearType(type: _categoryType, scope: _scope);
  }

  Future<void> clearTags() {
    return _localCacheService.clearType(type: _tagType, scope: _scope);
  }

  Future<void> clearIndex() {
    return _localCacheService.clearType(type: _indexType, scope: _scope);
  }

  Future<void> clear() async {
    await Future.wait([
      clearGuidelines(),
      clearCategories(),
      clearTags(),
      clearIndex(),
    ]);
  }

  // =========================================================
  // WATCH
  // =========================================================

  Stream<List<Guideline>> watchGuidelines() {
    return _localCacheService.watch(type: _guidelineType, scope: _scope).map((
      rows,
    ) {
      final result = <Guideline>[];

      for (final row in rows) {
        try {
          result.add(Guideline.fromJson(row));
        } catch (_) {}
      }

      result.sort(_sortGuidelines);

      return List<Guideline>.unmodifiable(result);
    });
  }

  Stream<List<GuidelineCategory>> watchCategories() {
    return _localCacheService.watch(type: _categoryType, scope: _scope).map((
      rows,
    ) {
      final result = <GuidelineCategory>[];

      for (final row in rows) {
        try {
          result.add(GuidelineCategory.fromJson(row));
        } catch (_) {}
      }

      result.sort(_sortCategories);

      return List<GuidelineCategory>.unmodifiable(result);
    });
  }

  Stream<List<GuidelineTag>> watchTags() {
    return _localCacheService.watch(type: _tagType, scope: _scope).map((rows) {
      final result = <GuidelineTag>[];

      for (final row in rows) {
        try {
          result.add(GuidelineTag.fromJson(row));
        } catch (_) {}
      }

      result.sort(_sortTags);

      return List<GuidelineTag>.unmodifiable(result);
    });
  }

  Stream<List<GuidelineIndex>> watchIndex() {
    return _localCacheService.watch(type: _indexType, scope: _scope).map((
      rows,
    ) {
      final result = <GuidelineIndex>[];

      for (final row in rows) {
        try {
          result.add(GuidelineIndex.fromJson(row));
        } catch (_) {}
      }

      result.sort(_sortIndexItems);

      return List<GuidelineIndex>.unmodifiable(result);
    });
  }

  // =========================================================
  // GUIDELINE FILTERS
  // =========================================================

  bool _matchesGuidelineFilters(
    Guideline guideline, {
    required String status,
    required List<String> categoryIds,
    required List<String> tagIds,
    required String indexId,
    required String priority,
    required String healthcareLevel,
    required String targetPopulation,
    required bool? published,
  }) {
    final normalizedStatus = status.trim().toLowerCase();

    if (normalizedStatus.isNotEmpty &&
        _guidelineStatus(guideline) != normalizedStatus) {
      return false;
    }

    if (published != null && _guidelinePublished(guideline) != published) {
      return false;
    }

    final normalizedPriority = priority.trim().toLowerCase();

    if (normalizedPriority.isNotEmpty &&
        guideline.priority.trim().toLowerCase() != normalizedPriority) {
      return false;
    }

    final normalizedLevel = healthcareLevel.trim().toLowerCase();

    if (normalizedLevel.isNotEmpty) {
      final levels = _guidelineHealthcareLevels(guideline);

      if (levels.every(
        (value) => !value.toLowerCase().contains(normalizedLevel),
      )) {
        return false;
      }
    }

    final normalizedPopulation = targetPopulation.trim().toLowerCase();

    if (normalizedPopulation.isNotEmpty) {
      final populations = _guidelineTargetPopulations(guideline);

      if (populations.every(
        (value) => !value.toLowerCase().contains(normalizedPopulation),
      )) {
        return false;
      }
    }

    if (categoryIds.isNotEmpty) {
      final guidelineCategoryIds = guideline.categories
          .map((category) => category.id)
          .where((id) => id.trim().isNotEmpty)
          .toSet();

      if (!categoryIds.any(guidelineCategoryIds.contains)) {
        return false;
      }
    }

    if (tagIds.isNotEmpty) {
      final guidelineTagIds = _guidelineTagIds(guideline);

      if (!tagIds.any(guidelineTagIds.contains)) {
        return false;
      }
    }

    final normalizedIndexId = indexId.trim();

    if (normalizedIndexId.isNotEmpty) {
      final ids = _guidelineIndexIds(guideline);

      if (!ids.contains(normalizedIndexId)) {
        return false;
      }
    }

    return true;
  }

  // =========================================================
  // CATEGORY FILTERS
  // =========================================================

  bool _matchesCategoryFilters(
    GuidelineCategory category, {
    required String status,
    required String parentId,
    required bool rootOnly,
  }) {
    final normalizedStatus = status.trim().toLowerCase();

    if (normalizedStatus.isNotEmpty &&
        _categoryStatus(category) != normalizedStatus) {
      return false;
    }

    final normalizedParentId = parentId.trim();

    if (normalizedParentId.isNotEmpty &&
        _categoryParentId(category) != normalizedParentId) {
      return false;
    }

    if (rootOnly && _categoryParentId(category).isNotEmpty) {
      return false;
    }

    return true;
  }

  // =========================================================
  // INDEX FILTERS
  // =========================================================

  bool _matchesIndexFilters(
    GuidelineIndex item, {
    required String parentId,
    required int? level,
  }) {
    final normalizedParentId = parentId.trim();

    if (normalizedParentId.isNotEmpty &&
        (item.parentId ?? '').trim() != normalizedParentId) {
      return false;
    }

    if (level != null && item.level != level) {
      return false;
    }

    return true;
  }

  // =========================================================
  // SEARCHABLE TEXT
  // =========================================================

  String _guidelineSearchableText(Guideline guideline) {
    return [
          guideline.conditionName,
          guideline.icd10Code,
          guideline.definition,
          guideline.causes,
          guideline.clinicalFeatures,
          guideline.differentialDiagnosis,
          guideline.generalManagement,
          guideline.medicationPrimary,
          guideline.medicationSecondary,
          guideline.monitoringRequirements,
          guideline.preventionMeasures,
          guideline.specialNotes,
          guideline.priority,
          ...guideline.categories.map((category) => category.name),
          ..._guidelineTagNames(guideline),
        ]
        .where((value) => value.trim().isNotEmpty)
        .map(_stripHtml)
        .join(' ')
        .toLowerCase();
  }

  String _categorySearchableText(GuidelineCategory category) {
    return [
      category.displayName,
      category.name,
    ].where((value) => value.trim().isNotEmpty).join(' ').toLowerCase();
  }

  String _tagSearchableText(GuidelineTag tag) {
    return [
      tag.displayName,
      tag.name,
    ].where((value) => value.trim().isNotEmpty).join(' ').toLowerCase();
  }

  String _indexSearchableText(GuidelineIndex item) {
    return [
      item.title,
      item.description,
    ].where((value) => value.trim().isNotEmpty).join(' ').toLowerCase();
  }

  // =========================================================
  // METADATA
  // =========================================================

  Map<String, dynamic> _guidelineMetadata(Guideline guideline) {
    return {
      'status': _guidelineStatus(guideline),
      'published': _guidelinePublished(guideline),
      'priority': guideline.priority,
      'categories': guideline.categories
          .map((category) => category.id)
          .where((id) => id.trim().isNotEmpty)
          .toList(growable: false),
      'tags': _guidelineTagIds(guideline),
      'indexIds': _guidelineIndexIds(guideline),
      'healthcareLevels': _guidelineHealthcareLevels(guideline),
      'targetPopulations': _guidelineTargetPopulations(guideline),
      'updatedAt': guideline.updatedDate?.toIso8601String(),
    };
  }

  Map<String, dynamic> _categoryMetadata(GuidelineCategory category) {
    return {
      'parentId': _categoryParentId(category),
      'status': _categoryStatus(category),
    };
  }

  Map<String, dynamic> _tagMetadata(GuidelineTag tag) {
    return {'name': tag.displayName};
  }

  Map<String, dynamic> _indexMetadata(GuidelineIndex item) {
    return {
      'parentId': item.parentId,
      'level': item.level,
      'order': item.order,
      'hasChildren': item.hasChildren,
    };
  }

  // =========================================================
  // MODEL HELPERS
  // =========================================================
  //
  // These helpers isolate fields that may differ slightly between
  // your generated model and backend JSON.
  // =========================================================

  String _guidelineStatus(Guideline guideline) {
    final json = guideline.toJson();
    return (json['status'] ?? '').toString().trim().toLowerCase();
  }

  bool _guidelinePublished(Guideline guideline) {
    final json = guideline.toJson();

    final value = json['is_published'] ?? json['published'];

    if (value is bool) return value;

    if (value is num) {
      return value != 0;
    }

    return value?.toString().toLowerCase() == 'true';
  }

  List<String> _guidelineTagIds(Guideline guideline) {
    final json = guideline.toJson();

    final raw = json['tags'];

    if (raw is! List) {
      return const [];
    }

    return raw
        .whereType<Map>()
        .map((value) => (value['id'] ?? '').toString().trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  List<String> _guidelineTagNames(Guideline guideline) {
    final json = guideline.toJson();

    final raw = json['tags'];

    if (raw is! List) {
      return const [];
    }

    return raw
        .whereType<Map>()
        .map(
          (value) =>
              (value['name'] ?? value['display_name'] ?? '').toString().trim(),
        )
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  List<String> _guidelineIndexIds(Guideline guideline) {
    final json = guideline.toJson();

    final result = <String>{};

    final parentId = (json['parent_id'] ?? '').toString().trim();

    if (parentId.isNotEmpty) {
      result.add(parentId);
    }

    final indexId = (json['index_id'] ?? '').toString().trim();

    if (indexId.isNotEmpty) {
      result.add(indexId);
    }

    final indexItems = json['index_items'];

    if (indexItems is List) {
      for (final item in indexItems.whereType<Map>()) {
        final id = (item['id'] ?? '').toString().trim();

        if (id.isNotEmpty) {
          result.add(id);
        }
      }
    }

    return result.toList(growable: false);
  }

  List<String> _guidelineHealthcareLevels(Guideline guideline) {
    final json = guideline.toJson();

    return _stringValues(json['healthcare_level'] ?? json['healthcare_levels']);
  }

  List<String> _guidelineTargetPopulations(Guideline guideline) {
    final json = guideline.toJson();

    return _stringValues(
      json['target_population'] ?? json['target_populations'],
    );
  }

  String _categoryParentId(GuidelineCategory category) {
    final json = category.toJson();

    return (json['parent_id'] ?? json['parentId'] ?? '').toString().trim();
  }

  String _categoryStatus(GuidelineCategory category) {
    final json = category.toJson();

    return (json['status'] ?? '').toString().trim().toLowerCase();
  }

  List<String> _stringValues(dynamic raw) {
    if (raw == null) {
      return const [];
    }

    if (raw is List) {
      return raw
          .map((value) => value.toString().trim())
          .where((value) => value.isNotEmpty)
          .toList(growable: false);
    }

    if (raw is String) {
      return raw
          .split(',')
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList(growable: false);
    }

    return [
      raw.toString().trim(),
    ].where((value) => value.isNotEmpty).toList(growable: false);
  }

  // =========================================================
  // SORTING
  // =========================================================

  int _sortGuidelines(Guideline a, Guideline b) {
    final aUpdated = a.updatedDate ?? DateTime.fromMillisecondsSinceEpoch(0);

    final bUpdated = b.updatedDate ?? DateTime.fromMillisecondsSinceEpoch(0);

    final updatedCompare = bUpdated.compareTo(aUpdated);

    if (updatedCompare != 0) {
      return updatedCompare;
    }

    return a.conditionName.toLowerCase().compareTo(
      b.conditionName.toLowerCase(),
    );
  }

  int _sortCategories(GuidelineCategory a, GuidelineCategory b) {
    final aJson = a.toJson();
    final bJson = b.toJson();

    final aOrder = (aJson['sort_order'] as num?)?.toInt() ?? 0;

    final bOrder = (bJson['sort_order'] as num?)?.toInt() ?? 0;

    final orderCompare = aOrder.compareTo(bOrder);

    if (orderCompare != 0) {
      return orderCompare;
    }

    return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
  }

  int _sortTags(GuidelineTag a, GuidelineTag b) {
    return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
  }

  int _sortIndexItems(GuidelineIndex a, GuidelineIndex b) {
    final levelCompare = a.level.compareTo(b.level);

    if (levelCompare != 0) {
      return levelCompare;
    }

    final orderCompare = a.order.compareTo(b.order);

    if (orderCompare != 0) {
      return orderCompare;
    }

    return a.title.toLowerCase().compareTo(b.title.toLowerCase());
  }

  // =========================================================
  // PAGINATION
  // =========================================================

  List<T> _paginate<T>(
    List<T> items, {
    required int page,
    required int perPage,
  }) {
    final start = (page - 1) * perPage;

    if (start >= items.length) {
      return const [];
    }

    final end = (start + perPage).clamp(0, items.length);

    return items.sublist(start, end);
  }

  // =========================================================
  // HTML
  // =========================================================

  String _stripHtml(String value) {
    return value
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
