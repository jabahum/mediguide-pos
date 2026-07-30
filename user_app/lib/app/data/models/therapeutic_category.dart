// ignore_for_file: unused_field

import 'package:user_app/app/data/models/api_record.dart';
import '../enums/common_enums.dart';
import 'base_model.dart';

/// Therapeutic category model based on backend resource API therapeutic_categories collection
class TherapeuticCategory extends BaseModel {
  TherapeuticCategory(super.data);

  /// backend resource API collection name
  static const String collection = 'therapeutic_categories';

  // Self-registration for dynamic model creation
  static final _registered = (() {
    BaseModel.registerModel(collection, (data) => TherapeuticCategory(data));
    return true;
  })();

  /// Create TherapeuticCategory from backend resource API record
  static TherapeuticCategory fromRecord(ApiRecord record) =>
      TherapeuticCategory(record.data);

  /// Create JSON for new therapeutic category record (excludes system fields)
  static Map<String, dynamic> forCreate({
    required String name,
    String? description,
    String? color,
    String? icon,
    double? sortOrder,
    Status? status,
  }) {
    return {
      'name': name,
      'description': ?description,
      'color': ?color,
      'icon': ?icon,
      'sort_order': ?sortOrder,
      'status': (status ?? Status.active).name,
    };
  }

  // Direct properties - late final for performance
  late final String name = get<String>("name", "");
  late final String description = get<String>("description", "");
  late final String color = get<String>("color", "");
  late final String icon = get<String>("icon", "");
  late final double sortOrder = get<double>("sort_order", 0);

  // Enum properties
  late final Status status =
      getEnum<Status>("status", Status.values) ?? Status.active;
}
