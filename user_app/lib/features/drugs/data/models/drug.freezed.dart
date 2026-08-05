// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'drug.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Drug {

 String get id; String get name;@JsonKey(name: 'brand_names') String get brandNames; String get description;@JsonKey(name: 'mechanism_of_action') String get mechanismOfAction;@JsonKey(name: 'adult_dose') String get adultDose;@JsonKey(name: 'pediatric_dose') String get pediatricDose;@JsonKey(name: 'elderly_dose') String get elderlyDose;@JsonKey(name: 'max_daily_dose') String get maxDailyDose; List<RouteOfAdministration> get routeOfAdministration; String get frequency; String get duration; String get indications; String get contraindications;@JsonKey(name: 'side_effects') String get sideEffects; String get warnings;@JsonKey(name: 'monitoring_parameters') String get monitoringParameters; PregnancyCategory? get pregnancyCategory;@JsonKey(name: 'clinical_notes') String get clinicalNotes; List<DrugCategory> get categories; List<DrugTag> get tags;@JsonKey(name: 'drug_class') DrugClass? get drugClass;@JsonKey(name: 'therapeutic_category') TherapeuticCategory? get therapeuticCategory;@JsonKey(name: 'who_eml_status') bool get whoEmlStatus;@JsonKey(name: 'antimicrobial_status') bool get antimicrobialStatus; ControlledSubstance? get controlledSubstance; DrugStatus get status;@JsonKey(name: 'review_status') ReviewStatus get reviewStatus;@JsonKey(name: 'search_keywords') String get searchKeywords;@JsonKey(name: 'reference_text') String get references;@JsonKey(name: 'usage_count') int get usageCount;@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? get createdAt;@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? get updatedAt;
/// Create a copy of Drug
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DrugCopyWith<Drug> get copyWith => _$DrugCopyWithImpl<Drug>(this as Drug, _$identity);

  /// Serializes this Drug to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Drug&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.brandNames, brandNames) || other.brandNames == brandNames)&&(identical(other.description, description) || other.description == description)&&(identical(other.mechanismOfAction, mechanismOfAction) || other.mechanismOfAction == mechanismOfAction)&&(identical(other.adultDose, adultDose) || other.adultDose == adultDose)&&(identical(other.pediatricDose, pediatricDose) || other.pediatricDose == pediatricDose)&&(identical(other.elderlyDose, elderlyDose) || other.elderlyDose == elderlyDose)&&(identical(other.maxDailyDose, maxDailyDose) || other.maxDailyDose == maxDailyDose)&&const DeepCollectionEquality().equals(other.routeOfAdministration, routeOfAdministration)&&(identical(other.frequency, frequency) || other.frequency == frequency)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.indications, indications) || other.indications == indications)&&(identical(other.contraindications, contraindications) || other.contraindications == contraindications)&&(identical(other.sideEffects, sideEffects) || other.sideEffects == sideEffects)&&(identical(other.warnings, warnings) || other.warnings == warnings)&&(identical(other.monitoringParameters, monitoringParameters) || other.monitoringParameters == monitoringParameters)&&(identical(other.pregnancyCategory, pregnancyCategory) || other.pregnancyCategory == pregnancyCategory)&&(identical(other.clinicalNotes, clinicalNotes) || other.clinicalNotes == clinicalNotes)&&const DeepCollectionEquality().equals(other.categories, categories)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.drugClass, drugClass) || other.drugClass == drugClass)&&(identical(other.therapeuticCategory, therapeuticCategory) || other.therapeuticCategory == therapeuticCategory)&&(identical(other.whoEmlStatus, whoEmlStatus) || other.whoEmlStatus == whoEmlStatus)&&(identical(other.antimicrobialStatus, antimicrobialStatus) || other.antimicrobialStatus == antimicrobialStatus)&&(identical(other.controlledSubstance, controlledSubstance) || other.controlledSubstance == controlledSubstance)&&(identical(other.status, status) || other.status == status)&&(identical(other.reviewStatus, reviewStatus) || other.reviewStatus == reviewStatus)&&(identical(other.searchKeywords, searchKeywords) || other.searchKeywords == searchKeywords)&&(identical(other.references, references) || other.references == references)&&(identical(other.usageCount, usageCount) || other.usageCount == usageCount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,name,brandNames,description,mechanismOfAction,adultDose,pediatricDose,elderlyDose,maxDailyDose,const DeepCollectionEquality().hash(routeOfAdministration),frequency,duration,indications,contraindications,sideEffects,warnings,monitoringParameters,pregnancyCategory,clinicalNotes,const DeepCollectionEquality().hash(categories),const DeepCollectionEquality().hash(tags),drugClass,therapeuticCategory,whoEmlStatus,antimicrobialStatus,controlledSubstance,status,reviewStatus,searchKeywords,references,usageCount,createdAt,updatedAt]);

@override
String toString() {
  return 'Drug(id: $id, name: $name, brandNames: $brandNames, description: $description, mechanismOfAction: $mechanismOfAction, adultDose: $adultDose, pediatricDose: $pediatricDose, elderlyDose: $elderlyDose, maxDailyDose: $maxDailyDose, routeOfAdministration: $routeOfAdministration, frequency: $frequency, duration: $duration, indications: $indications, contraindications: $contraindications, sideEffects: $sideEffects, warnings: $warnings, monitoringParameters: $monitoringParameters, pregnancyCategory: $pregnancyCategory, clinicalNotes: $clinicalNotes, categories: $categories, tags: $tags, drugClass: $drugClass, therapeuticCategory: $therapeuticCategory, whoEmlStatus: $whoEmlStatus, antimicrobialStatus: $antimicrobialStatus, controlledSubstance: $controlledSubstance, status: $status, reviewStatus: $reviewStatus, searchKeywords: $searchKeywords, references: $references, usageCount: $usageCount, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $DrugCopyWith<$Res>  {
  factory $DrugCopyWith(Drug value, $Res Function(Drug) _then) = _$DrugCopyWithImpl;
@useResult
$Res call({
 String id, String name,@JsonKey(name: 'brand_names') String brandNames, String description,@JsonKey(name: 'mechanism_of_action') String mechanismOfAction,@JsonKey(name: 'adult_dose') String adultDose,@JsonKey(name: 'pediatric_dose') String pediatricDose,@JsonKey(name: 'elderly_dose') String elderlyDose,@JsonKey(name: 'max_daily_dose') String maxDailyDose, List<RouteOfAdministration> routeOfAdministration, String frequency, String duration, String indications, String contraindications,@JsonKey(name: 'side_effects') String sideEffects, String warnings,@JsonKey(name: 'monitoring_parameters') String monitoringParameters, PregnancyCategory? pregnancyCategory,@JsonKey(name: 'clinical_notes') String clinicalNotes, List<DrugCategory> categories, List<DrugTag> tags,@JsonKey(name: 'drug_class') DrugClass? drugClass,@JsonKey(name: 'therapeutic_category') TherapeuticCategory? therapeuticCategory,@JsonKey(name: 'who_eml_status') bool whoEmlStatus,@JsonKey(name: 'antimicrobial_status') bool antimicrobialStatus, ControlledSubstance? controlledSubstance, DrugStatus status,@JsonKey(name: 'review_status') ReviewStatus reviewStatus,@JsonKey(name: 'search_keywords') String searchKeywords,@JsonKey(name: 'reference_text') String references,@JsonKey(name: 'usage_count') int usageCount,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});


$DrugClassCopyWith<$Res>? get drugClass;$TherapeuticCategoryCopyWith<$Res>? get therapeuticCategory;

}
/// @nodoc
class _$DrugCopyWithImpl<$Res>
    implements $DrugCopyWith<$Res> {
  _$DrugCopyWithImpl(this._self, this._then);

  final Drug _self;
  final $Res Function(Drug) _then;

/// Create a copy of Drug
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? brandNames = null,Object? description = null,Object? mechanismOfAction = null,Object? adultDose = null,Object? pediatricDose = null,Object? elderlyDose = null,Object? maxDailyDose = null,Object? routeOfAdministration = null,Object? frequency = null,Object? duration = null,Object? indications = null,Object? contraindications = null,Object? sideEffects = null,Object? warnings = null,Object? monitoringParameters = null,Object? pregnancyCategory = freezed,Object? clinicalNotes = null,Object? categories = null,Object? tags = null,Object? drugClass = freezed,Object? therapeuticCategory = freezed,Object? whoEmlStatus = null,Object? antimicrobialStatus = null,Object? controlledSubstance = freezed,Object? status = null,Object? reviewStatus = null,Object? searchKeywords = null,Object? references = null,Object? usageCount = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,brandNames: null == brandNames ? _self.brandNames : brandNames // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,mechanismOfAction: null == mechanismOfAction ? _self.mechanismOfAction : mechanismOfAction // ignore: cast_nullable_to_non_nullable
as String,adultDose: null == adultDose ? _self.adultDose : adultDose // ignore: cast_nullable_to_non_nullable
as String,pediatricDose: null == pediatricDose ? _self.pediatricDose : pediatricDose // ignore: cast_nullable_to_non_nullable
as String,elderlyDose: null == elderlyDose ? _self.elderlyDose : elderlyDose // ignore: cast_nullable_to_non_nullable
as String,maxDailyDose: null == maxDailyDose ? _self.maxDailyDose : maxDailyDose // ignore: cast_nullable_to_non_nullable
as String,routeOfAdministration: null == routeOfAdministration ? _self.routeOfAdministration : routeOfAdministration // ignore: cast_nullable_to_non_nullable
as List<RouteOfAdministration>,frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as String,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as String,indications: null == indications ? _self.indications : indications // ignore: cast_nullable_to_non_nullable
as String,contraindications: null == contraindications ? _self.contraindications : contraindications // ignore: cast_nullable_to_non_nullable
as String,sideEffects: null == sideEffects ? _self.sideEffects : sideEffects // ignore: cast_nullable_to_non_nullable
as String,warnings: null == warnings ? _self.warnings : warnings // ignore: cast_nullable_to_non_nullable
as String,monitoringParameters: null == monitoringParameters ? _self.monitoringParameters : monitoringParameters // ignore: cast_nullable_to_non_nullable
as String,pregnancyCategory: freezed == pregnancyCategory ? _self.pregnancyCategory : pregnancyCategory // ignore: cast_nullable_to_non_nullable
as PregnancyCategory?,clinicalNotes: null == clinicalNotes ? _self.clinicalNotes : clinicalNotes // ignore: cast_nullable_to_non_nullable
as String,categories: null == categories ? _self.categories : categories // ignore: cast_nullable_to_non_nullable
as List<DrugCategory>,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<DrugTag>,drugClass: freezed == drugClass ? _self.drugClass : drugClass // ignore: cast_nullable_to_non_nullable
as DrugClass?,therapeuticCategory: freezed == therapeuticCategory ? _self.therapeuticCategory : therapeuticCategory // ignore: cast_nullable_to_non_nullable
as TherapeuticCategory?,whoEmlStatus: null == whoEmlStatus ? _self.whoEmlStatus : whoEmlStatus // ignore: cast_nullable_to_non_nullable
as bool,antimicrobialStatus: null == antimicrobialStatus ? _self.antimicrobialStatus : antimicrobialStatus // ignore: cast_nullable_to_non_nullable
as bool,controlledSubstance: freezed == controlledSubstance ? _self.controlledSubstance : controlledSubstance // ignore: cast_nullable_to_non_nullable
as ControlledSubstance?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DrugStatus,reviewStatus: null == reviewStatus ? _self.reviewStatus : reviewStatus // ignore: cast_nullable_to_non_nullable
as ReviewStatus,searchKeywords: null == searchKeywords ? _self.searchKeywords : searchKeywords // ignore: cast_nullable_to_non_nullable
as String,references: null == references ? _self.references : references // ignore: cast_nullable_to_non_nullable
as String,usageCount: null == usageCount ? _self.usageCount : usageCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of Drug
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DrugClassCopyWith<$Res>? get drugClass {
    if (_self.drugClass == null) {
    return null;
  }

  return $DrugClassCopyWith<$Res>(_self.drugClass!, (value) {
    return _then(_self.copyWith(drugClass: value));
  });
}/// Create a copy of Drug
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TherapeuticCategoryCopyWith<$Res>? get therapeuticCategory {
    if (_self.therapeuticCategory == null) {
    return null;
  }

  return $TherapeuticCategoryCopyWith<$Res>(_self.therapeuticCategory!, (value) {
    return _then(_self.copyWith(therapeuticCategory: value));
  });
}
}


/// @nodoc

@JsonSerializable(explicitToJson: true)
class _Drug extends Drug {
  const _Drug({required this.id, this.name = '', @JsonKey(name: 'brand_names') this.brandNames = '', this.description = '', @JsonKey(name: 'mechanism_of_action') this.mechanismOfAction = '', @JsonKey(name: 'adult_dose') this.adultDose = '', @JsonKey(name: 'pediatric_dose') this.pediatricDose = '', @JsonKey(name: 'elderly_dose') this.elderlyDose = '', @JsonKey(name: 'max_daily_dose') this.maxDailyDose = '', final  List<RouteOfAdministration> routeOfAdministration = const [], this.frequency = '', this.duration = '', this.indications = '', this.contraindications = '', @JsonKey(name: 'side_effects') this.sideEffects = '', this.warnings = '', @JsonKey(name: 'monitoring_parameters') this.monitoringParameters = '', this.pregnancyCategory, @JsonKey(name: 'clinical_notes') this.clinicalNotes = '', final  List<DrugCategory> categories = const [], final  List<DrugTag> tags = const [], @JsonKey(name: 'drug_class') this.drugClass, @JsonKey(name: 'therapeutic_category') this.therapeuticCategory, @JsonKey(name: 'who_eml_status') this.whoEmlStatus = false, @JsonKey(name: 'antimicrobial_status') this.antimicrobialStatus = false, this.controlledSubstance, this.status = DrugStatus.active, @JsonKey(name: 'review_status') this.reviewStatus = ReviewStatus.pending, @JsonKey(name: 'search_keywords') this.searchKeywords = '', @JsonKey(name: 'reference_text') this.references = '', @JsonKey(name: 'usage_count') this.usageCount = 0, @JsonKey(name: 'created_at')@NullableDateTimeConverter() this.createdAt, @JsonKey(name: 'updated_at')@NullableDateTimeConverter() this.updatedAt}): _routeOfAdministration = routeOfAdministration,_categories = categories,_tags = tags,super._();
  factory _Drug.fromJson(Map<String, dynamic> json) => _$DrugFromJson(json);

@override final  String id;
@override@JsonKey() final  String name;
@override@JsonKey(name: 'brand_names') final  String brandNames;
@override@JsonKey() final  String description;
@override@JsonKey(name: 'mechanism_of_action') final  String mechanismOfAction;
@override@JsonKey(name: 'adult_dose') final  String adultDose;
@override@JsonKey(name: 'pediatric_dose') final  String pediatricDose;
@override@JsonKey(name: 'elderly_dose') final  String elderlyDose;
@override@JsonKey(name: 'max_daily_dose') final  String maxDailyDose;
 final  List<RouteOfAdministration> _routeOfAdministration;
@override@JsonKey() List<RouteOfAdministration> get routeOfAdministration {
  if (_routeOfAdministration is EqualUnmodifiableListView) return _routeOfAdministration;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_routeOfAdministration);
}

@override@JsonKey() final  String frequency;
@override@JsonKey() final  String duration;
@override@JsonKey() final  String indications;
@override@JsonKey() final  String contraindications;
@override@JsonKey(name: 'side_effects') final  String sideEffects;
@override@JsonKey() final  String warnings;
@override@JsonKey(name: 'monitoring_parameters') final  String monitoringParameters;
@override final  PregnancyCategory? pregnancyCategory;
@override@JsonKey(name: 'clinical_notes') final  String clinicalNotes;
 final  List<DrugCategory> _categories;
@override@JsonKey() List<DrugCategory> get categories {
  if (_categories is EqualUnmodifiableListView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categories);
}

 final  List<DrugTag> _tags;
@override@JsonKey() List<DrugTag> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

@override@JsonKey(name: 'drug_class') final  DrugClass? drugClass;
@override@JsonKey(name: 'therapeutic_category') final  TherapeuticCategory? therapeuticCategory;
@override@JsonKey(name: 'who_eml_status') final  bool whoEmlStatus;
@override@JsonKey(name: 'antimicrobial_status') final  bool antimicrobialStatus;
@override final  ControlledSubstance? controlledSubstance;
@override@JsonKey() final  DrugStatus status;
@override@JsonKey(name: 'review_status') final  ReviewStatus reviewStatus;
@override@JsonKey(name: 'search_keywords') final  String searchKeywords;
@override@JsonKey(name: 'reference_text') final  String references;
@override@JsonKey(name: 'usage_count') final  int usageCount;
@override@JsonKey(name: 'created_at')@NullableDateTimeConverter() final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at')@NullableDateTimeConverter() final  DateTime? updatedAt;

/// Create a copy of Drug
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DrugCopyWith<_Drug> get copyWith => __$DrugCopyWithImpl<_Drug>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DrugToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Drug&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.brandNames, brandNames) || other.brandNames == brandNames)&&(identical(other.description, description) || other.description == description)&&(identical(other.mechanismOfAction, mechanismOfAction) || other.mechanismOfAction == mechanismOfAction)&&(identical(other.adultDose, adultDose) || other.adultDose == adultDose)&&(identical(other.pediatricDose, pediatricDose) || other.pediatricDose == pediatricDose)&&(identical(other.elderlyDose, elderlyDose) || other.elderlyDose == elderlyDose)&&(identical(other.maxDailyDose, maxDailyDose) || other.maxDailyDose == maxDailyDose)&&const DeepCollectionEquality().equals(other._routeOfAdministration, _routeOfAdministration)&&(identical(other.frequency, frequency) || other.frequency == frequency)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.indications, indications) || other.indications == indications)&&(identical(other.contraindications, contraindications) || other.contraindications == contraindications)&&(identical(other.sideEffects, sideEffects) || other.sideEffects == sideEffects)&&(identical(other.warnings, warnings) || other.warnings == warnings)&&(identical(other.monitoringParameters, monitoringParameters) || other.monitoringParameters == monitoringParameters)&&(identical(other.pregnancyCategory, pregnancyCategory) || other.pregnancyCategory == pregnancyCategory)&&(identical(other.clinicalNotes, clinicalNotes) || other.clinicalNotes == clinicalNotes)&&const DeepCollectionEquality().equals(other._categories, _categories)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.drugClass, drugClass) || other.drugClass == drugClass)&&(identical(other.therapeuticCategory, therapeuticCategory) || other.therapeuticCategory == therapeuticCategory)&&(identical(other.whoEmlStatus, whoEmlStatus) || other.whoEmlStatus == whoEmlStatus)&&(identical(other.antimicrobialStatus, antimicrobialStatus) || other.antimicrobialStatus == antimicrobialStatus)&&(identical(other.controlledSubstance, controlledSubstance) || other.controlledSubstance == controlledSubstance)&&(identical(other.status, status) || other.status == status)&&(identical(other.reviewStatus, reviewStatus) || other.reviewStatus == reviewStatus)&&(identical(other.searchKeywords, searchKeywords) || other.searchKeywords == searchKeywords)&&(identical(other.references, references) || other.references == references)&&(identical(other.usageCount, usageCount) || other.usageCount == usageCount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,name,brandNames,description,mechanismOfAction,adultDose,pediatricDose,elderlyDose,maxDailyDose,const DeepCollectionEquality().hash(_routeOfAdministration),frequency,duration,indications,contraindications,sideEffects,warnings,monitoringParameters,pregnancyCategory,clinicalNotes,const DeepCollectionEquality().hash(_categories),const DeepCollectionEquality().hash(_tags),drugClass,therapeuticCategory,whoEmlStatus,antimicrobialStatus,controlledSubstance,status,reviewStatus,searchKeywords,references,usageCount,createdAt,updatedAt]);

@override
String toString() {
  return 'Drug(id: $id, name: $name, brandNames: $brandNames, description: $description, mechanismOfAction: $mechanismOfAction, adultDose: $adultDose, pediatricDose: $pediatricDose, elderlyDose: $elderlyDose, maxDailyDose: $maxDailyDose, routeOfAdministration: $routeOfAdministration, frequency: $frequency, duration: $duration, indications: $indications, contraindications: $contraindications, sideEffects: $sideEffects, warnings: $warnings, monitoringParameters: $monitoringParameters, pregnancyCategory: $pregnancyCategory, clinicalNotes: $clinicalNotes, categories: $categories, tags: $tags, drugClass: $drugClass, therapeuticCategory: $therapeuticCategory, whoEmlStatus: $whoEmlStatus, antimicrobialStatus: $antimicrobialStatus, controlledSubstance: $controlledSubstance, status: $status, reviewStatus: $reviewStatus, searchKeywords: $searchKeywords, references: $references, usageCount: $usageCount, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$DrugCopyWith<$Res> implements $DrugCopyWith<$Res> {
  factory _$DrugCopyWith(_Drug value, $Res Function(_Drug) _then) = __$DrugCopyWithImpl;
@override @useResult
$Res call({
 String id, String name,@JsonKey(name: 'brand_names') String brandNames, String description,@JsonKey(name: 'mechanism_of_action') String mechanismOfAction,@JsonKey(name: 'adult_dose') String adultDose,@JsonKey(name: 'pediatric_dose') String pediatricDose,@JsonKey(name: 'elderly_dose') String elderlyDose,@JsonKey(name: 'max_daily_dose') String maxDailyDose, List<RouteOfAdministration> routeOfAdministration, String frequency, String duration, String indications, String contraindications,@JsonKey(name: 'side_effects') String sideEffects, String warnings,@JsonKey(name: 'monitoring_parameters') String monitoringParameters, PregnancyCategory? pregnancyCategory,@JsonKey(name: 'clinical_notes') String clinicalNotes, List<DrugCategory> categories, List<DrugTag> tags,@JsonKey(name: 'drug_class') DrugClass? drugClass,@JsonKey(name: 'therapeutic_category') TherapeuticCategory? therapeuticCategory,@JsonKey(name: 'who_eml_status') bool whoEmlStatus,@JsonKey(name: 'antimicrobial_status') bool antimicrobialStatus, ControlledSubstance? controlledSubstance, DrugStatus status,@JsonKey(name: 'review_status') ReviewStatus reviewStatus,@JsonKey(name: 'search_keywords') String searchKeywords,@JsonKey(name: 'reference_text') String references,@JsonKey(name: 'usage_count') int usageCount,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});


@override $DrugClassCopyWith<$Res>? get drugClass;@override $TherapeuticCategoryCopyWith<$Res>? get therapeuticCategory;

}
/// @nodoc
class __$DrugCopyWithImpl<$Res>
    implements _$DrugCopyWith<$Res> {
  __$DrugCopyWithImpl(this._self, this._then);

  final _Drug _self;
  final $Res Function(_Drug) _then;

/// Create a copy of Drug
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? brandNames = null,Object? description = null,Object? mechanismOfAction = null,Object? adultDose = null,Object? pediatricDose = null,Object? elderlyDose = null,Object? maxDailyDose = null,Object? routeOfAdministration = null,Object? frequency = null,Object? duration = null,Object? indications = null,Object? contraindications = null,Object? sideEffects = null,Object? warnings = null,Object? monitoringParameters = null,Object? pregnancyCategory = freezed,Object? clinicalNotes = null,Object? categories = null,Object? tags = null,Object? drugClass = freezed,Object? therapeuticCategory = freezed,Object? whoEmlStatus = null,Object? antimicrobialStatus = null,Object? controlledSubstance = freezed,Object? status = null,Object? reviewStatus = null,Object? searchKeywords = null,Object? references = null,Object? usageCount = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_Drug(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,brandNames: null == brandNames ? _self.brandNames : brandNames // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,mechanismOfAction: null == mechanismOfAction ? _self.mechanismOfAction : mechanismOfAction // ignore: cast_nullable_to_non_nullable
as String,adultDose: null == adultDose ? _self.adultDose : adultDose // ignore: cast_nullable_to_non_nullable
as String,pediatricDose: null == pediatricDose ? _self.pediatricDose : pediatricDose // ignore: cast_nullable_to_non_nullable
as String,elderlyDose: null == elderlyDose ? _self.elderlyDose : elderlyDose // ignore: cast_nullable_to_non_nullable
as String,maxDailyDose: null == maxDailyDose ? _self.maxDailyDose : maxDailyDose // ignore: cast_nullable_to_non_nullable
as String,routeOfAdministration: null == routeOfAdministration ? _self._routeOfAdministration : routeOfAdministration // ignore: cast_nullable_to_non_nullable
as List<RouteOfAdministration>,frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as String,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as String,indications: null == indications ? _self.indications : indications // ignore: cast_nullable_to_non_nullable
as String,contraindications: null == contraindications ? _self.contraindications : contraindications // ignore: cast_nullable_to_non_nullable
as String,sideEffects: null == sideEffects ? _self.sideEffects : sideEffects // ignore: cast_nullable_to_non_nullable
as String,warnings: null == warnings ? _self.warnings : warnings // ignore: cast_nullable_to_non_nullable
as String,monitoringParameters: null == monitoringParameters ? _self.monitoringParameters : monitoringParameters // ignore: cast_nullable_to_non_nullable
as String,pregnancyCategory: freezed == pregnancyCategory ? _self.pregnancyCategory : pregnancyCategory // ignore: cast_nullable_to_non_nullable
as PregnancyCategory?,clinicalNotes: null == clinicalNotes ? _self.clinicalNotes : clinicalNotes // ignore: cast_nullable_to_non_nullable
as String,categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<DrugCategory>,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<DrugTag>,drugClass: freezed == drugClass ? _self.drugClass : drugClass // ignore: cast_nullable_to_non_nullable
as DrugClass?,therapeuticCategory: freezed == therapeuticCategory ? _self.therapeuticCategory : therapeuticCategory // ignore: cast_nullable_to_non_nullable
as TherapeuticCategory?,whoEmlStatus: null == whoEmlStatus ? _self.whoEmlStatus : whoEmlStatus // ignore: cast_nullable_to_non_nullable
as bool,antimicrobialStatus: null == antimicrobialStatus ? _self.antimicrobialStatus : antimicrobialStatus // ignore: cast_nullable_to_non_nullable
as bool,controlledSubstance: freezed == controlledSubstance ? _self.controlledSubstance : controlledSubstance // ignore: cast_nullable_to_non_nullable
as ControlledSubstance?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DrugStatus,reviewStatus: null == reviewStatus ? _self.reviewStatus : reviewStatus // ignore: cast_nullable_to_non_nullable
as ReviewStatus,searchKeywords: null == searchKeywords ? _self.searchKeywords : searchKeywords // ignore: cast_nullable_to_non_nullable
as String,references: null == references ? _self.references : references // ignore: cast_nullable_to_non_nullable
as String,usageCount: null == usageCount ? _self.usageCount : usageCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of Drug
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DrugClassCopyWith<$Res>? get drugClass {
    if (_self.drugClass == null) {
    return null;
  }

  return $DrugClassCopyWith<$Res>(_self.drugClass!, (value) {
    return _then(_self.copyWith(drugClass: value));
  });
}/// Create a copy of Drug
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TherapeuticCategoryCopyWith<$Res>? get therapeuticCategory {
    if (_self.therapeuticCategory == null) {
    return null;
  }

  return $TherapeuticCategoryCopyWith<$Res>(_self.therapeuticCategory!, (value) {
    return _then(_self.copyWith(therapeuticCategory: value));
  });
}
}

// dart format on
