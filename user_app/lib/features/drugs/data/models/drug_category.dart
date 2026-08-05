import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:user_app/core/utils/json_converters.dart';
import 'package:user_app/shared/models/common_enums.dart';

part 'drug_category.freezed.dart';
part 'drug_category.g.dart';

@freezed
abstract class DrugCategory with _$DrugCategory {
  const DrugCategory._();

  const factory DrugCategory({
    required String id,
    @Default('') String name,
    @Default('') String description,
    @Default('') String color,
    @Default('') String icon,
    @JsonKey(name: 'sort_order') @Default(0) int sortOrder,
    @JsonKey(unknownEnumValue: Status.unknown)
    @Default(Status.active)
    Status status,
    @JsonKey(name: 'parent_category_id') String? parentCategoryId,
    @JsonKey(name: 'created_at')
    @NullableDateTimeConverter()
    DateTime? createdAt,
    @JsonKey(name: 'updated_at')
    @NullableDateTimeConverter()
    DateTime? updatedAt,
  }) = _DrugCategory;

  factory DrugCategory.fromJson(Map<String, dynamic> json) =>
      _$DrugCategoryFromJson(json);

  bool get hasParent => parentCategoryId?.isNotEmpty == true;
}

@freezed
abstract class CreateDrugCategoryRequest with _$CreateDrugCategoryRequest {
  @JsonSerializable(includeIfNull: false)
  const factory CreateDrugCategoryRequest({
    required String name,
    String? description,
    String? color,
    String? icon,
    @JsonKey(name: 'sort_order') int? sortOrder,
    Status? status,
    @JsonKey(name: 'parent_category_id') String? parentCategoryId,
  }) = _CreateDrugCategoryRequest;

  factory CreateDrugCategoryRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateDrugCategoryRequestFromJson(json);
}
