// ignore_for_file: unused_field

import 'package:user_app/shared/models/api_record.dart';
import 'package:user_app/shared/models/base_model.dart';
import 'package:user_app/features/guidelines/data/models/guideline_category.dart';
import 'package:user_app/features/guidelines/data/models/guideline_tag.dart';

/// Abbreviation model based on backend resource API abbreviations collection
class Abbreviation extends BaseModel {
  Abbreviation(super.data);

  /// backend resource API collection name
  static const String collection = 'abbreviations';

  // Self-registration for dynamic model creation
  static final _registered = (() {
    BaseModel.registerModel(collection, (data) => Abbreviation(data));
    return true;
  })();

  /// Create Abbreviation from backend resource API record
  static Abbreviation fromRecord(ApiRecord record) => Abbreviation(record.data);

  /// Create JSON for new abbreviation record (excludes system fields)
  static Map<String, dynamic> forCreate({
    required String abbreviation,
    required String meaning,
    String? description,
    bool? commonUsage,
    String? categoryId,
    List<String>? tagIds,
  }) {
    return {
      'abbreviation': abbreviation,
      'meaning': meaning,
      'description': ?description,
      'common_usage': commonUsage ?? false,
      'category': ?categoryId,
      if (tagIds != null && tagIds.isNotEmpty) 'tags': tagIds,
    };
  }

  // Direct properties - late final for performance
  late final String abbreviation = get<String>("abbreviation", "");
  late final String meaning = get<String>("meaning", "");
  late final String description = get<String>("description", "");
  late final bool commonUsage = get<bool>("common_usage", false);
  late final String categoryId = get<String>("category", "");
  late final List<String> tagIds = get<List<String>>("tags", <String>[]);

  // Relationship properties
  late final GuidelineCategory? category = _getCategory();
  late final List<GuidelineTag> tags = _getTags();

  /// Get category from expanded data
  GuidelineCategory? _getCategory() {
    final categoryData = get<Map<String, dynamic>>("expand.category");
    if (categoryData.isEmpty) return null;
    return GuidelineCategory.fromJson(categoryData);
  }

  /// Get tags from expanded data
  List<GuidelineTag> _getTags() {
    final tagsData = get<List<dynamic>>("expand.tags", <dynamic>[]);
    return tagsData
        .whereType<Map<String, dynamic>>()
        .map(GuidelineTag.fromJson)
        .toList();
  }

  /// Check if abbreviation has category
  bool get hasCategory => categoryId.isNotEmpty && category != null;

  /// Check if abbreviation has tags
  bool get hasTags => tagIds.isNotEmpty;

  /// Check if abbreviation has description
  bool get hasDescription => description.isNotEmpty;

  /// Check if this is a commonly used abbreviation
  bool get isCommon => commonUsage;

  /// Get display abbreviation (uppercase for consistency)
  String get displayAbbreviation => abbreviation.toUpperCase();

  /// Get category name or empty string
  String get categoryName => category?.displayName ?? "";

  /// Get category color or default
  String get categoryColor => category?.color ?? "";

  /// Get category icon or default
  String get categoryIcon => category?.icon ?? "";

  /// Get tag names as list of strings
  List<String> get tagNames => tags.map((tag) => tag.displayName).toList();

  /// Create a search string for filtering
  String get searchString =>
      "${abbreviation.toLowerCase()} ${meaning.toLowerCase()} ${description.toLowerCase()} ${categoryName.toLowerCase()} ${tagNames.join(' ').toLowerCase()}";

  /// Check if abbreviation matches search query
  bool matchesSearch(String query) {
    if (query.isEmpty) return true;
    return searchString.contains(query.toLowerCase());
  }
}
