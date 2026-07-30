import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:user_app/app/data/models/filter_models.dart';

import '../../data/models/models.dart';
import '../../data/services/backend_api_service.dart';
import '../../utils/constants.dart';
import '../../utils/common.dart';
import '../../widgets/generic_filter_bottom_sheet.dart';

class MinistryDirectoryController extends GetxController {
  // ================= PAGINATION =================
  late final PagingController<int, MinistryDirectory> pagingController;

  // ================= FILTER STATE =================
  final RxMap<String, dynamic> treeFilters = <String, dynamic>{}.obs;

  final RxString searchQuery = ''.obs;
  final RxString selectedMinistry = ''.obs;
  final RxString selectedDistrict = ''.obs;
  final RxString selectedRegion = ''.obs;
  final RxString selectedDepartment = ''.obs;
  final RxString selectedStatus = ''.obs;

  final RxBool showEmergencyOnly = false.obs;
  final RxBool showActiveOnly = true.obs;

  final RxBool hasActiveFilters = false.obs;

  // ================= OPTIONS =================
  final RxList<String> availableMinistries = <String>[].obs;
  final RxList<String> availableDistricts = <String>[].obs;
  final RxList<String> availableRegions = <String>[].obs;

  final RxBool isLoadingFilters = false.obs;

  // ================= LIFECYCLE =================
  @override
  void onInit() {
    super.onInit();

    _applyTreeFiltersFromArguments();

    pagingController = PagingController<int, MinistryDirectory>(
      getNextPageKey: (state) =>
          state.lastPageIsEmpty ? null : state.nextIntPageKey,
      fetchPage: _loadPage,
    );

    _loadFilterOptions();
  }

  @override
  void onClose() {
    pagingController.dispose();
    super.onClose();
  }

  // ================= DATA LOADING =================

  Future<List<MinistryDirectory>> _loadPage(int pageKey) async {
    try {
      final filter = _buildFilter();

      final result = await BackendApiService.to.getRecordList(
        collectionName: 'ministry_directory',
        page: pageKey,
        perPage: pageSize,
        filter: filter.isEmpty ? null : filter,
        sort: 'priority_level,name',
        expand: 'district,region',
      );

      return result.items.map((e) => MinistryDirectory.fromRecord(e)).toList();
    } catch (e) {
      Common.quickToast(
        title: 'Error loading directory',
        description: e.toString(),
      );
      rethrow;
    }
  }

  // ================= FILTER BUILDING =================

  String _buildFilter() {
    final filters = <String>[];

    // Status logic
    if (selectedStatus.value.isNotEmpty) {
      final status = BackendApiService.escapeFilterValue(selectedStatus.value);
      filters.add('status="$status"');
    } else if (showActiveOnly.value) {
      filters.add('status="active"');
    }

    // Search
    if (searchQuery.value.isNotEmpty) {
      final q = BackendApiService.escapeFilterValue(searchQuery.value);
      filters.add(
        '(name~"$q" || title~"$q" || department~"$q" || ministry~"$q" || email~"$q")',
      );
    }

    // Simple filters
    if (selectedMinistry.value.isNotEmpty) {
      final ministry = BackendApiService.escapeFilterValue(
        selectedMinistry.value,
      );
      filters.add('ministry="$ministry"');
    }

    if (selectedDepartment.value.isNotEmpty) {
      final department = BackendApiService.escapeFilterValue(
        selectedDepartment.value,
      );
      filters.add('department~"$department"');
    }

    if (selectedDistrict.value.isNotEmpty) {
      final district = BackendApiService.escapeFilterValue(
        selectedDistrict.value,
      );
      filters.add('district.name~"$district"');
    }

    if (selectedRegion.value.isNotEmpty) {
      final region = BackendApiService.escapeFilterValue(selectedRegion.value);
      filters.add('region.name~"$region"');
    }

    // Flags
    if (showEmergencyOnly.value) {
      filters.add('priority_level=1');
    }

    return filters.join(' && ');
  }

  // ================= FILTER OPTIONS =================

  Future<void> _loadFilterOptions() async {
    try {
      isLoadingFilters.value = true;

      availableMinistries.value = Ministry.values.map((e) => e.label).toList();

      final districts = await BackendApiService.to.getRecordList(
        collectionName: 'districts',
        perPage: 500,
        sort: 'name',
      );

      availableDistricts.value = districts.items
          .map((e) => e.data['name'] as String)
          .toList();

      final regions = await BackendApiService.to.getRecordList(
        collectionName: 'regions',
        perPage: 500,
        sort: 'name',
      );

      availableRegions.value = regions.items
          .map((e) => e.data['name'] as String)
          .toList();
    } catch (e) {
      Common.quickToast(
        title: 'Error loading filters',
        description: e.toString(),
      );
    } finally {
      isLoadingFilters.value = false;
    }
  }

  // ================= ACTIONS =================

  void onSearchQueryChanged(String query) {
    searchQuery.value = query.trim();
    _refresh();
  }

  void resetFilters() {
    searchQuery.value = '';
    selectedMinistry.value = '';
    selectedDistrict.value = '';
    selectedRegion.value = '';
    selectedDepartment.value = '';
    selectedStatus.value = '';
    showEmergencyOnly.value = false;
    showActiveOnly.value = true;
    treeFilters.clear();

    _updateActiveFilters();
    _refresh();
  }

  Future<void> showAdvancedFilter(BuildContext context) async {
    final result = await GenericFilterBottomSheet.show(
      context: context,
      title: 'Filter Directory',
      fields: [
        FilterField.text('search', 'Search'),
        FilterField.dropdown('ministry', 'Ministry', availableMinistries),
        FilterField.dropdown('district', 'District', availableDistricts),
        FilterField.dropdown('region', 'Region', availableRegions),
        FilterField.boolean('emergency_only', 'Emergency Only'),
        FilterField.boolean('active_only', 'Active Only'),
      ],
      initialValues: {
        'search': searchQuery.value,
        'ministry': selectedMinistry.value,
        'district': selectedDistrict.value,
        'region': selectedRegion.value,
        'emergency_only': showEmergencyOnly.value,
        'active_only': showActiveOnly.value,
      },
    );

    if (result == null || !result.hasValues) return;

    final v = result.values;

    searchQuery.value = v['search'] ?? '';
    selectedMinistry.value = v['ministry'] ?? '';
    selectedDistrict.value = v['district'] ?? '';
    selectedRegion.value = v['region'] ?? '';
    showEmergencyOnly.value = v['emergency_only'] ?? false;
    showActiveOnly.value = v['active_only'] ?? true;

    _updateActiveFilters();
    _refresh();
  }

  // ================= HELPERS =================

  void _refresh() => pagingController.refresh();

  void _updateActiveFilters() {
    hasActiveFilters.value =
        searchQuery.value.isNotEmpty ||
        selectedMinistry.value.isNotEmpty ||
        selectedDistrict.value.isNotEmpty ||
        selectedRegion.value.isNotEmpty ||
        selectedDepartment.value.isNotEmpty ||
        selectedStatus.value.isNotEmpty ||
        showEmergencyOnly.value ||
        !showActiveOnly.value;
  }

  void _applyTreeFiltersFromArguments() {
    final args = Get.arguments;
    if (args is! Map) return;

    final filters = Map<String, dynamic>.from(args['treeFilters'] ?? {});
    treeFilters.assignAll(filters);

    selectedMinistry.value = _s(filters, 'ministry');
    selectedDistrict.value = _s(filters, 'district');
    selectedRegion.value = _s(filters, 'region');
    selectedDepartment.value = _s(filters, 'department');
    selectedStatus.value = _s(filters, 'status');

    showEmergencyOnly.value =
        filters['emergency_only'] == true ||
        filters['priority_level']?.toString() == '1';

    _updateActiveFilters();
  }

  String _s(Map<String, dynamic> map, String key) =>
      (map[key] ?? '').toString().trim();
}
