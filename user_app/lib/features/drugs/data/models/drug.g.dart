// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drug.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Drug _$DrugFromJson(Map<String, dynamic> json) => _Drug(
  id: json['id'] as String,
  name: json['name'] as String? ?? '',
  brandNames: json['brand_names'] as String? ?? '',
  description: json['description'] as String? ?? '',
  mechanismOfAction: json['mechanism_of_action'] as String? ?? '',
  adultDose: json['adult_dose'] as String? ?? '',
  pediatricDose: json['pediatric_dose'] as String? ?? '',
  elderlyDose: json['elderly_dose'] as String? ?? '',
  maxDailyDose: json['max_daily_dose'] as String? ?? '',
  routeOfAdministration:
      (json['routeOfAdministration'] as List<dynamic>?)
          ?.map((e) => $enumDecode(_$RouteOfAdministrationEnumMap, e))
          .toList() ??
      const [],
  frequency: json['frequency'] as String? ?? '',
  duration: json['duration'] as String? ?? '',
  indications: json['indications'] as String? ?? '',
  contraindications: json['contraindications'] as String? ?? '',
  sideEffects: json['side_effects'] as String? ?? '',
  warnings: json['warnings'] as String? ?? '',
  monitoringParameters: json['monitoring_parameters'] as String? ?? '',
  pregnancyCategory: $enumDecodeNullable(
    _$PregnancyCategoryEnumMap,
    json['pregnancyCategory'],
  ),
  clinicalNotes: json['clinical_notes'] as String? ?? '',
  categories:
      (json['categories'] as List<dynamic>?)
          ?.map((e) => DrugCategory.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  tags:
      (json['tags'] as List<dynamic>?)
          ?.map((e) => DrugTag.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  drugClass: json['drug_class'] == null
      ? null
      : DrugClass.fromJson(json['drug_class'] as Map<String, dynamic>),
  therapeuticCategory: json['therapeutic_category'] == null
      ? null
      : TherapeuticCategory.fromJson(
          json['therapeutic_category'] as Map<String, dynamic>,
        ),
  whoEmlStatus: json['who_eml_status'] as bool? ?? false,
  antimicrobialStatus: json['antimicrobial_status'] as bool? ?? false,
  controlledSubstance: $enumDecodeNullable(
    _$ControlledSubstanceEnumMap,
    json['controlledSubstance'],
  ),
  status:
      $enumDecodeNullable(_$DrugStatusEnumMap, json['status']) ??
      DrugStatus.active,
  reviewStatus:
      $enumDecodeNullable(_$ReviewStatusEnumMap, json['review_status']) ??
      ReviewStatus.pending,
  searchKeywords: json['search_keywords'] as String? ?? '',
  references: json['reference_text'] as String? ?? '',
  usageCount: (json['usage_count'] as num?)?.toInt() ?? 0,
  createdAt: const NullableDateTimeConverter().fromJson(json['created_at']),
  updatedAt: const NullableDateTimeConverter().fromJson(json['updated_at']),
);

Map<String, dynamic> _$DrugToJson(_Drug instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'brand_names': instance.brandNames,
  'description': instance.description,
  'mechanism_of_action': instance.mechanismOfAction,
  'adult_dose': instance.adultDose,
  'pediatric_dose': instance.pediatricDose,
  'elderly_dose': instance.elderlyDose,
  'max_daily_dose': instance.maxDailyDose,
  'routeOfAdministration': instance.routeOfAdministration
      .map((e) => _$RouteOfAdministrationEnumMap[e]!)
      .toList(),
  'frequency': instance.frequency,
  'duration': instance.duration,
  'indications': instance.indications,
  'contraindications': instance.contraindications,
  'side_effects': instance.sideEffects,
  'warnings': instance.warnings,
  'monitoring_parameters': instance.monitoringParameters,
  'pregnancyCategory': _$PregnancyCategoryEnumMap[instance.pregnancyCategory],
  'clinical_notes': instance.clinicalNotes,
  'categories': instance.categories.map((e) => e.toJson()).toList(),
  'tags': instance.tags.map((e) => e.toJson()).toList(),
  'drug_class': instance.drugClass?.toJson(),
  'therapeutic_category': instance.therapeuticCategory?.toJson(),
  'who_eml_status': instance.whoEmlStatus,
  'antimicrobial_status': instance.antimicrobialStatus,
  'controlledSubstance':
      _$ControlledSubstanceEnumMap[instance.controlledSubstance],
  'status': _$DrugStatusEnumMap[instance.status]!,
  'review_status': _$ReviewStatusEnumMap[instance.reviewStatus]!,
  'search_keywords': instance.searchKeywords,
  'reference_text': instance.references,
  'usage_count': instance.usageCount,
  'created_at': const NullableDateTimeConverter().toJson(instance.createdAt),
  'updated_at': const NullableDateTimeConverter().toJson(instance.updatedAt),
};

const _$RouteOfAdministrationEnumMap = {
  RouteOfAdministration.oral: 'oral',
  RouteOfAdministration.iv: 'iv',
  RouteOfAdministration.im: 'im',
  RouteOfAdministration.topical: 'topical',
  RouteOfAdministration.inhaled: 'inhaled',
  RouteOfAdministration.sublingual: 'sublingual',
  RouteOfAdministration.rectal: 'rectal',
  RouteOfAdministration.transdermal: 'transdermal',
  RouteOfAdministration.intranasal: 'intranasal',
  RouteOfAdministration.subcutaneous: 'subcutaneous',
};

const _$PregnancyCategoryEnumMap = {
  PregnancyCategory.a: 'a',
  PregnancyCategory.b: 'b',
  PregnancyCategory.c: 'c',
  PregnancyCategory.d: 'd',
  PregnancyCategory.x: 'x',
  PregnancyCategory.unknown: 'unknown',
};

const _$ControlledSubstanceEnumMap = {
  ControlledSubstance.none: 'none',
  ControlledSubstance.scheduleI: 'scheduleI',
  ControlledSubstance.scheduleII: 'scheduleII',
  ControlledSubstance.scheduleIII: 'scheduleIII',
  ControlledSubstance.scheduleIV: 'scheduleIV',
  ControlledSubstance.scheduleV: 'scheduleV',
};

const _$DrugStatusEnumMap = {
  DrugStatus.active: 'active',
  DrugStatus.inactive: 'inactive',
  DrugStatus.underReview: 'underReview',
  DrugStatus.archived: 'archived',
};

const _$ReviewStatusEnumMap = {
  ReviewStatus.approved: 'approved',
  ReviewStatus.pending: 'pending',
  ReviewStatus.needsUpdate: 'needsUpdate',
};
