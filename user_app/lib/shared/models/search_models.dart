/// Enum representing different search categories
enum SearchCategory {
  all(value: 'all', displayName: 'All Results'),
  drugs(value: 'drugs', displayName: 'Drugs'),
  guidelines(value: 'guidelines', displayName: 'Guidelines'),
  consultants(value: 'consultants', displayName: 'Consultants'),
  healthFacilities(
    value: 'health_facilities',
    displayName: 'Health Facilities',
  ),
  abbreviations(value: 'abbreviations', displayName: 'Abbreviations'),
  faq(value: 'faq', displayName: 'FAQ'),
  outbreaks(value: 'outbreaks', displayName: 'Outbreaks'),
  situationReports(
    value: 'situation_reports',
    displayName: 'Situation Reports',
  ),
  tools(value: 'tools', displayName: 'Tools');

  const SearchCategory({required this.value, required this.displayName});

  final String value;
  final String displayName;

  static SearchCategory fromString(String value) {
    return SearchCategory.values.firstWhere(
      (category) => category.value == value,
      orElse: () => SearchCategory.all,
    );
  }
}

/// Model representing a search result item
class SearchResult {
  final String id;
  final String title;
  final String? subtitle;
  final String? description;
  final SearchCategory category;
  final String? route;
  final Map<String, dynamic>? routeArguments;
  final double relevanceScore;
  final bool isOffline;
  final bool isStale;
  final dynamic item; // Store the actual object (Drug, Guideline, etc.)

  const SearchResult({
    required this.id,
    required this.title,
    this.subtitle,
    this.description,
    required this.category,
    this.route,
    this.routeArguments,
    this.relevanceScore = 0.0,
    this.isOffline = false,
    this.isStale = false,
    this.item,
  });

  /// Create SearchResult from JSON
  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      description: json['description'] as String?,
      category: SearchCategory.fromString(json['category'] as String? ?? 'all'),
      route: json['route'] as String?,
      routeArguments: json['routeArguments'] as Map<String, dynamic>?,
      relevanceScore: (json['relevanceScore'] as num?)?.toDouble() ?? 0.0,
      isOffline: json['isOffline'] as bool? ?? false,
      isStale: json['isStale'] as bool? ?? false,
      item:
          json['item'], // Note: item is not serialized/deserialized as it's runtime-only
    );
  }

  /// Convert SearchResult to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'category': category.value,
      'route': route,
      'routeArguments': routeArguments,
      'relevanceScore': relevanceScore,
      'isOffline': isOffline,
      'isStale': isStale,
      // Note: item is not serialized as it's a runtime-only object
    };
  }

  /// Create a copy with modified properties
  SearchResult copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? description,
    SearchCategory? category,
    String? route,
    Map<String, dynamic>? routeArguments,
    double? relevanceScore,
    bool? isOffline,
    bool? isStale,
    dynamic item,
  }) {
    return SearchResult(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      category: category ?? this.category,
      route: route ?? this.route,
      routeArguments: routeArguments ?? this.routeArguments,
      relevanceScore: relevanceScore ?? this.relevanceScore,
      isOffline: isOffline ?? this.isOffline,
      isStale: isStale ?? this.isStale,
      item: item ?? this.item,
    );
  }

  /// Get the stored item as a specific type
  /// Returns null if the item is null or not of the expected type
  T? getItem<T>() {
    return item is T ? item as T : null;
  }

  /// Check if the stored item is of a specific type
  bool hasItem<T>() {
    return item is T;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchResult && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Model for search filters
class SearchFilter {
  final SearchCategory category;
  final String? dateFrom;
  final String? dateTo;
  final String? sortBy;
  final bool sortAscending;
  final int limit;
  final int offset;

  const SearchFilter({
    this.category = SearchCategory.all,
    this.dateFrom,
    this.dateTo,
    this.sortBy,
    this.sortAscending = false,
    this.limit = 20,
    this.offset = 0,
  });

  /// Create SearchFilter from JSON
  factory SearchFilter.fromJson(Map<String, dynamic> json) {
    return SearchFilter(
      category: SearchCategory.fromString(json['category'] as String? ?? 'all'),
      dateFrom: json['dateFrom'] as String?,
      dateTo: json['dateTo'] as String?,
      sortBy: json['sortBy'] as String?,
      sortAscending: json['sortAscending'] as bool? ?? false,
      limit: json['limit'] as int? ?? 20,
      offset: json['offset'] as int? ?? 0,
    );
  }

  /// Convert SearchFilter to JSON
  Map<String, dynamic> toJson() {
    return {
      'category': category.value,
      'dateFrom': dateFrom,
      'dateTo': dateTo,
      'sortBy': sortBy,
      'sortAscending': sortAscending,
      'limit': limit,
      'offset': offset,
    };
  }

  /// Create a copy with modified properties
  SearchFilter copyWith({
    SearchCategory? category,
    String? dateFrom,
    String? dateTo,
    String? sortBy,
    bool? sortAscending,
    int? limit,
    int? offset,
  }) {
    return SearchFilter(
      category: category ?? this.category,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchFilter &&
        other.category == category &&
        other.dateFrom == dateFrom &&
        other.dateTo == dateTo &&
        other.sortBy == sortBy &&
        other.sortAscending == sortAscending &&
        other.limit == limit &&
        other.offset == offset;
  }

  @override
  int get hashCode => Object.hash(
    category,
    dateFrom,
    dateTo,
    sortBy,
    sortAscending,
    limit,
    offset,
  );
}

/// Model for recent search item
class RecentSearch {
  final String query;
  final SearchCategory category;
  final DateTime timestamp;
  final int resultCount;

  const RecentSearch({
    required this.query,
    required this.category,
    required this.timestamp,
    this.resultCount = 0,
  });

  /// Create RecentSearch from JSON
  factory RecentSearch.fromJson(Map<String, dynamic> json) {
    return RecentSearch(
      query: json['query'] as String,
      category: SearchCategory.fromString(json['category'] as String? ?? 'all'),
      timestamp: DateTime.parse(json['timestamp'] as String),
      resultCount: json['resultCount'] as int? ?? 0,
    );
  }

  /// Convert RecentSearch to JSON
  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'category': category.value,
      'timestamp': timestamp.toIso8601String(),
      'resultCount': resultCount,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RecentSearch &&
        other.query == query &&
        other.category == category &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode => Object.hash(query, category, timestamp);
}

/// Model for search suggestions
class SearchSuggestion {
  final String text;
  final SearchCategory category;
  final int popularity;
  final String? description;

  const SearchSuggestion({
    required this.text,
    required this.category,
    this.popularity = 0,
    this.description,
  });

  /// Create SearchSuggestion from JSON
  factory SearchSuggestion.fromJson(Map<String, dynamic> json) {
    return SearchSuggestion(
      text: json['text'] as String,
      category: SearchCategory.fromString(json['category'] as String? ?? 'all'),
      popularity: json['popularity'] as int? ?? 0,
      description: json['description'] as String?,
    );
  }

  /// Convert SearchSuggestion to JSON
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'category': category.value,
      'popularity': popularity,
      'description': description,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchSuggestion &&
        other.text == text &&
        other.category == category;
  }

  @override
  int get hashCode => Object.hash(text, category);
}
