// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'guideline_publication.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GuidelinePublication {

 String get id; String get slug; String get title; String get description; String get country;@JsonKey(name: 'source_org') String get sourceOrganization;@JsonKey(name: 'program_area') String get programArea; String get language;@JsonKey(name: 'publication_date') String get publicationDate;@JsonKey(name: 'review_date') String get reviewDate; String get version;@JsonKey(name: 'last_updated') DateTime? get lastUpdated;@JsonKey(name: 'intended_population') String get intendedPopulation;@JsonKey(name: 'healthcare_level') String get healthcareLevel;
/// Create a copy of GuidelinePublication
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GuidelinePublicationCopyWith<GuidelinePublication> get copyWith => _$GuidelinePublicationCopyWithImpl<GuidelinePublication>(this as GuidelinePublication, _$identity);

  /// Serializes this GuidelinePublication to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GuidelinePublication&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.country, country) || other.country == country)&&(identical(other.sourceOrganization, sourceOrganization) || other.sourceOrganization == sourceOrganization)&&(identical(other.programArea, programArea) || other.programArea == programArea)&&(identical(other.language, language) || other.language == language)&&(identical(other.publicationDate, publicationDate) || other.publicationDate == publicationDate)&&(identical(other.reviewDate, reviewDate) || other.reviewDate == reviewDate)&&(identical(other.version, version) || other.version == version)&&(identical(other.lastUpdated, lastUpdated) || other.lastUpdated == lastUpdated)&&(identical(other.intendedPopulation, intendedPopulation) || other.intendedPopulation == intendedPopulation)&&(identical(other.healthcareLevel, healthcareLevel) || other.healthcareLevel == healthcareLevel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,title,description,country,sourceOrganization,programArea,language,publicationDate,reviewDate,version,lastUpdated,intendedPopulation,healthcareLevel);

@override
String toString() {
  return 'GuidelinePublication(id: $id, slug: $slug, title: $title, description: $description, country: $country, sourceOrganization: $sourceOrganization, programArea: $programArea, language: $language, publicationDate: $publicationDate, reviewDate: $reviewDate, version: $version, lastUpdated: $lastUpdated, intendedPopulation: $intendedPopulation, healthcareLevel: $healthcareLevel)';
}


}

/// @nodoc
abstract mixin class $GuidelinePublicationCopyWith<$Res>  {
  factory $GuidelinePublicationCopyWith(GuidelinePublication value, $Res Function(GuidelinePublication) _then) = _$GuidelinePublicationCopyWithImpl;
@useResult
$Res call({
 String id, String slug, String title, String description, String country,@JsonKey(name: 'source_org') String sourceOrganization,@JsonKey(name: 'program_area') String programArea, String language,@JsonKey(name: 'publication_date') String publicationDate,@JsonKey(name: 'review_date') String reviewDate, String version,@JsonKey(name: 'last_updated') DateTime? lastUpdated,@JsonKey(name: 'intended_population') String intendedPopulation,@JsonKey(name: 'healthcare_level') String healthcareLevel
});




}
/// @nodoc
class _$GuidelinePublicationCopyWithImpl<$Res>
    implements $GuidelinePublicationCopyWith<$Res> {
  _$GuidelinePublicationCopyWithImpl(this._self, this._then);

  final GuidelinePublication _self;
  final $Res Function(GuidelinePublication) _then;

/// Create a copy of GuidelinePublication
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? slug = null,Object? title = null,Object? description = null,Object? country = null,Object? sourceOrganization = null,Object? programArea = null,Object? language = null,Object? publicationDate = null,Object? reviewDate = null,Object? version = null,Object? lastUpdated = freezed,Object? intendedPopulation = null,Object? healthcareLevel = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,country: null == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String,sourceOrganization: null == sourceOrganization ? _self.sourceOrganization : sourceOrganization // ignore: cast_nullable_to_non_nullable
as String,programArea: null == programArea ? _self.programArea : programArea // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,publicationDate: null == publicationDate ? _self.publicationDate : publicationDate // ignore: cast_nullable_to_non_nullable
as String,reviewDate: null == reviewDate ? _self.reviewDate : reviewDate // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,lastUpdated: freezed == lastUpdated ? _self.lastUpdated : lastUpdated // ignore: cast_nullable_to_non_nullable
as DateTime?,intendedPopulation: null == intendedPopulation ? _self.intendedPopulation : intendedPopulation // ignore: cast_nullable_to_non_nullable
as String,healthcareLevel: null == healthcareLevel ? _self.healthcareLevel : healthcareLevel // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _GuidelinePublication implements GuidelinePublication {
  const _GuidelinePublication({required this.id, this.slug = '', this.title = '', this.description = '', this.country = '', @JsonKey(name: 'source_org') this.sourceOrganization = '', @JsonKey(name: 'program_area') this.programArea = '', this.language = '', @JsonKey(name: 'publication_date') this.publicationDate = '', @JsonKey(name: 'review_date') this.reviewDate = '', this.version = '', @JsonKey(name: 'last_updated') this.lastUpdated, @JsonKey(name: 'intended_population') this.intendedPopulation = '', @JsonKey(name: 'healthcare_level') this.healthcareLevel = ''});
  factory _GuidelinePublication.fromJson(Map<String, dynamic> json) => _$GuidelinePublicationFromJson(json);

@override final  String id;
@override@JsonKey() final  String slug;
@override@JsonKey() final  String title;
@override@JsonKey() final  String description;
@override@JsonKey() final  String country;
@override@JsonKey(name: 'source_org') final  String sourceOrganization;
@override@JsonKey(name: 'program_area') final  String programArea;
@override@JsonKey() final  String language;
@override@JsonKey(name: 'publication_date') final  String publicationDate;
@override@JsonKey(name: 'review_date') final  String reviewDate;
@override@JsonKey() final  String version;
@override@JsonKey(name: 'last_updated') final  DateTime? lastUpdated;
@override@JsonKey(name: 'intended_population') final  String intendedPopulation;
@override@JsonKey(name: 'healthcare_level') final  String healthcareLevel;

/// Create a copy of GuidelinePublication
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GuidelinePublicationCopyWith<_GuidelinePublication> get copyWith => __$GuidelinePublicationCopyWithImpl<_GuidelinePublication>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GuidelinePublicationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GuidelinePublication&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.country, country) || other.country == country)&&(identical(other.sourceOrganization, sourceOrganization) || other.sourceOrganization == sourceOrganization)&&(identical(other.programArea, programArea) || other.programArea == programArea)&&(identical(other.language, language) || other.language == language)&&(identical(other.publicationDate, publicationDate) || other.publicationDate == publicationDate)&&(identical(other.reviewDate, reviewDate) || other.reviewDate == reviewDate)&&(identical(other.version, version) || other.version == version)&&(identical(other.lastUpdated, lastUpdated) || other.lastUpdated == lastUpdated)&&(identical(other.intendedPopulation, intendedPopulation) || other.intendedPopulation == intendedPopulation)&&(identical(other.healthcareLevel, healthcareLevel) || other.healthcareLevel == healthcareLevel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,title,description,country,sourceOrganization,programArea,language,publicationDate,reviewDate,version,lastUpdated,intendedPopulation,healthcareLevel);

@override
String toString() {
  return 'GuidelinePublication(id: $id, slug: $slug, title: $title, description: $description, country: $country, sourceOrganization: $sourceOrganization, programArea: $programArea, language: $language, publicationDate: $publicationDate, reviewDate: $reviewDate, version: $version, lastUpdated: $lastUpdated, intendedPopulation: $intendedPopulation, healthcareLevel: $healthcareLevel)';
}


}

/// @nodoc
abstract mixin class _$GuidelinePublicationCopyWith<$Res> implements $GuidelinePublicationCopyWith<$Res> {
  factory _$GuidelinePublicationCopyWith(_GuidelinePublication value, $Res Function(_GuidelinePublication) _then) = __$GuidelinePublicationCopyWithImpl;
@override @useResult
$Res call({
 String id, String slug, String title, String description, String country,@JsonKey(name: 'source_org') String sourceOrganization,@JsonKey(name: 'program_area') String programArea, String language,@JsonKey(name: 'publication_date') String publicationDate,@JsonKey(name: 'review_date') String reviewDate, String version,@JsonKey(name: 'last_updated') DateTime? lastUpdated,@JsonKey(name: 'intended_population') String intendedPopulation,@JsonKey(name: 'healthcare_level') String healthcareLevel
});




}
/// @nodoc
class __$GuidelinePublicationCopyWithImpl<$Res>
    implements _$GuidelinePublicationCopyWith<$Res> {
  __$GuidelinePublicationCopyWithImpl(this._self, this._then);

  final _GuidelinePublication _self;
  final $Res Function(_GuidelinePublication) _then;

/// Create a copy of GuidelinePublication
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? slug = null,Object? title = null,Object? description = null,Object? country = null,Object? sourceOrganization = null,Object? programArea = null,Object? language = null,Object? publicationDate = null,Object? reviewDate = null,Object? version = null,Object? lastUpdated = freezed,Object? intendedPopulation = null,Object? healthcareLevel = null,}) {
  return _then(_GuidelinePublication(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,country: null == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String,sourceOrganization: null == sourceOrganization ? _self.sourceOrganization : sourceOrganization // ignore: cast_nullable_to_non_nullable
as String,programArea: null == programArea ? _self.programArea : programArea // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,publicationDate: null == publicationDate ? _self.publicationDate : publicationDate // ignore: cast_nullable_to_non_nullable
as String,reviewDate: null == reviewDate ? _self.reviewDate : reviewDate // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,lastUpdated: freezed == lastUpdated ? _self.lastUpdated : lastUpdated // ignore: cast_nullable_to_non_nullable
as DateTime?,intendedPopulation: null == intendedPopulation ? _self.intendedPopulation : intendedPopulation // ignore: cast_nullable_to_non_nullable
as String,healthcareLevel: null == healthcareLevel ? _self.healthcareLevel : healthcareLevel // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$GuidelineVersionSummary {

 String get id; String get version;@JsonKey(name: 'publication_date') String get publicationDate;@JsonKey(name: 'review_date') String get reviewDate;
/// Create a copy of GuidelineVersionSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GuidelineVersionSummaryCopyWith<GuidelineVersionSummary> get copyWith => _$GuidelineVersionSummaryCopyWithImpl<GuidelineVersionSummary>(this as GuidelineVersionSummary, _$identity);

  /// Serializes this GuidelineVersionSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GuidelineVersionSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.version, version) || other.version == version)&&(identical(other.publicationDate, publicationDate) || other.publicationDate == publicationDate)&&(identical(other.reviewDate, reviewDate) || other.reviewDate == reviewDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,version,publicationDate,reviewDate);

@override
String toString() {
  return 'GuidelineVersionSummary(id: $id, version: $version, publicationDate: $publicationDate, reviewDate: $reviewDate)';
}


}

/// @nodoc
abstract mixin class $GuidelineVersionSummaryCopyWith<$Res>  {
  factory $GuidelineVersionSummaryCopyWith(GuidelineVersionSummary value, $Res Function(GuidelineVersionSummary) _then) = _$GuidelineVersionSummaryCopyWithImpl;
@useResult
$Res call({
 String id, String version,@JsonKey(name: 'publication_date') String publicationDate,@JsonKey(name: 'review_date') String reviewDate
});




}
/// @nodoc
class _$GuidelineVersionSummaryCopyWithImpl<$Res>
    implements $GuidelineVersionSummaryCopyWith<$Res> {
  _$GuidelineVersionSummaryCopyWithImpl(this._self, this._then);

  final GuidelineVersionSummary _self;
  final $Res Function(GuidelineVersionSummary) _then;

/// Create a copy of GuidelineVersionSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? version = null,Object? publicationDate = null,Object? reviewDate = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,publicationDate: null == publicationDate ? _self.publicationDate : publicationDate // ignore: cast_nullable_to_non_nullable
as String,reviewDate: null == reviewDate ? _self.reviewDate : reviewDate // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _GuidelineVersionSummary implements GuidelineVersionSummary {
  const _GuidelineVersionSummary({required this.id, required this.version, @JsonKey(name: 'publication_date') this.publicationDate = '', @JsonKey(name: 'review_date') this.reviewDate = ''});
  factory _GuidelineVersionSummary.fromJson(Map<String, dynamic> json) => _$GuidelineVersionSummaryFromJson(json);

@override final  String id;
@override final  String version;
@override@JsonKey(name: 'publication_date') final  String publicationDate;
@override@JsonKey(name: 'review_date') final  String reviewDate;

/// Create a copy of GuidelineVersionSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GuidelineVersionSummaryCopyWith<_GuidelineVersionSummary> get copyWith => __$GuidelineVersionSummaryCopyWithImpl<_GuidelineVersionSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GuidelineVersionSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GuidelineVersionSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.version, version) || other.version == version)&&(identical(other.publicationDate, publicationDate) || other.publicationDate == publicationDate)&&(identical(other.reviewDate, reviewDate) || other.reviewDate == reviewDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,version,publicationDate,reviewDate);

@override
String toString() {
  return 'GuidelineVersionSummary(id: $id, version: $version, publicationDate: $publicationDate, reviewDate: $reviewDate)';
}


}

/// @nodoc
abstract mixin class _$GuidelineVersionSummaryCopyWith<$Res> implements $GuidelineVersionSummaryCopyWith<$Res> {
  factory _$GuidelineVersionSummaryCopyWith(_GuidelineVersionSummary value, $Res Function(_GuidelineVersionSummary) _then) = __$GuidelineVersionSummaryCopyWithImpl;
@override @useResult
$Res call({
 String id, String version,@JsonKey(name: 'publication_date') String publicationDate,@JsonKey(name: 'review_date') String reviewDate
});




}
/// @nodoc
class __$GuidelineVersionSummaryCopyWithImpl<$Res>
    implements _$GuidelineVersionSummaryCopyWith<$Res> {
  __$GuidelineVersionSummaryCopyWithImpl(this._self, this._then);

  final _GuidelineVersionSummary _self;
  final $Res Function(_GuidelineVersionSummary) _then;

/// Create a copy of GuidelineVersionSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? version = null,Object? publicationDate = null,Object? reviewDate = null,}) {
  return _then(_GuidelineVersionSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,publicationDate: null == publicationDate ? _self.publicationDate : publicationDate // ignore: cast_nullable_to_non_nullable
as String,reviewDate: null == reviewDate ? _self.reviewDate : reviewDate // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$GuidelineManifest {

@JsonKey(name: 'guideline_id') String get guidelineId;@JsonKey(name: 'version_id') String get versionId; String get version;@JsonKey(name: 'schema_version') int get schemaVersion;@JsonKey(name: 'package_version') int get packageVersion;@JsonKey(name: 'extraction_quality') String get extractionQuality;@JsonKey(name: 'recommended_mode') GuidelineReaderMode get recommendedMode;@JsonKey(name: 'has_chapters') bool get hasChapters;@JsonKey(name: 'has_key_points') bool get hasKeyPoints;@JsonKey(name: 'has_tables') bool get hasTables;@JsonKey(name: 'has_figures') bool get hasFigures;@JsonKey(name: 'has_algorithms') bool get hasAlgorithms;@JsonKey(name: 'has_original_pdf') bool get hasOriginalPdf;@JsonKey(name: 'has_offline_package') bool get hasOfflinePackage;@JsonKey(name: 'section_count') int get sectionCount;@JsonKey(name: 'block_count') int get blockCount;@JsonKey(name: 'table_count') int get tableCount;@JsonKey(name: 'figure_count') int get figureCount;@JsonKey(name: 'algorithm_count') int get algorithmCount; String get checksum; String get etag;@JsonKey(name: 'generated_at') DateTime? get generatedAt;
/// Create a copy of GuidelineManifest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GuidelineManifestCopyWith<GuidelineManifest> get copyWith => _$GuidelineManifestCopyWithImpl<GuidelineManifest>(this as GuidelineManifest, _$identity);

  /// Serializes this GuidelineManifest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GuidelineManifest&&(identical(other.guidelineId, guidelineId) || other.guidelineId == guidelineId)&&(identical(other.versionId, versionId) || other.versionId == versionId)&&(identical(other.version, version) || other.version == version)&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion)&&(identical(other.packageVersion, packageVersion) || other.packageVersion == packageVersion)&&(identical(other.extractionQuality, extractionQuality) || other.extractionQuality == extractionQuality)&&(identical(other.recommendedMode, recommendedMode) || other.recommendedMode == recommendedMode)&&(identical(other.hasChapters, hasChapters) || other.hasChapters == hasChapters)&&(identical(other.hasKeyPoints, hasKeyPoints) || other.hasKeyPoints == hasKeyPoints)&&(identical(other.hasTables, hasTables) || other.hasTables == hasTables)&&(identical(other.hasFigures, hasFigures) || other.hasFigures == hasFigures)&&(identical(other.hasAlgorithms, hasAlgorithms) || other.hasAlgorithms == hasAlgorithms)&&(identical(other.hasOriginalPdf, hasOriginalPdf) || other.hasOriginalPdf == hasOriginalPdf)&&(identical(other.hasOfflinePackage, hasOfflinePackage) || other.hasOfflinePackage == hasOfflinePackage)&&(identical(other.sectionCount, sectionCount) || other.sectionCount == sectionCount)&&(identical(other.blockCount, blockCount) || other.blockCount == blockCount)&&(identical(other.tableCount, tableCount) || other.tableCount == tableCount)&&(identical(other.figureCount, figureCount) || other.figureCount == figureCount)&&(identical(other.algorithmCount, algorithmCount) || other.algorithmCount == algorithmCount)&&(identical(other.checksum, checksum) || other.checksum == checksum)&&(identical(other.etag, etag) || other.etag == etag)&&(identical(other.generatedAt, generatedAt) || other.generatedAt == generatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,guidelineId,versionId,version,schemaVersion,packageVersion,extractionQuality,recommendedMode,hasChapters,hasKeyPoints,hasTables,hasFigures,hasAlgorithms,hasOriginalPdf,hasOfflinePackage,sectionCount,blockCount,tableCount,figureCount,algorithmCount,checksum,etag,generatedAt]);

@override
String toString() {
  return 'GuidelineManifest(guidelineId: $guidelineId, versionId: $versionId, version: $version, schemaVersion: $schemaVersion, packageVersion: $packageVersion, extractionQuality: $extractionQuality, recommendedMode: $recommendedMode, hasChapters: $hasChapters, hasKeyPoints: $hasKeyPoints, hasTables: $hasTables, hasFigures: $hasFigures, hasAlgorithms: $hasAlgorithms, hasOriginalPdf: $hasOriginalPdf, hasOfflinePackage: $hasOfflinePackage, sectionCount: $sectionCount, blockCount: $blockCount, tableCount: $tableCount, figureCount: $figureCount, algorithmCount: $algorithmCount, checksum: $checksum, etag: $etag, generatedAt: $generatedAt)';
}


}

/// @nodoc
abstract mixin class $GuidelineManifestCopyWith<$Res>  {
  factory $GuidelineManifestCopyWith(GuidelineManifest value, $Res Function(GuidelineManifest) _then) = _$GuidelineManifestCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'guideline_id') String guidelineId,@JsonKey(name: 'version_id') String versionId, String version,@JsonKey(name: 'schema_version') int schemaVersion,@JsonKey(name: 'package_version') int packageVersion,@JsonKey(name: 'extraction_quality') String extractionQuality,@JsonKey(name: 'recommended_mode') GuidelineReaderMode recommendedMode,@JsonKey(name: 'has_chapters') bool hasChapters,@JsonKey(name: 'has_key_points') bool hasKeyPoints,@JsonKey(name: 'has_tables') bool hasTables,@JsonKey(name: 'has_figures') bool hasFigures,@JsonKey(name: 'has_algorithms') bool hasAlgorithms,@JsonKey(name: 'has_original_pdf') bool hasOriginalPdf,@JsonKey(name: 'has_offline_package') bool hasOfflinePackage,@JsonKey(name: 'section_count') int sectionCount,@JsonKey(name: 'block_count') int blockCount,@JsonKey(name: 'table_count') int tableCount,@JsonKey(name: 'figure_count') int figureCount,@JsonKey(name: 'algorithm_count') int algorithmCount, String checksum, String etag,@JsonKey(name: 'generated_at') DateTime? generatedAt
});




}
/// @nodoc
class _$GuidelineManifestCopyWithImpl<$Res>
    implements $GuidelineManifestCopyWith<$Res> {
  _$GuidelineManifestCopyWithImpl(this._self, this._then);

  final GuidelineManifest _self;
  final $Res Function(GuidelineManifest) _then;

/// Create a copy of GuidelineManifest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? guidelineId = null,Object? versionId = null,Object? version = null,Object? schemaVersion = null,Object? packageVersion = null,Object? extractionQuality = null,Object? recommendedMode = null,Object? hasChapters = null,Object? hasKeyPoints = null,Object? hasTables = null,Object? hasFigures = null,Object? hasAlgorithms = null,Object? hasOriginalPdf = null,Object? hasOfflinePackage = null,Object? sectionCount = null,Object? blockCount = null,Object? tableCount = null,Object? figureCount = null,Object? algorithmCount = null,Object? checksum = null,Object? etag = null,Object? generatedAt = freezed,}) {
  return _then(_self.copyWith(
guidelineId: null == guidelineId ? _self.guidelineId : guidelineId // ignore: cast_nullable_to_non_nullable
as String,versionId: null == versionId ? _self.versionId : versionId // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,packageVersion: null == packageVersion ? _self.packageVersion : packageVersion // ignore: cast_nullable_to_non_nullable
as int,extractionQuality: null == extractionQuality ? _self.extractionQuality : extractionQuality // ignore: cast_nullable_to_non_nullable
as String,recommendedMode: null == recommendedMode ? _self.recommendedMode : recommendedMode // ignore: cast_nullable_to_non_nullable
as GuidelineReaderMode,hasChapters: null == hasChapters ? _self.hasChapters : hasChapters // ignore: cast_nullable_to_non_nullable
as bool,hasKeyPoints: null == hasKeyPoints ? _self.hasKeyPoints : hasKeyPoints // ignore: cast_nullable_to_non_nullable
as bool,hasTables: null == hasTables ? _self.hasTables : hasTables // ignore: cast_nullable_to_non_nullable
as bool,hasFigures: null == hasFigures ? _self.hasFigures : hasFigures // ignore: cast_nullable_to_non_nullable
as bool,hasAlgorithms: null == hasAlgorithms ? _self.hasAlgorithms : hasAlgorithms // ignore: cast_nullable_to_non_nullable
as bool,hasOriginalPdf: null == hasOriginalPdf ? _self.hasOriginalPdf : hasOriginalPdf // ignore: cast_nullable_to_non_nullable
as bool,hasOfflinePackage: null == hasOfflinePackage ? _self.hasOfflinePackage : hasOfflinePackage // ignore: cast_nullable_to_non_nullable
as bool,sectionCount: null == sectionCount ? _self.sectionCount : sectionCount // ignore: cast_nullable_to_non_nullable
as int,blockCount: null == blockCount ? _self.blockCount : blockCount // ignore: cast_nullable_to_non_nullable
as int,tableCount: null == tableCount ? _self.tableCount : tableCount // ignore: cast_nullable_to_non_nullable
as int,figureCount: null == figureCount ? _self.figureCount : figureCount // ignore: cast_nullable_to_non_nullable
as int,algorithmCount: null == algorithmCount ? _self.algorithmCount : algorithmCount // ignore: cast_nullable_to_non_nullable
as int,checksum: null == checksum ? _self.checksum : checksum // ignore: cast_nullable_to_non_nullable
as String,etag: null == etag ? _self.etag : etag // ignore: cast_nullable_to_non_nullable
as String,generatedAt: freezed == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _GuidelineManifest implements GuidelineManifest {
  const _GuidelineManifest({@JsonKey(name: 'guideline_id') required this.guidelineId, @JsonKey(name: 'version_id') required this.versionId, this.version = '', @JsonKey(name: 'schema_version') this.schemaVersion = 1, @JsonKey(name: 'package_version') this.packageVersion = 1, @JsonKey(name: 'extraction_quality') this.extractionQuality = 'unreviewed', @JsonKey(name: 'recommended_mode') this.recommendedMode = GuidelineReaderMode.originalDocument, @JsonKey(name: 'has_chapters') this.hasChapters = false, @JsonKey(name: 'has_key_points') this.hasKeyPoints = false, @JsonKey(name: 'has_tables') this.hasTables = false, @JsonKey(name: 'has_figures') this.hasFigures = false, @JsonKey(name: 'has_algorithms') this.hasAlgorithms = false, @JsonKey(name: 'has_original_pdf') this.hasOriginalPdf = false, @JsonKey(name: 'has_offline_package') this.hasOfflinePackage = false, @JsonKey(name: 'section_count') this.sectionCount = 0, @JsonKey(name: 'block_count') this.blockCount = 0, @JsonKey(name: 'table_count') this.tableCount = 0, @JsonKey(name: 'figure_count') this.figureCount = 0, @JsonKey(name: 'algorithm_count') this.algorithmCount = 0, this.checksum = '', this.etag = '', @JsonKey(name: 'generated_at') this.generatedAt});
  factory _GuidelineManifest.fromJson(Map<String, dynamic> json) => _$GuidelineManifestFromJson(json);

@override@JsonKey(name: 'guideline_id') final  String guidelineId;
@override@JsonKey(name: 'version_id') final  String versionId;
@override@JsonKey() final  String version;
@override@JsonKey(name: 'schema_version') final  int schemaVersion;
@override@JsonKey(name: 'package_version') final  int packageVersion;
@override@JsonKey(name: 'extraction_quality') final  String extractionQuality;
@override@JsonKey(name: 'recommended_mode') final  GuidelineReaderMode recommendedMode;
@override@JsonKey(name: 'has_chapters') final  bool hasChapters;
@override@JsonKey(name: 'has_key_points') final  bool hasKeyPoints;
@override@JsonKey(name: 'has_tables') final  bool hasTables;
@override@JsonKey(name: 'has_figures') final  bool hasFigures;
@override@JsonKey(name: 'has_algorithms') final  bool hasAlgorithms;
@override@JsonKey(name: 'has_original_pdf') final  bool hasOriginalPdf;
@override@JsonKey(name: 'has_offline_package') final  bool hasOfflinePackage;
@override@JsonKey(name: 'section_count') final  int sectionCount;
@override@JsonKey(name: 'block_count') final  int blockCount;
@override@JsonKey(name: 'table_count') final  int tableCount;
@override@JsonKey(name: 'figure_count') final  int figureCount;
@override@JsonKey(name: 'algorithm_count') final  int algorithmCount;
@override@JsonKey() final  String checksum;
@override@JsonKey() final  String etag;
@override@JsonKey(name: 'generated_at') final  DateTime? generatedAt;

/// Create a copy of GuidelineManifest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GuidelineManifestCopyWith<_GuidelineManifest> get copyWith => __$GuidelineManifestCopyWithImpl<_GuidelineManifest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GuidelineManifestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GuidelineManifest&&(identical(other.guidelineId, guidelineId) || other.guidelineId == guidelineId)&&(identical(other.versionId, versionId) || other.versionId == versionId)&&(identical(other.version, version) || other.version == version)&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion)&&(identical(other.packageVersion, packageVersion) || other.packageVersion == packageVersion)&&(identical(other.extractionQuality, extractionQuality) || other.extractionQuality == extractionQuality)&&(identical(other.recommendedMode, recommendedMode) || other.recommendedMode == recommendedMode)&&(identical(other.hasChapters, hasChapters) || other.hasChapters == hasChapters)&&(identical(other.hasKeyPoints, hasKeyPoints) || other.hasKeyPoints == hasKeyPoints)&&(identical(other.hasTables, hasTables) || other.hasTables == hasTables)&&(identical(other.hasFigures, hasFigures) || other.hasFigures == hasFigures)&&(identical(other.hasAlgorithms, hasAlgorithms) || other.hasAlgorithms == hasAlgorithms)&&(identical(other.hasOriginalPdf, hasOriginalPdf) || other.hasOriginalPdf == hasOriginalPdf)&&(identical(other.hasOfflinePackage, hasOfflinePackage) || other.hasOfflinePackage == hasOfflinePackage)&&(identical(other.sectionCount, sectionCount) || other.sectionCount == sectionCount)&&(identical(other.blockCount, blockCount) || other.blockCount == blockCount)&&(identical(other.tableCount, tableCount) || other.tableCount == tableCount)&&(identical(other.figureCount, figureCount) || other.figureCount == figureCount)&&(identical(other.algorithmCount, algorithmCount) || other.algorithmCount == algorithmCount)&&(identical(other.checksum, checksum) || other.checksum == checksum)&&(identical(other.etag, etag) || other.etag == etag)&&(identical(other.generatedAt, generatedAt) || other.generatedAt == generatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,guidelineId,versionId,version,schemaVersion,packageVersion,extractionQuality,recommendedMode,hasChapters,hasKeyPoints,hasTables,hasFigures,hasAlgorithms,hasOriginalPdf,hasOfflinePackage,sectionCount,blockCount,tableCount,figureCount,algorithmCount,checksum,etag,generatedAt]);

@override
String toString() {
  return 'GuidelineManifest(guidelineId: $guidelineId, versionId: $versionId, version: $version, schemaVersion: $schemaVersion, packageVersion: $packageVersion, extractionQuality: $extractionQuality, recommendedMode: $recommendedMode, hasChapters: $hasChapters, hasKeyPoints: $hasKeyPoints, hasTables: $hasTables, hasFigures: $hasFigures, hasAlgorithms: $hasAlgorithms, hasOriginalPdf: $hasOriginalPdf, hasOfflinePackage: $hasOfflinePackage, sectionCount: $sectionCount, blockCount: $blockCount, tableCount: $tableCount, figureCount: $figureCount, algorithmCount: $algorithmCount, checksum: $checksum, etag: $etag, generatedAt: $generatedAt)';
}


}

/// @nodoc
abstract mixin class _$GuidelineManifestCopyWith<$Res> implements $GuidelineManifestCopyWith<$Res> {
  factory _$GuidelineManifestCopyWith(_GuidelineManifest value, $Res Function(_GuidelineManifest) _then) = __$GuidelineManifestCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'guideline_id') String guidelineId,@JsonKey(name: 'version_id') String versionId, String version,@JsonKey(name: 'schema_version') int schemaVersion,@JsonKey(name: 'package_version') int packageVersion,@JsonKey(name: 'extraction_quality') String extractionQuality,@JsonKey(name: 'recommended_mode') GuidelineReaderMode recommendedMode,@JsonKey(name: 'has_chapters') bool hasChapters,@JsonKey(name: 'has_key_points') bool hasKeyPoints,@JsonKey(name: 'has_tables') bool hasTables,@JsonKey(name: 'has_figures') bool hasFigures,@JsonKey(name: 'has_algorithms') bool hasAlgorithms,@JsonKey(name: 'has_original_pdf') bool hasOriginalPdf,@JsonKey(name: 'has_offline_package') bool hasOfflinePackage,@JsonKey(name: 'section_count') int sectionCount,@JsonKey(name: 'block_count') int blockCount,@JsonKey(name: 'table_count') int tableCount,@JsonKey(name: 'figure_count') int figureCount,@JsonKey(name: 'algorithm_count') int algorithmCount, String checksum, String etag,@JsonKey(name: 'generated_at') DateTime? generatedAt
});




}
/// @nodoc
class __$GuidelineManifestCopyWithImpl<$Res>
    implements _$GuidelineManifestCopyWith<$Res> {
  __$GuidelineManifestCopyWithImpl(this._self, this._then);

  final _GuidelineManifest _self;
  final $Res Function(_GuidelineManifest) _then;

/// Create a copy of GuidelineManifest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? guidelineId = null,Object? versionId = null,Object? version = null,Object? schemaVersion = null,Object? packageVersion = null,Object? extractionQuality = null,Object? recommendedMode = null,Object? hasChapters = null,Object? hasKeyPoints = null,Object? hasTables = null,Object? hasFigures = null,Object? hasAlgorithms = null,Object? hasOriginalPdf = null,Object? hasOfflinePackage = null,Object? sectionCount = null,Object? blockCount = null,Object? tableCount = null,Object? figureCount = null,Object? algorithmCount = null,Object? checksum = null,Object? etag = null,Object? generatedAt = freezed,}) {
  return _then(_GuidelineManifest(
guidelineId: null == guidelineId ? _self.guidelineId : guidelineId // ignore: cast_nullable_to_non_nullable
as String,versionId: null == versionId ? _self.versionId : versionId // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,packageVersion: null == packageVersion ? _self.packageVersion : packageVersion // ignore: cast_nullable_to_non_nullable
as int,extractionQuality: null == extractionQuality ? _self.extractionQuality : extractionQuality // ignore: cast_nullable_to_non_nullable
as String,recommendedMode: null == recommendedMode ? _self.recommendedMode : recommendedMode // ignore: cast_nullable_to_non_nullable
as GuidelineReaderMode,hasChapters: null == hasChapters ? _self.hasChapters : hasChapters // ignore: cast_nullable_to_non_nullable
as bool,hasKeyPoints: null == hasKeyPoints ? _self.hasKeyPoints : hasKeyPoints // ignore: cast_nullable_to_non_nullable
as bool,hasTables: null == hasTables ? _self.hasTables : hasTables // ignore: cast_nullable_to_non_nullable
as bool,hasFigures: null == hasFigures ? _self.hasFigures : hasFigures // ignore: cast_nullable_to_non_nullable
as bool,hasAlgorithms: null == hasAlgorithms ? _self.hasAlgorithms : hasAlgorithms // ignore: cast_nullable_to_non_nullable
as bool,hasOriginalPdf: null == hasOriginalPdf ? _self.hasOriginalPdf : hasOriginalPdf // ignore: cast_nullable_to_non_nullable
as bool,hasOfflinePackage: null == hasOfflinePackage ? _self.hasOfflinePackage : hasOfflinePackage // ignore: cast_nullable_to_non_nullable
as bool,sectionCount: null == sectionCount ? _self.sectionCount : sectionCount // ignore: cast_nullable_to_non_nullable
as int,blockCount: null == blockCount ? _self.blockCount : blockCount // ignore: cast_nullable_to_non_nullable
as int,tableCount: null == tableCount ? _self.tableCount : tableCount // ignore: cast_nullable_to_non_nullable
as int,figureCount: null == figureCount ? _self.figureCount : figureCount // ignore: cast_nullable_to_non_nullable
as int,algorithmCount: null == algorithmCount ? _self.algorithmCount : algorithmCount // ignore: cast_nullable_to_non_nullable
as int,checksum: null == checksum ? _self.checksum : checksum // ignore: cast_nullable_to_non_nullable
as String,etag: null == etag ? _self.etag : etag // ignore: cast_nullable_to_non_nullable
as String,generatedAt: freezed == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$PublicationSection {

 String get id;@JsonKey(name: 'parent_id') String? get parentId; String get title; String get slug; int get level;@JsonKey(name: 'page_start') int? get pageStart;@JsonKey(name: 'page_end') int? get pageEnd;@JsonKey(name: 'sort_order') int get sortOrder;
/// Create a copy of PublicationSection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PublicationSectionCopyWith<PublicationSection> get copyWith => _$PublicationSectionCopyWithImpl<PublicationSection>(this as PublicationSection, _$identity);

  /// Serializes this PublicationSection to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PublicationSection&&(identical(other.id, id) || other.id == id)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.title, title) || other.title == title)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.level, level) || other.level == level)&&(identical(other.pageStart, pageStart) || other.pageStart == pageStart)&&(identical(other.pageEnd, pageEnd) || other.pageEnd == pageEnd)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,parentId,title,slug,level,pageStart,pageEnd,sortOrder);

@override
String toString() {
  return 'PublicationSection(id: $id, parentId: $parentId, title: $title, slug: $slug, level: $level, pageStart: $pageStart, pageEnd: $pageEnd, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class $PublicationSectionCopyWith<$Res>  {
  factory $PublicationSectionCopyWith(PublicationSection value, $Res Function(PublicationSection) _then) = _$PublicationSectionCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'parent_id') String? parentId, String title, String slug, int level,@JsonKey(name: 'page_start') int? pageStart,@JsonKey(name: 'page_end') int? pageEnd,@JsonKey(name: 'sort_order') int sortOrder
});




}
/// @nodoc
class _$PublicationSectionCopyWithImpl<$Res>
    implements $PublicationSectionCopyWith<$Res> {
  _$PublicationSectionCopyWithImpl(this._self, this._then);

  final PublicationSection _self;
  final $Res Function(PublicationSection) _then;

/// Create a copy of PublicationSection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? parentId = freezed,Object? title = null,Object? slug = null,Object? level = null,Object? pageStart = freezed,Object? pageEnd = freezed,Object? sortOrder = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,pageStart: freezed == pageStart ? _self.pageStart : pageStart // ignore: cast_nullable_to_non_nullable
as int?,pageEnd: freezed == pageEnd ? _self.pageEnd : pageEnd // ignore: cast_nullable_to_non_nullable
as int?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _PublicationSection extends PublicationSection {
  const _PublicationSection({required this.id, @JsonKey(name: 'parent_id') this.parentId, this.title = '', this.slug = '', this.level = 1, @JsonKey(name: 'page_start') this.pageStart, @JsonKey(name: 'page_end') this.pageEnd, @JsonKey(name: 'sort_order') this.sortOrder = 0}): super._();
  factory _PublicationSection.fromJson(Map<String, dynamic> json) => _$PublicationSectionFromJson(json);

@override final  String id;
@override@JsonKey(name: 'parent_id') final  String? parentId;
@override@JsonKey() final  String title;
@override@JsonKey() final  String slug;
@override@JsonKey() final  int level;
@override@JsonKey(name: 'page_start') final  int? pageStart;
@override@JsonKey(name: 'page_end') final  int? pageEnd;
@override@JsonKey(name: 'sort_order') final  int sortOrder;

/// Create a copy of PublicationSection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PublicationSectionCopyWith<_PublicationSection> get copyWith => __$PublicationSectionCopyWithImpl<_PublicationSection>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PublicationSectionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PublicationSection&&(identical(other.id, id) || other.id == id)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.title, title) || other.title == title)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.level, level) || other.level == level)&&(identical(other.pageStart, pageStart) || other.pageStart == pageStart)&&(identical(other.pageEnd, pageEnd) || other.pageEnd == pageEnd)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,parentId,title,slug,level,pageStart,pageEnd,sortOrder);

@override
String toString() {
  return 'PublicationSection(id: $id, parentId: $parentId, title: $title, slug: $slug, level: $level, pageStart: $pageStart, pageEnd: $pageEnd, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class _$PublicationSectionCopyWith<$Res> implements $PublicationSectionCopyWith<$Res> {
  factory _$PublicationSectionCopyWith(_PublicationSection value, $Res Function(_PublicationSection) _then) = __$PublicationSectionCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'parent_id') String? parentId, String title, String slug, int level,@JsonKey(name: 'page_start') int? pageStart,@JsonKey(name: 'page_end') int? pageEnd,@JsonKey(name: 'sort_order') int sortOrder
});




}
/// @nodoc
class __$PublicationSectionCopyWithImpl<$Res>
    implements _$PublicationSectionCopyWith<$Res> {
  __$PublicationSectionCopyWithImpl(this._self, this._then);

  final _PublicationSection _self;
  final $Res Function(_PublicationSection) _then;

/// Create a copy of PublicationSection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? parentId = freezed,Object? title = null,Object? slug = null,Object? level = null,Object? pageStart = freezed,Object? pageEnd = freezed,Object? sortOrder = null,}) {
  return _then(_PublicationSection(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,pageStart: freezed == pageStart ? _self.pageStart : pageStart // ignore: cast_nullable_to_non_nullable
as int?,pageEnd: freezed == pageEnd ? _self.pageEnd : pageEnd // ignore: cast_nullable_to_non_nullable
as int?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$GuidelineTablePayload {

 String get title; List<String> get columns; List<List<String>> get rows; List<String> get footnotes;
/// Create a copy of GuidelineTablePayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GuidelineTablePayloadCopyWith<GuidelineTablePayload> get copyWith => _$GuidelineTablePayloadCopyWithImpl<GuidelineTablePayload>(this as GuidelineTablePayload, _$identity);

  /// Serializes this GuidelineTablePayload to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GuidelineTablePayload&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other.columns, columns)&&const DeepCollectionEquality().equals(other.rows, rows)&&const DeepCollectionEquality().equals(other.footnotes, footnotes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,const DeepCollectionEquality().hash(columns),const DeepCollectionEquality().hash(rows),const DeepCollectionEquality().hash(footnotes));

@override
String toString() {
  return 'GuidelineTablePayload(title: $title, columns: $columns, rows: $rows, footnotes: $footnotes)';
}


}

/// @nodoc
abstract mixin class $GuidelineTablePayloadCopyWith<$Res>  {
  factory $GuidelineTablePayloadCopyWith(GuidelineTablePayload value, $Res Function(GuidelineTablePayload) _then) = _$GuidelineTablePayloadCopyWithImpl;
@useResult
$Res call({
 String title, List<String> columns, List<List<String>> rows, List<String> footnotes
});




}
/// @nodoc
class _$GuidelineTablePayloadCopyWithImpl<$Res>
    implements $GuidelineTablePayloadCopyWith<$Res> {
  _$GuidelineTablePayloadCopyWithImpl(this._self, this._then);

  final GuidelineTablePayload _self;
  final $Res Function(GuidelineTablePayload) _then;

/// Create a copy of GuidelineTablePayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? columns = null,Object? rows = null,Object? footnotes = null,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,columns: null == columns ? _self.columns : columns // ignore: cast_nullable_to_non_nullable
as List<String>,rows: null == rows ? _self.rows : rows // ignore: cast_nullable_to_non_nullable
as List<List<String>>,footnotes: null == footnotes ? _self.footnotes : footnotes // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _GuidelineTablePayload implements GuidelineTablePayload {
  const _GuidelineTablePayload({this.title = '', final  List<String> columns = const <String>[], final  List<List<String>> rows = const <List<String>>[], final  List<String> footnotes = const <String>[]}): _columns = columns,_rows = rows,_footnotes = footnotes;
  factory _GuidelineTablePayload.fromJson(Map<String, dynamic> json) => _$GuidelineTablePayloadFromJson(json);

@override@JsonKey() final  String title;
 final  List<String> _columns;
@override@JsonKey() List<String> get columns {
  if (_columns is EqualUnmodifiableListView) return _columns;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_columns);
}

 final  List<List<String>> _rows;
@override@JsonKey() List<List<String>> get rows {
  if (_rows is EqualUnmodifiableListView) return _rows;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rows);
}

 final  List<String> _footnotes;
@override@JsonKey() List<String> get footnotes {
  if (_footnotes is EqualUnmodifiableListView) return _footnotes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_footnotes);
}


/// Create a copy of GuidelineTablePayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GuidelineTablePayloadCopyWith<_GuidelineTablePayload> get copyWith => __$GuidelineTablePayloadCopyWithImpl<_GuidelineTablePayload>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GuidelineTablePayloadToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GuidelineTablePayload&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other._columns, _columns)&&const DeepCollectionEquality().equals(other._rows, _rows)&&const DeepCollectionEquality().equals(other._footnotes, _footnotes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,const DeepCollectionEquality().hash(_columns),const DeepCollectionEquality().hash(_rows),const DeepCollectionEquality().hash(_footnotes));

@override
String toString() {
  return 'GuidelineTablePayload(title: $title, columns: $columns, rows: $rows, footnotes: $footnotes)';
}


}

/// @nodoc
abstract mixin class _$GuidelineTablePayloadCopyWith<$Res> implements $GuidelineTablePayloadCopyWith<$Res> {
  factory _$GuidelineTablePayloadCopyWith(_GuidelineTablePayload value, $Res Function(_GuidelineTablePayload) _then) = __$GuidelineTablePayloadCopyWithImpl;
@override @useResult
$Res call({
 String title, List<String> columns, List<List<String>> rows, List<String> footnotes
});




}
/// @nodoc
class __$GuidelineTablePayloadCopyWithImpl<$Res>
    implements _$GuidelineTablePayloadCopyWith<$Res> {
  __$GuidelineTablePayloadCopyWithImpl(this._self, this._then);

  final _GuidelineTablePayload _self;
  final $Res Function(_GuidelineTablePayload) _then;

/// Create a copy of GuidelineTablePayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? columns = null,Object? rows = null,Object? footnotes = null,}) {
  return _then(_GuidelineTablePayload(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,columns: null == columns ? _self._columns : columns // ignore: cast_nullable_to_non_nullable
as List<String>,rows: null == rows ? _self._rows : rows // ignore: cast_nullable_to_non_nullable
as List<List<String>>,footnotes: null == footnotes ? _self._footnotes : footnotes // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$GuidelineFigurePayload {

@JsonKey(name: 'asset_id') String get assetId; String get caption;@JsonKey(name: 'alternative_text') String get alternativeText;
/// Create a copy of GuidelineFigurePayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GuidelineFigurePayloadCopyWith<GuidelineFigurePayload> get copyWith => _$GuidelineFigurePayloadCopyWithImpl<GuidelineFigurePayload>(this as GuidelineFigurePayload, _$identity);

  /// Serializes this GuidelineFigurePayload to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GuidelineFigurePayload&&(identical(other.assetId, assetId) || other.assetId == assetId)&&(identical(other.caption, caption) || other.caption == caption)&&(identical(other.alternativeText, alternativeText) || other.alternativeText == alternativeText));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,assetId,caption,alternativeText);

@override
String toString() {
  return 'GuidelineFigurePayload(assetId: $assetId, caption: $caption, alternativeText: $alternativeText)';
}


}

/// @nodoc
abstract mixin class $GuidelineFigurePayloadCopyWith<$Res>  {
  factory $GuidelineFigurePayloadCopyWith(GuidelineFigurePayload value, $Res Function(GuidelineFigurePayload) _then) = _$GuidelineFigurePayloadCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'asset_id') String assetId, String caption,@JsonKey(name: 'alternative_text') String alternativeText
});




}
/// @nodoc
class _$GuidelineFigurePayloadCopyWithImpl<$Res>
    implements $GuidelineFigurePayloadCopyWith<$Res> {
  _$GuidelineFigurePayloadCopyWithImpl(this._self, this._then);

  final GuidelineFigurePayload _self;
  final $Res Function(GuidelineFigurePayload) _then;

/// Create a copy of GuidelineFigurePayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? assetId = null,Object? caption = null,Object? alternativeText = null,}) {
  return _then(_self.copyWith(
assetId: null == assetId ? _self.assetId : assetId // ignore: cast_nullable_to_non_nullable
as String,caption: null == caption ? _self.caption : caption // ignore: cast_nullable_to_non_nullable
as String,alternativeText: null == alternativeText ? _self.alternativeText : alternativeText // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _GuidelineFigurePayload implements GuidelineFigurePayload {
  const _GuidelineFigurePayload({@JsonKey(name: 'asset_id') required this.assetId, this.caption = '', @JsonKey(name: 'alternative_text') this.alternativeText = 'Clinical figure'});
  factory _GuidelineFigurePayload.fromJson(Map<String, dynamic> json) => _$GuidelineFigurePayloadFromJson(json);

@override@JsonKey(name: 'asset_id') final  String assetId;
@override@JsonKey() final  String caption;
@override@JsonKey(name: 'alternative_text') final  String alternativeText;

/// Create a copy of GuidelineFigurePayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GuidelineFigurePayloadCopyWith<_GuidelineFigurePayload> get copyWith => __$GuidelineFigurePayloadCopyWithImpl<_GuidelineFigurePayload>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GuidelineFigurePayloadToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GuidelineFigurePayload&&(identical(other.assetId, assetId) || other.assetId == assetId)&&(identical(other.caption, caption) || other.caption == caption)&&(identical(other.alternativeText, alternativeText) || other.alternativeText == alternativeText));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,assetId,caption,alternativeText);

@override
String toString() {
  return 'GuidelineFigurePayload(assetId: $assetId, caption: $caption, alternativeText: $alternativeText)';
}


}

/// @nodoc
abstract mixin class _$GuidelineFigurePayloadCopyWith<$Res> implements $GuidelineFigurePayloadCopyWith<$Res> {
  factory _$GuidelineFigurePayloadCopyWith(_GuidelineFigurePayload value, $Res Function(_GuidelineFigurePayload) _then) = __$GuidelineFigurePayloadCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'asset_id') String assetId, String caption,@JsonKey(name: 'alternative_text') String alternativeText
});




}
/// @nodoc
class __$GuidelineFigurePayloadCopyWithImpl<$Res>
    implements _$GuidelineFigurePayloadCopyWith<$Res> {
  __$GuidelineFigurePayloadCopyWithImpl(this._self, this._then);

  final _GuidelineFigurePayload _self;
  final $Res Function(_GuidelineFigurePayload) _then;

/// Create a copy of GuidelineFigurePayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? assetId = null,Object? caption = null,Object? alternativeText = null,}) {
  return _then(_GuidelineFigurePayload(
assetId: null == assetId ? _self.assetId : assetId // ignore: cast_nullable_to_non_nullable
as String,caption: null == caption ? _self.caption : caption // ignore: cast_nullable_to_non_nullable
as String,alternativeText: null == alternativeText ? _self.alternativeText : alternativeText // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$GuidelineCalloutPayload {

 String get title; String get content; String get severity;@JsonKey(name: 'evidence_grade') String get evidenceGrade; String get source;
/// Create a copy of GuidelineCalloutPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GuidelineCalloutPayloadCopyWith<GuidelineCalloutPayload> get copyWith => _$GuidelineCalloutPayloadCopyWithImpl<GuidelineCalloutPayload>(this as GuidelineCalloutPayload, _$identity);

  /// Serializes this GuidelineCalloutPayload to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GuidelineCalloutPayload&&(identical(other.title, title) || other.title == title)&&(identical(other.content, content) || other.content == content)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.evidenceGrade, evidenceGrade) || other.evidenceGrade == evidenceGrade)&&(identical(other.source, source) || other.source == source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,content,severity,evidenceGrade,source);

@override
String toString() {
  return 'GuidelineCalloutPayload(title: $title, content: $content, severity: $severity, evidenceGrade: $evidenceGrade, source: $source)';
}


}

/// @nodoc
abstract mixin class $GuidelineCalloutPayloadCopyWith<$Res>  {
  factory $GuidelineCalloutPayloadCopyWith(GuidelineCalloutPayload value, $Res Function(GuidelineCalloutPayload) _then) = _$GuidelineCalloutPayloadCopyWithImpl;
@useResult
$Res call({
 String title, String content, String severity,@JsonKey(name: 'evidence_grade') String evidenceGrade, String source
});




}
/// @nodoc
class _$GuidelineCalloutPayloadCopyWithImpl<$Res>
    implements $GuidelineCalloutPayloadCopyWith<$Res> {
  _$GuidelineCalloutPayloadCopyWithImpl(this._self, this._then);

  final GuidelineCalloutPayload _self;
  final $Res Function(GuidelineCalloutPayload) _then;

/// Create a copy of GuidelineCalloutPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? content = null,Object? severity = null,Object? evidenceGrade = null,Object? source = null,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as String,evidenceGrade: null == evidenceGrade ? _self.evidenceGrade : evidenceGrade // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _GuidelineCalloutPayload implements GuidelineCalloutPayload {
  const _GuidelineCalloutPayload({this.title = '', this.content = '', this.severity = 'standard', @JsonKey(name: 'evidence_grade') this.evidenceGrade = '', this.source = ''});
  factory _GuidelineCalloutPayload.fromJson(Map<String, dynamic> json) => _$GuidelineCalloutPayloadFromJson(json);

@override@JsonKey() final  String title;
@override@JsonKey() final  String content;
@override@JsonKey() final  String severity;
@override@JsonKey(name: 'evidence_grade') final  String evidenceGrade;
@override@JsonKey() final  String source;

/// Create a copy of GuidelineCalloutPayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GuidelineCalloutPayloadCopyWith<_GuidelineCalloutPayload> get copyWith => __$GuidelineCalloutPayloadCopyWithImpl<_GuidelineCalloutPayload>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GuidelineCalloutPayloadToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GuidelineCalloutPayload&&(identical(other.title, title) || other.title == title)&&(identical(other.content, content) || other.content == content)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.evidenceGrade, evidenceGrade) || other.evidenceGrade == evidenceGrade)&&(identical(other.source, source) || other.source == source));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,content,severity,evidenceGrade,source);

@override
String toString() {
  return 'GuidelineCalloutPayload(title: $title, content: $content, severity: $severity, evidenceGrade: $evidenceGrade, source: $source)';
}


}

/// @nodoc
abstract mixin class _$GuidelineCalloutPayloadCopyWith<$Res> implements $GuidelineCalloutPayloadCopyWith<$Res> {
  factory _$GuidelineCalloutPayloadCopyWith(_GuidelineCalloutPayload value, $Res Function(_GuidelineCalloutPayload) _then) = __$GuidelineCalloutPayloadCopyWithImpl;
@override @useResult
$Res call({
 String title, String content, String severity,@JsonKey(name: 'evidence_grade') String evidenceGrade, String source
});




}
/// @nodoc
class __$GuidelineCalloutPayloadCopyWithImpl<$Res>
    implements _$GuidelineCalloutPayloadCopyWith<$Res> {
  __$GuidelineCalloutPayloadCopyWithImpl(this._self, this._then);

  final _GuidelineCalloutPayload _self;
  final $Res Function(_GuidelineCalloutPayload) _then;

/// Create a copy of GuidelineCalloutPayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? content = null,Object? severity = null,Object? evidenceGrade = null,Object? source = null,}) {
  return _then(_GuidelineCalloutPayload(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as String,evidenceGrade: null == evidenceGrade ? _self.evidenceGrade : evidenceGrade // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$GuidelineAlgorithmNode {

 String get id; String get label; String get kind; List<String> get next;
/// Create a copy of GuidelineAlgorithmNode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GuidelineAlgorithmNodeCopyWith<GuidelineAlgorithmNode> get copyWith => _$GuidelineAlgorithmNodeCopyWithImpl<GuidelineAlgorithmNode>(this as GuidelineAlgorithmNode, _$identity);

  /// Serializes this GuidelineAlgorithmNode to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GuidelineAlgorithmNode&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.kind, kind) || other.kind == kind)&&const DeepCollectionEquality().equals(other.next, next));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,kind,const DeepCollectionEquality().hash(next));

@override
String toString() {
  return 'GuidelineAlgorithmNode(id: $id, label: $label, kind: $kind, next: $next)';
}


}

/// @nodoc
abstract mixin class $GuidelineAlgorithmNodeCopyWith<$Res>  {
  factory $GuidelineAlgorithmNodeCopyWith(GuidelineAlgorithmNode value, $Res Function(GuidelineAlgorithmNode) _then) = _$GuidelineAlgorithmNodeCopyWithImpl;
@useResult
$Res call({
 String id, String label, String kind, List<String> next
});




}
/// @nodoc
class _$GuidelineAlgorithmNodeCopyWithImpl<$Res>
    implements $GuidelineAlgorithmNodeCopyWith<$Res> {
  _$GuidelineAlgorithmNodeCopyWithImpl(this._self, this._then);

  final GuidelineAlgorithmNode _self;
  final $Res Function(GuidelineAlgorithmNode) _then;

/// Create a copy of GuidelineAlgorithmNode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? kind = null,Object? next = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,next: null == next ? _self.next : next // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _GuidelineAlgorithmNode implements GuidelineAlgorithmNode {
  const _GuidelineAlgorithmNode({required this.id, this.label = '', this.kind = '', final  List<String> next = const <String>[]}): _next = next;
  factory _GuidelineAlgorithmNode.fromJson(Map<String, dynamic> json) => _$GuidelineAlgorithmNodeFromJson(json);

@override final  String id;
@override@JsonKey() final  String label;
@override@JsonKey() final  String kind;
 final  List<String> _next;
@override@JsonKey() List<String> get next {
  if (_next is EqualUnmodifiableListView) return _next;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_next);
}


/// Create a copy of GuidelineAlgorithmNode
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GuidelineAlgorithmNodeCopyWith<_GuidelineAlgorithmNode> get copyWith => __$GuidelineAlgorithmNodeCopyWithImpl<_GuidelineAlgorithmNode>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GuidelineAlgorithmNodeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GuidelineAlgorithmNode&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.kind, kind) || other.kind == kind)&&const DeepCollectionEquality().equals(other._next, _next));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,kind,const DeepCollectionEquality().hash(_next));

@override
String toString() {
  return 'GuidelineAlgorithmNode(id: $id, label: $label, kind: $kind, next: $next)';
}


}

/// @nodoc
abstract mixin class _$GuidelineAlgorithmNodeCopyWith<$Res> implements $GuidelineAlgorithmNodeCopyWith<$Res> {
  factory _$GuidelineAlgorithmNodeCopyWith(_GuidelineAlgorithmNode value, $Res Function(_GuidelineAlgorithmNode) _then) = __$GuidelineAlgorithmNodeCopyWithImpl;
@override @useResult
$Res call({
 String id, String label, String kind, List<String> next
});




}
/// @nodoc
class __$GuidelineAlgorithmNodeCopyWithImpl<$Res>
    implements _$GuidelineAlgorithmNodeCopyWith<$Res> {
  __$GuidelineAlgorithmNodeCopyWithImpl(this._self, this._then);

  final _GuidelineAlgorithmNode _self;
  final $Res Function(_GuidelineAlgorithmNode) _then;

/// Create a copy of GuidelineAlgorithmNode
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? kind = null,Object? next = null,}) {
  return _then(_GuidelineAlgorithmNode(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,next: null == next ? _self._next : next // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$GuidelineAlgorithmPayload {

 String get title; List<GuidelineAlgorithmNode> get nodes;
/// Create a copy of GuidelineAlgorithmPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GuidelineAlgorithmPayloadCopyWith<GuidelineAlgorithmPayload> get copyWith => _$GuidelineAlgorithmPayloadCopyWithImpl<GuidelineAlgorithmPayload>(this as GuidelineAlgorithmPayload, _$identity);

  /// Serializes this GuidelineAlgorithmPayload to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GuidelineAlgorithmPayload&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other.nodes, nodes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,const DeepCollectionEquality().hash(nodes));

@override
String toString() {
  return 'GuidelineAlgorithmPayload(title: $title, nodes: $nodes)';
}


}

/// @nodoc
abstract mixin class $GuidelineAlgorithmPayloadCopyWith<$Res>  {
  factory $GuidelineAlgorithmPayloadCopyWith(GuidelineAlgorithmPayload value, $Res Function(GuidelineAlgorithmPayload) _then) = _$GuidelineAlgorithmPayloadCopyWithImpl;
@useResult
$Res call({
 String title, List<GuidelineAlgorithmNode> nodes
});




}
/// @nodoc
class _$GuidelineAlgorithmPayloadCopyWithImpl<$Res>
    implements $GuidelineAlgorithmPayloadCopyWith<$Res> {
  _$GuidelineAlgorithmPayloadCopyWithImpl(this._self, this._then);

  final GuidelineAlgorithmPayload _self;
  final $Res Function(GuidelineAlgorithmPayload) _then;

/// Create a copy of GuidelineAlgorithmPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? nodes = null,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,nodes: null == nodes ? _self.nodes : nodes // ignore: cast_nullable_to_non_nullable
as List<GuidelineAlgorithmNode>,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _GuidelineAlgorithmPayload implements GuidelineAlgorithmPayload {
  const _GuidelineAlgorithmPayload({this.title = '', final  List<GuidelineAlgorithmNode> nodes = const <GuidelineAlgorithmNode>[]}): _nodes = nodes;
  factory _GuidelineAlgorithmPayload.fromJson(Map<String, dynamic> json) => _$GuidelineAlgorithmPayloadFromJson(json);

@override@JsonKey() final  String title;
 final  List<GuidelineAlgorithmNode> _nodes;
@override@JsonKey() List<GuidelineAlgorithmNode> get nodes {
  if (_nodes is EqualUnmodifiableListView) return _nodes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_nodes);
}


/// Create a copy of GuidelineAlgorithmPayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GuidelineAlgorithmPayloadCopyWith<_GuidelineAlgorithmPayload> get copyWith => __$GuidelineAlgorithmPayloadCopyWithImpl<_GuidelineAlgorithmPayload>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GuidelineAlgorithmPayloadToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GuidelineAlgorithmPayload&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other._nodes, _nodes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,const DeepCollectionEquality().hash(_nodes));

@override
String toString() {
  return 'GuidelineAlgorithmPayload(title: $title, nodes: $nodes)';
}


}

/// @nodoc
abstract mixin class _$GuidelineAlgorithmPayloadCopyWith<$Res> implements $GuidelineAlgorithmPayloadCopyWith<$Res> {
  factory _$GuidelineAlgorithmPayloadCopyWith(_GuidelineAlgorithmPayload value, $Res Function(_GuidelineAlgorithmPayload) _then) = __$GuidelineAlgorithmPayloadCopyWithImpl;
@override @useResult
$Res call({
 String title, List<GuidelineAlgorithmNode> nodes
});




}
/// @nodoc
class __$GuidelineAlgorithmPayloadCopyWithImpl<$Res>
    implements _$GuidelineAlgorithmPayloadCopyWith<$Res> {
  __$GuidelineAlgorithmPayloadCopyWithImpl(this._self, this._then);

  final _GuidelineAlgorithmPayload _self;
  final $Res Function(_GuidelineAlgorithmPayload) _then;

/// Create a copy of GuidelineAlgorithmPayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? nodes = null,}) {
  return _then(_GuidelineAlgorithmPayload(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,nodes: null == nodes ? _self._nodes : nodes // ignore: cast_nullable_to_non_nullable
as List<GuidelineAlgorithmNode>,
  ));
}


}


/// @nodoc
mixin _$GuidelineAsset {

@JsonKey(name: 'asset_id') String? get id; String get type;@JsonKey(name: 'mime_type') String get mimeType; String get checksum;@JsonKey(name: 'size_bytes') int get sizeBytes;@JsonKey(name: 'original_filename') String get originalFilename; String get url;@JsonKey(name: 'expires_at') DateTime? get expiresAt;
/// Create a copy of GuidelineAsset
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GuidelineAssetCopyWith<GuidelineAsset> get copyWith => _$GuidelineAssetCopyWithImpl<GuidelineAsset>(this as GuidelineAsset, _$identity);

  /// Serializes this GuidelineAsset to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GuidelineAsset&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.checksum, checksum) || other.checksum == checksum)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.originalFilename, originalFilename) || other.originalFilename == originalFilename)&&(identical(other.url, url) || other.url == url)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,mimeType,checksum,sizeBytes,originalFilename,url,expiresAt);

@override
String toString() {
  return 'GuidelineAsset(id: $id, type: $type, mimeType: $mimeType, checksum: $checksum, sizeBytes: $sizeBytes, originalFilename: $originalFilename, url: $url, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class $GuidelineAssetCopyWith<$Res>  {
  factory $GuidelineAssetCopyWith(GuidelineAsset value, $Res Function(GuidelineAsset) _then) = _$GuidelineAssetCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'asset_id') String? id, String type,@JsonKey(name: 'mime_type') String mimeType, String checksum,@JsonKey(name: 'size_bytes') int sizeBytes,@JsonKey(name: 'original_filename') String originalFilename, String url,@JsonKey(name: 'expires_at') DateTime? expiresAt
});




}
/// @nodoc
class _$GuidelineAssetCopyWithImpl<$Res>
    implements $GuidelineAssetCopyWith<$Res> {
  _$GuidelineAssetCopyWithImpl(this._self, this._then);

  final GuidelineAsset _self;
  final $Res Function(GuidelineAsset) _then;

/// Create a copy of GuidelineAsset
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? type = null,Object? mimeType = null,Object? checksum = null,Object? sizeBytes = null,Object? originalFilename = null,Object? url = null,Object? expiresAt = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,mimeType: null == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String,checksum: null == checksum ? _self.checksum : checksum // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,originalFilename: null == originalFilename ? _self.originalFilename : originalFilename // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _GuidelineAsset implements GuidelineAsset {
  const _GuidelineAsset({@JsonKey(name: 'asset_id') this.id, this.type = '', @JsonKey(name: 'mime_type') this.mimeType = '', this.checksum = '', @JsonKey(name: 'size_bytes') this.sizeBytes = 0, @JsonKey(name: 'original_filename') this.originalFilename = '', this.url = '', @JsonKey(name: 'expires_at') this.expiresAt});
  factory _GuidelineAsset.fromJson(Map<String, dynamic> json) => _$GuidelineAssetFromJson(json);

@override@JsonKey(name: 'asset_id') final  String? id;
@override@JsonKey() final  String type;
@override@JsonKey(name: 'mime_type') final  String mimeType;
@override@JsonKey() final  String checksum;
@override@JsonKey(name: 'size_bytes') final  int sizeBytes;
@override@JsonKey(name: 'original_filename') final  String originalFilename;
@override@JsonKey() final  String url;
@override@JsonKey(name: 'expires_at') final  DateTime? expiresAt;

/// Create a copy of GuidelineAsset
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GuidelineAssetCopyWith<_GuidelineAsset> get copyWith => __$GuidelineAssetCopyWithImpl<_GuidelineAsset>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GuidelineAssetToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GuidelineAsset&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.checksum, checksum) || other.checksum == checksum)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.originalFilename, originalFilename) || other.originalFilename == originalFilename)&&(identical(other.url, url) || other.url == url)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,mimeType,checksum,sizeBytes,originalFilename,url,expiresAt);

@override
String toString() {
  return 'GuidelineAsset(id: $id, type: $type, mimeType: $mimeType, checksum: $checksum, sizeBytes: $sizeBytes, originalFilename: $originalFilename, url: $url, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$GuidelineAssetCopyWith<$Res> implements $GuidelineAssetCopyWith<$Res> {
  factory _$GuidelineAssetCopyWith(_GuidelineAsset value, $Res Function(_GuidelineAsset) _then) = __$GuidelineAssetCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'asset_id') String? id, String type,@JsonKey(name: 'mime_type') String mimeType, String checksum,@JsonKey(name: 'size_bytes') int sizeBytes,@JsonKey(name: 'original_filename') String originalFilename, String url,@JsonKey(name: 'expires_at') DateTime? expiresAt
});




}
/// @nodoc
class __$GuidelineAssetCopyWithImpl<$Res>
    implements _$GuidelineAssetCopyWith<$Res> {
  __$GuidelineAssetCopyWithImpl(this._self, this._then);

  final _GuidelineAsset _self;
  final $Res Function(_GuidelineAsset) _then;

/// Create a copy of GuidelineAsset
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? type = null,Object? mimeType = null,Object? checksum = null,Object? sizeBytes = null,Object? originalFilename = null,Object? url = null,Object? expiresAt = freezed,}) {
  return _then(_GuidelineAsset(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,mimeType: null == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String,checksum: null == checksum ? _self.checksum : checksum // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,originalFilename: null == originalFilename ? _self.originalFilename : originalFilename // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$OfflinePackageManifest {

@JsonKey(name: 'guideline_id') String get guidelineId;@JsonKey(name: 'version_id') String get versionId;@JsonKey(name: 'package_version') int get packageVersion; String get checksum;@JsonKey(name: 'size_bytes') int get sizeBytes; Map<String, String> get checksums;
/// Create a copy of OfflinePackageManifest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OfflinePackageManifestCopyWith<OfflinePackageManifest> get copyWith => _$OfflinePackageManifestCopyWithImpl<OfflinePackageManifest>(this as OfflinePackageManifest, _$identity);

  /// Serializes this OfflinePackageManifest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OfflinePackageManifest&&(identical(other.guidelineId, guidelineId) || other.guidelineId == guidelineId)&&(identical(other.versionId, versionId) || other.versionId == versionId)&&(identical(other.packageVersion, packageVersion) || other.packageVersion == packageVersion)&&(identical(other.checksum, checksum) || other.checksum == checksum)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&const DeepCollectionEquality().equals(other.checksums, checksums));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,guidelineId,versionId,packageVersion,checksum,sizeBytes,const DeepCollectionEquality().hash(checksums));

@override
String toString() {
  return 'OfflinePackageManifest(guidelineId: $guidelineId, versionId: $versionId, packageVersion: $packageVersion, checksum: $checksum, sizeBytes: $sizeBytes, checksums: $checksums)';
}


}

/// @nodoc
abstract mixin class $OfflinePackageManifestCopyWith<$Res>  {
  factory $OfflinePackageManifestCopyWith(OfflinePackageManifest value, $Res Function(OfflinePackageManifest) _then) = _$OfflinePackageManifestCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'guideline_id') String guidelineId,@JsonKey(name: 'version_id') String versionId,@JsonKey(name: 'package_version') int packageVersion, String checksum,@JsonKey(name: 'size_bytes') int sizeBytes, Map<String, String> checksums
});




}
/// @nodoc
class _$OfflinePackageManifestCopyWithImpl<$Res>
    implements $OfflinePackageManifestCopyWith<$Res> {
  _$OfflinePackageManifestCopyWithImpl(this._self, this._then);

  final OfflinePackageManifest _self;
  final $Res Function(OfflinePackageManifest) _then;

/// Create a copy of OfflinePackageManifest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? guidelineId = null,Object? versionId = null,Object? packageVersion = null,Object? checksum = null,Object? sizeBytes = null,Object? checksums = null,}) {
  return _then(_self.copyWith(
guidelineId: null == guidelineId ? _self.guidelineId : guidelineId // ignore: cast_nullable_to_non_nullable
as String,versionId: null == versionId ? _self.versionId : versionId // ignore: cast_nullable_to_non_nullable
as String,packageVersion: null == packageVersion ? _self.packageVersion : packageVersion // ignore: cast_nullable_to_non_nullable
as int,checksum: null == checksum ? _self.checksum : checksum // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,checksums: null == checksums ? _self.checksums : checksums // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _OfflinePackageManifest implements OfflinePackageManifest {
  const _OfflinePackageManifest({@JsonKey(name: 'guideline_id') required this.guidelineId, @JsonKey(name: 'version_id') required this.versionId, @JsonKey(name: 'package_version') required this.packageVersion, required this.checksum, @JsonKey(name: 'size_bytes') this.sizeBytes = 0, final  Map<String, String> checksums = const <String, String>{}}): _checksums = checksums;
  factory _OfflinePackageManifest.fromJson(Map<String, dynamic> json) => _$OfflinePackageManifestFromJson(json);

@override@JsonKey(name: 'guideline_id') final  String guidelineId;
@override@JsonKey(name: 'version_id') final  String versionId;
@override@JsonKey(name: 'package_version') final  int packageVersion;
@override final  String checksum;
@override@JsonKey(name: 'size_bytes') final  int sizeBytes;
 final  Map<String, String> _checksums;
@override@JsonKey() Map<String, String> get checksums {
  if (_checksums is EqualUnmodifiableMapView) return _checksums;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_checksums);
}


/// Create a copy of OfflinePackageManifest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OfflinePackageManifestCopyWith<_OfflinePackageManifest> get copyWith => __$OfflinePackageManifestCopyWithImpl<_OfflinePackageManifest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OfflinePackageManifestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OfflinePackageManifest&&(identical(other.guidelineId, guidelineId) || other.guidelineId == guidelineId)&&(identical(other.versionId, versionId) || other.versionId == versionId)&&(identical(other.packageVersion, packageVersion) || other.packageVersion == packageVersion)&&(identical(other.checksum, checksum) || other.checksum == checksum)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&const DeepCollectionEquality().equals(other._checksums, _checksums));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,guidelineId,versionId,packageVersion,checksum,sizeBytes,const DeepCollectionEquality().hash(_checksums));

@override
String toString() {
  return 'OfflinePackageManifest(guidelineId: $guidelineId, versionId: $versionId, packageVersion: $packageVersion, checksum: $checksum, sizeBytes: $sizeBytes, checksums: $checksums)';
}


}

/// @nodoc
abstract mixin class _$OfflinePackageManifestCopyWith<$Res> implements $OfflinePackageManifestCopyWith<$Res> {
  factory _$OfflinePackageManifestCopyWith(_OfflinePackageManifest value, $Res Function(_OfflinePackageManifest) _then) = __$OfflinePackageManifestCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'guideline_id') String guidelineId,@JsonKey(name: 'version_id') String versionId,@JsonKey(name: 'package_version') int packageVersion, String checksum,@JsonKey(name: 'size_bytes') int sizeBytes, Map<String, String> checksums
});




}
/// @nodoc
class __$OfflinePackageManifestCopyWithImpl<$Res>
    implements _$OfflinePackageManifestCopyWith<$Res> {
  __$OfflinePackageManifestCopyWithImpl(this._self, this._then);

  final _OfflinePackageManifest _self;
  final $Res Function(_OfflinePackageManifest) _then;

/// Create a copy of OfflinePackageManifest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? guidelineId = null,Object? versionId = null,Object? packageVersion = null,Object? checksum = null,Object? sizeBytes = null,Object? checksums = null,}) {
  return _then(_OfflinePackageManifest(
guidelineId: null == guidelineId ? _self.guidelineId : guidelineId // ignore: cast_nullable_to_non_nullable
as String,versionId: null == versionId ? _self.versionId : versionId // ignore: cast_nullable_to_non_nullable
as String,packageVersion: null == packageVersion ? _self.packageVersion : packageVersion // ignore: cast_nullable_to_non_nullable
as int,checksum: null == checksum ? _self.checksum : checksum // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,checksums: null == checksums ? _self._checksums : checksums // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}


}

GuidelineBlock _$GuidelineBlockFromJson(
  Map<String, dynamic> json
) {
        switch (json['kind']) {
                  case 'paragraph':
          return ParagraphGuidelineBlock.fromJson(
            json
          );
                case 'heading':
          return HeadingGuidelineBlock.fromJson(
            json
          );
                case 'orderedList':
          return OrderedListGuidelineBlock.fromJson(
            json
          );
                case 'unorderedList':
          return UnorderedListGuidelineBlock.fromJson(
            json
          );
                case 'table':
          return TableGuidelineBlock.fromJson(
            json
          );
                case 'figure':
          return FigureGuidelineBlock.fromJson(
            json
          );
                case 'callout':
          return CalloutGuidelineBlock.fromJson(
            json
          );
                case 'algorithm':
          return AlgorithmGuidelineBlock.fromJson(
            json
          );
                case 'reference':
          return ReferenceGuidelineBlock.fromJson(
            json
          );
                case 'pageBreak':
          return PageBreakGuidelineBlock.fromJson(
            json
          );
        
          default:
            return UnknownGuidelineBlock.fromJson(
  json
);
        }
      
}

/// @nodoc
mixin _$GuidelineBlock {

 String get id; String? get sectionId; int get sortOrder; int? get pageStart; int? get pageEnd;
/// Create a copy of GuidelineBlock
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GuidelineBlockCopyWith<GuidelineBlock> get copyWith => _$GuidelineBlockCopyWithImpl<GuidelineBlock>(this as GuidelineBlock, _$identity);

  /// Serializes this GuidelineBlock to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GuidelineBlock&&(identical(other.id, id) || other.id == id)&&(identical(other.sectionId, sectionId) || other.sectionId == sectionId)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.pageStart, pageStart) || other.pageStart == pageStart)&&(identical(other.pageEnd, pageEnd) || other.pageEnd == pageEnd));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sectionId,sortOrder,pageStart,pageEnd);

@override
String toString() {
  return 'GuidelineBlock(id: $id, sectionId: $sectionId, sortOrder: $sortOrder, pageStart: $pageStart, pageEnd: $pageEnd)';
}


}

/// @nodoc
abstract mixin class $GuidelineBlockCopyWith<$Res>  {
  factory $GuidelineBlockCopyWith(GuidelineBlock value, $Res Function(GuidelineBlock) _then) = _$GuidelineBlockCopyWithImpl;
@useResult
$Res call({
 String id, String? sectionId, int sortOrder, int? pageStart, int? pageEnd
});




}
/// @nodoc
class _$GuidelineBlockCopyWithImpl<$Res>
    implements $GuidelineBlockCopyWith<$Res> {
  _$GuidelineBlockCopyWithImpl(this._self, this._then);

  final GuidelineBlock _self;
  final $Res Function(GuidelineBlock) _then;

/// Create a copy of GuidelineBlock
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? sectionId = freezed,Object? sortOrder = null,Object? pageStart = freezed,Object? pageEnd = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sectionId: freezed == sectionId ? _self.sectionId : sectionId // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,pageStart: freezed == pageStart ? _self.pageStart : pageStart // ignore: cast_nullable_to_non_nullable
as int?,pageEnd: freezed == pageEnd ? _self.pageEnd : pageEnd // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class ParagraphGuidelineBlock extends GuidelineBlock {
  const ParagraphGuidelineBlock({required this.id, this.sectionId, required this.sortOrder, required this.text, this.pageStart, this.pageEnd, final  String? $type}): $type = $type ?? 'paragraph',super._();
  factory ParagraphGuidelineBlock.fromJson(Map<String, dynamic> json) => _$ParagraphGuidelineBlockFromJson(json);

@override final  String id;
@override final  String? sectionId;
@override final  int sortOrder;
 final  String text;
@override final  int? pageStart;
@override final  int? pageEnd;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of GuidelineBlock
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ParagraphGuidelineBlockCopyWith<ParagraphGuidelineBlock> get copyWith => _$ParagraphGuidelineBlockCopyWithImpl<ParagraphGuidelineBlock>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ParagraphGuidelineBlockToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ParagraphGuidelineBlock&&(identical(other.id, id) || other.id == id)&&(identical(other.sectionId, sectionId) || other.sectionId == sectionId)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.text, text) || other.text == text)&&(identical(other.pageStart, pageStart) || other.pageStart == pageStart)&&(identical(other.pageEnd, pageEnd) || other.pageEnd == pageEnd));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sectionId,sortOrder,text,pageStart,pageEnd);

@override
String toString() {
  return 'GuidelineBlock.paragraph(id: $id, sectionId: $sectionId, sortOrder: $sortOrder, text: $text, pageStart: $pageStart, pageEnd: $pageEnd)';
}


}

/// @nodoc
abstract mixin class $ParagraphGuidelineBlockCopyWith<$Res> implements $GuidelineBlockCopyWith<$Res> {
  factory $ParagraphGuidelineBlockCopyWith(ParagraphGuidelineBlock value, $Res Function(ParagraphGuidelineBlock) _then) = _$ParagraphGuidelineBlockCopyWithImpl;
@override @useResult
$Res call({
 String id, String? sectionId, int sortOrder, String text, int? pageStart, int? pageEnd
});




}
/// @nodoc
class _$ParagraphGuidelineBlockCopyWithImpl<$Res>
    implements $ParagraphGuidelineBlockCopyWith<$Res> {
  _$ParagraphGuidelineBlockCopyWithImpl(this._self, this._then);

  final ParagraphGuidelineBlock _self;
  final $Res Function(ParagraphGuidelineBlock) _then;

/// Create a copy of GuidelineBlock
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sectionId = freezed,Object? sortOrder = null,Object? text = null,Object? pageStart = freezed,Object? pageEnd = freezed,}) {
  return _then(ParagraphGuidelineBlock(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sectionId: freezed == sectionId ? _self.sectionId : sectionId // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,pageStart: freezed == pageStart ? _self.pageStart : pageStart // ignore: cast_nullable_to_non_nullable
as int?,pageEnd: freezed == pageEnd ? _self.pageEnd : pageEnd // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class HeadingGuidelineBlock extends GuidelineBlock {
  const HeadingGuidelineBlock({required this.id, this.sectionId, required this.sortOrder, required this.text, required this.level, this.pageStart, this.pageEnd, final  String? $type}): $type = $type ?? 'heading',super._();
  factory HeadingGuidelineBlock.fromJson(Map<String, dynamic> json) => _$HeadingGuidelineBlockFromJson(json);

@override final  String id;
@override final  String? sectionId;
@override final  int sortOrder;
 final  String text;
 final  int level;
@override final  int? pageStart;
@override final  int? pageEnd;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of GuidelineBlock
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HeadingGuidelineBlockCopyWith<HeadingGuidelineBlock> get copyWith => _$HeadingGuidelineBlockCopyWithImpl<HeadingGuidelineBlock>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HeadingGuidelineBlockToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HeadingGuidelineBlock&&(identical(other.id, id) || other.id == id)&&(identical(other.sectionId, sectionId) || other.sectionId == sectionId)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.text, text) || other.text == text)&&(identical(other.level, level) || other.level == level)&&(identical(other.pageStart, pageStart) || other.pageStart == pageStart)&&(identical(other.pageEnd, pageEnd) || other.pageEnd == pageEnd));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sectionId,sortOrder,text,level,pageStart,pageEnd);

@override
String toString() {
  return 'GuidelineBlock.heading(id: $id, sectionId: $sectionId, sortOrder: $sortOrder, text: $text, level: $level, pageStart: $pageStart, pageEnd: $pageEnd)';
}


}

/// @nodoc
abstract mixin class $HeadingGuidelineBlockCopyWith<$Res> implements $GuidelineBlockCopyWith<$Res> {
  factory $HeadingGuidelineBlockCopyWith(HeadingGuidelineBlock value, $Res Function(HeadingGuidelineBlock) _then) = _$HeadingGuidelineBlockCopyWithImpl;
@override @useResult
$Res call({
 String id, String? sectionId, int sortOrder, String text, int level, int? pageStart, int? pageEnd
});




}
/// @nodoc
class _$HeadingGuidelineBlockCopyWithImpl<$Res>
    implements $HeadingGuidelineBlockCopyWith<$Res> {
  _$HeadingGuidelineBlockCopyWithImpl(this._self, this._then);

  final HeadingGuidelineBlock _self;
  final $Res Function(HeadingGuidelineBlock) _then;

/// Create a copy of GuidelineBlock
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sectionId = freezed,Object? sortOrder = null,Object? text = null,Object? level = null,Object? pageStart = freezed,Object? pageEnd = freezed,}) {
  return _then(HeadingGuidelineBlock(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sectionId: freezed == sectionId ? _self.sectionId : sectionId // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,pageStart: freezed == pageStart ? _self.pageStart : pageStart // ignore: cast_nullable_to_non_nullable
as int?,pageEnd: freezed == pageEnd ? _self.pageEnd : pageEnd // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class OrderedListGuidelineBlock extends GuidelineBlock {
  const OrderedListGuidelineBlock({required this.id, this.sectionId, required this.sortOrder, required final  List<String> items, this.pageStart, this.pageEnd, final  String? $type}): _items = items,$type = $type ?? 'orderedList',super._();
  factory OrderedListGuidelineBlock.fromJson(Map<String, dynamic> json) => _$OrderedListGuidelineBlockFromJson(json);

@override final  String id;
@override final  String? sectionId;
@override final  int sortOrder;
 final  List<String> _items;
 List<String> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  int? pageStart;
@override final  int? pageEnd;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of GuidelineBlock
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderedListGuidelineBlockCopyWith<OrderedListGuidelineBlock> get copyWith => _$OrderedListGuidelineBlockCopyWithImpl<OrderedListGuidelineBlock>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrderedListGuidelineBlockToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderedListGuidelineBlock&&(identical(other.id, id) || other.id == id)&&(identical(other.sectionId, sectionId) || other.sectionId == sectionId)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.pageStart, pageStart) || other.pageStart == pageStart)&&(identical(other.pageEnd, pageEnd) || other.pageEnd == pageEnd));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sectionId,sortOrder,const DeepCollectionEquality().hash(_items),pageStart,pageEnd);

@override
String toString() {
  return 'GuidelineBlock.orderedList(id: $id, sectionId: $sectionId, sortOrder: $sortOrder, items: $items, pageStart: $pageStart, pageEnd: $pageEnd)';
}


}

/// @nodoc
abstract mixin class $OrderedListGuidelineBlockCopyWith<$Res> implements $GuidelineBlockCopyWith<$Res> {
  factory $OrderedListGuidelineBlockCopyWith(OrderedListGuidelineBlock value, $Res Function(OrderedListGuidelineBlock) _then) = _$OrderedListGuidelineBlockCopyWithImpl;
@override @useResult
$Res call({
 String id, String? sectionId, int sortOrder, List<String> items, int? pageStart, int? pageEnd
});




}
/// @nodoc
class _$OrderedListGuidelineBlockCopyWithImpl<$Res>
    implements $OrderedListGuidelineBlockCopyWith<$Res> {
  _$OrderedListGuidelineBlockCopyWithImpl(this._self, this._then);

  final OrderedListGuidelineBlock _self;
  final $Res Function(OrderedListGuidelineBlock) _then;

/// Create a copy of GuidelineBlock
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sectionId = freezed,Object? sortOrder = null,Object? items = null,Object? pageStart = freezed,Object? pageEnd = freezed,}) {
  return _then(OrderedListGuidelineBlock(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sectionId: freezed == sectionId ? _self.sectionId : sectionId // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<String>,pageStart: freezed == pageStart ? _self.pageStart : pageStart // ignore: cast_nullable_to_non_nullable
as int?,pageEnd: freezed == pageEnd ? _self.pageEnd : pageEnd // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class UnorderedListGuidelineBlock extends GuidelineBlock {
  const UnorderedListGuidelineBlock({required this.id, this.sectionId, required this.sortOrder, required final  List<String> items, this.pageStart, this.pageEnd, final  String? $type}): _items = items,$type = $type ?? 'unorderedList',super._();
  factory UnorderedListGuidelineBlock.fromJson(Map<String, dynamic> json) => _$UnorderedListGuidelineBlockFromJson(json);

@override final  String id;
@override final  String? sectionId;
@override final  int sortOrder;
 final  List<String> _items;
 List<String> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  int? pageStart;
@override final  int? pageEnd;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of GuidelineBlock
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnorderedListGuidelineBlockCopyWith<UnorderedListGuidelineBlock> get copyWith => _$UnorderedListGuidelineBlockCopyWithImpl<UnorderedListGuidelineBlock>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UnorderedListGuidelineBlockToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnorderedListGuidelineBlock&&(identical(other.id, id) || other.id == id)&&(identical(other.sectionId, sectionId) || other.sectionId == sectionId)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.pageStart, pageStart) || other.pageStart == pageStart)&&(identical(other.pageEnd, pageEnd) || other.pageEnd == pageEnd));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sectionId,sortOrder,const DeepCollectionEquality().hash(_items),pageStart,pageEnd);

@override
String toString() {
  return 'GuidelineBlock.unorderedList(id: $id, sectionId: $sectionId, sortOrder: $sortOrder, items: $items, pageStart: $pageStart, pageEnd: $pageEnd)';
}


}

/// @nodoc
abstract mixin class $UnorderedListGuidelineBlockCopyWith<$Res> implements $GuidelineBlockCopyWith<$Res> {
  factory $UnorderedListGuidelineBlockCopyWith(UnorderedListGuidelineBlock value, $Res Function(UnorderedListGuidelineBlock) _then) = _$UnorderedListGuidelineBlockCopyWithImpl;
@override @useResult
$Res call({
 String id, String? sectionId, int sortOrder, List<String> items, int? pageStart, int? pageEnd
});




}
/// @nodoc
class _$UnorderedListGuidelineBlockCopyWithImpl<$Res>
    implements $UnorderedListGuidelineBlockCopyWith<$Res> {
  _$UnorderedListGuidelineBlockCopyWithImpl(this._self, this._then);

  final UnorderedListGuidelineBlock _self;
  final $Res Function(UnorderedListGuidelineBlock) _then;

/// Create a copy of GuidelineBlock
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sectionId = freezed,Object? sortOrder = null,Object? items = null,Object? pageStart = freezed,Object? pageEnd = freezed,}) {
  return _then(UnorderedListGuidelineBlock(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sectionId: freezed == sectionId ? _self.sectionId : sectionId // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<String>,pageStart: freezed == pageStart ? _self.pageStart : pageStart // ignore: cast_nullable_to_non_nullable
as int?,pageEnd: freezed == pageEnd ? _self.pageEnd : pageEnd // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class TableGuidelineBlock extends GuidelineBlock {
  const TableGuidelineBlock({required this.id, this.sectionId, required this.sortOrder, required this.payload, this.pageStart, this.pageEnd, final  String? $type}): $type = $type ?? 'table',super._();
  factory TableGuidelineBlock.fromJson(Map<String, dynamic> json) => _$TableGuidelineBlockFromJson(json);

@override final  String id;
@override final  String? sectionId;
@override final  int sortOrder;
 final  GuidelineTablePayload payload;
@override final  int? pageStart;
@override final  int? pageEnd;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of GuidelineBlock
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TableGuidelineBlockCopyWith<TableGuidelineBlock> get copyWith => _$TableGuidelineBlockCopyWithImpl<TableGuidelineBlock>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TableGuidelineBlockToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TableGuidelineBlock&&(identical(other.id, id) || other.id == id)&&(identical(other.sectionId, sectionId) || other.sectionId == sectionId)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.payload, payload) || other.payload == payload)&&(identical(other.pageStart, pageStart) || other.pageStart == pageStart)&&(identical(other.pageEnd, pageEnd) || other.pageEnd == pageEnd));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sectionId,sortOrder,payload,pageStart,pageEnd);

@override
String toString() {
  return 'GuidelineBlock.table(id: $id, sectionId: $sectionId, sortOrder: $sortOrder, payload: $payload, pageStart: $pageStart, pageEnd: $pageEnd)';
}


}

/// @nodoc
abstract mixin class $TableGuidelineBlockCopyWith<$Res> implements $GuidelineBlockCopyWith<$Res> {
  factory $TableGuidelineBlockCopyWith(TableGuidelineBlock value, $Res Function(TableGuidelineBlock) _then) = _$TableGuidelineBlockCopyWithImpl;
@override @useResult
$Res call({
 String id, String? sectionId, int sortOrder, GuidelineTablePayload payload, int? pageStart, int? pageEnd
});


$GuidelineTablePayloadCopyWith<$Res> get payload;

}
/// @nodoc
class _$TableGuidelineBlockCopyWithImpl<$Res>
    implements $TableGuidelineBlockCopyWith<$Res> {
  _$TableGuidelineBlockCopyWithImpl(this._self, this._then);

  final TableGuidelineBlock _self;
  final $Res Function(TableGuidelineBlock) _then;

/// Create a copy of GuidelineBlock
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sectionId = freezed,Object? sortOrder = null,Object? payload = null,Object? pageStart = freezed,Object? pageEnd = freezed,}) {
  return _then(TableGuidelineBlock(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sectionId: freezed == sectionId ? _self.sectionId : sectionId // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as GuidelineTablePayload,pageStart: freezed == pageStart ? _self.pageStart : pageStart // ignore: cast_nullable_to_non_nullable
as int?,pageEnd: freezed == pageEnd ? _self.pageEnd : pageEnd // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of GuidelineBlock
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GuidelineTablePayloadCopyWith<$Res> get payload {
  
  return $GuidelineTablePayloadCopyWith<$Res>(_self.payload, (value) {
    return _then(_self.copyWith(payload: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class FigureGuidelineBlock extends GuidelineBlock {
  const FigureGuidelineBlock({required this.id, this.sectionId, required this.sortOrder, required this.payload, this.asset, this.pageStart, this.pageEnd, final  String? $type}): $type = $type ?? 'figure',super._();
  factory FigureGuidelineBlock.fromJson(Map<String, dynamic> json) => _$FigureGuidelineBlockFromJson(json);

@override final  String id;
@override final  String? sectionId;
@override final  int sortOrder;
 final  GuidelineFigurePayload payload;
 final  GuidelineAsset? asset;
@override final  int? pageStart;
@override final  int? pageEnd;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of GuidelineBlock
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FigureGuidelineBlockCopyWith<FigureGuidelineBlock> get copyWith => _$FigureGuidelineBlockCopyWithImpl<FigureGuidelineBlock>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FigureGuidelineBlockToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FigureGuidelineBlock&&(identical(other.id, id) || other.id == id)&&(identical(other.sectionId, sectionId) || other.sectionId == sectionId)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.payload, payload) || other.payload == payload)&&(identical(other.asset, asset) || other.asset == asset)&&(identical(other.pageStart, pageStart) || other.pageStart == pageStart)&&(identical(other.pageEnd, pageEnd) || other.pageEnd == pageEnd));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sectionId,sortOrder,payload,asset,pageStart,pageEnd);

@override
String toString() {
  return 'GuidelineBlock.figure(id: $id, sectionId: $sectionId, sortOrder: $sortOrder, payload: $payload, asset: $asset, pageStart: $pageStart, pageEnd: $pageEnd)';
}


}

/// @nodoc
abstract mixin class $FigureGuidelineBlockCopyWith<$Res> implements $GuidelineBlockCopyWith<$Res> {
  factory $FigureGuidelineBlockCopyWith(FigureGuidelineBlock value, $Res Function(FigureGuidelineBlock) _then) = _$FigureGuidelineBlockCopyWithImpl;
@override @useResult
$Res call({
 String id, String? sectionId, int sortOrder, GuidelineFigurePayload payload, GuidelineAsset? asset, int? pageStart, int? pageEnd
});


$GuidelineFigurePayloadCopyWith<$Res> get payload;$GuidelineAssetCopyWith<$Res>? get asset;

}
/// @nodoc
class _$FigureGuidelineBlockCopyWithImpl<$Res>
    implements $FigureGuidelineBlockCopyWith<$Res> {
  _$FigureGuidelineBlockCopyWithImpl(this._self, this._then);

  final FigureGuidelineBlock _self;
  final $Res Function(FigureGuidelineBlock) _then;

/// Create a copy of GuidelineBlock
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sectionId = freezed,Object? sortOrder = null,Object? payload = null,Object? asset = freezed,Object? pageStart = freezed,Object? pageEnd = freezed,}) {
  return _then(FigureGuidelineBlock(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sectionId: freezed == sectionId ? _self.sectionId : sectionId // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as GuidelineFigurePayload,asset: freezed == asset ? _self.asset : asset // ignore: cast_nullable_to_non_nullable
as GuidelineAsset?,pageStart: freezed == pageStart ? _self.pageStart : pageStart // ignore: cast_nullable_to_non_nullable
as int?,pageEnd: freezed == pageEnd ? _self.pageEnd : pageEnd // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of GuidelineBlock
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GuidelineFigurePayloadCopyWith<$Res> get payload {
  
  return $GuidelineFigurePayloadCopyWith<$Res>(_self.payload, (value) {
    return _then(_self.copyWith(payload: value));
  });
}/// Create a copy of GuidelineBlock
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GuidelineAssetCopyWith<$Res>? get asset {
    if (_self.asset == null) {
    return null;
  }

  return $GuidelineAssetCopyWith<$Res>(_self.asset!, (value) {
    return _then(_self.copyWith(asset: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class CalloutGuidelineBlock extends GuidelineBlock {
  const CalloutGuidelineBlock({required this.id, this.sectionId, required this.sortOrder, required this.blockType, required this.payload, this.pageStart, this.pageEnd, final  String? $type}): $type = $type ?? 'callout',super._();
  factory CalloutGuidelineBlock.fromJson(Map<String, dynamic> json) => _$CalloutGuidelineBlockFromJson(json);

@override final  String id;
@override final  String? sectionId;
@override final  int sortOrder;
 final  String blockType;
 final  GuidelineCalloutPayload payload;
@override final  int? pageStart;
@override final  int? pageEnd;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of GuidelineBlock
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CalloutGuidelineBlockCopyWith<CalloutGuidelineBlock> get copyWith => _$CalloutGuidelineBlockCopyWithImpl<CalloutGuidelineBlock>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CalloutGuidelineBlockToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CalloutGuidelineBlock&&(identical(other.id, id) || other.id == id)&&(identical(other.sectionId, sectionId) || other.sectionId == sectionId)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.blockType, blockType) || other.blockType == blockType)&&(identical(other.payload, payload) || other.payload == payload)&&(identical(other.pageStart, pageStart) || other.pageStart == pageStart)&&(identical(other.pageEnd, pageEnd) || other.pageEnd == pageEnd));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sectionId,sortOrder,blockType,payload,pageStart,pageEnd);

@override
String toString() {
  return 'GuidelineBlock.callout(id: $id, sectionId: $sectionId, sortOrder: $sortOrder, blockType: $blockType, payload: $payload, pageStart: $pageStart, pageEnd: $pageEnd)';
}


}

/// @nodoc
abstract mixin class $CalloutGuidelineBlockCopyWith<$Res> implements $GuidelineBlockCopyWith<$Res> {
  factory $CalloutGuidelineBlockCopyWith(CalloutGuidelineBlock value, $Res Function(CalloutGuidelineBlock) _then) = _$CalloutGuidelineBlockCopyWithImpl;
@override @useResult
$Res call({
 String id, String? sectionId, int sortOrder, String blockType, GuidelineCalloutPayload payload, int? pageStart, int? pageEnd
});


$GuidelineCalloutPayloadCopyWith<$Res> get payload;

}
/// @nodoc
class _$CalloutGuidelineBlockCopyWithImpl<$Res>
    implements $CalloutGuidelineBlockCopyWith<$Res> {
  _$CalloutGuidelineBlockCopyWithImpl(this._self, this._then);

  final CalloutGuidelineBlock _self;
  final $Res Function(CalloutGuidelineBlock) _then;

/// Create a copy of GuidelineBlock
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sectionId = freezed,Object? sortOrder = null,Object? blockType = null,Object? payload = null,Object? pageStart = freezed,Object? pageEnd = freezed,}) {
  return _then(CalloutGuidelineBlock(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sectionId: freezed == sectionId ? _self.sectionId : sectionId // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,blockType: null == blockType ? _self.blockType : blockType // ignore: cast_nullable_to_non_nullable
as String,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as GuidelineCalloutPayload,pageStart: freezed == pageStart ? _self.pageStart : pageStart // ignore: cast_nullable_to_non_nullable
as int?,pageEnd: freezed == pageEnd ? _self.pageEnd : pageEnd // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of GuidelineBlock
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GuidelineCalloutPayloadCopyWith<$Res> get payload {
  
  return $GuidelineCalloutPayloadCopyWith<$Res>(_self.payload, (value) {
    return _then(_self.copyWith(payload: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class AlgorithmGuidelineBlock extends GuidelineBlock {
  const AlgorithmGuidelineBlock({required this.id, this.sectionId, required this.sortOrder, required this.payload, this.pageStart, this.pageEnd, final  String? $type}): $type = $type ?? 'algorithm',super._();
  factory AlgorithmGuidelineBlock.fromJson(Map<String, dynamic> json) => _$AlgorithmGuidelineBlockFromJson(json);

@override final  String id;
@override final  String? sectionId;
@override final  int sortOrder;
 final  GuidelineAlgorithmPayload payload;
@override final  int? pageStart;
@override final  int? pageEnd;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of GuidelineBlock
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AlgorithmGuidelineBlockCopyWith<AlgorithmGuidelineBlock> get copyWith => _$AlgorithmGuidelineBlockCopyWithImpl<AlgorithmGuidelineBlock>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AlgorithmGuidelineBlockToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AlgorithmGuidelineBlock&&(identical(other.id, id) || other.id == id)&&(identical(other.sectionId, sectionId) || other.sectionId == sectionId)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.payload, payload) || other.payload == payload)&&(identical(other.pageStart, pageStart) || other.pageStart == pageStart)&&(identical(other.pageEnd, pageEnd) || other.pageEnd == pageEnd));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sectionId,sortOrder,payload,pageStart,pageEnd);

@override
String toString() {
  return 'GuidelineBlock.algorithm(id: $id, sectionId: $sectionId, sortOrder: $sortOrder, payload: $payload, pageStart: $pageStart, pageEnd: $pageEnd)';
}


}

/// @nodoc
abstract mixin class $AlgorithmGuidelineBlockCopyWith<$Res> implements $GuidelineBlockCopyWith<$Res> {
  factory $AlgorithmGuidelineBlockCopyWith(AlgorithmGuidelineBlock value, $Res Function(AlgorithmGuidelineBlock) _then) = _$AlgorithmGuidelineBlockCopyWithImpl;
@override @useResult
$Res call({
 String id, String? sectionId, int sortOrder, GuidelineAlgorithmPayload payload, int? pageStart, int? pageEnd
});


$GuidelineAlgorithmPayloadCopyWith<$Res> get payload;

}
/// @nodoc
class _$AlgorithmGuidelineBlockCopyWithImpl<$Res>
    implements $AlgorithmGuidelineBlockCopyWith<$Res> {
  _$AlgorithmGuidelineBlockCopyWithImpl(this._self, this._then);

  final AlgorithmGuidelineBlock _self;
  final $Res Function(AlgorithmGuidelineBlock) _then;

/// Create a copy of GuidelineBlock
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sectionId = freezed,Object? sortOrder = null,Object? payload = null,Object? pageStart = freezed,Object? pageEnd = freezed,}) {
  return _then(AlgorithmGuidelineBlock(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sectionId: freezed == sectionId ? _self.sectionId : sectionId // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as GuidelineAlgorithmPayload,pageStart: freezed == pageStart ? _self.pageStart : pageStart // ignore: cast_nullable_to_non_nullable
as int?,pageEnd: freezed == pageEnd ? _self.pageEnd : pageEnd // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of GuidelineBlock
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GuidelineAlgorithmPayloadCopyWith<$Res> get payload {
  
  return $GuidelineAlgorithmPayloadCopyWith<$Res>(_self.payload, (value) {
    return _then(_self.copyWith(payload: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class ReferenceGuidelineBlock extends GuidelineBlock {
  const ReferenceGuidelineBlock({required this.id, this.sectionId, required this.sortOrder, required this.citation, this.url = '', this.pageStart, this.pageEnd, final  String? $type}): $type = $type ?? 'reference',super._();
  factory ReferenceGuidelineBlock.fromJson(Map<String, dynamic> json) => _$ReferenceGuidelineBlockFromJson(json);

@override final  String id;
@override final  String? sectionId;
@override final  int sortOrder;
 final  String citation;
@JsonKey() final  String url;
@override final  int? pageStart;
@override final  int? pageEnd;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of GuidelineBlock
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReferenceGuidelineBlockCopyWith<ReferenceGuidelineBlock> get copyWith => _$ReferenceGuidelineBlockCopyWithImpl<ReferenceGuidelineBlock>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReferenceGuidelineBlockToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReferenceGuidelineBlock&&(identical(other.id, id) || other.id == id)&&(identical(other.sectionId, sectionId) || other.sectionId == sectionId)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.citation, citation) || other.citation == citation)&&(identical(other.url, url) || other.url == url)&&(identical(other.pageStart, pageStart) || other.pageStart == pageStart)&&(identical(other.pageEnd, pageEnd) || other.pageEnd == pageEnd));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sectionId,sortOrder,citation,url,pageStart,pageEnd);

@override
String toString() {
  return 'GuidelineBlock.reference(id: $id, sectionId: $sectionId, sortOrder: $sortOrder, citation: $citation, url: $url, pageStart: $pageStart, pageEnd: $pageEnd)';
}


}

/// @nodoc
abstract mixin class $ReferenceGuidelineBlockCopyWith<$Res> implements $GuidelineBlockCopyWith<$Res> {
  factory $ReferenceGuidelineBlockCopyWith(ReferenceGuidelineBlock value, $Res Function(ReferenceGuidelineBlock) _then) = _$ReferenceGuidelineBlockCopyWithImpl;
@override @useResult
$Res call({
 String id, String? sectionId, int sortOrder, String citation, String url, int? pageStart, int? pageEnd
});




}
/// @nodoc
class _$ReferenceGuidelineBlockCopyWithImpl<$Res>
    implements $ReferenceGuidelineBlockCopyWith<$Res> {
  _$ReferenceGuidelineBlockCopyWithImpl(this._self, this._then);

  final ReferenceGuidelineBlock _self;
  final $Res Function(ReferenceGuidelineBlock) _then;

/// Create a copy of GuidelineBlock
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sectionId = freezed,Object? sortOrder = null,Object? citation = null,Object? url = null,Object? pageStart = freezed,Object? pageEnd = freezed,}) {
  return _then(ReferenceGuidelineBlock(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sectionId: freezed == sectionId ? _self.sectionId : sectionId // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,citation: null == citation ? _self.citation : citation // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,pageStart: freezed == pageStart ? _self.pageStart : pageStart // ignore: cast_nullable_to_non_nullable
as int?,pageEnd: freezed == pageEnd ? _self.pageEnd : pageEnd // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class PageBreakGuidelineBlock extends GuidelineBlock {
  const PageBreakGuidelineBlock({required this.id, this.sectionId, required this.sortOrder, required this.page, this.pageStart, this.pageEnd, final  String? $type}): $type = $type ?? 'pageBreak',super._();
  factory PageBreakGuidelineBlock.fromJson(Map<String, dynamic> json) => _$PageBreakGuidelineBlockFromJson(json);

@override final  String id;
@override final  String? sectionId;
@override final  int sortOrder;
 final  int page;
@override final  int? pageStart;
@override final  int? pageEnd;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of GuidelineBlock
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PageBreakGuidelineBlockCopyWith<PageBreakGuidelineBlock> get copyWith => _$PageBreakGuidelineBlockCopyWithImpl<PageBreakGuidelineBlock>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PageBreakGuidelineBlockToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PageBreakGuidelineBlock&&(identical(other.id, id) || other.id == id)&&(identical(other.sectionId, sectionId) || other.sectionId == sectionId)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.page, page) || other.page == page)&&(identical(other.pageStart, pageStart) || other.pageStart == pageStart)&&(identical(other.pageEnd, pageEnd) || other.pageEnd == pageEnd));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sectionId,sortOrder,page,pageStart,pageEnd);

@override
String toString() {
  return 'GuidelineBlock.pageBreak(id: $id, sectionId: $sectionId, sortOrder: $sortOrder, page: $page, pageStart: $pageStart, pageEnd: $pageEnd)';
}


}

/// @nodoc
abstract mixin class $PageBreakGuidelineBlockCopyWith<$Res> implements $GuidelineBlockCopyWith<$Res> {
  factory $PageBreakGuidelineBlockCopyWith(PageBreakGuidelineBlock value, $Res Function(PageBreakGuidelineBlock) _then) = _$PageBreakGuidelineBlockCopyWithImpl;
@override @useResult
$Res call({
 String id, String? sectionId, int sortOrder, int page, int? pageStart, int? pageEnd
});




}
/// @nodoc
class _$PageBreakGuidelineBlockCopyWithImpl<$Res>
    implements $PageBreakGuidelineBlockCopyWith<$Res> {
  _$PageBreakGuidelineBlockCopyWithImpl(this._self, this._then);

  final PageBreakGuidelineBlock _self;
  final $Res Function(PageBreakGuidelineBlock) _then;

/// Create a copy of GuidelineBlock
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sectionId = freezed,Object? sortOrder = null,Object? page = null,Object? pageStart = freezed,Object? pageEnd = freezed,}) {
  return _then(PageBreakGuidelineBlock(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sectionId: freezed == sectionId ? _self.sectionId : sectionId // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,pageStart: freezed == pageStart ? _self.pageStart : pageStart // ignore: cast_nullable_to_non_nullable
as int?,pageEnd: freezed == pageEnd ? _self.pageEnd : pageEnd // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class UnknownGuidelineBlock extends GuidelineBlock {
  const UnknownGuidelineBlock({required this.id, this.sectionId, required this.sortOrder, this.rawType = 'unknown', final  Map<String, dynamic> raw = const <String, dynamic>{}, this.pageStart, this.pageEnd, final  String? $type}): _raw = raw,$type = $type ?? 'unknown',super._();
  factory UnknownGuidelineBlock.fromJson(Map<String, dynamic> json) => _$UnknownGuidelineBlockFromJson(json);

@override final  String id;
@override final  String? sectionId;
@override final  int sortOrder;
@JsonKey() final  String rawType;
 final  Map<String, dynamic> _raw;
@JsonKey() Map<String, dynamic> get raw {
  if (_raw is EqualUnmodifiableMapView) return _raw;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_raw);
}

@override final  int? pageStart;
@override final  int? pageEnd;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of GuidelineBlock
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnknownGuidelineBlockCopyWith<UnknownGuidelineBlock> get copyWith => _$UnknownGuidelineBlockCopyWithImpl<UnknownGuidelineBlock>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UnknownGuidelineBlockToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnknownGuidelineBlock&&(identical(other.id, id) || other.id == id)&&(identical(other.sectionId, sectionId) || other.sectionId == sectionId)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.rawType, rawType) || other.rawType == rawType)&&const DeepCollectionEquality().equals(other._raw, _raw)&&(identical(other.pageStart, pageStart) || other.pageStart == pageStart)&&(identical(other.pageEnd, pageEnd) || other.pageEnd == pageEnd));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sectionId,sortOrder,rawType,const DeepCollectionEquality().hash(_raw),pageStart,pageEnd);

@override
String toString() {
  return 'GuidelineBlock.unknown(id: $id, sectionId: $sectionId, sortOrder: $sortOrder, rawType: $rawType, raw: $raw, pageStart: $pageStart, pageEnd: $pageEnd)';
}


}

/// @nodoc
abstract mixin class $UnknownGuidelineBlockCopyWith<$Res> implements $GuidelineBlockCopyWith<$Res> {
  factory $UnknownGuidelineBlockCopyWith(UnknownGuidelineBlock value, $Res Function(UnknownGuidelineBlock) _then) = _$UnknownGuidelineBlockCopyWithImpl;
@override @useResult
$Res call({
 String id, String? sectionId, int sortOrder, String rawType, Map<String, dynamic> raw, int? pageStart, int? pageEnd
});




}
/// @nodoc
class _$UnknownGuidelineBlockCopyWithImpl<$Res>
    implements $UnknownGuidelineBlockCopyWith<$Res> {
  _$UnknownGuidelineBlockCopyWithImpl(this._self, this._then);

  final UnknownGuidelineBlock _self;
  final $Res Function(UnknownGuidelineBlock) _then;

/// Create a copy of GuidelineBlock
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sectionId = freezed,Object? sortOrder = null,Object? rawType = null,Object? raw = null,Object? pageStart = freezed,Object? pageEnd = freezed,}) {
  return _then(UnknownGuidelineBlock(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sectionId: freezed == sectionId ? _self.sectionId : sectionId // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,rawType: null == rawType ? _self.rawType : rawType // ignore: cast_nullable_to_non_nullable
as String,raw: null == raw ? _self._raw : raw // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,pageStart: freezed == pageStart ? _self.pageStart : pageStart // ignore: cast_nullable_to_non_nullable
as int?,pageEnd: freezed == pageEnd ? _self.pageEnd : pageEnd // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
