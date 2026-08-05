// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$User {

 String get id; String get name; String get email;@JsonKey(name: 'email_visibility') bool get emailVisibility; bool get verified; String get phone;@JsonKey(name: 'alternative_phone') String get alternativePhone; String get address; String get city; String get state; String get country;@JsonKey(name: 'postal_code') String get postalCode;@JsonKey(name: 'license_number') String get licenseNumber; String get organization; String get department;@JsonKey(name: 'job_title') String get jobTitle; String get timezone; String get notes; String get avatar;@JsonKey(fromJson: _roleFromJson, toJson: _roleToJson) UserRole? get role;@JsonKey(fromJson: _statusFromJson, toJson: _statusToJson) UserStatus? get status; String get specialization;@JsonKey(name: 'preferred_language', fromJson: _languageFromJson, toJson: _languageToJson) PreferredLanguage? get preferredLanguage;@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? get createdAt;@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? get updatedAt;
/// Create a copy of User
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserCopyWith<User> get copyWith => _$UserCopyWithImpl<User>(this as User, _$identity);

  /// Serializes this User to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is User&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email)&&(identical(other.emailVisibility, emailVisibility) || other.emailVisibility == emailVisibility)&&(identical(other.verified, verified) || other.verified == verified)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.alternativePhone, alternativePhone) || other.alternativePhone == alternativePhone)&&(identical(other.address, address) || other.address == address)&&(identical(other.city, city) || other.city == city)&&(identical(other.state, state) || other.state == state)&&(identical(other.country, country) || other.country == country)&&(identical(other.postalCode, postalCode) || other.postalCode == postalCode)&&(identical(other.licenseNumber, licenseNumber) || other.licenseNumber == licenseNumber)&&(identical(other.organization, organization) || other.organization == organization)&&(identical(other.department, department) || other.department == department)&&(identical(other.jobTitle, jobTitle) || other.jobTitle == jobTitle)&&(identical(other.timezone, timezone) || other.timezone == timezone)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.avatar, avatar) || other.avatar == avatar)&&(identical(other.role, role) || other.role == role)&&(identical(other.status, status) || other.status == status)&&(identical(other.specialization, specialization) || other.specialization == specialization)&&(identical(other.preferredLanguage, preferredLanguage) || other.preferredLanguage == preferredLanguage)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,name,email,emailVisibility,verified,phone,alternativePhone,address,city,state,country,postalCode,licenseNumber,organization,department,jobTitle,timezone,notes,avatar,role,status,specialization,preferredLanguage,createdAt,updatedAt]);

@override
String toString() {
  return 'User(id: $id, name: $name, email: $email, emailVisibility: $emailVisibility, verified: $verified, phone: $phone, alternativePhone: $alternativePhone, address: $address, city: $city, state: $state, country: $country, postalCode: $postalCode, licenseNumber: $licenseNumber, organization: $organization, department: $department, jobTitle: $jobTitle, timezone: $timezone, notes: $notes, avatar: $avatar, role: $role, status: $status, specialization: $specialization, preferredLanguage: $preferredLanguage, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $UserCopyWith<$Res>  {
  factory $UserCopyWith(User value, $Res Function(User) _then) = _$UserCopyWithImpl;
@useResult
$Res call({
 String id, String name, String email,@JsonKey(name: 'email_visibility') bool emailVisibility, bool verified, String phone,@JsonKey(name: 'alternative_phone') String alternativePhone, String address, String city, String state, String country,@JsonKey(name: 'postal_code') String postalCode,@JsonKey(name: 'license_number') String licenseNumber, String organization, String department,@JsonKey(name: 'job_title') String jobTitle, String timezone, String notes, String avatar,@JsonKey(fromJson: _roleFromJson, toJson: _roleToJson) UserRole? role,@JsonKey(fromJson: _statusFromJson, toJson: _statusToJson) UserStatus? status, String specialization,@JsonKey(name: 'preferred_language', fromJson: _languageFromJson, toJson: _languageToJson) PreferredLanguage? preferredLanguage,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$UserCopyWithImpl<$Res>
    implements $UserCopyWith<$Res> {
  _$UserCopyWithImpl(this._self, this._then);

  final User _self;
  final $Res Function(User) _then;

/// Create a copy of User
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? email = null,Object? emailVisibility = null,Object? verified = null,Object? phone = null,Object? alternativePhone = null,Object? address = null,Object? city = null,Object? state = null,Object? country = null,Object? postalCode = null,Object? licenseNumber = null,Object? organization = null,Object? department = null,Object? jobTitle = null,Object? timezone = null,Object? notes = null,Object? avatar = null,Object? role = freezed,Object? status = freezed,Object? specialization = null,Object? preferredLanguage = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,emailVisibility: null == emailVisibility ? _self.emailVisibility : emailVisibility // ignore: cast_nullable_to_non_nullable
as bool,verified: null == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as bool,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,alternativePhone: null == alternativePhone ? _self.alternativePhone : alternativePhone // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,country: null == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String,postalCode: null == postalCode ? _self.postalCode : postalCode // ignore: cast_nullable_to_non_nullable
as String,licenseNumber: null == licenseNumber ? _self.licenseNumber : licenseNumber // ignore: cast_nullable_to_non_nullable
as String,organization: null == organization ? _self.organization : organization // ignore: cast_nullable_to_non_nullable
as String,department: null == department ? _self.department : department // ignore: cast_nullable_to_non_nullable
as String,jobTitle: null == jobTitle ? _self.jobTitle : jobTitle // ignore: cast_nullable_to_non_nullable
as String,timezone: null == timezone ? _self.timezone : timezone // ignore: cast_nullable_to_non_nullable
as String,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,avatar: null == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as String,role: freezed == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as UserRole?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as UserStatus?,specialization: null == specialization ? _self.specialization : specialization // ignore: cast_nullable_to_non_nullable
as String,preferredLanguage: freezed == preferredLanguage ? _self.preferredLanguage : preferredLanguage // ignore: cast_nullable_to_non_nullable
as PreferredLanguage?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _User extends User {
  const _User({required this.id, this.name = '', this.email = '', @JsonKey(name: 'email_visibility') this.emailVisibility = false, this.verified = false, this.phone = '', @JsonKey(name: 'alternative_phone') this.alternativePhone = '', this.address = '', this.city = '', this.state = '', this.country = '', @JsonKey(name: 'postal_code') this.postalCode = '', @JsonKey(name: 'license_number') this.licenseNumber = '', this.organization = '', this.department = '', @JsonKey(name: 'job_title') this.jobTitle = '', this.timezone = '', this.notes = '', this.avatar = '', @JsonKey(fromJson: _roleFromJson, toJson: _roleToJson) this.role, @JsonKey(fromJson: _statusFromJson, toJson: _statusToJson) this.status, this.specialization = '', @JsonKey(name: 'preferred_language', fromJson: _languageFromJson, toJson: _languageToJson) this.preferredLanguage, @JsonKey(name: 'created_at')@NullableDateTimeConverter() this.createdAt, @JsonKey(name: 'updated_at')@NullableDateTimeConverter() this.updatedAt}): super._();
  factory _User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

@override final  String id;
@override@JsonKey() final  String name;
@override@JsonKey() final  String email;
@override@JsonKey(name: 'email_visibility') final  bool emailVisibility;
@override@JsonKey() final  bool verified;
@override@JsonKey() final  String phone;
@override@JsonKey(name: 'alternative_phone') final  String alternativePhone;
@override@JsonKey() final  String address;
@override@JsonKey() final  String city;
@override@JsonKey() final  String state;
@override@JsonKey() final  String country;
@override@JsonKey(name: 'postal_code') final  String postalCode;
@override@JsonKey(name: 'license_number') final  String licenseNumber;
@override@JsonKey() final  String organization;
@override@JsonKey() final  String department;
@override@JsonKey(name: 'job_title') final  String jobTitle;
@override@JsonKey() final  String timezone;
@override@JsonKey() final  String notes;
@override@JsonKey() final  String avatar;
@override@JsonKey(fromJson: _roleFromJson, toJson: _roleToJson) final  UserRole? role;
@override@JsonKey(fromJson: _statusFromJson, toJson: _statusToJson) final  UserStatus? status;
@override@JsonKey() final  String specialization;
@override@JsonKey(name: 'preferred_language', fromJson: _languageFromJson, toJson: _languageToJson) final  PreferredLanguage? preferredLanguage;
@override@JsonKey(name: 'created_at')@NullableDateTimeConverter() final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at')@NullableDateTimeConverter() final  DateTime? updatedAt;

/// Create a copy of User
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserCopyWith<_User> get copyWith => __$UserCopyWithImpl<_User>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _User&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email)&&(identical(other.emailVisibility, emailVisibility) || other.emailVisibility == emailVisibility)&&(identical(other.verified, verified) || other.verified == verified)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.alternativePhone, alternativePhone) || other.alternativePhone == alternativePhone)&&(identical(other.address, address) || other.address == address)&&(identical(other.city, city) || other.city == city)&&(identical(other.state, state) || other.state == state)&&(identical(other.country, country) || other.country == country)&&(identical(other.postalCode, postalCode) || other.postalCode == postalCode)&&(identical(other.licenseNumber, licenseNumber) || other.licenseNumber == licenseNumber)&&(identical(other.organization, organization) || other.organization == organization)&&(identical(other.department, department) || other.department == department)&&(identical(other.jobTitle, jobTitle) || other.jobTitle == jobTitle)&&(identical(other.timezone, timezone) || other.timezone == timezone)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.avatar, avatar) || other.avatar == avatar)&&(identical(other.role, role) || other.role == role)&&(identical(other.status, status) || other.status == status)&&(identical(other.specialization, specialization) || other.specialization == specialization)&&(identical(other.preferredLanguage, preferredLanguage) || other.preferredLanguage == preferredLanguage)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,name,email,emailVisibility,verified,phone,alternativePhone,address,city,state,country,postalCode,licenseNumber,organization,department,jobTitle,timezone,notes,avatar,role,status,specialization,preferredLanguage,createdAt,updatedAt]);

@override
String toString() {
  return 'User(id: $id, name: $name, email: $email, emailVisibility: $emailVisibility, verified: $verified, phone: $phone, alternativePhone: $alternativePhone, address: $address, city: $city, state: $state, country: $country, postalCode: $postalCode, licenseNumber: $licenseNumber, organization: $organization, department: $department, jobTitle: $jobTitle, timezone: $timezone, notes: $notes, avatar: $avatar, role: $role, status: $status, specialization: $specialization, preferredLanguage: $preferredLanguage, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$UserCopyWith<$Res> implements $UserCopyWith<$Res> {
  factory _$UserCopyWith(_User value, $Res Function(_User) _then) = __$UserCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String email,@JsonKey(name: 'email_visibility') bool emailVisibility, bool verified, String phone,@JsonKey(name: 'alternative_phone') String alternativePhone, String address, String city, String state, String country,@JsonKey(name: 'postal_code') String postalCode,@JsonKey(name: 'license_number') String licenseNumber, String organization, String department,@JsonKey(name: 'job_title') String jobTitle, String timezone, String notes, String avatar,@JsonKey(fromJson: _roleFromJson, toJson: _roleToJson) UserRole? role,@JsonKey(fromJson: _statusFromJson, toJson: _statusToJson) UserStatus? status, String specialization,@JsonKey(name: 'preferred_language', fromJson: _languageFromJson, toJson: _languageToJson) PreferredLanguage? preferredLanguage,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$UserCopyWithImpl<$Res>
    implements _$UserCopyWith<$Res> {
  __$UserCopyWithImpl(this._self, this._then);

  final _User _self;
  final $Res Function(_User) _then;

/// Create a copy of User
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? email = null,Object? emailVisibility = null,Object? verified = null,Object? phone = null,Object? alternativePhone = null,Object? address = null,Object? city = null,Object? state = null,Object? country = null,Object? postalCode = null,Object? licenseNumber = null,Object? organization = null,Object? department = null,Object? jobTitle = null,Object? timezone = null,Object? notes = null,Object? avatar = null,Object? role = freezed,Object? status = freezed,Object? specialization = null,Object? preferredLanguage = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_User(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,emailVisibility: null == emailVisibility ? _self.emailVisibility : emailVisibility // ignore: cast_nullable_to_non_nullable
as bool,verified: null == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as bool,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,alternativePhone: null == alternativePhone ? _self.alternativePhone : alternativePhone // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,country: null == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String,postalCode: null == postalCode ? _self.postalCode : postalCode // ignore: cast_nullable_to_non_nullable
as String,licenseNumber: null == licenseNumber ? _self.licenseNumber : licenseNumber // ignore: cast_nullable_to_non_nullable
as String,organization: null == organization ? _self.organization : organization // ignore: cast_nullable_to_non_nullable
as String,department: null == department ? _self.department : department // ignore: cast_nullable_to_non_nullable
as String,jobTitle: null == jobTitle ? _self.jobTitle : jobTitle // ignore: cast_nullable_to_non_nullable
as String,timezone: null == timezone ? _self.timezone : timezone // ignore: cast_nullable_to_non_nullable
as String,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,avatar: null == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as String,role: freezed == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as UserRole?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as UserStatus?,specialization: null == specialization ? _self.specialization : specialization // ignore: cast_nullable_to_non_nullable
as String,preferredLanguage: freezed == preferredLanguage ? _self.preferredLanguage : preferredLanguage // ignore: cast_nullable_to_non_nullable
as PreferredLanguage?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$UserUpdateRequest {

 String? get name; String? get phone;@JsonKey(name: 'alternative_phone') String? get alternativePhone; String? get address; String? get city; String? get state; String? get country;@JsonKey(name: 'postal_code') String? get postalCode; String? get organization; String? get department;@JsonKey(name: 'job_title') String? get jobTitle; String? get specialization;@JsonKey(name: 'preferred_language') String? get preferredLanguage;
/// Create a copy of UserUpdateRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserUpdateRequestCopyWith<UserUpdateRequest> get copyWith => _$UserUpdateRequestCopyWithImpl<UserUpdateRequest>(this as UserUpdateRequest, _$identity);

  /// Serializes this UserUpdateRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserUpdateRequest&&(identical(other.name, name) || other.name == name)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.alternativePhone, alternativePhone) || other.alternativePhone == alternativePhone)&&(identical(other.address, address) || other.address == address)&&(identical(other.city, city) || other.city == city)&&(identical(other.state, state) || other.state == state)&&(identical(other.country, country) || other.country == country)&&(identical(other.postalCode, postalCode) || other.postalCode == postalCode)&&(identical(other.organization, organization) || other.organization == organization)&&(identical(other.department, department) || other.department == department)&&(identical(other.jobTitle, jobTitle) || other.jobTitle == jobTitle)&&(identical(other.specialization, specialization) || other.specialization == specialization)&&(identical(other.preferredLanguage, preferredLanguage) || other.preferredLanguage == preferredLanguage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,phone,alternativePhone,address,city,state,country,postalCode,organization,department,jobTitle,specialization,preferredLanguage);

@override
String toString() {
  return 'UserUpdateRequest(name: $name, phone: $phone, alternativePhone: $alternativePhone, address: $address, city: $city, state: $state, country: $country, postalCode: $postalCode, organization: $organization, department: $department, jobTitle: $jobTitle, specialization: $specialization, preferredLanguage: $preferredLanguage)';
}


}

/// @nodoc
abstract mixin class $UserUpdateRequestCopyWith<$Res>  {
  factory $UserUpdateRequestCopyWith(UserUpdateRequest value, $Res Function(UserUpdateRequest) _then) = _$UserUpdateRequestCopyWithImpl;
@useResult
$Res call({
 String? name, String? phone,@JsonKey(name: 'alternative_phone') String? alternativePhone, String? address, String? city, String? state, String? country,@JsonKey(name: 'postal_code') String? postalCode, String? organization, String? department,@JsonKey(name: 'job_title') String? jobTitle, String? specialization,@JsonKey(name: 'preferred_language') String? preferredLanguage
});




}
/// @nodoc
class _$UserUpdateRequestCopyWithImpl<$Res>
    implements $UserUpdateRequestCopyWith<$Res> {
  _$UserUpdateRequestCopyWithImpl(this._self, this._then);

  final UserUpdateRequest _self;
  final $Res Function(UserUpdateRequest) _then;

/// Create a copy of UserUpdateRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = freezed,Object? phone = freezed,Object? alternativePhone = freezed,Object? address = freezed,Object? city = freezed,Object? state = freezed,Object? country = freezed,Object? postalCode = freezed,Object? organization = freezed,Object? department = freezed,Object? jobTitle = freezed,Object? specialization = freezed,Object? preferredLanguage = freezed,}) {
  return _then(_self.copyWith(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,alternativePhone: freezed == alternativePhone ? _self.alternativePhone : alternativePhone // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,city: freezed == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String?,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String?,country: freezed == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String?,postalCode: freezed == postalCode ? _self.postalCode : postalCode // ignore: cast_nullable_to_non_nullable
as String?,organization: freezed == organization ? _self.organization : organization // ignore: cast_nullable_to_non_nullable
as String?,department: freezed == department ? _self.department : department // ignore: cast_nullable_to_non_nullable
as String?,jobTitle: freezed == jobTitle ? _self.jobTitle : jobTitle // ignore: cast_nullable_to_non_nullable
as String?,specialization: freezed == specialization ? _self.specialization : specialization // ignore: cast_nullable_to_non_nullable
as String?,preferredLanguage: freezed == preferredLanguage ? _self.preferredLanguage : preferredLanguage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc

@JsonSerializable(includeIfNull: false)
class _UserUpdateRequest implements UserUpdateRequest {
  const _UserUpdateRequest({this.name, this.phone, @JsonKey(name: 'alternative_phone') this.alternativePhone, this.address, this.city, this.state, this.country, @JsonKey(name: 'postal_code') this.postalCode, this.organization, this.department, @JsonKey(name: 'job_title') this.jobTitle, this.specialization, @JsonKey(name: 'preferred_language') this.preferredLanguage});
  factory _UserUpdateRequest.fromJson(Map<String, dynamic> json) => _$UserUpdateRequestFromJson(json);

@override final  String? name;
@override final  String? phone;
@override@JsonKey(name: 'alternative_phone') final  String? alternativePhone;
@override final  String? address;
@override final  String? city;
@override final  String? state;
@override final  String? country;
@override@JsonKey(name: 'postal_code') final  String? postalCode;
@override final  String? organization;
@override final  String? department;
@override@JsonKey(name: 'job_title') final  String? jobTitle;
@override final  String? specialization;
@override@JsonKey(name: 'preferred_language') final  String? preferredLanguage;

/// Create a copy of UserUpdateRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserUpdateRequestCopyWith<_UserUpdateRequest> get copyWith => __$UserUpdateRequestCopyWithImpl<_UserUpdateRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserUpdateRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserUpdateRequest&&(identical(other.name, name) || other.name == name)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.alternativePhone, alternativePhone) || other.alternativePhone == alternativePhone)&&(identical(other.address, address) || other.address == address)&&(identical(other.city, city) || other.city == city)&&(identical(other.state, state) || other.state == state)&&(identical(other.country, country) || other.country == country)&&(identical(other.postalCode, postalCode) || other.postalCode == postalCode)&&(identical(other.organization, organization) || other.organization == organization)&&(identical(other.department, department) || other.department == department)&&(identical(other.jobTitle, jobTitle) || other.jobTitle == jobTitle)&&(identical(other.specialization, specialization) || other.specialization == specialization)&&(identical(other.preferredLanguage, preferredLanguage) || other.preferredLanguage == preferredLanguage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,phone,alternativePhone,address,city,state,country,postalCode,organization,department,jobTitle,specialization,preferredLanguage);

@override
String toString() {
  return 'UserUpdateRequest(name: $name, phone: $phone, alternativePhone: $alternativePhone, address: $address, city: $city, state: $state, country: $country, postalCode: $postalCode, organization: $organization, department: $department, jobTitle: $jobTitle, specialization: $specialization, preferredLanguage: $preferredLanguage)';
}


}

/// @nodoc
abstract mixin class _$UserUpdateRequestCopyWith<$Res> implements $UserUpdateRequestCopyWith<$Res> {
  factory _$UserUpdateRequestCopyWith(_UserUpdateRequest value, $Res Function(_UserUpdateRequest) _then) = __$UserUpdateRequestCopyWithImpl;
@override @useResult
$Res call({
 String? name, String? phone,@JsonKey(name: 'alternative_phone') String? alternativePhone, String? address, String? city, String? state, String? country,@JsonKey(name: 'postal_code') String? postalCode, String? organization, String? department,@JsonKey(name: 'job_title') String? jobTitle, String? specialization,@JsonKey(name: 'preferred_language') String? preferredLanguage
});




}
/// @nodoc
class __$UserUpdateRequestCopyWithImpl<$Res>
    implements _$UserUpdateRequestCopyWith<$Res> {
  __$UserUpdateRequestCopyWithImpl(this._self, this._then);

  final _UserUpdateRequest _self;
  final $Res Function(_UserUpdateRequest) _then;

/// Create a copy of UserUpdateRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = freezed,Object? phone = freezed,Object? alternativePhone = freezed,Object? address = freezed,Object? city = freezed,Object? state = freezed,Object? country = freezed,Object? postalCode = freezed,Object? organization = freezed,Object? department = freezed,Object? jobTitle = freezed,Object? specialization = freezed,Object? preferredLanguage = freezed,}) {
  return _then(_UserUpdateRequest(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,alternativePhone: freezed == alternativePhone ? _self.alternativePhone : alternativePhone // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,city: freezed == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String?,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String?,country: freezed == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String?,postalCode: freezed == postalCode ? _self.postalCode : postalCode // ignore: cast_nullable_to_non_nullable
as String?,organization: freezed == organization ? _self.organization : organization // ignore: cast_nullable_to_non_nullable
as String?,department: freezed == department ? _self.department : department // ignore: cast_nullable_to_non_nullable
as String?,jobTitle: freezed == jobTitle ? _self.jobTitle : jobTitle // ignore: cast_nullable_to_non_nullable
as String?,specialization: freezed == specialization ? _self.specialization : specialization // ignore: cast_nullable_to_non_nullable
as String?,preferredLanguage: freezed == preferredLanguage ? _self.preferredLanguage : preferredLanguage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
