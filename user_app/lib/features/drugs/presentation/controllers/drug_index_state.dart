// drug_index_state.dart

import 'package:user_app/features/drugs/presentation/controllers/drug_index_query.dart';

final class DrugIndexState {
  const DrugIndexState({
    this.query = DrugIndexQuery.empty,
    this.categories = const [],
    this.tags = const [],
    this.routes = const [],
    this.pregnancyCategories = const [],
    this.isLoadingFilters = false,
    this.filterError,
  });

  final DrugIndexQuery query;

  final List<String> categories;
  final List<String> tags;
  final List<String> routes;
  final List<String> pregnancyCategories;

  final bool isLoadingFilters;
  final String? filterError;

  bool get hasActiveFilters => query.hasActiveFilters;

  String get searchQuery => query.search;

  List<String> get selectedCategories => query.selectedCategories;

  List<String> get selectedTags => query.selectedTags;

  List<String> get selectedRoutes => query.selectedRoutes;

  List<String> get selectedPregnancyCategories =>
      query.selectedPregnancyCategories;

  bool get whoEmlOnly => query.whoEmlOnly;

  bool get antimicrobialOnly => query.antimicrobialOnly;

  DrugIndexState copyWith({
    DrugIndexQuery? query,
    List<String>? categories,
    List<String>? tags,
    List<String>? routes,
    List<String>? pregnancyCategories,
    bool? isLoadingFilters,
    String? filterError,
    bool clearFilterError = false,
  }) {
    return DrugIndexState(
      query: query ?? this.query,
      categories: categories ?? this.categories,
      tags: tags ?? this.tags,
      routes: routes ?? this.routes,
      pregnancyCategories: pregnancyCategories ?? this.pregnancyCategories,
      isLoadingFilters: isLoadingFilters ?? this.isLoadingFilters,
      filterError: clearFilterError ? null : filterError ?? this.filterError,
    );
  }
}
