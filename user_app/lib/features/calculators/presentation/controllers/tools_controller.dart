import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/core/config/app_keys.dart';
import 'package:user_app/core/constants/app_constants.dart';
import 'package:user_app/core/utils/app_message.dart';

import 'package:user_app/features/calculators/data/repositories/calculator_repository.dart';
import 'package:user_app/features/calculators/presentation/controllers/tools_query.dart';
import 'package:user_app/features/calculators/presentation/controllers/tools_state.dart';

import 'package:user_app/shared/models/filter_models.dart';
import 'package:user_app/shared/models/models.dart';
import 'package:user_app/shared/widgets/generic_filter_bottom_sheet.dart';

part 'tools_controller.g.dart';

/// ======================================================
/// CONTROLLER
/// ======================================================

@riverpod
class ToolsController extends _$ToolsController {
  late final PagingController<int, Calculator> pagingController;

  CalculatorRepository get _repository =>
      ref.read(calculatorRepositoryProvider);

  @override
  ToolsState build(Object? arguments) {
    final initialQuery = _queryFromArguments(arguments);

    pagingController = PagingController<int, Calculator>(
      getNextPageKey: (pagingState) {
        if (pagingState.lastPageIsEmpty) {
          return null;
        }

        return pagingState.nextIntPageKey;
      },
      fetchPage: _fetchPage,
    );

    ref.onDispose(() {
      pagingController.dispose();
    });

    return ToolsState(query: initialQuery);
  }

  /// ======================================================
  /// ARGUMENTS
  /// ======================================================

  ToolsQuery _queryFromArguments(Object? arguments) {
    if (arguments is! Map) {
      return ToolsQuery.empty;
    }

    final tab = arguments['initialTab'];

    if (tab is int && tab >= 0 && tab <= 3) {
      return ToolsQuery(selectedTabIndex: tab);
    }

    return ToolsQuery.empty;
  }

  /// ======================================================
  /// FETCH
  /// ======================================================

  Future<List<Calculator>> _fetchPage(int page) async {
    try {
      final query = state.query;

      final tabType = _getTabType(query.selectedTabIndex);

      final types = query.selectedTypes.isNotEmpty
          ? query.selectedTypes.map(_typeToString).toList(growable: false)
          : tabType == null
          ? <String>[]
          : <String>[_typeToString(tabType)];

      final statuses = query.selectedStatuses.isNotEmpty
          ? query.selectedStatuses.map(_statusToString).toList(growable: false)
          : const <String>['active'];

      final result = await _repository.list(
        page: page,
        perPage: AppConstants.pageSize,
        search: query.search,
        types: types,
        statuses: statuses,
        sort: 'created_at',
        order: 'desc',
      );

      return result.items;
    } catch (error) {
      _showError(error.toString());

      rethrow;
    }
  }

  /// ======================================================
  /// REFRESH
  /// ======================================================

  void refreshData() {
    pagingController.refresh();
  }

  /// ======================================================
  /// SEARCH
  /// ======================================================

  void updateSearch(String value) {
    state = state.copyWith(query: state.query.copyWith(search: value.trim()));

    pagingController.refresh();
  }

  /// ======================================================
  /// TAB
  /// ======================================================

  void onTabChanged(int index) {
    if (index < 0 || index > 3) {
      return;
    }

    state = state.copyWith(
      query: state.query.copyWith(selectedTabIndex: index),
    );

    pagingController.refresh();
  }

  /// ======================================================
  /// FILTER MODAL
  /// ======================================================

  Future<void> showFilterModal(BuildContext context) async {
    if (!context.mounted) {
      return;
    }

    final query = state.query;

    final fields = <FilterField>[
      FilterField.text('search', 'Search'),
      FilterField.multiSelect(
        'types',
        'Calculator Type',
        CalculatorType.values.map((type) => type.name).toList(growable: false),
      ),
      FilterField.multiSelect(
        'statuses',
        'Status',
        CalculatorStatus.values
            .map((status) => status.name)
            .toList(growable: false),
      ),
    ];

    final result = await GenericFilterBottomSheet.show(
      context: context,
      title: 'Filter Calculators',
      fields: fields,
      initialValues: {
        if (query.search.isNotEmpty) 'search': query.search,
        if (query.selectedTypes.isNotEmpty)
          'types': query.selectedTypes
              .map((type) => type.name)
              .toList(growable: false),
        if (query.selectedStatuses.isNotEmpty)
          'statuses': query.selectedStatuses
              .map((status) => status.name)
              .toList(growable: false),
      },
    );

    if (result == null) {
      return;
    }

    _applyFilters(result);
  }

  void _applyFilters(FilterResult result) {
    final search = result.getValue<String>('search')?.trim() ?? '';

    final typeValues = result.getValue<List>('types') ?? const [];

    final statusValues = result.getValue<List>('statuses') ?? const [];

    final types = typeValues
        .map(
          (value) => CalculatorType.values.firstWhere(
            (type) => type.name == value.toString(),
          ),
        )
        .toList(growable: false);

    final statuses = statusValues
        .map(
          (value) => CalculatorStatus.values.firstWhere(
            (status) => status.name == value.toString(),
          ),
        )
        .toList(growable: false);

    state = state.copyWith(
      query: state.query.copyWith(
        search: search,
        selectedTypes: types,
        selectedStatuses: statuses,
      ),
    );

    pagingController.refresh();
  }

  /// ======================================================
  /// FILTER HELPERS
  /// ======================================================

  void setTypes(List<CalculatorType> types) {
    state = state.copyWith(
      query: state.query.copyWith(
        selectedTypes: List<CalculatorType>.unmodifiable(types),
      ),
    );

    pagingController.refresh();
  }

  void setStatuses(List<CalculatorStatus> statuses) {
    state = state.copyWith(
      query: state.query.copyWith(
        selectedStatuses: List<CalculatorStatus>.unmodifiable(statuses),
      ),
    );

    pagingController.refresh();
  }

  void clearAllFilters() {
    state = const ToolsState(query: ToolsQuery.empty);

    pagingController.refresh();
  }

  /// ======================================================
  /// TAB MAPPING
  /// ======================================================

  CalculatorType? _getTabType(int tab) {
    return switch (tab) {
      1 => CalculatorType.calculator,
      2 => CalculatorType.decisionTool,
      3 => CalculatorType.checklist,
      _ => null,
    };
  }

  String _typeToString(CalculatorType type) {
    return switch (type) {
      CalculatorType.calculator => 'calculator',
      CalculatorType.decisionTool => 'decision_tool',
      CalculatorType.checklist => 'checklist',
    };
  }

  String _statusToString(CalculatorStatus status) {
    return switch (status) {
      CalculatorStatus.active => 'active',
      CalculatorStatus.draft => 'draft',
      CalculatorStatus.archived => 'archived',
    };
  }

  /// ======================================================
  /// ERRORS
  /// ======================================================

  void _showError(String message) {
    final context = AppKeys.navigatorKey.currentContext;

    if (context == null) {
      return;
    }

    AppMessage.error(context, message);
  }
}
