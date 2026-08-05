import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:user_app/core/utils/json_converters.dart';

part 'guideline_category.freezed.dart';
part 'guideline_category.g.dart';

enum GuidelineCategoryStatus {
  @JsonValue('active')
  active,
  @JsonValue('inactive')
  inactive,
  @JsonValue('unknown')
  unknown,
}

@freezed
abstract class GuidelineCategory with _$GuidelineCategory {
  const GuidelineCategory._();

  const factory GuidelineCategory({
    required String id,
    @Default('') String name,
    @Default('') String slug,
    @Default('') String description,
    @JsonKey(name: 'sort_order') @Default(0) int sortOrder,
    @Default('') String color,
    @Default('') String icon,
    @JsonKey(name: 'parent_category_id') String? parentCategoryId,
    @JsonKey(name: 'parent_name') String? parentName,
    @Default(GuidelineCategoryStatus.active) GuidelineCategoryStatus status,
    @JsonKey(name: 'created_at')
    @NullableDateTimeConverter()
    DateTime? createdAt,
    @JsonKey(name: 'updated_at')
    @NullableDateTimeConverter()
    DateTime? updatedAt,
  }) = _GuidelineCategory;

  factory GuidelineCategory.fromJson(Map<String, dynamic> json) =>
      _$GuidelineCategoryFromJson(_normalizeCategory(json));

  bool get hasParent => parentCategoryId?.isNotEmpty == true;
  bool get isActive => status == GuidelineCategoryStatus.active;
  String get displayName => name.isNotEmpty ? name : slug;
}

Map<String, dynamic> _normalizeCategory(Map<String, dynamic> json) {
  final status = json['status']?.toString();
  return {
    ...json,
    if (status != null && status != 'active' && status != 'inactive')
      'status': 'unknown',
  };
}

@freezed
abstract class CreateGuidelineCategoryRequest
    with _$CreateGuidelineCategoryRequest {
  @JsonSerializable(includeIfNull: false)
  const factory CreateGuidelineCategoryRequest({
    required String name,
    String? slug,
    String? description,
    @JsonKey(name: 'sort_order') int? sortOrder,
    GuidelineCategoryStatus? status,
    String? color,
    String? icon,
    @JsonKey(name: 'parent_category_id') String? parentCategoryId,
  }) = _CreateGuidelineCategoryRequest;

  factory CreateGuidelineCategoryRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateGuidelineCategoryRequestFromJson(json);
}
