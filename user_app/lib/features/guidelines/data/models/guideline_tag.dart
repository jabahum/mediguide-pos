import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:user_app/core/utils/json_converters.dart';

part 'guideline_tag.freezed.dart';
part 'guideline_tag.g.dart';

@freezed
abstract class GuidelineTag with _$GuidelineTag {
  const GuidelineTag._();

  const factory GuidelineTag({
    required String id,
    @Default('') String name,
    @Default('') String description,
    @JsonKey(name: 'created_at')
    @NullableDateTimeConverter()
    DateTime? createdAt,
    @JsonKey(name: 'updated_at')
    @NullableDateTimeConverter()
    DateTime? updatedAt,
  }) = _GuidelineTag;

  factory GuidelineTag.fromJson(Map<String, dynamic> json) =>
      _$GuidelineTagFromJson(json);

  String get displayName => name;
  bool get hasDescription => description.isNotEmpty;
}

@freezed
abstract class CreateGuidelineTagRequest with _$CreateGuidelineTagRequest {
  @JsonSerializable(includeIfNull: false)
  const factory CreateGuidelineTagRequest({
    required String name,
    String? description,
  }) = _CreateGuidelineTagRequest;

  factory CreateGuidelineTagRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateGuidelineTagRequestFromJson(json);
}
