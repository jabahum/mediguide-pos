// GENERATED FILE — DO NOT EDIT.
// Source: backend/docs/swagger.json
// Generator: tool/generate_backend_contracts.dart

import 'dart:collection';

Map<String, dynamic> _jsonMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const <String, dynamic>{};
}

final class HandlersAskEnvelope {
  HandlersAskEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersAskEnvelope.fromJson(Map<String, dynamic> json) =>
      HandlersAskEnvelope(json);

  static const schemaName = 'handlers.AskEnvelope';
  final Map<String, dynamic> value;

  ServicesAskResponse? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ServicesAskResponse.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersCalculatorEnvelope {
  HandlersCalculatorEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersCalculatorEnvelope.fromJson(Map<String, dynamic> json) =>
      HandlersCalculatorEnvelope(json);

  static const schemaName = 'handlers.CalculatorEnvelope';
  final Map<String, dynamic> value;

  ModelsCalculator? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ModelsCalculator.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersCalculatorUsageEnvelope {
  HandlersCalculatorUsageEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersCalculatorUsageEnvelope.fromJson(Map<String, dynamic> json) =>
      HandlersCalculatorUsageEnvelope(json);

  static const schemaName = 'handlers.CalculatorUsageEnvelope';
  final Map<String, dynamic> value;

  ModelsCalculatorUsageLog? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ModelsCalculatorUsageLog.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersClinicalProtocolEnvelope {
  HandlersClinicalProtocolEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersClinicalProtocolEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersClinicalProtocolEnvelope(json);

  static const schemaName = 'handlers.ClinicalProtocolEnvelope';
  final Map<String, dynamic> value;

  ModelsClinicalProtocol? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ModelsClinicalProtocol.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersDownloadURLEnvelope {
  HandlersDownloadURLEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersDownloadURLEnvelope.fromJson(Map<String, dynamic> json) =>
      HandlersDownloadURLEnvelope(json);

  static const schemaName = 'handlers.DownloadURLEnvelope';
  final Map<String, dynamic> value;

  HandlersDownloadURLResult? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return HandlersDownloadURLResult.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersDownloadURLResult {
  HandlersDownloadURLResult(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersDownloadURLResult.fromJson(Map<String, dynamic> json) =>
      HandlersDownloadURLResult(json);

  static const schemaName = 'handlers.DownloadURLResult';
  final Map<String, dynamic> value;

  String? get url => value['url']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersDrugCategoryEnvelope {
  HandlersDrugCategoryEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersDrugCategoryEnvelope.fromJson(Map<String, dynamic> json) =>
      HandlersDrugCategoryEnvelope(json);

  static const schemaName = 'handlers.DrugCategoryEnvelope';
  final Map<String, dynamic> value;

  ModelsDrugCategory? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ModelsDrugCategory.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersDrugClassEnvelope {
  HandlersDrugClassEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersDrugClassEnvelope.fromJson(Map<String, dynamic> json) =>
      HandlersDrugClassEnvelope(json);

  static const schemaName = 'handlers.DrugClassEnvelope';
  final Map<String, dynamic> value;

  ModelsDrugClass? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ModelsDrugClass.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersDrugEnvelope {
  HandlersDrugEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersDrugEnvelope.fromJson(Map<String, dynamic> json) =>
      HandlersDrugEnvelope(json);

  static const schemaName = 'handlers.DrugEnvelope';
  final Map<String, dynamic> value;

  ModelsDrug? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ModelsDrug.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersDrugTagEnvelope {
  HandlersDrugTagEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersDrugTagEnvelope.fromJson(Map<String, dynamic> json) =>
      HandlersDrugTagEnvelope(json);

  static const schemaName = 'handlers.DrugTagEnvelope';
  final Map<String, dynamic> value;

  ModelsDrugTag? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ModelsDrugTag.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersDrugUsageEnvelope {
  HandlersDrugUsageEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersDrugUsageEnvelope.fromJson(Map<String, dynamic> json) =>
      HandlersDrugUsageEnvelope(json);

  static const schemaName = 'handlers.DrugUsageEnvelope';
  final Map<String, dynamic> value;

  ModelsDrugUsageLog? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ModelsDrugUsageLog.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersEmailVerificationConfirmRequest {
  HandlersEmailVerificationConfirmRequest(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersEmailVerificationConfirmRequest.fromJson(
    Map<String, dynamic> json,
  ) => HandlersEmailVerificationConfirmRequest(json);

  static const schemaName = 'handlers.EmailVerificationConfirmRequest';
  final Map<String, dynamic> value;

  String? get token => value['token']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersEmailVerificationRequest {
  HandlersEmailVerificationRequest(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersEmailVerificationRequest.fromJson(
    Map<String, dynamic> json,
  ) => HandlersEmailVerificationRequest(json);

  static const schemaName = 'handlers.EmailVerificationRequest';
  final Map<String, dynamic> value;

  String? get email => value['email']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersErrorResponse {
  HandlersErrorResponse(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersErrorResponse.fromJson(Map<String, dynamic> json) =>
      HandlersErrorResponse(json);

  static const schemaName = 'handlers.ErrorResponse';
  final Map<String, dynamic> value;

  String? get error => value['error']?.toString();

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersGuidelineDocumentEnvelope {
  HandlersGuidelineDocumentEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersGuidelineDocumentEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersGuidelineDocumentEnvelope(json);

  static const schemaName = 'handlers.GuidelineDocumentEnvelope';
  final Map<String, dynamic> value;

  ModelsGuidelineDocument? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ModelsGuidelineDocument.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersGuidelineVersionEnvelope {
  HandlersGuidelineVersionEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersGuidelineVersionEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersGuidelineVersionEnvelope(json);

  static const schemaName = 'handlers.GuidelineVersionEnvelope';
  final Map<String, dynamic> value;

  ModelsGuidelineVersion? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ModelsGuidelineVersion.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersIngestionJobEnvelope {
  HandlersIngestionJobEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersIngestionJobEnvelope.fromJson(Map<String, dynamic> json) =>
      HandlersIngestionJobEnvelope(json);

  static const schemaName = 'handlers.IngestionJobEnvelope';
  final Map<String, dynamic> value;

  ModelsIngestionJob? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ModelsIngestionJob.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersJSONMap {
  HandlersJSONMap(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersJSONMap.fromJson(Map<String, dynamic> json) =>
      HandlersJSONMap(json);

  static const schemaName = 'handlers.JSONMap';
  final Map<String, dynamic> value;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersLanguageEnvelope {
  HandlersLanguageEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersLanguageEnvelope.fromJson(Map<String, dynamic> json) =>
      HandlersLanguageEnvelope(json);

  static const schemaName = 'handlers.LanguageEnvelope';
  final Map<String, dynamic> value;

  ModelsLanguage? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ModelsLanguage.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersLegacyOverviewResult {
  HandlersLegacyOverviewResult(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersLegacyOverviewResult.fromJson(Map<String, dynamic> json) =>
      HandlersLegacyOverviewResult(json);

  static const schemaName = 'handlers.LegacyOverviewResult';
  final Map<String, dynamic> value;

  String? get cachedAt => value['cached_at']?.toString();

  Map<String, dynamic> get contenthealth => _jsonMap(value['contentHealth']);

  Map<String, dynamic> get coverage => _jsonMap(value['coverage']);

  Map<String, dynamic> get engagement => _jsonMap(value['engagement']);

  Map<String, dynamic> get metrics => _jsonMap(value['metrics']);

  Map<String, dynamic> get pipeline => _jsonMap(value['pipeline']);

  Map<String, dynamic> get series => _jsonMap(value['series']);

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> get support => _jsonMap(value['support']);

  Map<String, dynamic> get taxonomy => _jsonMap(value['taxonomy']);

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersLegacyStatsResult {
  HandlersLegacyStatsResult(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersLegacyStatsResult.fromJson(Map<String, dynamic> json) =>
      HandlersLegacyStatsResult(json);

  static const schemaName = 'handlers.LegacyStatsResult';
  final Map<String, dynamic> value;

  int? get abbreviations => (value['abbreviations'] as num?)?.toInt();

  String? get cachedAt => value['cached_at']?.toString();

  int? get calculators => (value['calculators'] as num?)?.toInt();

  int? get consultants => (value['consultants'] as num?)?.toInt();

  int? get drugs => (value['drugs'] as num?)?.toInt();

  int? get faqs => (value['faqs'] as num?)?.toInt();

  int? get healthFacilities => (value['health_facilities'] as num?)?.toInt();

  int? get medicalGuidelines => (value['medical_guidelines'] as num?)?.toInt();

  int? get ministryDirectory => (value['ministry_directory'] as num?)?.toInt();

  bool? get success => value['success'] as bool?;

  int? get totalUsers => (value['total_users'] as num?)?.toInt();

  int? get unreadMessagesCount =>
      (value['unread_messages_count'] as num?)?.toInt();

  int? get userConversationsCount =>
      (value['user_conversations_count'] as num?)?.toInt();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersLegacyTreeResult {
  HandlersLegacyTreeResult(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersLegacyTreeResult.fromJson(Map<String, dynamic> json) =>
      HandlersLegacyTreeResult(json);

  static const schemaName = 'handlers.LegacyTreeResult';
  final Map<String, dynamic> value;

  List<ServicesTreeNode> get data {
    final raw = value['data'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ServicesTreeNode.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  int? get level => (value['level'] as num?)?.toInt();

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersLoginEnvelope {
  HandlersLoginEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersLoginEnvelope.fromJson(Map<String, dynamic> json) =>
      HandlersLoginEnvelope(json);

  static const schemaName = 'handlers.LoginEnvelope';
  final Map<String, dynamic> value;

  ServicesLoginResult? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ServicesLoginResult.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersLoginRequest {
  HandlersLoginRequest(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersLoginRequest.fromJson(Map<String, dynamic> json) =>
      HandlersLoginRequest(json);

  static const schemaName = 'handlers.LoginRequest';
  final Map<String, dynamic> value;

  String? get email => value['email']?.toString();

  String? get password => value['password']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersLogoutEnvelope {
  HandlersLogoutEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersLogoutEnvelope.fromJson(Map<String, dynamic> json) =>
      HandlersLogoutEnvelope(json);

  static const schemaName = 'handlers.LogoutEnvelope';
  final Map<String, dynamic> value;

  HandlersLogoutResult? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return HandlersLogoutResult.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersLogoutResult {
  HandlersLogoutResult(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersLogoutResult.fromJson(Map<String, dynamic> json) =>
      HandlersLogoutResult(json);

  static const schemaName = 'handlers.LogoutResult';
  final Map<String, dynamic> value;

  bool? get loggedOut => value['logged_out'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersManifestEnvelope {
  HandlersManifestEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersManifestEnvelope.fromJson(Map<String, dynamic> json) =>
      HandlersManifestEnvelope(json);

  static const schemaName = 'handlers.ManifestEnvelope';
  final Map<String, dynamic> value;

  ServicesManifestResult? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ServicesManifestResult.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersMarkdownUpdateEnvelope {
  HandlersMarkdownUpdateEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersMarkdownUpdateEnvelope.fromJson(Map<String, dynamic> json) =>
      HandlersMarkdownUpdateEnvelope(json);

  static const schemaName = 'handlers.MarkdownUpdateEnvelope';
  final Map<String, dynamic> value;

  HandlersMarkdownUpdateResult? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return HandlersMarkdownUpdateResult.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersMarkdownUpdateResult {
  HandlersMarkdownUpdateResult(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersMarkdownUpdateResult.fromJson(Map<String, dynamic> json) =>
      HandlersMarkdownUpdateResult(json);

  static const schemaName = 'handlers.MarkdownUpdateResult';
  final Map<String, dynamic> value;

  int? get size => (value['size'] as num?)?.toInt();

  bool? get updated => value['updated'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPaginatedCalculators {
  HandlersPaginatedCalculators(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedCalculators.fromJson(Map<String, dynamic> json) =>
      HandlersPaginatedCalculators(json);

  static const schemaName = 'handlers.PaginatedCalculators';
  final Map<String, dynamic> value;

  List<ModelsCalculator> get items {
    final raw = value['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ModelsCalculator.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  int? get page => (value['page'] as num?)?.toInt();

  int? get perPage => (value['per_page'] as num?)?.toInt();

  int? get totalItems => (value['total_items'] as num?)?.toInt();

  int? get totalPages => (value['total_pages'] as num?)?.toInt();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPaginatedCalculatorsEnvelope {
  HandlersPaginatedCalculatorsEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedCalculatorsEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersPaginatedCalculatorsEnvelope(json);

  static const schemaName = 'handlers.PaginatedCalculatorsEnvelope';
  final Map<String, dynamic> value;

  HandlersPaginatedCalculators? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return HandlersPaginatedCalculators.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPaginatedClinicalProtocols {
  HandlersPaginatedClinicalProtocols(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedClinicalProtocols.fromJson(
    Map<String, dynamic> json,
  ) => HandlersPaginatedClinicalProtocols(json);

  static const schemaName = 'handlers.PaginatedClinicalProtocols';
  final Map<String, dynamic> value;

  List<ModelsClinicalProtocol> get items {
    final raw = value['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ModelsClinicalProtocol.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  int? get page => (value['page'] as num?)?.toInt();

  int? get perPage => (value['per_page'] as num?)?.toInt();

  int? get totalItems => (value['total_items'] as num?)?.toInt();

  int? get totalPages => (value['total_pages'] as num?)?.toInt();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPaginatedClinicalProtocolsEnvelope {
  HandlersPaginatedClinicalProtocolsEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedClinicalProtocolsEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersPaginatedClinicalProtocolsEnvelope(json);

  static const schemaName = 'handlers.PaginatedClinicalProtocolsEnvelope';
  final Map<String, dynamic> value;

  HandlersPaginatedClinicalProtocols? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return HandlersPaginatedClinicalProtocols.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPaginatedDrugCategoriesEnvelope {
  HandlersPaginatedDrugCategoriesEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedDrugCategoriesEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersPaginatedDrugCategoriesEnvelope(json);

  static const schemaName = 'handlers.PaginatedDrugCategoriesEnvelope';
  final Map<String, dynamic> value;

  Map<String, dynamic> get data => _jsonMap(value['data']);

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPaginatedDrugClassesEnvelope {
  HandlersPaginatedDrugClassesEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedDrugClassesEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersPaginatedDrugClassesEnvelope(json);

  static const schemaName = 'handlers.PaginatedDrugClassesEnvelope';
  final Map<String, dynamic> value;

  Map<String, dynamic> get data => _jsonMap(value['data']);

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPaginatedDrugTagsEnvelope {
  HandlersPaginatedDrugTagsEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedDrugTagsEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersPaginatedDrugTagsEnvelope(json);

  static const schemaName = 'handlers.PaginatedDrugTagsEnvelope';
  final Map<String, dynamic> value;

  Map<String, dynamic> get data => _jsonMap(value['data']);

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPaginatedDrugs {
  HandlersPaginatedDrugs(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedDrugs.fromJson(Map<String, dynamic> json) =>
      HandlersPaginatedDrugs(json);

  static const schemaName = 'handlers.PaginatedDrugs';
  final Map<String, dynamic> value;

  List<ModelsDrug> get items {
    final raw = value['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ModelsDrug.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  int? get page => (value['page'] as num?)?.toInt();

  int? get perPage => (value['per_page'] as num?)?.toInt();

  int? get totalItems => (value['total_items'] as num?)?.toInt();

  int? get totalPages => (value['total_pages'] as num?)?.toInt();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPaginatedDrugsEnvelope {
  HandlersPaginatedDrugsEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedDrugsEnvelope.fromJson(Map<String, dynamic> json) =>
      HandlersPaginatedDrugsEnvelope(json);

  static const schemaName = 'handlers.PaginatedDrugsEnvelope';
  final Map<String, dynamic> value;

  HandlersPaginatedDrugs? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return HandlersPaginatedDrugs.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPaginatedGuidelineChunks {
  HandlersPaginatedGuidelineChunks(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedGuidelineChunks.fromJson(
    Map<String, dynamic> json,
  ) => HandlersPaginatedGuidelineChunks(json);

  static const schemaName = 'handlers.PaginatedGuidelineChunks';
  final Map<String, dynamic> value;

  List<ModelsGuidelineChunk> get items {
    final raw = value['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ModelsGuidelineChunk.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  int? get page => (value['page'] as num?)?.toInt();

  int? get perPage => (value['per_page'] as num?)?.toInt();

  int? get totalItems => (value['total_items'] as num?)?.toInt();

  int? get totalPages => (value['total_pages'] as num?)?.toInt();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPaginatedGuidelineChunksEnvelope {
  HandlersPaginatedGuidelineChunksEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedGuidelineChunksEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersPaginatedGuidelineChunksEnvelope(json);

  static const schemaName = 'handlers.PaginatedGuidelineChunksEnvelope';
  final Map<String, dynamic> value;

  HandlersPaginatedGuidelineChunks? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return HandlersPaginatedGuidelineChunks.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPaginatedGuidelineDocuments {
  HandlersPaginatedGuidelineDocuments(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedGuidelineDocuments.fromJson(
    Map<String, dynamic> json,
  ) => HandlersPaginatedGuidelineDocuments(json);

  static const schemaName = 'handlers.PaginatedGuidelineDocuments';
  final Map<String, dynamic> value;

  List<ModelsGuidelineDocument> get items {
    final raw = value['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ModelsGuidelineDocument.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  int? get page => (value['page'] as num?)?.toInt();

  int? get perPage => (value['per_page'] as num?)?.toInt();

  int? get totalItems => (value['total_items'] as num?)?.toInt();

  int? get totalPages => (value['total_pages'] as num?)?.toInt();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPaginatedGuidelineDocumentsEnvelope {
  HandlersPaginatedGuidelineDocumentsEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedGuidelineDocumentsEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersPaginatedGuidelineDocumentsEnvelope(json);

  static const schemaName = 'handlers.PaginatedGuidelineDocumentsEnvelope';
  final Map<String, dynamic> value;

  HandlersPaginatedGuidelineDocuments? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return HandlersPaginatedGuidelineDocuments.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPaginatedGuidelineSections {
  HandlersPaginatedGuidelineSections(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedGuidelineSections.fromJson(
    Map<String, dynamic> json,
  ) => HandlersPaginatedGuidelineSections(json);

  static const schemaName = 'handlers.PaginatedGuidelineSections';
  final Map<String, dynamic> value;

  List<ModelsGuidelineSection> get items {
    final raw = value['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ModelsGuidelineSection.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  int? get page => (value['page'] as num?)?.toInt();

  int? get perPage => (value['per_page'] as num?)?.toInt();

  int? get totalItems => (value['total_items'] as num?)?.toInt();

  int? get totalPages => (value['total_pages'] as num?)?.toInt();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPaginatedGuidelineSectionsEnvelope {
  HandlersPaginatedGuidelineSectionsEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedGuidelineSectionsEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersPaginatedGuidelineSectionsEnvelope(json);

  static const schemaName = 'handlers.PaginatedGuidelineSectionsEnvelope';
  final Map<String, dynamic> value;

  HandlersPaginatedGuidelineSections? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return HandlersPaginatedGuidelineSections.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPaginatedLanguages {
  HandlersPaginatedLanguages(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedLanguages.fromJson(Map<String, dynamic> json) =>
      HandlersPaginatedLanguages(json);

  static const schemaName = 'handlers.PaginatedLanguages';
  final Map<String, dynamic> value;

  List<ModelsLanguage> get items {
    final raw = value['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ModelsLanguage.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  int? get page => (value['page'] as num?)?.toInt();

  int? get perPage => (value['per_page'] as num?)?.toInt();

  int? get totalItems => (value['total_items'] as num?)?.toInt();

  int? get totalPages => (value['total_pages'] as num?)?.toInt();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPaginatedLanguagesEnvelope {
  HandlersPaginatedLanguagesEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedLanguagesEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersPaginatedLanguagesEnvelope(json);

  static const schemaName = 'handlers.PaginatedLanguagesEnvelope';
  final Map<String, dynamic> value;

  HandlersPaginatedLanguages? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return HandlersPaginatedLanguages.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPaginatedRolesEnvelope {
  HandlersPaginatedRolesEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedRolesEnvelope.fromJson(Map<String, dynamic> json) =>
      HandlersPaginatedRolesEnvelope(json);

  static const schemaName = 'handlers.PaginatedRolesEnvelope';
  final Map<String, dynamic> value;

  ServicesPageResultServicesRoleView? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ServicesPageResultServicesRoleView.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPaginatedSettings {
  HandlersPaginatedSettings(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedSettings.fromJson(Map<String, dynamic> json) =>
      HandlersPaginatedSettings(json);

  static const schemaName = 'handlers.PaginatedSettings';
  final Map<String, dynamic> value;

  List<ModelsSetting> get items {
    final raw = value['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ModelsSetting.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  int? get page => (value['page'] as num?)?.toInt();

  int? get perPage => (value['per_page'] as num?)?.toInt();

  int? get totalItems => (value['total_items'] as num?)?.toInt();

  int? get totalPages => (value['total_pages'] as num?)?.toInt();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPaginatedSettingsEnvelope {
  HandlersPaginatedSettingsEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedSettingsEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersPaginatedSettingsEnvelope(json);

  static const schemaName = 'handlers.PaginatedSettingsEnvelope';
  final Map<String, dynamic> value;

  HandlersPaginatedSettings? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return HandlersPaginatedSettings.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPaginatedTherapeuticCategoriesEnvelope {
  HandlersPaginatedTherapeuticCategoriesEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedTherapeuticCategoriesEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersPaginatedTherapeuticCategoriesEnvelope(json);

  static const schemaName = 'handlers.PaginatedTherapeuticCategoriesEnvelope';
  final Map<String, dynamic> value;

  Map<String, dynamic> get data => _jsonMap(value['data']);

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPaginatedUsersEnvelope {
  HandlersPaginatedUsersEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedUsersEnvelope.fromJson(Map<String, dynamic> json) =>
      HandlersPaginatedUsersEnvelope(json);

  static const schemaName = 'handlers.PaginatedUsersEnvelope';
  final Map<String, dynamic> value;

  ServicesPageResultServicesUserView? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ServicesPageResultServicesUserView.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPasswordChangeRequest {
  HandlersPasswordChangeRequest(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPasswordChangeRequest.fromJson(Map<String, dynamic> json) =>
      HandlersPasswordChangeRequest(json);

  static const schemaName = 'handlers.PasswordChangeRequest';
  final Map<String, dynamic> value;

  String? get currentPassword => value['current_password']?.toString();

  String? get newPassword => value['new_password']?.toString();

  String? get newPasswordConfirm => value['new_password_confirm']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPasswordResetConfirmRequest {
  HandlersPasswordResetConfirmRequest(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPasswordResetConfirmRequest.fromJson(
    Map<String, dynamic> json,
  ) => HandlersPasswordResetConfirmRequest(json);

  static const schemaName = 'handlers.PasswordResetConfirmRequest';
  final Map<String, dynamic> value;

  String? get password => value['password']?.toString();

  String? get passwordConfirm => value['password_confirm']?.toString();

  String? get token => value['token']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPasswordResetRequest {
  HandlersPasswordResetRequest(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPasswordResetRequest.fromJson(Map<String, dynamic> json) =>
      HandlersPasswordResetRequest(json);

  static const schemaName = 'handlers.PasswordResetRequest';
  final Map<String, dynamic> value;

  String? get email => value['email']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPermissionDocumentEnvelope {
  HandlersPermissionDocumentEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPermissionDocumentEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersPermissionDocumentEnvelope(json);

  static const schemaName = 'handlers.PermissionDocumentEnvelope';
  final Map<String, dynamic> value;

  Map<String, dynamic> get data => _jsonMap(value['data']);

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPermissionsEnvelope {
  HandlersPermissionsEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPermissionsEnvelope.fromJson(Map<String, dynamic> json) =>
      HandlersPermissionsEnvelope(json);

  static const schemaName = 'handlers.PermissionsEnvelope';
  final Map<String, dynamic> value;

  List<ModelsPermission> get data {
    final raw = value['data'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ModelsPermission.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersProtocolRunEnvelope {
  HandlersProtocolRunEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersProtocolRunEnvelope.fromJson(Map<String, dynamic> json) =>
      HandlersProtocolRunEnvelope(json);

  static const schemaName = 'handlers.ProtocolRunEnvelope';
  final Map<String, dynamic> value;

  ServicesRunProtocolResult? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ServicesRunProtocolResult.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPublishEnvelope {
  HandlersPublishEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPublishEnvelope.fromJson(Map<String, dynamic> json) =>
      HandlersPublishEnvelope(json);

  static const schemaName = 'handlers.PublishEnvelope';
  final Map<String, dynamic> value;

  HandlersPublishResult? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return HandlersPublishResult.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPublishResult {
  HandlersPublishResult(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPublishResult.fromJson(Map<String, dynamic> json) =>
      HandlersPublishResult(json);

  static const schemaName = 'handlers.PublishResult';
  final Map<String, dynamic> value;

  bool? get published => value['published'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersRefreshRequest {
  HandlersRefreshRequest(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersRefreshRequest.fromJson(Map<String, dynamic> json) =>
      HandlersRefreshRequest(json);

  static const schemaName = 'handlers.RefreshRequest';
  final Map<String, dynamic> value;

  String? get refreshToken => value['refresh_token']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersRegisterRequest {
  HandlersRegisterRequest(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersRegisterRequest.fromJson(Map<String, dynamic> json) =>
      HandlersRegisterRequest(json);

  static const schemaName = 'handlers.RegisterRequest';
  final Map<String, dynamic> value;

  String? get address => value['address']?.toString();

  String? get alternativePhone => value['alternative_phone']?.toString();

  String? get avatar => value['avatar']?.toString();

  String? get city => value['city']?.toString();

  String? get country => value['country']?.toString();

  String? get department => value['department']?.toString();

  String? get email => value['email']?.toString();

  String? get facilityId => value['facility_id']?.toString();

  String? get jobTitle => value['job_title']?.toString();

  String? get licenseNumber => value['license_number']?.toString();

  String? get name => value['name']?.toString();

  String? get notes => value['notes']?.toString();

  String? get organization => value['organization']?.toString();

  String? get password => value['password']?.toString();

  String? get phone => value['phone']?.toString();

  String? get postalCode => value['postal_code']?.toString();

  String? get preferredLanguage => value['preferred_language']?.toString();

  List<String> get specialization {
    final raw = value['specialization'];
    if (raw is! List) return const [];
    return raw.whereType<String>().toList(growable: false);
  }

  String? get timezone => value['timezone']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersRolePermissionsRequest {
  HandlersRolePermissionsRequest(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersRolePermissionsRequest.fromJson(Map<String, dynamic> json) =>
      HandlersRolePermissionsRequest(json);

  static const schemaName = 'handlers.RolePermissionsRequest';
  final Map<String, dynamic> value;

  Map<String, dynamic> get permissions => _jsonMap(value['permissions']);

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersRoleViewEnvelope {
  HandlersRoleViewEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersRoleViewEnvelope.fromJson(Map<String, dynamic> json) =>
      HandlersRoleViewEnvelope(json);

  static const schemaName = 'handlers.RoleViewEnvelope';
  final Map<String, dynamic> value;

  ServicesRoleView? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ServicesRoleView.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersSearchResultsEnvelope {
  HandlersSearchResultsEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersSearchResultsEnvelope.fromJson(Map<String, dynamic> json) =>
      HandlersSearchResultsEnvelope(json);

  static const schemaName = 'handlers.SearchResultsEnvelope';
  final Map<String, dynamic> value;

  List<ServicesSearchResult> get data {
    final raw = value['data'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ServicesSearchResult.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersSettingEnvelope {
  HandlersSettingEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersSettingEnvelope.fromJson(Map<String, dynamic> json) =>
      HandlersSettingEnvelope(json);

  static const schemaName = 'handlers.SettingEnvelope';
  final Map<String, dynamic> value;

  ModelsSetting? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ModelsSetting.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersSyncPackageEnvelope {
  HandlersSyncPackageEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersSyncPackageEnvelope.fromJson(Map<String, dynamic> json) =>
      HandlersSyncPackageEnvelope(json);

  static const schemaName = 'handlers.SyncPackageEnvelope';
  final Map<String, dynamic> value;

  ModelsSyncPackage? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ModelsSyncPackage.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersTherapeuticCategoryEnvelope {
  HandlersTherapeuticCategoryEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersTherapeuticCategoryEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersTherapeuticCategoryEnvelope(json);

  static const schemaName = 'handlers.TherapeuticCategoryEnvelope';
  final Map<String, dynamic> value;

  ModelsTherapeuticCategory? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ModelsTherapeuticCategory.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersUpdateMarkdownInput {
  HandlersUpdateMarkdownInput(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersUpdateMarkdownInput.fromJson(Map<String, dynamic> json) =>
      HandlersUpdateMarkdownInput(json);

  static const schemaName = 'handlers.UpdateMarkdownInput';
  final Map<String, dynamic> value;

  String? get content => value['content']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersUserEnvelope {
  HandlersUserEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersUserEnvelope.fromJson(Map<String, dynamic> json) =>
      HandlersUserEnvelope(json);

  static const schemaName = 'handlers.UserEnvelope';
  final Map<String, dynamic> value;

  ModelsUser? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ModelsUser.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersUserViewEnvelope {
  HandlersUserViewEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersUserViewEnvelope.fromJson(Map<String, dynamic> json) =>
      HandlersUserViewEnvelope(json);

  static const schemaName = 'handlers.UserViewEnvelope';
  final Map<String, dynamic> value;

  ServicesUserView? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ServicesUserView.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersVerificationResult {
  HandlersVerificationResult(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersVerificationResult.fromJson(Map<String, dynamic> json) =>
      HandlersVerificationResult(json);

  static const schemaName = 'handlers.VerificationResult';
  final Map<String, dynamic> value;

  bool? get verified => value['verified'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersVerificationResultEnvelope {
  HandlersVerificationResultEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersVerificationResultEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersVerificationResultEnvelope(json);

  static const schemaName = 'handlers.VerificationResultEnvelope';
  final Map<String, dynamic> value;

  HandlersVerificationResult? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return HandlersVerificationResult.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ModelsCalculator {
  ModelsCalculator(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ModelsCalculator.fromJson(Map<String, dynamic> json) =>
      ModelsCalculator(json);

  static const schemaName = 'models.Calculator';
  final Map<String, dynamic> value;

  String? get addedByUserId => value['added_by_user_id']?.toString();

  Map<String, dynamic> get appFileJson => _jsonMap(value['app_file_json']);

  String? get backgroundColor => value['background_color']?.toString();

  String? get color => value['color']?.toString();

  String? get createdAt => value['created_at']?.toString();

  String? get description => value['description']?.toString();

  bool? get featured => value['featured'] as bool?;

  String? get icon => value['icon']?.toString();

  String? get id => value['id']?.toString();

  String? get name => value['name']?.toString();

  String? get status => value['status']?.toString();

  String? get type => value['type']?.toString();

  String? get updatedAt => value['updated_at']?.toString();

  int? get usageCount => (value['usage_count'] as num?)?.toInt();

  String? get version => value['version']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ModelsCalculatorUsageLog {
  ModelsCalculatorUsageLog(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ModelsCalculatorUsageLog.fromJson(Map<String, dynamic> json) =>
      ModelsCalculatorUsageLog(json);

  static const schemaName = 'models.CalculatorUsageLog';
  final Map<String, dynamic> value;

  String? get calculatorId => value['calculator_id']?.toString();

  String? get calculatorType => value['calculator_type']?.toString();

  String? get createdAt => value['created_at']?.toString();

  String? get id => value['id']?.toString();

  String? get sessionEnd => value['session_end']?.toString();

  String? get sessionStart => value['session_start']?.toString();

  String? get updatedAt => value['updated_at']?.toString();

  String? get userId => value['user_id']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ModelsClinicalProtocol {
  ModelsClinicalProtocol(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ModelsClinicalProtocol.fromJson(Map<String, dynamic> json) =>
      ModelsClinicalProtocol(json);

  static const schemaName = 'models.ClinicalProtocol';
  final Map<String, dynamic> value;

  String? get code => value['code']?.toString();

  String? get createdAt => value['created_at']?.toString();

  String? get definitionJson => value['definition_json']?.toString();

  String? get definitionYaml => value['definition_yaml']?.toString();

  String? get id => value['id']?.toString();

  String? get language => value['language']?.toString();

  String? get programArea => value['program_area']?.toString();

  String? get status => value['status']?.toString();

  String? get title => value['title']?.toString();

  String? get updatedAt => value['updated_at']?.toString();

  String? get version => value['version']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ModelsDrug {
  ModelsDrug(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ModelsDrug.fromJson(Map<String, dynamic> json) => ModelsDrug(json);

  static const schemaName = 'models.Drug';
  final Map<String, dynamic> value;

  String? get adultDose => value['adult_dose']?.toString();

  bool? get antimicrobialStatus => value['antimicrobial_status'] as bool?;

  String? get brandNames => value['brand_names']?.toString();

  List<String> get categoriesJson {
    final raw = value['categories_json'];
    if (raw is! List) return const [];
    return raw.whereType<String>().toList(growable: false);
  }

  String? get clinicalNotes => value['clinical_notes']?.toString();

  String? get contraindications => value['contraindications']?.toString();

  String? get controlledSubstance => value['controlled_substance']?.toString();

  String? get createdAt => value['created_at']?.toString();

  String? get description => value['description']?.toString();

  String? get drugClassId => value['drug_class_id']?.toString();

  String? get drugClassName => value['drug_class_name']?.toString();

  String? get duration => value['duration']?.toString();

  String? get elderlyDose => value['elderly_dose']?.toString();

  String? get frequency => value['frequency']?.toString();

  String? get id => value['id']?.toString();

  String? get indications => value['indications']?.toString();

  String? get maxDailyDose => value['max_daily_dose']?.toString();

  String? get mechanismOfAction => value['mechanism_of_action']?.toString();

  String? get monitoringParameters =>
      value['monitoring_parameters']?.toString();

  String? get name => value['name']?.toString();

  String? get pediatricDose => value['pediatric_dose']?.toString();

  String? get pregnancyCategory => value['pregnancy_category']?.toString();

  String? get referenceText => value['reference_text']?.toString();

  String? get reviewStatus => value['review_status']?.toString();

  String? get routeOfAdministration =>
      value['route_of_administration']?.toString();

  String? get searchKeywords => value['search_keywords']?.toString();

  String? get sideEffects => value['side_effects']?.toString();

  String? get status => value['status']?.toString();

  List<String> get tagsJson {
    final raw = value['tags_json'];
    if (raw is! List) return const [];
    return raw.whereType<String>().toList(growable: false);
  }

  String? get therapeuticCategoryId =>
      value['therapeutic_category_id']?.toString();

  String? get therapeuticCategoryName =>
      value['therapeutic_category_name']?.toString();

  String? get updatedAt => value['updated_at']?.toString();

  int? get usageCount => (value['usage_count'] as num?)?.toInt();

  String? get warnings => value['warnings']?.toString();

  bool? get whoEmlStatus => value['who_eml_status'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ModelsDrugCategory {
  ModelsDrugCategory(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ModelsDrugCategory.fromJson(Map<String, dynamic> json) =>
      ModelsDrugCategory(json);

  static const schemaName = 'models.DrugCategory';
  final Map<String, dynamic> value;

  String? get color => value['color']?.toString();

  String? get createdAt => value['created_at']?.toString();

  String? get description => value['description']?.toString();

  String? get icon => value['icon']?.toString();

  String? get id => value['id']?.toString();

  String? get name => value['name']?.toString();

  String? get parentCategoryId => value['parent_category_id']?.toString();

  int? get sortOrder => (value['sort_order'] as num?)?.toInt();

  String? get status => value['status']?.toString();

  String? get updatedAt => value['updated_at']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ModelsDrugClass {
  ModelsDrugClass(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ModelsDrugClass.fromJson(Map<String, dynamic> json) =>
      ModelsDrugClass(json);

  static const schemaName = 'models.DrugClass';
  final Map<String, dynamic> value;

  String? get createdAt => value['created_at']?.toString();

  String? get description => value['description']?.toString();

  String? get id => value['id']?.toString();

  String? get name => value['name']?.toString();

  int? get sortOrder => (value['sort_order'] as num?)?.toInt();

  String? get status => value['status']?.toString();

  String? get updatedAt => value['updated_at']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ModelsDrugTag {
  ModelsDrugTag(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ModelsDrugTag.fromJson(Map<String, dynamic> json) =>
      ModelsDrugTag(json);

  static const schemaName = 'models.DrugTag';
  final Map<String, dynamic> value;

  String? get color => value['color']?.toString();

  String? get createdAt => value['created_at']?.toString();

  String? get description => value['description']?.toString();

  String? get id => value['id']?.toString();

  String? get name => value['name']?.toString();

  int? get sortOrder => (value['sort_order'] as num?)?.toInt();

  String? get status => value['status']?.toString();

  String? get tagCategory => value['tag_category']?.toString();

  String? get updatedAt => value['updated_at']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ModelsDrugUsageLog {
  ModelsDrugUsageLog(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ModelsDrugUsageLog.fromJson(Map<String, dynamic> json) =>
      ModelsDrugUsageLog(json);

  static const schemaName = 'models.DrugUsageLog';
  final Map<String, dynamic> value;

  String? get createdAt => value['created_at']?.toString();

  String? get drugId => value['drug_id']?.toString();

  String? get id => value['id']?.toString();

  String? get updatedAt => value['updated_at']?.toString();

  String? get userId => value['user_id']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ModelsGuidelineChunk {
  ModelsGuidelineChunk(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ModelsGuidelineChunk.fromJson(Map<String, dynamic> json) =>
      ModelsGuidelineChunk(json);

  static const schemaName = 'models.GuidelineChunk';
  final Map<String, dynamic> value;

  String? get content => value['content']?.toString();

  String? get createdAt => value['created_at']?.toString();

  String? get html => value['html']?.toString();

  String? get id => value['id']?.toString();

  String? get language => value['language']?.toString();

  int? get pageEnd => (value['page_end'] as num?)?.toInt();

  int? get pageStart => (value['page_start'] as num?)?.toInt();

  String? get programArea => value['program_area']?.toString();

  String? get reviewStatus => value['review_status']?.toString();

  String? get sectionId => value['section_id']?.toString();

  String? get sourceName => value['source_name']?.toString();

  String? get sourceVersion => value['source_version']?.toString();

  String? get title => value['title']?.toString();

  String? get updatedAt => value['updated_at']?.toString();

  String? get versionId => value['version_id']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ModelsGuidelineDocument {
  ModelsGuidelineDocument(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ModelsGuidelineDocument.fromJson(Map<String, dynamic> json) =>
      ModelsGuidelineDocument(json);

  static const schemaName = 'models.GuidelineDocument';
  final Map<String, dynamic> value;

  String? get country => value['country']?.toString();

  String? get createdAt => value['created_at']?.toString();

  String? get currentVersionId => value['current_version_id']?.toString();

  String? get description => value['description']?.toString();

  String? get id => value['id']?.toString();

  String? get language => value['language']?.toString();

  String? get programArea => value['program_area']?.toString();

  String? get sourceOrg => value['source_org']?.toString();

  String? get title => value['title']?.toString();

  String? get updatedAt => value['updated_at']?.toString();

  List<ModelsGuidelineVersion> get versions {
    final raw = value['versions'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ModelsGuidelineVersion.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ModelsGuidelineSection {
  ModelsGuidelineSection(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ModelsGuidelineSection.fromJson(Map<String, dynamic> json) =>
      ModelsGuidelineSection(json);

  static const schemaName = 'models.GuidelineSection';
  final Map<String, dynamic> value;

  String? get createdAt => value['created_at']?.toString();

  String? get html => value['html']?.toString();

  String? get id => value['id']?.toString();

  int? get level => (value['level'] as num?)?.toInt();

  int? get pageEnd => (value['page_end'] as num?)?.toInt();

  int? get pageStart => (value['page_start'] as num?)?.toInt();

  String? get parentId => value['parent_id']?.toString();

  String? get slug => value['slug']?.toString();

  int? get sortOrder => (value['sort_order'] as num?)?.toInt();

  String? get text => value['text']?.toString();

  String? get title => value['title']?.toString();

  String? get updatedAt => value['updated_at']?.toString();

  String? get versionId => value['version_id']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ModelsGuidelineVersion {
  ModelsGuidelineVersion(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ModelsGuidelineVersion.fromJson(Map<String, dynamic> json) =>
      ModelsGuidelineVersion(json);

  static const schemaName = 'models.GuidelineVersion';
  final Map<String, dynamic> value;

  String? get approvedAt => value['approved_at']?.toString();

  String? get approvedBy => value['approved_by']?.toString();

  String? get checksum => value['checksum']?.toString();

  String? get createdAt => value['created_at']?.toString();

  String? get documentId => value['document_id']?.toString();

  String? get htmlFileKey => value['html_file_key']?.toString();

  String? get id => value['id']?.toString();

  String? get markdownFileKey => value['markdown_file_key']?.toString();

  String? get originalFileKey => value['original_file_key']?.toString();

  String? get publicationDate => value['publication_date']?.toString();

  String? get reviewDate => value['review_date']?.toString();

  List<ModelsGuidelineSection> get sections {
    final raw = value['sections'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ModelsGuidelineSection.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  String? get status => value['status']?.toString();

  String? get updatedAt => value['updated_at']?.toString();

  String? get version => value['version']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ModelsIngestionJob {
  ModelsIngestionJob(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ModelsIngestionJob.fromJson(Map<String, dynamic> json) =>
      ModelsIngestionJob(json);

  static const schemaName = 'models.IngestionJob';
  final Map<String, dynamic> value;

  int? get attemptCount => (value['attempt_count'] as num?)?.toInt();

  String? get completedAt => value['completed_at']?.toString();

  String? get createdAt => value['created_at']?.toString();

  String? get error => value['error']?.toString();

  String? get id => value['id']?.toString();

  String? get jobType => value['job_type']?.toString();

  String? get payloadJson => value['payload_json']?.toString();

  String? get startedAt => value['started_at']?.toString();

  String? get status => value['status']?.toString();

  String? get updatedAt => value['updated_at']?.toString();

  String? get versionId => value['version_id']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ModelsLanguage {
  ModelsLanguage(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ModelsLanguage.fromJson(Map<String, dynamic> json) =>
      ModelsLanguage(json);

  static const schemaName = 'models.Language';
  final Map<String, dynamic> value;

  String? get code => value['code']?.toString();

  String? get createdAt => value['created_at']?.toString();

  bool? get enabledForUsers => value['enabled_for_users'] as bool?;

  String? get id => value['id']?.toString();

  bool? get isActive => value['is_active'] as bool?;

  bool? get isDefault => value['is_default'] as bool?;

  String? get name => value['name']?.toString();

  String? get nativeName => value['native_name']?.toString();

  num? get progress => value['progress'] as num?;

  String? get status => value['status']?.toString();

  Map<String, dynamic> get translationsJson =>
      _jsonMap(value['translations_json']);

  String? get translationsUrl => value['translations_url']?.toString();

  String? get updatedAt => value['updated_at']?.toString();

  num? get version => value['version'] as num?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ModelsPermission {
  ModelsPermission(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ModelsPermission.fromJson(Map<String, dynamic> json) =>
      ModelsPermission(json);

  static const schemaName = 'models.Permission';
  final Map<String, dynamic> value;

  String? get code => value['code']?.toString();

  String? get createdAt => value['created_at']?.toString();

  String? get id => value['id']?.toString();

  String? get name => value['name']?.toString();

  String? get updatedAt => value['updated_at']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ModelsRole {
  ModelsRole(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ModelsRole.fromJson(Map<String, dynamic> json) => ModelsRole(json);

  static const schemaName = 'models.Role';
  final Map<String, dynamic> value;

  String? get createdAt => value['created_at']?.toString();

  String? get description => value['description']?.toString();

  String? get id => value['id']?.toString();

  bool? get isActive => value['is_active'] as bool?;

  String? get name => value['name']?.toString();

  List<ModelsPermission> get permissions {
    final raw = value['permissions'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ModelsPermission.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  Map<String, dynamic> get permissionsJson =>
      _jsonMap(value['permissions_json']);

  String? get roleKey => value['role_key']?.toString();

  String? get updatedAt => value['updated_at']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ModelsSetting {
  ModelsSetting(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ModelsSetting.fromJson(Map<String, dynamic> json) =>
      ModelsSetting(json);

  static const schemaName = 'models.Setting';
  final Map<String, dynamic> value;

  String? get category => value['category']?.toString();

  String? get createdAt => value['created_at']?.toString();

  String? get description => value['description']?.toString();

  String? get id => value['id']?.toString();

  bool? get isPublic => value['is_public'] as bool?;

  String? get key => value['key']?.toString();

  String? get updatedAt => value['updated_at']?.toString();

  Map<String, dynamic> get valueJson => _jsonMap(value['value_json']);

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ModelsSyncPackage {
  ModelsSyncPackage(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ModelsSyncPackage.fromJson(Map<String, dynamic> json) =>
      ModelsSyncPackage(json);

  static const schemaName = 'models.SyncPackage';
  final Map<String, dynamic> value;

  String? get checksum => value['checksum']?.toString();

  String? get createdAt => value['created_at']?.toString();

  String? get fileKey => value['file_key']?.toString();

  String? get id => value['id']?.toString();

  String? get manifestJson => value['manifest_json']?.toString();

  String? get name => value['name']?.toString();

  int? get sizeBytes => (value['size_bytes'] as num?)?.toInt();

  String? get status => value['status']?.toString();

  String? get updatedAt => value['updated_at']?.toString();

  String? get version => value['version']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ModelsTherapeuticCategory {
  ModelsTherapeuticCategory(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ModelsTherapeuticCategory.fromJson(Map<String, dynamic> json) =>
      ModelsTherapeuticCategory(json);

  static const schemaName = 'models.TherapeuticCategory';
  final Map<String, dynamic> value;

  String? get createdAt => value['created_at']?.toString();

  String? get description => value['description']?.toString();

  String? get id => value['id']?.toString();

  String? get name => value['name']?.toString();

  int? get sortOrder => (value['sort_order'] as num?)?.toInt();

  String? get status => value['status']?.toString();

  String? get updatedAt => value['updated_at']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ModelsUser {
  ModelsUser(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ModelsUser.fromJson(Map<String, dynamic> json) => ModelsUser(json);

  static const schemaName = 'models.User';
  final Map<String, dynamic> value;

  String? get address => value['address']?.toString();

  String? get alternativePhone => value['alternative_phone']?.toString();

  String? get avatar => value['avatar']?.toString();

  String? get city => value['city']?.toString();

  String? get country => value['country']?.toString();

  String? get createdAt => value['created_at']?.toString();

  String? get department => value['department']?.toString();

  String? get email => value['email']?.toString();

  String? get facilityId => value['facility_id']?.toString();

  String? get id => value['id']?.toString();

  bool? get isActive => value['is_active'] as bool?;

  String? get jobTitle => value['job_title']?.toString();

  String? get licenseNumber => value['license_number']?.toString();

  String? get name => value['name']?.toString();

  String? get notes => value['notes']?.toString();

  String? get organization => value['organization']?.toString();

  String? get phone => value['phone']?.toString();

  String? get postalCode => value['postal_code']?.toString();

  String? get preferredLanguage => value['preferred_language']?.toString();

  List<ModelsRole> get roles {
    final raw = value['roles'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ModelsRole.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  List<String> get specialization {
    final raw = value['specialization'];
    if (raw is! List) return const [];
    return raw.whereType<String>().toList(growable: false);
  }

  String? get status => value['status']?.toString();

  String? get timezone => value['timezone']?.toString();

  String? get updatedAt => value['updated_at']?.toString();

  bool? get verified => value['verified'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesAccountActionResult {
  ServicesAccountActionResult(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesAccountActionResult.fromJson(Map<String, dynamic> json) =>
      ServicesAccountActionResult(json);

  static const schemaName = 'services.AccountActionResult';
  final Map<String, dynamic> value;

  bool? get accepted => value['accepted'] as bool?;

  bool? get deliveryAccepted => value['delivery_accepted'] as bool?;

  String? get developmentToken => value['development_token']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesAskRequest {
  ServicesAskRequest(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesAskRequest.fromJson(Map<String, dynamic> json) =>
      ServicesAskRequest(json);

  static const schemaName = 'services.AskRequest';
  final Map<String, dynamic> value;

  String? get country => value['country']?.toString();

  String? get language => value['language']?.toString();

  String? get programArea => value['program_area']?.toString();

  String? get question => value['question']?.toString();

  String? get sessionId => value['session_id']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesAskResponse {
  ServicesAskResponse(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesAskResponse.fromJson(Map<String, dynamic> json) =>
      ServicesAskResponse(json);

  static const schemaName = 'services.AskResponse';
  final Map<String, dynamic> value;

  String? get answer => value['answer']?.toString();

  List<ServicesCitation> get citations {
    final raw = value['citations'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ServicesCitation.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  String? get sessionId => value['session_id']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesCitation {
  ServicesCitation(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesCitation.fromJson(Map<String, dynamic> json) =>
      ServicesCitation(json);

  static const schemaName = 'services.Citation';
  final Map<String, dynamic> value;

  String? get chunkId => value['chunk_id']?.toString();

  int? get pageEnd => (value['page_end'] as num?)?.toInt();

  int? get pageStart => (value['page_start'] as num?)?.toInt();

  String? get sourceName => value['source_name']?.toString();

  String? get sourceVersion => value['source_version']?.toString();

  String? get title => value['title']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesCreateCalculatorInput {
  ServicesCreateCalculatorInput(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesCreateCalculatorInput.fromJson(Map<String, dynamic> json) =>
      ServicesCreateCalculatorInput(json);

  static const schemaName = 'services.CreateCalculatorInput';
  final Map<String, dynamic> value;

  Map<String, dynamic> get appFileJson => _jsonMap(value['app_file_json']);

  String? get backgroundColor => value['background_color']?.toString();

  String? get color => value['color']?.toString();

  String? get description => value['description']?.toString();

  bool? get featured => value['featured'] as bool?;

  String? get icon => value['icon']?.toString();

  String? get name => value['name']?.toString();

  String? get status => value['status']?.toString();

  String? get type => value['type']?.toString();

  String? get version => value['version']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesCreateGuidelineInput {
  ServicesCreateGuidelineInput(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesCreateGuidelineInput.fromJson(Map<String, dynamic> json) =>
      ServicesCreateGuidelineInput(json);

  static const schemaName = 'services.CreateGuidelineInput';
  final Map<String, dynamic> value;

  String? get country => value['country']?.toString();

  String? get description => value['description']?.toString();

  String? get language => value['language']?.toString();

  String? get programArea => value['program_area']?.toString();

  String? get sourceOrg => value['source_org']?.toString();

  String? get title => value['title']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesCreateLanguageInput {
  ServicesCreateLanguageInput(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesCreateLanguageInput.fromJson(Map<String, dynamic> json) =>
      ServicesCreateLanguageInput(json);

  static const schemaName = 'services.CreateLanguageInput';
  final Map<String, dynamic> value;

  String? get code => value['code']?.toString();

  bool? get enabledForUsers => value['enabled_for_users'] as bool?;

  bool? get isActive => value['is_active'] as bool?;

  bool? get isDefault => value['is_default'] as bool?;

  String? get name => value['name']?.toString();

  String? get nativeName => value['native_name']?.toString();

  num? get progress => value['progress'] as num?;

  String? get status => value['status']?.toString();

  Map<String, dynamic> get translationsJson =>
      _jsonMap(value['translations_json']);

  String? get translationsUrl => value['translations_url']?.toString();

  num? get version => value['version'] as num?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesCreateProtocolInput {
  ServicesCreateProtocolInput(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesCreateProtocolInput.fromJson(Map<String, dynamic> json) =>
      ServicesCreateProtocolInput(json);

  static const schemaName = 'services.CreateProtocolInput';
  final Map<String, dynamic> value;

  String? get code => value['code']?.toString();

  String? get definitionYaml => value['definition_yaml']?.toString();

  String? get language => value['language']?.toString();

  String? get programArea => value['program_area']?.toString();

  String? get title => value['title']?.toString();

  String? get version => value['version']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesCreateSettingInput {
  ServicesCreateSettingInput(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesCreateSettingInput.fromJson(Map<String, dynamic> json) =>
      ServicesCreateSettingInput(json);

  static const schemaName = 'services.CreateSettingInput';
  final Map<String, dynamic> value;

  String? get category => value['category']?.toString();

  String? get description => value['description']?.toString();

  bool? get isPublic => value['is_public'] as bool?;

  String? get key => value['key']?.toString();

  Map<String, dynamic> get valueJson => _jsonMap(value['value_json']);

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesCreateSyncPackageInput {
  ServicesCreateSyncPackageInput(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesCreateSyncPackageInput.fromJson(Map<String, dynamic> json) =>
      ServicesCreateSyncPackageInput(json);

  static const schemaName = 'services.CreateSyncPackageInput';
  final Map<String, dynamic> value;

  String? get manifestJson => value['manifest_json']?.toString();

  String? get name => value['name']?.toString();

  String? get version => value['version']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesCreateVersionInput {
  ServicesCreateVersionInput(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesCreateVersionInput.fromJson(Map<String, dynamic> json) =>
      ServicesCreateVersionInput(json);

  static const schemaName = 'services.CreateVersionInput';
  final Map<String, dynamic> value;

  String? get publicationDate => value['publication_date']?.toString();

  String? get reviewDate => value['review_date']?.toString();

  String? get version => value['version']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesDrugCategoryInput {
  ServicesDrugCategoryInput(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesDrugCategoryInput.fromJson(Map<String, dynamic> json) =>
      ServicesDrugCategoryInput(json);

  static const schemaName = 'services.DrugCategoryInput';
  final Map<String, dynamic> value;

  String? get color => value['color']?.toString();

  String? get description => value['description']?.toString();

  String? get icon => value['icon']?.toString();

  String? get name => value['name']?.toString();

  String? get parentCategoryId => value['parent_category_id']?.toString();

  int? get sortOrder => (value['sort_order'] as num?)?.toInt();

  String? get status => value['status']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesDrugInput {
  ServicesDrugInput(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesDrugInput.fromJson(Map<String, dynamic> json) =>
      ServicesDrugInput(json);

  static const schemaName = 'services.DrugInput';
  final Map<String, dynamic> value;

  String? get adultDose => value['adult_dose']?.toString();

  bool? get antimicrobialStatus => value['antimicrobial_status'] as bool?;

  String? get brandNames => value['brand_names']?.toString();

  List<String> get categories {
    final raw = value['categories'];
    if (raw is! List) return const [];
    return raw.whereType<String>().toList(growable: false);
  }

  String? get clinicalNotes => value['clinical_notes']?.toString();

  String? get contraindications => value['contraindications']?.toString();

  String? get controlledSubstance => value['controlled_substance']?.toString();

  String? get description => value['description']?.toString();

  String? get drugClassId => value['drug_class_id']?.toString();

  String? get duration => value['duration']?.toString();

  String? get elderlyDose => value['elderly_dose']?.toString();

  String? get frequency => value['frequency']?.toString();

  String? get indications => value['indications']?.toString();

  String? get maxDailyDose => value['max_daily_dose']?.toString();

  String? get mechanismOfAction => value['mechanism_of_action']?.toString();

  String? get monitoringParameters =>
      value['monitoring_parameters']?.toString();

  String? get name => value['name']?.toString();

  String? get pediatricDose => value['pediatric_dose']?.toString();

  String? get pregnancyCategory => value['pregnancy_category']?.toString();

  String? get referenceText => value['reference_text']?.toString();

  String? get reviewStatus => value['review_status']?.toString();

  String? get routeOfAdministration =>
      value['route_of_administration']?.toString();

  String? get searchKeywords => value['search_keywords']?.toString();

  String? get sideEffects => value['side_effects']?.toString();

  String? get status => value['status']?.toString();

  List<String> get tags {
    final raw = value['tags'];
    if (raw is! List) return const [];
    return raw.whereType<String>().toList(growable: false);
  }

  String? get therapeuticCategoryId =>
      value['therapeutic_category_id']?.toString();

  String? get warnings => value['warnings']?.toString();

  bool? get whoEmlStatus => value['who_eml_status'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesDrugNamedReferenceInput {
  ServicesDrugNamedReferenceInput(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesDrugNamedReferenceInput.fromJson(Map<String, dynamic> json) =>
      ServicesDrugNamedReferenceInput(json);

  static const schemaName = 'services.DrugNamedReferenceInput';
  final Map<String, dynamic> value;

  String? get description => value['description']?.toString();

  String? get name => value['name']?.toString();

  int? get sortOrder => (value['sort_order'] as num?)?.toInt();

  String? get status => value['status']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesDrugTagInput {
  ServicesDrugTagInput(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesDrugTagInput.fromJson(Map<String, dynamic> json) =>
      ServicesDrugTagInput(json);

  static const schemaName = 'services.DrugTagInput';
  final Map<String, dynamic> value;

  String? get color => value['color']?.toString();

  String? get description => value['description']?.toString();

  String? get name => value['name']?.toString();

  int? get sortOrder => (value['sort_order'] as num?)?.toInt();

  String? get status => value['status']?.toString();

  String? get tagCategory => value['tag_category']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesFinishCalculatorUsageInput {
  ServicesFinishCalculatorUsageInput(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesFinishCalculatorUsageInput.fromJson(
    Map<String, dynamic> json,
  ) => ServicesFinishCalculatorUsageInput(json);

  static const schemaName = 'services.FinishCalculatorUsageInput';
  final Map<String, dynamic> value;

  String? get sessionEnd => value['session_end']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesLoginResult {
  ServicesLoginResult(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesLoginResult.fromJson(Map<String, dynamic> json) =>
      ServicesLoginResult(json);

  static const schemaName = 'services.LoginResult';
  final Map<String, dynamic> value;

  String? get expiresAt => value['expires_at']?.toString();

  String? get refreshExpiresAt => value['refresh_expires_at']?.toString();

  String? get refreshToken => value['refresh_token']?.toString();

  String? get sessionId => value['session_id']?.toString();

  String? get token => value['token']?.toString();

  ModelsUser? get user {
    final raw = value['user'];
    if (raw is! Map) return null;
    return ModelsUser.fromJson(_jsonMap(raw));
  }

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesManifestResult {
  ServicesManifestResult(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesManifestResult.fromJson(Map<String, dynamic> json) =>
      ServicesManifestResult(json);

  static const schemaName = 'services.ManifestResult';
  final Map<String, dynamic> value;

  String? get generatedAt => value['generated_at']?.toString();

  List<ModelsSyncPackage> get packages {
    final raw = value['packages'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ModelsSyncPackage.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesPageResultServicesRoleView {
  ServicesPageResultServicesRoleView(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesPageResultServicesRoleView.fromJson(
    Map<String, dynamic> json,
  ) => ServicesPageResultServicesRoleView(json);

  static const schemaName = 'services.PageResult-services_RoleView';
  final Map<String, dynamic> value;

  List<ServicesRoleView> get items {
    final raw = value['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ServicesRoleView.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  int? get page => (value['page'] as num?)?.toInt();

  int? get perPage => (value['per_page'] as num?)?.toInt();

  int? get totalItems => (value['total_items'] as num?)?.toInt();

  int? get totalPages => (value['total_pages'] as num?)?.toInt();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesPageResultServicesUserView {
  ServicesPageResultServicesUserView(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesPageResultServicesUserView.fromJson(
    Map<String, dynamic> json,
  ) => ServicesPageResultServicesUserView(json);

  static const schemaName = 'services.PageResult-services_UserView';
  final Map<String, dynamic> value;

  List<ServicesUserView> get items {
    final raw = value['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ServicesUserView.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  int? get page => (value['page'] as num?)?.toInt();

  int? get perPage => (value['per_page'] as num?)?.toInt();

  int? get totalItems => (value['total_items'] as num?)?.toInt();

  int? get totalPages => (value['total_pages'] as num?)?.toInt();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesProtocolStep {
  ServicesProtocolStep(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesProtocolStep.fromJson(Map<String, dynamic> json) =>
      ServicesProtocolStep(json);

  static const schemaName = 'services.ProtocolStep';
  final Map<String, dynamic> value;

  Map<String, dynamic> get citation => _jsonMap(value['citation']);

  String? get id => value['id']?.toString();

  String? get message => value['message']?.toString();

  Map<String, dynamic> get next => _jsonMap(value['next']);

  List<String> get options {
    final raw = value['options'];
    if (raw is! List) return const [];
    return raw.whereType<String>().toList(growable: false);
  }

  String? get question => value['question']?.toString();

  String? get type => value['type']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesRoleInput {
  ServicesRoleInput(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesRoleInput.fromJson(Map<String, dynamic> json) =>
      ServicesRoleInput(json);

  static const schemaName = 'services.RoleInput';
  final Map<String, dynamic> value;

  String? get description => value['description']?.toString();

  bool? get isactive => value['isActive'] as bool?;

  String? get key => value['key']?.toString();

  String? get name => value['name']?.toString();

  Map<String, dynamic> get permissions => _jsonMap(value['permissions']);

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesRoleView {
  ServicesRoleView(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesRoleView.fromJson(Map<String, dynamic> json) =>
      ServicesRoleView(json);

  static const schemaName = 'services.RoleView';
  final Map<String, dynamic> value;

  String? get createdAt => value['created_at']?.toString();

  String? get description => value['description']?.toString();

  String? get id => value['id']?.toString();

  bool? get isactive => value['isActive'] as bool?;

  String? get key => value['key']?.toString();

  String? get name => value['name']?.toString();

  Map<String, dynamic> get permissions => _jsonMap(value['permissions']);

  String? get updatedAt => value['updated_at']?.toString();

  int? get userCount => (value['user_count'] as num?)?.toInt();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesRunProtocolResult {
  ServicesRunProtocolResult(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesRunProtocolResult.fromJson(Map<String, dynamic> json) =>
      ServicesRunProtocolResult(json);

  static const schemaName = 'services.RunProtocolResult';
  final Map<String, dynamic> value;

  ServicesProtocolStep? get currentStep {
    final raw = value['current_step'];
    if (raw is! Map) return null;
    return ServicesProtocolStep.fromJson(_jsonMap(raw));
  }

  Map<String, dynamic> get input => _jsonMap(value['input']);

  String? get note => value['note']?.toString();

  String? get protocol => value['protocol']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesSearchResult {
  ServicesSearchResult(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesSearchResult.fromJson(Map<String, dynamic> json) =>
      ServicesSearchResult(json);

  static const schemaName = 'services.SearchResult';
  final Map<String, dynamic> value;

  String? get id => value['id']?.toString();

  int? get pageEnd => (value['page_end'] as num?)?.toInt();

  int? get pageStart => (value['page_start'] as num?)?.toInt();

  String? get snippet => value['snippet']?.toString();

  String? get sourceName => value['source_name']?.toString();

  String? get sourceVersion => value['source_version']?.toString();

  String? get title => value['title']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesStartCalculatorUsageInput {
  ServicesStartCalculatorUsageInput(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesStartCalculatorUsageInput.fromJson(
    Map<String, dynamic> json,
  ) => ServicesStartCalculatorUsageInput(json);

  static const schemaName = 'services.StartCalculatorUsageInput';
  final Map<String, dynamic> value;

  String? get calculatorType => value['calculator_type']?.toString();

  String? get sessionStart => value['session_start']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesTreeNode {
  ServicesTreeNode(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesTreeNode.fromJson(Map<String, dynamic> json) =>
      ServicesTreeNode(json);

  static const schemaName = 'services.TreeNode';
  final Map<String, dynamic> value;

  int? get count => (value['count'] as num?)?.toInt();

  Map<String, dynamic> get filters => _jsonMap(value['filters']);

  bool? get haschildren => value['hasChildren'] as bool?;

  String? get id => value['id']?.toString();

  int? get level => (value['level'] as num?)?.toInt();

  String? get subtitle => value['subtitle']?.toString();

  String? get title => value['title']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesUpdateCalculatorInput {
  ServicesUpdateCalculatorInput(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesUpdateCalculatorInput.fromJson(Map<String, dynamic> json) =>
      ServicesUpdateCalculatorInput(json);

  static const schemaName = 'services.UpdateCalculatorInput';
  final Map<String, dynamic> value;

  Map<String, dynamic> get appFileJson => _jsonMap(value['app_file_json']);

  String? get backgroundColor => value['background_color']?.toString();

  String? get color => value['color']?.toString();

  String? get description => value['description']?.toString();

  bool? get featured => value['featured'] as bool?;

  String? get icon => value['icon']?.toString();

  String? get name => value['name']?.toString();

  String? get status => value['status']?.toString();

  String? get type => value['type']?.toString();

  String? get version => value['version']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesUpdateGuidelineInput {
  ServicesUpdateGuidelineInput(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesUpdateGuidelineInput.fromJson(Map<String, dynamic> json) =>
      ServicesUpdateGuidelineInput(json);

  static const schemaName = 'services.UpdateGuidelineInput';
  final Map<String, dynamic> value;

  String? get country => value['country']?.toString();

  String? get description => value['description']?.toString();

  String? get language => value['language']?.toString();

  String? get programArea => value['program_area']?.toString();

  String? get sourceOrg => value['source_org']?.toString();

  String? get title => value['title']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesUserCreateInput {
  ServicesUserCreateInput(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesUserCreateInput.fromJson(Map<String, dynamic> json) =>
      ServicesUserCreateInput(json);

  static const schemaName = 'services.UserCreateInput';
  final Map<String, dynamic> value;

  String? get email => value['email']?.toString();

  String? get name => value['name']?.toString();

  String? get password => value['password']?.toString();

  String? get phone => value['phone']?.toString();

  String? get role => value['role']?.toString();

  String? get roleId => value['role_id']?.toString();

  String? get status => value['status']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesUserUpdateInput {
  ServicesUserUpdateInput(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesUserUpdateInput.fromJson(Map<String, dynamic> json) =>
      ServicesUserUpdateInput(json);

  static const schemaName = 'services.UserUpdateInput';
  final Map<String, dynamic> value;

  String? get address => value['address']?.toString();

  String? get alternativePhone => value['alternative_phone']?.toString();

  String? get avatar => value['avatar']?.toString();

  String? get city => value['city']?.toString();

  String? get country => value['country']?.toString();

  String? get department => value['department']?.toString();

  String? get email => value['email']?.toString();

  bool? get isActive => value['is_active'] as bool?;

  String? get jobTitle => value['job_title']?.toString();

  String? get name => value['name']?.toString();

  String? get notes => value['notes']?.toString();

  String? get organization => value['organization']?.toString();

  String? get password => value['password']?.toString();

  String? get phone => value['phone']?.toString();

  String? get postalCode => value['postal_code']?.toString();

  String? get preferredLanguage => value['preferred_language']?.toString();

  String? get role => value['role']?.toString();

  String? get roleId => value['role_id']?.toString();

  List<String> get specialization {
    final raw = value['specialization'];
    if (raw is! List) return const [];
    return raw.whereType<String>().toList(growable: false);
  }

  String? get status => value['status']?.toString();

  String? get timezone => value['timezone']?.toString();

  bool? get verified => value['verified'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesUserView {
  ServicesUserView(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesUserView.fromJson(Map<String, dynamic> json) =>
      ServicesUserView(json);

  static const schemaName = 'services.UserView';
  final Map<String, dynamic> value;

  String? get address => value['address']?.toString();

  String? get alternativePhone => value['alternative_phone']?.toString();

  String? get avatar => value['avatar']?.toString();

  String? get city => value['city']?.toString();

  String? get country => value['country']?.toString();

  String? get createdAt => value['created_at']?.toString();

  String? get department => value['department']?.toString();

  String? get email => value['email']?.toString();

  String? get facilityId => value['facility_id']?.toString();

  String? get id => value['id']?.toString();

  bool? get isActive => value['is_active'] as bool?;

  String? get jobTitle => value['job_title']?.toString();

  String? get licenseNumber => value['license_number']?.toString();

  String? get name => value['name']?.toString();

  String? get notes => value['notes']?.toString();

  String? get organization => value['organization']?.toString();

  String? get phone => value['phone']?.toString();

  String? get postalCode => value['postal_code']?.toString();

  String? get preferredLanguage => value['preferred_language']?.toString();

  String? get role => value['role']?.toString();

  String? get roleId => value['role_id']?.toString();

  List<ModelsRole> get roles {
    final raw = value['roles'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ModelsRole.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  List<String> get specialization {
    final raw = value['specialization'];
    if (raw is! List) return const [];
    return raw.whereType<String>().toList(growable: false);
  }

  String? get status => value['status']?.toString();

  String? get timezone => value['timezone']?.toString();

  String? get updatedAt => value['updated_at']?.toString();

  bool? get verified => value['verified'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}
