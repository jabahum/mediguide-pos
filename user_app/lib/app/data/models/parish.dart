// ignore_for_file: unused_field

import 'package:user_app/app/data/models/api_record.dart';
import 'base_model.dart';

/// Parish model based on legacy collection API parishes collection
class Parish extends BaseModel {
  Parish(super.data);

  /// legacy collection API collection name
  static const String collection = 'parishes';

  // Self-registration for dynamic model creation
  static final _registered = (() {
    BaseModel.registerModel(collection, (data) => Parish(data));
    return true;
  })();

  /// Create Parish from legacy collection API record
  static Parish fromRecord(ApiRecord record) => Parish(record.data);

  /// Create JSON for new parish record (excludes system fields)
  static Map<String, dynamic> forCreate({
    required String name,
    String? nhpiCode,
    String? hsdtCode,
    String? subcountyId,
    String? districtId,
  }) {
    return {
      'name': name,
      'nhpi_code': ?nhpiCode,
      'hsdt_code': ?hsdtCode,
      'subcounty': ?subcountyId,
      'district': ?districtId,
    };
  }

  // Direct properties - late final for performance
  late final String name = get<String>("name", "");
  late final String nhpiCode = get<String>("nhpi_code", "");
  late final String hsdtCode = get<String>("hsdt_code", "");
}
