import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:user_app/core/utils/json_converters.dart';

part 'my_notification.freezed.dart';
part 'my_notification.g.dart';

@freezed
abstract class MyNotification with _$MyNotification {
  const MyNotification._();

  const factory MyNotification({
    required String id,
    @Default('') String title,
    @Default('') String message,
    @Default('info') String type,
    @JsonKey(name: 'user_id') String? userId,
    @Default('normal') String priority,
    Map<String, dynamic>? action,
    @JsonKey(name: 'action_url') String? actionUrl,
    @JsonKey(name: 'is_read') @Default(false) bool isRead,
    @JsonKey(name: 'created_at')
    @NullableDateTimeConverter()
    DateTime? createdAt,
    @JsonKey(name: 'updated_at')
    @NullableDateTimeConverter()
    DateTime? updatedAt,
  }) = _MyNotification;

  factory MyNotification.fromJson(Map<String, dynamic> json) =>
      _$MyNotificationFromJson(json);

  bool get isGeneralNotification => userId == null || userId!.isEmpty;

  String get typeColor => switch (type) {
    'success' => 'green',
    'warning' => 'orange',
    'error' => 'red',
    _ => 'blue',
  };

  int get priorityLevel => switch (priority) {
    'urgent' => 4,
    'high' => 3,
    'normal' => 2,
    _ => 1,
  };

  String get formattedDate {
    final value = createdAt;
    if (value == null) return 'Unknown';
    final difference = DateTime.now().difference(value);
    if (difference.inDays > 7) {
      return '${value.day}/${value.month}/${value.year}';
    }
    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'Just now';
  }
}
