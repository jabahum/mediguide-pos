import 'dart:async';

import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/core/config/app_keys.dart';
import 'package:user_app/core/constants/app_constants.dart';
import 'package:user_app/core/utils/app_message.dart';

import 'package:user_app/features/content/data/repositories/content_reference_repository.dart';
import 'package:user_app/features/content/presentation/controllers/ministry_directory_query.dart';
import 'package:user_app/features/content/presentation/controllers/ministry_directory_state.dart';

import 'package:user_app/features/facilities/data/repositories/facility_repository.dart';

import 'package:user_app/shared/models/filter_models.dart';
import 'package:user_app/shared/models/models.dart';
import 'package:user_app/shared/widgets/generic_filter_bottom_sheet.dart';

part 'ministry_directory_controller.g.dart';

@riverpod
class MinistryDirectoryController extends _$MinistryDirectoryController {
  late final PagingController<int, MinistryDirectory> pagingController;

  final Map<String, String> _districtIds = {};
  final Map<String, String> _regionIds = {};

  FacilityRepository get _facilityRepository =>
      ref.read(facilityRepositoryProvider);

  MinistryDirectoryRepository get _directoryRepository =>
      ref.read(ministryDirectoryRepositoryProvider);

  @override
  MinistryDirectoryState build() {
    pagingController = PagingController<int, MinistryDirectory>(
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

    return const MinistryDirectoryState();
  }

  // ======================================================
  // DATA LOADING
  // ======================================================

  Future<List<MinistryDirectory>> _loadPage(int pageKey) async {
    try {
      final query = state.query;

      final result = await _directoryRepository.list(
        page: pageKey,
        perPage: AppConstants.pageSize,
        search: query.search,
        ministry: query.selectedMinistry,
        department: query.selectedDepartment,
        districtId:
            _districtIds[query.selectedDistrict] ?? query.selectedDistrict,
        regionId: _regionIds[query.selectedRegion] ?? query.selectedRegion,
        status: query.selectedStatus.isNotEmpty
            ? query.selectedStatus
            : query.showActiveOnly
            ? 'active'
            : null,
      );

      var items = result.items;

      if (query.showEmergencyOnly) {
        items = items
            .where((entry) => entry.isEmergencyContact)
            .toList(growable: false);
      }

      return items;
    } catch (error) {
      _showError(error.toString());
      rethrow;
    }
  }

  // ======================================================
  // FILTER OPTIONS
  // ======================================================

  Future<void> _loadFilterOptions() async {
    state = state.copyWith(isLoadingFilters: true, clearFilterError: true);

    try {
      final ministries = Ministry.values
          .map((value) => value.label)
          .toList(growable: false);

      final districts = await _facilityRepository.districts(perPage: 500);
      final regions = await _facilityRepository.regions(perPage: 500);

      _districtIds
        ..clear()
        ..addEntries(
          districts.items.map((item) => MapEntry(item.name, item.id)),
        );

      _regionIds
        ..clear()
        ..addEntries(regions.items.map((item) => MapEntry(item.name, item.id)));

      final districtNames = _districtIds.keys.toList()..sort();

      final regionNames = _regionIds.keys.toList()..sort();

      state = state.copyWith(
        availableMinistries: List<String>.unmodifiable(ministries),
        availableDistricts: List<String>.unmodifiable(districtNames),
        availableRegions: List<String>.unmodifiable(regionNames),
      );
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

  // ======================================================
  // SEARCH
  // ======================================================

  void onSearchQueryChanged(String value) {
    state = state.copyWith(query: state.query.copyWith(search: value.trim()));

    _refresh();
  }

  // ======================================================
  // RESET
  // ======================================================

  void resetFilters() {
    state = state.copyWith(query: MinistryDirectoryQuery.empty);

    _refresh();
  }

  // ======================================================
  // ADVANCED FILTER
  // ======================================================

  Future<void> showAdvancedFilter(BuildContext context) async {
    if (!context.mounted) {
      return;
    }

    final query = state.query;

    final result = await GenericFilterBottomSheet.show(
      context: context,
      title: 'Filter Directory',
      fields: [
        FilterField.text('search', 'Search'),
        FilterField.dropdown('ministry', 'Ministry', state.availableMinistries),
        FilterField.dropdown('district', 'District', state.availableDistricts),
        FilterField.dropdown('region', 'Region', state.availableRegions),
        FilterField.boolean('emergency_only', 'Emergency Only'),
        FilterField.boolean('active_only', 'Active Only'),
      ],
      initialValues: {
        if (query.search.isNotEmpty) 'search': query.search,
        if (query.selectedMinistry.isNotEmpty)
          'ministry': query.selectedMinistry,
        if (query.selectedDistrict.isNotEmpty)
          'district': query.selectedDistrict,
        if (query.selectedRegion.isNotEmpty) 'region': query.selectedRegion,
        'emergency_only': query.showEmergencyOnly,
        'active_only': query.showActiveOnly,
      },
    );

    if (result == null || !result.hasValues) {
      return;
    }

    final values = result.values;

    state = state.copyWith(
      query: state.query.copyWith(
        search: values['search']?.toString().trim() ?? '',
        selectedMinistry: values['ministry']?.toString().trim() ?? '',
        selectedDistrict: values['district']?.toString().trim() ?? '',
        selectedRegion: values['region']?.toString().trim() ?? '',
        showEmergencyOnly: values['emergency_only'] == true,
        showActiveOnly: values['active_only'] is bool
            ? values['active_only'] as bool
            : true,
      ),
    );

    _refresh();
  }

  // ======================================================
  // TREE FILTERS
  // ======================================================

  void applyTreeFilters(Map<String, dynamic> filters) {
    state = state.copyWith(
      query: MinistryDirectoryQuery.fromTreeFilters(filters),
    );

    _refresh();
  }

  void clearTreeFilters() {
    state = state.copyWith(
      query: state.query.copyWith(
        selectedMinistry: '',
        selectedDistrict: '',
        selectedRegion: '',
        selectedDepartment: '',
        selectedStatus: '',
        showEmergencyOnly: false,
        treeFilters: const {},
      ),
    );

    _refresh();
  }

  // ======================================================
  // MANUAL FILTER SETTERS
  // ======================================================

  void setMinistry(String value) {
    state = state.copyWith(
      query: state.query.copyWith(selectedMinistry: value.trim()),
    );

    _refresh();
  }

  void setDistrict(String value) {
    state = state.copyWith(
      query: state.query.copyWith(selectedDistrict: value.trim()),
    );

    _refresh();
  }

  void setRegion(String value) {
    state = state.copyWith(
      query: state.query.copyWith(selectedRegion: value.trim()),
    );

    _refresh();
  }

  void setDepartment(String value) {
    state = state.copyWith(
      query: state.query.copyWith(selectedDepartment: value.trim()),
    );

    _refresh();
  }

  void setStatus(String value) {
    state = state.copyWith(
      query: state.query.copyWith(selectedStatus: value.trim()),
    );

    _refresh();
  }

  void setEmergencyOnly(bool value) {
    state = state.copyWith(
      query: state.query.copyWith(showEmergencyOnly: value),
    );

    _refresh();
  }

  void setActiveOnly(bool value) {
    state = state.copyWith(query: state.query.copyWith(showActiveOnly: value));

    _refresh();
  }

  // ======================================================
  // REFRESH
  // ======================================================

  void refreshData() {
    _refresh();
  }

  void refresh() {
    refreshData();
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
