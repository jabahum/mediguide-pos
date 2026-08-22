import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:user_app/core/utils/json_converters.dart';
import 'package:user_app/features/calculators/data/models/calculator_enums.dart';

part 'calculator.freezed.dart';
part 'calculator.g.dart';

@freezed
abstract class Calculator with _$Calculator {
  const Calculator._();
  const factory Calculator({
    required String id,
    @Default('') String name,
    @Default('') String description,
    @Default('') String icon,
    @Default('') String color,
    @JsonKey(name: 'background_color') @Default('') String backgroundColor,
    @JsonKey(name: 'app_file') @Default('') String appFile,
    @Default('') String version,
    @JsonKey(name: 'added_by_user_id') String? addedByUserId,
    @JsonKey(name: 'type') @Default('calculator') String typeValue,
    @JsonKey(name: 'status') @Default('draft') String statusValue,
    @JsonKey(name: 'usage_count') @Default(0) int usageCount,
    @JsonKey(name: 'runtime_type') @Default('legacy_html') String runtimeKind,
    @JsonKey(name: 'current_version_id') String? currentVersionId,
    @Default(false) bool featured,
    @JsonKey(name: 'created_at')
    @NullableDateTimeConverter()
    DateTime? createdAt,
    @JsonKey(name: 'updated_at')
    @NullableDateTimeConverter()
    DateTime? updatedAt,
  }) = _Calculator;
  factory Calculator.fromJson(Map<String, dynamic> json) =>
      _$CalculatorFromJson(_normalizeCalculator(json));
  CalculatorType get type => switch (typeValue) {
    'decision_tool' => CalculatorType.decisionTool,
    'checklist' => CalculatorType.checklist,
    _ => CalculatorType.calculator,
  };
  CalculatorStatus get status => switch (statusValue) {
    'active' => CalculatorStatus.active,
    'archived' => CalculatorStatus.archived,
    _ => CalculatorStatus.draft,
  };
  String getAppFileUrl(String baseUrl) =>
      appFile.isEmpty ? '' : '$baseUrl/api/v2/calculators/$id/content';
  bool get isActive => status == CalculatorStatus.active;
  bool get isDraft => status == CalculatorStatus.draft;
  bool get isArchived => status == CalculatorStatus.archived;
  bool get isNativeSchema => runtimeKind == 'schema_v1';
  String get typeDisplayName => switch (type) {
    CalculatorType.calculator => 'Calculator',
    CalculatorType.decisionTool => 'Decision Tool',
    CalculatorType.checklist => 'Checklist',
  };
}

Map<String, dynamic> _normalizeCalculator(Map<String, dynamic> json) {
  final file = json['app_file'] ?? json['app_file_json'];
  return {
    ...json,
    'app_file': file is String
        ? file
        : file is Map
        ? (file['path'] ?? file['url'] ?? file['name'] ?? '').toString()
        : '',
  };
}

@freezed
abstract class CalculatorRequest with _$CalculatorRequest {
  @JsonSerializable(includeIfNull: false)
  const factory CalculatorRequest({
    String? name,
    String? description,
    String? icon,
    String? color,
    @JsonKey(name: 'background_color') String? backgroundColor,
    @JsonKey(name: 'app_file') Map<String, dynamic>? appFile,
    String? version,
    @JsonKey(name: 'added_by_user_id') String? addedByUserId,
    String? type,
    String? status,
    bool? featured,
  }) = _CalculatorRequest;
  factory CalculatorRequest.fromJson(Map<String, dynamic> json) =>
      _$CalculatorRequestFromJson(json);
}
