import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_app/core/storage/local_cache_service.dart';

import 'package:user_app/shared/models/models.dart';

final helpContentLocalRepositoryProvider = Provider<HelpContentLocalRepository>(
  (ref) {
    return HelpContentLocalRepository(ref.watch(localCacheServiceProvider));
  },
);

final class HelpContentLocalRepository {
  HelpContentLocalRepository(this._localCacheService);

  final LocalCacheService _localCacheService;

  static const String _scope = 'public';

  static const String _faqType = 'faq';
  static const String _documentationType = 'documentation';

  // =========================================================
  // FAQ - SAVE
  // =========================================================

  Future<void> saveFAQ(FAQ faq) async {
    await _localCacheService.put(
      type: _faqType,
      id: faq.id,
      scope: _scope,
      data: faq.toJson(),
      searchableText: _faqSearchableText(faq),
      metadata: _faqMetadata(faq),
      remoteUpdatedAt: _updatedAt(faq.toJson()),
    );
  }

  Future<void> saveFAQs(Iterable<FAQ> faqs) async {
    if (faqs.isEmpty) return;

    await _localCacheService.putMany(
      type: _faqType,
      scope: _scope,
      entities: faqs.map(
        (faq) => CachedEntityInput(
          id: faq.id,
          data: faq.toJson(),
          searchableText: _faqSearchableText(faq),
          metadata: _faqMetadata(faq),
          remoteUpdatedAt: _updatedAt(faq.toJson()),
        ),
      ),
    );
  }

  // =========================================================
  // FAQ - GET
  // =========================================================

  Future<FAQ?> getFAQ(String id) async {
    final normalized = id.trim();

    if (normalized.isEmpty) {
      return null;
    }

    final row = await _localCacheService.get(
      type: _faqType,
      id: normalized,
      scope: _scope,
    );

    if (row == null) {
      return null;
    }

    try {
      return FAQ.fromJson(row);
    } catch (_) {
      return null;
    }
  }

  Future<List<FAQ>> getFAQs({
    int page = 1,
    int perPage = 10,
    String search = '',
    bool? featured,
  }) async {
    final safePage = page < 1 ? 1 : page;
    final safePerPage = perPage < 1 ? 10 : perPage;

    final rows = await _localCacheService.list(
      type: _faqType,
      scope: _scope,
      search: search.trim(),
      limit: 1000,
      offset: 0,
    );

    final result = <FAQ>[];

    for (final row in rows) {
      try {
        final faq = FAQ.fromJson(row);

        if (featured != null && _faqFeatured(faq) != featured) {
          continue;
        }

        result.add(faq);
      } catch (_) {
        // Ignore malformed cached rows.
      }
    }

    result.sort(_sortFAQs);

    return _paginate(result, page: safePage, perPage: safePerPage);
  }

  // =========================================================
  // DOCUMENTATION - SAVE
  // =========================================================

  Future<void> saveDocumentation(Documentation documentation) async {
    await _localCacheService.put(
      type: _documentationType,
      id: documentation.id,
      scope: _scope,
      data: documentation.toJson(),
      searchableText: _documentationSearchableText(documentation),
      metadata: _documentationMetadata(documentation),
      remoteUpdatedAt: _updatedAt(documentation.toJson()),
    );
  }

  Future<void> saveDocumentationItems(
    Iterable<Documentation> documentation,
  ) async {
    if (documentation.isEmpty) return;

    await _localCacheService.putMany(
      type: _documentationType,
      scope: _scope,
      entities: documentation.map(
        (item) => CachedEntityInput(
          id: item.id,
          data: item.toJson(),
          searchableText: _documentationSearchableText(item),
          metadata: _documentationMetadata(item),
          remoteUpdatedAt: _updatedAt(item.toJson()),
        ),
      ),
    );
  }

  // =========================================================
  // DOCUMENTATION - GET
  // =========================================================

  Future<Documentation?> getDocumentation(String id) async {
    final normalized = id.trim();

    if (normalized.isEmpty) {
      return null;
    }

    final row = await _localCacheService.get(
      type: _documentationType,
      id: normalized,
      scope: _scope,
    );

    if (row == null) {
      return null;
    }

    try {
      return Documentation.fromJson(row);
    } catch (_) {
      return null;
    }
  }

  Future<List<Documentation>> getDocumentationItems({
    int page = 1,
    int perPage = 20,
    String search = '',
    String category = '',
  }) async {
    final safePage = page < 1 ? 1 : page;
    final safePerPage = perPage < 1 ? 20 : perPage;

    final rows = await _localCacheService.list(
      type: _documentationType,
      scope: _scope,
      search: search.trim(),
      limit: 1000,
      offset: 0,
    );

    final normalizedCategory = category.trim().toLowerCase();

    final result = <Documentation>[];

    for (final row in rows) {
      try {
        final documentation = Documentation.fromJson(row);

        if (normalizedCategory.isNotEmpty &&
            _documentationCategory(documentation) != normalizedCategory) {
          continue;
        }

        result.add(documentation);
      } catch (_) {
        // Ignore malformed rows.
      }
    }

    result.sort(_sortDocumentation);

    return _paginate(result, page: safePage, perPage: safePerPage);
  }

  // =========================================================
  // CACHE STATE
  // =========================================================

  Future<bool> hasCachedFAQs() {
    return _localCacheService.hasData(type: _faqType, scope: _scope);
  }

  Future<bool> hasCachedDocumentation() {
    return _localCacheService.hasData(type: _documentationType, scope: _scope);
  }

  Future<bool> isFAQCacheStale({Duration maxAge = const Duration(hours: 24)}) {
    return _localCacheService.isStale(
      type: _faqType,
      scope: _scope,
      maxAge: maxAge,
    );
  }

  Future<bool> isDocumentationCacheStale({
    Duration maxAge = const Duration(hours: 24),
  }) {
    return _localCacheService.isStale(
      type: _documentationType,
      scope: _scope,
      maxAge: maxAge,
    );
  }

  // =========================================================
  // CLEAR
  // =========================================================

  Future<void> clearFAQs() {
    return _localCacheService.clearType(type: _faqType, scope: _scope);
  }

  Future<void> clearDocumentation() {
    return _localCacheService.clearType(
      type: _documentationType,
      scope: _scope,
    );
  }

  Future<void> clear() async {
    await Future.wait([clearFAQs(), clearDocumentation()]);
  }

  // =========================================================
  // WATCH
  // =========================================================

  Stream<List<FAQ>> watchFAQs() {
    return _localCacheService.watch(type: _faqType, scope: _scope).map((rows) {
      final result = <FAQ>[];

      for (final row in rows) {
        try {
          result.add(FAQ.fromJson(row));
        } catch (_) {}
      }

      result.sort(_sortFAQs);

      return List<FAQ>.unmodifiable(result);
    });
  }

  Stream<List<Documentation>> watchDocumentation() {
    return _localCacheService
        .watch(type: _documentationType, scope: _scope)
        .map((rows) {
          final result = <Documentation>[];

          for (final row in rows) {
            try {
              result.add(Documentation.fromJson(row));
            } catch (_) {}
          }

          result.sort(_sortDocumentation);

          return List<Documentation>.unmodifiable(result);
        });
  }

  // =========================================================
  // SEARCH TEXT
  // =========================================================

  String _faqSearchableText(FAQ faq) {
    final json = faq.toJson();

    return [
          json['question']?.toString() ?? '',
          json['answer']?.toString() ?? '',
          json['category']?.toString() ?? '',
          json['tags']?.toString() ?? '',
        ]
        .where((value) => value.trim().isNotEmpty)
        .map(_stripHtml)
        .join(' ')
        .toLowerCase();
  }

  String _documentationSearchableText(Documentation documentation) {
    final json = documentation.toJson();

    return [
          json['title']?.toString() ?? '',
          json['description']?.toString() ?? '',
          json['content']?.toString() ?? '',
          json['category']?.toString() ?? '',
        ]
        .where((value) => value.trim().isNotEmpty)
        .map(_stripHtml)
        .join(' ')
        .toLowerCase();
  }

  // =========================================================
  // METADATA
  // =========================================================

  Map<String, dynamic> _faqMetadata(FAQ faq) {
    final json = faq.toJson();

    return {
      'featured': json['is_featured'] ?? json['featured'] ?? false,
      'category': json['category'],
      'sortOrder': json['sort_order'] ?? json['sortOrder'] ?? 0,
    };
  }

  Map<String, dynamic> _documentationMetadata(Documentation documentation) {
    final json = documentation.toJson();

    return {
      'category': json['category'],
      'sortOrder': json['sort_order'] ?? json['sortOrder'] ?? 0,
    };
  }

  // =========================================================
  // FILTER HELPERS
  // =========================================================

  bool _faqFeatured(FAQ faq) {
    final json = faq.toJson();

    final value = json['is_featured'] ?? json['featured'];

    if (value is bool) return value;
    if (value is num) return value != 0;

    return value?.toString().toLowerCase() == 'true';
  }

  String _documentationCategory(Documentation documentation) {
    return (documentation.toJson()['category'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
  }

  // =========================================================
  // SORTING
  // =========================================================

  int _sortFAQs(FAQ a, FAQ b) {
    final aJson = a.toJson();
    final bJson = b.toJson();

    final aOrder = (aJson['sort_order'] as num?)?.toInt() ?? 0;

    final bOrder = (bJson['sort_order'] as num?)?.toInt() ?? 0;

    final orderCompare = aOrder.compareTo(bOrder);

    if (orderCompare != 0) {
      return orderCompare;
    }

    final aQuestion = (aJson['question'] ?? '').toString().toLowerCase();

    final bQuestion = (bJson['question'] ?? '').toString().toLowerCase();

    return aQuestion.compareTo(bQuestion);
  }

  int _sortDocumentation(Documentation a, Documentation b) {
    final aJson = a.toJson();
    final bJson = b.toJson();

    final aOrder = (aJson['sort_order'] as num?)?.toInt() ?? 0;

    final bOrder = (bJson['sort_order'] as num?)?.toInt() ?? 0;

    final orderCompare = aOrder.compareTo(bOrder);

    if (orderCompare != 0) {
      return orderCompare;
    }

    final aTitle = (aJson['title'] ?? '').toString().toLowerCase();

    final bTitle = (bJson['title'] ?? '').toString().toLowerCase();

    return aTitle.compareTo(bTitle);
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
      return <T>[];
    }

    final end = (start + perPage).clamp(0, items.length);

    return items.sublist(start, end);
  }

  // =========================================================
  // DATES
  // =========================================================

  DateTime? _updatedAt(Map<String, dynamic> json) {
    final value =
        json['updated_at'] ??
        json['updated'] ??
        json['created_at'] ??
        json['created'];

    if (value == null) return null;

    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(value.toString());
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
