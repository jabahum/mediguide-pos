import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:user_app/core/utils/json_converters.dart';

part 'guideline_index.freezed.dart';
part 'guideline_index.g.dart';

@freezed
abstract class GuidelineIndex with _$GuidelineIndex {
  const GuidelineIndex._();

  const factory GuidelineIndex({
    required String id,
    @Default('') String title,
    @Default('') String description,
    @JsonKey(name: 'parent_id') String? parentId,
    @JsonKey(name: 'parent_title') String? parentTitle,
    @JsonKey(name: 'sort_order') @Default(0) int order,
    @Default(0) int level,
    @JsonKey(name: 'has_children') @Default(false) bool hasChildren,
    @JsonKey(name: 'created_at')
    @NullableDateTimeConverter()
    DateTime? createdAt,
    @JsonKey(name: 'updated_at')
    @NullableDateTimeConverter()
    DateTime? updatedAt,
  }) = _GuidelineIndex;

  factory GuidelineIndex.fromJson(Map<String, dynamic> json) =>
      _$GuidelineIndexFromJson(json);

  bool get hasParent => parentId?.isNotEmpty == true;
  bool get isRoot => !hasParent;
  String get displayTitle => title;
  bool get isBlueBranch =>
      title == 'Blue Channel' || parentTitle == 'Blue Channel';
  bool get isRedBranch =>
      title == 'Red Channel' || parentTitle == 'Red Channel';
}

@freezed
abstract class CreateGuidelineIndexRequest with _$CreateGuidelineIndexRequest {
  @JsonSerializable(includeIfNull: false)
  const factory CreateGuidelineIndexRequest({
    required String title,
    String? description,
    @JsonKey(name: 'parent_id') String? parentId,
    @JsonKey(name: 'sort_order') int? sortOrder,
    int? level,
  }) = _CreateGuidelineIndexRequest;

  factory CreateGuidelineIndexRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateGuidelineIndexRequestFromJson(json);
}
