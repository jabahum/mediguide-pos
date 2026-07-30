// ignore_for_file: unused_field

import 'package:user_app/app/data/models/api_record.dart';
import '../enums/common_enums.dart';
import 'base_model.dart';

/// Guideline category model based on legacy collection API guideline_categories collection
class GuidelineCategory extends BaseModel {
  GuidelineCategory(super.data);

  /// legacy collection API collection name
  static const String collection = 'guideline_categories';

  // Self-registration for dynamic model creation
  static final _registered = (() {
    BaseModel.registerModel(collection, (data) => GuidelineCategory(data));
    return true;
  })();

  /// Create GuidelineCategory from legacy collection API record
  static GuidelineCategory fromRecord(ApiRecord record) =>
      GuidelineCategory(record.data);

  /// Create JSON for new guideline category record (excludes system fields)
  static Map<String, dynamic> forCreate({
    required String name,
    String? slug,
    String? description,
    double? sortOrder,
    Status? status,
    String? color,
    String? icon,
    String? parentCategoryId,
  }) {
    return {
      'name': name,
      'slug': ?slug,
      'description': ?description,
      'sort_order': ?sortOrder,
      'status': (status ?? Status.active).name,
      'color': ?color,
      'icon': ?icon,
      'parent_category': ?parentCategoryId,
    };
  }

  // Direct properties - late final for performance
  late final String name = get<String>("name", "");
  late final String slug = get<String>("slug", "");
  late final String description = get<String>("description", "");
  late final double sortOrder = get<double>("sort_order", 0);
  late final String color = get<String>("color", "");
  late final String icon = get<String>("icon", "");
  late final String parentCategoryId = get<String>("parent_category", "");

  // Enum properties
  late final Status status =
      getEnum<Status>("status", Status.values) ?? Status.active;

  // Relationship properties
  late final GuidelineCategory? parentCategory = _getParentCategory();

  /// Get parent category from expanded data
  GuidelineCategory? _getParentCategory() {
    final parentData = get<Map<String, dynamic>>("expand.parent_category");
    if (parentData.isEmpty) return null;
    return GuidelineCategory.fromRecord(ApiRecord(parentData));
  }

  /// Check if this category has a parent
  bool get hasParent => parentCategoryId.isNotEmpty;

  /// Check if this category is active
  bool get isActive => status == Status.active;

  /// Get display name (falls back to slug if name is empty)
  String get displayName => name.isNotEmpty ? name : slug;
}
