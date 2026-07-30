import 'package:user_app/app/data/models/api_record.dart';

/// Base model extending the backend-neutral record with common functionality.
abstract class BaseModel extends ApiRecord {
  BaseModel(super.data);

  /// Each model must define its compatibility API collection name.
  /// This eliminates hardcoded collection names throughout the app
  static String get collection => throw UnimplementedError(
    'Each model must implement static String get collection',
  );

  // Model registry for dynamic model creation
  static final Map<String, BaseModel Function(Map<String, dynamic>)>
  _modelRegistry = {};

  /// Register a model factory for a collection
  static void registerModel(
    String collectionName,
    BaseModel Function(Map<String, dynamic>) factory,
  ) {
    _modelRegistry[collectionName] = factory;
  }

  /// Create a model instance dynamically from collection name (replaces switch statements)
  static T? createModelFromRegistry<T extends BaseModel>(
    Map<String, dynamic> data,
  ) {
    final collectionName = data['collectionName'] as String?;
    if (collectionName == null || collectionName.isEmpty) return null;

    final factory = _modelRegistry[collectionName];
    if (factory == null) return null;

    try {
      return factory(data) as T?;
    } catch (e) {
      return null;
    }
  }

  // Common fields - late final for performance
  @override
  late final String id = get<String>("id", "");

  @override
  late final String collectionId = get<String>("collectionId", "");

  @override
  late final String collectionName = get<String>("collectionName", "");

  @override
  late final String created = get<String>("created", "");

  @override
  late final String updated = get<String>("updated", "");

  // Convenience getters for parsed dates
  late final DateTime? createdDate = _parseDateTime(created);
  late final DateTime? updatedDate = _parseDateTime(updated);

  // Private helper for date parsing
  DateTime? _parseDateTime(String dateStr) {
    if (dateStr.isEmpty) return null;
    return DateTime.tryParse(dateStr);
  }

  // JSON serialization - includes all fields
  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);

  // Helper method to get enum from string value
  T? getEnum<T extends Enum>(String fieldName, List<T> values) {
    final stringValue = get<String>(fieldName, "");
    if (stringValue.isEmpty) return null;

    // Try to find enum by name (handles snake_case to camelCase conversion)
    for (final enumValue in values) {
      final enumName = enumValue.name;
      final snakeCaseName = _camelToSnakeCase(enumName);

      if (stringValue.toLowerCase() == enumName.toLowerCase() ||
          stringValue.toLowerCase() == snakeCaseName.toLowerCase()) {
        return enumValue;
      }
    }

    return null;
  }

  // Helper method to get list of enums from string list
  List<T> getEnumList<T extends Enum>(String fieldName, List<T> values) {
    final stringList = get<List<String>>(fieldName, <String>[]);
    final result = <T>[];

    for (final stringValue in stringList) {
      for (final enumValue in values) {
        final enumName = enumValue.name;
        final snakeCaseName = _camelToSnakeCase(enumName);

        if (stringValue.toLowerCase() == enumName.toLowerCase() ||
            stringValue.toLowerCase() == snakeCaseName.toLowerCase()) {
          result.add(enumValue);
          break;
        }
      }
    }

    return result;
  }

  // Helper method to get related model
  T? getRelation<T extends BaseModel>(String fieldName) {
    try {
      final expandData = data["expand"];
      if (expandData == null || expandData is! Map<String, dynamic>) {
        return null;
      }

      final relatedData = expandData[fieldName];
      if (relatedData == null) {
        return null;
      }

      // Handle both single objects and arrays (legacy collection API can return both)
      Map<String, dynamic>? targetData;

      if (relatedData is Map<String, dynamic>) {
        targetData = relatedData;
      } else if (relatedData is List && relatedData.isNotEmpty) {
        final firstItem = relatedData.first;
        if (firstItem is Map<String, dynamic>) {
          targetData = firstItem;
        }
      }

      if (targetData == null) {
        return null;
      }

      return BaseModel.createModelFromRegistry<T>(targetData);
    } catch (e) {
      return null;
    }
  }

  // Helper method to get list of related models
  List<T> getRelationList<T extends BaseModel>(String fieldName) {
    try {
      final expandData = data["expand"];
      if (expandData == null || expandData is! Map<String, dynamic>) {
        return <T>[];
      }

      final relatedList = expandData[fieldName];
      if (relatedList == null || relatedList is! List) {
        return <T>[];
      }

      final result = <T>[];
      for (final item in relatedList) {
        if (item is Map<String, dynamic>) {
          final model = BaseModel.createModelFromRegistry<T>(item);
          if (model != null) result.add(model);
        }
      }

      return result;
    } catch (e) {
      // Return empty list for graceful degradation
      return <T>[];
    }
  }

  // Helper method to convert camelCase to snake_case
  String _camelToSnakeCase(String camelCase) {
    return camelCase
        .replaceAllMapped(
          RegExp(r'[A-Z]'),
          (match) => '_${match.group(0)!.toLowerCase()}',
        )
        .replaceFirst(RegExp(r'^_'), '');
  }
}
