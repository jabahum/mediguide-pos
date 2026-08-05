// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'guideline.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Guideline _$GuidelineFromJson(Map<String, dynamic> json) => _Guideline(
  id: json['id'] as String,
  conditionName: json['condition_name'] as String? ?? '',
  icd10Code: json['icd10_code'] as String? ?? '',
  targetPopulation: json['target_population'] as String? ?? '',
  version: json['version'] as String? ?? '',
  definition: json['definition'] as String? ?? '',
  causes: json['causes'] as String? ?? '',
  clinicalFeatures: json['clinical_features'] as String? ?? '',
  differentialDiagnosis: json['differential_diagnosis'] as String? ?? '',
  classificationMild: json['classification_mild'] as String? ?? '',
  classificationModerate: json['classification_moderate'] as String? ?? '',
  classificationSevere: json['classification_severe'] as String? ?? '',
  classificationCritical: json['classification_critical'] as String? ?? '',
  generalManagement: json['general_management'] as String? ?? '',
  medicationPrimary: json['medication_primary'] as String? ?? '',
  dosageAdult: json['dosage_adult'] as String? ?? '',
  dosagePediatric: json['dosage_pediatric'] as String? ?? '',
  medicationSecondary: json['medication_secondary'] as String? ?? '',
  dosageSecondaryAdult: json['dosage_secondary_adult'] as String? ?? '',
  dosageSecondaryPediatric: json['dosage_secondary_pediatric'] as String? ?? '',
  healthcareLevelRequired: json['healthcare_level_required'] as String? ?? '',
  routeAdministration: json['route_administration'] as String? ?? '',
  monitoringRequirements: json['monitoring_requirements'] as String? ?? '',
  contraindications: json['contraindications'] as String? ?? '',
  preventionMeasures: json['prevention_measures'] as String? ?? '',
  specialNotes: json['special_notes'] as String? ?? '',
  status: json['status'] as String? ?? '',
  isPublished: json['is_published'] as bool? ?? false,
  priority: json['priority'] as String? ?? '',
  categories:
      (json['categories'] as List<dynamic>?)
          ?.map((e) => GuidelineCategory.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  tags:
      (json['tags'] as List<dynamic>?)
          ?.map((e) => GuidelineTag.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  indexItem: json['index_item'] == null
      ? null
      : GuidelineIndex.fromJson(json['index_item'] as Map<String, dynamic>),
  usageCount: (json['usage_count'] as num?)?.toInt() ?? 0,
  createdAt: const NullableDateTimeConverter().fromJson(json['created_at']),
  updatedAt: const NullableDateTimeConverter().fromJson(json['updated_at']),
);

Map<String, dynamic> _$GuidelineToJson(
  _Guideline instance,
) => <String, dynamic>{
  'id': instance.id,
  'condition_name': instance.conditionName,
  'icd10_code': instance.icd10Code,
  'target_population': instance.targetPopulation,
  'version': instance.version,
  'definition': instance.definition,
  'causes': instance.causes,
  'clinical_features': instance.clinicalFeatures,
  'differential_diagnosis': instance.differentialDiagnosis,
  'classification_mild': instance.classificationMild,
  'classification_moderate': instance.classificationModerate,
  'classification_severe': instance.classificationSevere,
  'classification_critical': instance.classificationCritical,
  'general_management': instance.generalManagement,
  'medication_primary': instance.medicationPrimary,
  'dosage_adult': instance.dosageAdult,
  'dosage_pediatric': instance.dosagePediatric,
  'medication_secondary': instance.medicationSecondary,
  'dosage_secondary_adult': instance.dosageSecondaryAdult,
  'dosage_secondary_pediatric': instance.dosageSecondaryPediatric,
  'healthcare_level_required': instance.healthcareLevelRequired,
  'route_administration': instance.routeAdministration,
  'monitoring_requirements': instance.monitoringRequirements,
  'contraindications': instance.contraindications,
  'prevention_measures': instance.preventionMeasures,
  'special_notes': instance.specialNotes,
  'status': instance.status,
  'is_published': instance.isPublished,
  'priority': instance.priority,
  'categories': instance.categories.map((e) => e.toJson()).toList(),
  'tags': instance.tags.map((e) => e.toJson()).toList(),
  'index_item': instance.indexItem?.toJson(),
  'usage_count': instance.usageCount,
  'created_at': const NullableDateTimeConverter().toJson(instance.createdAt),
  'updated_at': const NullableDateTimeConverter().toJson(instance.updatedAt),
};
