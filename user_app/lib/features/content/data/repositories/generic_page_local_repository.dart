import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_app/core/storage/local_cache_service.dart';

import 'package:user_app/features/content/data/models/generic_page.dart';

final genericPageLocalRepositoryProvider = Provider<GenericPageLocalRepository>(
  (ref) {
    return GenericPageLocalRepository(ref.watch(localCacheServiceProvider));
  },
);

class GenericPageLocalRepository {
  GenericPageLocalRepository(this._localCacheService);

  final LocalCacheService _localCacheService;

  static const String _entityType = 'generic_page';
  static const String _scope = 'public';

  // =========================================================
  // SAVE ONE
  // =========================================================

  Future<void> savePage(GenericPage page) async {
    await _localCacheService.put(
      type: _entityType,
      id: page.id,
      scope: _scope,
      data: page.toJson(),
      searchableText: _searchableText(page),
      metadata: _metadata(page),
    );
  }

  // =========================================================
  // SAVE MANY
  // =========================================================

  Future<void> savePages(Iterable<GenericPage> pages) async {
    if (pages.isEmpty) {
      return;
    }

    await _localCacheService.putMany(
      type: _entityType,
      scope: _scope,
      entities: pages.map((page) {
        return CachedEntityInput(
          id: page.id,
          data: page.toJson(),
          searchableText: _searchableText(page),
          metadata: _metadata(page),
        );
      }),
    );
  }

  // =========================================================
  // GET BY ID
  // =========================================================

  Future<GenericPage?> getPage(String id) async {
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
      return GenericPage.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  // =========================================================
  // GET BY KEY
  // =========================================================

  Future<GenericPage?> getPageByKey(String key) async {
    final normalizedKey = key.trim();

    if (normalizedKey.isEmpty) {
      return null;
    }

    //
    // We fetch enough cached pages to resolve a key locally.
    //
    // Later we can move this to metadata-level SQL filtering
    // inside LocalCacheService for better performance.
    //
    final pages = await getPages(page: 1, perPage: 500);

    for (final page in pages) {
      if (_pageKey(page) == normalizedKey) {
        return page;
      }
    }

    return null;
  }

  // =========================================================
  // LIST
  // =========================================================

  Future<List<GenericPage>> getPages({
    int page = 1,
    int perPage = 50,
    String search = '',
  }) async {
    final safePage = page < 1 ? 1 : page;
    final safePerPage = perPage < 1 ? 50 : perPage;

    final rows = await _localCacheService.list(
      type: _entityType,
      scope: _scope,
      search: search.trim(),
      limit: safePerPage,
      offset: (safePage - 1) * safePerPage,
    );

    final result = <GenericPage>[];

    for (final row in rows) {
      try {
        result.add(GenericPage.fromJson(row));
      } catch (_) {
        // Ignore corrupted/stale cache rows.
        //
        // They will be replaced during the next successful sync.
      }
    }

    return result;
  }

  // =========================================================
  // SEARCH
  // =========================================================

  Future<List<GenericPage>> searchPages(
    String query, {
    int page = 1,
    int perPage = 50,
  }) {
    return getPages(page: page, perPage: perPage, search: query);
  }

  // =========================================================
  // CACHE STATE
  // =========================================================

  Future<bool> hasCachedPages() {
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
  // WATCH
  // =========================================================

  Stream<List<GenericPage>> watchPages() {
    return _localCacheService.watch(type: _entityType, scope: _scope).map((
      rows,
    ) {
      final result = <GenericPage>[];

      for (final row in rows) {
        try {
          result.add(GenericPage.fromJson(row));
        } catch (_) {
          // Ignore invalid cached records.
        }
      }

      return List<GenericPage>.unmodifiable(result);
    });
  }

  // =========================================================
  // SEARCHABLE CONTENT
  // =========================================================

  String _searchableText(GenericPage page) {
    final values = <String>[page.title, page.description ?? ''];

    //
    // Your GenericPage already exposes:
    //
    // isStringContent
    // isKeyValueContent
    // stringContent
    // sections
    //

    if (page.isStringContent) {
      values.add(_stripHtml(page.stringContent));
    }

    if (page.isKeyValueContent) {
      for (final section in page.sections) {
        values
          ..add(section.title)
          ..add(_stripHtml(section.content));
      }
    }

    return values
        .where((value) => value.trim().isNotEmpty)
        .join(' ')
        .toLowerCase();
  }

  // =========================================================
  // METADATA
  // =========================================================

  Map<String, dynamic> _metadata(GenericPage page) {
    return {
      'key': _pageKey(page),
      'title': page.title,
      'contentType': page.isKeyValueContent
          ? 'key_value'
          : page.isStringContent
          ? 'string'
          : 'unknown',
    };
  }

  // =========================================================
  // PAGE KEY
  // =========================================================

  String _pageKey(GenericPage page) {
    //
    // IMPORTANT:
    //
    // Your API repository has:
    //
    //     byKey(pageKey)
    //
    // therefore GenericPage should have a corresponding field.
    //
    // Replace this implementation with the exact model property:
    //
    //     return page.key;
    //
    // if `key` exists on GenericPage.
    //
    // Falling back to id keeps this file compiling until that
    // model field is confirmed.
    //

    return page.id;
  }

  // =========================================================
  // HTML CLEANUP
  // =========================================================

  String _stripHtml(String value) {
    return value
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
