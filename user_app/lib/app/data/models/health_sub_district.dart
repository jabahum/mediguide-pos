// ignore_for_file: unused_field

import 'package:user_app/app/data/models/api_record.dart';
import 'base_model.dart';

/// Health sub-district model based on legacy collection API health_sub_districts collection
class HealthSubDistrict extends BaseModel {
  HealthSubDistrict(super.data);

  /// legacy collection API collection name
  static const String collection = 'health_sub_districts';

  // Self-registration for dynamic model creation
  static final _registered = (() {
    BaseModel.registerModel(collection, (data) => HealthSubDistrict(data));
    return true;
  })();

  /// Create HealthSubDistrict from legacy collection API record
  static HealthSubDistrict fromRecord(ApiRecord record) =>
      HealthSubDistrict(record.data);

  /// Create JSON for new health sub-district record (excludes system fields)
  static Map<String, dynamic> forCreate({
    required String name,
    String? nhpiCode,
    String? hsdtCode,
    String? districtId,
  }) {
    return {
      'name': name,
      'nhpi_code': ?nhpiCode,
      'hsdt_code': ?hsdtCode,
      'district': ?districtId,
    };
  }

  // Direct properties - late final for performance
  late final String name = get<String>("name", "");
  late final String nhpiCode = get<String>("nhpi_code", "");
  late final String hsdtCode = get<String>("hsdt_code", "");
}
