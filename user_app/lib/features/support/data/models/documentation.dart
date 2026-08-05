import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:user_app/core/utils/json_converters.dart';

part 'documentation.freezed.dart';
part 'documentation.g.dart';

@freezed
abstract class Documentation with _$Documentation {
  const factory Documentation({
    required String id,
    @Default('') String title,
    @Default('') String description,
    @Default('') String content,
    @Default('') String category,
    @Default('') String status,
    @Default('') String tags,
    @JsonKey(name: 'created_at')
    @NullableDateTimeConverter()
    DateTime? createdAt,
    @JsonKey(name: 'updated_at')
    @NullableDateTimeConverter()
    DateTime? updatedAt,
  }) = _Documentation;
  factory Documentation.fromJson(Map<String, dynamic> json) =>
      _$DocumentationFromJson(json);
}
