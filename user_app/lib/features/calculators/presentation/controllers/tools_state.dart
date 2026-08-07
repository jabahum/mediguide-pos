import 'package:user_app/features/calculators/data/models/calculator_enums.dart';
import 'package:user_app/features/calculators/presentation/controllers/tools_query.dart';

final class ToolsState {
  const ToolsState({this.query = ToolsQuery.empty});

  final ToolsQuery query;

  bool get hasActiveFilters => query.hasFilters;

  String get searchQuery => query.search;

  List<CalculatorType> get selectedTypes => query.selectedTypes;

  List<CalculatorStatus> get selectedStatuses => query.selectedStatuses;

  int get selectedTabIndex => query.selectedTabIndex;

  ToolsState copyWith({ToolsQuery? query}) {
    return ToolsState(query: query ?? this.query);
  }
}
