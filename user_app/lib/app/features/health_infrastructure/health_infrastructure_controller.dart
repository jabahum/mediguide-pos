import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:user_app/app/core/extensions/app_extensions.dart';
import 'package:user_app/app/core/navigation/app_navigator.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:user_app/app/data/models/filter_models.dart';
import 'package:user_app/app/widgets/generic_filter_bottom_sheet.dart';

import '../../data/models/models.dart';
import '../../data/repositories/facility_repository.dart';
import '../../core/di/core_providers.dart';
import '../../core/navigation/app_router.dart';
import '../../utils/constants.dart';
import '../../utils/common.dart';

final healthInfrastructureControllerProvider = ChangeNotifierProvider
    .autoDispose
    .family<HealthInfrastructureController, Object?>((ref, arguments) {
      return HealthInfrastructureController(
        ref.watch(facilityRepositoryProvider),
        arguments,
      );
    });

class HealthInfrastructureController extends ChangeNotifier {
  HealthInfrastructureController(this._repository, Object? arguments) {
    _initFromArguments(arguments);
    pagingController = PagingController<int, HealthFacility>(
      getNextPageKey: (state) =>
          state.lastPageIsEmpty ? null : state.nextIntPageKey,
      fetchPage: _loadPage,
    );
    unawaited(_loadFilterOptions());
    _updateActiveFilters();
  }

  final FacilityRepository _repository;
  late final PagingController<int, HealthFacility> pagingController;

  // ==================== FILTER STATE ====================
  final _filters = _Filters();
  Map<String, dynamic> treeFilters = {};

  // ==================== DATA STATE ====================
  List<Region> availableRegions = [];
  List<District> availableDistricts = [];
  List<FacilityLevel> availableFacilityLevels = [];
  List<OwnershipType> availableOwnershipTypes = [];

  bool isLoadingFilters = false;
  bool hasActiveFilters = false;
  bool _disposed = false;

  bool get isFiltering => _filters.isActive;

  @override
  void dispose() {
    _disposed = true;
    pagingController.dispose();
    super.dispose();
  }

  // ==================== INIT ====================

  void _initFromArguments(Object? args) {
    if (args is Map && args['treeFilters'] is Map) {
      treeFilters = Map<String, dynamic>.from(args['treeFilters']);
      _updateFromTreeFilters(treeFilters);
    }

    _updateActiveFilters();
  }

  // ==================== PAGINATION ====================

  Future<List<HealthFacility>> _loadPage(int pageKey) async {
    try {
      final result = await _repository.listFacilities(
        page: pageKey,
        perPage: pageSize,
        search: _filters.query,
        regionId: _filters.regionId,
        districtId: _filters.districtId,
        facilityLevelId: _filters.facilityLevelId,
        ownershipTypeId: _filters.ownershipTypeId,
      );

      return result.items.map((r) => HealthFacility.fromRecord(r)).toList();
    } catch (e) {
      Common.quickToast(title: 'errorLoadingFacilities'.tr);
      rethrow;
    }
  }

  // ==================== ACTIONS ====================

  void search(String value) {
    _filters.query = value.trim();
    _updateActiveFilters();
    _refresh();
  }

  void clearAllFilters() {
    _filters.reset();
    treeFilters.clear();
    availableDistricts.clear();
    _updateActiveFilters();
    _refresh();
  }

  void _refresh() {
    pagingController.refresh();
  }

  // ==================== FILTER MODAL ====================

  Future<void> showFilterModal(BuildContext context) async {
    final fields = <FilterField>[
      FilterField.text('search', 'search'.tr),
      FilterField.dropdown(
        'region',
        'region'.tr,
        [''] + availableRegions.map((e) => e.name).toList(),
      ),
      FilterField.dropdown(
        'district',
        'district'.tr,
        [''] + availableDistricts.map((e) => e.name).toList(),
      ),
      FilterField.dropdown(
        'facilityLevel',
        'facilityLevel'.tr,
        [''] + availableFacilityLevels.map((e) => e.name).toList(),
      ),
      FilterField.dropdown(
        'ownershipType',
        'ownershipType'.tr,
        [''] + availableOwnershipTypes.map((e) => e.name).toList(),
      ),
    ];

    final result = await GenericFilterBottomSheet.show(
      context: context,
      title: 'filterFacilities'.tr,
      fields: fields,
      initialValues: _filters.toMap(),
    );

    if (result != null) _applyFilters(result);
  }

  void _applyFilters(FilterResult result) {
    _filters
      ..query = result.getValue<String>('search') ?? ''
      ..regionId = _resolveRegion(result.getValue<String>('region'))
      ..districtId = _resolveDistrict(result.getValue<String>('district'))
      ..facilityLevelId = _resolveFacilityLevel(
        result.getValue<String>('facilityLevel'),
      )
      ..ownershipTypeId = _resolveOwnership(
        result.getValue<String>('ownershipType'),
      );

    if (_filters.regionId.isNotEmpty) {
      _loadDistricts(_filters.regionId);
    } else {
      availableDistricts.clear();
    }

    _updateActiveFilters();
    _refresh();
  }

  // ==================== HELPERS ====================

  Future<void> _loadFilterOptions() async {
    try {
      isLoadingFilters = true;

      final regions = await getRegions();

      availableRegions = regions;

      final levels = await _repository.levels();

      availableFacilityLevels = levels.items
          .map(FacilityLevel.fromRecord)
          .toList();

      final ownership = await _repository.ownershipTypes();

      availableOwnershipTypes = ownership.items
          .map(OwnershipType.fromRecord)
          .toList();

      if (_filters.regionId.isNotEmpty) {
        await _loadDistricts(_filters.regionId);
      }
    } finally {
      isLoadingFilters = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<List<Region>> getRegions({String? filter, String? sort}) async {
    final result = await _repository.regions();

    return result.items.map((e) => Region.fromRecord(e)).toList();
  }

  Future<void> _loadDistricts(String regionId) async {
    final districts = await _repository.districts(regionId: regionId);

    availableDistricts = districts.items
        .map((e) => District.fromRecord(e))
        .toList();
    if (!_disposed) notifyListeners();
  }

  String _resolveRegion(String? name) =>
      availableRegions.firstWhereOrNull((e) => e.name == name)?.id ?? '';

  String _resolveDistrict(String? name) =>
      availableDistricts.firstWhereOrNull((e) => e.name == name)?.id ?? '';

  String _resolveFacilityLevel(String? name) =>
      availableFacilityLevels.firstWhereOrNull((e) => e.name == name)?.id ?? '';

  String _resolveOwnership(String? name) =>
      availableOwnershipTypes.firstWhereOrNull((e) => e.name == name)?.id ?? '';

  void goToFacilityDetail(HealthFacility facility) {
    unawaited(_recordUsage(facility.id));
    AppNavigator.pushNamed(AppRoutes.healthFacility, arguments: facility);
  }

  Future<void> _recordUsage(String id) async {
    try {
      await _repository.recordUsage(id);
    } catch (_) {
      // Analytics must not block facility details.
    }
  }

  // ==================== TREE FILTERS ====================

  void _updateFromTreeFilters(Map<String, dynamic> filters) {
    _filters
      ..regionId = filters['region']?.toString() ?? ''
      ..districtId = filters['district']?.toString() ?? ''
      ..facilityLevelId = filters['facility_level']?.toString() ?? ''
      ..ownershipTypeId = filters['ownership_type']?.toString() ?? '';

    _updateActiveFilters();
  }

  void _updateActiveFilters() {
    hasActiveFilters = _filters.isActive;
    if (!_disposed) notifyListeners();
  }
}

// ==================== FILTER MODEL ====================

class _Filters {
  String query = '';
  String regionId = '';
  String districtId = '';
  String facilityLevelId = '';
  String ownershipTypeId = '';

  bool get isActive =>
      query.isNotEmpty ||
      regionId.isNotEmpty ||
      districtId.isNotEmpty ||
      facilityLevelId.isNotEmpty ||
      ownershipTypeId.isNotEmpty;

  void reset() {
    query = '';
    regionId = '';
    districtId = '';
    facilityLevelId = '';
    ownershipTypeId = '';
  }

  Map<String, dynamic> toMap() => {'search': query};
}
