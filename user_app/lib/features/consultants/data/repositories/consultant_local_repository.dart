import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_app/core/storage/local_cache_service.dart';

import 'package:user_app/features/consultants/data/models/consultant.dart';

final consultantLocalRepositoryProvider = Provider<ConsultantLocalRepository>((
  ref,
) {
  return ConsultantLocalRepository(ref.watch(localCacheServiceProvider));
});

class ConsultantLocalRepository {
  ConsultantLocalRepository(this._localCacheService);

  final LocalCacheService _localCacheService;

  static const String _entityType = 'consultant';
  static const String _scope = 'public';

  // =========================================================
  // SAVE ONE
  // =========================================================

  Future<void> saveConsultant(Consultant consultant) async {
    await _localCacheService.put(
      type: _entityType,
      id: consultant.id,
      scope: _scope,
      data: consultant.toJson(),
      searchableText: _searchableText(consultant),
      metadata: _metadata(consultant),
    );
  }

  // =========================================================
  // SAVE MANY
  // =========================================================

  Future<void> saveConsultants(Iterable<Consultant> consultants) async {
    if (consultants.isEmpty) {
      return;
    }

    await _localCacheService.putMany(
      type: _entityType,
      scope: _scope,
      entities: consultants.map((consultant) {
        return CachedEntityInput(
          id: consultant.id,
          data: consultant.toJson(),
          searchableText: _searchableText(consultant),
          metadata: _metadata(consultant),
        );
      }),
    );
  }

  // =========================================================
  // GET ONE
  // =========================================================

  Future<Consultant?> getConsultant(String id) async {
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
      return Consultant.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  // =========================================================
  // GET LIST
  // =========================================================

  Future<List<Consultant>> getConsultants({
    int page = 1,
    int perPage = 30,
    String search = '',
    String specialty = '',
    String region = '',
    String city = '',
    bool? verified,
    bool activeOnly = false,
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

    final consultants = <Consultant>[];

    for (final row in rows) {
      try {
        final consultant = Consultant.fromJson(row);

        if (!_matchesFilters(
          consultant,
          specialty: specialty,
          region: region,
          city: city,
          verified: verified,
          activeOnly: activeOnly,
        )) {
          continue;
        }

        consultants.add(consultant);
      } catch (_) {
        // Ignore malformed cache rows.
        //
        // The next successful remote refresh will replace them.
      }
    }

    return consultants;
  }

  // =========================================================
  // SEARCH
  // =========================================================

  Future<List<Consultant>> searchConsultants(
    String query, {
    int page = 1,
    int perPage = 30,
  }) {
    return getConsultants(page: page, perPage: perPage, search: query);
  }

  // =========================================================
  // VERIFIED
  // =========================================================

  Future<List<Consultant>> getVerifiedConsultants({
    int page = 1,
    int perPage = 30,
    String search = '',
  }) {
    return getConsultants(
      page: page,
      perPage: perPage,
      search: search,
      verified: true,
    );
  }

  // =========================================================
  // ACTIVE / ONLINE
  // =========================================================

  Future<List<Consultant>> getActiveConsultants({
    int page = 1,
    int perPage = 30,
    String search = '',
  }) {
    return getConsultants(
      page: page,
      perPage: perPage,
      search: search,
      activeOnly: true,
    );
  }

  // =========================================================
  // SPECIALTY
  // =========================================================

  Future<List<Consultant>> getBySpecialty({
    required String specialty,
    int page = 1,
    int perPage = 30,
    String search = '',
  }) {
    return getConsultants(
      page: page,
      perPage: perPage,
      search: search,
      specialty: specialty,
    );
  }

  // =========================================================
  // LOCATION
  // =========================================================

  Future<List<Consultant>> getByLocation({
    String region = '',
    String city = '',
    int page = 1,
    int perPage = 30,
    String search = '',
  }) {
    return getConsultants(
      page: page,
      perPage: perPage,
      search: search,
      region: region,
      city: city,
    );
  }

  // =========================================================
  // FILTER OPTIONS
  // =========================================================

  Future<List<String>> getSpecialties() async {
    final consultants = await getConsultants(page: 1, perPage: 500);

    final values = consultants
        .map((consultant) => consultant.specialty?.name.trim() ?? '')
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();

    values.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return values;
  }

  Future<List<String>> getLocations() async {
    final consultants = await getConsultants(page: 1, perPage: 500);

    final values = consultants
        .map((consultant) => consultant.city.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();

    values.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return values;
  }

  // =========================================================
  // CACHE STATE
  // =========================================================

  Future<bool> hasCachedConsultants() {
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

  Stream<List<Consultant>> watchConsultants() {
    return _localCacheService.watch(type: _entityType, scope: _scope).map((
      rows,
    ) {
      final consultants = <Consultant>[];

      for (final row in rows) {
        try {
          consultants.add(Consultant.fromJson(row));
        } catch (_) {
          // Ignore malformed cache records.
        }
      }

      return List<Consultant>.unmodifiable(consultants);
    });
  }

  // =========================================================
  // FILTER MATCHING
  // =========================================================

  bool _matchesFilters(
    Consultant consultant, {
    required String specialty,
    required String region,
    required String city,
    required bool? verified,
    required bool activeOnly,
  }) {
    final specialtyFilter = specialty.trim().toLowerCase();

    if (specialtyFilter.isNotEmpty) {
      final value = consultant.specialty?.name.trim().toLowerCase() ?? '';

      if (value != specialtyFilter) {
        return false;
      }
    }

    final regionFilter = region.trim().toLowerCase();

    if (regionFilter.isNotEmpty) {
      final value = _consultantRegion(consultant).toLowerCase();

      if (value != regionFilter) {
        return false;
      }
    }

    final cityFilter = city.trim().toLowerCase();

    if (cityFilter.isNotEmpty &&
        consultant.city.trim().toLowerCase() != cityFilter) {
      return false;
    }

    if (verified != null && consultant.verified != verified) {
      return false;
    }

    if (activeOnly && !_isActive(consultant)) {
      return false;
    }

    return true;
  }

  // =========================================================
  // SEARCHABLE TEXT
  // =========================================================

  String _searchableText(Consultant consultant) {
    return [
      consultant.name,
      consultant.email,
      consultant.specialty?.name ?? '',
      consultant.department,
      consultant.city,
      _consultantRegion(consultant),
    ].where((value) => value.trim().isNotEmpty).join(' ').toLowerCase();
  }

  // =========================================================
  // METADATA
  // =========================================================

  Map<String, dynamic> _metadata(Consultant consultant) {
    return {
      'specialty': consultant.specialty?.name ?? '',
      'department': consultant.department,
      'city': consultant.city,
      'region': _consultantRegion(consultant),
      'verified': consultant.verified,
      'active': _isActive(consultant),
    };
  }

  // =========================================================
  // ACTIVE STATUS
  // =========================================================

  bool _isActive(Consultant consultant) {
    // Update this if your Consultant model exposes
    // a direct enum/boolean such as:
    //
    // consultant.isOnline
    // consultant.status == ConsultantStatus.active
    //
    // If your current model has a string status, use:
    //
    // return consultant.status.toLowerCase() == 'active';

    return true;
  }

  // =========================================================
  // REGION
  // =========================================================

  String _consultantRegion(Consultant consultant) {
    // Replace with the exact property from your Consultant model,
    // for example:
    //
    // return consultant.region;
    //
    // or:
    //
    // return consultant.region?.name ?? '';

    return '';
  }
}
