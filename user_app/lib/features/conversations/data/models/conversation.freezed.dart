// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'conversation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Conversation {

 String get id;@JsonKey(name: 'participant1_user_id') String get participant1;@JsonKey(name: 'participant2_user_id') String get participant2;@JsonKey(name: 'last_message_id') String get lastMessage;@JsonKey(name: 'last_activity')@NullableDateTimeConverter() DateTime? get lastActivityDate;@JsonKey(name: 'participant1') User? get participant1User;@JsonKey(name: 'participant2') User? get participant2User;@JsonKey(name: 'last_message_data') Message? get lastMessageData; List<Message> get messages;@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? get createdAt;@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? get updatedAt;
/// Create a copy of Conversation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConversationCopyWith<Conversation> get copyWith => _$ConversationCopyWithImpl<Conversation>(this as Conversation, _$identity);

  /// Serializes this Conversation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Conversation&&(identical(other.id, id) || other.id == id)&&(identical(other.participant1, participant1) || other.participant1 == participant1)&&(identical(other.participant2, participant2) || other.participant2 == participant2)&&(identical(other.lastMessage, lastMessage) || other.lastMessage == lastMessage)&&(identical(other.lastActivityDate, lastActivityDate) || other.lastActivityDate == lastActivityDate)&&(identical(other.participant1User, participant1User) || other.participant1User == participant1User)&&(identical(other.participant2User, participant2User) || other.participant2User == participant2User)&&(identical(other.lastMessageData, lastMessageData) || other.lastMessageData == lastMessageData)&&const DeepCollectionEquality().equals(other.messages, messages)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,participant1,participant2,lastMessage,lastActivityDate,participant1User,participant2User,lastMessageData,const DeepCollectionEquality().hash(messages),createdAt,updatedAt);

@override
String toString() {
  return 'Conversation(id: $id, participant1: $participant1, participant2: $participant2, lastMessage: $lastMessage, lastActivityDate: $lastActivityDate, participant1User: $participant1User, participant2User: $participant2User, lastMessageData: $lastMessageData, messages: $messages, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $ConversationCopyWith<$Res>  {
  factory $ConversationCopyWith(Conversation value, $Res Function(Conversation) _then) = _$ConversationCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'participant1_user_id') String participant1,@JsonKey(name: 'participant2_user_id') String participant2,@JsonKey(name: 'last_message_id') String lastMessage,@JsonKey(name: 'last_activity')@NullableDateTimeConverter() DateTime? lastActivityDate,@JsonKey(name: 'participant1') User? participant1User,@JsonKey(name: 'participant2') User? participant2User,@JsonKey(name: 'last_message_data') Message? lastMessageData, List<Message> messages,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});


$UserCopyWith<$Res>? get participant1User;$UserCopyWith<$Res>? get participant2User;$MessageCopyWith<$Res>? get lastMessageData;

}
/// @nodoc
class _$ConversationCopyWithImpl<$Res>
    implements $ConversationCopyWith<$Res> {
  _$ConversationCopyWithImpl(this._self, this._then);

  final Conversation _self;
  final $Res Function(Conversation) _then;

/// Create a copy of Conversation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? participant1 = null,Object? participant2 = null,Object? lastMessage = null,Object? lastActivityDate = freezed,Object? participant1User = freezed,Object? participant2User = freezed,Object? lastMessageData = freezed,Object? messages = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,participant1: null == participant1 ? _self.participant1 : participant1 // ignore: cast_nullable_to_non_nullable
as String,participant2: null == participant2 ? _self.participant2 : participant2 // ignore: cast_nullable_to_non_nullable
as String,lastMessage: null == lastMessage ? _self.lastMessage : lastMessage // ignore: cast_nullable_to_non_nullable
as String,lastActivityDate: freezed == lastActivityDate ? _self.lastActivityDate : lastActivityDate // ignore: cast_nullable_to_non_nullable
as DateTime?,participant1User: freezed == participant1User ? _self.participant1User : participant1User // ignore: cast_nullable_to_non_nullable
as User?,participant2User: freezed == participant2User ? _self.participant2User : participant2User // ignore: cast_nullable_to_non_nullable
as User?,lastMessageData: freezed == lastMessageData ? _self.lastMessageData : lastMessageData // ignore: cast_nullable_to_non_nullable
as Message?,messages: null == messages ? _self.messages : messages // ignore: cast_nullable_to_non_nullable
as List<Message>,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of Conversation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserCopyWith<$Res>? get participant1User {
    if (_self.participant1User == null) {
    return null;
  }

  return $UserCopyWith<$Res>(_self.participant1User!, (value) {
    return _then(_self.copyWith(participant1User: value));
  });
}/// Create a copy of Conversation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserCopyWith<$Res>? get participant2User {
    if (_self.participant2User == null) {
    return null;
  }

  return $UserCopyWith<$Res>(_self.participant2User!, (value) {
    return _then(_self.copyWith(participant2User: value));
  });
}/// Create a copy of Conversation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageCopyWith<$Res>? get lastMessageData {
    if (_self.lastMessageData == null) {
    return null;
  }

  return $MessageCopyWith<$Res>(_self.lastMessageData!, (value) {
    return _then(_self.copyWith(lastMessageData: value));
  });
}
}


/// @nodoc

@JsonSerializable(explicitToJson: true)
class _Conversation extends Conversation {
  const _Conversation({required this.id, @JsonKey(name: 'participant1_user_id') this.participant1 = '', @JsonKey(name: 'participant2_user_id') this.participant2 = '', @JsonKey(name: 'last_message_id') this.lastMessage = '', @JsonKey(name: 'last_activity')@NullableDateTimeConverter() this.lastActivityDate, @JsonKey(name: 'participant1') this.participant1User, @JsonKey(name: 'participant2') this.participant2User, @JsonKey(name: 'last_message_data') this.lastMessageData, final  List<Message> messages = const [], @JsonKey(name: 'created_at')@NullableDateTimeConverter() this.createdAt, @JsonKey(name: 'updated_at')@NullableDateTimeConverter() this.updatedAt}): _messages = messages,super._();
  factory _Conversation.fromJson(Map<String, dynamic> json) => _$ConversationFromJson(json);

@override final  String id;
@override@JsonKey(name: 'participant1_user_id') final  String participant1;
@override@JsonKey(name: 'participant2_user_id') final  String participant2;
@override@JsonKey(name: 'last_message_id') final  String lastMessage;
@override@JsonKey(name: 'last_activity')@NullableDateTimeConverter() final  DateTime? lastActivityDate;
@override@JsonKey(name: 'participant1') final  User? participant1User;
@override@JsonKey(name: 'participant2') final  User? participant2User;
@override@JsonKey(name: 'last_message_data') final  Message? lastMessageData;
 final  List<Message> _messages;
@override@JsonKey() List<Message> get messages {
  if (_messages is EqualUnmodifiableListView) return _messages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_messages);
}

@override@JsonKey(name: 'created_at')@NullableDateTimeConverter() final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at')@NullableDateTimeConverter() final  DateTime? updatedAt;

/// Create a copy of Conversation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConversationCopyWith<_Conversation> get copyWith => __$ConversationCopyWithImpl<_Conversation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ConversationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Conversation&&(identical(other.id, id) || other.id == id)&&(identical(other.participant1, participant1) || other.participant1 == participant1)&&(identical(other.participant2, participant2) || other.participant2 == participant2)&&(identical(other.lastMessage, lastMessage) || other.lastMessage == lastMessage)&&(identical(other.lastActivityDate, lastActivityDate) || other.lastActivityDate == lastActivityDate)&&(identical(other.participant1User, participant1User) || other.participant1User == participant1User)&&(identical(other.participant2User, participant2User) || other.participant2User == participant2User)&&(identical(other.lastMessageData, lastMessageData) || other.lastMessageData == lastMessageData)&&const DeepCollectionEquality().equals(other._messages, _messages)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,participant1,participant2,lastMessage,lastActivityDate,participant1User,participant2User,lastMessageData,const DeepCollectionEquality().hash(_messages),createdAt,updatedAt);

@override
String toString() {
  return 'Conversation(id: $id, participant1: $participant1, participant2: $participant2, lastMessage: $lastMessage, lastActivityDate: $lastActivityDate, participant1User: $participant1User, participant2User: $participant2User, lastMessageData: $lastMessageData, messages: $messages, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ConversationCopyWith<$Res> implements $ConversationCopyWith<$Res> {
  factory _$ConversationCopyWith(_Conversation value, $Res Function(_Conversation) _then) = __$ConversationCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'participant1_user_id') String participant1,@JsonKey(name: 'participant2_user_id') String participant2,@JsonKey(name: 'last_message_id') String lastMessage,@JsonKey(name: 'last_activity')@NullableDateTimeConverter() DateTime? lastActivityDate,@JsonKey(name: 'participant1') User? participant1User,@JsonKey(name: 'participant2') User? participant2User,@JsonKey(name: 'last_message_data') Message? lastMessageData, List<Message> messages,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});


@override $UserCopyWith<$Res>? get participant1User;@override $UserCopyWith<$Res>? get participant2User;@override $MessageCopyWith<$Res>? get lastMessageData;

}
/// @nodoc
class __$ConversationCopyWithImpl<$Res>
    implements _$ConversationCopyWith<$Res> {
  __$ConversationCopyWithImpl(this._self, this._then);

  final _Conversation _self;
  final $Res Function(_Conversation) _then;

/// Create a copy of Conversation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? participant1 = null,Object? participant2 = null,Object? lastMessage = null,Object? lastActivityDate = freezed,Object? participant1User = freezed,Object? participant2User = freezed,Object? lastMessageData = freezed,Object? messages = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_Conversation(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,participant1: null == participant1 ? _self.participant1 : participant1 // ignore: cast_nullable_to_non_nullable
as String,participant2: null == participant2 ? _self.participant2 : participant2 // ignore: cast_nullable_to_non_nullable
as String,lastMessage: null == lastMessage ? _self.lastMessage : lastMessage // ignore: cast_nullable_to_non_nullable
as String,lastActivityDate: freezed == lastActivityDate ? _self.lastActivityDate : lastActivityDate // ignore: cast_nullable_to_non_nullable
as DateTime?,participant1User: freezed == participant1User ? _self.participant1User : participant1User // ignore: cast_nullable_to_non_nullable
as User?,participant2User: freezed == participant2User ? _self.participant2User : participant2User // ignore: cast_nullable_to_non_nullable
as User?,lastMessageData: freezed == lastMessageData ? _self.lastMessageData : lastMessageData // ignore: cast_nullable_to_non_nullable
as Message?,messages: null == messages ? _self._messages : messages // ignore: cast_nullable_to_non_nullable
as List<Message>,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of Conversation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserCopyWith<$Res>? get participant1User {
    if (_self.participant1User == null) {
    return null;
  }

  return $UserCopyWith<$Res>(_self.participant1User!, (value) {
    return _then(_self.copyWith(participant1User: value));
  });
}/// Create a copy of Conversation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserCopyWith<$Res>? get participant2User {
    if (_self.participant2User == null) {
    return null;
  }

  return $UserCopyWith<$Res>(_self.participant2User!, (value) {
    return _then(_self.copyWith(participant2User: value));
  });
}/// Create a copy of Conversation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageCopyWith<$Res>? get lastMessageData {
    if (_self.lastMessageData == null) {
    return null;
  }

  return $MessageCopyWith<$Res>(_self.lastMessageData!, (value) {
    return _then(_self.copyWith(lastMessageData: value));
  });
}
}


/// @nodoc
mixin _$ConversationRequest {

@JsonKey(name: 'other_participant_id') String get otherParticipantId;
/// Create a copy of ConversationRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConversationRequestCopyWith<ConversationRequest> get copyWith => _$ConversationRequestCopyWithImpl<ConversationRequest>(this as ConversationRequest, _$identity);

  /// Serializes this ConversationRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConversationRequest&&(identical(other.otherParticipantId, otherParticipantId) || other.otherParticipantId == otherParticipantId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,otherParticipantId);

@override
String toString() {
  return 'ConversationRequest(otherParticipantId: $otherParticipantId)';
}


}

/// @nodoc
abstract mixin class $ConversationRequestCopyWith<$Res>  {
  factory $ConversationRequestCopyWith(ConversationRequest value, $Res Function(ConversationRequest) _then) = _$ConversationRequestCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'other_participant_id') String otherParticipantId
});




}
/// @nodoc
class _$ConversationRequestCopyWithImpl<$Res>
    implements $ConversationRequestCopyWith<$Res> {
  _$ConversationRequestCopyWithImpl(this._self, this._then);

  final ConversationRequest _self;
  final $Res Function(ConversationRequest) _then;

/// Create a copy of ConversationRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? otherParticipantId = null,}) {
  return _then(_self.copyWith(
otherParticipantId: null == otherParticipantId ? _self.otherParticipantId : otherParticipantId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _ConversationRequest implements ConversationRequest {
  const _ConversationRequest({@JsonKey(name: 'other_participant_id') required this.otherParticipantId});
  factory _ConversationRequest.fromJson(Map<String, dynamic> json) => _$ConversationRequestFromJson(json);

@override@JsonKey(name: 'other_participant_id') final  String otherParticipantId;

/// Create a copy of ConversationRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConversationRequestCopyWith<_ConversationRequest> get copyWith => __$ConversationRequestCopyWithImpl<_ConversationRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ConversationRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConversationRequest&&(identical(other.otherParticipantId, otherParticipantId) || other.otherParticipantId == otherParticipantId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,otherParticipantId);

@override
String toString() {
  return 'ConversationRequest(otherParticipantId: $otherParticipantId)';
}


}

/// @nodoc
abstract mixin class _$ConversationRequestCopyWith<$Res> implements $ConversationRequestCopyWith<$Res> {
  factory _$ConversationRequestCopyWith(_ConversationRequest value, $Res Function(_ConversationRequest) _then) = __$ConversationRequestCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'other_participant_id') String otherParticipantId
});




}
/// @nodoc
class __$ConversationRequestCopyWithImpl<$Res>
    implements _$ConversationRequestCopyWith<$Res> {
  __$ConversationRequestCopyWithImpl(this._self, this._then);

  final _ConversationRequest _self;
  final $Res Function(_ConversationRequest) _then;

/// Create a copy of ConversationRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? otherParticipantId = null,}) {
  return _then(_ConversationRequest(
otherParticipantId: null == otherParticipantId ? _self.otherParticipantId : otherParticipantId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
