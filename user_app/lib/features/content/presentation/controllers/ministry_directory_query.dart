final class MinistryDirectoryQuery {
  const MinistryDirectoryQuery({
    this.search = '',
    this.selectedMinistry = '',
    this.selectedDistrict = '',
    this.selectedRegion = '',
    this.selectedDepartment = '',
    this.selectedStatus = '',
    this.showEmergencyOnly = false,
    this.showActiveOnly = true,
    this.treeFilters = const {},
  });

  static const empty = MinistryDirectoryQuery();

  final String search;
  final String selectedMinistry;
  final String selectedDistrict;
  final String selectedRegion;
  final String selectedDepartment;
  final String selectedStatus;

  final bool showEmergencyOnly;
  final bool showActiveOnly;

  final Map<String, dynamic> treeFilters;

  bool get hasActiveFilters =>
      search.isNotEmpty ||
      selectedMinistry.isNotEmpty ||
      selectedDistrict.isNotEmpty ||
      selectedRegion.isNotEmpty ||
      selectedDepartment.isNotEmpty ||
      selectedStatus.isNotEmpty ||
      showEmergencyOnly ||
      !showActiveOnly;

  MinistryDirectoryQuery copyWith({
    String? search,
    String? selectedMinistry,
    String? selectedDistrict,
    String? selectedRegion,
    String? selectedDepartment,
    String? selectedStatus,
    bool? showEmergencyOnly,
    bool? showActiveOnly,
    Map<String, dynamic>? treeFilters,
  }) {
    return MinistryDirectoryQuery(
      search: search ?? this.search,
      selectedMinistry: selectedMinistry ?? this.selectedMinistry,
      selectedDistrict: selectedDistrict ?? this.selectedDistrict,
      selectedRegion: selectedRegion ?? this.selectedRegion,
      selectedDepartment: selectedDepartment ?? this.selectedDepartment,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      showEmergencyOnly: showEmergencyOnly ?? this.showEmergencyOnly,
      showActiveOnly: showActiveOnly ?? this.showActiveOnly,
      treeFilters: treeFilters ?? this.treeFilters,
    );
  }

  factory MinistryDirectoryQuery.fromTreeFilters(Map<String, dynamic> filters) {
    return MinistryDirectoryQuery(
      selectedMinistry: _read(filters, 'ministry'),
      selectedDistrict: _read(filters, 'district'),
      selectedRegion: _read(filters, 'region'),
      selectedDepartment: _read(filters, 'department'),
      selectedStatus: _read(filters, 'status'),
      showEmergencyOnly:
          filters['emergency_only'] == true ||
          filters['priority_level']?.toString() == '1',
      treeFilters: Map<String, dynamic>.from(filters),
    );
  }

  static String _read(Map<String, dynamic> map, String key) {
    return (map[key] ?? '').toString().trim();
  }
}
