import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:user_app/core/utils/json_converters.dart';
import 'package:user_app/features/guidelines/data/models/guideline_category.dart';
import 'package:user_app/features/guidelines/data/models/guideline_tag.dart';

part 'abbreviation.freezed.dart';
part 'abbreviation.g.dart';

@Freezed(makeCollectionsUnmodifiable: true)
abstract class Abbreviation with _$Abbreviation {
  const Abbreviation._();
  @JsonSerializable(explicitToJson: true)
  const factory Abbreviation({
    required String id,
    @Default('') String abbreviation,
    @Default('') String meaning,
    @Default('') String description,
    @JsonKey(name: 'common_usage') @Default(false) bool commonUsage,
    @JsonKey(name: 'category_id') @Default('') String categoryId,
    GuidelineCategory? category,
    @Default([]) List<GuidelineTag> tags,
    @JsonKey(name: 'usage_count') @Default(0) int usageCount,
    @JsonKey(name: 'created_at')
    @NullableDateTimeConverter()
    DateTime? createdAt,
    @JsonKey(name: 'updated_at')
    @NullableDateTimeConverter()
    DateTime? updatedAt,
  }) = _Abbreviation;

  factory Abbreviation.fromJson(Map<String, dynamic> json) =>
      _$AbbreviationFromJson(_normalizeAbbreviation(json));

  bool get hasCategory => categoryId.isNotEmpty || category != null;
  bool get hasTags => tags.isNotEmpty;
  bool get hasDescription => description.isNotEmpty;
  bool get isCommon => commonUsage;
  String get displayAbbreviation => abbreviation.toUpperCase();
  String get categoryName => category?.displayName ?? '';
  String get categoryColor => category?.color ?? '';
  String get categoryIcon => category?.icon ?? '';
  List<String> get tagNames => tags.map((tag) => tag.displayName).toList();
  String get searchString =>
      '${abbreviation.toLowerCase()} ${meaning.toLowerCase()} ${description.toLowerCase()} ${categoryName.toLowerCase()} ${tagNames.join(' ').toLowerCase()}';
  bool matchesSearch(String query) =>
      query.isEmpty || searchString.contains(query.toLowerCase());
}

Map<String, dynamic> _normalizeAbbreviation(Map<String, dynamic> json) {
  final categories = json['categories'];
  final category = json['category'];
  final firstCategory = categories is List && categories.isNotEmpty
      ? categories.first
      : null;
  final categoryId =
      json['category_id'] ??
      (category is Map ? category['id'] : null) ??
      (firstCategory is Map ? firstCategory['id'] : null);
  List<Map<String, dynamic>> relations(Object? raw) => raw is List
      ? raw
            .map(
              (value) => value is Map
                  ? Map<String, dynamic>.from(value)
                  : {'id': '', 'name': value.toString()},
            )
            .toList()
      : [];
  return {
    ...json,
    'category_id': categoryId?.toString() ?? '',
    'category': category is Map
        ? Map<String, dynamic>.from(category)
        : firstCategory == null
        ? null
        : firstCategory is Map
        ? Map<String, dynamic>.from(firstCategory)
        : {'id': '', 'name': firstCategory.toString()},
    'tags': relations(json['tags']),
  };
}

@freezed
abstract class AbbreviationRequest with _$AbbreviationRequest {
  @JsonSerializable(includeIfNull: false)
  const factory AbbreviationRequest({
    String? abbreviation,
    String? meaning,
    String? description,
    @JsonKey(name: 'common_usage') bool? commonUsage,
    @JsonKey(name: 'category_id') String? categoryId,
    @JsonKey(name: 'tag_ids') List<String>? tagIds,
  }) = _AbbreviationRequest;
  factory AbbreviationRequest.fromJson(Map<String, dynamic> json) =>
      _$AbbreviationRequestFromJson(json);
}
