import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:user_app/core/utils/json_converters.dart';
import 'package:user_app/shared/models/common_enums.dart';

part 'therapeutic_category.freezed.dart';
part 'therapeutic_category.g.dart';

@freezed
abstract class TherapeuticCategory with _$TherapeuticCategory {
  const factory TherapeuticCategory({
    required String id,
    @Default('') String name,
    @Default('') String description,
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
  }) = _TherapeuticCategory;

  factory TherapeuticCategory.fromJson(Map<String, dynamic> json) =>
      _$TherapeuticCategoryFromJson(json);
}

@freezed
abstract class CreateTherapeuticCategoryRequest
    with _$CreateTherapeuticCategoryRequest {
  @JsonSerializable(includeIfNull: false)
  const factory CreateTherapeuticCategoryRequest({
    required String name,
    String? description,
    @JsonKey(name: 'sort_order') int? sortOrder,
    Status? status,
  }) = _CreateTherapeuticCategoryRequest;

  factory CreateTherapeuticCategoryRequest.fromJson(
    Map<String, dynamic> json,
  ) => _$CreateTherapeuticCategoryRequestFromJson(json);
}
