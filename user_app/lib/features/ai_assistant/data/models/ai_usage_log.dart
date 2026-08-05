// ignore_for_file: unused_field

import 'package:user_app/shared/models/api_record.dart';
import 'package:user_app/shared/models/base_model.dart';
import 'package:user_app/features/authentication/data/models/user.dart';

/// AI Assistant usage log model for tracking AI interactions and improving responses
class AiUsageLog extends BaseModel {
  AiUsageLog(super.data);

  /// backend resource API collection name
  static const String collection = 'ai_usage_logs';

  // Self-registration for dynamic model creation
  static final _registered = (() {
    BaseModel.registerModel(collection, (data) => AiUsageLog(data));
    return true;
  })();

  /// Create AiUsageLog from backend resource API record
  static AiUsageLog fromRecord(ApiRecord record) => AiUsageLog(record.data);

  /// Create JSON for new AI usage log record
  static Map<String, dynamic> forCreate({required String userId}) {
    return {'user_id': userId};
  }

  // Direct field properties
  late final String userId = get<String>("user_id", "");

  // Relationship properties
  late final User? user = getRelation<User>("user_id");
}
