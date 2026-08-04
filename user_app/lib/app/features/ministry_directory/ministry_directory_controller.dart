import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:user_app/app/data/models/filter_models.dart';

import '../../data/models/models.dart';
import '../../data/repositories/facility_repository.dart';
import '../../data/repositories/content_reference_repository.dart';
import '../../core/di/core_providers.dart';
import '../../utils/constants.dart';
import '../../utils/common.dart';
import '../../widgets/generic_filter_bottom_sheet.dart';

final ministryDirectoryControllerProvider = ChangeNotifierProvider.autoDispose(
  (ref) => MinistryDirectoryController(
    ref.watch(facilityRepositoryProvider),
    ref.watch(ministryDirectoryRepositoryProvider),
  ),
);

class MinistryDirectoryController extends ChangeNotifier {
  MinistryDirectoryController(
    this._facilityRepository,
    this._directoryRepository,
  ) {
    pagingController = PagingController<int, MinistryDirectory>(
      getNextPageKey: (state) =>
          state.lastPageIsEmpty ? null : state.nextIntPageKey,
      fetchPage: _loadPage,
    );
    _loadFilterOptions();
  }

  final FacilityRepository _facilityRepository;
  final MinistryDirectoryRepository _directoryRepository;
  final Map<String, String> _districtIds = {};
  final Map<String, String> _regionIds = {};

  // ================= PAGINATION =================
  late final PagingController<int, MinistryDirectory> pagingController;

  // ================= FILTER STATE =================
  final Map<String, dynamic> treeFilters = {};

  String searchQuery = '';
  String selectedMinistry = '';
  String selectedDistrict = '';
  String selectedRegion = '';
  String selectedDepartment = '';
  String selectedStatus = '';

  bool showEmergencyOnly = false;
  bool showActiveOnly = true;

  bool hasActiveFilters = false;

  // ================= OPTIONS =================
  List<String> availableMinistries = [];
  List<String> availableDistricts = [];
  List<String> availableRegions = [];

  bool isLoadingFilters = false;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    pagingController.dispose();
    super.dispose();
  }

  // ================= DATA LOADING =================

  Future<List<MinistryDirectory>> _loadPage(int pageKey) async {
    try {
      final result = await _directoryRepository.list(
        page: pageKey,
        perPage: pageSize,
        search: searchQuery,
        ministry: selectedMinistry,
        department: selectedDepartment,
        districtId: _districtIds[selectedDistrict] ?? selectedDistrict,
        regionId: _regionIds[selectedRegion] ?? selectedRegion,
        status: selectedStatus.isNotEmpty
            ? selectedStatus
            : showActiveOnly
            ? 'active'
            : null,
      );
      var items = result.items;
      if (showEmergencyOnly) {
        items = items.where((entry) => entry.isEmergencyContact).toList();
      }
      return items;
    } catch (e) {
      Common.quickToast(
        title: 'Error loading directory',
        description: e.toString(),
      );
      rethrow;
    }
  }

  // ================= FILTER BUILDING =================

  // ================= FILTER OPTIONS =================

  Future<void> _loadFilterOptions() async {
    try {
      isLoadingFilters = true;
      _notify();

      availableMinistries = Ministry.values.map((e) => e.label).toList();

      final districts = await _facilityRepository.districts(perPage: 500);

      _districtIds
        ..clear()
        ..addEntries(
          districts.items.map((e) => MapEntry(e.data['name'] as String, e.id)),
        );
      availableDistricts = _districtIds.keys.toList();

      final regions = await _facilityRepository.regions(perPage: 500);

      _regionIds
        ..clear()
        ..addEntries(
          regions.items.map((e) => MapEntry(e.data['name'] as String, e.id)),
        );
      availableRegions = _regionIds.keys.toList();
    } catch (e) {
      Common.quickToast(
        title: 'Error loading filters',
        description: e.toString(),
      );
    } finally {
      isLoadingFilters = false;
      _notify();
    }
  }

  // ================= ACTIONS =================

  void onSearchQueryChanged(String query) {
    searchQuery = query.trim();
    _updateActiveFilters();
    _refresh();
  }

  void resetFilters() {
    searchQuery = '';
    selectedMinistry = '';
    selectedDistrict = '';
    selectedRegion = '';
    selectedDepartment = '';
    selectedStatus = '';
    showEmergencyOnly = false;
    showActiveOnly = true;
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
        'search': searchQuery,
        'ministry': selectedMinistry,
        'district': selectedDistrict,
        'region': selectedRegion,
        'emergency_only': showEmergencyOnly,
        'active_only': showActiveOnly,
      },
    );

    if (result == null || !result.hasValues) return;

    final v = result.values;

    searchQuery = v['search'] ?? '';
    selectedMinistry = v['ministry'] ?? '';
    selectedDistrict = v['district'] ?? '';
    selectedRegion = v['region'] ?? '';
    showEmergencyOnly = v['emergency_only'] ?? false;
    showActiveOnly = v['active_only'] ?? true;

    _updateActiveFilters();
    _refresh();
  }

  // ================= HELPERS =================

  void _refresh() => pagingController.refresh();

  void _updateActiveFilters() {
    hasActiveFilters =
        searchQuery.isNotEmpty ||
        selectedMinistry.isNotEmpty ||
        selectedDistrict.isNotEmpty ||
        selectedRegion.isNotEmpty ||
        selectedDepartment.isNotEmpty ||
        selectedStatus.isNotEmpty ||
        showEmergencyOnly ||
        !showActiveOnly;
    _notify();
  }

  void applyTreeFilters(Map<String, dynamic> filters) {
    treeFilters
      ..clear()
      ..addAll(filters);

    selectedMinistry = _s(filters, 'ministry');
    selectedDistrict = _s(filters, 'district');
    selectedRegion = _s(filters, 'region');
    selectedDepartment = _s(filters, 'department');
    selectedStatus = _s(filters, 'status');

    showEmergencyOnly =
        filters['emergency_only'] == true ||
        filters['priority_level']?.toString() == '1';

    _updateActiveFilters();
    _refresh();
  }

  String _s(Map<String, dynamic> map, String key) =>
      (map[key] ?? '').toString().trim();

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}
