// ignore_for_file: unused_field

import 'package:user_app/shared/models/api_record.dart';
import 'package:user_app/shared/models/base_model.dart';
import 'package:user_app/features/authentication/data/models/user.dart';
import 'package:user_app/features/facilities/data/models/health_facility.dart';

/// Facility usage log model for tracking health facility information access
class FacilityUsageLog extends BaseModel {
  FacilityUsageLog(super.data);

  /// backend resource API collection name
  static const String collection = 'facility_usage_logs';

  // Self-registration for dynamic model creation
  static final _registered = (() {
    BaseModel.registerModel(collection, (data) => FacilityUsageLog(data));
    return true;
  })();

  /// Create FacilityUsageLog from backend resource API record
  static FacilityUsageLog fromRecord(ApiRecord record) =>
      FacilityUsageLog(record.data);

  /// Create JSON for new usage log record
  static Map<String, dynamic> forCreate({
    required String userId,
    required String facilityId,
  }) {
    return {'user_id': userId, 'facility_id': facilityId};
  }

  // Direct field properties
  late final String userId = get<String>("user_id", "");
  late final String facilityId = get<String>("facility_id", "");

  // Relationship properties
  late final User? user = getRelation<User>("user_id");
  late final HealthFacility? facility = getRelation<HealthFacility>(
    "facility_id",
  );

  // Computed properties

  /// Get access date (uses created field)
  DateTime get accessedAt => createdDate ?? DateTime.now();

  /// Get formatted access time
  String get accessTimeFormatted {
    final now = DateTime.now();
    final difference = now.difference(accessedAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  /// Get access date formatted
  String get accessDateFormatted {
    final now = DateTime.now();
    final accessDate = DateTime(
      accessedAt.year,
      accessedAt.month,
      accessedAt.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (accessDate == today) {
      return 'Today';
    } else if (accessDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${accessedAt.day}/${accessedAt.month}/${accessedAt.year}';
    }
  }
}
