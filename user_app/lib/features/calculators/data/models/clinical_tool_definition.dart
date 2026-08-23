import 'package:freezed_annotation/freezed_annotation.dart';

part 'clinical_tool_definition.freezed.dart';
part 'clinical_tool_definition.g.dart';

@freezed
abstract class ClinicalToolDefinition with _$ClinicalToolDefinition {
  const factory ClinicalToolDefinition({
    @JsonKey(name: 'schema_version') required String schemaVersion,
    @JsonKey(name: 'tool_type') required String toolType,
    required String title,
    @Default('') String description,
    required String version,
    @Default('en') String locale,
    @JsonKey(name: 'clinical_owner') @Default('') String clinicalOwner,
    @Default([]) List<ClinicalToolMessage> warnings,
    @Default([]) List<ClinicalToolCitation> citations,
    @Default([]) List<ClinicalToolInput> inputs,
    @Default([]) List<ClinicalToolSection> sections,
    @JsonKey(name: 'calculation')
    @Default([])
    List<ClinicalToolCalculation> calculations,
    @Default([]) List<ClinicalToolRule> rules,
    @Default([]) List<ClinicalToolOutput> outputs,
    @Default([]) List<ClinicalToolInterpretation> interpretations,
    required ClinicalToolCompletion completion,
    @JsonKey(name: 'minimum_app_version') String? minimumAppVersion,
  }) = _ClinicalToolDefinition;
  factory ClinicalToolDefinition.fromJson(Map<String, dynamic> json) =>
      _$ClinicalToolDefinitionFromJson(json);
}

@freezed
abstract class ClinicalToolDefinitionEnvelope
    with _$ClinicalToolDefinitionEnvelope {
  const factory ClinicalToolDefinitionEnvelope({
    @JsonKey(name: 'calculator_id') required String calculatorId,
    @JsonKey(name: 'version_id') required String versionId,
    @JsonKey(name: 'runtime_type') required String runtimeKind,
    @JsonKey(name: 'semantic_version') required String semanticVersion,
    @JsonKey(name: 'definition_checksum') required String definitionChecksum,
    required ClinicalToolDefinition definition,
  }) = _ClinicalToolDefinitionEnvelope;
  factory ClinicalToolDefinitionEnvelope.fromJson(Map<String, dynamic> json) =>
      _$ClinicalToolDefinitionEnvelopeFromJson(json);
}

@freezed
abstract class ClinicalToolExpression with _$ClinicalToolExpression {
  const factory ClinicalToolExpression({
    required String op,
    Object? value,
    String? field,
    @Default([]) List<ClinicalToolExpression> args,
    int? precision,
    @JsonKey(name: 'rounding_mode') String? roundingMode,
    @JsonKey(name: 'from_unit') String? fromUnit,
    @JsonKey(name: 'to_unit') String? toUnit,
    @JsonKey(name: 'date_unit') String? dateUnit,
  }) = _ClinicalToolExpression;
  factory ClinicalToolExpression.fromJson(Map<String, dynamic> json) =>
      _$ClinicalToolExpressionFromJson(json);
}

@freezed
abstract class ClinicalToolInput with _$ClinicalToolInput {
  const factory ClinicalToolInput({
    required String key,
    required String type,
    required String label,
    @Default('') String description,
    @Default(false) bool required,
    double? minimum,
    double? maximum,
    double? step,
    @JsonKey(name: 'default') Object? defaultValue,
    @JsonKey(name: 'allowed_units') @Default([]) List<String> allowedUnits,
    @JsonKey(name: 'default_unit') @Default('') String defaultUnit,
    @Default([]) List<ClinicalToolOption> options,
    @JsonKey(name: 'help_text') @Default('') String helpText,
    @JsonKey(name: 'clinical_warning') @Default('') String clinicalWarning,
    @JsonKey(name: 'visible_when') ClinicalToolExpression? visibleWhen,
    @JsonKey(name: 'section_key') @Default('') String sectionKey,
    @JsonKey(name: 'checklist_kind') @Default('') String checklistKind,
    @Default(false) bool critical,
    @JsonKey(name: 'allow_note') @Default(false) bool allowNote,
  }) = _ClinicalToolInput;
  factory ClinicalToolInput.fromJson(Map<String, dynamic> json) =>
      _$ClinicalToolInputFromJson(json);
}

@freezed
abstract class ClinicalToolOption with _$ClinicalToolOption {
  const factory ClinicalToolOption({
    required Object? value,
    required String label,
    @Default('') String description,
    double? score,
  }) = _ClinicalToolOption;
  factory ClinicalToolOption.fromJson(Map<String, dynamic> json) =>
      _$ClinicalToolOptionFromJson(json);
}

@freezed
abstract class ClinicalToolSection with _$ClinicalToolSection {
  const factory ClinicalToolSection({
    required String key,
    required String title,
    @Default('') String description,
    @Default(0) int order,
  }) = _ClinicalToolSection;
  factory ClinicalToolSection.fromJson(Map<String, dynamic> json) =>
      _$ClinicalToolSectionFromJson(json);
}

@freezed
abstract class ClinicalToolCalculation with _$ClinicalToolCalculation {
  const factory ClinicalToolCalculation({
    required String key,
    required ClinicalToolExpression expression,
    int? precision,
    @JsonKey(name: 'rounding_mode') String? roundingMode,
    @Default('') String unit,
  }) = _ClinicalToolCalculation;
  factory ClinicalToolCalculation.fromJson(Map<String, dynamic> json) =>
      _$ClinicalToolCalculationFromJson(json);
}

@freezed
abstract class ClinicalToolAction with _$ClinicalToolAction {
  const factory ClinicalToolAction({
    required String type,
    @Default('') String target,
    ClinicalToolExpression? value,
    @JsonKey(name: 'message_key') @Default('') String messageKey,
  }) = _ClinicalToolAction;
  factory ClinicalToolAction.fromJson(Map<String, dynamic> json) =>
      _$ClinicalToolActionFromJson(json);
}

@freezed
abstract class ClinicalToolRule with _$ClinicalToolRule {
  const factory ClinicalToolRule({
    required String key,
    required ClinicalToolExpression when,
    @Default([]) List<ClinicalToolAction> actions,
    @Default(0) int order,
    @Default(false) bool stop,
  }) = _ClinicalToolRule;
  factory ClinicalToolRule.fromJson(Map<String, dynamic> json) =>
      _$ClinicalToolRuleFromJson(json);
}

@freezed
abstract class ClinicalToolOutput with _$ClinicalToolOutput {
  const factory ClinicalToolOutput({
    required String key,
    required String label,
    required ClinicalToolExpression value,
    @Default('') String unit,
    int? precision,
    @JsonKey(name: 'rounding_mode') String? roundingMode,
    @JsonKey(name: 'accessibility_label')
    @Default('')
    String accessibilityLabel,
  }) = _ClinicalToolOutput;
  factory ClinicalToolOutput.fromJson(Map<String, dynamic> json) =>
      _$ClinicalToolOutputFromJson(json);
}

@freezed
abstract class ClinicalToolInterpretation with _$ClinicalToolInterpretation {
  const factory ClinicalToolInterpretation({
    required String key,
    required ClinicalToolExpression when,
    required String label,
    @Default('') String description,
    @Default('info') String severity,
    @Default([]) List<String> recommendations,
    @Default(0) int order,
  }) = _ClinicalToolInterpretation;
  factory ClinicalToolInterpretation.fromJson(Map<String, dynamic> json) =>
      _$ClinicalToolInterpretationFromJson(json);
}

@freezed
abstract class ClinicalToolMessage with _$ClinicalToolMessage {
  const factory ClinicalToolMessage({
    required String key,
    required String text,
    @Default('info') String severity,
    ClinicalToolExpression? when,
  }) = _ClinicalToolMessage;
  factory ClinicalToolMessage.fromJson(Map<String, dynamic> json) =>
      _$ClinicalToolMessageFromJson(json);
}

@freezed
abstract class ClinicalToolCitation with _$ClinicalToolCitation {
  const factory ClinicalToolCitation({
    required String key,
    required String title,
    @Default('') String organization,
    @Default('') String url,
    @JsonKey(name: 'published_at') @Default('') String publishedAt,
  }) = _ClinicalToolCitation;
  factory ClinicalToolCitation.fromJson(Map<String, dynamic> json) =>
      _$ClinicalToolCitationFromJson(json);
}

@freezed
abstract class ClinicalToolCompletion with _$ClinicalToolCompletion {
  const factory ClinicalToolCompletion({
    required String mode,
    ClinicalToolExpression? expression,
    @JsonKey(name: 'allow_resume') @Default(false) bool allowResume,
    @JsonKey(name: 'require_review') @Default(false) bool requireReview,
    @JsonKey(name: 'show_percentage') @Default(false) bool showPercentage,
    @JsonKey(name: 'reset_confirmation') @Default(true) bool resetConfirmation,
  }) = _ClinicalToolCompletion;
  factory ClinicalToolCompletion.fromJson(Map<String, dynamic> json) =>
      _$ClinicalToolCompletionFromJson(json);
}
