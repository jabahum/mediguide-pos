// ignore_for_file: unused_field

import 'package:user_app/app/data/models/api_record.dart';
import 'base_model.dart';
import 'ownership_type.dart';

/// Authority model based on legacy collection API authorities collection
class Authority extends BaseModel {
  Authority(super.data);

  /// legacy collection API collection name
  static const String collection = 'authorities';

  // Self-registration for dynamic model creation
  static final _registered = (() {
    BaseModel.registerModel(collection, (data) => Authority(data));
    return true;
  })();

  /// Create Authority from legacy collection API record
  static Authority fromRecord(ApiRecord record) => Authority(record.data);

  /// Create JSON for new authority record (excludes system fields)
  static Map<String, dynamic> forCreate({
    required String name,
    String? code,
    required String ownershipTypeId,
  }) {
    return {'name': name, 'code': ?code, 'ownership_type': ownershipTypeId};
  }

  // Direct properties - late final for performance
  late final String name = get<String>("name", "");
  late final String code = get<String>("code", "");

  // Relationship properties
  late final OwnershipType? ownershipType = getRelation<OwnershipType>(
    "ownership_type",
  );
}
