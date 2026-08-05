// ignore_for_file: unused_field

import 'package:user_app/shared/models/api_record.dart';
import 'package:user_app/shared/models/base_model.dart';
import 'package:user_app/features/facilities/data/models/county.dart';
import 'package:user_app/features/facilities/data/models/district.dart';

/// Subcounty model based on backend resource API subcounties collection
class Subcounty extends BaseModel {
  Subcounty(super.data);

  /// backend resource API collection name
  static const String collection = 'subcounties';

  // Self-registration for dynamic model creation
  static final _registered = (() {
    BaseModel.registerModel(collection, (data) => Subcounty(data));
    return true;
  })();

  /// Create Subcounty from backend resource API record
  static Subcounty fromRecord(ApiRecord record) => Subcounty(record.data);

  /// Create JSON for new subcounty record (excludes system fields)
  static Map<String, dynamic> forCreate({
    required String name,
    required String nhpiCode,
    required String hsdtCode,
    required String countyId,
    required String districtId,
  }) {
    return {
      'name': name,
      'nhpi_code': nhpiCode,
      'hsdt_code': hsdtCode,
      'county': countyId,
      'district': districtId,
    };
  }

  // Direct properties - late final for performance
  late final String name = get<String>("name", "");
  late final String nhpiCode = get<String>("nhpi_code", "");
  late final String hsdtCode = get<String>("hsdt_code", "");

  // Relationship properties
  late final County? county = getRelation<County>("county");
  late final District? district = getRelation<District>("district");
}
