// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'support_ticket.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SupportTicket {

 String get id; String get subject; String get description; String get category;@JsonKey(fromJson: _ticketStatusFromJson, toJson: _ticketStatusToJson) TicketStatus get status;@JsonKey(fromJson: _priorityFromJson, toJson: _priorityToJson) TicketPriority get priority;@JsonKey(name: 'user_id') String get userId;@JsonKey(name: 'assigned_to') String? get assignedTo; User? get user;@JsonKey(name: 'assigned_user') User? get assignedUser;@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? get createdAt;@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? get updatedAt;
/// Create a copy of SupportTicket
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SupportTicketCopyWith<SupportTicket> get copyWith => _$SupportTicketCopyWithImpl<SupportTicket>(this as SupportTicket, _$identity);

  /// Serializes this SupportTicket to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SupportTicket&&(identical(other.id, id) || other.id == id)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.description, description) || other.description == description)&&(identical(other.category, category) || other.category == category)&&(identical(other.status, status) || other.status == status)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.assignedTo, assignedTo) || other.assignedTo == assignedTo)&&(identical(other.user, user) || other.user == user)&&(identical(other.assignedUser, assignedUser) || other.assignedUser == assignedUser)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,subject,description,category,status,priority,userId,assignedTo,user,assignedUser,createdAt,updatedAt);

@override
String toString() {
  return 'SupportTicket(id: $id, subject: $subject, description: $description, category: $category, status: $status, priority: $priority, userId: $userId, assignedTo: $assignedTo, user: $user, assignedUser: $assignedUser, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $SupportTicketCopyWith<$Res>  {
  factory $SupportTicketCopyWith(SupportTicket value, $Res Function(SupportTicket) _then) = _$SupportTicketCopyWithImpl;
@useResult
$Res call({
 String id, String subject, String description, String category,@JsonKey(fromJson: _ticketStatusFromJson, toJson: _ticketStatusToJson) TicketStatus status,@JsonKey(fromJson: _priorityFromJson, toJson: _priorityToJson) TicketPriority priority,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'assigned_to') String? assignedTo, User? user,@JsonKey(name: 'assigned_user') User? assignedUser,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});


$UserCopyWith<$Res>? get user;$UserCopyWith<$Res>? get assignedUser;

}
/// @nodoc
class _$SupportTicketCopyWithImpl<$Res>
    implements $SupportTicketCopyWith<$Res> {
  _$SupportTicketCopyWithImpl(this._self, this._then);

  final SupportTicket _self;
  final $Res Function(SupportTicket) _then;

/// Create a copy of SupportTicket
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? subject = null,Object? description = null,Object? category = null,Object? status = null,Object? priority = null,Object? userId = null,Object? assignedTo = freezed,Object? user = freezed,Object? assignedUser = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TicketStatus,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as TicketPriority,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,assignedTo: freezed == assignedTo ? _self.assignedTo : assignedTo // ignore: cast_nullable_to_non_nullable
as String?,user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as User?,assignedUser: freezed == assignedUser ? _self.assignedUser : assignedUser // ignore: cast_nullable_to_non_nullable
as User?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of SupportTicket
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserCopyWith<$Res>? get user {
    if (_self.user == null) {
    return null;
  }

  return $UserCopyWith<$Res>(_self.user!, (value) {
    return _then(_self.copyWith(user: value));
  });
}/// Create a copy of SupportTicket
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserCopyWith<$Res>? get assignedUser {
    if (_self.assignedUser == null) {
    return null;
  }

  return $UserCopyWith<$Res>(_self.assignedUser!, (value) {
    return _then(_self.copyWith(assignedUser: value));
  });
}
}


/// @nodoc

@JsonSerializable(explicitToJson: true)
class _SupportTicket extends SupportTicket {
  const _SupportTicket({required this.id, this.subject = '', this.description = '', this.category = '', @JsonKey(fromJson: _ticketStatusFromJson, toJson: _ticketStatusToJson) this.status = TicketStatus.open, @JsonKey(fromJson: _priorityFromJson, toJson: _priorityToJson) this.priority = TicketPriority.normal, @JsonKey(name: 'user_id') this.userId = '', @JsonKey(name: 'assigned_to') this.assignedTo, this.user, @JsonKey(name: 'assigned_user') this.assignedUser, @JsonKey(name: 'created_at')@NullableDateTimeConverter() this.createdAt, @JsonKey(name: 'updated_at')@NullableDateTimeConverter() this.updatedAt}): super._();
  factory _SupportTicket.fromJson(Map<String, dynamic> json) => _$SupportTicketFromJson(json);

@override final  String id;
@override@JsonKey() final  String subject;
@override@JsonKey() final  String description;
@override@JsonKey() final  String category;
@override@JsonKey(fromJson: _ticketStatusFromJson, toJson: _ticketStatusToJson) final  TicketStatus status;
@override@JsonKey(fromJson: _priorityFromJson, toJson: _priorityToJson) final  TicketPriority priority;
@override@JsonKey(name: 'user_id') final  String userId;
@override@JsonKey(name: 'assigned_to') final  String? assignedTo;
@override final  User? user;
@override@JsonKey(name: 'assigned_user') final  User? assignedUser;
@override@JsonKey(name: 'created_at')@NullableDateTimeConverter() final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at')@NullableDateTimeConverter() final  DateTime? updatedAt;

/// Create a copy of SupportTicket
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SupportTicketCopyWith<_SupportTicket> get copyWith => __$SupportTicketCopyWithImpl<_SupportTicket>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SupportTicketToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SupportTicket&&(identical(other.id, id) || other.id == id)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.description, description) || other.description == description)&&(identical(other.category, category) || other.category == category)&&(identical(other.status, status) || other.status == status)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.assignedTo, assignedTo) || other.assignedTo == assignedTo)&&(identical(other.user, user) || other.user == user)&&(identical(other.assignedUser, assignedUser) || other.assignedUser == assignedUser)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,subject,description,category,status,priority,userId,assignedTo,user,assignedUser,createdAt,updatedAt);

@override
String toString() {
  return 'SupportTicket(id: $id, subject: $subject, description: $description, category: $category, status: $status, priority: $priority, userId: $userId, assignedTo: $assignedTo, user: $user, assignedUser: $assignedUser, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$SupportTicketCopyWith<$Res> implements $SupportTicketCopyWith<$Res> {
  factory _$SupportTicketCopyWith(_SupportTicket value, $Res Function(_SupportTicket) _then) = __$SupportTicketCopyWithImpl;
@override @useResult
$Res call({
 String id, String subject, String description, String category,@JsonKey(fromJson: _ticketStatusFromJson, toJson: _ticketStatusToJson) TicketStatus status,@JsonKey(fromJson: _priorityFromJson, toJson: _priorityToJson) TicketPriority priority,@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'assigned_to') String? assignedTo, User? user,@JsonKey(name: 'assigned_user') User? assignedUser,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});


@override $UserCopyWith<$Res>? get user;@override $UserCopyWith<$Res>? get assignedUser;

}
/// @nodoc
class __$SupportTicketCopyWithImpl<$Res>
    implements _$SupportTicketCopyWith<$Res> {
  __$SupportTicketCopyWithImpl(this._self, this._then);

  final _SupportTicket _self;
  final $Res Function(_SupportTicket) _then;

/// Create a copy of SupportTicket
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? subject = null,Object? description = null,Object? category = null,Object? status = null,Object? priority = null,Object? userId = null,Object? assignedTo = freezed,Object? user = freezed,Object? assignedUser = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_SupportTicket(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TicketStatus,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as TicketPriority,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,assignedTo: freezed == assignedTo ? _self.assignedTo : assignedTo // ignore: cast_nullable_to_non_nullable
as String?,user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as User?,assignedUser: freezed == assignedUser ? _self.assignedUser : assignedUser // ignore: cast_nullable_to_non_nullable
as User?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of SupportTicket
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserCopyWith<$Res>? get user {
    if (_self.user == null) {
    return null;
  }

  return $UserCopyWith<$Res>(_self.user!, (value) {
    return _then(_self.copyWith(user: value));
  });
}/// Create a copy of SupportTicket
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserCopyWith<$Res>? get assignedUser {
    if (_self.assignedUser == null) {
    return null;
  }

  return $UserCopyWith<$Res>(_self.assignedUser!, (value) {
    return _then(_self.copyWith(assignedUser: value));
  });
}
}


/// @nodoc
mixin _$SupportTicketRequest {

 String? get subject; String? get description; String? get category; String? get priority; String? get status;@JsonKey(name: 'assigned_to') String? get assignedTo;
/// Create a copy of SupportTicketRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SupportTicketRequestCopyWith<SupportTicketRequest> get copyWith => _$SupportTicketRequestCopyWithImpl<SupportTicketRequest>(this as SupportTicketRequest, _$identity);

  /// Serializes this SupportTicketRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SupportTicketRequest&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.description, description) || other.description == description)&&(identical(other.category, category) || other.category == category)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.status, status) || other.status == status)&&(identical(other.assignedTo, assignedTo) || other.assignedTo == assignedTo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,subject,description,category,priority,status,assignedTo);

@override
String toString() {
  return 'SupportTicketRequest(subject: $subject, description: $description, category: $category, priority: $priority, status: $status, assignedTo: $assignedTo)';
}


}

/// @nodoc
abstract mixin class $SupportTicketRequestCopyWith<$Res>  {
  factory $SupportTicketRequestCopyWith(SupportTicketRequest value, $Res Function(SupportTicketRequest) _then) = _$SupportTicketRequestCopyWithImpl;
@useResult
$Res call({
 String? subject, String? description, String? category, String? priority, String? status,@JsonKey(name: 'assigned_to') String? assignedTo
});




}
/// @nodoc
class _$SupportTicketRequestCopyWithImpl<$Res>
    implements $SupportTicketRequestCopyWith<$Res> {
  _$SupportTicketRequestCopyWithImpl(this._self, this._then);

  final SupportTicketRequest _self;
  final $Res Function(SupportTicketRequest) _then;

/// Create a copy of SupportTicketRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? subject = freezed,Object? description = freezed,Object? category = freezed,Object? priority = freezed,Object? status = freezed,Object? assignedTo = freezed,}) {
  return _then(_self.copyWith(
subject: freezed == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,priority: freezed == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,assignedTo: freezed == assignedTo ? _self.assignedTo : assignedTo // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// @nodoc

@JsonSerializable(includeIfNull: false)
class _SupportTicketRequest implements SupportTicketRequest {
  const _SupportTicketRequest({this.subject, this.description, this.category, this.priority, this.status, @JsonKey(name: 'assigned_to') this.assignedTo});
  factory _SupportTicketRequest.fromJson(Map<String, dynamic> json) => _$SupportTicketRequestFromJson(json);

@override final  String? subject;
@override final  String? description;
@override final  String? category;
@override final  String? priority;
@override final  String? status;
@override@JsonKey(name: 'assigned_to') final  String? assignedTo;

/// Create a copy of SupportTicketRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SupportTicketRequestCopyWith<_SupportTicketRequest> get copyWith => __$SupportTicketRequestCopyWithImpl<_SupportTicketRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SupportTicketRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SupportTicketRequest&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.description, description) || other.description == description)&&(identical(other.category, category) || other.category == category)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.status, status) || other.status == status)&&(identical(other.assignedTo, assignedTo) || other.assignedTo == assignedTo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,subject,description,category,priority,status,assignedTo);

@override
String toString() {
  return 'SupportTicketRequest(subject: $subject, description: $description, category: $category, priority: $priority, status: $status, assignedTo: $assignedTo)';
}


}

/// @nodoc
abstract mixin class _$SupportTicketRequestCopyWith<$Res> implements $SupportTicketRequestCopyWith<$Res> {
  factory _$SupportTicketRequestCopyWith(_SupportTicketRequest value, $Res Function(_SupportTicketRequest) _then) = __$SupportTicketRequestCopyWithImpl;
@override @useResult
$Res call({
 String? subject, String? description, String? category, String? priority, String? status,@JsonKey(name: 'assigned_to') String? assignedTo
});




}
/// @nodoc
class __$SupportTicketRequestCopyWithImpl<$Res>
    implements _$SupportTicketRequestCopyWith<$Res> {
  __$SupportTicketRequestCopyWithImpl(this._self, this._then);

  final _SupportTicketRequest _self;
  final $Res Function(_SupportTicketRequest) _then;

/// Create a copy of SupportTicketRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? subject = freezed,Object? description = freezed,Object? category = freezed,Object? priority = freezed,Object? status = freezed,Object? assignedTo = freezed,}) {
  return _then(_SupportTicketRequest(
subject: freezed == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,priority: freezed == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,assignedTo: freezed == assignedTo ? _self.assignedTo : assignedTo // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
