import 'package:user_app/shared/models/filter_models.dart';

final class ConsultantsQuery {
  const ConsultantsQuery({
    this.search = '',
    this.selectedSpecialty = '',
    this.selectedLocation = '',
    this.selectedRegion = '',
    this.selectedCity = '',
    this.showOnlineOnly = false,
    this.showVerifiedOnly = false,
    this.treeFilters = const {},
  });

  static const empty = ConsultantsQuery();

  final String search;

  final String selectedSpecialty;
  final String selectedLocation;

  final String selectedRegion;
  final String selectedCity;

  final bool showOnlineOnly;
  final bool showVerifiedOnly;

  final Map<String, dynamic> treeFilters;

  bool get hasActiveFilters =>
      search.isNotEmpty ||
      selectedSpecialty.isNotEmpty ||
      selectedLocation.isNotEmpty ||
      selectedRegion.isNotEmpty ||
      selectedCity.isNotEmpty ||
      showOnlineOnly ||
      showVerifiedOnly;

  ConsultantsQuery copyWith({
    String? search,
    String? selectedSpecialty,
    String? selectedLocation,
    String? selectedRegion,
    String? selectedCity,
    bool? showOnlineOnly,
    bool? showVerifiedOnly,
    Map<String, dynamic>? treeFilters,
  }) {
    return ConsultantsQuery(
      search: search ?? this.search,
      selectedSpecialty: selectedSpecialty ?? this.selectedSpecialty,
      selectedLocation: selectedLocation ?? this.selectedLocation,
      selectedRegion: selectedRegion ?? this.selectedRegion,
      selectedCity: selectedCity ?? this.selectedCity,
      showOnlineOnly: showOnlineOnly ?? this.showOnlineOnly,
      showVerifiedOnly: showVerifiedOnly ?? this.showVerifiedOnly,
      treeFilters: treeFilters ?? this.treeFilters,
    );
  }

  ConsultantsQuery clear() {
    return ConsultantsQuery.empty;
  }

  ConsultantsQuery applyFilterResult(FilterResult result) {
    final search = result.getValue<String>('search')?.trim() ?? '';

    final specialty = result.getValue<String>('specialty')?.trim() ?? '';

    final location = result.getValue<String>('location')?.trim() ?? '';

    return ConsultantsQuery(
      search: search,
      selectedSpecialty: specialty,
      selectedLocation: location,
      selectedCity: location,
      showOnlineOnly: result.getValue<bool>('showOnlineOnly') ?? false,
      showVerifiedOnly: result.getValue<bool>('showVerifiedOnly') ?? false,

      // Modal filters intentionally replace tree-specific region/city state.
      selectedRegion: '',
      treeFilters: const {},
    );
  }

  factory ConsultantsQuery.fromArguments(Object? arguments) {
    if (arguments is! Map) {
      return ConsultantsQuery.empty;
    }

    final rawTreeFilters = arguments['treeFilters'];

    if (rawTreeFilters is! Map) {
      return ConsultantsQuery.empty;
    }

    final filters = Map<String, dynamic>.from(rawTreeFilters);

    return ConsultantsQuery(
      selectedRegion: _read(filters, 'region'),
      selectedCity: _read(filters, 'city'),
      selectedSpecialty: _read(filters, 'specialty'),
      treeFilters: filters,
    );
  }

  static String _read(Map<String, dynamic> map, String key) {
    return map[key]?.toString().trim() ?? '';
  }
}
