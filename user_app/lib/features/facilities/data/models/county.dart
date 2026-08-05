// ignore_for_file: unused_field

import 'package:user_app/shared/models/api_record.dart';
import 'package:user_app/shared/models/base_model.dart';
import 'package:user_app/features/facilities/data/models/district.dart';

/// County model based on backend resource API counties collection
class County extends BaseModel {
  County(super.data);

  /// backend resource API collection name
  static const String collection = 'counties';

  // Self-registration for dynamic model creation
  static final _registered = (() {
    BaseModel.registerModel(collection, (data) => County(data));
    return true;
  })();

  /// Create County from backend resource API record
  static County fromRecord(ApiRecord record) => County(record.data);

  /// Create JSON for new county record (excludes system fields)
  static Map<String, dynamic> forCreate({
    required String name,
    required String districtId,
    String? nhpiCode,
    String? hsdtCode,
  }) {
    return {
      'name': name,
      'district': districtId,
      'nhpi_code': ?nhpiCode,
      'hsdt_code': ?hsdtCode,
    };
  }

  // Direct properties - late final for performance
  late final String name = get<String>("name", "");
  late final String nhpiCode = get<String>("nhpi_code", "");
  late final String hsdtCode = get<String>("hsdt_code", "");

  // Relationship properties
  late final District? district = getRelation<District>("district");
}
