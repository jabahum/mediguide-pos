// ignore_for_file: unused_field

import 'package:user_app/app/data/models/api_record.dart';
import 'base_model.dart';
import 'user.dart';
import 'drug.dart';

/// Drug usage log model for tracking drug information access
class DrugUsageLog extends BaseModel {
  DrugUsageLog(super.data);

  /// legacy collection API collection name
  static const String collection = 'drug_usage_logs';

  // Self-registration for dynamic model creation
  static final _registered = (() {
    BaseModel.registerModel(collection, (data) => DrugUsageLog(data));
    return true;
  })();

  /// Create DrugUsageLog from legacy collection API record
  static DrugUsageLog fromRecord(ApiRecord record) => DrugUsageLog(record.data);

  /// Create JSON for new usage log record
  static Map<String, dynamic> forCreate({
    required String userId,
    required String drugId,
  }) {
    return {'user_id': userId, 'drug_id': drugId};
  }

  // Direct field properties
  late final String userId = get<String>("user_id", "");
  late final String drugId = get<String>("drug_id", "");

  // Relationship properties
  late final User? user = getRelation<User>("user_id");
  late final Drug? drug = getRelation<Drug>("drug_id");

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
