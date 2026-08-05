// ignore_for_file: unused_field

import 'package:user_app/shared/models/api_record.dart';
import 'package:user_app/shared/models/base_model.dart';
import 'package:user_app/features/facilities/data/models/region.dart';

/// District model based on backend resource API districts collection
class District extends BaseModel {
  District(super.data);

  /// backend resource API collection name
  static const String collection = 'districts';

  // Self-registration for dynamic model creation
  static final _registered = (() {
    BaseModel.registerModel(collection, (data) => District(data));
    return true;
  })();

  /// Create District from backend resource API record
  static District fromRecord(ApiRecord record) => District(record.data);

  /// Create JSON for new district record (excludes system fields)
  static Map<String, dynamic> forCreate({
    required String name,
    String? description,
    String? regionId,
  }) {
    return {'name': name, 'description': ?description, 'region': ?regionId};
  }

  // Direct properties - late final for performance
  late final String name = get<String>("name", "");
  late final String description = get<String>("description", "");

  // Relationship properties
  late final Region? region = getRelation<Region>("region");
}
