import 'package:user_app/shared/models/api_record.dart';
import 'package:user_app/shared/models/base_model.dart';

/// MyNotification model representing a notification from backend resource API
class MyNotification extends BaseModel {
  MyNotification(super.data);

  // Core notification fields
  late final String title = get<String>("title", "");
  late final String message = get<String>("message", "");
  late final String type = get<String>("type", "info");
  late final String? userId = get<String?>("user_id");
  late final String priority = get<String>("priority", "normal");
  late final String? actionUrl = get<String?>("action_url");
  late final bool isRead = get<bool>("is_read", false);

  // Timestamps inherited from BaseModel (created, updated as String)
  // Use createdDate and updatedDate for DateTime values

  /// Factory constructor to create MyNotification from backend resource API record
  static MyNotification fromRecord(ApiRecord record) {
    return MyNotification(record.data);
  }

  /// Check if this is a general notification (no specific user)
  bool get isGeneralNotification => userId == null || userId!.isEmpty;

  /// Get notification type color for UI
  String get typeColor {
    switch (type) {
      case 'success':
        return 'green';
      case 'warning':
        return 'orange';
      case 'error':
        return 'red';
      case 'info':
      default:
        return 'blue';
    }
  }

  /// Get priority level for sorting/display
  int get priorityLevel {
    switch (priority) {
      case 'urgent':
        return 4;
      case 'high':
        return 3;
      case 'normal':
        return 2;
      case 'low':
      default:
        return 1;
    }
  }

  /// Format the created date for display
  String get formattedDate {
    final createdDateTime = createdDate;
    if (createdDateTime == null) return "Unknown";

    final now = DateTime.now();
    final difference = now.difference(createdDateTime);

    if (difference.inDays > 7) {
      return "${createdDateTime.day}/${createdDateTime.month}/${createdDateTime.year}";
    } else if (difference.inDays > 0) {
      return "${difference.inDays}d ago";
    } else if (difference.inHours > 0) {
      return "${difference.inHours}h ago";
    } else if (difference.inMinutes > 0) {
      return "${difference.inMinutes}m ago";
    } else {
      return "Just now";
    }
  }

  @override
  String toString() {
    return 'MyNotification{id: $id, title: $title, type: $type, priority: $priority, created: $created}';
  }
}
