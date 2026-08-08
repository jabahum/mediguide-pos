import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_app/core/storage/local_cache_service.dart';

import 'package:user_app/features/abbreviations/data/models/abbreviation.dart';

final abbreviationLocalRepositoryProvider =
    Provider<AbbreviationLocalRepository>((ref) {
      return AbbreviationLocalRepository(ref.watch(localCacheServiceProvider));
    });

class AbbreviationLocalRepository {
  AbbreviationLocalRepository(this._localCacheService);

  final LocalCacheService _localCacheService;

  static const String _entityType = 'abbreviation';
  static const String _scope = 'public';

  // =========================================================
  // SAVE ONE
  // =========================================================

  Future<void> saveAbbreviation(Abbreviation abbreviation) async {
    await _localCacheService.put(
      type: _entityType,
      id: abbreviation.id,
      scope: _scope,
      data: abbreviation.toJson(),
      searchableText: _searchableText(abbreviation),
      metadata: _metadata(abbreviation),
    );
  }

  // =========================================================
  // SAVE MANY
  // =========================================================

  Future<void> saveAbbreviations(Iterable<Abbreviation> abbreviations) async {
    if (abbreviations.isEmpty) {
      return;
    }

    await _localCacheService.putMany(
      type: _entityType,
      scope: _scope,
      entities: abbreviations.map((abbreviation) {
        return CachedEntityInput(
          id: abbreviation.id,
          data: abbreviation.toJson(),
          searchableText: _searchableText(abbreviation),
          metadata: _metadata(abbreviation),
        );
      }),
    );
  }

  // =========================================================
  // GET ONE
  // =========================================================

  Future<Abbreviation?> getAbbreviation(String id) async {
    final normalizedId = id.trim();

    if (normalizedId.isEmpty) {
      return null;
    }

    final json = await _localCacheService.get(
      type: _entityType,
      id: normalizedId,
      scope: _scope,
    );

    if (json == null) {
      return null;
    }

    try {
      return Abbreviation.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  // =========================================================
  // GET LIST
  // =========================================================

  Future<List<Abbreviation>> getAbbreviations({
    int page = 1,
    int perPage = 30,
    String search = '',
  }) async {
    final safePage = page < 1 ? 1 : page;
    final safePerPage = perPage < 1 ? 30 : perPage;

    final rows = await _localCacheService.list(
      type: _entityType,
      scope: _scope,
      search: search.trim(),
      limit: safePerPage,
      offset: (safePage - 1) * safePerPage,
    );

    final abbreviations = <Abbreviation>[];

    for (final row in rows) {
      try {
        abbreviations.add(Abbreviation.fromJson(row));
      } catch (_) {
        // Ignore malformed cache rows.
        //
        // A future online refresh will replace them with
        // a valid server representation.
      }
    }

    return abbreviations;
  }

  // =========================================================
  // SEARCH
  // =========================================================

  Future<List<Abbreviation>> searchAbbreviations(
    String query, {
    int page = 1,
    int perPage = 30,
  }) {
    return getAbbreviations(page: page, perPage: perPage, search: query);
  }

  // =========================================================
  // COMMON ABBREVIATIONS
  // =========================================================

  Future<List<Abbreviation>> getCommonAbbreviations({int limit = 50}) async {
    final abbreviations = await getAbbreviations(page: 1, perPage: limit);

    return abbreviations.where(_isCommon).take(limit).toList(growable: false);
  }

  // =========================================================
  // CACHE STATUS
  // =========================================================

  Future<bool> hasCachedAbbreviations() {
    return _localCacheService.hasData(type: _entityType, scope: _scope);
  }

  Future<bool> isCacheStale({Duration maxAge = const Duration(hours: 24)}) {
    return _localCacheService.isStale(
      type: _entityType,
      scope: _scope,
      maxAge: maxAge,
    );
  }

  // =========================================================
  // CLEAR
  // =========================================================

  Future<void> clear() {
    return _localCacheService.clearType(type: _entityType, scope: _scope);
  }

  // =========================================================
  // STREAM
  // =========================================================

  Stream<List<Abbreviation>> watchAbbreviations() {
    return _localCacheService.watch(type: _entityType, scope: _scope).map((
      rows,
    ) {
      final result = <Abbreviation>[];

      for (final row in rows) {
        try {
          result.add(Abbreviation.fromJson(row));
        } catch (_) {
          // Skip invalid cached values.
        }
      }

      return List<Abbreviation>.unmodifiable(result);
    });
  }

  // =========================================================
  // SEARCHABLE TEXT
  // =========================================================

  String _searchableText(Abbreviation abbreviation) {
    return [
      abbreviation.displayAbbreviation,
      abbreviation.meaning,
      abbreviation.description,
    ].where((value) => value.trim().isNotEmpty).join(' ').toLowerCase();
  }

  // =========================================================
  // METADATA
  // =========================================================

  Map<String, dynamic> _metadata(Abbreviation abbreviation) {
    return {
      'abbreviation': abbreviation.displayAbbreviation,
      'meaning': abbreviation.meaning,

      // Add additional filterable values here as your
      // Abbreviation model exposes them.
    };
  }

  // =========================================================
  // COMMON FLAG
  // =========================================================

  bool _isCommon(Abbreviation abbreviation) {
    // Replace this with the exact property from your model
    // if Abbreviation exposes something such as:
    //
    // abbreviation.commonUsage
    // abbreviation.isCommon
    //
    // Until then, do not incorrectly classify cache entries.
    return false;
  }
}
