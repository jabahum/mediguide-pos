import 'dart:async';

import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/core/config/app_keys.dart';
import 'package:user_app/core/constants/app_constants.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:user_app/core/utils/app_message.dart';

import 'package:user_app/features/consultants/data/repositories/consultant_repository.dart';
import 'package:user_app/features/consultants/presentation/controllers/consultants_query.dart';
import 'package:user_app/features/consultants/presentation/controllers/consultants_state.dart';
import 'package:user_app/features/consultants/presentation/widgets/consultant_detail_modal.dart';

import 'package:user_app/shared/models/filter_models.dart';
import 'package:user_app/shared/models/models.dart';
import 'package:user_app/shared/widgets/generic_filter_bottom_sheet.dart';

part 'consultants_controller.g.dart';

@riverpod
class ConsultantsController extends _$ConsultantsController {
  late final PagingController<int, Consultant> pagingController;

  ConsultantRepository get _repository =>
      ref.read(consultantRepositoryProvider);

  @override
  ConsultantsState build(Object? arguments) {
    final initialQuery = ConsultantsQuery.fromArguments(arguments);

    pagingController = PagingController<int, Consultant>(
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

    return ConsultantsState(query: initialQuery);
  }

  // ======================================================
  // DATA LOADING
  // ======================================================

  Future<List<Consultant>> _loadPage(int pageKey) async {
    try {
      final query = state.query;

      final result = await _repository.list(
        page: pageKey,
        perPage: AppConstants.pageSize,
        search: query.search,
        status: query.showOnlineOnly ? 'active' : null,
        specialty: query.selectedSpecialty,
        region: query.selectedRegion,
        city: query.selectedCity,
        verified: query.showVerifiedOnly ? true : null,
        sort: 'rating',
        order: 'desc',
      );

      return result.items;
    } catch (error) {
      _showError(error.toString());

      rethrow;
    }
  }

  // ======================================================
  // REFRESH
  // ======================================================

  void refreshData() {
    pagingController.refresh();
  }

  // ======================================================
  // SEARCH
  // ======================================================

  void searchConsultants(String value) {
    state = state.copyWith(query: state.query.copyWith(search: value.trim()));

    pagingController.refresh();
  }

  // ======================================================
  // FILTERS
  // ======================================================

  void clearAllFilters() {
    state = state.copyWith(query: ConsultantsQuery.empty);

    pagingController.refresh();
  }

  void setOnlineOnly(bool value) {
    state = state.copyWith(query: state.query.copyWith(showOnlineOnly: value));

    pagingController.refresh();
  }

  void setVerifiedOnly(bool value) {
    state = state.copyWith(
      query: state.query.copyWith(showVerifiedOnly: value),
    );

    pagingController.refresh();
  }

  void setSpecialty(String value) {
    state = state.copyWith(
      query: state.query.copyWith(selectedSpecialty: value.trim()),
    );

    pagingController.refresh();
  }

  void setLocation(String value) {
    final location = value.trim();

    state = state.copyWith(
      query: state.query.copyWith(
        selectedLocation: location,
        selectedCity: location,
      ),
    );

    pagingController.refresh();
  }

  // ======================================================
  // FILTER MODAL
  // ======================================================

  Future<void> showFilterModal(BuildContext context) async {
    if (!context.mounted) {
      return;
    }

    final query = state.query;

    final fields = <FilterField>[
      FilterField.text('search', 'search'.tr),
      FilterField.boolean('showOnlineOnly', 'showOnlineOnly'.tr),
      FilterField.boolean('showVerifiedOnly', 'showVerifiedOnly'.tr),
    ];

    if (state.availableSpecialties.isNotEmpty) {
      fields.add(
        FilterField.dropdown('specialty', 'specialty'.tr, [
          '',
          ...state.availableSpecialties,
        ]),
      );
    }

    if (state.availableLocations.isNotEmpty) {
      fields.add(
        FilterField.dropdown('location', 'location'.tr, [
          '',
          ...state.availableLocations,
        ]),
      );
    }

    final initialValues = <String, dynamic>{
      if (query.search.isNotEmpty) 'search': query.search,

      if (query.showOnlineOnly) 'showOnlineOnly': true,

      if (query.showVerifiedOnly) 'showVerifiedOnly': true,

      if (query.selectedSpecialty.isNotEmpty)
        'specialty': query.selectedSpecialty,

      if (query.selectedLocation.isNotEmpty) 'location': query.selectedLocation,
    };

    final result = await GenericFilterBottomSheet.show(
      context: context,
      title: 'filterConsultants'.tr,
      fields: fields,
      initialValues: initialValues,
    );

    if (result == null) {
      return;
    }

    _applyFilters(result);
  }

  void _applyFilters(FilterResult result) {
    state = state.copyWith(query: state.query.applyFilterResult(result));

    pagingController.refresh();
  }

  // ======================================================
  // TREE FILTERS
  // ======================================================

  void applyTreeFilters(Map<String, dynamic> filters) {
    final region = _read(filters, 'region');

    final city = _read(filters, 'city');

    final specialty = _read(filters, 'specialty');

    state = state.copyWith(
      query: state.query.copyWith(
        selectedRegion: region,
        selectedCity: city,
        selectedSpecialty: specialty,
        treeFilters: Map<String, dynamic>.from(filters),
      ),
    );

    pagingController.refresh();
  }

  void clearTreeFilters() {
    state = state.copyWith(
      query: state.query.copyWith(
        selectedRegion: '',
        selectedCity: '',
        treeFilters: const {},
      ),
    );

    pagingController.refresh();
  }

  String _read(Map<String, dynamic> map, String key) {
    return map[key]?.toString().trim() ?? '';
  }

  // ======================================================
  // CONSULTANT DETAILS
  // ======================================================

  Future<void> showConsultantDetail(
    BuildContext context,
    Consultant consultant,
  ) async {
    if (!context.mounted) {
      return;
    }

    unawaited(_recordUsage(consultant.id));

    await ConsultantDetailModal.show(context, consultant);
  }

  Future<void> _recordUsage(String id) async {
    try {
      await _repository.recordUsage(id);
    } catch (_) {
      // Analytics must never block consultant details.
    }
  }

  // ======================================================
  // FILTER OPTIONS
  // ======================================================

  Future<void> _loadFilterOptions() async {
    state = state.copyWith(isLoadingFilters: true, clearFilterError: true);

    try {
      final result = await _repository.list(
        perPage: 100,
        status: 'active',
        sort: 'name',
        order: 'asc',
      );

      final consultants = result.items;

      final specialties =
          consultants
              .map((consultant) => consultant.specialty?.name.trim() ?? '')
              .where((value) => value.isNotEmpty)
              .toSet()
              .toList()
            ..sort();

      final locations =
          consultants
              .map((consultant) => consultant.city.trim())
              .where((value) => value.isNotEmpty)
              .toSet()
              .toList()
            ..sort();

      state = state.copyWith(
        availableSpecialties: List<String>.unmodifiable(specialties),
        availableLocations: List<String>.unmodifiable(locations),
      );
    } catch (_) {
      final message = 'errorLoadingFilters'.tr;

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
