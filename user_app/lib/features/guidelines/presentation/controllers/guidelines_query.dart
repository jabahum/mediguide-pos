final class GuidelinesQuery {
  const GuidelinesQuery({
    this.search = '',
    this.selectedCategoryId = '',
    this.selectedTagIds = const [],
    this.selectedPriority = '',
    this.selectedHealthcareLevel = '',
    this.selectedTargetPopulation = '',
    this.showHighPriorityOnly = false,
  });

  static const empty = GuidelinesQuery();

  final String search;
  final String selectedCategoryId;
  final List<String> selectedTagIds;
  final String selectedPriority;
  final String selectedHealthcareLevel;
  final String selectedTargetPopulation;
  final bool showHighPriorityOnly;

  bool get hasActiveFilters =>
      search.trim().isNotEmpty ||
      selectedCategoryId.isNotEmpty ||
      selectedTagIds.isNotEmpty ||
      selectedPriority.isNotEmpty ||
      selectedHealthcareLevel.isNotEmpty ||
      selectedTargetPopulation.isNotEmpty ||
      showHighPriorityOnly;

  GuidelinesQuery copyWith({
    String? search,
    String? selectedCategoryId,
    List<String>? selectedTagIds,
    String? selectedPriority,
    String? selectedHealthcareLevel,
    String? selectedTargetPopulation,
    bool? showHighPriorityOnly,
  }) {
    return GuidelinesQuery(
      search: search ?? this.search,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      selectedTagIds: selectedTagIds ?? this.selectedTagIds,
      selectedPriority: selectedPriority ?? this.selectedPriority,
      selectedHealthcareLevel:
          selectedHealthcareLevel ?? this.selectedHealthcareLevel,
      selectedTargetPopulation:
          selectedTargetPopulation ?? this.selectedTargetPopulation,
      showHighPriorityOnly: showHighPriorityOnly ?? this.showHighPriorityOnly,
    );
  }
}
