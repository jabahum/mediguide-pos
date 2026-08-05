// ignore_for_file: unused_field

import 'package:user_app/shared/models/api_record.dart';
import 'package:user_app/shared/models/base_model.dart';

/// Guideline index model for hierarchical organization of medical guidelines
/// Based on backend resource API guideline_index collection with self-referencing structure
class GuidelineIndex extends BaseModel {
  GuidelineIndex(super.data);

  /// backend resource API collection name
  static const String collection = 'guideline_index';

  // Self-registration for dynamic model creation
  static final _registered = (() {
    BaseModel.registerModel(collection, (data) => GuidelineIndex(data));
    return true;
  })();

  /// Create GuidelineIndex from backend resource API record
  static GuidelineIndex fromRecord(ApiRecord record) =>
      GuidelineIndex(record.data);

  /// Create JSON for new guideline index record (excludes system fields)
  static Map<String, dynamic> forCreate({
    required String title,
    String? description,
    String? parentId,
    int? order,
    int? level,
    bool? hasChildren,
  }) {
    return {
      'title': title,
      'description': ?description,
      'parent': ?parentId,
      'order': ?order,
      'level': ?level,
      'hasChildren': ?hasChildren,
    };
  }

  // Direct properties - late final for performance
  late final String title = get<String>("title", "");
  late final String description = get<String>("description", "");
  late final String parentId = get<String>("parent", "");
  late final int order = get<int>("order", 0);
  late final int level = get<int>("level", 0);
  late final bool hasChildren = get<bool>("hasChildren", false);

  /// Check if this index has a parent (not a root level item)
  bool get hasParent => parentId.isNotEmpty;

  /// Check if this is a root level index item
  bool get isRoot => !hasParent;

  /// Get display title (required field so always has value)
  String get displayTitle => title;

  /// Get parent index from expanded data (safely)
  GuidelineIndex? get parent {
    if (!hasParent) return null;

    try {
      // Check if we have expanded parent data
      final expandData = data["expand"];
      if (expandData is Map<String, dynamic>) {
        final parentData = expandData["parent"];
        if (parentData is Map<String, dynamic> && parentData.isNotEmpty) {
          return GuidelineIndex.fromRecord(ApiRecord(parentData));
        }
      }
      return null;
    } catch (e) {
      // Return null if there's any error parsing parent data
      return null;
    }
  }

  /// Check if this index is a Blue Channel item
  bool get isBlueBranch =>
      title == 'Blue Channel' || (hasParent && _isInChannel('Blue Channel'));

  /// Check if this index is a Red Channel item
  bool get isRedBranch =>
      title == 'Red Channel' || (hasParent && _isInChannel('Red Channel'));

  /// Simple helper to check if item is in a specific channel without complex recursion
  bool _isInChannel(String channelTitle) {
    // For now, we'll use a simple approach based on the title
    // This can be enhanced later when we have proper parent IDs stored
    return title.contains(channelTitle) ||
        (hasParent && parent?.title == channelTitle);
  }
}
