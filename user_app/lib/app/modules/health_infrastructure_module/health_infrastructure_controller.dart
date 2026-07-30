import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:user_app/app/data/models/filter_models.dart';
import 'package:user_app/app/widgets/generic_filter_bottom_sheet.dart';

import '../../data/models/models.dart';
import '../../data/services/backend_api_service.dart';
import '../../data/repositories/facility_repository.dart';
import '../../utils/constants.dart';
import '../../utils/common.dart';
import 'health_facility_detail_page.dart';

class HealthInfrastructureController extends GetxController {
  FacilityRepository get _repository =>
      FacilityRepository(BackendApiService.to);
  late final PagingController<int, HealthFacility> pagingController;

  // ==================== FILTER STATE ====================
  final _filters = _Filters();
  final RxMap<String, dynamic> treeFilters = <String, dynamic>{}.obs;

  // ==================== DATA STATE ====================
  final RxList<Region> availableRegions = <Region>[].obs;
  final RxList<District> availableDistricts = <District>[].obs;
  final RxList<FacilityLevel> availableFacilityLevels = <FacilityLevel>[].obs;
  final RxList<OwnershipType> availableOwnershipTypes = <OwnershipType>[].obs;

  final RxBool isLoadingFilters = false.obs;

  final RxBool hasActiveFilters = false.obs;

  bool get isFiltering => _filters.isActive;

  @override
  void onInit() {
    super.onInit();

    _initFromArguments();

    pagingController = PagingController<int, HealthFacility>(
      getNextPageKey: (state) =>
          state.lastPageIsEmpty ? null : state.nextIntPageKey,
      fetchPage: _loadPage,
    );

    _loadFilterOptions();
    _updateActiveFilters();
  }

  @override
  void onClose() {
    pagingController.dispose();
    super.onClose();
  }

  // ==================== INIT ====================

  void _initFromArguments() {
    final args = Get.arguments;

    if (args is Map && args['treeFilters'] is Map) {
      treeFilters.assignAll(Map<String, dynamic>.from(args['treeFilters']));
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

  void _applyFilters(dynamic result) {
    _filters
      ..query = result.get<String>('search')
      ..regionId = _resolveRegion(result.get('region'))
      ..districtId = _resolveDistrict(result.get('district'))
      ..facilityLevelId = _resolveFacilityLevel(result.get('facilityLevel'))
      ..ownershipTypeId = _resolveOwnership(result.get('ownershipType'));

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
      isLoadingFilters.value = true;

      final regions = await getRegions();

      availableRegions.assignAll(regions);

      final levels = await _repository.levels();

      availableFacilityLevels.assignAll(
        levels.items.map((e) => FacilityLevel.fromRecord(e)),
      );

      final ownership = await _repository.ownershipTypes();

      availableOwnershipTypes.assignAll(
        ownership.items.map((e) => OwnershipType.fromRecord(e)),
      );

      if (_filters.regionId.isNotEmpty) {
        await _loadDistricts(_filters.regionId);
      }
    } finally {
      isLoadingFilters.value = false;
    }
  }

  Future<List<Region>> getRegions({String? filter, String? sort}) async {
    final result = await _repository.regions();

    return result.items.map((e) => Region.fromRecord(e)).toList();
  }

  Future<void> _loadDistricts(String regionId) async {
    final districts = await _repository.districts(regionId: regionId);

    availableDistricts.value = districts.items
        .map((e) => District.fromRecord(e))
        .toList();
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
    Get.to(() => const HealthFacilityDetailPage(), arguments: facility);
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
    hasActiveFilters.value = _filters.isActive;
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
