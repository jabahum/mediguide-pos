import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:user_app/core/utils/json_converters.dart';
import 'package:user_app/features/guidelines/data/models/guideline_category.dart';
import 'package:user_app/features/guidelines/data/models/guideline_tag.dart';
import 'package:user_app/features/guidelines/data/models/guideline_index.dart';

part 'guideline.freezed.dart';
part 'guideline.g.dart';

@freezed
abstract class Guideline with _$Guideline {
  const Guideline._();
  @JsonSerializable(explicitToJson: true)
  const factory Guideline({
    required String id,
    @JsonKey(name: 'condition_name') @Default('') String conditionName,
    @JsonKey(name: 'icd10_code') @Default('') String icd10Code,
    @JsonKey(name: 'target_population') @Default('') String targetPopulation,
    @Default('') String version,
    @Default('') String definition,
    @Default('') String causes,
    @JsonKey(name: 'clinical_features') @Default('') String clinicalFeatures,
    @JsonKey(name: 'differential_diagnosis')
    @Default('')
    String differentialDiagnosis,
    @JsonKey(name: 'classification_mild')
    @Default('')
    String classificationMild,
    @JsonKey(name: 'classification_moderate')
    @Default('')
    String classificationModerate,
    @JsonKey(name: 'classification_severe')
    @Default('')
    String classificationSevere,
    @JsonKey(name: 'classification_critical')
    @Default('')
    String classificationCritical,
    @JsonKey(name: 'general_management') @Default('') String generalManagement,
    @JsonKey(name: 'medication_primary') @Default('') String medicationPrimary,
    @JsonKey(name: 'dosage_adult') @Default('') String dosageAdult,
    @JsonKey(name: 'dosage_pediatric') @Default('') String dosagePediatric,
    @JsonKey(name: 'medication_secondary')
    @Default('')
    String medicationSecondary,
    @JsonKey(name: 'dosage_secondary_adult')
    @Default('')
    String dosageSecondaryAdult,
    @JsonKey(name: 'dosage_secondary_pediatric')
    @Default('')
    String dosageSecondaryPediatric,
    @JsonKey(name: 'healthcare_level_required')
    @Default('')
    String healthcareLevelRequired,
    @JsonKey(name: 'route_administration')
    @Default('')
    String routeAdministration,
    @JsonKey(name: 'monitoring_requirements')
    @Default('')
    String monitoringRequirements,
    @Default('') String contraindications,
    @JsonKey(name: 'prevention_measures')
    @Default('')
    String preventionMeasures,
    @JsonKey(name: 'special_notes') @Default('') String specialNotes,
    @Default('') String status,
    @JsonKey(name: 'is_published') @Default(false) bool isPublished,
    @Default('') String priority,
    @Default([]) List<GuidelineCategory> categories,
    @Default([]) List<GuidelineTag> tags,
    @JsonKey(name: 'index_item') GuidelineIndex? indexItem,
    @JsonKey(name: 'usage_count') @Default(0) int usageCount,
    @JsonKey(name: 'created_at')
    @NullableDateTimeConverter()
    DateTime? createdAt,
    @JsonKey(name: 'updated_at')
    @NullableDateTimeConverter()
    DateTime? updatedAt,
  }) = _Guideline;
  factory Guideline.fromJson(Map<String, dynamic> json) =>
      _$GuidelineFromJson(_normalizeGuideline(json));

  DateTime? get updatedDate => updatedAt;
  String get displayName => conditionName;
  bool get isActive => isPublished && status == 'published';
  bool get hasCategories => categories.isNotEmpty;
  bool get hasTags => tags.isNotEmpty;
  bool get hasIndexItem => indexItem != null;
  String get indexItemTitle => indexItem?.title ?? '';
  bool get hasDefinition => definition.isNotEmpty;
  bool get hasCauses => causes.isNotEmpty;
  bool get hasClinicalFeatures => clinicalFeatures.isNotEmpty;
  bool get hasPrimaryMedication => medicationPrimary.isNotEmpty;
  bool get hasSecondaryMedication => medicationSecondary.isNotEmpty;
  bool get hasIcd10Code => icd10Code.isNotEmpty;
  bool get hasTargetPopulation => targetPopulation.isNotEmpty;
  bool get hasClassifications => [
    classificationMild,
    classificationModerate,
    classificationSevere,
    classificationCritical,
  ].any((v) => v.isNotEmpty);
  GuidelinePriority get priorityLevel => GuidelinePriority.values.firstWhere(
    (e) => e.name == priority.toLowerCase(),
    orElse: () => GuidelinePriority.medium,
  );
  String get shortDescription {
    final text = definition
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return text.length <= 150 ? text : '${text.substring(0, 150)}...';
  }

  HealthcareLevel get healthcareLevelEnum =>
      switch (healthcareLevelRequired.toUpperCase()) {
        'HC1' => HealthcareLevel.hc1,
        'HC3' => HealthcareLevel.hc3,
        'HC4' => HealthcareLevel.hc4,
        _ => HealthcareLevel.hc2,
      };
}

Map<String, dynamic> _normalizeGuideline(Map<String, dynamic> json) {
  List<Map<String, dynamic>> relations(Object? raw) => raw is List
      ? raw
            .map(
              (v) => v is Map
                  ? Map<String, dynamic>.from(v)
                  : {'id': '', 'name': v.toString()},
            )
            .toList()
      : [];
  final index = json['index_item'];
  final indexId = json['index_item_id']?.toString() ?? '';
  return {
    ...json,
    'categories': relations(json['categories']),
    'tags': relations(json['tags']),
    'index_item': index is Map
        ? index
        : (indexId.isEmpty
              ? null
              : {'id': indexId, 'title': json['index_item_title'] ?? ''}),
  };
}

enum GuidelinePriority {
  critical(label: 'Critical'),
  high(label: 'High'),
  medium(label: 'Medium'),
  low(label: 'Low');

  const GuidelinePriority({required this.label});
  final String label;
}

enum HealthcareLevel {
  hc1(label: 'HC I (Village Health Team)', shortName: 'HC I'),
  hc2(label: 'HC II (Health Center II)', shortName: 'HC II'),
  hc3(label: 'HC III (Health Center III)', shortName: 'HC III'),
  hc4(label: 'HC IV (Health Center IV)', shortName: 'HC IV');

  const HealthcareLevel({required this.label, required this.shortName});
  final String label;
  final String shortName;
}
