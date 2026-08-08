import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:user_app/core/storage/local_cache_service.dart';

import 'package:user_app/features/drugs/data/models/drug_category.dart';
import 'package:user_app/features/drugs/data/models/drug_class.dart';
import 'package:user_app/features/drugs/data/models/drug_tag.dart';
import 'package:user_app/features/drugs/data/models/therapeutic_category.dart';

final drugReferenceLocalRepositoryProvider =
    Provider<DrugReferenceLocalRepository>((ref) {
      return DrugReferenceLocalRepository(ref.watch(localCacheServiceProvider));
    });

final class DrugReferenceLocalRepository {
  DrugReferenceLocalRepository(this._localCacheService);

  final LocalCacheService _localCacheService;

  static const String _scope = 'public';

  static const String _categoryType = 'drug_category';
  static const String _tagType = 'drug_tag';
  static const String _classType = 'drug_class';
  static const String _therapeuticCategoryType = 'therapeutic_category';

  // =========================================================
  // DRUG CATEGORIES
  // =========================================================

  Future<void> saveCategories(Iterable<DrugCategory> items) {
    return _saveMany(
      type: _categoryType,
      items: items,
      idOf: (item) => item.id,
      nameOf: (item) => item.name,
      toJson: (item) => item.toJson(),
    );
  }

  Future<List<DrugCategory>> getCategories() {
    return _getMany(type: _categoryType, fromJson: DrugCategory.fromJson);
  }

  // =========================================================
  // DRUG TAGS
  // =========================================================

  Future<void> saveTags(Iterable<DrugTag> items) {
    return _saveMany(
      type: _tagType,
      items: items,
      idOf: (item) => item.id,
      nameOf: (item) => item.name,
      toJson: (item) => item.toJson(),
    );
  }

  Future<List<DrugTag>> getTags() {
    return _getMany(type: _tagType, fromJson: DrugTag.fromJson);
  }

  // =========================================================
  // DRUG CLASSES
  // =========================================================

  Future<void> saveClasses(Iterable<DrugClass> items) {
    return _saveMany(
      type: _classType,
      items: items,
      idOf: (item) => item.id,
      nameOf: (item) => item.name,
      toJson: (item) => item.toJson(),
    );
  }

  Future<List<DrugClass>> getClasses() {
    return _getMany(type: _classType, fromJson: DrugClass.fromJson);
  }

  // =========================================================
  // THERAPEUTIC CATEGORIES
  // =========================================================

  Future<void> saveTherapeuticCategories(Iterable<TherapeuticCategory> items) {
    return _saveMany(
      type: _therapeuticCategoryType,
      items: items,
      idOf: (item) => item.id,
      nameOf: (item) => item.name,
      toJson: (item) => item.toJson(),
    );
  }

  Future<List<TherapeuticCategory>> getTherapeuticCategories() {
    return _getMany(
      type: _therapeuticCategoryType,
      fromJson: TherapeuticCategory.fromJson,
    );
  }

  // =========================================================
  // CACHE STATUS
  // =========================================================

  Future<bool> hasCachedCategories() {
    return _localCacheService.hasData(type: _categoryType, scope: _scope);
  }

  Future<bool> hasCachedTags() {
    return _localCacheService.hasData(type: _tagType, scope: _scope);
  }

  Future<bool> hasCachedClasses() {
    return _localCacheService.hasData(type: _classType, scope: _scope);
  }

  Future<bool> hasCachedTherapeuticCategories() {
    return _localCacheService.hasData(
      type: _therapeuticCategoryType,
      scope: _scope,
    );
  }

  Future<bool> isStale({Duration maxAge = const Duration(days: 7)}) async {
    final results = await Future.wait([
      _localCacheService.isStale(
        type: _categoryType,
        scope: _scope,
        maxAge: maxAge,
      ),
      _localCacheService.isStale(type: _tagType, scope: _scope, maxAge: maxAge),
      _localCacheService.isStale(
        type: _classType,
        scope: _scope,
        maxAge: maxAge,
      ),
      _localCacheService.isStale(
        type: _therapeuticCategoryType,
        scope: _scope,
        maxAge: maxAge,
      ),
    ]);

    return results.any((value) => value);
  }

  // =========================================================
  // CLEAR
  // =========================================================

  Future<void> clear() async {
    await Future.wait([
      _localCacheService.clearType(type: _categoryType, scope: _scope),
      _localCacheService.clearType(type: _tagType, scope: _scope),
      _localCacheService.clearType(type: _classType, scope: _scope),
      _localCacheService.clearType(
        type: _therapeuticCategoryType,
        scope: _scope,
      ),
    ]);
  }

  // =========================================================
  // GENERIC SAVE
  // =========================================================

  Future<void> _saveMany<T>({
    required String type,
    required Iterable<T> items,
    required String Function(T item) idOf,
    required String Function(T item) nameOf,
    required Map<String, dynamic> Function(T item) toJson,
  }) async {
    if (items.isEmpty) return;

    await _localCacheService.putMany(
      type: type,
      scope: _scope,
      entities: items.map(
        (item) => CachedEntityInput(
          id: idOf(item),
          data: toJson(item),
          searchableText: nameOf(item).trim().toLowerCase(),
          metadata: {'name': nameOf(item)},
        ),
      ),
    );
  }

  // =========================================================
  // GENERIC READ
  // =========================================================

  Future<List<T>> _getMany<T>({
    required String type,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    final rows = await _localCacheService.list(
      type: type,
      scope: _scope,
      limit: 500,
      offset: 0,
    );

    final result = <T>[];

    for (final row in rows) {
      try {
        result.add(fromJson(row));
      } catch (_) {
        // Ignore malformed local rows.
      }
    }

    return result;
  }
}
