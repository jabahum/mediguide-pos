// guidelines_tree_filter.dart

final class GuidelinesTreeFilter {
  const GuidelinesTreeFilter({
    this.search = '',
    this.level,
    this.showOnlyParents = false,
  });

  static const empty = GuidelinesTreeFilter();

  final String search;
  final int? level;
  final bool showOnlyParents;

  bool get hasFilters =>
      search.trim().isNotEmpty || level != null || showOnlyParents;

  GuidelinesTreeFilter copyWith({
    String? search,
    int? level,
    bool? showOnlyParents,
    bool clearLevel = false,
  }) {
    return GuidelinesTreeFilter(
      search: search ?? this.search,
      level: clearLevel ? null : level ?? this.level,
      showOnlyParents: showOnlyParents ?? this.showOnlyParents,
    );
  }
}
