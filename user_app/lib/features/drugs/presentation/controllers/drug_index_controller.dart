// drug_index_controller.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/app/router/app_navigator.dart';
import 'package:user_app/core/config/app_keys.dart';
import 'package:user_app/core/constants/app_constants.dart';
import 'package:user_app/core/utils/app_extensions.dart';
import 'package:user_app/core/utils/app_message.dart';

import 'package:user_app/features/calculators/data/repositories/calculator_repository.dart';
import 'package:user_app/features/drugs/data/repositories/drug_reference_repository.dart';
import 'package:user_app/features/drugs/presentation/controllers/drug_index_query.dart';
import 'package:user_app/features/drugs/presentation/controllers/drug_index_state.dart';
import 'package:user_app/features/drugs/presentation/widgets/drug_details_bottom_sheet.dart';

import 'package:user_app/l10n/app_translations.dart';
import 'package:user_app/shared/models/filter_models.dart';
import 'package:user_app/shared/models/models.dart';
import 'package:user_app/shared/widgets/generic_filter_bottom_sheet.dart';

part 'drug_index_controller.g.dart';

@riverpod
class DrugIndexController extends _$DrugIndexController {
  late final PagingController<int, Drug> pagingController;

  DrugReferenceRepository get _references =>
      ref.read(drugReferenceRepositoryProvider);

  DrugRepository get _drugs => ref.read(drugRepositoryProvider);

  @override
  DrugIndexState build() {
    pagingController = PagingController<int, Drug>(
      getNextPageKey: (pagingState) {
        if (pagingState.lastPageIsEmpty) {
          return null;
        }

        return pagingState.nextIntPageKey;
      },
      fetchPage: _fetchDrugsPage,
    );

    ref.onDispose(() {
      pagingController.dispose();
    });

    Future.microtask(_loadFilterOptions);

    return const DrugIndexState();
  }

  // ======================================================
  // PAGINATION
  // ======================================================

  Future<List<Drug>> _fetchDrugsPage(int pageKey) async {
    try {
      return getDrugs(page: pageKey, perPage: AppConstants.pageSize);
    } catch (_) {
      _showError('failedToLoadDrugs'.tr);

      rethrow;
    }
  }

  // ======================================================
  // FILTER OPTIONS
  // ======================================================

  Future<void> _loadFilterOptions() async {
    state = state.copyWith(isLoadingFilters: true, clearFilterError: true);

    try {
      final results = await Future.wait([
        _references.categoryNames(),
        _references.tagNames(),
      ]);

      final categories = results[0] as List<String>;

      final tags = results[1] as List<String>;

      const routes = <String>[
        'oral',
        'IV',
        'IM',
        'topical',
        'inhaled',
        'sublingual',
        'rectal',
        'transdermal',
        'intranasal',
        'subcutaneous',
      ];

      const pregnancyCategories = <String>['A', 'B', 'C', 'D', 'X', 'Unknown'];

      state = state.copyWith(
        categories: List<String>.unmodifiable(categories),
        tags: List<String>.unmodifiable(tags),
        routes: routes,
        pregnancyCategories: pregnancyCategories,
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
  // REFRESH
  // ======================================================

  Future<void> refreshData() async {
    pagingController.refresh();
  }

  // ======================================================
  // SEARCH
  // ======================================================

  void setSearchQuery(String value) {
    state = state.copyWith(query: state.query.copyWith(search: value.trim()));

    pagingController.refresh();
  }

  // ======================================================
  // CLEAR FILTERS
  // ======================================================

  void clearAllFilters() {
    state = state.copyWith(query: DrugIndexQuery.empty);

    pagingController.refresh();
  }

  // ======================================================
  // CATEGORY
  // ======================================================

  void toggleCategory(String value) {
    final values = [...state.query.selectedCategories];

    if (values.contains(value)) {
      values.remove(value);
    } else {
      values.add(value);
    }

    state = state.copyWith(
      query: state.query.copyWith(
        selectedCategories: List<String>.unmodifiable(values),
      ),
    );

    pagingController.refresh();
  }

  // ======================================================
  // TAG
  // ======================================================

  void toggleTag(String value) {
    final values = [...state.query.selectedTags];

    if (values.contains(value)) {
      values.remove(value);
    } else {
      values.add(value);
    }

    state = state.copyWith(
      query: state.query.copyWith(
        selectedTags: List<String>.unmodifiable(values),
      ),
    );

    pagingController.refresh();
  }

  // ======================================================
  // ROUTE
  // ======================================================

  void toggleRoute(String value) {
    final values = [...state.query.selectedRoutes];

    if (values.contains(value)) {
      values.remove(value);
    } else {
      values.add(value);
    }

    state = state.copyWith(
      query: state.query.copyWith(
        selectedRoutes: List<String>.unmodifiable(values),
      ),
    );

    pagingController.refresh();
  }

  // ======================================================
  // PREGNANCY CATEGORY
  // ======================================================

  void togglePregnancyCategory(String value) {
    final values = [...state.query.selectedPregnancyCategories];

    if (values.contains(value)) {
      values.remove(value);
    } else {
      values.add(value);
    }

    state = state.copyWith(
      query: state.query.copyWith(
        selectedPregnancyCategories: List<String>.unmodifiable(values),
      ),
    );

    pagingController.refresh();
  }

  // ======================================================
  // WHO EML
  // ======================================================

  void toggleWhoEml() {
    state = state.copyWith(
      query: state.query.copyWith(whoEmlOnly: !state.query.whoEmlOnly),
    );

    pagingController.refresh();
  }

  void setWhoEmlOnly(bool value) {
    state = state.copyWith(query: state.query.copyWith(whoEmlOnly: value));

    pagingController.refresh();
  }

  // ======================================================
  // ANTIMICROBIAL
  // ======================================================

  void toggleAntimicrobial() {
    state = state.copyWith(
      query: state.query.copyWith(
        antimicrobialOnly: !state.query.antimicrobialOnly,
      ),
    );

    pagingController.refresh();
  }

  void setAntimicrobialOnly(bool value) {
    state = state.copyWith(
      query: state.query.copyWith(antimicrobialOnly: value),
    );

    pagingController.refresh();
  }

  // ======================================================
  // FILTER MODAL
  // ======================================================

  Future<void> showFilterModal(BuildContext context) async {
    if (state.categories.isEmpty || state.tags.isEmpty) {
      await _loadFilterOptions();
    }

    if (!context.mounted) {
      return;
    }

    final query = state.query;

    final fields = <FilterField>[
      FilterField.text('search', 'search'.tr),
      FilterField.boolean('whoEmlOnly', AppTranslationKey.whoEmlOnly),
      FilterField.boolean(
        'antimicrobialOnly',
        AppTranslationKey.antimicrobialOnly,
      ),
      FilterField.multiSelect('categories', 'categories'.tr, state.categories),
      FilterField.multiSelect('tags', 'tags'.tr, state.tags),
      FilterField.multiSelect('routes', 'routes'.tr, state.routes),
      FilterField.multiSelect(
        'pregnancyCategories',
        'pregnancyCategories'.tr,
        state.pregnancyCategories,
      ),
    ];

    final initialValues = <String, dynamic>{
      if (query.search.isNotEmpty) 'search': query.search,

      if (query.whoEmlOnly) 'whoEmlOnly': true,

      if (query.antimicrobialOnly) 'antimicrobialOnly': true,

      if (query.selectedCategories.isNotEmpty)
        'categories': query.selectedCategories,

      if (query.selectedTags.isNotEmpty) 'tags': query.selectedTags,

      if (query.selectedRoutes.isNotEmpty) 'routes': query.selectedRoutes,

      if (query.selectedPregnancyCategories.isNotEmpty)
        'pregnancyCategories': query.selectedPregnancyCategories,
    };

    final result = await GenericFilterBottomSheet.show(
      context: context,
      title: AppTranslationKey.filterDrugs,
      fields: fields,
      initialValues: initialValues,
    );

    if (result == null) {
      return;
    }

    _applyFilters(result);
  }

  void _applyFilters(FilterResult result) {
    final search = result.getValue<String>('search')?.trim() ?? '';

    final categories = _stringList(result.getValue<List>('categories'));

    final tags = _stringList(result.getValue<List>('tags'));

    final routes = _stringList(result.getValue<List>('routes'));

    final pregnancyCategories = _stringList(
      result.getValue<List>('pregnancyCategories'),
    );

    state = state.copyWith(
      query: DrugIndexQuery(
        search: search,
        whoEmlOnly: result.getValue<bool>('whoEmlOnly') ?? false,
        antimicrobialOnly: result.getValue<bool>('antimicrobialOnly') ?? false,
        selectedCategories: categories,
        selectedTags: tags,
        selectedRoutes: routes,
        selectedPregnancyCategories: pregnancyCategories,
      ),
    );

    pagingController.refresh();
  }

  List<String> _stringList(List<dynamic>? values) {
    if (values == null) {
      return const [];
    }

    return List<String>.unmodifiable(
      values
          .map((value) => value.toString())
          .where((value) => value.isNotEmpty),
    );
  }

  // ======================================================
  // API
  // ======================================================

  Future<List<Drug>> getDrugs({int page = 1, int perPage = 30}) async {
    final query = state.query;

    final result = await _drugs.list(
      page: page,
      perPage: perPage,
      search: query.search,
      status: 'active',
      route: query.selectedRoutes.length == 1
          ? query.selectedRoutes.single
          : null,
      pregnancyCategory: query.selectedPregnancyCategories.length == 1
          ? query.selectedPregnancyCategories.single
          : null,
      whoEml: query.whoEmlOnly ? true : null,
      antimicrobial: query.antimicrobialOnly ? true : null,
    );

    var items = result.items;

    // The existing DrugRepository API only accepts one
    // route/pregnancy category. Preserve multi-select
    // behavior locally when multiple values are selected.
    if (query.selectedRoutes.length > 1) {
      final selected = query.selectedRoutes.toSet();

      items = items
          .where((drug) {
            final route = drug.route;

            return route != null && selected.contains(route);
          })
          .toList(growable: false);
    }

    if (query.selectedPregnancyCategories.length > 1) {
      final selected = query.selectedPregnancyCategories.toSet();

      items = items
          .where((drug) {
            final category = drug.pregnancyCategory;

            return category != null && selected.contains(category);
          })
          .toList(growable: false);
    }

    return items;
  }

  // ======================================================
  // DETAILS
  // ======================================================

  Future<void> navigateToDrugDetail(Drug drug) async {
    final context = AppNavigator.context;

    await DrugDetailsBottomSheet.show(context: context, drug: drug);
  }

  // ======================================================
  // BOOKMARK
  // ======================================================

  void toggleBookmark(Drug drug) {
    final context = AppKeys.navigatorKey.currentContext;

    if (context == null) {
      return;
    }

    AppMessage.success(context, 'Bookmark toggled for ${drug.name}');

    // TODO:
    // Replace with a bookmark repository/controller.
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
