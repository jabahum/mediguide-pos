import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:user_app/core/utils/json_converters.dart';
import 'package:user_app/features/calculators/data/models/calculator_enums.dart';

part 'usage_event.freezed.dart';
part 'usage_event.g.dart';

@freezed
abstract class AbbreviationUsageLog with _$AbbreviationUsageLog {
  const factory AbbreviationUsageLog({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'abbreviation_id') required String abbreviationId,
    @JsonKey(name: 'created_at')
    @NullableDateTimeConverter()
    DateTime? createdAt,
    @JsonKey(name: 'updated_at')
    @NullableDateTimeConverter()
    DateTime? updatedAt,
  }) = _AbbreviationUsageLog;
  factory AbbreviationUsageLog.fromJson(Map<String, dynamic> json) =>
      _$AbbreviationUsageLogFromJson(json);
}

@freezed
abstract class AiUsageLog with _$AiUsageLog {
  const factory AiUsageLog({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'created_at')
    @NullableDateTimeConverter()
    DateTime? createdAt,
    @JsonKey(name: 'updated_at')
    @NullableDateTimeConverter()
    DateTime? updatedAt,
  }) = _AiUsageLog;
  factory AiUsageLog.fromJson(Map<String, dynamic> json) =>
      _$AiUsageLogFromJson(json);
}

@freezed
abstract class ConsultantUsageLog with _$ConsultantUsageLog {
  const factory ConsultantUsageLog({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'consultant_id') required String consultantId,
    @JsonKey(name: 'created_at')
    @NullableDateTimeConverter()
    DateTime? createdAt,
    @JsonKey(name: 'updated_at')
    @NullableDateTimeConverter()
    DateTime? updatedAt,
  }) = _ConsultantUsageLog;
  factory ConsultantUsageLog.fromJson(Map<String, dynamic> json) =>
      _$ConsultantUsageLogFromJson(json);
}

@freezed
abstract class DrugUsageLog with _$DrugUsageLog {
  const factory DrugUsageLog({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'drug_id') required String drugId,
    @JsonKey(name: 'created_at')
    @NullableDateTimeConverter()
    DateTime? createdAt,
    @JsonKey(name: 'updated_at')
    @NullableDateTimeConverter()
    DateTime? updatedAt,
  }) = _DrugUsageLog;
  factory DrugUsageLog.fromJson(Map<String, dynamic> json) =>
      _$DrugUsageLogFromJson(json);
}

@freezed
abstract class GuidelineUsageLog with _$GuidelineUsageLog {
  const factory GuidelineUsageLog({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'guideline_id') required String guidelineId,
    @JsonKey(name: 'created_at')
    @NullableDateTimeConverter()
    DateTime? createdAt,
    @JsonKey(name: 'updated_at')
    @NullableDateTimeConverter()
    DateTime? updatedAt,
  }) = _GuidelineUsageLog;
  factory GuidelineUsageLog.fromJson(Map<String, dynamic> json) =>
      _$GuidelineUsageLogFromJson(json);
}

@freezed
abstract class CalculatorUsageLog with _$CalculatorUsageLog {
  const CalculatorUsageLog._();
  const factory CalculatorUsageLog({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'calculator_id') required String calculatorId,
    @JsonKey(name: 'session_start') required DateTime sessionStart,
    @JsonKey(name: 'session_end') DateTime? sessionEnd,
    @JsonKey(name: 'calculator_type')
    @Default('calculator')
    String calculatorTypeValue,
    @JsonKey(name: 'created_at')
    @NullableDateTimeConverter()
    DateTime? createdAt,
    @JsonKey(name: 'updated_at')
    @NullableDateTimeConverter()
    DateTime? updatedAt,
  }) = _CalculatorUsageLog;
  factory CalculatorUsageLog.fromJson(Map<String, dynamic> json) =>
      _$CalculatorUsageLogFromJson(json);
  CalculatorType get calculatorType => switch (calculatorTypeValue) {
    'decision_tool' => CalculatorType.decisionTool,
    'checklist' => CalculatorType.checklist,
    _ => CalculatorType.calculator,
  };
  int get totalDurationSeconds =>
      (sessionEnd ?? DateTime.now()).difference(sessionStart).inSeconds;
  int get totalDurationMinutes => (totalDurationSeconds / 60).round();
  double get totalDurationHours => totalDurationSeconds / 3600;
  bool get isValidSession => sessionEnd != null && totalDurationSeconds > 0;
  bool get isActiveSession => sessionEnd == null;
  bool get meetsMinimumDuration => totalDurationSeconds >= 30;
}

@freezed
abstract class CalculatorUsageRequest with _$CalculatorUsageRequest {
  @JsonSerializable(includeIfNull: false)
  const factory CalculatorUsageRequest({
    @JsonKey(name: 'calculator_id') String? calculatorId,
    @JsonKey(name: 'session_start') DateTime? sessionStart,
    @JsonKey(name: 'session_end') DateTime? sessionEnd,
    @JsonKey(name: 'calculator_type') String? calculatorType,
  }) = _CalculatorUsageRequest;
  factory CalculatorUsageRequest.fromJson(Map<String, dynamic> json) =>
      _$CalculatorUsageRequestFromJson(json);
}
