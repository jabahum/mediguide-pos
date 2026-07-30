// ignore_for_file: unused_field

import 'package:user_app/app/data/models/api_record.dart';
import 'base_model.dart';

/// Facility level model based on backend resource API facility_levels collection
class FacilityLevel extends BaseModel {
  FacilityLevel(super.data);

  /// backend resource API collection name
  static const String collection = 'facility_levels';

  // Self-registration for dynamic model creation
  static final _registered = (() {
    BaseModel.registerModel(collection, (data) => FacilityLevel(data));
    return true;
  })();

  /// Create FacilityLevel from backend resource API record
  static FacilityLevel fromRecord(ApiRecord record) =>
      FacilityLevel(record.data);

  /// Create JSON for new facility level record (excludes system fields)
  static Map<String, dynamic> forCreate({
    required String name,
    String? description,
    int? level,
  }) {
    return {'name': name, 'description': ?description, 'level': ?level};
  }

  // Direct properties - late final for performance
  late final String name = get<String>("name", "");
  late final String description = get<String>("description", "");
  late final int level = get<int>("level", 0);
}
