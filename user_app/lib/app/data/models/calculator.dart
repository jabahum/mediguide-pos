// ignore_for_file: unused_field

import 'package:user_app/app/data/models/api_record.dart';
import '../enums/calculator_enums.dart';
import 'base_model.dart';
import 'user.dart';

/// Calculator model based on backend resource API calculators collection
class Calculator extends BaseModel {
  Calculator(super.data);

  /// backend resource API collection name
  static const String collection = 'calculators';

  // Self-registration for dynamic model creation
  static final _registered = (() {
    BaseModel.registerModel(collection, (data) => Calculator(data));
    return true;
  })();

  /// Create Calculator from backend resource API record
  static Calculator fromRecord(ApiRecord record) => Calculator(record.data);

  /// Create JSON for new calculator record (excludes system fields)
  static Map<String, dynamic> forCreate({
    required String name,
    String? description,
    String? icon,
    String? color,
    String? backgroundColor,
    required String appFile,
    required String version,
    required String addedBy,
    required CalculatorType type,
    CalculatorStatus? status,
    int? usageCount,
    bool? featured,
  }) {
    return {
      'name': name,
      'description': ?description,
      'icon': ?icon,
      'color': ?color,
      'backgroundColor': ?backgroundColor,
      'appFile': appFile,
      'version': version,
      'addedBy': addedBy,
      'type': _typeToString(type),
      'status': _statusToString(status ?? CalculatorStatus.draft),
      'usageCount': ?usageCount,
      'featured': ?featured,
    };
  }

  // Direct string properties - late final for performance
  late final String name = get<String>("name", "");
  late final String description = get<String>("description", "");
  late final String icon = get<String>("icon", "");
  late final String color = get<String>("color", "");
  late final String backgroundColor = get<String>("backgroundColor", "");
  late final String appFile = get<String>("appFile", "");
  late final String version = get<String>("version", "");

  // Numeric properties
  late final int usageCount = get<int>("usageCount", 0);

  // Boolean properties
  late final bool featured = get<bool>("featured", false);

  // Enum properties with proper conversion
  late final CalculatorType type =
      _parseType(get<String>("type", "")) ?? CalculatorType.calculator;
  late final CalculatorStatus status =
      _parseStatus(get<String>("status", "")) ?? CalculatorStatus.draft;

  // Relationship properties
  late final User? addedBy = getRelation<User>("addedBy");

  // Helper methods for enum conversion
  static String _typeToString(CalculatorType type) {
    switch (type) {
      case CalculatorType.calculator:
        return 'calculator';
      case CalculatorType.decisionTool:
        return 'decision_tool';
      case CalculatorType.checklist:
        return 'checklist';
    }
  }

  static CalculatorType? _parseType(String value) {
    switch (value.toLowerCase()) {
      case 'calculator':
        return CalculatorType.calculator;
      case 'decision_tool':
        return CalculatorType.decisionTool;
      case 'checklist':
        return CalculatorType.checklist;
      default:
        return null;
    }
  }

  static String _statusToString(CalculatorStatus status) {
    switch (status) {
      case CalculatorStatus.active:
        return 'active';
      case CalculatorStatus.draft:
        return 'draft';
      case CalculatorStatus.archived:
        return 'archived';
    }
  }

  static CalculatorStatus? _parseStatus(String value) {
    switch (value.toLowerCase()) {
      case 'active':
        return CalculatorStatus.active;
      case 'draft':
        return CalculatorStatus.draft;
      case 'archived':
        return CalculatorStatus.archived;
      default:
        return null;
    }
  }

  // Convenience getters
  /// Get the full URL for the app file
  String getAppFileUrl(String baseUrl) {
    if (appFile.isEmpty) return '';
    return '$baseUrl/api/files/$collectionId/$id/$appFile';
  }

  /// Check if calculator is active
  bool get isActive => status == CalculatorStatus.active;

  /// Check if calculator is a draft
  bool get isDraft => status == CalculatorStatus.draft;

  /// Check if calculator is archived
  bool get isArchived => status == CalculatorStatus.archived;

  /// Get display name for type
  String get typeDisplayName {
    switch (type) {
      case CalculatorType.calculator:
        return 'Calculator';
      case CalculatorType.decisionTool:
        return 'Decision Tool';
      case CalculatorType.checklist:
        return 'Checklist';
    }
  }
}
