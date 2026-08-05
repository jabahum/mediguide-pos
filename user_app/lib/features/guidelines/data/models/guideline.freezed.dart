// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'guideline.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Guideline {

 String get id;@JsonKey(name: 'condition_name') String get conditionName;@JsonKey(name: 'icd10_code') String get icd10Code;@JsonKey(name: 'target_population') String get targetPopulation; String get version; String get definition; String get causes;@JsonKey(name: 'clinical_features') String get clinicalFeatures;@JsonKey(name: 'differential_diagnosis') String get differentialDiagnosis;@JsonKey(name: 'classification_mild') String get classificationMild;@JsonKey(name: 'classification_moderate') String get classificationModerate;@JsonKey(name: 'classification_severe') String get classificationSevere;@JsonKey(name: 'classification_critical') String get classificationCritical;@JsonKey(name: 'general_management') String get generalManagement;@JsonKey(name: 'medication_primary') String get medicationPrimary;@JsonKey(name: 'dosage_adult') String get dosageAdult;@JsonKey(name: 'dosage_pediatric') String get dosagePediatric;@JsonKey(name: 'medication_secondary') String get medicationSecondary;@JsonKey(name: 'dosage_secondary_adult') String get dosageSecondaryAdult;@JsonKey(name: 'dosage_secondary_pediatric') String get dosageSecondaryPediatric;@JsonKey(name: 'healthcare_level_required') String get healthcareLevelRequired;@JsonKey(name: 'route_administration') String get routeAdministration;@JsonKey(name: 'monitoring_requirements') String get monitoringRequirements; String get contraindications;@JsonKey(name: 'prevention_measures') String get preventionMeasures;@JsonKey(name: 'special_notes') String get specialNotes; String get status;@JsonKey(name: 'is_published') bool get isPublished; String get priority; List<GuidelineCategory> get categories; List<GuidelineTag> get tags;@JsonKey(name: 'index_item') GuidelineIndex? get indexItem;@JsonKey(name: 'usage_count') int get usageCount;@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? get createdAt;@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? get updatedAt;
/// Create a copy of Guideline
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GuidelineCopyWith<Guideline> get copyWith => _$GuidelineCopyWithImpl<Guideline>(this as Guideline, _$identity);

  /// Serializes this Guideline to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Guideline&&(identical(other.id, id) || other.id == id)&&(identical(other.conditionName, conditionName) || other.conditionName == conditionName)&&(identical(other.icd10Code, icd10Code) || other.icd10Code == icd10Code)&&(identical(other.targetPopulation, targetPopulation) || other.targetPopulation == targetPopulation)&&(identical(other.version, version) || other.version == version)&&(identical(other.definition, definition) || other.definition == definition)&&(identical(other.causes, causes) || other.causes == causes)&&(identical(other.clinicalFeatures, clinicalFeatures) || other.clinicalFeatures == clinicalFeatures)&&(identical(other.differentialDiagnosis, differentialDiagnosis) || other.differentialDiagnosis == differentialDiagnosis)&&(identical(other.classificationMild, classificationMild) || other.classificationMild == classificationMild)&&(identical(other.classificationModerate, classificationModerate) || other.classificationModerate == classificationModerate)&&(identical(other.classificationSevere, classificationSevere) || other.classificationSevere == classificationSevere)&&(identical(other.classificationCritical, classificationCritical) || other.classificationCritical == classificationCritical)&&(identical(other.generalManagement, generalManagement) || other.generalManagement == generalManagement)&&(identical(other.medicationPrimary, medicationPrimary) || other.medicationPrimary == medicationPrimary)&&(identical(other.dosageAdult, dosageAdult) || other.dosageAdult == dosageAdult)&&(identical(other.dosagePediatric, dosagePediatric) || other.dosagePediatric == dosagePediatric)&&(identical(other.medicationSecondary, medicationSecondary) || other.medicationSecondary == medicationSecondary)&&(identical(other.dosageSecondaryAdult, dosageSecondaryAdult) || other.dosageSecondaryAdult == dosageSecondaryAdult)&&(identical(other.dosageSecondaryPediatric, dosageSecondaryPediatric) || other.dosageSecondaryPediatric == dosageSecondaryPediatric)&&(identical(other.healthcareLevelRequired, healthcareLevelRequired) || other.healthcareLevelRequired == healthcareLevelRequired)&&(identical(other.routeAdministration, routeAdministration) || other.routeAdministration == routeAdministration)&&(identical(other.monitoringRequirements, monitoringRequirements) || other.monitoringRequirements == monitoringRequirements)&&(identical(other.contraindications, contraindications) || other.contraindications == contraindications)&&(identical(other.preventionMeasures, preventionMeasures) || other.preventionMeasures == preventionMeasures)&&(identical(other.specialNotes, specialNotes) || other.specialNotes == specialNotes)&&(identical(other.status, status) || other.status == status)&&(identical(other.isPublished, isPublished) || other.isPublished == isPublished)&&(identical(other.priority, priority) || other.priority == priority)&&const DeepCollectionEquality().equals(other.categories, categories)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.indexItem, indexItem) || other.indexItem == indexItem)&&(identical(other.usageCount, usageCount) || other.usageCount == usageCount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,conditionName,icd10Code,targetPopulation,version,definition,causes,clinicalFeatures,differentialDiagnosis,classificationMild,classificationModerate,classificationSevere,classificationCritical,generalManagement,medicationPrimary,dosageAdult,dosagePediatric,medicationSecondary,dosageSecondaryAdult,dosageSecondaryPediatric,healthcareLevelRequired,routeAdministration,monitoringRequirements,contraindications,preventionMeasures,specialNotes,status,isPublished,priority,const DeepCollectionEquality().hash(categories),const DeepCollectionEquality().hash(tags),indexItem,usageCount,createdAt,updatedAt]);

@override
String toString() {
  return 'Guideline(id: $id, conditionName: $conditionName, icd10Code: $icd10Code, targetPopulation: $targetPopulation, version: $version, definition: $definition, causes: $causes, clinicalFeatures: $clinicalFeatures, differentialDiagnosis: $differentialDiagnosis, classificationMild: $classificationMild, classificationModerate: $classificationModerate, classificationSevere: $classificationSevere, classificationCritical: $classificationCritical, generalManagement: $generalManagement, medicationPrimary: $medicationPrimary, dosageAdult: $dosageAdult, dosagePediatric: $dosagePediatric, medicationSecondary: $medicationSecondary, dosageSecondaryAdult: $dosageSecondaryAdult, dosageSecondaryPediatric: $dosageSecondaryPediatric, healthcareLevelRequired: $healthcareLevelRequired, routeAdministration: $routeAdministration, monitoringRequirements: $monitoringRequirements, contraindications: $contraindications, preventionMeasures: $preventionMeasures, specialNotes: $specialNotes, status: $status, isPublished: $isPublished, priority: $priority, categories: $categories, tags: $tags, indexItem: $indexItem, usageCount: $usageCount, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $GuidelineCopyWith<$Res>  {
  factory $GuidelineCopyWith(Guideline value, $Res Function(Guideline) _then) = _$GuidelineCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'condition_name') String conditionName,@JsonKey(name: 'icd10_code') String icd10Code,@JsonKey(name: 'target_population') String targetPopulation, String version, String definition, String causes,@JsonKey(name: 'clinical_features') String clinicalFeatures,@JsonKey(name: 'differential_diagnosis') String differentialDiagnosis,@JsonKey(name: 'classification_mild') String classificationMild,@JsonKey(name: 'classification_moderate') String classificationModerate,@JsonKey(name: 'classification_severe') String classificationSevere,@JsonKey(name: 'classification_critical') String classificationCritical,@JsonKey(name: 'general_management') String generalManagement,@JsonKey(name: 'medication_primary') String medicationPrimary,@JsonKey(name: 'dosage_adult') String dosageAdult,@JsonKey(name: 'dosage_pediatric') String dosagePediatric,@JsonKey(name: 'medication_secondary') String medicationSecondary,@JsonKey(name: 'dosage_secondary_adult') String dosageSecondaryAdult,@JsonKey(name: 'dosage_secondary_pediatric') String dosageSecondaryPediatric,@JsonKey(name: 'healthcare_level_required') String healthcareLevelRequired,@JsonKey(name: 'route_administration') String routeAdministration,@JsonKey(name: 'monitoring_requirements') String monitoringRequirements, String contraindications,@JsonKey(name: 'prevention_measures') String preventionMeasures,@JsonKey(name: 'special_notes') String specialNotes, String status,@JsonKey(name: 'is_published') bool isPublished, String priority, List<GuidelineCategory> categories, List<GuidelineTag> tags,@JsonKey(name: 'index_item') GuidelineIndex? indexItem,@JsonKey(name: 'usage_count') int usageCount,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});


$GuidelineIndexCopyWith<$Res>? get indexItem;

}
/// @nodoc
class _$GuidelineCopyWithImpl<$Res>
    implements $GuidelineCopyWith<$Res> {
  _$GuidelineCopyWithImpl(this._self, this._then);

  final Guideline _self;
  final $Res Function(Guideline) _then;

/// Create a copy of Guideline
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? conditionName = null,Object? icd10Code = null,Object? targetPopulation = null,Object? version = null,Object? definition = null,Object? causes = null,Object? clinicalFeatures = null,Object? differentialDiagnosis = null,Object? classificationMild = null,Object? classificationModerate = null,Object? classificationSevere = null,Object? classificationCritical = null,Object? generalManagement = null,Object? medicationPrimary = null,Object? dosageAdult = null,Object? dosagePediatric = null,Object? medicationSecondary = null,Object? dosageSecondaryAdult = null,Object? dosageSecondaryPediatric = null,Object? healthcareLevelRequired = null,Object? routeAdministration = null,Object? monitoringRequirements = null,Object? contraindications = null,Object? preventionMeasures = null,Object? specialNotes = null,Object? status = null,Object? isPublished = null,Object? priority = null,Object? categories = null,Object? tags = null,Object? indexItem = freezed,Object? usageCount = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,conditionName: null == conditionName ? _self.conditionName : conditionName // ignore: cast_nullable_to_non_nullable
as String,icd10Code: null == icd10Code ? _self.icd10Code : icd10Code // ignore: cast_nullable_to_non_nullable
as String,targetPopulation: null == targetPopulation ? _self.targetPopulation : targetPopulation // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,definition: null == definition ? _self.definition : definition // ignore: cast_nullable_to_non_nullable
as String,causes: null == causes ? _self.causes : causes // ignore: cast_nullable_to_non_nullable
as String,clinicalFeatures: null == clinicalFeatures ? _self.clinicalFeatures : clinicalFeatures // ignore: cast_nullable_to_non_nullable
as String,differentialDiagnosis: null == differentialDiagnosis ? _self.differentialDiagnosis : differentialDiagnosis // ignore: cast_nullable_to_non_nullable
as String,classificationMild: null == classificationMild ? _self.classificationMild : classificationMild // ignore: cast_nullable_to_non_nullable
as String,classificationModerate: null == classificationModerate ? _self.classificationModerate : classificationModerate // ignore: cast_nullable_to_non_nullable
as String,classificationSevere: null == classificationSevere ? _self.classificationSevere : classificationSevere // ignore: cast_nullable_to_non_nullable
as String,classificationCritical: null == classificationCritical ? _self.classificationCritical : classificationCritical // ignore: cast_nullable_to_non_nullable
as String,generalManagement: null == generalManagement ? _self.generalManagement : generalManagement // ignore: cast_nullable_to_non_nullable
as String,medicationPrimary: null == medicationPrimary ? _self.medicationPrimary : medicationPrimary // ignore: cast_nullable_to_non_nullable
as String,dosageAdult: null == dosageAdult ? _self.dosageAdult : dosageAdult // ignore: cast_nullable_to_non_nullable
as String,dosagePediatric: null == dosagePediatric ? _self.dosagePediatric : dosagePediatric // ignore: cast_nullable_to_non_nullable
as String,medicationSecondary: null == medicationSecondary ? _self.medicationSecondary : medicationSecondary // ignore: cast_nullable_to_non_nullable
as String,dosageSecondaryAdult: null == dosageSecondaryAdult ? _self.dosageSecondaryAdult : dosageSecondaryAdult // ignore: cast_nullable_to_non_nullable
as String,dosageSecondaryPediatric: null == dosageSecondaryPediatric ? _self.dosageSecondaryPediatric : dosageSecondaryPediatric // ignore: cast_nullable_to_non_nullable
as String,healthcareLevelRequired: null == healthcareLevelRequired ? _self.healthcareLevelRequired : healthcareLevelRequired // ignore: cast_nullable_to_non_nullable
as String,routeAdministration: null == routeAdministration ? _self.routeAdministration : routeAdministration // ignore: cast_nullable_to_non_nullable
as String,monitoringRequirements: null == monitoringRequirements ? _self.monitoringRequirements : monitoringRequirements // ignore: cast_nullable_to_non_nullable
as String,contraindications: null == contraindications ? _self.contraindications : contraindications // ignore: cast_nullable_to_non_nullable
as String,preventionMeasures: null == preventionMeasures ? _self.preventionMeasures : preventionMeasures // ignore: cast_nullable_to_non_nullable
as String,specialNotes: null == specialNotes ? _self.specialNotes : specialNotes // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,isPublished: null == isPublished ? _self.isPublished : isPublished // ignore: cast_nullable_to_non_nullable
as bool,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as String,categories: null == categories ? _self.categories : categories // ignore: cast_nullable_to_non_nullable
as List<GuidelineCategory>,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<GuidelineTag>,indexItem: freezed == indexItem ? _self.indexItem : indexItem // ignore: cast_nullable_to_non_nullable
as GuidelineIndex?,usageCount: null == usageCount ? _self.usageCount : usageCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of Guideline
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GuidelineIndexCopyWith<$Res>? get indexItem {
    if (_self.indexItem == null) {
    return null;
  }

  return $GuidelineIndexCopyWith<$Res>(_self.indexItem!, (value) {
    return _then(_self.copyWith(indexItem: value));
  });
}
}


/// @nodoc

@JsonSerializable(explicitToJson: true)
class _Guideline extends Guideline {
  const _Guideline({required this.id, @JsonKey(name: 'condition_name') this.conditionName = '', @JsonKey(name: 'icd10_code') this.icd10Code = '', @JsonKey(name: 'target_population') this.targetPopulation = '', this.version = '', this.definition = '', this.causes = '', @JsonKey(name: 'clinical_features') this.clinicalFeatures = '', @JsonKey(name: 'differential_diagnosis') this.differentialDiagnosis = '', @JsonKey(name: 'classification_mild') this.classificationMild = '', @JsonKey(name: 'classification_moderate') this.classificationModerate = '', @JsonKey(name: 'classification_severe') this.classificationSevere = '', @JsonKey(name: 'classification_critical') this.classificationCritical = '', @JsonKey(name: 'general_management') this.generalManagement = '', @JsonKey(name: 'medication_primary') this.medicationPrimary = '', @JsonKey(name: 'dosage_adult') this.dosageAdult = '', @JsonKey(name: 'dosage_pediatric') this.dosagePediatric = '', @JsonKey(name: 'medication_secondary') this.medicationSecondary = '', @JsonKey(name: 'dosage_secondary_adult') this.dosageSecondaryAdult = '', @JsonKey(name: 'dosage_secondary_pediatric') this.dosageSecondaryPediatric = '', @JsonKey(name: 'healthcare_level_required') this.healthcareLevelRequired = '', @JsonKey(name: 'route_administration') this.routeAdministration = '', @JsonKey(name: 'monitoring_requirements') this.monitoringRequirements = '', this.contraindications = '', @JsonKey(name: 'prevention_measures') this.preventionMeasures = '', @JsonKey(name: 'special_notes') this.specialNotes = '', this.status = '', @JsonKey(name: 'is_published') this.isPublished = false, this.priority = '', final  List<GuidelineCategory> categories = const [], final  List<GuidelineTag> tags = const [], @JsonKey(name: 'index_item') this.indexItem, @JsonKey(name: 'usage_count') this.usageCount = 0, @JsonKey(name: 'created_at')@NullableDateTimeConverter() this.createdAt, @JsonKey(name: 'updated_at')@NullableDateTimeConverter() this.updatedAt}): _categories = categories,_tags = tags,super._();
  factory _Guideline.fromJson(Map<String, dynamic> json) => _$GuidelineFromJson(json);

@override final  String id;
@override@JsonKey(name: 'condition_name') final  String conditionName;
@override@JsonKey(name: 'icd10_code') final  String icd10Code;
@override@JsonKey(name: 'target_population') final  String targetPopulation;
@override@JsonKey() final  String version;
@override@JsonKey() final  String definition;
@override@JsonKey() final  String causes;
@override@JsonKey(name: 'clinical_features') final  String clinicalFeatures;
@override@JsonKey(name: 'differential_diagnosis') final  String differentialDiagnosis;
@override@JsonKey(name: 'classification_mild') final  String classificationMild;
@override@JsonKey(name: 'classification_moderate') final  String classificationModerate;
@override@JsonKey(name: 'classification_severe') final  String classificationSevere;
@override@JsonKey(name: 'classification_critical') final  String classificationCritical;
@override@JsonKey(name: 'general_management') final  String generalManagement;
@override@JsonKey(name: 'medication_primary') final  String medicationPrimary;
@override@JsonKey(name: 'dosage_adult') final  String dosageAdult;
@override@JsonKey(name: 'dosage_pediatric') final  String dosagePediatric;
@override@JsonKey(name: 'medication_secondary') final  String medicationSecondary;
@override@JsonKey(name: 'dosage_secondary_adult') final  String dosageSecondaryAdult;
@override@JsonKey(name: 'dosage_secondary_pediatric') final  String dosageSecondaryPediatric;
@override@JsonKey(name: 'healthcare_level_required') final  String healthcareLevelRequired;
@override@JsonKey(name: 'route_administration') final  String routeAdministration;
@override@JsonKey(name: 'monitoring_requirements') final  String monitoringRequirements;
@override@JsonKey() final  String contraindications;
@override@JsonKey(name: 'prevention_measures') final  String preventionMeasures;
@override@JsonKey(name: 'special_notes') final  String specialNotes;
@override@JsonKey() final  String status;
@override@JsonKey(name: 'is_published') final  bool isPublished;
@override@JsonKey() final  String priority;
 final  List<GuidelineCategory> _categories;
@override@JsonKey() List<GuidelineCategory> get categories {
  if (_categories is EqualUnmodifiableListView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categories);
}

 final  List<GuidelineTag> _tags;
@override@JsonKey() List<GuidelineTag> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

@override@JsonKey(name: 'index_item') final  GuidelineIndex? indexItem;
@override@JsonKey(name: 'usage_count') final  int usageCount;
@override@JsonKey(name: 'created_at')@NullableDateTimeConverter() final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at')@NullableDateTimeConverter() final  DateTime? updatedAt;

/// Create a copy of Guideline
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GuidelineCopyWith<_Guideline> get copyWith => __$GuidelineCopyWithImpl<_Guideline>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GuidelineToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Guideline&&(identical(other.id, id) || other.id == id)&&(identical(other.conditionName, conditionName) || other.conditionName == conditionName)&&(identical(other.icd10Code, icd10Code) || other.icd10Code == icd10Code)&&(identical(other.targetPopulation, targetPopulation) || other.targetPopulation == targetPopulation)&&(identical(other.version, version) || other.version == version)&&(identical(other.definition, definition) || other.definition == definition)&&(identical(other.causes, causes) || other.causes == causes)&&(identical(other.clinicalFeatures, clinicalFeatures) || other.clinicalFeatures == clinicalFeatures)&&(identical(other.differentialDiagnosis, differentialDiagnosis) || other.differentialDiagnosis == differentialDiagnosis)&&(identical(other.classificationMild, classificationMild) || other.classificationMild == classificationMild)&&(identical(other.classificationModerate, classificationModerate) || other.classificationModerate == classificationModerate)&&(identical(other.classificationSevere, classificationSevere) || other.classificationSevere == classificationSevere)&&(identical(other.classificationCritical, classificationCritical) || other.classificationCritical == classificationCritical)&&(identical(other.generalManagement, generalManagement) || other.generalManagement == generalManagement)&&(identical(other.medicationPrimary, medicationPrimary) || other.medicationPrimary == medicationPrimary)&&(identical(other.dosageAdult, dosageAdult) || other.dosageAdult == dosageAdult)&&(identical(other.dosagePediatric, dosagePediatric) || other.dosagePediatric == dosagePediatric)&&(identical(other.medicationSecondary, medicationSecondary) || other.medicationSecondary == medicationSecondary)&&(identical(other.dosageSecondaryAdult, dosageSecondaryAdult) || other.dosageSecondaryAdult == dosageSecondaryAdult)&&(identical(other.dosageSecondaryPediatric, dosageSecondaryPediatric) || other.dosageSecondaryPediatric == dosageSecondaryPediatric)&&(identical(other.healthcareLevelRequired, healthcareLevelRequired) || other.healthcareLevelRequired == healthcareLevelRequired)&&(identical(other.routeAdministration, routeAdministration) || other.routeAdministration == routeAdministration)&&(identical(other.monitoringRequirements, monitoringRequirements) || other.monitoringRequirements == monitoringRequirements)&&(identical(other.contraindications, contraindications) || other.contraindications == contraindications)&&(identical(other.preventionMeasures, preventionMeasures) || other.preventionMeasures == preventionMeasures)&&(identical(other.specialNotes, specialNotes) || other.specialNotes == specialNotes)&&(identical(other.status, status) || other.status == status)&&(identical(other.isPublished, isPublished) || other.isPublished == isPublished)&&(identical(other.priority, priority) || other.priority == priority)&&const DeepCollectionEquality().equals(other._categories, _categories)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.indexItem, indexItem) || other.indexItem == indexItem)&&(identical(other.usageCount, usageCount) || other.usageCount == usageCount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,conditionName,icd10Code,targetPopulation,version,definition,causes,clinicalFeatures,differentialDiagnosis,classificationMild,classificationModerate,classificationSevere,classificationCritical,generalManagement,medicationPrimary,dosageAdult,dosagePediatric,medicationSecondary,dosageSecondaryAdult,dosageSecondaryPediatric,healthcareLevelRequired,routeAdministration,monitoringRequirements,contraindications,preventionMeasures,specialNotes,status,isPublished,priority,const DeepCollectionEquality().hash(_categories),const DeepCollectionEquality().hash(_tags),indexItem,usageCount,createdAt,updatedAt]);

@override
String toString() {
  return 'Guideline(id: $id, conditionName: $conditionName, icd10Code: $icd10Code, targetPopulation: $targetPopulation, version: $version, definition: $definition, causes: $causes, clinicalFeatures: $clinicalFeatures, differentialDiagnosis: $differentialDiagnosis, classificationMild: $classificationMild, classificationModerate: $classificationModerate, classificationSevere: $classificationSevere, classificationCritical: $classificationCritical, generalManagement: $generalManagement, medicationPrimary: $medicationPrimary, dosageAdult: $dosageAdult, dosagePediatric: $dosagePediatric, medicationSecondary: $medicationSecondary, dosageSecondaryAdult: $dosageSecondaryAdult, dosageSecondaryPediatric: $dosageSecondaryPediatric, healthcareLevelRequired: $healthcareLevelRequired, routeAdministration: $routeAdministration, monitoringRequirements: $monitoringRequirements, contraindications: $contraindications, preventionMeasures: $preventionMeasures, specialNotes: $specialNotes, status: $status, isPublished: $isPublished, priority: $priority, categories: $categories, tags: $tags, indexItem: $indexItem, usageCount: $usageCount, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$GuidelineCopyWith<$Res> implements $GuidelineCopyWith<$Res> {
  factory _$GuidelineCopyWith(_Guideline value, $Res Function(_Guideline) _then) = __$GuidelineCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'condition_name') String conditionName,@JsonKey(name: 'icd10_code') String icd10Code,@JsonKey(name: 'target_population') String targetPopulation, String version, String definition, String causes,@JsonKey(name: 'clinical_features') String clinicalFeatures,@JsonKey(name: 'differential_diagnosis') String differentialDiagnosis,@JsonKey(name: 'classification_mild') String classificationMild,@JsonKey(name: 'classification_moderate') String classificationModerate,@JsonKey(name: 'classification_severe') String classificationSevere,@JsonKey(name: 'classification_critical') String classificationCritical,@JsonKey(name: 'general_management') String generalManagement,@JsonKey(name: 'medication_primary') String medicationPrimary,@JsonKey(name: 'dosage_adult') String dosageAdult,@JsonKey(name: 'dosage_pediatric') String dosagePediatric,@JsonKey(name: 'medication_secondary') String medicationSecondary,@JsonKey(name: 'dosage_secondary_adult') String dosageSecondaryAdult,@JsonKey(name: 'dosage_secondary_pediatric') String dosageSecondaryPediatric,@JsonKey(name: 'healthcare_level_required') String healthcareLevelRequired,@JsonKey(name: 'route_administration') String routeAdministration,@JsonKey(name: 'monitoring_requirements') String monitoringRequirements, String contraindications,@JsonKey(name: 'prevention_measures') String preventionMeasures,@JsonKey(name: 'special_notes') String specialNotes, String status,@JsonKey(name: 'is_published') bool isPublished, String priority, List<GuidelineCategory> categories, List<GuidelineTag> tags,@JsonKey(name: 'index_item') GuidelineIndex? indexItem,@JsonKey(name: 'usage_count') int usageCount,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});


@override $GuidelineIndexCopyWith<$Res>? get indexItem;

}
/// @nodoc
class __$GuidelineCopyWithImpl<$Res>
    implements _$GuidelineCopyWith<$Res> {
  __$GuidelineCopyWithImpl(this._self, this._then);

  final _Guideline _self;
  final $Res Function(_Guideline) _then;

/// Create a copy of Guideline
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? conditionName = null,Object? icd10Code = null,Object? targetPopulation = null,Object? version = null,Object? definition = null,Object? causes = null,Object? clinicalFeatures = null,Object? differentialDiagnosis = null,Object? classificationMild = null,Object? classificationModerate = null,Object? classificationSevere = null,Object? classificationCritical = null,Object? generalManagement = null,Object? medicationPrimary = null,Object? dosageAdult = null,Object? dosagePediatric = null,Object? medicationSecondary = null,Object? dosageSecondaryAdult = null,Object? dosageSecondaryPediatric = null,Object? healthcareLevelRequired = null,Object? routeAdministration = null,Object? monitoringRequirements = null,Object? contraindications = null,Object? preventionMeasures = null,Object? specialNotes = null,Object? status = null,Object? isPublished = null,Object? priority = null,Object? categories = null,Object? tags = null,Object? indexItem = freezed,Object? usageCount = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_Guideline(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,conditionName: null == conditionName ? _self.conditionName : conditionName // ignore: cast_nullable_to_non_nullable
as String,icd10Code: null == icd10Code ? _self.icd10Code : icd10Code // ignore: cast_nullable_to_non_nullable
as String,targetPopulation: null == targetPopulation ? _self.targetPopulation : targetPopulation // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,definition: null == definition ? _self.definition : definition // ignore: cast_nullable_to_non_nullable
as String,causes: null == causes ? _self.causes : causes // ignore: cast_nullable_to_non_nullable
as String,clinicalFeatures: null == clinicalFeatures ? _self.clinicalFeatures : clinicalFeatures // ignore: cast_nullable_to_non_nullable
as String,differentialDiagnosis: null == differentialDiagnosis ? _self.differentialDiagnosis : differentialDiagnosis // ignore: cast_nullable_to_non_nullable
as String,classificationMild: null == classificationMild ? _self.classificationMild : classificationMild // ignore: cast_nullable_to_non_nullable
as String,classificationModerate: null == classificationModerate ? _self.classificationModerate : classificationModerate // ignore: cast_nullable_to_non_nullable
as String,classificationSevere: null == classificationSevere ? _self.classificationSevere : classificationSevere // ignore: cast_nullable_to_non_nullable
as String,classificationCritical: null == classificationCritical ? _self.classificationCritical : classificationCritical // ignore: cast_nullable_to_non_nullable
as String,generalManagement: null == generalManagement ? _self.generalManagement : generalManagement // ignore: cast_nullable_to_non_nullable
as String,medicationPrimary: null == medicationPrimary ? _self.medicationPrimary : medicationPrimary // ignore: cast_nullable_to_non_nullable
as String,dosageAdult: null == dosageAdult ? _self.dosageAdult : dosageAdult // ignore: cast_nullable_to_non_nullable
as String,dosagePediatric: null == dosagePediatric ? _self.dosagePediatric : dosagePediatric // ignore: cast_nullable_to_non_nullable
as String,medicationSecondary: null == medicationSecondary ? _self.medicationSecondary : medicationSecondary // ignore: cast_nullable_to_non_nullable
as String,dosageSecondaryAdult: null == dosageSecondaryAdult ? _self.dosageSecondaryAdult : dosageSecondaryAdult // ignore: cast_nullable_to_non_nullable
as String,dosageSecondaryPediatric: null == dosageSecondaryPediatric ? _self.dosageSecondaryPediatric : dosageSecondaryPediatric // ignore: cast_nullable_to_non_nullable
as String,healthcareLevelRequired: null == healthcareLevelRequired ? _self.healthcareLevelRequired : healthcareLevelRequired // ignore: cast_nullable_to_non_nullable
as String,routeAdministration: null == routeAdministration ? _self.routeAdministration : routeAdministration // ignore: cast_nullable_to_non_nullable
as String,monitoringRequirements: null == monitoringRequirements ? _self.monitoringRequirements : monitoringRequirements // ignore: cast_nullable_to_non_nullable
as String,contraindications: null == contraindications ? _self.contraindications : contraindications // ignore: cast_nullable_to_non_nullable
as String,preventionMeasures: null == preventionMeasures ? _self.preventionMeasures : preventionMeasures // ignore: cast_nullable_to_non_nullable
as String,specialNotes: null == specialNotes ? _self.specialNotes : specialNotes // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,isPublished: null == isPublished ? _self.isPublished : isPublished // ignore: cast_nullable_to_non_nullable
as bool,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as String,categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<GuidelineCategory>,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<GuidelineTag>,indexItem: freezed == indexItem ? _self.indexItem : indexItem // ignore: cast_nullable_to_non_nullable
as GuidelineIndex?,usageCount: null == usageCount ? _self.usageCount : usageCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of Guideline
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GuidelineIndexCopyWith<$Res>? get indexItem {
    if (_self.indexItem == null) {
    return null;
  }

  return $GuidelineIndexCopyWith<$Res>(_self.indexItem!, (value) {
    return _then(_self.copyWith(indexItem: value));
  });
}
}

// dart format on
