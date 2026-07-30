// ignore_for_file: unused_field

import 'package:user_app/app/data/models/api_record.dart';
import 'base_model.dart';

/// Role model based on backend resource API roles collection
class Role extends BaseModel {
  Role(super.data);

  /// backend resource API collection name
  static const String collection = 'roles';

  // Self-registration for dynamic model creation
  static final _registered = (() {
    BaseModel.registerModel(collection, (data) => Role(data));
    return true;
  })();

  /// Create Role from backend resource API record
  static Role fromRecord(ApiRecord record) => Role(record.data);

  /// Create JSON for new role record (excludes system fields)
  static Map<String, dynamic> forCreate({
    required String name,
    required String key,
    String? description,
    Map<String, dynamic>? permissions,
    bool? isActive,
  }) {
    return {
      'name': name,
      'key': key,
      'description': ?description,
      'permissions': ?permissions,
      'isActive': ?isActive,
    };
  }

  // Direct properties - late final for performance
  late final String name = get<String>("name", "");
  late final String key = get<String>("key", "");
  late final String description = get<String>("description", "");
  late final Map<String, dynamic> permissions = get<Map<String, dynamic>>(
    "permissions",
    {},
  );
  late final bool isActive = get<bool>("isActive", true);
}
