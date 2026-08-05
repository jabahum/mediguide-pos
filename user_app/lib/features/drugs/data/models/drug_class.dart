import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:user_app/core/utils/json_converters.dart';
import 'package:user_app/shared/models/common_enums.dart';

part 'drug_class.freezed.dart';
part 'drug_class.g.dart';

@freezed
abstract class DrugClass with _$DrugClass {
  const factory DrugClass({
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
  }) = _DrugClass;

  factory DrugClass.fromJson(Map<String, dynamic> json) =>
      _$DrugClassFromJson(json);
}

@freezed
abstract class CreateDrugClassRequest with _$CreateDrugClassRequest {
  @JsonSerializable(includeIfNull: false)
  const factory CreateDrugClassRequest({
    required String name,
    String? description,
    @JsonKey(name: 'sort_order') int? sortOrder,
    Status? status,
  }) = _CreateDrugClassRequest;

  factory CreateDrugClassRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateDrugClassRequestFromJson(json);
}
