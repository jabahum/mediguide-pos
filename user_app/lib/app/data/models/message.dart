// ignore_for_file: unused_field

import 'package:user_app/app/data/models/api_record.dart';
import 'base_model.dart';
import 'user.dart';

/// Enum for message types matching legacy collection API collection schema
enum MessageType {
  text(label: 'Text'),
  image(label: 'Image'),
  file(label: 'File'),
  voice(label: 'Voice');

  const MessageType({required this.label});

  final String label;
}

/// Message model for chat functionality
class Message extends BaseModel {
  Message(super.data);

  /// legacy collection API collection name
  static const String collection = 'messages';

  // Self-registration for dynamic model creation
  static final _registered = (() {
    BaseModel.registerModel(collection, (data) => Message(data));
    return true;
  })();

  // Ensure registration is triggered
  static void ensureRegistration() {
    // Access _registered to trigger the initialization
    _registered;
  }

  /// Create Message from legacy collection API record
  static Message fromRecord(ApiRecord record) => Message(record.data);

  /// Create JSON for new message record
  static Map<String, dynamic> forCreate({
    required String conversation,
    required String sender,
    required String content,
    MessageType messageType = MessageType.text,
    String? replyTo,
    List<String>? attachments,
    Map<String, dynamic>? readBy,
    Map<String, dynamic>? reactions,
  }) {
    return {
      'conversation': conversation,
      'sender': sender,
      'content': content,
      'message_type': messageType.name,
      'reply_to': ?replyTo,
      'attachments': ?attachments,
      'read_by': ?readBy,
      'reactions': ?reactions,
      'is_edited': false,
    };
  }

  /// Create JSON for updating message
  static Map<String, dynamic> forUpdate({
    String? content,
    Map<String, dynamic>? readBy,
    Map<String, dynamic>? reactions,
    bool? isEdited,
    DateTime? editedAt,
  }) {
    return {
      'content': ?content,
      'read_by': ?readBy,
      'reactions': ?reactions,
      'is_edited': ?isEdited,
      if (editedAt != null) 'edited_at': editedAt.toIso8601String(),
    };
  }

  // Direct properties - late final for performance
  late final String conversation = get<String>("conversation", "");
  late final String sender = get<String>("sender", "");
  late final String content = get<String>("content", "");
  late final String messageTypeString = get<String>("message_type", "text");
  late final String replyTo = get<String>("reply_to", "");
  late final List<String> attachments = get<List<String>>(
    "attachments",
    <String>[],
  );
  late final Map<String, dynamic> readBy = _getMapField("read_by");
  late final Map<String, dynamic> reactions = _getMapField("reactions");
  late final bool isEdited = get<bool>("is_edited", false);
  late final String editedAt = get<String>("edited_at", "");

  // Convenience getters
  late final MessageType messageType = _getMessageType();
  late final DateTime? editedAtDate = _parseDateTime(editedAt);

  // Related models - using expand functionality
  User? get senderUser => getRelation<User>("sender");
  Message? get replyToMessage => getRelation<Message>("reply_to");

  /// Parse message type from string
  MessageType _getMessageType() {
    try {
      return MessageType.values.firstWhere(
        (type) => type.name.toLowerCase() == messageTypeString.toLowerCase(),
        orElse: () => MessageType.text,
      );
    } catch (e) {
      return MessageType.text;
    }
  }

  /// Private helper for date parsing
  DateTime? _parseDateTime(String dateStr) {
    if (dateStr.isEmpty) return null;
    return DateTime.tryParse(dateStr);
  }

  /// Safe helper for getting map fields from legacy collection API
  Map<String, dynamic> _getMapField(String fieldName) {
    try {
      final value = data[fieldName];
      if (value == null) return <String, dynamic>{};

      if (value is Map<String, dynamic>) {
        return value;
      } else if (value is Map) {
        // Convert Map to Map<String, dynamic>
        return Map<String, dynamic>.from(value);
      } else if (value is String && value.isEmpty) {
        return <String, dynamic>{};
      } else {
        // For any other type, return empty map
        return <String, dynamic>{};
      }
    } catch (e) {
      // If there's any casting error, return empty map
      return <String, dynamic>{};
    }
  }

  /// Check if message is read by specific user
  bool isReadBy(String userId) {
    return readBy.containsKey(userId);
  }

  /// Check if message has reactions
  bool get hasReactions => reactions.isNotEmpty;

  /// Get reaction count
  int get reactionCount => reactions.values
      .map((userIds) => userIds is List ? userIds.length : 0)
      .fold(0, (sum, count) => sum + count);

  /// Check if user has reacted with specific emoji
  bool hasUserReacted(String userId, String emoji) {
    final userIds = reactions[emoji];
    return userIds is List && userIds.contains(userId);
  }
}
