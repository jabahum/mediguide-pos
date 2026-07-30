// ignore_for_file: unused_field

import 'package:user_app/app/data/models/api_record.dart';
import 'base_model.dart';
import 'region.dart';

/// Health sub-region model based on backend resource API health_sub_regions collection
class HealthSubRegion extends BaseModel {
  HealthSubRegion(super.data);

  /// backend resource API collection name
  static const String collection = 'health_sub_regions';

  // Self-registration for dynamic model creation
  static final _registered = (() {
    BaseModel.registerModel(collection, (data) => HealthSubRegion(data));
    return true;
  })();

  /// Create HealthSubRegion from backend resource API record
  static HealthSubRegion fromRecord(ApiRecord record) =>
      HealthSubRegion(record.data);

  /// Create JSON for new health sub-region record (excludes system fields)
  static Map<String, dynamic> forCreate({
    required String name,
    required String nhpiCode,
    required String hsdtCode,
    required String regionId,
  }) {
    return {
      'name': name,
      'nhpi_code': nhpiCode,
      'hsdt_code': hsdtCode,
      'region': regionId,
    };
  }

  // Direct properties - late final for performance
  late final String name = get<String>("name", "");
  late final String nhpiCode = get<String>("nhpi_code", "");
  late final String hsdtCode = get<String>("hsdt_code", "");

  // Relationship properties
  late final Region? region = getRelation<Region>("region");
}
