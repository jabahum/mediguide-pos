// ignore_for_file: unused_field

import 'package:user_app/shared/models/api_record.dart';
import 'package:user_app/shared/models/base_model.dart';

/// Settings model based on backend resource API settings collection
/// Handles application configuration and settings storage
class Settings extends BaseModel {
  Settings(super.data);

  /// backend resource API collection name
  static const String collection = 'settings';

  // Self-registration for dynamic model creation
  static final _registered = (() {
    BaseModel.registerModel(collection, (data) => Settings(data));
    return true;
  })();

  /// Create Settings from backend resource API record
  static Settings fromRecord(ApiRecord record) => Settings(record.data);

  /// Create JSON for new settings record (excludes system fields)
  static Map<String, dynamic> forCreate({
    required String key,
    required dynamic value,
    String? category,
    String? description,
    bool? isPublic,
  }) {
    return {
      'key': key,
      'value': value,
      'category': ?category,
      'description': ?description,
      'is_public': ?isPublic,
    };
  }

  // Direct properties - late final for performance
  late final String key = get<String>("key", "");
  late final dynamic value = get<dynamic>("value");
  late final String category = get<String>("category", "");
  late final String description = get<String>("description", "");
  late final bool isPublic = get<bool>("is_public", false);

  // Convenience getters for typed value access

  /// Get value as String
  String get stringValue => value?.toString() ?? "";

  /// Get value as int (returns 0 if not valid)
  int get intValue {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Get value as double (returns 0.0 if not valid)
  double get doubleValue {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Get value as bool (returns false if not valid)
  bool get boolValue {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is num) return value != 0;
    return false;
  }

  /// Get value as `List<String>` (returns empty list if not valid)
  List<String> get stringListValue {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return <String>[];
  }

  /// Get value as `Map<String, dynamic>` (returns empty map if not valid)
  Map<String, dynamic> get mapValue {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  /// Get typed value with fallback
  T getTypedValue<T>(T fallback) {
    try {
      if (value is T) return value;
      return fallback;
    } catch (e) {
      return fallback;
    }
  }

  // Helper methods

  /// Check if settings has category
  bool get hasCategory => category.isNotEmpty;

  /// Check if settings has description
  bool get hasDescription => description.isNotEmpty;

  /// Check if this setting is publicly accessible
  bool get isPublicSetting => isPublic;

  /// Check if value is null or empty
  bool get hasValue => value != null;

  /// Get display key (formatted for UI)
  String get displayKey => key
      .replaceAll('_', ' ')
      .split(' ')
      .map(
        (word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '',
      )
      .join(' ');

  /// Get category display name (formatted for UI)
  String get displayCategory => category
      .replaceAll('_', ' ')
      .split(' ')
      .map(
        (word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '',
      )
      .join(' ');

  /// Create a search string for filtering
  String get searchString =>
      "${key.toLowerCase()} ${category.toLowerCase()} ${description.toLowerCase()} ${stringValue.toLowerCase()}";

  /// Check if setting matches search query
  bool matchesSearch(String query) {
    if (query.isEmpty) return true;
    return searchString.contains(query.toLowerCase());
  }

  /// Check if setting belongs to specific category
  bool belongsToCategory(String categoryName) {
    if (categoryName.isEmpty) return true;
    return category.toLowerCase() == categoryName.toLowerCase();
  }

  /// Get value type as string for debugging/display
  String get valueType {
    if (value == null) return 'null';
    if (value is String) return 'string';
    if (value is int) return 'int';
    if (value is double) return 'double';
    if (value is bool) return 'bool';
    if (value is List) return 'list';
    if (value is Map) return 'map';
    return value.runtimeType.toString();
  }

  /// Create a copy of this setting with updated values
  Map<String, dynamic> copyWith({
    String? key,
    dynamic value,
    String? category,
    String? description,
    bool? isPublic,
  }) {
    return {
      'key': key ?? this.key,
      'value': value ?? this.value,
      'category': category ?? this.category,
      'description': description ?? this.description,
      'is_public': isPublic ?? this.isPublic,
    };
  }
}
