import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:user_app/app/data/models/filter_models.dart';

import '../../data/models/models.dart';
import '../../data/repositories/consultant_repository.dart';
import '../../data/services/backend_api_service.dart';
import '../../utils/constants.dart';
import '../../utils/common.dart';
import '../../widgets/generic_filter_bottom_sheet.dart';
import 'widgets/consultant_detail_modal.dart';

class ConsultantsController extends GetxController {
  ConsultantRepository get _repository =>
      ConsultantRepository(BackendApiService.to);
  late final PagingController<int, Consultant> pagingController;

  // ================= FILTER STATE =================
  final RxString searchQuery = ''.obs;
  final RxBool hasActiveFilters = false.obs;

  final RxString selectedSpecialty = ''.obs;
  final RxString selectedLocation = ''.obs;

  final RxString selectedRegion = ''.obs;
  final RxString selectedCity = ''.obs;

  final RxBool showOnlineOnly = false.obs;
  final RxBool showVerifiedOnly = false.obs;

  final RxMap<String, dynamic> treeFilters = <String, dynamic>{}.obs;

  // options
  final RxList<String> availableSpecialties = <String>[].obs;
  final RxList<String> availableLocations = <String>[].obs;
  final RxBool isLoadingFilters = false.obs;

  @override
  void onInit() {
    super.onInit();

    _applyTreeFiltersFromArguments();

    pagingController = PagingController<int, Consultant>(
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

  Future<List<Consultant>> _loadPage(int pageKey) async {
    try {
      final result = await _repository.list(
        page: pageKey,
        perPage: pageSize,
        search: searchQuery.value,
        status: showOnlineOnly.value ? 'active' : null,
        specialty: selectedSpecialty.value,
        region: selectedRegion.value,
        city: selectedCity.value,
        verified: showVerifiedOnly.value ? true : null,
        sort: 'rating',
        order: 'desc',
      );

      return result.items.map((r) => Consultant.fromRecord(r)).toList();
    } catch (e) {
      Common.quickToast(title: 'errorLoadingConsultants'.tr);
      rethrow;
    }
  }

  // ================= FILTER STATE HELPERS =================

  void _updateHasActiveFilters() {
    hasActiveFilters.value =
        searchQuery.value.isNotEmpty ||
        selectedSpecialty.value.isNotEmpty ||
        selectedLocation.value.isNotEmpty ||
        selectedRegion.value.isNotEmpty ||
        selectedCity.value.isNotEmpty ||
        showOnlineOnly.value ||
        showVerifiedOnly.value;
  }

  void clearAllFilters() {
    searchQuery.value = '';
    selectedSpecialty.value = '';
    selectedLocation.value = '';
    selectedRegion.value = '';
    selectedCity.value = '';
    showOnlineOnly.value = false;
    showVerifiedOnly.value = false;
    treeFilters.clear();

    _updateHasActiveFilters();
    pagingController.refresh();
  }

  void searchConsultants(String query) {
    searchQuery.value = query.trim();
    _updateHasActiveFilters();
    pagingController.refresh();
  }

  // ================= FILTER MODAL =================

  Future<void> showFilterModal(BuildContext context) async {
    final fields = <FilterField>[
      FilterField.text('search', 'search'.tr),
      FilterField.boolean('showOnlineOnly', 'showOnlineOnly'.tr),
      FilterField.boolean('showVerifiedOnly', 'showVerifiedOnly'.tr),
    ];

    if (availableSpecialties.isNotEmpty) {
      fields.add(
        FilterField.dropdown(
          'specialty',
          'specialty'.tr,
          [''] + availableSpecialties,
        ),
      );
    }

    if (availableLocations.isNotEmpty) {
      fields.add(
        FilterField.dropdown(
          'location',
          'location'.tr,
          [''] + availableLocations,
        ),
      );
    }

    final values = <String, dynamic>{
      if (searchQuery.value.isNotEmpty) 'search': searchQuery.value,
      if (showOnlineOnly.value) 'showOnlineOnly': true,
      if (showVerifiedOnly.value) 'showVerifiedOnly': true,
      if (selectedSpecialty.value.isNotEmpty)
        'specialty': selectedSpecialty.value,
      if (selectedLocation.value.isNotEmpty) 'location': selectedLocation.value,
    };

    final result = await GenericFilterBottomSheet.show(
      context: context,
      title: 'filterConsultants'.tr,
      fields: fields,
      initialValues: values,
    );

    if (result != null && result.isNotEmpty) {
      _applyFilters(result);
    }
  }

  void _applyFilters(dynamic result) {
    searchQuery.value = '';
    selectedSpecialty.value = '';
    selectedLocation.value = '';
    selectedRegion.value = '';
    selectedCity.value = '';
    showOnlineOnly.value = false;
    showVerifiedOnly.value = false;

    final search = result.getValue<String>('search');
    if (search != null && search.isNotEmpty) {
      searchQuery.value = search;
    }

    if (result.getValue<bool>('showOnlineOnly') == true) {
      showOnlineOnly.value = true;
    }

    if (result.getValue<bool>('showVerifiedOnly') == true) {
      showVerifiedOnly.value = true;
    }

    final specialty = result.getValue<String>('specialty');
    if (specialty != null && specialty.isNotEmpty) {
      selectedSpecialty.value = specialty;
    }

    final location = result.getValue<String>('location');
    if (location != null && location.isNotEmpty) {
      selectedLocation.value = location;
    }

    _updateHasActiveFilters();
    pagingController.refresh();
  }

  // ================= TREE FILTERS =================

  void _applyTreeFiltersFromArguments() {
    final args = Get.arguments;
    if (args is! Map) return;

    final raw = args['treeFilters'];
    if (raw is! Map) return;

    treeFilters.assignAll(Map<String, dynamic>.from(raw));

    final region = _read(raw, 'region');
    final city = _read(raw, 'city');
    final specialty = _read(raw, 'specialty');

    selectedRegion.value = region;
    selectedCity.value = city;
    selectedSpecialty.value = specialty;

    _updateHasActiveFilters();
  }

  String _read(Map map, String key) => (map[key]?.toString().trim()) ?? '';

  // ================= DETAIL =================

  Future<void> showConsultantDetail(
    BuildContext context,
    Consultant consultant,
  ) async {
    await ConsultantDetailModal.show(context, consultant);
  }

  // ================= FILTER OPTIONS =================

  Future<void> _loadFilterOptions() async {
    try {
      isLoadingFilters.value = true;

      final result = await _repository.list(
        perPage: 100,
        status: 'active',
        sort: 'name',
        order: 'asc',
      );

      final consultants = result.items
          .map((r) => Consultant.fromRecord(r))
          .toList();

      availableSpecialties.value =
          consultants
              .map((c) => c.specialty?.toString() ?? '')
              .where((s) => s.isNotEmpty)
              .toSet()
              .toList()
            ..sort();

      availableLocations.value =
          consultants
              .map((c) => c.city)
              .where((c) => c.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
    } catch (e) {
      Common.quickToast(title: 'errorLoadingFilters'.tr);
    } finally {
      isLoadingFilters.value = false;
    }
  }
}
