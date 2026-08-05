import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:user_app/core/utils/json_converters.dart';
import 'package:user_app/shared/models/common_enums.dart';

part 'drug_tag.freezed.dart';
part 'drug_tag.g.dart';

@freezed
abstract class DrugTag with _$DrugTag {
  const factory DrugTag({
    required String id,
    @Default('') String name,
    @Default('') String description,
    @Default('') String color,
    @JsonKey(name: 'tag_category') @Default('') String tagCategory,
    @JsonKey(name: 'sort_order') @Default(0) int sortOrder,
    @JsonKey(unknownEnumValue: Status.unknown)
    @Default(Status.active)
    Status status,
    @JsonKey(name: 'created_at')
    @NullableDateTimeConverter()
    DateTime? createdAt,
    @JsonKey(name: 'updated_at')
    @NullableDateTimeConverter()
    DateTime? updatedAt,
  }) = _DrugTag;

  factory DrugTag.fromJson(Map<String, dynamic> json) =>
      _$DrugTagFromJson(json);
}

@freezed
abstract class CreateDrugTagRequest with _$CreateDrugTagRequest {
  @JsonSerializable(includeIfNull: false)
  const factory CreateDrugTagRequest({
    required String name,
    String? description,
    String? color,
    @JsonKey(name: 'tag_category') String? tagCategory,
    @JsonKey(name: 'sort_order') int? sortOrder,
    Status? status,
  }) = _CreateDrugTagRequest;

  factory CreateDrugTagRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateDrugTagRequestFromJson(json);
}
