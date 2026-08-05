// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'consultant.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Consultant {

 String get id; String get name; String get email; String get phone;@JsonKey(name: 'alternative_phone') String get alternativePhone;@JsonKey(name: 'profile_picture') String get profilePicture; String get avatar;@JsonKey(name: 'specialty') String get specialtyValue;@JsonKey(name: 'license_number') String get licenseNumber;@JsonKey(name: 'years_of_experience') double get yearsOfExperience; List<String> get qualifications; String get certifications; String get address; String get city; String get region; String get country;@JsonKey(name: 'postal_code') String get postalCode; String get organization; String get department;@JsonKey(name: 'preferred_language') String get preferredLanguageValue; String get timezone; Map<String, dynamic> get availability;@JsonKey(name: 'consultation_types') List<String> get consultationTypeValues;@JsonKey(name: 'status') String get statusValue;@JsonKey(name: 'is_verified') bool get isVerified; double get rating;@JsonKey(name: 'total_consultations') int get totalConsultations; String get notes;@JsonKey(name: 'usage_count') int get usageCount;@JsonKey(name: 'user_id') String? get userId;@JsonKey(name: 'user') Map<String, dynamic>? get userData;@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? get createdAt;@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? get updatedAt;
/// Create a copy of Consultant
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConsultantCopyWith<Consultant> get copyWith => _$ConsultantCopyWithImpl<Consultant>(this as Consultant, _$identity);

  /// Serializes this Consultant to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Consultant&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.alternativePhone, alternativePhone) || other.alternativePhone == alternativePhone)&&(identical(other.profilePicture, profilePicture) || other.profilePicture == profilePicture)&&(identical(other.avatar, avatar) || other.avatar == avatar)&&(identical(other.specialtyValue, specialtyValue) || other.specialtyValue == specialtyValue)&&(identical(other.licenseNumber, licenseNumber) || other.licenseNumber == licenseNumber)&&(identical(other.yearsOfExperience, yearsOfExperience) || other.yearsOfExperience == yearsOfExperience)&&const DeepCollectionEquality().equals(other.qualifications, qualifications)&&(identical(other.certifications, certifications) || other.certifications == certifications)&&(identical(other.address, address) || other.address == address)&&(identical(other.city, city) || other.city == city)&&(identical(other.region, region) || other.region == region)&&(identical(other.country, country) || other.country == country)&&(identical(other.postalCode, postalCode) || other.postalCode == postalCode)&&(identical(other.organization, organization) || other.organization == organization)&&(identical(other.department, department) || other.department == department)&&(identical(other.preferredLanguageValue, preferredLanguageValue) || other.preferredLanguageValue == preferredLanguageValue)&&(identical(other.timezone, timezone) || other.timezone == timezone)&&const DeepCollectionEquality().equals(other.availability, availability)&&const DeepCollectionEquality().equals(other.consultationTypeValues, consultationTypeValues)&&(identical(other.statusValue, statusValue) || other.statusValue == statusValue)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.totalConsultations, totalConsultations) || other.totalConsultations == totalConsultations)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.usageCount, usageCount) || other.usageCount == usageCount)&&(identical(other.userId, userId) || other.userId == userId)&&const DeepCollectionEquality().equals(other.userData, userData)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,name,email,phone,alternativePhone,profilePicture,avatar,specialtyValue,licenseNumber,yearsOfExperience,const DeepCollectionEquality().hash(qualifications),certifications,address,city,region,country,postalCode,organization,department,preferredLanguageValue,timezone,const DeepCollectionEquality().hash(availability),const DeepCollectionEquality().hash(consultationTypeValues),statusValue,isVerified,rating,totalConsultations,notes,usageCount,userId,const DeepCollectionEquality().hash(userData),createdAt,updatedAt]);

@override
String toString() {
  return 'Consultant(id: $id, name: $name, email: $email, phone: $phone, alternativePhone: $alternativePhone, profilePicture: $profilePicture, avatar: $avatar, specialtyValue: $specialtyValue, licenseNumber: $licenseNumber, yearsOfExperience: $yearsOfExperience, qualifications: $qualifications, certifications: $certifications, address: $address, city: $city, region: $region, country: $country, postalCode: $postalCode, organization: $organization, department: $department, preferredLanguageValue: $preferredLanguageValue, timezone: $timezone, availability: $availability, consultationTypeValues: $consultationTypeValues, statusValue: $statusValue, isVerified: $isVerified, rating: $rating, totalConsultations: $totalConsultations, notes: $notes, usageCount: $usageCount, userId: $userId, userData: $userData, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $ConsultantCopyWith<$Res>  {
  factory $ConsultantCopyWith(Consultant value, $Res Function(Consultant) _then) = _$ConsultantCopyWithImpl;
@useResult
$Res call({
 String id, String name, String email, String phone,@JsonKey(name: 'alternative_phone') String alternativePhone,@JsonKey(name: 'profile_picture') String profilePicture, String avatar,@JsonKey(name: 'specialty') String specialtyValue,@JsonKey(name: 'license_number') String licenseNumber,@JsonKey(name: 'years_of_experience') double yearsOfExperience, List<String> qualifications, String certifications, String address, String city, String region, String country,@JsonKey(name: 'postal_code') String postalCode, String organization, String department,@JsonKey(name: 'preferred_language') String preferredLanguageValue, String timezone, Map<String, dynamic> availability,@JsonKey(name: 'consultation_types') List<String> consultationTypeValues,@JsonKey(name: 'status') String statusValue,@JsonKey(name: 'is_verified') bool isVerified, double rating,@JsonKey(name: 'total_consultations') int totalConsultations, String notes,@JsonKey(name: 'usage_count') int usageCount,@JsonKey(name: 'user_id') String? userId,@JsonKey(name: 'user') Map<String, dynamic>? userData,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$ConsultantCopyWithImpl<$Res>
    implements $ConsultantCopyWith<$Res> {
  _$ConsultantCopyWithImpl(this._self, this._then);

  final Consultant _self;
  final $Res Function(Consultant) _then;

/// Create a copy of Consultant
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? email = null,Object? phone = null,Object? alternativePhone = null,Object? profilePicture = null,Object? avatar = null,Object? specialtyValue = null,Object? licenseNumber = null,Object? yearsOfExperience = null,Object? qualifications = null,Object? certifications = null,Object? address = null,Object? city = null,Object? region = null,Object? country = null,Object? postalCode = null,Object? organization = null,Object? department = null,Object? preferredLanguageValue = null,Object? timezone = null,Object? availability = null,Object? consultationTypeValues = null,Object? statusValue = null,Object? isVerified = null,Object? rating = null,Object? totalConsultations = null,Object? notes = null,Object? usageCount = null,Object? userId = freezed,Object? userData = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,alternativePhone: null == alternativePhone ? _self.alternativePhone : alternativePhone // ignore: cast_nullable_to_non_nullable
as String,profilePicture: null == profilePicture ? _self.profilePicture : profilePicture // ignore: cast_nullable_to_non_nullable
as String,avatar: null == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as String,specialtyValue: null == specialtyValue ? _self.specialtyValue : specialtyValue // ignore: cast_nullable_to_non_nullable
as String,licenseNumber: null == licenseNumber ? _self.licenseNumber : licenseNumber // ignore: cast_nullable_to_non_nullable
as String,yearsOfExperience: null == yearsOfExperience ? _self.yearsOfExperience : yearsOfExperience // ignore: cast_nullable_to_non_nullable
as double,qualifications: null == qualifications ? _self.qualifications : qualifications // ignore: cast_nullable_to_non_nullable
as List<String>,certifications: null == certifications ? _self.certifications : certifications // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,region: null == region ? _self.region : region // ignore: cast_nullable_to_non_nullable
as String,country: null == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String,postalCode: null == postalCode ? _self.postalCode : postalCode // ignore: cast_nullable_to_non_nullable
as String,organization: null == organization ? _self.organization : organization // ignore: cast_nullable_to_non_nullable
as String,department: null == department ? _self.department : department // ignore: cast_nullable_to_non_nullable
as String,preferredLanguageValue: null == preferredLanguageValue ? _self.preferredLanguageValue : preferredLanguageValue // ignore: cast_nullable_to_non_nullable
as String,timezone: null == timezone ? _self.timezone : timezone // ignore: cast_nullable_to_non_nullable
as String,availability: null == availability ? _self.availability : availability // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,consultationTypeValues: null == consultationTypeValues ? _self.consultationTypeValues : consultationTypeValues // ignore: cast_nullable_to_non_nullable
as List<String>,statusValue: null == statusValue ? _self.statusValue : statusValue // ignore: cast_nullable_to_non_nullable
as String,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double,totalConsultations: null == totalConsultations ? _self.totalConsultations : totalConsultations // ignore: cast_nullable_to_non_nullable
as int,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,usageCount: null == usageCount ? _self.usageCount : usageCount // ignore: cast_nullable_to_non_nullable
as int,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,userData: freezed == userData ? _self.userData : userData // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// @nodoc

@JsonSerializable(explicitToJson: true)
class _Consultant extends Consultant {
  const _Consultant({required this.id, this.name = '', this.email = '', this.phone = '', @JsonKey(name: 'alternative_phone') this.alternativePhone = '', @JsonKey(name: 'profile_picture') this.profilePicture = '', this.avatar = '', @JsonKey(name: 'specialty') this.specialtyValue = '', @JsonKey(name: 'license_number') this.licenseNumber = '', @JsonKey(name: 'years_of_experience') this.yearsOfExperience = 0, final  List<String> qualifications = const [], this.certifications = '', this.address = '', this.city = '', this.region = '', this.country = '', @JsonKey(name: 'postal_code') this.postalCode = '', this.organization = '', this.department = '', @JsonKey(name: 'preferred_language') this.preferredLanguageValue = '', this.timezone = '', final  Map<String, dynamic> availability = const {}, @JsonKey(name: 'consultation_types') final  List<String> consultationTypeValues = const [], @JsonKey(name: 'status') this.statusValue = 'inactive', @JsonKey(name: 'is_verified') this.isVerified = false, this.rating = 0, @JsonKey(name: 'total_consultations') this.totalConsultations = 0, this.notes = '', @JsonKey(name: 'usage_count') this.usageCount = 0, @JsonKey(name: 'user_id') this.userId, @JsonKey(name: 'user') final  Map<String, dynamic>? userData, @JsonKey(name: 'created_at')@NullableDateTimeConverter() this.createdAt, @JsonKey(name: 'updated_at')@NullableDateTimeConverter() this.updatedAt}): _qualifications = qualifications,_availability = availability,_consultationTypeValues = consultationTypeValues,_userData = userData,super._();
  factory _Consultant.fromJson(Map<String, dynamic> json) => _$ConsultantFromJson(json);

@override final  String id;
@override@JsonKey() final  String name;
@override@JsonKey() final  String email;
@override@JsonKey() final  String phone;
@override@JsonKey(name: 'alternative_phone') final  String alternativePhone;
@override@JsonKey(name: 'profile_picture') final  String profilePicture;
@override@JsonKey() final  String avatar;
@override@JsonKey(name: 'specialty') final  String specialtyValue;
@override@JsonKey(name: 'license_number') final  String licenseNumber;
@override@JsonKey(name: 'years_of_experience') final  double yearsOfExperience;
 final  List<String> _qualifications;
@override@JsonKey() List<String> get qualifications {
  if (_qualifications is EqualUnmodifiableListView) return _qualifications;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_qualifications);
}

@override@JsonKey() final  String certifications;
@override@JsonKey() final  String address;
@override@JsonKey() final  String city;
@override@JsonKey() final  String region;
@override@JsonKey() final  String country;
@override@JsonKey(name: 'postal_code') final  String postalCode;
@override@JsonKey() final  String organization;
@override@JsonKey() final  String department;
@override@JsonKey(name: 'preferred_language') final  String preferredLanguageValue;
@override@JsonKey() final  String timezone;
 final  Map<String, dynamic> _availability;
@override@JsonKey() Map<String, dynamic> get availability {
  if (_availability is EqualUnmodifiableMapView) return _availability;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_availability);
}

 final  List<String> _consultationTypeValues;
@override@JsonKey(name: 'consultation_types') List<String> get consultationTypeValues {
  if (_consultationTypeValues is EqualUnmodifiableListView) return _consultationTypeValues;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_consultationTypeValues);
}

@override@JsonKey(name: 'status') final  String statusValue;
@override@JsonKey(name: 'is_verified') final  bool isVerified;
@override@JsonKey() final  double rating;
@override@JsonKey(name: 'total_consultations') final  int totalConsultations;
@override@JsonKey() final  String notes;
@override@JsonKey(name: 'usage_count') final  int usageCount;
@override@JsonKey(name: 'user_id') final  String? userId;
 final  Map<String, dynamic>? _userData;
@override@JsonKey(name: 'user') Map<String, dynamic>? get userData {
  final value = _userData;
  if (value == null) return null;
  if (_userData is EqualUnmodifiableMapView) return _userData;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override@JsonKey(name: 'created_at')@NullableDateTimeConverter() final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at')@NullableDateTimeConverter() final  DateTime? updatedAt;

/// Create a copy of Consultant
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConsultantCopyWith<_Consultant> get copyWith => __$ConsultantCopyWithImpl<_Consultant>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ConsultantToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Consultant&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.alternativePhone, alternativePhone) || other.alternativePhone == alternativePhone)&&(identical(other.profilePicture, profilePicture) || other.profilePicture == profilePicture)&&(identical(other.avatar, avatar) || other.avatar == avatar)&&(identical(other.specialtyValue, specialtyValue) || other.specialtyValue == specialtyValue)&&(identical(other.licenseNumber, licenseNumber) || other.licenseNumber == licenseNumber)&&(identical(other.yearsOfExperience, yearsOfExperience) || other.yearsOfExperience == yearsOfExperience)&&const DeepCollectionEquality().equals(other._qualifications, _qualifications)&&(identical(other.certifications, certifications) || other.certifications == certifications)&&(identical(other.address, address) || other.address == address)&&(identical(other.city, city) || other.city == city)&&(identical(other.region, region) || other.region == region)&&(identical(other.country, country) || other.country == country)&&(identical(other.postalCode, postalCode) || other.postalCode == postalCode)&&(identical(other.organization, organization) || other.organization == organization)&&(identical(other.department, department) || other.department == department)&&(identical(other.preferredLanguageValue, preferredLanguageValue) || other.preferredLanguageValue == preferredLanguageValue)&&(identical(other.timezone, timezone) || other.timezone == timezone)&&const DeepCollectionEquality().equals(other._availability, _availability)&&const DeepCollectionEquality().equals(other._consultationTypeValues, _consultationTypeValues)&&(identical(other.statusValue, statusValue) || other.statusValue == statusValue)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.totalConsultations, totalConsultations) || other.totalConsultations == totalConsultations)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.usageCount, usageCount) || other.usageCount == usageCount)&&(identical(other.userId, userId) || other.userId == userId)&&const DeepCollectionEquality().equals(other._userData, _userData)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,name,email,phone,alternativePhone,profilePicture,avatar,specialtyValue,licenseNumber,yearsOfExperience,const DeepCollectionEquality().hash(_qualifications),certifications,address,city,region,country,postalCode,organization,department,preferredLanguageValue,timezone,const DeepCollectionEquality().hash(_availability),const DeepCollectionEquality().hash(_consultationTypeValues),statusValue,isVerified,rating,totalConsultations,notes,usageCount,userId,const DeepCollectionEquality().hash(_userData),createdAt,updatedAt]);

@override
String toString() {
  return 'Consultant(id: $id, name: $name, email: $email, phone: $phone, alternativePhone: $alternativePhone, profilePicture: $profilePicture, avatar: $avatar, specialtyValue: $specialtyValue, licenseNumber: $licenseNumber, yearsOfExperience: $yearsOfExperience, qualifications: $qualifications, certifications: $certifications, address: $address, city: $city, region: $region, country: $country, postalCode: $postalCode, organization: $organization, department: $department, preferredLanguageValue: $preferredLanguageValue, timezone: $timezone, availability: $availability, consultationTypeValues: $consultationTypeValues, statusValue: $statusValue, isVerified: $isVerified, rating: $rating, totalConsultations: $totalConsultations, notes: $notes, usageCount: $usageCount, userId: $userId, userData: $userData, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ConsultantCopyWith<$Res> implements $ConsultantCopyWith<$Res> {
  factory _$ConsultantCopyWith(_Consultant value, $Res Function(_Consultant) _then) = __$ConsultantCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String email, String phone,@JsonKey(name: 'alternative_phone') String alternativePhone,@JsonKey(name: 'profile_picture') String profilePicture, String avatar,@JsonKey(name: 'specialty') String specialtyValue,@JsonKey(name: 'license_number') String licenseNumber,@JsonKey(name: 'years_of_experience') double yearsOfExperience, List<String> qualifications, String certifications, String address, String city, String region, String country,@JsonKey(name: 'postal_code') String postalCode, String organization, String department,@JsonKey(name: 'preferred_language') String preferredLanguageValue, String timezone, Map<String, dynamic> availability,@JsonKey(name: 'consultation_types') List<String> consultationTypeValues,@JsonKey(name: 'status') String statusValue,@JsonKey(name: 'is_verified') bool isVerified, double rating,@JsonKey(name: 'total_consultations') int totalConsultations, String notes,@JsonKey(name: 'usage_count') int usageCount,@JsonKey(name: 'user_id') String? userId,@JsonKey(name: 'user') Map<String, dynamic>? userData,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$ConsultantCopyWithImpl<$Res>
    implements _$ConsultantCopyWith<$Res> {
  __$ConsultantCopyWithImpl(this._self, this._then);

  final _Consultant _self;
  final $Res Function(_Consultant) _then;

/// Create a copy of Consultant
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? email = null,Object? phone = null,Object? alternativePhone = null,Object? profilePicture = null,Object? avatar = null,Object? specialtyValue = null,Object? licenseNumber = null,Object? yearsOfExperience = null,Object? qualifications = null,Object? certifications = null,Object? address = null,Object? city = null,Object? region = null,Object? country = null,Object? postalCode = null,Object? organization = null,Object? department = null,Object? preferredLanguageValue = null,Object? timezone = null,Object? availability = null,Object? consultationTypeValues = null,Object? statusValue = null,Object? isVerified = null,Object? rating = null,Object? totalConsultations = null,Object? notes = null,Object? usageCount = null,Object? userId = freezed,Object? userData = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_Consultant(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,alternativePhone: null == alternativePhone ? _self.alternativePhone : alternativePhone // ignore: cast_nullable_to_non_nullable
as String,profilePicture: null == profilePicture ? _self.profilePicture : profilePicture // ignore: cast_nullable_to_non_nullable
as String,avatar: null == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as String,specialtyValue: null == specialtyValue ? _self.specialtyValue : specialtyValue // ignore: cast_nullable_to_non_nullable
as String,licenseNumber: null == licenseNumber ? _self.licenseNumber : licenseNumber // ignore: cast_nullable_to_non_nullable
as String,yearsOfExperience: null == yearsOfExperience ? _self.yearsOfExperience : yearsOfExperience // ignore: cast_nullable_to_non_nullable
as double,qualifications: null == qualifications ? _self._qualifications : qualifications // ignore: cast_nullable_to_non_nullable
as List<String>,certifications: null == certifications ? _self.certifications : certifications // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,region: null == region ? _self.region : region // ignore: cast_nullable_to_non_nullable
as String,country: null == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String,postalCode: null == postalCode ? _self.postalCode : postalCode // ignore: cast_nullable_to_non_nullable
as String,organization: null == organization ? _self.organization : organization // ignore: cast_nullable_to_non_nullable
as String,department: null == department ? _self.department : department // ignore: cast_nullable_to_non_nullable
as String,preferredLanguageValue: null == preferredLanguageValue ? _self.preferredLanguageValue : preferredLanguageValue // ignore: cast_nullable_to_non_nullable
as String,timezone: null == timezone ? _self.timezone : timezone // ignore: cast_nullable_to_non_nullable
as String,availability: null == availability ? _self._availability : availability // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,consultationTypeValues: null == consultationTypeValues ? _self._consultationTypeValues : consultationTypeValues // ignore: cast_nullable_to_non_nullable
as List<String>,statusValue: null == statusValue ? _self.statusValue : statusValue // ignore: cast_nullable_to_non_nullable
as String,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double,totalConsultations: null == totalConsultations ? _self.totalConsultations : totalConsultations // ignore: cast_nullable_to_non_nullable
as int,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,usageCount: null == usageCount ? _self.usageCount : usageCount // ignore: cast_nullable_to_non_nullable
as int,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,userData: freezed == userData ? _self._userData : userData // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$ConsultantRequest {

@JsonKey(name: 'user_id') String? get userId; String? get name; String? get email; String? get phone;@JsonKey(name: 'alternative_phone') String? get alternativePhone; String? get specialty;@JsonKey(name: 'license_number') String? get licenseNumber;@JsonKey(name: 'years_of_experience') double? get yearsOfExperience; List<String>? get qualifications; String? get certifications; String? get address; String? get city; String? get region; String? get country;@JsonKey(name: 'postal_code') String? get postalCode; String? get organization; String? get department;@JsonKey(name: 'preferred_language') String? get preferredLanguage; String? get timezone; Map<String, dynamic>? get availability;@JsonKey(name: 'consultation_types') List<String>? get consultationTypes; String? get status;@JsonKey(name: 'is_verified') bool? get isVerified; double? get rating;@JsonKey(name: 'total_consultations') int? get totalConsultations; String? get notes;
/// Create a copy of ConsultantRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConsultantRequestCopyWith<ConsultantRequest> get copyWith => _$ConsultantRequestCopyWithImpl<ConsultantRequest>(this as ConsultantRequest, _$identity);

  /// Serializes this ConsultantRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConsultantRequest&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.alternativePhone, alternativePhone) || other.alternativePhone == alternativePhone)&&(identical(other.specialty, specialty) || other.specialty == specialty)&&(identical(other.licenseNumber, licenseNumber) || other.licenseNumber == licenseNumber)&&(identical(other.yearsOfExperience, yearsOfExperience) || other.yearsOfExperience == yearsOfExperience)&&const DeepCollectionEquality().equals(other.qualifications, qualifications)&&(identical(other.certifications, certifications) || other.certifications == certifications)&&(identical(other.address, address) || other.address == address)&&(identical(other.city, city) || other.city == city)&&(identical(other.region, region) || other.region == region)&&(identical(other.country, country) || other.country == country)&&(identical(other.postalCode, postalCode) || other.postalCode == postalCode)&&(identical(other.organization, organization) || other.organization == organization)&&(identical(other.department, department) || other.department == department)&&(identical(other.preferredLanguage, preferredLanguage) || other.preferredLanguage == preferredLanguage)&&(identical(other.timezone, timezone) || other.timezone == timezone)&&const DeepCollectionEquality().equals(other.availability, availability)&&const DeepCollectionEquality().equals(other.consultationTypes, consultationTypes)&&(identical(other.status, status) || other.status == status)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.totalConsultations, totalConsultations) || other.totalConsultations == totalConsultations)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,userId,name,email,phone,alternativePhone,specialty,licenseNumber,yearsOfExperience,const DeepCollectionEquality().hash(qualifications),certifications,address,city,region,country,postalCode,organization,department,preferredLanguage,timezone,const DeepCollectionEquality().hash(availability),const DeepCollectionEquality().hash(consultationTypes),status,isVerified,rating,totalConsultations,notes]);

@override
String toString() {
  return 'ConsultantRequest(userId: $userId, name: $name, email: $email, phone: $phone, alternativePhone: $alternativePhone, specialty: $specialty, licenseNumber: $licenseNumber, yearsOfExperience: $yearsOfExperience, qualifications: $qualifications, certifications: $certifications, address: $address, city: $city, region: $region, country: $country, postalCode: $postalCode, organization: $organization, department: $department, preferredLanguage: $preferredLanguage, timezone: $timezone, availability: $availability, consultationTypes: $consultationTypes, status: $status, isVerified: $isVerified, rating: $rating, totalConsultations: $totalConsultations, notes: $notes)';
}


}

/// @nodoc
abstract mixin class $ConsultantRequestCopyWith<$Res>  {
  factory $ConsultantRequestCopyWith(ConsultantRequest value, $Res Function(ConsultantRequest) _then) = _$ConsultantRequestCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'user_id') String? userId, String? name, String? email, String? phone,@JsonKey(name: 'alternative_phone') String? alternativePhone, String? specialty,@JsonKey(name: 'license_number') String? licenseNumber,@JsonKey(name: 'years_of_experience') double? yearsOfExperience, List<String>? qualifications, String? certifications, String? address, String? city, String? region, String? country,@JsonKey(name: 'postal_code') String? postalCode, String? organization, String? department,@JsonKey(name: 'preferred_language') String? preferredLanguage, String? timezone, Map<String, dynamic>? availability,@JsonKey(name: 'consultation_types') List<String>? consultationTypes, String? status,@JsonKey(name: 'is_verified') bool? isVerified, double? rating,@JsonKey(name: 'total_consultations') int? totalConsultations, String? notes
});




}
/// @nodoc
class _$ConsultantRequestCopyWithImpl<$Res>
    implements $ConsultantRequestCopyWith<$Res> {
  _$ConsultantRequestCopyWithImpl(this._self, this._then);

  final ConsultantRequest _self;
  final $Res Function(ConsultantRequest) _then;

/// Create a copy of ConsultantRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = freezed,Object? name = freezed,Object? email = freezed,Object? phone = freezed,Object? alternativePhone = freezed,Object? specialty = freezed,Object? licenseNumber = freezed,Object? yearsOfExperience = freezed,Object? qualifications = freezed,Object? certifications = freezed,Object? address = freezed,Object? city = freezed,Object? region = freezed,Object? country = freezed,Object? postalCode = freezed,Object? organization = freezed,Object? department = freezed,Object? preferredLanguage = freezed,Object? timezone = freezed,Object? availability = freezed,Object? consultationTypes = freezed,Object? status = freezed,Object? isVerified = freezed,Object? rating = freezed,Object? totalConsultations = freezed,Object? notes = freezed,}) {
  return _then(_self.copyWith(
userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,alternativePhone: freezed == alternativePhone ? _self.alternativePhone : alternativePhone // ignore: cast_nullable_to_non_nullable
as String?,specialty: freezed == specialty ? _self.specialty : specialty // ignore: cast_nullable_to_non_nullable
as String?,licenseNumber: freezed == licenseNumber ? _self.licenseNumber : licenseNumber // ignore: cast_nullable_to_non_nullable
as String?,yearsOfExperience: freezed == yearsOfExperience ? _self.yearsOfExperience : yearsOfExperience // ignore: cast_nullable_to_non_nullable
as double?,qualifications: freezed == qualifications ? _self.qualifications : qualifications // ignore: cast_nullable_to_non_nullable
as List<String>?,certifications: freezed == certifications ? _self.certifications : certifications // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,city: freezed == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String?,region: freezed == region ? _self.region : region // ignore: cast_nullable_to_non_nullable
as String?,country: freezed == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String?,postalCode: freezed == postalCode ? _self.postalCode : postalCode // ignore: cast_nullable_to_non_nullable
as String?,organization: freezed == organization ? _self.organization : organization // ignore: cast_nullable_to_non_nullable
as String?,department: freezed == department ? _self.department : department // ignore: cast_nullable_to_non_nullable
as String?,preferredLanguage: freezed == preferredLanguage ? _self.preferredLanguage : preferredLanguage // ignore: cast_nullable_to_non_nullable
as String?,timezone: freezed == timezone ? _self.timezone : timezone // ignore: cast_nullable_to_non_nullable
as String?,availability: freezed == availability ? _self.availability : availability // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,consultationTypes: freezed == consultationTypes ? _self.consultationTypes : consultationTypes // ignore: cast_nullable_to_non_nullable
as List<String>?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,isVerified: freezed == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool?,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,totalConsultations: freezed == totalConsultations ? _self.totalConsultations : totalConsultations // ignore: cast_nullable_to_non_nullable
as int?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc

@JsonSerializable(includeIfNull: false)
class _ConsultantRequest implements ConsultantRequest {
  const _ConsultantRequest({@JsonKey(name: 'user_id') this.userId, this.name, this.email, this.phone, @JsonKey(name: 'alternative_phone') this.alternativePhone, this.specialty, @JsonKey(name: 'license_number') this.licenseNumber, @JsonKey(name: 'years_of_experience') this.yearsOfExperience, final  List<String>? qualifications, this.certifications, this.address, this.city, this.region, this.country, @JsonKey(name: 'postal_code') this.postalCode, this.organization, this.department, @JsonKey(name: 'preferred_language') this.preferredLanguage, this.timezone, final  Map<String, dynamic>? availability, @JsonKey(name: 'consultation_types') final  List<String>? consultationTypes, this.status, @JsonKey(name: 'is_verified') this.isVerified, this.rating, @JsonKey(name: 'total_consultations') this.totalConsultations, this.notes}): _qualifications = qualifications,_availability = availability,_consultationTypes = consultationTypes;
  factory _ConsultantRequest.fromJson(Map<String, dynamic> json) => _$ConsultantRequestFromJson(json);

@override@JsonKey(name: 'user_id') final  String? userId;
@override final  String? name;
@override final  String? email;
@override final  String? phone;
@override@JsonKey(name: 'alternative_phone') final  String? alternativePhone;
@override final  String? specialty;
@override@JsonKey(name: 'license_number') final  String? licenseNumber;
@override@JsonKey(name: 'years_of_experience') final  double? yearsOfExperience;
 final  List<String>? _qualifications;
@override List<String>? get qualifications {
  final value = _qualifications;
  if (value == null) return null;
  if (_qualifications is EqualUnmodifiableListView) return _qualifications;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  String? certifications;
@override final  String? address;
@override final  String? city;
@override final  String? region;
@override final  String? country;
@override@JsonKey(name: 'postal_code') final  String? postalCode;
@override final  String? organization;
@override final  String? department;
@override@JsonKey(name: 'preferred_language') final  String? preferredLanguage;
@override final  String? timezone;
 final  Map<String, dynamic>? _availability;
@override Map<String, dynamic>? get availability {
  final value = _availability;
  if (value == null) return null;
  if (_availability is EqualUnmodifiableMapView) return _availability;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

 final  List<String>? _consultationTypes;
@override@JsonKey(name: 'consultation_types') List<String>? get consultationTypes {
  final value = _consultationTypes;
  if (value == null) return null;
  if (_consultationTypes is EqualUnmodifiableListView) return _consultationTypes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  String? status;
@override@JsonKey(name: 'is_verified') final  bool? isVerified;
@override final  double? rating;
@override@JsonKey(name: 'total_consultations') final  int? totalConsultations;
@override final  String? notes;

/// Create a copy of ConsultantRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConsultantRequestCopyWith<_ConsultantRequest> get copyWith => __$ConsultantRequestCopyWithImpl<_ConsultantRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ConsultantRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConsultantRequest&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.alternativePhone, alternativePhone) || other.alternativePhone == alternativePhone)&&(identical(other.specialty, specialty) || other.specialty == specialty)&&(identical(other.licenseNumber, licenseNumber) || other.licenseNumber == licenseNumber)&&(identical(other.yearsOfExperience, yearsOfExperience) || other.yearsOfExperience == yearsOfExperience)&&const DeepCollectionEquality().equals(other._qualifications, _qualifications)&&(identical(other.certifications, certifications) || other.certifications == certifications)&&(identical(other.address, address) || other.address == address)&&(identical(other.city, city) || other.city == city)&&(identical(other.region, region) || other.region == region)&&(identical(other.country, country) || other.country == country)&&(identical(other.postalCode, postalCode) || other.postalCode == postalCode)&&(identical(other.organization, organization) || other.organization == organization)&&(identical(other.department, department) || other.department == department)&&(identical(other.preferredLanguage, preferredLanguage) || other.preferredLanguage == preferredLanguage)&&(identical(other.timezone, timezone) || other.timezone == timezone)&&const DeepCollectionEquality().equals(other._availability, _availability)&&const DeepCollectionEquality().equals(other._consultationTypes, _consultationTypes)&&(identical(other.status, status) || other.status == status)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.totalConsultations, totalConsultations) || other.totalConsultations == totalConsultations)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,userId,name,email,phone,alternativePhone,specialty,licenseNumber,yearsOfExperience,const DeepCollectionEquality().hash(_qualifications),certifications,address,city,region,country,postalCode,organization,department,preferredLanguage,timezone,const DeepCollectionEquality().hash(_availability),const DeepCollectionEquality().hash(_consultationTypes),status,isVerified,rating,totalConsultations,notes]);

@override
String toString() {
  return 'ConsultantRequest(userId: $userId, name: $name, email: $email, phone: $phone, alternativePhone: $alternativePhone, specialty: $specialty, licenseNumber: $licenseNumber, yearsOfExperience: $yearsOfExperience, qualifications: $qualifications, certifications: $certifications, address: $address, city: $city, region: $region, country: $country, postalCode: $postalCode, organization: $organization, department: $department, preferredLanguage: $preferredLanguage, timezone: $timezone, availability: $availability, consultationTypes: $consultationTypes, status: $status, isVerified: $isVerified, rating: $rating, totalConsultations: $totalConsultations, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$ConsultantRequestCopyWith<$Res> implements $ConsultantRequestCopyWith<$Res> {
  factory _$ConsultantRequestCopyWith(_ConsultantRequest value, $Res Function(_ConsultantRequest) _then) = __$ConsultantRequestCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'user_id') String? userId, String? name, String? email, String? phone,@JsonKey(name: 'alternative_phone') String? alternativePhone, String? specialty,@JsonKey(name: 'license_number') String? licenseNumber,@JsonKey(name: 'years_of_experience') double? yearsOfExperience, List<String>? qualifications, String? certifications, String? address, String? city, String? region, String? country,@JsonKey(name: 'postal_code') String? postalCode, String? organization, String? department,@JsonKey(name: 'preferred_language') String? preferredLanguage, String? timezone, Map<String, dynamic>? availability,@JsonKey(name: 'consultation_types') List<String>? consultationTypes, String? status,@JsonKey(name: 'is_verified') bool? isVerified, double? rating,@JsonKey(name: 'total_consultations') int? totalConsultations, String? notes
});




}
/// @nodoc
class __$ConsultantRequestCopyWithImpl<$Res>
    implements _$ConsultantRequestCopyWith<$Res> {
  __$ConsultantRequestCopyWithImpl(this._self, this._then);

  final _ConsultantRequest _self;
  final $Res Function(_ConsultantRequest) _then;

/// Create a copy of ConsultantRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = freezed,Object? name = freezed,Object? email = freezed,Object? phone = freezed,Object? alternativePhone = freezed,Object? specialty = freezed,Object? licenseNumber = freezed,Object? yearsOfExperience = freezed,Object? qualifications = freezed,Object? certifications = freezed,Object? address = freezed,Object? city = freezed,Object? region = freezed,Object? country = freezed,Object? postalCode = freezed,Object? organization = freezed,Object? department = freezed,Object? preferredLanguage = freezed,Object? timezone = freezed,Object? availability = freezed,Object? consultationTypes = freezed,Object? status = freezed,Object? isVerified = freezed,Object? rating = freezed,Object? totalConsultations = freezed,Object? notes = freezed,}) {
  return _then(_ConsultantRequest(
userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,alternativePhone: freezed == alternativePhone ? _self.alternativePhone : alternativePhone // ignore: cast_nullable_to_non_nullable
as String?,specialty: freezed == specialty ? _self.specialty : specialty // ignore: cast_nullable_to_non_nullable
as String?,licenseNumber: freezed == licenseNumber ? _self.licenseNumber : licenseNumber // ignore: cast_nullable_to_non_nullable
as String?,yearsOfExperience: freezed == yearsOfExperience ? _self.yearsOfExperience : yearsOfExperience // ignore: cast_nullable_to_non_nullable
as double?,qualifications: freezed == qualifications ? _self._qualifications : qualifications // ignore: cast_nullable_to_non_nullable
as List<String>?,certifications: freezed == certifications ? _self.certifications : certifications // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,city: freezed == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String?,region: freezed == region ? _self.region : region // ignore: cast_nullable_to_non_nullable
as String?,country: freezed == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String?,postalCode: freezed == postalCode ? _self.postalCode : postalCode // ignore: cast_nullable_to_non_nullable
as String?,organization: freezed == organization ? _self.organization : organization // ignore: cast_nullable_to_non_nullable
as String?,department: freezed == department ? _self.department : department // ignore: cast_nullable_to_non_nullable
as String?,preferredLanguage: freezed == preferredLanguage ? _self.preferredLanguage : preferredLanguage // ignore: cast_nullable_to_non_nullable
as String?,timezone: freezed == timezone ? _self.timezone : timezone // ignore: cast_nullable_to_non_nullable
as String?,availability: freezed == availability ? _self._availability : availability // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,consultationTypes: freezed == consultationTypes ? _self._consultationTypes : consultationTypes // ignore: cast_nullable_to_non_nullable
as List<String>?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,isVerified: freezed == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool?,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,totalConsultations: freezed == totalConsultations ? _self.totalConsultations : totalConsultations // ignore: cast_nullable_to_non_nullable
as int?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
