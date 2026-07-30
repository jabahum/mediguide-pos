import 'package:user_app/app/data/models/api_record.dart';

/// Model representing a language available in the system
class LanguageModel {
  final String id;
  final String code;
  final String name;
  final String nativeName;
  final bool isActive;
  final bool isDefault;
  final String translationsUrl;
  final Map<String, dynamic> translations;
  final double version;
  final DateTime created;
  final DateTime updated;

  LanguageModel({
    required this.id,
    required this.code,
    required this.name,
    required this.nativeName,
    required this.isActive,
    required this.isDefault,
    required this.translationsUrl,
    required this.translations,
    required this.version,
    DateTime? created,
    DateTime? updated,
  }) : created = created ?? DateTime.fromMillisecondsSinceEpoch(0),
       updated = updated ?? DateTime.fromMillisecondsSinceEpoch(0);

  /// Create from backend resource API record
  factory LanguageModel.fromRecord(ApiRecord record) {
    return LanguageModel(
      id: record.id,
      code: record.getStringValue('code'),
      name: record.getStringValue('name'),
      nativeName: record.getStringValue('native_name'),
      isActive: record.getBoolValue('is_active'),
      isDefault: record.getBoolValue('is_default'),
      translationsUrl: record.getStringValue('translations_url'),
      translations: record.get<Map<String, dynamic>>('translations'),
      version: record.getDoubleValue('version'),
      created:
          DateTime.tryParse(record.get<String>('created')) ?? DateTime.now(),
      updated:
          DateTime.tryParse(record.get<String>('updated')) ?? DateTime.now(),
    );
  }

  /// Create from JSON
  factory LanguageModel.fromJson(Map<String, dynamic> json) {
    return LanguageModel(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      nativeName: json['native_name'] as String,
      isActive: json['is_active'] as bool? ?? true,
      isDefault: json['is_default'] as bool? ?? false,
      translationsUrl: json['translations_url'] as String? ?? '',
      translations: json['translations'] as Map<String, dynamic>? ?? {},
      version: (json['version'] as num?)?.toDouble() ?? 1.0,
      created: json['created'] != null
          ? DateTime.parse(json['created'])
          : DateTime.now(),
      updated: json['updated'] != null
          ? DateTime.parse(json['updated'])
          : DateTime.now(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'native_name': nativeName,
      'is_active': isActive,
      'is_default': isDefault,
      'translations_url': translationsUrl,
      'translations': translations,
      'version': version,
      'created': created.toIso8601String(),
      'updated': updated.toIso8601String(),
    };
  }

  /// Display name for UI (shows native name if different from English name)
  String get displayName {
    if (nativeName != name && nativeName.isNotEmpty) {
      return '$name ($nativeName)';
    }
    return name;
  }

  /// Short display name (just the native name or name)
  String get shortDisplayName {
    return nativeName.isNotEmpty ? nativeName : name;
  }

  /// Whether this language has translations available
  bool get hasTranslations {
    return translations.isNotEmpty || translationsUrl.isNotEmpty;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LanguageModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          code == other.code;

  @override
  int get hashCode => id.hashCode ^ code.hashCode;

  @override
  String toString() {
    return 'LanguageModel{id: $id, code: $code, name: $name, nativeName: $nativeName, isActive: $isActive, isDefault: $isDefault}';
  }

  /// Copy with method for immutable updates
  LanguageModel copyWith({
    String? id,
    String? code,
    String? name,
    String? nativeName,
    bool? isActive,
    bool? isDefault,
    String? translationsUrl,
    Map<String, dynamic>? translations,
    double? version,
    DateTime? created,
    DateTime? updated,
  }) {
    return LanguageModel(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      nativeName: nativeName ?? this.nativeName,
      isActive: isActive ?? this.isActive,
      isDefault: isDefault ?? this.isDefault,
      translationsUrl: translationsUrl ?? this.translationsUrl,
      translations: translations ?? this.translations,
      version: version ?? this.version,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }
}
