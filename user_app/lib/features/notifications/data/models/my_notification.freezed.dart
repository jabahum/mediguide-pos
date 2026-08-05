// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'my_notification.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MyNotification {

 String get id; String get title; String get message; String get type;@JsonKey(name: 'user_id') String? get userId; String get priority;@JsonKey(name: 'action_url') String? get actionUrl;@JsonKey(name: 'is_read') bool get isRead;@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? get createdAt;@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? get updatedAt;
/// Create a copy of MyNotification
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MyNotificationCopyWith<MyNotification> get copyWith => _$MyNotificationCopyWithImpl<MyNotification>(this as MyNotification, _$identity);

  /// Serializes this MyNotification to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MyNotification&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.message, message) || other.message == message)&&(identical(other.type, type) || other.type == type)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.actionUrl, actionUrl) || other.actionUrl == actionUrl)&&(identical(other.isRead, isRead) || other.isRead == isRead)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,message,type,userId,priority,actionUrl,isRead,createdAt,updatedAt);

@override
String toString() {
  return 'MyNotification(id: $id, title: $title, message: $message, type: $type, userId: $userId, priority: $priority, actionUrl: $actionUrl, isRead: $isRead, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $MyNotificationCopyWith<$Res>  {
  factory $MyNotificationCopyWith(MyNotification value, $Res Function(MyNotification) _then) = _$MyNotificationCopyWithImpl;
@useResult
$Res call({
 String id, String title, String message, String type,@JsonKey(name: 'user_id') String? userId, String priority,@JsonKey(name: 'action_url') String? actionUrl,@JsonKey(name: 'is_read') bool isRead,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class _$MyNotificationCopyWithImpl<$Res>
    implements $MyNotificationCopyWith<$Res> {
  _$MyNotificationCopyWithImpl(this._self, this._then);

  final MyNotification _self;
  final $Res Function(MyNotification) _then;

/// Create a copy of MyNotification
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? message = null,Object? type = null,Object? userId = freezed,Object? priority = null,Object? actionUrl = freezed,Object? isRead = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as String,actionUrl: freezed == actionUrl ? _self.actionUrl : actionUrl // ignore: cast_nullable_to_non_nullable
as String?,isRead: null == isRead ? _self.isRead : isRead // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _MyNotification extends MyNotification {
  const _MyNotification({required this.id, this.title = '', this.message = '', this.type = 'info', @JsonKey(name: 'user_id') this.userId, this.priority = 'normal', @JsonKey(name: 'action_url') this.actionUrl, @JsonKey(name: 'is_read') this.isRead = false, @JsonKey(name: 'created_at')@NullableDateTimeConverter() this.createdAt, @JsonKey(name: 'updated_at')@NullableDateTimeConverter() this.updatedAt}): super._();
  factory _MyNotification.fromJson(Map<String, dynamic> json) => _$MyNotificationFromJson(json);

@override final  String id;
@override@JsonKey() final  String title;
@override@JsonKey() final  String message;
@override@JsonKey() final  String type;
@override@JsonKey(name: 'user_id') final  String? userId;
@override@JsonKey() final  String priority;
@override@JsonKey(name: 'action_url') final  String? actionUrl;
@override@JsonKey(name: 'is_read') final  bool isRead;
@override@JsonKey(name: 'created_at')@NullableDateTimeConverter() final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at')@NullableDateTimeConverter() final  DateTime? updatedAt;

/// Create a copy of MyNotification
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MyNotificationCopyWith<_MyNotification> get copyWith => __$MyNotificationCopyWithImpl<_MyNotification>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MyNotificationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MyNotification&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.message, message) || other.message == message)&&(identical(other.type, type) || other.type == type)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.actionUrl, actionUrl) || other.actionUrl == actionUrl)&&(identical(other.isRead, isRead) || other.isRead == isRead)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,message,type,userId,priority,actionUrl,isRead,createdAt,updatedAt);

@override
String toString() {
  return 'MyNotification(id: $id, title: $title, message: $message, type: $type, userId: $userId, priority: $priority, actionUrl: $actionUrl, isRead: $isRead, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$MyNotificationCopyWith<$Res> implements $MyNotificationCopyWith<$Res> {
  factory _$MyNotificationCopyWith(_MyNotification value, $Res Function(_MyNotification) _then) = __$MyNotificationCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String message, String type,@JsonKey(name: 'user_id') String? userId, String priority,@JsonKey(name: 'action_url') String? actionUrl,@JsonKey(name: 'is_read') bool isRead,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});




}
/// @nodoc
class __$MyNotificationCopyWithImpl<$Res>
    implements _$MyNotificationCopyWith<$Res> {
  __$MyNotificationCopyWithImpl(this._self, this._then);

  final _MyNotification _self;
  final $Res Function(_MyNotification) _then;

/// Create a copy of MyNotification
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? message = null,Object? type = null,Object? userId = freezed,Object? priority = null,Object? actionUrl = freezed,Object? isRead = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_MyNotification(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as String,actionUrl: freezed == actionUrl ? _self.actionUrl : actionUrl // ignore: cast_nullable_to_non_nullable
as String?,isRead: null == isRead ? _self.isRead : isRead // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
