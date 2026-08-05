// ignore_for_file: unused_field

import 'package:user_app/shared/models/api_record.dart';
import 'package:user_app/shared/models/base_model.dart';

/// Guideline tag model based on backend resource API guideline_tags collection
class GuidelineTag extends BaseModel {
  GuidelineTag(super.data);

  /// backend resource API collection name
  static const String collection = 'guideline_tags';

  // Self-registration for dynamic model creation
  static final _registered = (() {
    BaseModel.registerModel(collection, (data) => GuidelineTag(data));
    return true;
  })();

  /// Create GuidelineTag from backend resource API record
  static GuidelineTag fromRecord(ApiRecord record) => GuidelineTag(record.data);

  /// Create JSON for new guideline tag record (excludes system fields)
  static Map<String, dynamic> forCreate({
    required String name,
    String? description,
  }) {
    return {'name': name, 'description': ?description};
  }

  // Direct properties - late final for performance
  late final String name = get<String>("name", "");
  late final String description = get<String>("description", "");

  /// Get display name
  String get displayName => name;

  /// Check if tag has description
  bool get hasDescription => description.isNotEmpty;
}
