import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:user_app/core/utils/json_converters.dart';

part 'settings.freezed.dart';
part 'settings.g.dart';

@freezed
abstract class Settings with _$Settings {
  const Settings._();
  const factory Settings({
    required String id,
    required String key,
    Object? value,
    @Default('') String category,
    @Default('') String description,
    @JsonKey(name: 'is_public') @Default(false) bool isPublic,
    @JsonKey(name: 'created_at')
    @NullableDateTimeConverter()
    DateTime? createdAt,
    @JsonKey(name: 'updated_at')
    @NullableDateTimeConverter()
    DateTime? updatedAt,
  }) = _Settings;
  factory Settings.fromJson(Map<String, dynamic> json) =>
      _$SettingsFromJson(json);
  String get stringValue => value?.toString() ?? '';
  int get intValue =>
      value is num ? (value as num).toInt() : int.tryParse(stringValue) ?? 0;
  double get doubleValue => value is num
      ? (value as num).toDouble()
      : double.tryParse(stringValue) ?? 0;
  bool get boolValue => value is bool
      ? value! as bool
      : value is num
      ? (value as num) != 0
      : stringValue.toLowerCase() == 'true';
  List<String> get stringListValue => value is List
      ? (value as List).map((item) => item.toString()).toList()
      : const [];
  Map<String, dynamic> get mapValue =>
      value is Map ? Map<String, dynamic>.from(value! as Map) : const {};
  T getTypedValue<T>(T fallback) => value is T ? value! as T : fallback;
  bool get hasCategory => category.isNotEmpty;
  bool get hasDescription => description.isNotEmpty;
  bool get isPublicSetting => isPublic;
  bool get hasValue => value != null;
  String get displayKey => _display(key);
  String get displayCategory => _display(category);
  String get searchString =>
      '$key $category $description $stringValue'.toLowerCase();
  bool matchesSearch(String query) =>
      query.isEmpty || searchString.contains(query.toLowerCase());
  bool belongsToCategory(String name) =>
      name.isEmpty || category.toLowerCase() == name.toLowerCase();
  String get valueType =>
      value == null ? 'null' : value.runtimeType.toString().toLowerCase();
}

String _display(String value) => value
    .replaceAll('_', ' ')
    .split(' ')
    .map(
      (word) =>
          word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}',
    )
    .join(' ');

@freezed
abstract class SettingsRequest with _$SettingsRequest {
  @JsonSerializable(includeIfNull: false)
  const factory SettingsRequest({
    String? key,
    Object? value,
    String? category,
    String? description,
    @JsonKey(name: 'is_public') bool? isPublic,
  }) = _SettingsRequest;
  factory SettingsRequest.fromJson(Map<String, dynamic> json) =>
      _$SettingsRequestFromJson(json);
}
