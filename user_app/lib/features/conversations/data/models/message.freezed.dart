// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Message {

 String get id;@JsonKey(name: 'conversation_id') String get conversation;@JsonKey(name: 'sender_user_id') String get sender; String get content;@JsonKey(name: 'message_type', fromJson: _messageTypeFromJson, toJson: _messageTypeToJson) MessageType get messageType;@JsonKey(name: 'reply_to_id') String get replyTo; List<String> get attachments;@JsonKey(name: 'read_by') Map<String, dynamic> get readBy; Map<String, dynamic> get reactions;@JsonKey(name: 'is_edited') bool get isEdited;@JsonKey(name: 'edited_at')@NullableDateTimeConverter() DateTime? get editedAtDate;@JsonKey(name: 'sender') User? get senderUser;@JsonKey(name: 'reply_to_message') Message? get replyToMessage;@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? get createdAt;@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? get updatedAt;
/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageCopyWith<Message> get copyWith => _$MessageCopyWithImpl<Message>(this as Message, _$identity);

  /// Serializes this Message to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Message&&(identical(other.id, id) || other.id == id)&&(identical(other.conversation, conversation) || other.conversation == conversation)&&(identical(other.sender, sender) || other.sender == sender)&&(identical(other.content, content) || other.content == content)&&(identical(other.messageType, messageType) || other.messageType == messageType)&&(identical(other.replyTo, replyTo) || other.replyTo == replyTo)&&const DeepCollectionEquality().equals(other.attachments, attachments)&&const DeepCollectionEquality().equals(other.readBy, readBy)&&const DeepCollectionEquality().equals(other.reactions, reactions)&&(identical(other.isEdited, isEdited) || other.isEdited == isEdited)&&(identical(other.editedAtDate, editedAtDate) || other.editedAtDate == editedAtDate)&&(identical(other.senderUser, senderUser) || other.senderUser == senderUser)&&(identical(other.replyToMessage, replyToMessage) || other.replyToMessage == replyToMessage)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,conversation,sender,content,messageType,replyTo,const DeepCollectionEquality().hash(attachments),const DeepCollectionEquality().hash(readBy),const DeepCollectionEquality().hash(reactions),isEdited,editedAtDate,senderUser,replyToMessage,createdAt,updatedAt);

@override
String toString() {
  return 'Message(id: $id, conversation: $conversation, sender: $sender, content: $content, messageType: $messageType, replyTo: $replyTo, attachments: $attachments, readBy: $readBy, reactions: $reactions, isEdited: $isEdited, editedAtDate: $editedAtDate, senderUser: $senderUser, replyToMessage: $replyToMessage, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $MessageCopyWith<$Res>  {
  factory $MessageCopyWith(Message value, $Res Function(Message) _then) = _$MessageCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'conversation_id') String conversation,@JsonKey(name: 'sender_user_id') String sender, String content,@JsonKey(name: 'message_type', fromJson: _messageTypeFromJson, toJson: _messageTypeToJson) MessageType messageType,@JsonKey(name: 'reply_to_id') String replyTo, List<String> attachments,@JsonKey(name: 'read_by') Map<String, dynamic> readBy, Map<String, dynamic> reactions,@JsonKey(name: 'is_edited') bool isEdited,@JsonKey(name: 'edited_at')@NullableDateTimeConverter() DateTime? editedAtDate,@JsonKey(name: 'sender') User? senderUser,@JsonKey(name: 'reply_to_message') Message? replyToMessage,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});


$UserCopyWith<$Res>? get senderUser;$MessageCopyWith<$Res>? get replyToMessage;

}
/// @nodoc
class _$MessageCopyWithImpl<$Res>
    implements $MessageCopyWith<$Res> {
  _$MessageCopyWithImpl(this._self, this._then);

  final Message _self;
  final $Res Function(Message) _then;

/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? conversation = null,Object? sender = null,Object? content = null,Object? messageType = null,Object? replyTo = null,Object? attachments = null,Object? readBy = null,Object? reactions = null,Object? isEdited = null,Object? editedAtDate = freezed,Object? senderUser = freezed,Object? replyToMessage = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,conversation: null == conversation ? _self.conversation : conversation // ignore: cast_nullable_to_non_nullable
as String,sender: null == sender ? _self.sender : sender // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,messageType: null == messageType ? _self.messageType : messageType // ignore: cast_nullable_to_non_nullable
as MessageType,replyTo: null == replyTo ? _self.replyTo : replyTo // ignore: cast_nullable_to_non_nullable
as String,attachments: null == attachments ? _self.attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<String>,readBy: null == readBy ? _self.readBy : readBy // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,reactions: null == reactions ? _self.reactions : reactions // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,isEdited: null == isEdited ? _self.isEdited : isEdited // ignore: cast_nullable_to_non_nullable
as bool,editedAtDate: freezed == editedAtDate ? _self.editedAtDate : editedAtDate // ignore: cast_nullable_to_non_nullable
as DateTime?,senderUser: freezed == senderUser ? _self.senderUser : senderUser // ignore: cast_nullable_to_non_nullable
as User?,replyToMessage: freezed == replyToMessage ? _self.replyToMessage : replyToMessage // ignore: cast_nullable_to_non_nullable
as Message?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserCopyWith<$Res>? get senderUser {
    if (_self.senderUser == null) {
    return null;
  }

  return $UserCopyWith<$Res>(_self.senderUser!, (value) {
    return _then(_self.copyWith(senderUser: value));
  });
}/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageCopyWith<$Res>? get replyToMessage {
    if (_self.replyToMessage == null) {
    return null;
  }

  return $MessageCopyWith<$Res>(_self.replyToMessage!, (value) {
    return _then(_self.copyWith(replyToMessage: value));
  });
}
}


/// @nodoc

@JsonSerializable(explicitToJson: true)
class _Message extends Message {
  const _Message({required this.id, @JsonKey(name: 'conversation_id') this.conversation = '', @JsonKey(name: 'sender_user_id') this.sender = '', this.content = '', @JsonKey(name: 'message_type', fromJson: _messageTypeFromJson, toJson: _messageTypeToJson) this.messageType = MessageType.text, @JsonKey(name: 'reply_to_id') this.replyTo = '', final  List<String> attachments = const [], @JsonKey(name: 'read_by') final  Map<String, dynamic> readBy = const {}, final  Map<String, dynamic> reactions = const {}, @JsonKey(name: 'is_edited') this.isEdited = false, @JsonKey(name: 'edited_at')@NullableDateTimeConverter() this.editedAtDate, @JsonKey(name: 'sender') this.senderUser, @JsonKey(name: 'reply_to_message') this.replyToMessage, @JsonKey(name: 'created_at')@NullableDateTimeConverter() this.createdAt, @JsonKey(name: 'updated_at')@NullableDateTimeConverter() this.updatedAt}): _attachments = attachments,_readBy = readBy,_reactions = reactions,super._();
  factory _Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);

@override final  String id;
@override@JsonKey(name: 'conversation_id') final  String conversation;
@override@JsonKey(name: 'sender_user_id') final  String sender;
@override@JsonKey() final  String content;
@override@JsonKey(name: 'message_type', fromJson: _messageTypeFromJson, toJson: _messageTypeToJson) final  MessageType messageType;
@override@JsonKey(name: 'reply_to_id') final  String replyTo;
 final  List<String> _attachments;
@override@JsonKey() List<String> get attachments {
  if (_attachments is EqualUnmodifiableListView) return _attachments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_attachments);
}

 final  Map<String, dynamic> _readBy;
@override@JsonKey(name: 'read_by') Map<String, dynamic> get readBy {
  if (_readBy is EqualUnmodifiableMapView) return _readBy;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_readBy);
}

 final  Map<String, dynamic> _reactions;
@override@JsonKey() Map<String, dynamic> get reactions {
  if (_reactions is EqualUnmodifiableMapView) return _reactions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_reactions);
}

@override@JsonKey(name: 'is_edited') final  bool isEdited;
@override@JsonKey(name: 'edited_at')@NullableDateTimeConverter() final  DateTime? editedAtDate;
@override@JsonKey(name: 'sender') final  User? senderUser;
@override@JsonKey(name: 'reply_to_message') final  Message? replyToMessage;
@override@JsonKey(name: 'created_at')@NullableDateTimeConverter() final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at')@NullableDateTimeConverter() final  DateTime? updatedAt;

/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageCopyWith<_Message> get copyWith => __$MessageCopyWithImpl<_Message>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Message&&(identical(other.id, id) || other.id == id)&&(identical(other.conversation, conversation) || other.conversation == conversation)&&(identical(other.sender, sender) || other.sender == sender)&&(identical(other.content, content) || other.content == content)&&(identical(other.messageType, messageType) || other.messageType == messageType)&&(identical(other.replyTo, replyTo) || other.replyTo == replyTo)&&const DeepCollectionEquality().equals(other._attachments, _attachments)&&const DeepCollectionEquality().equals(other._readBy, _readBy)&&const DeepCollectionEquality().equals(other._reactions, _reactions)&&(identical(other.isEdited, isEdited) || other.isEdited == isEdited)&&(identical(other.editedAtDate, editedAtDate) || other.editedAtDate == editedAtDate)&&(identical(other.senderUser, senderUser) || other.senderUser == senderUser)&&(identical(other.replyToMessage, replyToMessage) || other.replyToMessage == replyToMessage)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,conversation,sender,content,messageType,replyTo,const DeepCollectionEquality().hash(_attachments),const DeepCollectionEquality().hash(_readBy),const DeepCollectionEquality().hash(_reactions),isEdited,editedAtDate,senderUser,replyToMessage,createdAt,updatedAt);

@override
String toString() {
  return 'Message(id: $id, conversation: $conversation, sender: $sender, content: $content, messageType: $messageType, replyTo: $replyTo, attachments: $attachments, readBy: $readBy, reactions: $reactions, isEdited: $isEdited, editedAtDate: $editedAtDate, senderUser: $senderUser, replyToMessage: $replyToMessage, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$MessageCopyWith<$Res> implements $MessageCopyWith<$Res> {
  factory _$MessageCopyWith(_Message value, $Res Function(_Message) _then) = __$MessageCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'conversation_id') String conversation,@JsonKey(name: 'sender_user_id') String sender, String content,@JsonKey(name: 'message_type', fromJson: _messageTypeFromJson, toJson: _messageTypeToJson) MessageType messageType,@JsonKey(name: 'reply_to_id') String replyTo, List<String> attachments,@JsonKey(name: 'read_by') Map<String, dynamic> readBy, Map<String, dynamic> reactions,@JsonKey(name: 'is_edited') bool isEdited,@JsonKey(name: 'edited_at')@NullableDateTimeConverter() DateTime? editedAtDate,@JsonKey(name: 'sender') User? senderUser,@JsonKey(name: 'reply_to_message') Message? replyToMessage,@JsonKey(name: 'created_at')@NullableDateTimeConverter() DateTime? createdAt,@JsonKey(name: 'updated_at')@NullableDateTimeConverter() DateTime? updatedAt
});


@override $UserCopyWith<$Res>? get senderUser;@override $MessageCopyWith<$Res>? get replyToMessage;

}
/// @nodoc
class __$MessageCopyWithImpl<$Res>
    implements _$MessageCopyWith<$Res> {
  __$MessageCopyWithImpl(this._self, this._then);

  final _Message _self;
  final $Res Function(_Message) _then;

/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? conversation = null,Object? sender = null,Object? content = null,Object? messageType = null,Object? replyTo = null,Object? attachments = null,Object? readBy = null,Object? reactions = null,Object? isEdited = null,Object? editedAtDate = freezed,Object? senderUser = freezed,Object? replyToMessage = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_Message(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,conversation: null == conversation ? _self.conversation : conversation // ignore: cast_nullable_to_non_nullable
as String,sender: null == sender ? _self.sender : sender // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,messageType: null == messageType ? _self.messageType : messageType // ignore: cast_nullable_to_non_nullable
as MessageType,replyTo: null == replyTo ? _self.replyTo : replyTo // ignore: cast_nullable_to_non_nullable
as String,attachments: null == attachments ? _self._attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<String>,readBy: null == readBy ? _self._readBy : readBy // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,reactions: null == reactions ? _self._reactions : reactions // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,isEdited: null == isEdited ? _self.isEdited : isEdited // ignore: cast_nullable_to_non_nullable
as bool,editedAtDate: freezed == editedAtDate ? _self.editedAtDate : editedAtDate // ignore: cast_nullable_to_non_nullable
as DateTime?,senderUser: freezed == senderUser ? _self.senderUser : senderUser // ignore: cast_nullable_to_non_nullable
as User?,replyToMessage: freezed == replyToMessage ? _self.replyToMessage : replyToMessage // ignore: cast_nullable_to_non_nullable
as Message?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserCopyWith<$Res>? get senderUser {
    if (_self.senderUser == null) {
    return null;
  }

  return $UserCopyWith<$Res>(_self.senderUser!, (value) {
    return _then(_self.copyWith(senderUser: value));
  });
}/// Create a copy of Message
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MessageCopyWith<$Res>? get replyToMessage {
    if (_self.replyToMessage == null) {
    return null;
  }

  return $MessageCopyWith<$Res>(_self.replyToMessage!, (value) {
    return _then(_self.copyWith(replyToMessage: value));
  });
}
}


/// @nodoc
mixin _$MessageRequest {

 String get content;@JsonKey(name: 'message_type') String get messageType;@JsonKey(name: 'reply_to_id') String? get replyToId; List<String>? get attachments;
/// Create a copy of MessageRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageRequestCopyWith<MessageRequest> get copyWith => _$MessageRequestCopyWithImpl<MessageRequest>(this as MessageRequest, _$identity);

  /// Serializes this MessageRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessageRequest&&(identical(other.content, content) || other.content == content)&&(identical(other.messageType, messageType) || other.messageType == messageType)&&(identical(other.replyToId, replyToId) || other.replyToId == replyToId)&&const DeepCollectionEquality().equals(other.attachments, attachments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,content,messageType,replyToId,const DeepCollectionEquality().hash(attachments));

@override
String toString() {
  return 'MessageRequest(content: $content, messageType: $messageType, replyToId: $replyToId, attachments: $attachments)';
}


}

/// @nodoc
abstract mixin class $MessageRequestCopyWith<$Res>  {
  factory $MessageRequestCopyWith(MessageRequest value, $Res Function(MessageRequest) _then) = _$MessageRequestCopyWithImpl;
@useResult
$Res call({
 String content,@JsonKey(name: 'message_type') String messageType,@JsonKey(name: 'reply_to_id') String? replyToId, List<String>? attachments
});




}
/// @nodoc
class _$MessageRequestCopyWithImpl<$Res>
    implements $MessageRequestCopyWith<$Res> {
  _$MessageRequestCopyWithImpl(this._self, this._then);

  final MessageRequest _self;
  final $Res Function(MessageRequest) _then;

/// Create a copy of MessageRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? content = null,Object? messageType = null,Object? replyToId = freezed,Object? attachments = freezed,}) {
  return _then(_self.copyWith(
content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,messageType: null == messageType ? _self.messageType : messageType // ignore: cast_nullable_to_non_nullable
as String,replyToId: freezed == replyToId ? _self.replyToId : replyToId // ignore: cast_nullable_to_non_nullable
as String?,attachments: freezed == attachments ? _self.attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}

}


/// @nodoc

@JsonSerializable(includeIfNull: false)
class _MessageRequest implements MessageRequest {
  const _MessageRequest({required this.content, @JsonKey(name: 'message_type') this.messageType = 'text', @JsonKey(name: 'reply_to_id') this.replyToId, final  List<String>? attachments}): _attachments = attachments;
  factory _MessageRequest.fromJson(Map<String, dynamic> json) => _$MessageRequestFromJson(json);

@override final  String content;
@override@JsonKey(name: 'message_type') final  String messageType;
@override@JsonKey(name: 'reply_to_id') final  String? replyToId;
 final  List<String>? _attachments;
@override List<String>? get attachments {
  final value = _attachments;
  if (value == null) return null;
  if (_attachments is EqualUnmodifiableListView) return _attachments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of MessageRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageRequestCopyWith<_MessageRequest> get copyWith => __$MessageRequestCopyWithImpl<_MessageRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MessageRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MessageRequest&&(identical(other.content, content) || other.content == content)&&(identical(other.messageType, messageType) || other.messageType == messageType)&&(identical(other.replyToId, replyToId) || other.replyToId == replyToId)&&const DeepCollectionEquality().equals(other._attachments, _attachments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,content,messageType,replyToId,const DeepCollectionEquality().hash(_attachments));

@override
String toString() {
  return 'MessageRequest(content: $content, messageType: $messageType, replyToId: $replyToId, attachments: $attachments)';
}


}

/// @nodoc
abstract mixin class _$MessageRequestCopyWith<$Res> implements $MessageRequestCopyWith<$Res> {
  factory _$MessageRequestCopyWith(_MessageRequest value, $Res Function(_MessageRequest) _then) = __$MessageRequestCopyWithImpl;
@override @useResult
$Res call({
 String content,@JsonKey(name: 'message_type') String messageType,@JsonKey(name: 'reply_to_id') String? replyToId, List<String>? attachments
});




}
/// @nodoc
class __$MessageRequestCopyWithImpl<$Res>
    implements _$MessageRequestCopyWith<$Res> {
  __$MessageRequestCopyWithImpl(this._self, this._then);

  final _MessageRequest _self;
  final $Res Function(_MessageRequest) _then;

/// Create a copy of MessageRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? content = null,Object? messageType = null,Object? replyToId = freezed,Object? attachments = freezed,}) {
  return _then(_MessageRequest(
content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,messageType: null == messageType ? _self.messageType : messageType // ignore: cast_nullable_to_non_nullable
as String,replyToId: freezed == replyToId ? _self.replyToId : replyToId // ignore: cast_nullable_to_non_nullable
as String?,attachments: freezed == attachments ? _self._attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}


}

// dart format on
