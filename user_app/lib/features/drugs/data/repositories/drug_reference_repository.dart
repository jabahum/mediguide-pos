import 'package:user_app/core/network/api_client.dart';
import 'package:user_app/core/network/ttl_response_cache.dart';

import 'package:user_app/features/drugs/data/models/drug_category.dart';
import 'package:user_app/features/drugs/data/models/drug_class.dart';
import 'package:user_app/features/drugs/data/models/drug_tag.dart';
import 'package:user_app/features/drugs/data/models/therapeutic_category.dart';

import 'package:user_app/features/drugs/data/repositories/drug_reference_local_repository.dart';

final class DrugReferenceRepository {
  DrugReferenceRepository(this._api, this._local, {TtlResponseCache? cache})
    : _cache = cache ?? TtlResponseCache();

  final BackendApiService _api;
  final DrugReferenceLocalRepository _local;
  final TtlResponseCache _cache;

  // =========================================================
  // CATEGORIES
  // =========================================================

  Future<List<DrugCategory>> categories() {
    return _items<DrugCategory>(
      path: '/api/v2/drug-categories',
      cacheKey: 'drug-reference:categories',
      fromJson: DrugCategory.fromJson,
      saveLocal: _local.saveCategories,
      readLocal: _local.getCategories,
    );
  }

  // =========================================================
  // TAGS
  // =========================================================

  Future<List<DrugTag>> tags() {
    return _items<DrugTag>(
      path: '/api/v2/drug-tags',
      cacheKey: 'drug-reference:tags',
      fromJson: DrugTag.fromJson,
      saveLocal: _local.saveTags,
      readLocal: _local.getTags,
    );
  }

  // =========================================================
  // CLASSES
  // =========================================================

  Future<List<DrugClass>> classes() {
    return _items<DrugClass>(
      path: '/api/v2/drug-classes',
      cacheKey: 'drug-reference:classes',
      fromJson: DrugClass.fromJson,
      saveLocal: _local.saveClasses,
      readLocal: _local.getClasses,
    );
  }

  // =========================================================
  // THERAPEUTIC CATEGORIES
  // =========================================================

  Future<List<TherapeuticCategory>> therapeuticCategories() {
    return _items<TherapeuticCategory>(
      path: '/api/v2/therapeutic-categories',
      cacheKey: 'drug-reference:therapeutic-categories',
      fromJson: TherapeuticCategory.fromJson,
      saveLocal: _local.saveTherapeuticCategories,
      readLocal: _local.getTherapeuticCategories,
    );
  }

  // =========================================================
  // NAMES
  // =========================================================

  Future<List<String>> categoryNames() async {
    final values = (await categories())
        .map((item) => item.name.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();

    values.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return List<String>.unmodifiable(values);
  }

  Future<List<String>> tagNames() async {
    final values = (await tags())
        .map((item) => item.name.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();

    values.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return List<String>.unmodifiable(values);
  }

  // =========================================================
  // CACHE STATE
  // =========================================================

  Future<bool> isCacheStale({Duration maxAge = const Duration(days: 7)}) {
    return _local.isStale(maxAge: maxAge);
  }

  Future<void> clearPersistentCache() {
    return _local.clear();
  }

  // =========================================================
  // GENERIC LOADER
  // =========================================================

  Future<List<T>> _items<T>({
    required String path,
    required String cacheKey,
    required T Function(Map<String, dynamic>) fromJson,
    required Future<void> Function(Iterable<T>) saveLocal,
    required Future<List<T>> Function() readLocal,
  }) async {
    try {
      // -------------------------------------------------------
      // Fast path:
      //
      // TtlResponseCache may return a response already loaded
      // recently without touching the network.
      // -------------------------------------------------------

      final response = await _cache.getOrLoad(
        key: cacheKey,
        ttl: const Duration(minutes: 30),
        load: () => _api.requestJson(
          path,
          method: 'GET',
          query: const {
            'page': '1',
            'per_page': '100',
            'sort': 'name',
            'order': 'asc',
          },
        ),
      );

      final value = response['data'] is Map ? response['data'] : response;

      final items = value is Map ? value['items'] : null;

      final result = (items as List? ?? const [])
          .whereType<Map>()
          .map((item) => fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false);

      // -------------------------------------------------------
      // Persist successful response.
      //
      // Local cache failures are intentionally non-fatal.
      // -------------------------------------------------------

      if (result.isNotEmpty) {
        try {
          await saveLocal(result);
        } catch (_) {
          // Persistent cache must not block successful API data.
        }
      }

      return result;
    } catch (_) {
      // -------------------------------------------------------
      // OFFLINE FALLBACK
      // -------------------------------------------------------

      final cached = await readLocal();

      if (cached.isNotEmpty) {
        return cached;
      }

      rethrow;
    }
  }
}
