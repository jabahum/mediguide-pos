import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:user_app/core/utils/json_converters.dart';
import 'package:user_app/features/drugs/data/models/drug_enums.dart';
import 'package:user_app/features/drugs/data/models/drug_category.dart';
import 'package:user_app/features/drugs/data/models/drug_tag.dart';
import 'package:user_app/features/drugs/data/models/drug_class.dart';
import 'package:user_app/features/drugs/data/models/therapeutic_category.dart';

part 'drug.freezed.dart';
part 'drug.g.dart';

@freezed
abstract class Drug with _$Drug {
  const Drug._();
  @JsonSerializable(explicitToJson: true)
  const factory Drug({
    required String id,
    @Default('') String name,
    @JsonKey(name: 'brand_names') @Default('') String brandNames,
    @Default('') String description,
    @JsonKey(name: 'mechanism_of_action') @Default('') String mechanismOfAction,
    @JsonKey(name: 'adult_dose') @Default('') String adultDose,
    @JsonKey(name: 'pediatric_dose') @Default('') String pediatricDose,
    @JsonKey(name: 'elderly_dose') @Default('') String elderlyDose,
    @JsonKey(name: 'max_daily_dose') @Default('') String maxDailyDose,
    @Default([]) List<RouteOfAdministration> routeOfAdministration,
    @Default('') String frequency,
    @Default('') String duration,
    @Default('') String indications,
    @Default('') String contraindications,
    @JsonKey(name: 'side_effects') @Default('') String sideEffects,
    @Default('') String warnings,
    @JsonKey(name: 'monitoring_parameters')
    @Default('')
    String monitoringParameters,
    PregnancyCategory? pregnancyCategory,
    @JsonKey(name: 'clinical_notes') @Default('') String clinicalNotes,
    @Default([]) List<DrugCategory> categories,
    @Default([]) List<DrugTag> tags,
    @JsonKey(name: 'drug_class') DrugClass? drugClass,
    @JsonKey(name: 'therapeutic_category')
    TherapeuticCategory? therapeuticCategory,
    @JsonKey(name: 'who_eml_status') @Default(false) bool whoEmlStatus,
    @JsonKey(name: 'antimicrobial_status')
    @Default(false)
    bool antimicrobialStatus,
    ControlledSubstance? controlledSubstance,
    @Default(DrugStatus.active) DrugStatus status,
    @JsonKey(name: 'review_status')
    @Default(ReviewStatus.pending)
    ReviewStatus reviewStatus,
    @JsonKey(name: 'search_keywords') @Default('') String searchKeywords,
    @JsonKey(name: 'reference_text') @Default('') String references,
    @JsonKey(name: 'usage_count') @Default(0) int usageCount,
    @JsonKey(name: 'created_at')
    @NullableDateTimeConverter()
    DateTime? createdAt,
    @JsonKey(name: 'updated_at')
    @NullableDateTimeConverter()
    DateTime? updatedAt,
  }) = _Drug;
  factory Drug.fromJson(Map<String, dynamic> json) =>
      _$DrugFromJson(_normalizeDrug(json));
}

Map<String, dynamic> _normalizeDrug(Map<String, dynamic> json) {
  List<String> strings(Object? value) {
    if (value is List) return value.map((e) => e.toString()).toList();
    if (value is String) {
      return value
          .split(RegExp(r'[,;]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return [];
  }

  List<Map<String, dynamic>> relations(Object? value) => value is List
      ? value
            .map(
              (e) => e is Map
                  ? Map<String, dynamic>.from(e)
                  : {'id': '', 'name': e.toString()},
            )
            .toList()
      : [];
  Map<String, dynamic>? relation(String key, String idKey, String nameKey) {
    final value = json[key];
    if (value is Map) return Map<String, dynamic>.from(value);
    final id = json[idKey]?.toString() ?? '';
    final name = json[nameKey]?.toString() ?? '';
    return id.isEmpty && name.isEmpty ? null : {'id': id, 'name': name};
  }

  String? normalizedEnum(Object? value) {
    final result = value
        ?.toString()
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('_', '');
    return result == null || result.isEmpty ? null : result;
  }

  String status(Object? value) => switch (normalizedEnum(value)) {
    'underreview' => 'underReview',
    _ => normalizedEnum(value) ?? 'active',
  };
  String review(Object? value) => switch (normalizedEnum(value)) {
    'needsupdate' => 'needsUpdate',
    _ => normalizedEnum(value) ?? 'pending',
  };
  String? controlled(Object? value) => switch (normalizedEnum(value)) {
    'schedulei' => 'scheduleI',
    'scheduleii' => 'scheduleII',
    'scheduleiii' => 'scheduleIII',
    'scheduleiv' => 'scheduleIV',
    'schedulev' => 'scheduleV',
    _ => normalizedEnum(value),
  };
  return {
    ...json,
    'routeOfAdministration': strings(
      json['route_of_administration'],
    ).map((e) => e.toLowerCase()).toList(),
    'pregnancyCategory': normalizedEnum(json['pregnancy_category']),
    'controlledSubstance': controlled(json['controlled_substance']),
    'status': status(json['status']),
    'review_status': review(json['review_status']),
    'categories': relations(json['categories_json'] ?? json['categories']),
    'tags': relations(json['tags_json'] ?? json['tags']),
    'drug_class': relation('drug_class', 'drug_class_id', 'drug_class_name'),
    'therapeutic_category': relation(
      'therapeutic_category',
      'therapeutic_category_id',
      'therapeutic_category_name',
    ),
  };
}
