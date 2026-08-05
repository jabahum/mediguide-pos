import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:user_app/core/utils/json_converters.dart';

part 'facility_usage_log.freezed.dart';
part 'facility_usage_log.g.dart';

@freezed
abstract class FacilityUsageLog with _$FacilityUsageLog {
  const FacilityUsageLog._();

  const factory FacilityUsageLog({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'facility_id') required String facilityId,
    @JsonKey(name: 'created_at')
    @NullableDateTimeConverter()
    DateTime? createdAt,
    @JsonKey(name: 'updated_at')
    @NullableDateTimeConverter()
    DateTime? updatedAt,
  }) = _FacilityUsageLog;

  factory FacilityUsageLog.fromJson(Map<String, dynamic> json) =>
      _$FacilityUsageLogFromJson(json);

  DateTime get accessedAt => createdAt ?? DateTime.now();
  String get accessTimeFormatted {
    final difference = DateTime.now().difference(accessedAt);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${(difference.inDays / 7).floor()}w ago';
  }

  String get accessDateFormatted {
    final now = DateTime.now();
    final accessDate = DateTime(
      accessedAt.year,
      accessedAt.month,
      accessedAt.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    if (accessDate == today) return 'Today';
    if (accessDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    }
    return '${accessedAt.day}/${accessedAt.month}/${accessedAt.year}';
  }
}
