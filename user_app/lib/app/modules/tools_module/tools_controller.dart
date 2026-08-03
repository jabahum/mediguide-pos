import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../data/models/models.dart';
import '../../data/models/filter_models.dart';
import '../../data/repositories/calculator_repository.dart';
import '../../providers/core_providers.dart';
import '../../utils/common.dart';
import '../../utils/constants.dart';
import '../../widgets/generic_filter_bottom_sheet.dart';

final toolsControllerProvider = ChangeNotifierProvider.autoDispose
    .family<ToolsController, Object?>((ref, arguments) {
      return ToolsController(
        ref.watch(calculatorRepositoryProvider),
        arguments,
      );
    });

class ToolsController extends ChangeNotifier {
  ToolsController(this._repository, Object? arguments) {
    _initPaging();
    _handleArgs(arguments);
  }

  final CalculatorRepository _repository;

  late final PagingController<int, Calculator> pagingController;

  bool hasActiveFilters = false;

  String searchQuery = '';
  List<CalculatorType> selectedTypes = [];
  List<CalculatorStatus> selectedStatuses = [];
  int selectedTabIndex = 0;

  void _handleArgs(Object? args) {
    if (args is Map<String, dynamic>) {
      final tab = args['initialTab'];
      if (tab is int && tab >= 0 && tab <= 3) {
        selectedTabIndex = tab;
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
      final tabType = _getTabType(selectedTabIndex);
      final types = selectedTypes.isNotEmpty
          ? selectedTypes.map(_typeToString).toList()
          : tabType == null
          ? <String>[]
          : [_typeToString(tabType)];
      final statuses = selectedStatuses.isNotEmpty
          ? selectedStatuses.map(_statusToString).toList()
          : const ['active'];
      final result = await _repository.list(
        page: page,
        perPage: pageSize,
        search: searchQuery,
        types: types,
        statuses: statuses,
        sort: 'created_at',
        order: 'desc',
      );

      return result.items.map((r) => Calculator.fromRecord(r)).toList();
    } catch (e) {
      Common.quickToast(title: 'Failed to load calculators');
      rethrow;
    }
  }

  // ================================
  // EVENTS
  // ================================
  void refreshData() => pagingController.refresh();

  void onTabChanged(int index) {
    selectedTabIndex = index;
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
        'search': searchQuery,
        'types': selectedTypes.map((e) => e.name).toList(),
        'statuses': selectedStatuses.map((e) => e.name).toList(),
      },
    );

    if (result != null && result.isNotEmpty) {
      _applyFilters(result);
    }
  }

  void _applyFilters(FilterResult result) {
    searchQuery = '';

    selectedTypes.clear();
    selectedStatuses.clear();

    final search = result.getValue<String>('search');
    if (search != null) searchQuery = search;

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
    searchQuery = '';
    selectedTypes.clear();
    selectedStatuses.clear();
    selectedTabIndex = 0;

    _updateFilterState();
    pagingController.refresh();
  }

  // ================================
  // STATE
  // ================================
  void _updateFilterState() {
    hasActiveFilters =
        searchQuery.isNotEmpty ||
        selectedTypes.isNotEmpty ||
        selectedStatuses.isNotEmpty ||
        selectedTabIndex > 0;
    notifyListeners();
  }

  @override
  void dispose() {
    pagingController.dispose();
    super.dispose();
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
}
