import 'dart:async';

import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/app/router/app_navigator.dart';
import 'package:user_app/app/router/app_router.dart';
import 'package:user_app/core/config/app_keys.dart';
import 'package:user_app/core/constants/app_constants.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:user_app/core/utils/app_message.dart';

import 'package:user_app/features/facilities/data/repositories/facility_repository.dart';
import 'package:user_app/features/facilities/presentation/controllers/health_infrastructure_query.dart';
import 'package:user_app/features/facilities/presentation/controllers/health_infrastructure_state.dart';

import 'package:user_app/shared/models/filter_models.dart';
import 'package:user_app/shared/models/models.dart';
import 'package:user_app/shared/widgets/generic_filter_bottom_sheet.dart';

part 'health_infrastructure_controller.g.dart';

@riverpod
class HealthInfrastructureController extends _$HealthInfrastructureController {
  late final PagingController<int, HealthFacility> pagingController;

  FacilityRepository get _repository => ref.read(facilityRepositoryProvider);

  @override
  HealthInfrastructureState build(Object? arguments) {
    final initialQuery = HealthInfrastructureQuery.fromArguments(arguments);

    pagingController = PagingController<int, HealthFacility>(
      getNextPageKey: (pagingState) {
        if (pagingState.lastPageIsEmpty) {
          return null;
        }

        return pagingState.nextIntPageKey;
      },
      fetchPage: _loadPage,
    );

    ref.onDispose(() {
      pagingController.dispose();
    });

    Future.microtask(_loadFilterOptions);

    return HealthInfrastructureState(query: initialQuery);
  }

  // ======================================================
  // PAGINATION
  // ======================================================

  Future<List<HealthFacility>> _loadPage(int pageKey) async {
    try {
      final query = state.query;

      final result = await _repository.listFacilities(
        page: pageKey,
        perPage: AppConstants.pageSize,
        search: query.search,
        regionId: query.regionId,
        districtId: query.districtId,
        facilityLevelId: query.facilityLevelId,
        ownershipTypeId: query.ownershipTypeId,
      );

      return result.items;
    } catch (error) {
      _showError(error.toString());

      rethrow;
    }
  }

  // ======================================================
  // SEARCH
  // ======================================================

  void search(String value) {
    state = state.copyWith(query: state.query.copyWith(search: value.trim()));

    _refresh();
  }

  // ======================================================
  // CLEAR FILTERS
  // ======================================================

  void clearAllFilters() {
    state = state.copyWith(
      query: HealthInfrastructureQuery.empty,
      availableDistricts: const [],
    );

    _refresh();
  }

  // ======================================================
  // FILTER MODAL
  // ======================================================

  Future<void> showFilterModal(BuildContext context) async {
    if (!context.mounted) {
      return;
    }

    final fields = <FilterField>[
      FilterField.text('search', 'search'.tr),
      FilterField.dropdown('region', 'region'.tr, [
        '',
        ...state.availableRegions.map((region) => region.name),
      ]),
      FilterField.dropdown('district', 'district'.tr, [
        '',
        ...state.availableDistricts.map((district) => district.name),
      ]),
      FilterField.dropdown('facilityLevel', 'facilityLevel'.tr, [
        '',
        ...state.availableFacilityLevels.map((level) => level.name),
      ]),
      FilterField.dropdown('ownershipType', 'ownershipType'.tr, [
        '',
        ...state.availableOwnershipTypes.map((ownership) => ownership.name),
      ]),
    ];

    final result = await GenericFilterBottomSheet.show(
      context: context,
      title: 'filterFacilities'.tr,
      fields: fields,
      initialValues: _initialFilterValues(),
    );

    if (result == null) {
      return;
    }

    await _applyFilters(result);
  }

  Map<String, dynamic> _initialFilterValues() {
    final query = state.query;

    return <String, dynamic>{
      if (query.search.isNotEmpty) 'search': query.search,
      if (query.regionId.isNotEmpty) 'region': _regionName(query.regionId),
      if (query.districtId.isNotEmpty)
        'district': _districtName(query.districtId),
      if (query.facilityLevelId.isNotEmpty)
        'facilityLevel': _facilityLevelName(query.facilityLevelId),
      if (query.ownershipTypeId.isNotEmpty)
        'ownershipType': _ownershipName(query.ownershipTypeId),
    };
  }

  Future<void> _applyFilters(FilterResult result) async {
    final regionId = _resolveRegion(result.getValue<String>('region'));

    final districtId = _resolveDistrict(result.getValue<String>('district'));

    state = state.copyWith(
      query: state.query.copyWith(
        search: result.getValue<String>('search')?.trim() ?? '',
        regionId: regionId,
        districtId: districtId,
        facilityLevelId: _resolveFacilityLevel(
          result.getValue<String>('facilityLevel'),
        ),
        ownershipTypeId: _resolveOwnership(
          result.getValue<String>('ownershipType'),
        ),
        treeFilters: const {},
      ),
    );

    if (regionId.isNotEmpty) {
      await _loadDistricts(regionId);
    } else {
      state = state.copyWith(availableDistricts: const []);
    }

    _refresh();
  }

  // ======================================================
  // FILTER OPTIONS
  // ======================================================

  Future<void> _loadFilterOptions() async {
    state = state.copyWith(isLoadingFilters: true, clearFilterError: true);

    try {
      final results = await Future.wait([
        _repository.regions(),
        _repository.levels(),
        _repository.ownershipTypes(),
      ]);

      final regions = results[0];
      final levels = results[1];
      final ownership = results[2];

      state = state.copyWith(
        availableRegions: List<Region>.unmodifiable(regions.items),
        availableFacilityLevels: List<FacilityLevel>.unmodifiable(levels.items),
        availableOwnershipTypes: List<OwnershipType>.unmodifiable(
          ownership.items,
        ),
      );

      if (state.query.regionId.isNotEmpty) {
        await _loadDistricts(state.query.regionId);
      }
    } catch (error) {
      final message = error.toString();

      state = state.copyWith(filterError: message);

      _showError(message);
    } finally {
      state = state.copyWith(isLoadingFilters: false);
    }
  }

  Future<void> reloadFilterOptions() {
    return _loadFilterOptions();
  }

  Future<List<Region>> getRegions({String? filter, String? sort}) async {
    final result = await _repository.regions();

    return result.items;
  }

  Future<void> _loadDistricts(String regionId) async {
    try {
      final districts = await _repository.districts(regionId: regionId);

      state = state.copyWith(
        availableDistricts: List<District>.unmodifiable(districts.items),
      );
    } catch (error) {
      _showError(error.toString());
    }
  }

  // ======================================================
  // RESOLVE IDS
  // ======================================================

  String _resolveRegion(String? name) {
    final value = name?.trim() ?? '';

    if (value.isEmpty) {
      return '';
    }

    for (final region in state.availableRegions) {
      if (region.name == value) {
        return region.id;
      }
    }

    return '';
  }

  String _resolveDistrict(String? name) {
    final value = name?.trim() ?? '';

    if (value.isEmpty) {
      return '';
    }

    for (final district in state.availableDistricts) {
      if (district.name == value) {
        return district.id;
      }
    }

    return '';
  }

  String _resolveFacilityLevel(String? name) {
    final value = name?.trim() ?? '';

    if (value.isEmpty) {
      return '';
    }

    for (final level in state.availableFacilityLevels) {
      if (level.name == value) {
        return level.id;
      }
    }

    return '';
  }

  String _resolveOwnership(String? name) {
    final value = name?.trim() ?? '';

    if (value.isEmpty) {
      return '';
    }

    for (final ownership in state.availableOwnershipTypes) {
      if (ownership.name == value) {
        return ownership.id;
      }
    }

    return '';
  }

  // ======================================================
  // RESOLVE NAMES
  // ======================================================

  String _regionName(String id) {
    for (final region in state.availableRegions) {
      if (region.id == id) {
        return region.name;
      }
    }

    return '';
  }

  String _districtName(String id) {
    for (final district in state.availableDistricts) {
      if (district.id == id) {
        return district.name;
      }
    }

    return '';
  }

  String _facilityLevelName(String id) {
    for (final level in state.availableFacilityLevels) {
      if (level.id == id) {
        return level.name;
      }
    }

    return '';
  }

  String _ownershipName(String id) {
    for (final ownership in state.availableOwnershipTypes) {
      if (ownership.id == id) {
        return ownership.name;
      }
    }

    return '';
  }

  // ======================================================
  // TREE FILTERS
  // ======================================================

  Future<void> applyTreeFilters(Map<String, dynamic> filters) async {
    final query = HealthInfrastructureQuery(
      regionId: filters['region']?.toString().trim() ?? '',
      districtId: filters['district']?.toString().trim() ?? '',
      facilityLevelId: filters['facility_level']?.toString().trim() ?? '',
      ownershipTypeId: filters['ownership_type']?.toString().trim() ?? '',
      treeFilters: Map<String, dynamic>.from(filters),
    );

    state = state.copyWith(query: query);

    if (query.regionId.isNotEmpty) {
      await _loadDistricts(query.regionId);
    }

    _refresh();
  }

  // ======================================================
  // DETAILS
  // ======================================================

  void goToFacilityDetail(HealthFacility facility) {
    unawaited(_recordUsage(facility.id));

    AppNavigator.push(AppRoutes.healthFacility(facility.id), extra: facility);
  }

  Future<void> _recordUsage(String id) async {
    try {
      await _repository.recordUsage(id);
    } catch (_) {
      // Analytics must never block facility details.
    }
  }

  // ======================================================
  // REFRESH
  // ======================================================

  void refreshData() {
    _refresh();
  }

  void _refresh() {
    pagingController.refresh();
  }

  // ======================================================
  // ERROR
  // ======================================================

  void _showError(String message) {
    final context = AppKeys.navigatorKey.currentContext;

    if (context == null) {
      return;
    }

    AppMessage.error(context, message);
  }
}
