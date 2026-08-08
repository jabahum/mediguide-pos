import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_app/core/storage/local_cache_service.dart';

import 'package:user_app/features/calculators/data/models/calculator.dart';
import 'package:user_app/features/calculators/data/models/calculator_enums.dart';

final calculatorLocalRepositoryProvider = Provider<CalculatorLocalRepository>((
  ref,
) {
  return CalculatorLocalRepository(ref.watch(localCacheServiceProvider));
});

class CalculatorLocalRepository {
  CalculatorLocalRepository(this._localCacheService);

  final LocalCacheService _localCacheService;

  static const String _entityType = 'calculator';
  static const String _scope = 'public';

  // =========================================================
  // SAVE ONE
  // =========================================================

  Future<void> saveCalculator(Calculator calculator) async {
    await _localCacheService.put(
      type: _entityType,
      id: calculator.id,
      scope: _scope,
      data: calculator.toJson(),
      searchableText: _searchableText(calculator),
      metadata: _metadata(calculator),
      version: calculator.version,
    );
  }

  // =========================================================
  // SAVE MANY
  // =========================================================

  Future<void> saveCalculators(Iterable<Calculator> calculators) async {
    if (calculators.isEmpty) {
      return;
    }

    await _localCacheService.putMany(
      type: _entityType,
      scope: _scope,
      entities: calculators.map((calculator) {
        return CachedEntityInput(
          id: calculator.id,
          data: calculator.toJson(),
          searchableText: _searchableText(calculator),
          metadata: _metadata(calculator),
          version: calculator.version,
        );
      }),
    );
  }

  // =========================================================
  // GET ONE
  // =========================================================

  Future<Calculator?> getCalculator(String id) async {
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
      return Calculator.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  // =========================================================
  // GET LIST
  // =========================================================

  Future<List<Calculator>> getCalculators({
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

    final calculators = <Calculator>[];

    for (final row in rows) {
      try {
        calculators.add(Calculator.fromJson(row));
      } catch (_) {
        // Ignore malformed cache records.
        //
        // The next successful server refresh will replace them.
      }
    }

    return calculators;
  }

  // =========================================================
  // SEARCH
  // =========================================================

  Future<List<Calculator>> searchCalculators(
    String query, {
    int page = 1,
    int perPage = 30,
  }) {
    return getCalculators(page: page, perPage: perPage, search: query);
  }

  // =========================================================
  // FILTER BY TYPE
  // =========================================================

  Future<List<Calculator>> getByType({
    required CalculatorType type,
    int page = 1,
    int perPage = 30,
    String search = '',
  }) async {
    final items = await getCalculators(
      page: page,
      perPage: perPage,
      search: search,
    );

    return items
        .where((calculator) => calculator.type == type)
        .toList(growable: false);
  }

  // =========================================================
  // FILTER BY STATUS
  // =========================================================

  Future<List<Calculator>> getByStatus({
    required CalculatorStatus status,
    int page = 1,
    int perPage = 30,
    String search = '',
  }) async {
    final items = await getCalculators(
      page: page,
      perPage: perPage,
      search: search,
    );

    return items
        .where((calculator) => calculator.status == status)
        .toList(growable: false);
  }

  // =========================================================
  // ACTIVE CALCULATORS
  // =========================================================

  Future<List<Calculator>> getActiveCalculators({
    int page = 1,
    int perPage = 30,
    String search = '',
  }) async {
    final items = await getCalculators(
      page: page,
      perPage: perPage,
      search: search,
    );

    return items
        .where((calculator) => calculator.status == CalculatorStatus.active)
        .toList(growable: false);
  }

  // =========================================================
  // FEATURED
  // =========================================================

  Future<List<Calculator>> getFeaturedCalculators({int limit = 6}) async {
    final items = await getCalculators(page: 1, perPage: 100);

    return items.where(_isFeatured).take(limit).toList(growable: false);
  }

  // =========================================================
  // CACHE STATE
  // =========================================================

  Future<bool> hasCachedCalculators() {
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

  Stream<List<Calculator>> watchCalculators() {
    return _localCacheService.watch(type: _entityType, scope: _scope).map((
      rows,
    ) {
      final result = <Calculator>[];

      for (final row in rows) {
        try {
          result.add(Calculator.fromJson(row));
        } catch (_) {
          // Ignore invalid cached records.
        }
      }

      return List<Calculator>.unmodifiable(result);
    });
  }

  // =========================================================
  // SEARCHABLE TEXT
  // =========================================================

  String _searchableText(Calculator calculator) {
    return [
      calculator.name,
      calculator.description,
      calculator.type.name,
      calculator.status.name,
    ].where((value) => value.trim().isNotEmpty).join(' ').toLowerCase();
  }

  // =========================================================
  // METADATA
  // =========================================================

  Map<String, dynamic> _metadata(Calculator calculator) {
    return {
      'type': _typeToString(calculator.type),
      'status': calculator.status.name,
      'version': calculator.version,
      'appFile': calculator.appFile,
      'featured': _isFeatured(calculator),
    };
  }

  // =========================================================
  // FEATURED
  // =========================================================

  bool _isFeatured(Calculator calculator) {
    // Replace this with:
    //
    // return calculator.featured;
    //
    // if the model already exposes a featured flag.
    return false;
  }

  // =========================================================
  // TYPE MAPPING
  // =========================================================

  String _typeToString(CalculatorType type) {
    return switch (type) {
      CalculatorType.calculator => 'calculator',

      CalculatorType.decisionTool => 'decision_tool',

      CalculatorType.checklist => 'checklist',
    };
  }
}
