import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:user_app/core/storage/local_cache_service.dart';
import 'package:user_app/core/storage/local_page.dart';
import 'package:user_app/features/drugs/data/models/drug.dart';

final drugLocalRepositoryProvider = Provider<DrugLocalRepository>((ref) {
  return DrugLocalRepository(ref.watch(localCacheServiceProvider));
});

final class DrugLocalRepository {
  DrugLocalRepository(this._cache);

  final LocalCacheService _cache;

  static const String _type = 'drug';
  static const String _scope = 'public';

  // =========================================================
  // SAVE ONE
  // =========================================================

  Future<void> saveDrug(Drug drug) {
    final json = drug.toJson();

    return _cache.put(
      type: _type,
      id: drug.id,
      scope: _scope,
      data: json,
      searchableText: _searchableText(json),
      metadata: _metadata(json),
      remoteUpdatedAt: _updatedAt(json),
    );
  }

  // =========================================================
  // SAVE MANY
  // =========================================================

  Future<void> saveDrugs(Iterable<Drug> drugs) async {
    if (drugs.isEmpty) {
      return;
    }

    await _cache.putMany(
      type: _type,
      scope: _scope,
      entities: drugs.map((drug) {
        final json = drug.toJson();

        return CachedEntityInput(
          id: drug.id,
          data: json,
          searchableText: _searchableText(json),
          metadata: _metadata(json),
          remoteUpdatedAt: _updatedAt(json),
        );
      }),
    );
  }

  // =========================================================
  // GET ONE
  // =========================================================

  Future<Drug?> get(String id) async {
    final normalizedId = id.trim();

    if (normalizedId.isEmpty) {
      return null;
    }

    final row = await _cache.get(type: _type, id: normalizedId, scope: _scope);

    if (row == null) {
      return null;
    }

    try {
      return Drug.fromJson(row);
    } catch (_) {
      return null;
    }
  }

  // =========================================================
  // LIST
  // =========================================================

  Future<LocalPage<Drug>> list({
    int page = 1,
    int perPage = 30,
    String search = '',
    String status = '',
    String reviewStatus = '',
    String drugClassId = '',
    String therapeuticCategoryId = '',
    String route = '',
    String pregnancyCategory = '',
    bool? whoEml,
    bool? antimicrobial,
    String sort = 'name',
    String order = 'asc',
  }) async {
    final safePage = page < 1 ? 1 : page;
    final safePerPage = perPage < 1 ? 30 : perPage;

    final rows = await _cache.list(
      type: _type,
      scope: _scope,
      search: search.trim(),
      limit: 5000,
      offset: 0,
    );

    final drugs = <Drug>[];

    for (final row in rows) {
      if (!_matches(
        row,
        status: status,
        reviewStatus: reviewStatus,
        drugClassId: drugClassId,
        therapeuticCategoryId: therapeuticCategoryId,
        route: route,
        pregnancyCategory: pregnancyCategory,
        whoEml: whoEml,
        antimicrobial: antimicrobial,
      )) {
        continue;
      }

      try {
        drugs.add(Drug.fromJson(row));
      } catch (_) {
        // Ignore corrupt cache records.
      }
    }

    drugs.sort(
      (a, b) => _compare(a.toJson(), b.toJson(), sort: sort, order: order),
    );

    final totalItems = drugs.length;

    final items = _paginate(drugs, page: safePage, perPage: safePerPage);

    return LocalPage<Drug>(
      items: items,
      totalItems: totalItems,
      page: safePage,
      perPage: safePerPage,
    );
  }

  // =========================================================
  // FILTER MATCHING
  // =========================================================

  bool _matches(
    Map<String, dynamic> json, {
    required String status,
    required String reviewStatus,
    required String drugClassId,
    required String therapeuticCategoryId,
    required String route,
    required String pregnancyCategory,
    required bool? whoEml,
    required bool? antimicrobial,
  }) {
    if (!_matchesString(json['status'], status)) {
      return false;
    }

    if (!_matchesString(
      json['review_status'] ?? json['reviewStatus'],
      reviewStatus,
    )) {
      return false;
    }

    if (!_matchesString(
      json['drug_class_id'] ?? json['drugClassId'],
      drugClassId,
    )) {
      return false;
    }

    if (!_matchesString(
      json['therapeutic_category_id'] ?? json['therapeuticCategoryId'],
      therapeuticCategoryId,
    )) {
      return false;
    }

    if (!_matchesString(json['route'], route)) {
      return false;
    }

    if (!_matchesString(
      json['pregnancy_category'] ?? json['pregnancyCategory'],
      pregnancyCategory,
    )) {
      return false;
    }

    if (whoEml != null) {
      final value = json['who_eml'] ?? json['whoEml'];

      if (_bool(value) != whoEml) {
        return false;
      }
    }

    if (antimicrobial != null) {
      final value = json['antimicrobial'];

      if (_bool(value) != antimicrobial) {
        return false;
      }
    }

    return true;
  }

  bool _matchesString(dynamic value, String filter) {
    final normalizedFilter = filter.trim().toLowerCase();

    if (normalizedFilter.isEmpty) {
      return true;
    }

    final normalizedValue = (value ?? '').toString().trim().toLowerCase();

    return normalizedValue == normalizedFilter;
  }

  bool _bool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final normalized = value?.toString().trim().toLowerCase();

    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }

  // =========================================================
  // CACHE STATE
  // =========================================================

  Future<bool> hasData() {
    return _cache.hasData(type: _type, scope: _scope);
  }

  Future<bool> isStale({Duration maxAge = const Duration(hours: 24)}) {
    return _cache.isStale(type: _type, scope: _scope, maxAge: maxAge);
  }

  Future<void> clear() {
    return _cache.clearType(type: _type, scope: _scope);
  }

  // =========================================================
  // WATCH
  // =========================================================

  Stream<List<Drug>> watch() {
    return _cache.watch(type: _type, scope: _scope).map((rows) {
      final drugs = <Drug>[];

      for (final row in rows) {
        try {
          drugs.add(Drug.fromJson(row));
        } catch (_) {
          // Ignore corrupt local row.
        }
      }

      drugs.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

      return List<Drug>.unmodifiable(drugs);
    });
  }

  // =========================================================
  // SEARCHABLE TEXT
  // =========================================================

  String _searchableText(Map<String, dynamic> json) {
    return [
          json['name']?.toString() ?? '',
          json['generic_name']?.toString() ?? '',
          json['genericName']?.toString() ?? '',
          json['brand_names']?.toString() ?? '',
          json['brandNames']?.toString() ?? '',
          json['description']?.toString() ?? '',
          json['indications']?.toString() ?? '',
          json['contraindications']?.toString() ?? '',
          json['route']?.toString() ?? '',
          json['pregnancy_category']?.toString() ?? '',
          json['pregnancyCategory']?.toString() ?? '',
          json['drug_class_name']?.toString() ?? '',
          json['drugClassName']?.toString() ?? '',
          json['therapeutic_category_name']?.toString() ?? '',
          json['therapeuticCategoryName']?.toString() ?? '',
        ]
        .where((value) => value.trim().isNotEmpty)
        .map(_stripHtml)
        .join(' ')
        .toLowerCase();
  }

  // =========================================================
  // METADATA
  // =========================================================

  Map<String, dynamic> _metadata(Map<String, dynamic> json) {
    return {
      'status': json['status'],

      'reviewStatus': json['review_status'] ?? json['reviewStatus'],

      'drugClassId': json['drug_class_id'] ?? json['drugClassId'],

      'therapeuticCategoryId':
          json['therapeutic_category_id'] ?? json['therapeuticCategoryId'],

      'route': json['route'],

      'pregnancyCategory':
          json['pregnancy_category'] ?? json['pregnancyCategory'],

      'whoEml': json['who_eml'] ?? json['whoEml'],

      'antimicrobial': json['antimicrobial'],
    };
  }

  // =========================================================
  // SORT
  // =========================================================

  int _compare(
    Map<String, dynamic> a,
    Map<String, dynamic> b, {
    required String sort,
    required String order,
  }) {
    dynamic aValue;
    dynamic bValue;

    switch (sort) {
      case 'updated_at':
        aValue = a['updated_at'] ?? a['updated'];

        bValue = b['updated_at'] ?? b['updated'];

        break;

      case 'created_at':
        aValue = a['created_at'] ?? a['created'];

        bValue = b['created_at'] ?? b['created'];

        break;

      case 'generic_name':
        aValue = a['generic_name'] ?? a['genericName'];

        bValue = b['generic_name'] ?? b['genericName'];

        break;

      case 'name':
      default:
        aValue = a['name'];
        bValue = b['name'];
    }

    final result = _compareValues(aValue, bValue);

    return order.toLowerCase() == 'desc' ? -result : result;
  }

  int _compareValues(dynamic a, dynamic b) {
    if (a is num && b is num) {
      return a.compareTo(b);
    }

    final aDate = _date(a);
    final bDate = _date(b);

    if (aDate != null && bDate != null) {
      return aDate.compareTo(bDate);
    }

    return (a ?? '').toString().toLowerCase().compareTo(
      (b ?? '').toString().toLowerCase(),
    );
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
    return _date(
      json['updated_at'] ??
          json['updated'] ??
          json['created_at'] ??
          json['created'],
    );
  }

  DateTime? _date(dynamic value) {
    if (value == null) {
      return null;
    }

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
