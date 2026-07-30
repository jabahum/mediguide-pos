import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../data/models/models.dart';
import '../../data/models/filter_models.dart';
import '../../data/services/backend_api_service.dart';
import '../../utils/common.dart';
import '../../utils/constants.dart';
import '../../widgets/generic_filter_bottom_sheet.dart';

class ToolsController extends GetxController {
  final BackendApiService _apiService = BackendApiService.to;

  late final PagingController<int, Calculator> pagingController;

  final hasActiveFilters = false.obs;

  final searchQuery = ''.obs;
  final selectedTypes = <CalculatorType>[].obs;
  final selectedStatuses = <CalculatorStatus>[].obs;
  final selectedTabIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _initPaging();
    _handleArgs();
  }

  void _handleArgs() {
    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      final tab = args['initialTab'];
      if (tab is int && tab >= 0 && tab <= 3) {
        selectedTabIndex.value = tab;
        _updateFilterState();
      }
    }
  }

  void _initPaging() {
    pagingController = PagingController<int, Calculator>(
      getNextPageKey: (state) =>
          state.lastPageIsEmpty ? null : state.nextIntPageKey,
      fetchPage: _fetchPage,
    );
  }

  // ================================
  // FETCH
  // ================================
  Future<List<Calculator>> _fetchPage(int page) async {
    try {
      final filter = _buildFilter();

      final result = await _apiService.getRecordList(
        collectionName: Calculator.collection,
        page: page,
        perPage: pageSize,
        filter: filter.isEmpty ? null : filter,
        sort: '-created',
        expand: 'addedBy',
      );

      return result.items.map((r) => Calculator.fromRecord(r)).toList();
    } catch (e) {
      Common.quickToast(title: 'Failed to load calculators');
      rethrow;
    }
  }

  // ================================
  // FILTER ENGINE (FIXED)
  // ================================
  String _buildFilter() {
    final parts = <String>[];

    // search
    if (searchQuery.value.isNotEmpty) {
      final q = BackendApiService.escapeFilterValue(searchQuery.value);
      parts.add('(name ~ "$q" || description ~ "$q")');
    }

    // tab filter
    final tabType = _getTabType(selectedTabIndex.value);
    if (tabType != null) {
      parts.add('type = "${_typeToString(tabType)}"');
    }

    // multi type filter
    if (selectedTypes.isNotEmpty) {
      final types = selectedTypes
          .map((t) => 'type = "${_typeToString(t)}"')
          .join(' || ');
      parts.add('($types)');
    }

    // status filter
    if (selectedStatuses.isNotEmpty) {
      final statuses = selectedStatuses
          .map((s) => 'status = "${_statusToString(s)}"')
          .join(' || ');
      parts.add('($statuses)');
    } else {
      parts.add('status = "active"');
    }

    return parts.join(' && ');
  }

  // ================================
  // EVENTS
  // ================================
  void refreshData() => pagingController.refresh();

  void onTabChanged(int index) {
    selectedTabIndex.value = index;
    _updateFilterState();
    pagingController.refresh();
  }

  // ================================
  // FILTER MODAL
  // ================================
  Future<void> showFilterModal(BuildContext context) async {
    final fields = <FilterField>[
      FilterField.text('search', 'Search'),
      FilterField.multiSelect(
        'types',
        'Calculator Type',
        CalculatorType.values.map((e) => e.name).toList(),
      ),
      FilterField.multiSelect(
        'statuses',
        'Status',
        CalculatorStatus.values.map((e) => e.name).toList(),
      ),
    ];

    final result = await GenericFilterBottomSheet.show(
      context: context,
      title: 'Filter Calculators',
      fields: fields,
      initialValues: {
        'search': searchQuery.value,
        'types': selectedTypes.map((e) => e.name).toList(),
        'statuses': selectedStatuses.map((e) => e.name).toList(),
      },
    );

    if (result != null && result.isNotEmpty) {
      _applyFilters(result);
    }
  }

  void _applyFilters(FilterResult result) {
    searchQuery.value = '';

    selectedTypes.clear();
    selectedStatuses.clear();

    final search = result.getValue<String>('search');
    if (search != null) searchQuery.value = search;

    final types = result.getValue<List>('types');
    if (types != null) {
      selectedTypes.addAll(
        types.map((e) => CalculatorType.values.firstWhere((t) => t.name == e)),
      );
    }

    final statuses = result.getValue<List>('statuses');
    if (statuses != null) {
      selectedStatuses.addAll(
        statuses.map(
          (e) => CalculatorStatus.values.firstWhere((s) => s.name == e),
        ),
      );
    }

    _updateFilterState();
    pagingController.refresh();
  }

  void clearAllFilters() {
    searchQuery.value = '';
    selectedTypes.clear();
    selectedStatuses.clear();
    selectedTabIndex.value = 0;

    _updateFilterState();
    pagingController.refresh();
  }

  // ================================
  // STATE
  // ================================
  void _updateFilterState() {
    hasActiveFilters.value =
        searchQuery.value.isNotEmpty ||
        selectedTypes.isNotEmpty ||
        selectedStatuses.isNotEmpty ||
        selectedTabIndex.value > 0;
  }

  // ================================
  // TAB MAPPING
  // ================================
  CalculatorType? _getTabType(int tab) {
    switch (tab) {
      case 1:
        return CalculatorType.calculator;
      case 2:
        return CalculatorType.decisionTool;
      case 3:
        return CalculatorType.checklist;
      default:
        return null;
    }
  }

  String _typeToString(CalculatorType t) => switch (t) {
    CalculatorType.calculator => 'calculator',
    CalculatorType.decisionTool => 'decision_tool',
    CalculatorType.checklist => 'checklist',
  };

  String _statusToString(CalculatorStatus s) => switch (s) {
    CalculatorStatus.active => 'active',
    CalculatorStatus.draft => 'draft',
    CalculatorStatus.archived => 'archived',
  };

  // ================================
  // API LAYER
  // ================================
  Future<List<Calculator>> getCalculators({
    int page = 1,
    int perPage = 30,
    String? filter,
    String? sort,
    String? expand,
  }) async {
    final result = await _apiService.getRecordList(
      collectionName: Calculator.collection,
      page: page,
      perPage: perPage,
      filter: filter,
      sort: sort,
      expand: expand,
    );

    return result.items.map((e) => Calculator.fromRecord(e)).toList();
  }
}
