import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:user_app/core/utils/json_converters.dart';

part 'language_model.freezed.dart';
part 'language_model.g.dart';

@freezed
abstract class LanguageModel with _$LanguageModel {
  const LanguageModel._();

  const factory LanguageModel({
    required String id,
    required String code,
    required String name,
    @JsonKey(name: 'native_name') @Default('') String nativeName,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'is_default') @Default(false) bool isDefault,
    @JsonKey(name: 'translations_url') @Default('') String translationsUrl,
    @Default({}) Map<String, dynamic> translations,
    @Default(1) double version,
    @NullableDateTimeConverter() DateTime? created,
    @NullableDateTimeConverter() DateTime? updated,
  }) = _LanguageModel;

  factory LanguageModel.fromJson(Map<String, dynamic> json) =>
      _$LanguageModelFromJson(json);

  String get displayName => nativeName != name && nativeName.isNotEmpty
      ? '$name ($nativeName)'
      : name;

  String get shortDisplayName => nativeName.isNotEmpty ? nativeName : name;

  bool get hasTranslations =>
      translations.isNotEmpty || translationsUrl.isNotEmpty;
}
