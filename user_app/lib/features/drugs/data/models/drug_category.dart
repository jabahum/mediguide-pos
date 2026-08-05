// ignore_for_file: unused_field

import 'package:user_app/shared/models/api_record.dart';
import 'package:user_app/shared/models/common_enums.dart';
import 'package:user_app/shared/models/base_model.dart';

/// Drug category model based on backend resource API drug_categories collection
class DrugCategory extends BaseModel {
  DrugCategory(super.data);

  /// backend resource API collection name
  static const String collection = 'drug_categories';

  // Self-registration for dynamic model creation
  static final _registered = (() {
    BaseModel.registerModel(collection, (data) => DrugCategory(data));
    return true;
  })();

  /// Create DrugCategory from backend resource API record
  static DrugCategory fromRecord(ApiRecord record) => DrugCategory(record.data);

  /// Create JSON for new drug category record (excludes system fields)
  static Map<String, dynamic> forCreate({
    required String name,
    String? description,
    String? color,
    String? icon,
    double? sortOrder,
    Status? status,
    String? parentCategoryId,
  }) {
    return {
      'name': name,
      'description': ?description,
      'color': ?color,
      'icon': ?icon,
      'sort_order': ?sortOrder,
      'status': (status ?? Status.active).name,
      'parent_category': ?parentCategoryId,
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

  // Self-referencing relationship
  late final DrugCategory? parentCategory = getRelation<DrugCategory>(
    "parent_category",
  );
}
