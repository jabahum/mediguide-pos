// drug_index_query.dart

final class DrugIndexQuery {
  const DrugIndexQuery({
    this.search = '',
    this.selectedCategories = const [],
    this.selectedTags = const [],
    this.selectedRoutes = const [],
    this.selectedPregnancyCategories = const [],
    this.whoEmlOnly = false,
    this.antimicrobialOnly = false,
  });

  static const empty = DrugIndexQuery();

  final String search;

  final List<String> selectedCategories;
  final List<String> selectedTags;
  final List<String> selectedRoutes;
  final List<String> selectedPregnancyCategories;

  final bool whoEmlOnly;
  final bool antimicrobialOnly;

  bool get hasActiveFilters =>
      search.isNotEmpty ||
      selectedCategories.isNotEmpty ||
      selectedTags.isNotEmpty ||
      selectedRoutes.isNotEmpty ||
      selectedPregnancyCategories.isNotEmpty ||
      whoEmlOnly ||
      antimicrobialOnly;

  DrugIndexQuery copyWith({
    String? search,
    List<String>? selectedCategories,
    List<String>? selectedTags,
    List<String>? selectedRoutes,
    List<String>? selectedPregnancyCategories,
    bool? whoEmlOnly,
    bool? antimicrobialOnly,
  }) {
    return DrugIndexQuery(
      search: search ?? this.search,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      selectedTags: selectedTags ?? this.selectedTags,
      selectedRoutes: selectedRoutes ?? this.selectedRoutes,
      selectedPregnancyCategories:
          selectedPregnancyCategories ?? this.selectedPregnancyCategories,
      whoEmlOnly: whoEmlOnly ?? this.whoEmlOnly,
      antimicrobialOnly: antimicrobialOnly ?? this.antimicrobialOnly,
    );
  }
}
