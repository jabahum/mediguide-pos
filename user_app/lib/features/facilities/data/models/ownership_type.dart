// ignore_for_file: unused_field

import 'package:user_app/shared/models/api_record.dart';
import 'package:user_app/shared/models/base_model.dart';

/// Ownership type model based on backend resource API ownership_types collection
class OwnershipType extends BaseModel {
  OwnershipType(super.data);

  /// backend resource API collection name
  static const String collection = 'ownership_types';

  // Self-registration for dynamic model creation
  static final _registered = (() {
    BaseModel.registerModel(collection, (data) => OwnershipType(data));
    return true;
  })();

  /// Create OwnershipType from backend resource API record
  static OwnershipType fromRecord(ApiRecord record) =>
      OwnershipType(record.data);

  /// Create JSON for new ownership type record (excludes system fields)
  static Map<String, dynamic> forCreate({
    required String name,
    String? description,
    String? code,
  }) {
    return {'name': name, 'description': ?description, 'code': ?code};
  }

  // Direct properties - late final for performance
  late final String name = get<String>("name", "");
  late final String description = get<String>("description", "");
  late final String code = get<String>("code", "");
}
