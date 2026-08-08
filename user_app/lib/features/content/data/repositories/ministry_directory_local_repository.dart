import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_app/core/storage/local_cache_service.dart';

import 'package:user_app/features/content/data/models/ministry_directory.dart';

final ministryDirectoryLocalRepositoryProvider =
    Provider<MinistryDirectoryLocalRepository>((ref) {
      return MinistryDirectoryLocalRepository(
        ref.watch(localCacheServiceProvider),
      );
    });

class MinistryDirectoryLocalRepository {
  MinistryDirectoryLocalRepository(this._localCacheService);

  final LocalCacheService _localCacheService;

  static const String _entityType = 'ministry_directory';
  static const String _scope = 'public';

  // =========================================================
  // SAVE ONE
  // =========================================================

  Future<void> saveEntry(MinistryDirectory entry) async {
    await _localCacheService.put(
      type: _entityType,
      id: entry.id,
      scope: _scope,
      data: entry.toJson(),
      searchableText: _searchableText(entry),
      metadata: _metadata(entry),
    );
  }

  // =========================================================
  // SAVE MANY
  // =========================================================

  Future<void> saveEntries(Iterable<MinistryDirectory> entries) async {
    if (entries.isEmpty) {
      return;
    }

    await _localCacheService.putMany(
      type: _entityType,
      scope: _scope,
      entities: entries.map((entry) {
        return CachedEntityInput(
          id: entry.id,
          data: entry.toJson(),
          searchableText: _searchableText(entry),
          metadata: _metadata(entry),
        );
      }),
    );
  }

  // =========================================================
  // GET ONE
  // =========================================================

  Future<MinistryDirectory?> getEntry(String id) async {
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
      return MinistryDirectory.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  // =========================================================
  // LIST
  // =========================================================

  Future<List<MinistryDirectory>> getEntries({
    int page = 1,
    int perPage = 30,
    String search = '',
    String ministry = '',
    String department = '',
    String districtId = '',
    String regionId = '',
    String status = '',
    bool emergencyOnly = false,
  }) async {
    final safePage = page < 1 ? 1 : page;
    final safePerPage = perPage < 1 ? 30 : perPage;

    //
    // Fetching a larger candidate set is intentional here.
    //
    // The current generic cache service only filters search at SQL
    // level. Other metadata filters are applied below.
    //
    // We will improve LocalCacheService later so metadata filtering
    // and pagination happen entirely in SQLite.
    //
    final rows = await _localCacheService.list(
      type: _entityType,
      scope: _scope,
      search: search.trim(),
      limit: safePerPage * 5,
      offset: 0,
    );

    final entries = <MinistryDirectory>[];

    for (final row in rows) {
      try {
        final entry = MinistryDirectory.fromJson(row);

        if (!_matchesFilters(
          entry,
          ministry: ministry,
          department: department,
          districtId: districtId,
          regionId: regionId,
          status: status,
          emergencyOnly: emergencyOnly,
        )) {
          continue;
        }

        entries.add(entry);
      } catch (_) {
        // Skip malformed local data.
      }
    }

    final start = (safePage - 1) * safePerPage;

    if (start >= entries.length) {
      return const [];
    }

    final end = (start + safePerPage).clamp(0, entries.length);

    return entries.sublist(start, end);
  }

  // =========================================================
  // SEARCH
  // =========================================================

  Future<List<MinistryDirectory>> searchEntries(
    String query, {
    int page = 1,
    int perPage = 30,
  }) {
    return getEntries(page: page, perPage: perPage, search: query);
  }

  // =========================================================
  // EMERGENCY CONTACTS
  // =========================================================

  Future<List<MinistryDirectory>> getEmergencyContacts({
    int page = 1,
    int perPage = 30,
    String search = '',
  }) {
    return getEntries(
      page: page,
      perPage: perPage,
      search: search,
      emergencyOnly: true,
    );
  }

  // =========================================================
  // ACTIVE DIRECTORY ENTRIES
  // =========================================================

  Future<List<MinistryDirectory>> getActiveEntries({
    int page = 1,
    int perPage = 30,
    String search = '',
  }) {
    return getEntries(
      page: page,
      perPage: perPage,
      search: search,
      status: 'active',
    );
  }

  // =========================================================
  // CACHE STATE
  // =========================================================

  Future<bool> hasCachedEntries() {
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

  Stream<List<MinistryDirectory>> watchEntries() {
    return _localCacheService.watch(type: _entityType, scope: _scope).map((
      rows,
    ) {
      final result = <MinistryDirectory>[];

      for (final row in rows) {
        try {
          result.add(MinistryDirectory.fromJson(row));
        } catch (_) {
          // Skip invalid cached records.
        }
      }

      return List<MinistryDirectory>.unmodifiable(result);
    });
  }

  // =========================================================
  // FILTERING
  // =========================================================

  bool _matchesFilters(
    MinistryDirectory entry, {
    required String ministry,
    required String department,
    required String districtId,
    required String regionId,
    required String status,
    required bool emergencyOnly,
  }) {
    final ministryFilter = ministry.trim().toLowerCase();

    if (ministryFilter.isNotEmpty) {
      final value = _ministry(entry).toLowerCase();

      if (value != ministryFilter) {
        return false;
      }
    }

    final departmentFilter = department.trim().toLowerCase();

    if (departmentFilter.isNotEmpty) {
      final value = _department(entry).toLowerCase();

      if (value != departmentFilter) {
        return false;
      }
    }

    final districtFilter = districtId.trim().toLowerCase();

    if (districtFilter.isNotEmpty) {
      final value = _districtId(entry).toLowerCase();

      if (value != districtFilter) {
        return false;
      }
    }

    final regionFilter = regionId.trim().toLowerCase();

    if (regionFilter.isNotEmpty) {
      final value = _regionId(entry).toLowerCase();

      if (value != regionFilter) {
        return false;
      }
    }

    final statusFilter = status.trim().toLowerCase();

    if (statusFilter.isNotEmpty) {
      final value = _status(entry).toLowerCase();

      if (value != statusFilter) {
        return false;
      }
    }

    if (emergencyOnly && !entry.isEmergencyContact) {
      return false;
    }

    return true;
  }

  // =========================================================
  // SEARCHABLE TEXT
  // =========================================================

  String _searchableText(MinistryDirectory entry) {
    return [
      _displayName(entry),
      _ministry(entry),
      _department(entry),
      _districtName(entry),
      _regionName(entry),
      _phone(entry),
      _email(entry),
    ].where((value) => value.trim().isNotEmpty).join(' ').toLowerCase();
  }

  // =========================================================
  // METADATA
  // =========================================================

  Map<String, dynamic> _metadata(MinistryDirectory entry) {
    return {
      'ministry': _ministry(entry),
      'department': _department(entry),
      'districtId': _districtId(entry),
      'regionId': _regionId(entry),
      'status': _status(entry),
      'emergency': entry.isEmergencyContact,
    };
  }

  // =========================================================
  // MODEL FIELD MAPPERS
  // =========================================================
  //
  // These helpers intentionally isolate model-property assumptions.
  //
  // Replace each implementation with your exact MinistryDirectory
  // model property if the name differs.
  // =========================================================

  String _displayName(MinistryDirectory entry) {
    //
    // Example:
    //
    // return entry.name;
    //

    return entry.toString();
  }

  String _ministry(MinistryDirectory entry) {
    //
    // Example:
    //
    // return entry.ministry;
    //

    return '';
  }

  String _department(MinistryDirectory entry) {
    //
    // Example:
    //
    // return entry.department;
    //

    return '';
  }

  String _districtId(MinistryDirectory entry) {
    //
    // Example:
    //
    // return entry.districtId;
    //

    return '';
  }

  String _districtName(MinistryDirectory entry) {
    //
    // Example:
    //
    // return entry.districtName;
    //

    return '';
  }

  String _regionId(MinistryDirectory entry) {
    //
    // Example:
    //
    // return entry.regionId;
    //

    return '';
  }

  String _regionName(MinistryDirectory entry) {
    //
    // Example:
    //
    // return entry.regionName;
    //

    return '';
  }

  String _status(MinistryDirectory entry) {
    //
    // Example:
    //
    // return entry.status;
    //

    return '';
  }

  String _phone(MinistryDirectory entry) {
    //
    // Example:
    //
    // return entry.phone;
    //

    return '';
  }

  String _email(MinistryDirectory entry) {
    //
    // Example:
    //
    // return entry.email;
    //

    return '';
  }
}
