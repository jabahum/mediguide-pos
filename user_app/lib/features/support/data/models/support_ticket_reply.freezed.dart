// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'support_ticket_reply.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SupportReplyAuthor {

 String get id; String get name; String get email;
/// Create a copy of SupportReplyAuthor
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SupportReplyAuthorCopyWith<SupportReplyAuthor> get copyWith => _$SupportReplyAuthorCopyWithImpl<SupportReplyAuthor>(this as SupportReplyAuthor, _$identity);

  /// Serializes this SupportReplyAuthor to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SupportReplyAuthor&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,email);

@override
String toString() {
  return 'SupportReplyAuthor(id: $id, name: $name, email: $email)';
}


}

/// @nodoc
abstract mixin class $SupportReplyAuthorCopyWith<$Res>  {
  factory $SupportReplyAuthorCopyWith(SupportReplyAuthor value, $Res Function(SupportReplyAuthor) _then) = _$SupportReplyAuthorCopyWithImpl;
@useResult
$Res call({
 String id, String name, String email
});




}
/// @nodoc
class _$SupportReplyAuthorCopyWithImpl<$Res>
    implements $SupportReplyAuthorCopyWith<$Res> {
  _$SupportReplyAuthorCopyWithImpl(this._self, this._then);

  final SupportReplyAuthor _self;
  final $Res Function(SupportReplyAuthor) _then;

/// Create a copy of SupportReplyAuthor
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? email = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _SupportReplyAuthor implements SupportReplyAuthor {
  const _SupportReplyAuthor({required this.id, this.name = '', this.email = ''});
  factory _SupportReplyAuthor.fromJson(Map<String, dynamic> json) => _$SupportReplyAuthorFromJson(json);

@override final  String id;
@override@JsonKey() final  String name;
@override@JsonKey() final  String email;

/// Create a copy of SupportReplyAuthor
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SupportReplyAuthorCopyWith<_SupportReplyAuthor> get copyWith => __$SupportReplyAuthorCopyWithImpl<_SupportReplyAuthor>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SupportReplyAuthorToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SupportReplyAuthor&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,email);

@override
String toString() {
  return 'SupportReplyAuthor(id: $id, name: $name, email: $email)';
}


}

/// @nodoc
abstract mixin class _$SupportReplyAuthorCopyWith<$Res> implements $SupportReplyAuthorCopyWith<$Res> {
  factory _$SupportReplyAuthorCopyWith(_SupportReplyAuthor value, $Res Function(_SupportReplyAuthor) _then) = __$SupportReplyAuthorCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String email
});




}
/// @nodoc
class __$SupportReplyAuthorCopyWithImpl<$Res>
    implements _$SupportReplyAuthorCopyWith<$Res> {
  __$SupportReplyAuthorCopyWithImpl(this._self, this._then);

  final _SupportReplyAuthor _self;
  final $Res Function(_SupportReplyAuthor) _then;

/// Create a copy of SupportReplyAuthor
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? email = null,}) {
  return _then(_SupportReplyAuthor(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$SupportTicketReply {

 String get id; String get message;@JsonKey(name: 'is_internal') bool get isInternal;@JsonKey(name: 'ticket_id') String get ticketId;@JsonKey(name: 'user_id') String get userId; SupportReplyAuthor? get user;@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? get createdAt;@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? get updatedAt;
/// Create a copy of SupportTicketReply
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SupportTicketReplyCopyWith<SupportTicketReply> get copyWith => _$SupportTicketReplyCopyWithImpl<SupportTicketReply>(this as SupportTicketReply, _$identity);

  /// Serializes this SupportTicketReply to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SupportTicketReply&&(identical(other.id, id) || other.id == id)&&(identical(other.message, message) || other.message == message)&&(identical(other.isInternal, isInternal) || other.isInternal == isInternal)&&(identical(other.ticketId, ticketId) || other.ticketId == ticketId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.user, user) || other.user == user)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,message,isInternal,ticketId,userId,user,createdAt,updatedAt);

@override
String toString() {
  return 'SupportTicketReply(id: $id, message: $message, isInternal: $isInternal, ticketId: $ticketId, userId: $userId, user: $user, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $SupportTicketReplyCopyWith<$Res>  {
  factory $SupportTicketReplyCopyWith(SupportTicketReply value, $Res Function(SupportTicketReply) _then) = _$SupportTicketReplyCopyWithImpl;
@useResult
$Res call({
 String id, String message,@JsonKey(name: 'is_internal') bool isInternal,@JsonKey(name: 'ticket_id') String ticketId,@JsonKey(name: 'user_id') String userId, SupportReplyAuthor? user,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});


$SupportReplyAuthorCopyWith<$Res>? get user;

}
/// @nodoc
class _$SupportTicketReplyCopyWithImpl<$Res>
    implements $SupportTicketReplyCopyWith<$Res> {
  _$SupportTicketReplyCopyWithImpl(this._self, this._then);

  final SupportTicketReply _self;
  final $Res Function(SupportTicketReply) _then;

/// Create a copy of SupportTicketReply
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? message = null,Object? isInternal = null,Object? ticketId = null,Object? userId = null,Object? user = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,isInternal: null == isInternal ? _self.isInternal : isInternal // ignore: cast_nullable_to_non_nullable
as bool,ticketId: null == ticketId ? _self.ticketId : ticketId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as SupportReplyAuthor?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of SupportTicketReply
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SupportReplyAuthorCopyWith<$Res>? get user {
    if (_self.user == null) {
    return null;
  }

  return $SupportReplyAuthorCopyWith<$Res>(_self.user!, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}


/// @nodoc

@JsonSerializable(explicitToJson: true)
class _SupportTicketReply extends SupportTicketReply {
  const _SupportTicketReply({required this.id, this.message = '', @JsonKey(name: 'is_internal') this.isInternal = false, @JsonKey(name: 'ticket_id') this.ticketId = '', @JsonKey(name: 'user_id') this.userId = '', this.user, @JsonKey(name: 'created_at')@NullableDateTimeConverter() this.createdAt, @JsonKey(name: 'updated_at')@NullableDateTimeConverter() this.updatedAt}): super._();
  factory _SupportTicketReply.fromJson(Map<String, dynamic> json) => _$SupportTicketReplyFromJson(json);

@override final  String id;
@override@JsonKey() final  String message;
@override@JsonKey(name: 'is_internal') final  bool isInternal;
@override@JsonKey(name: 'ticket_id') final  String ticketId;
@override@JsonKey(name: 'user_id') final  String userId;
@override final  SupportReplyAuthor? user;
@override@JsonKey(name: 'created_at')@NullableDateTimeConverter() final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at')@NullableDateTimeConverter() final  DateTime? updatedAt;

/// Create a copy of SupportTicketReply
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SupportTicketReplyCopyWith<_SupportTicketReply> get copyWith => __$SupportTicketReplyCopyWithImpl<_SupportTicketReply>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SupportTicketReplyToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SupportTicketReply&&(identical(other.id, id) || other.id == id)&&(identical(other.message, message) || other.message == message)&&(identical(other.isInternal, isInternal) || other.isInternal == isInternal)&&(identical(other.ticketId, ticketId) || other.ticketId == ticketId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.user, user) || other.user == user)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,message,isInternal,ticketId,userId,user,createdAt,updatedAt);

@override
String toString() {
  return 'SupportTicketReply(id: $id, message: $message, isInternal: $isInternal, ticketId: $ticketId, userId: $userId, user: $user, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$SupportTicketReplyCopyWith<$Res> implements $SupportTicketReplyCopyWith<$Res> {
  factory _$SupportTicketReplyCopyWith(_SupportTicketReply value, $Res Function(_SupportTicketReply) _then) = __$SupportTicketReplyCopyWithImpl;
@override @useResult
$Res call({
 String id, String message,@JsonKey(name: 'is_internal') bool isInternal,@JsonKey(name: 'ticket_id') String ticketId,@JsonKey(name: 'user_id') String userId, SupportReplyAuthor? user,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});


@override $SupportReplyAuthorCopyWith<$Res>? get user;

}
/// @nodoc
class __$SupportTicketReplyCopyWithImpl<$Res>
    implements _$SupportTicketReplyCopyWith<$Res> {
  __$SupportTicketReplyCopyWithImpl(this._self, this._then);

  final _SupportTicketReply _self;
  final $Res Function(_SupportTicketReply) _then;

/// Create a copy of SupportTicketReply
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? message = null,Object? isInternal = null,Object? ticketId = null,Object? userId = null,Object? user = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_SupportTicketReply(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,isInternal: null == isInternal ? _self.isInternal : isInternal // ignore: cast_nullable_to_non_nullable
as bool,ticketId: null == ticketId ? _self.ticketId : ticketId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as SupportReplyAuthor?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of SupportTicketReply
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SupportReplyAuthorCopyWith<$Res>? get user {
    if (_self.user == null) {
    return null;
  }

  return $SupportReplyAuthorCopyWith<$Res>(_self.user!, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}

// dart format on
