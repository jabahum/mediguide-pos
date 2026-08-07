import 'package:user_app/features/content/presentation/controllers/ministry_directory_query.dart';

final class MinistryDirectoryState {
  const MinistryDirectoryState({
    this.query = MinistryDirectoryQuery.empty,
    this.availableMinistries = const [],
    this.availableDistricts = const [],
    this.availableRegions = const [],
    this.isLoadingFilters = false,
    this.filterError,
  });

  final MinistryDirectoryQuery query;

  final List<String> availableMinistries;
  final List<String> availableDistricts;
  final List<String> availableRegions;

  final bool isLoadingFilters;
  final String? filterError;

  bool get hasActiveFilters => query.hasActiveFilters;

  String get searchQuery => query.search;
  String get selectedMinistry => query.selectedMinistry;
  String get selectedDistrict => query.selectedDistrict;
  String get selectedRegion => query.selectedRegion;
  String get selectedDepartment => query.selectedDepartment;
  String get selectedStatus => query.selectedStatus;

  bool get showEmergencyOnly => query.showEmergencyOnly;
  bool get showActiveOnly => query.showActiveOnly;

  Map<String, dynamic> get treeFilters => query.treeFilters;

  MinistryDirectoryState copyWith({
    MinistryDirectoryQuery? query,
    List<String>? availableMinistries,
    List<String>? availableDistricts,
    List<String>? availableRegions,
    bool? isLoadingFilters,
    String? filterError,
    bool clearFilterError = false,
  }) {
    return MinistryDirectoryState(
      query: query ?? this.query,
      availableMinistries: availableMinistries ?? this.availableMinistries,
      availableDistricts: availableDistricts ?? this.availableDistricts,
      availableRegions: availableRegions ?? this.availableRegions,
      isLoadingFilters: isLoadingFilters ?? this.isLoadingFilters,
      filterError: clearFilterError ? null : filterError ?? this.filterError,
    );
  }
}
