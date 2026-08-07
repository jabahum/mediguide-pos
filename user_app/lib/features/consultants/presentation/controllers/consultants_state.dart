import 'package:user_app/features/consultants/presentation/controllers/consultants_query.dart';

final class ConsultantsState {
  const ConsultantsState({
    this.query = ConsultantsQuery.empty,
    this.availableSpecialties = const [],
    this.availableLocations = const [],
    this.isLoadingFilters = false,
    this.filterError,
  });

  final ConsultantsQuery query;

  final List<String> availableSpecialties;
  final List<String> availableLocations;

  final bool isLoadingFilters;

  final String? filterError;

  bool get hasActiveFilters => query.hasActiveFilters;

  String get searchQuery => query.search;

  String get selectedSpecialty => query.selectedSpecialty;

  String get selectedLocation => query.selectedLocation;

  String get selectedRegion => query.selectedRegion;

  String get selectedCity => query.selectedCity;

  bool get showOnlineOnly => query.showOnlineOnly;

  bool get showVerifiedOnly => query.showVerifiedOnly;

  Map<String, dynamic> get treeFilters => query.treeFilters;

  ConsultantsState copyWith({
    ConsultantsQuery? query,
    List<String>? availableSpecialties,
    List<String>? availableLocations,
    bool? isLoadingFilters,
    String? filterError,
    bool clearFilterError = false,
  }) {
    return ConsultantsState(
      query: query ?? this.query,
      availableSpecialties: availableSpecialties ?? this.availableSpecialties,
      availableLocations: availableLocations ?? this.availableLocations,
      isLoadingFilters: isLoadingFilters ?? this.isLoadingFilters,
      filterError: clearFilterError ? null : filterError ?? this.filterError,
    );
  }
}
