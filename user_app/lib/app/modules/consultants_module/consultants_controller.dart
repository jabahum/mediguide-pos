import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:user_app/app/data/models/filter_models.dart';

import '../../data/models/models.dart';
import '../../data/repositories/consultant_repository.dart';
import '../../providers/core_providers.dart';
import '../../utils/constants.dart';
import '../../utils/common.dart';
import '../../widgets/generic_filter_bottom_sheet.dart';
import 'widgets/consultant_detail_modal.dart';

final consultantsControllerProvider = ChangeNotifierProvider.autoDispose
    .family<ConsultantsController, Object?>((ref, arguments) {
      return ConsultantsController(
        ref.watch(consultantRepositoryProvider),
        arguments,
      );
    });

class ConsultantsController extends ChangeNotifier {
  ConsultantsController(this._repository, Object? arguments) {
    _applyTreeFiltersFromArguments(arguments);
    pagingController = PagingController<int, Consultant>(
      getNextPageKey: (state) =>
          state.lastPageIsEmpty ? null : state.nextIntPageKey,
      fetchPage: _loadPage,
    );
    unawaited(_loadFilterOptions());
  }

  final ConsultantRepository _repository;
  late final PagingController<int, Consultant> pagingController;

  // ================= FILTER STATE =================
  String searchQuery = '';
  bool hasActiveFilters = false;

  String selectedSpecialty = '';
  String selectedLocation = '';

  String selectedRegion = '';
  String selectedCity = '';

  bool showOnlineOnly = false;
  bool showVerifiedOnly = false;

  Map<String, dynamic> treeFilters = {};

  // options
  List<String> availableSpecialties = [];
  List<String> availableLocations = [];
  bool isLoadingFilters = false;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    pagingController.dispose();
    super.dispose();
  }

  // ================= DATA LOADING =================

  Future<List<Consultant>> _loadPage(int pageKey) async {
    try {
      final result = await _repository.list(
        page: pageKey,
        perPage: pageSize,
        search: searchQuery,
        status: showOnlineOnly ? 'active' : null,
        specialty: selectedSpecialty,
        region: selectedRegion,
        city: selectedCity,
        verified: showVerifiedOnly ? true : null,
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
    hasActiveFilters =
        searchQuery.isNotEmpty ||
        selectedSpecialty.isNotEmpty ||
        selectedLocation.isNotEmpty ||
        selectedRegion.isNotEmpty ||
        selectedCity.isNotEmpty ||
        showOnlineOnly ||
        showVerifiedOnly;
    if (!_disposed) notifyListeners();
  }

  void clearAllFilters() {
    searchQuery = '';
    selectedSpecialty = '';
    selectedLocation = '';
    selectedRegion = '';
    selectedCity = '';
    showOnlineOnly = false;
    showVerifiedOnly = false;
    treeFilters.clear();

    _updateHasActiveFilters();
    pagingController.refresh();
  }

  void searchConsultants(String query) {
    searchQuery = query.trim();
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
      if (searchQuery.isNotEmpty) 'search': searchQuery,
      if (showOnlineOnly) 'showOnlineOnly': true,
      if (showVerifiedOnly) 'showVerifiedOnly': true,
      if (selectedSpecialty.isNotEmpty) 'specialty': selectedSpecialty,
      if (selectedLocation.isNotEmpty) 'location': selectedLocation,
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

  void _applyFilters(FilterResult result) {
    searchQuery = '';
    selectedSpecialty = '';
    selectedLocation = '';
    selectedRegion = '';
    selectedCity = '';
    showOnlineOnly = false;
    showVerifiedOnly = false;

    final search = result.getValue<String>('search');
    if (search != null && search.isNotEmpty) {
      searchQuery = search;
    }

    if (result.getValue<bool>('showOnlineOnly') == true) {
      showOnlineOnly = true;
    }

    if (result.getValue<bool>('showVerifiedOnly') == true) {
      showVerifiedOnly = true;
    }

    final specialty = result.getValue<String>('specialty');
    if (specialty != null && specialty.isNotEmpty) {
      selectedSpecialty = specialty;
    }

    final location = result.getValue<String>('location');
    if (location != null && location.isNotEmpty) {
      selectedLocation = location;
      selectedCity = location;
    }

    _updateHasActiveFilters();
    pagingController.refresh();
  }

  // ================= TREE FILTERS =================

  void _applyTreeFiltersFromArguments(Object? args) {
    if (args is! Map) return;

    final raw = args['treeFilters'];
    if (raw is! Map) return;

    treeFilters = Map<String, dynamic>.from(raw);

    final region = _read(raw, 'region');
    final city = _read(raw, 'city');
    final specialty = _read(raw, 'specialty');

    selectedRegion = region;
    selectedCity = city;
    selectedSpecialty = specialty;

    _updateHasActiveFilters();
  }

  String _read(Map map, String key) => (map[key]?.toString().trim()) ?? '';

  // ================= DETAIL =================

  Future<void> showConsultantDetail(
    BuildContext context,
    Consultant consultant,
  ) async {
    unawaited(_recordUsage(consultant.id));
    await ConsultantDetailModal.show(context, consultant);
  }

  Future<void> _recordUsage(String id) async {
    try {
      await _repository.recordUsage(id);
    } catch (_) {
      // Analytics must not block consultant details.
    }
  }

  // ================= FILTER OPTIONS =================

  Future<void> _loadFilterOptions() async {
    try {
      isLoadingFilters = true;

      final result = await _repository.list(
        perPage: 100,
        status: 'active',
        sort: 'name',
        order: 'asc',
      );

      final consultants = result.items
          .map((r) => Consultant.fromRecord(r))
          .toList();

      availableSpecialties =
          consultants
              .map((c) => c.specialty?.name ?? '')
              .where((s) => s.isNotEmpty)
              .toSet()
              .toList()
            ..sort();

      availableLocations =
          consultants
              .map((c) => c.city)
              .where((c) => c.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
    } catch (e) {
      if (!_disposed) Common.quickToast(title: 'errorLoadingFilters'.tr);
    } finally {
      isLoadingFilters = false;
      if (!_disposed) notifyListeners();
    }
  }
}
