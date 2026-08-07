import 'package:user_app/features/guidelines/presentation/controllers/guidelines_query.dart';
import 'package:user_app/features/guidelines/presentation/controllers/guidelines_route_state.dart';
import 'package:user_app/shared/models/models.dart';

final class GuidelinesState {
  const GuidelinesState({
    this.query = GuidelinesQuery.empty,
    this.route = const GuidelinesRouteState(),
    this.availableCategories = const [],
    this.availableTags = const [],
    this.isLoadingFilters = false,
    this.filterError,
  });

  final GuidelinesQuery query;
  final GuidelinesRouteState route;

  final List<GuidelineCategory> availableCategories;
  final List<GuidelineTag> availableTags;

  final bool isLoadingFilters;
  final String? filterError;

  bool get hasActiveFilters => query.hasActiveFilters;

  bool get hasPermanentFilter => route.hasPermanentFilter;

  String get effectivePageTitle => route.effectivePageTitle;

  bool get isEmergencyRoute => route.isEmergencyRoute;

  GuidelinesState copyWith({
    GuidelinesQuery? query,
    GuidelinesRouteState? route,
    List<GuidelineCategory>? availableCategories,
    List<GuidelineTag>? availableTags,
    bool? isLoadingFilters,
    String? filterError,
    bool clearFilterError = false,
  }) {
    return GuidelinesState(
      query: query ?? this.query,
      route: route ?? this.route,
      availableCategories: availableCategories ?? this.availableCategories,
      availableTags: availableTags ?? this.availableTags,
      isLoadingFilters: isLoadingFilters ?? this.isLoadingFilters,
      filterError: clearFilterError ? null : filterError ?? this.filterError,
    );
  }
}
