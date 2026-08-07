import 'package:user_app/features/calculators/data/models/calculator_enums.dart';

final class ToolsQuery {
  const ToolsQuery({
    this.search = '',
    this.selectedTypes = const [],
    this.selectedStatuses = const [],
    this.selectedTabIndex = 0,
  });

  final String search;
  final List<CalculatorType> selectedTypes;
  final List<CalculatorStatus> selectedStatuses;
  final int selectedTabIndex;

  bool get hasFilters =>
      search.isNotEmpty ||
      selectedTypes.isNotEmpty ||
      selectedStatuses.isNotEmpty ||
      selectedTabIndex > 0;

  ToolsQuery copyWith({
    String? search,
    List<CalculatorType>? selectedTypes,
    List<CalculatorStatus>? selectedStatuses,
    int? selectedTabIndex,
  }) {
    return ToolsQuery(
      search: search ?? this.search,
      selectedTypes: selectedTypes ?? this.selectedTypes,
      selectedStatuses: selectedStatuses ?? this.selectedStatuses,
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
    );
  }

  static const empty = ToolsQuery();
}
