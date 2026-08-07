// faq_state.dart

final class FaqState {
  const FaqState({this.searchQuery = ''});

  final String searchQuery;

  bool get hasActiveFilters => searchQuery.isNotEmpty;

  FaqState copyWith({String? searchQuery}) {
    return FaqState(searchQuery: searchQuery ?? this.searchQuery);
  }
}
