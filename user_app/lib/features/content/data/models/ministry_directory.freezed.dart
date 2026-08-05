// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ministry_directory.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MinistryDirectory {

 String get id; String get name; String get title;@JsonKey(name: 'ministry') String get ministryValue; String get department; String get phone;@JsonKey(name: 'alternative_phone') String get alternativePhone; String get email;@JsonKey(name: 'office_address') String get officeAddress;@JsonKey(name: 'priority_level') int get priorityLevel;@JsonKey(name: 'availability_hours') String get availabilityHours; String get specialization;@JsonKey(name: 'status') String get statusValue; String get notes;@JsonKey(name: 'district_id') String? get districtId;@JsonKey(name: 'district_name') String get districtName;@JsonKey(name: 'region_id') String? get regionId;@JsonKey(name: 'region_name') String get regionName;@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? get createdAt;@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? get updatedAt;
/// Create a copy of MinistryDirectory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MinistryDirectoryCopyWith<MinistryDirectory> get copyWith => _$MinistryDirectoryCopyWithImpl<MinistryDirectory>(this as MinistryDirectory, _$identity);

  /// Serializes this MinistryDirectory to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MinistryDirectory&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.title, title) || other.title == title)&&(identical(other.ministryValue, ministryValue) || other.ministryValue == ministryValue)&&(identical(other.department, department) || other.department == department)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.alternativePhone, alternativePhone) || other.alternativePhone == alternativePhone)&&(identical(other.email, email) || other.email == email)&&(identical(other.officeAddress, officeAddress) || other.officeAddress == officeAddress)&&(identical(other.priorityLevel, priorityLevel) || other.priorityLevel == priorityLevel)&&(identical(other.availabilityHours, availabilityHours) || other.availabilityHours == availabilityHours)&&(identical(other.specialization, specialization) || other.specialization == specialization)&&(identical(other.statusValue, statusValue) || other.statusValue == statusValue)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.districtId, districtId) || other.districtId == districtId)&&(identical(other.districtName, districtName) || other.districtName == districtName)&&(identical(other.regionId, regionId) || other.regionId == regionId)&&(identical(other.regionName, regionName) || other.regionName == regionName)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,name,title,ministryValue,department,phone,alternativePhone,email,officeAddress,priorityLevel,availabilityHours,specialization,statusValue,notes,districtId,districtName,regionId,regionName,createdAt,updatedAt]);

@override
String toString() {
  return 'MinistryDirectory(id: $id, name: $name, title: $title, ministryValue: $ministryValue, department: $department, phone: $phone, alternativePhone: $alternativePhone, email: $email, officeAddress: $officeAddress, priorityLevel: $priorityLevel, availabilityHours: $availabilityHours, specialization: $specialization, statusValue: $statusValue, notes: $notes, districtId: $districtId, districtName: $districtName, regionId: $regionId, regionName: $regionName, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $MinistryDirectoryCopyWith<$Res>  {
  factory $MinistryDirectoryCopyWith(MinistryDirectory value, $Res Function(MinistryDirectory) _then) = _$MinistryDirectoryCopyWithImpl;
@useResult
$Res call({
 String id, String name, String title,@JsonKey(name: 'ministry') String ministryValue, String department, String phone,@JsonKey(name: 'alternative_phone') String alternativePhone, String email,@JsonKey(name: 'office_address') String officeAddress,@JsonKey(name: 'priority_level') int priorityLevel,@JsonKey(name: 'availability_hours') String availabilityHours, String specialization,@JsonKey(name: 'status') String statusValue, String notes,@JsonKey(name: 'district_id') String? districtId,@JsonKey(name: 'district_name') String districtName,@JsonKey(name: 'region_id') String? regionId,@JsonKey(name: 'region_name') String regionName,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$MinistryDirectoryCopyWithImpl<$Res>
    implements $MinistryDirectoryCopyWith<$Res> {
  _$MinistryDirectoryCopyWithImpl(this._self, this._then);

  final MinistryDirectory _self;
  final $Res Function(MinistryDirectory) _then;

/// Create a copy of MinistryDirectory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? title = null,Object? ministryValue = null,Object? department = null,Object? phone = null,Object? alternativePhone = null,Object? email = null,Object? officeAddress = null,Object? priorityLevel = null,Object? availabilityHours = null,Object? specialization = null,Object? statusValue = null,Object? notes = null,Object? districtId = freezed,Object? districtName = null,Object? regionId = freezed,Object? regionName = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,ministryValue: null == ministryValue ? _self.ministryValue : ministryValue // ignore: cast_nullable_to_non_nullable
as String,department: null == department ? _self.department : department // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,alternativePhone: null == alternativePhone ? _self.alternativePhone : alternativePhone // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,officeAddress: null == officeAddress ? _self.officeAddress : officeAddress // ignore: cast_nullable_to_non_nullable
as String,priorityLevel: null == priorityLevel ? _self.priorityLevel : priorityLevel // ignore: cast_nullable_to_non_nullable
as int,availabilityHours: null == availabilityHours ? _self.availabilityHours : availabilityHours // ignore: cast_nullable_to_non_nullable
as String,specialization: null == specialization ? _self.specialization : specialization // ignore: cast_nullable_to_non_nullable
as String,statusValue: null == statusValue ? _self.statusValue : statusValue // ignore: cast_nullable_to_non_nullable
as String,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,districtId: freezed == districtId ? _self.districtId : districtId // ignore: cast_nullable_to_non_nullable
as String?,districtName: null == districtName ? _self.districtName : districtName // ignore: cast_nullable_to_non_nullable
as String,regionId: freezed == regionId ? _self.regionId : regionId // ignore: cast_nullable_to_non_nullable
as String?,regionName: null == regionName ? _self.regionName : regionName // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _MinistryDirectory extends MinistryDirectory {
  const _MinistryDirectory({required this.id, this.name = '', this.title = '', @JsonKey(name: 'ministry') this.ministryValue = '', this.department = '', this.phone = '', @JsonKey(name: 'alternative_phone') this.alternativePhone = '', this.email = '', @JsonKey(name: 'office_address') this.officeAddress = '', @JsonKey(name: 'priority_level') this.priorityLevel = 0, @JsonKey(name: 'availability_hours') this.availabilityHours = '', this.specialization = '', @JsonKey(name: 'status') this.statusValue = 'inactive', this.notes = '', @JsonKey(name: 'district_id') this.districtId, @JsonKey(name: 'district_name') this.districtName = '', @JsonKey(name: 'region_id') this.regionId, @JsonKey(name: 'region_name') this.regionName = '', @JsonKey(name: 'created_at')@NullableDateTimeConverter() this.createdAt, @JsonKey(name: 'updated_at')@NullableDateTimeConverter() this.updatedAt}): super._();
  factory _MinistryDirectory.fromJson(Map<String, dynamic> json) => _$MinistryDirectoryFromJson(json);

@override final  String id;
@override@JsonKey() final  String name;
@override@JsonKey() final  String title;
@override@JsonKey(name: 'ministry') final  String ministryValue;
@override@JsonKey() final  String department;
@override@JsonKey() final  String phone;
@override@JsonKey(name: 'alternative_phone') final  String alternativePhone;
@override@JsonKey() final  String email;
@override@JsonKey(name: 'office_address') final  String officeAddress;
@override@JsonKey(name: 'priority_level') final  int priorityLevel;
@override@JsonKey(name: 'availability_hours') final  String availabilityHours;
@override@JsonKey() final  String specialization;
@override@JsonKey(name: 'status') final  String statusValue;
@override@JsonKey() final  String notes;
@override@JsonKey(name: 'district_id') final  String? districtId;
@override@JsonKey(name: 'district_name') final  String districtName;
@override@JsonKey(name: 'region_id') final  String? regionId;
@override@JsonKey(name: 'region_name') final  String regionName;
@override@JsonKey(name: 'created_at')@NullableDateTimeConverter() final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at')@NullableDateTimeConverter() final  DateTime? updatedAt;

/// Create a copy of MinistryDirectory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MinistryDirectoryCopyWith<_MinistryDirectory> get copyWith => __$MinistryDirectoryCopyWithImpl<_MinistryDirectory>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MinistryDirectoryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MinistryDirectory&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.title, title) || other.title == title)&&(identical(other.ministryValue, ministryValue) || other.ministryValue == ministryValue)&&(identical(other.department, department) || other.department == department)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.alternativePhone, alternativePhone) || other.alternativePhone == alternativePhone)&&(identical(other.email, email) || other.email == email)&&(identical(other.officeAddress, officeAddress) || other.officeAddress == officeAddress)&&(identical(other.priorityLevel, priorityLevel) || other.priorityLevel == priorityLevel)&&(identical(other.availabilityHours, availabilityHours) || other.availabilityHours == availabilityHours)&&(identical(other.specialization, specialization) || other.specialization == specialization)&&(identical(other.statusValue, statusValue) || other.statusValue == statusValue)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.districtId, districtId) || other.districtId == districtId)&&(identical(other.districtName, districtName) || other.districtName == districtName)&&(identical(other.regionId, regionId) || other.regionId == regionId)&&(identical(other.regionName, regionName) || other.regionName == regionName)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,name,title,ministryValue,department,phone,alternativePhone,email,officeAddress,priorityLevel,availabilityHours,specialization,statusValue,notes,districtId,districtName,regionId,regionName,createdAt,updatedAt]);

@override
String toString() {
  return 'MinistryDirectory(id: $id, name: $name, title: $title, ministryValue: $ministryValue, department: $department, phone: $phone, alternativePhone: $alternativePhone, email: $email, officeAddress: $officeAddress, priorityLevel: $priorityLevel, availabilityHours: $availabilityHours, specialization: $specialization, statusValue: $statusValue, notes: $notes, districtId: $districtId, districtName: $districtName, regionId: $regionId, regionName: $regionName, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$MinistryDirectoryCopyWith<$Res> implements $MinistryDirectoryCopyWith<$Res> {
  factory _$MinistryDirectoryCopyWith(_MinistryDirectory value, $Res Function(_MinistryDirectory) _then) = __$MinistryDirectoryCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String title,@JsonKey(name: 'ministry') String ministryValue, String department, String phone,@JsonKey(name: 'alternative_phone') String alternativePhone, String email,@JsonKey(name: 'office_address') String officeAddress,@JsonKey(name: 'priority_level') int priorityLevel,@JsonKey(name: 'availability_hours') String availabilityHours, String specialization,@JsonKey(name: 'status') String statusValue, String notes,@JsonKey(name: 'district_id') String? districtId,@JsonKey(name: 'district_name') String districtName,@JsonKey(name: 'region_id') String? regionId,@JsonKey(name: 'region_name') String regionName,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$MinistryDirectoryCopyWithImpl<$Res>
    implements _$MinistryDirectoryCopyWith<$Res> {
  __$MinistryDirectoryCopyWithImpl(this._self, this._then);

  final _MinistryDirectory _self;
  final $Res Function(_MinistryDirectory) _then;

/// Create a copy of MinistryDirectory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? title = null,Object? ministryValue = null,Object? department = null,Object? phone = null,Object? alternativePhone = null,Object? email = null,Object? officeAddress = null,Object? priorityLevel = null,Object? availabilityHours = null,Object? specialization = null,Object? statusValue = null,Object? notes = null,Object? districtId = freezed,Object? districtName = null,Object? regionId = freezed,Object? regionName = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_MinistryDirectory(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,ministryValue: null == ministryValue ? _self.ministryValue : ministryValue // ignore: cast_nullable_to_non_nullable
as String,department: null == department ? _self.department : department // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,alternativePhone: null == alternativePhone ? _self.alternativePhone : alternativePhone // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,officeAddress: null == officeAddress ? _self.officeAddress : officeAddress // ignore: cast_nullable_to_non_nullable
as String,priorityLevel: null == priorityLevel ? _self.priorityLevel : priorityLevel // ignore: cast_nullable_to_non_nullable
as int,availabilityHours: null == availabilityHours ? _self.availabilityHours : availabilityHours // ignore: cast_nullable_to_non_nullable
as String,specialization: null == specialization ? _self.specialization : specialization // ignore: cast_nullable_to_non_nullable
as String,statusValue: null == statusValue ? _self.statusValue : statusValue // ignore: cast_nullable_to_non_nullable
as String,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,districtId: freezed == districtId ? _self.districtId : districtId // ignore: cast_nullable_to_non_nullable
as String?,districtName: null == districtName ? _self.districtName : districtName // ignore: cast_nullable_to_non_nullable
as String,regionId: freezed == regionId ? _self.regionId : regionId // ignore: cast_nullable_to_non_nullable
as String?,regionName: null == regionName ? _self.regionName : regionName // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$MinistryDirectoryRequest {

 String? get name; String? get title; String? get ministry; String? get department; String? get phone;@JsonKey(name: 'alternative_phone') String? get alternativePhone; String? get email;@JsonKey(name: 'office_address') String? get officeAddress;@JsonKey(name: 'priority_level') int? get priorityLevel;@JsonKey(name: 'availability_hours') String? get availabilityHours; String? get specialization; String? get status; String? get notes;@JsonKey(name: 'district_id') String? get districtId;@JsonKey(name: 'region_id') String? get regionId;
/// Create a copy of MinistryDirectoryRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MinistryDirectoryRequestCopyWith<MinistryDirectoryRequest> get copyWith => _$MinistryDirectoryRequestCopyWithImpl<MinistryDirectoryRequest>(this as MinistryDirectoryRequest, _$identity);

  /// Serializes this MinistryDirectoryRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MinistryDirectoryRequest&&(identical(other.name, name) || other.name == name)&&(identical(other.title, title) || other.title == title)&&(identical(other.ministry, ministry) || other.ministry == ministry)&&(identical(other.department, department) || other.department == department)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.alternativePhone, alternativePhone) || other.alternativePhone == alternativePhone)&&(identical(other.email, email) || other.email == email)&&(identical(other.officeAddress, officeAddress) || other.officeAddress == officeAddress)&&(identical(other.priorityLevel, priorityLevel) || other.priorityLevel == priorityLevel)&&(identical(other.availabilityHours, availabilityHours) || other.availabilityHours == availabilityHours)&&(identical(other.specialization, specialization) || other.specialization == specialization)&&(identical(other.status, status) || other.status == status)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.districtId, districtId) || other.districtId == districtId)&&(identical(other.regionId, regionId) || other.regionId == regionId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,title,ministry,department,phone,alternativePhone,email,officeAddress,priorityLevel,availabilityHours,specialization,status,notes,districtId,regionId);

@override
String toString() {
  return 'MinistryDirectoryRequest(name: $name, title: $title, ministry: $ministry, department: $department, phone: $phone, alternativePhone: $alternativePhone, email: $email, officeAddress: $officeAddress, priorityLevel: $priorityLevel, availabilityHours: $availabilityHours, specialization: $specialization, status: $status, notes: $notes, districtId: $districtId, regionId: $regionId)';
}


}

/// @nodoc
abstract mixin class $MinistryDirectoryRequestCopyWith<$Res>  {
  factory $MinistryDirectoryRequestCopyWith(MinistryDirectoryRequest value, $Res Function(MinistryDirectoryRequest) _then) = _$MinistryDirectoryRequestCopyWithImpl;
@useResult
$Res call({
 String? name, String? title, String? ministry, String? department, String? phone,@JsonKey(name: 'alternative_phone') String? alternativePhone, String? email,@JsonKey(name: 'office_address') String? officeAddress,@JsonKey(name: 'priority_level') int? priorityLevel,@JsonKey(name: 'availability_hours') String? availabilityHours, String? specialization, String? status, String? notes,@JsonKey(name: 'district_id') String? districtId,@JsonKey(name: 'region_id') String? regionId
});




}
/// @nodoc
class _$MinistryDirectoryRequestCopyWithImpl<$Res>
    implements $MinistryDirectoryRequestCopyWith<$Res> {
  _$MinistryDirectoryRequestCopyWithImpl(this._self, this._then);

  final MinistryDirectoryRequest _self;
  final $Res Function(MinistryDirectoryRequest) _then;

/// Create a copy of MinistryDirectoryRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = freezed,Object? title = freezed,Object? ministry = freezed,Object? department = freezed,Object? phone = freezed,Object? alternativePhone = freezed,Object? email = freezed,Object? officeAddress = freezed,Object? priorityLevel = freezed,Object? availabilityHours = freezed,Object? specialization = freezed,Object? status = freezed,Object? notes = freezed,Object? districtId = freezed,Object? regionId = freezed,}) {
  return _then(_self.copyWith(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,ministry: freezed == ministry ? _self.ministry : ministry // ignore: cast_nullable_to_non_nullable
as String?,department: freezed == department ? _self.department : department // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,alternativePhone: freezed == alternativePhone ? _self.alternativePhone : alternativePhone // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,officeAddress: freezed == officeAddress ? _self.officeAddress : officeAddress // ignore: cast_nullable_to_non_nullable
as String?,priorityLevel: freezed == priorityLevel ? _self.priorityLevel : priorityLevel // ignore: cast_nullable_to_non_nullable
as int?,availabilityHours: freezed == availabilityHours ? _self.availabilityHours : availabilityHours // ignore: cast_nullable_to_non_nullable
as String?,specialization: freezed == specialization ? _self.specialization : specialization // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,districtId: freezed == districtId ? _self.districtId : districtId // ignore: cast_nullable_to_non_nullable
as String?,regionId: freezed == regionId ? _self.regionId : regionId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc

@JsonSerializable(includeIfNull: false)
class _MinistryDirectoryRequest implements MinistryDirectoryRequest {
  const _MinistryDirectoryRequest({this.name, this.title, this.ministry, this.department, this.phone, @JsonKey(name: 'alternative_phone') this.alternativePhone, this.email, @JsonKey(name: 'office_address') this.officeAddress, @JsonKey(name: 'priority_level') this.priorityLevel, @JsonKey(name: 'availability_hours') this.availabilityHours, this.specialization, this.status, this.notes, @JsonKey(name: 'district_id') this.districtId, @JsonKey(name: 'region_id') this.regionId});
  factory _MinistryDirectoryRequest.fromJson(Map<String, dynamic> json) => _$MinistryDirectoryRequestFromJson(json);

@override final  String? name;
@override final  String? title;
@override final  String? ministry;
@override final  String? department;
@override final  String? phone;
@override@JsonKey(name: 'alternative_phone') final  String? alternativePhone;
@override final  String? email;
@override@JsonKey(name: 'office_address') final  String? officeAddress;
@override@JsonKey(name: 'priority_level') final  int? priorityLevel;
@override@JsonKey(name: 'availability_hours') final  String? availabilityHours;
@override final  String? specialization;
@override final  String? status;
@override final  String? notes;
@override@JsonKey(name: 'district_id') final  String? districtId;
@override@JsonKey(name: 'region_id') final  String? regionId;

/// Create a copy of MinistryDirectoryRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MinistryDirectoryRequestCopyWith<_MinistryDirectoryRequest> get copyWith => __$MinistryDirectoryRequestCopyWithImpl<_MinistryDirectoryRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MinistryDirectoryRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MinistryDirectoryRequest&&(identical(other.name, name) || other.name == name)&&(identical(other.title, title) || other.title == title)&&(identical(other.ministry, ministry) || other.ministry == ministry)&&(identical(other.department, department) || other.department == department)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.alternativePhone, alternativePhone) || other.alternativePhone == alternativePhone)&&(identical(other.email, email) || other.email == email)&&(identical(other.officeAddress, officeAddress) || other.officeAddress == officeAddress)&&(identical(other.priorityLevel, priorityLevel) || other.priorityLevel == priorityLevel)&&(identical(other.availabilityHours, availabilityHours) || other.availabilityHours == availabilityHours)&&(identical(other.specialization, specialization) || other.specialization == specialization)&&(identical(other.status, status) || other.status == status)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.districtId, districtId) || other.districtId == districtId)&&(identical(other.regionId, regionId) || other.regionId == regionId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,title,ministry,department,phone,alternativePhone,email,officeAddress,priorityLevel,availabilityHours,specialization,status,notes,districtId,regionId);

@override
String toString() {
  return 'MinistryDirectoryRequest(name: $name, title: $title, ministry: $ministry, department: $department, phone: $phone, alternativePhone: $alternativePhone, email: $email, officeAddress: $officeAddress, priorityLevel: $priorityLevel, availabilityHours: $availabilityHours, specialization: $specialization, status: $status, notes: $notes, districtId: $districtId, regionId: $regionId)';
}


}

/// @nodoc
abstract mixin class _$MinistryDirectoryRequestCopyWith<$Res> implements $MinistryDirectoryRequestCopyWith<$Res> {
  factory _$MinistryDirectoryRequestCopyWith(_MinistryDirectoryRequest value, $Res Function(_MinistryDirectoryRequest) _then) = __$MinistryDirectoryRequestCopyWithImpl;
@override @useResult
$Res call({
 String? name, String? title, String? ministry, String? department, String? phone,@JsonKey(name: 'alternative_phone') String? alternativePhone, String? email,@JsonKey(name: 'office_address') String? officeAddress,@JsonKey(name: 'priority_level') int? priorityLevel,@JsonKey(name: 'availability_hours') String? availabilityHours, String? specialization, String? status, String? notes,@JsonKey(name: 'district_id') String? districtId,@JsonKey(name: 'region_id') String? regionId
});




}
/// @nodoc
class __$MinistryDirectoryRequestCopyWithImpl<$Res>
    implements _$MinistryDirectoryRequestCopyWith<$Res> {
  __$MinistryDirectoryRequestCopyWithImpl(this._self, this._then);

  final _MinistryDirectoryRequest _self;
  final $Res Function(_MinistryDirectoryRequest) _then;

/// Create a copy of MinistryDirectoryRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = freezed,Object? title = freezed,Object? ministry = freezed,Object? department = freezed,Object? phone = freezed,Object? alternativePhone = freezed,Object? email = freezed,Object? officeAddress = freezed,Object? priorityLevel = freezed,Object? availabilityHours = freezed,Object? specialization = freezed,Object? status = freezed,Object? notes = freezed,Object? districtId = freezed,Object? regionId = freezed,}) {
  return _then(_MinistryDirectoryRequest(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,ministry: freezed == ministry ? _self.ministry : ministry // ignore: cast_nullable_to_non_nullable
as String?,department: freezed == department ? _self.department : department // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,alternativePhone: freezed == alternativePhone ? _self.alternativePhone : alternativePhone // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,officeAddress: freezed == officeAddress ? _self.officeAddress : officeAddress // ignore: cast_nullable_to_non_nullable
as String?,priorityLevel: freezed == priorityLevel ? _self.priorityLevel : priorityLevel // ignore: cast_nullable_to_non_nullable
as int?,availabilityHours: freezed == availabilityHours ? _self.availabilityHours : availabilityHours // ignore: cast_nullable_to_non_nullable
as String?,specialization: freezed == specialization ? _self.specialization : specialization // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,districtId: freezed == districtId ? _self.districtId : districtId // ignore: cast_nullable_to_non_nullable
as String?,regionId: freezed == regionId ? _self.regionId : regionId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
