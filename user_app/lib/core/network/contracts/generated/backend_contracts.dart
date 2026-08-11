// GENERATED FILE — DO NOT EDIT.
// Source: backend/docs/swagger.json
// Generator: tool/generate_backend_contracts.dart

import 'dart:collection';

Map<String, dynamic> _jsonMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const <String, dynamic>{};
}

final class HandlersAbbreviationEnvelope {
  HandlersAbbreviationEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersAbbreviationEnvelope.fromJson(Map<String, dynamic> json) =>
      HandlersAbbreviationEnvelope(json);

  static const schemaName = 'handlers.AbbreviationEnvelope';
  final Map<String, dynamic> value;

  ModelsAbbreviation? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ModelsAbbreviation.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
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

final class HandlersConversationEnvelope {
  HandlersConversationEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersConversationEnvelope.fromJson(Map<String, dynamic> json) =>
      HandlersConversationEnvelope(json);

  static const schemaName = 'handlers.ConversationEnvelope';
  final Map<String, dynamic> value;

  ServicesConversationView? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ServicesConversationView.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersDocumentationEnvelope {
  HandlersDocumentationEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersDocumentationEnvelope.fromJson(Map<String, dynamic> json) =>
      HandlersDocumentationEnvelope(json);

  static const schemaName = 'handlers.DocumentationEnvelope';
  final Map<String, dynamic> value;

  ModelsDocumentation? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ModelsDocumentation.fromJson(_jsonMap(raw));
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

final class HandlersEmergencyProtocolEnvelope {
  HandlersEmergencyProtocolEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersEmergencyProtocolEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersEmergencyProtocolEnvelope(json);

  static const schemaName = 'handlers.EmergencyProtocolEnvelope';
  final Map<String, dynamic> value;

  ModelsEmergencyProtocol? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ModelsEmergencyProtocol.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

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

final class HandlersFAQEnvelope {
  HandlersFAQEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersFAQEnvelope.fromJson(Map<String, dynamic> json) =>
      HandlersFAQEnvelope(json);

  static const schemaName = 'handlers.FAQEnvelope';
  final Map<String, dynamic> value;

  ModelsFAQ? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ModelsFAQ.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersFAQTagEnvelope {
  HandlersFAQTagEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersFAQTagEnvelope.fromJson(Map<String, dynamic> json) =>
      HandlersFAQTagEnvelope(json);

  static const schemaName = 'handlers.FAQTagEnvelope';
  final Map<String, dynamic> value;

  ModelsFAQTag? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ModelsFAQTag.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersGenericPageEnvelope {
  HandlersGenericPageEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersGenericPageEnvelope.fromJson(Map<String, dynamic> json) =>
      HandlersGenericPageEnvelope(json);

  static const schemaName = 'handlers.GenericPageEnvelope';
  final Map<String, dynamic> value;

  ModelsGenericPage? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ModelsGenericPage.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersGuidelineAssetEnvelope {
  HandlersGuidelineAssetEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersGuidelineAssetEnvelope.fromJson(Map<String, dynamic> json) =>
      HandlersGuidelineAssetEnvelope(json);

  static const schemaName = 'handlers.GuidelineAssetEnvelope';
  final Map<String, dynamic> value;

  ModelsGuidelineAsset? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ModelsGuidelineAsset.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersGuidelineCategoryEnvelope {
  HandlersGuidelineCategoryEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersGuidelineCategoryEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersGuidelineCategoryEnvelope(json);

  static const schemaName = 'handlers.GuidelineCategoryEnvelope';
  final Map<String, dynamic> value;

  ModelsGuidelineCategory? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ModelsGuidelineCategory.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersGuidelineCollectionEnvelope {
  HandlersGuidelineCollectionEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersGuidelineCollectionEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersGuidelineCollectionEnvelope(json);

  static const schemaName = 'handlers.GuidelineCollectionEnvelope';
  final Map<String, dynamic> value;

  ServicesGuidelineCollectionDTO? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ServicesGuidelineCollectionDTO.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersGuidelineContentBlockEnvelope {
  HandlersGuidelineContentBlockEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersGuidelineContentBlockEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersGuidelineContentBlockEnvelope(json);

  static const schemaName = 'handlers.GuidelineContentBlockEnvelope';
  final Map<String, dynamic> value;

  ModelsGuidelineContentBlock? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ModelsGuidelineContentBlock.fromJson(_jsonMap(raw));
  }

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

final class HandlersGuidelineDownloadEnvelope {
  HandlersGuidelineDownloadEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersGuidelineDownloadEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersGuidelineDownloadEnvelope(json);

  static const schemaName = 'handlers.GuidelineDownloadEnvelope';
  final Map<String, dynamic> value;

  ServicesGuidelineDownloadDTO? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ServicesGuidelineDownloadDTO.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersGuidelineExtractionStatusEnvelope {
  HandlersGuidelineExtractionStatusEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersGuidelineExtractionStatusEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersGuidelineExtractionStatusEnvelope(json);

  static const schemaName = 'handlers.GuidelineExtractionStatusEnvelope';
  final Map<String, dynamic> value;

  ServicesGuidelineExtractionStatus? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ServicesGuidelineExtractionStatus.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersGuidelineIndexEnvelope {
  HandlersGuidelineIndexEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersGuidelineIndexEnvelope.fromJson(Map<String, dynamic> json) =>
      HandlersGuidelineIndexEnvelope(json);

  static const schemaName = 'handlers.GuidelineIndexEnvelope';
  final Map<String, dynamic> value;

  ModelsGuidelineIndexEntry? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ModelsGuidelineIndexEntry.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersGuidelinePreviewEnvelope {
  HandlersGuidelinePreviewEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersGuidelinePreviewEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersGuidelinePreviewEnvelope(json);

  static const schemaName = 'handlers.GuidelinePreviewEnvelope';
  final Map<String, dynamic> value;

  ServicesGuidelinePreview? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ServicesGuidelinePreview.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersGuidelineSectionEnvelope {
  HandlersGuidelineSectionEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersGuidelineSectionEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersGuidelineSectionEnvelope(json);

  static const schemaName = 'handlers.GuidelineSectionEnvelope';
  final Map<String, dynamic> value;

  ModelsGuidelineSection? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ModelsGuidelineSection.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersGuidelineTagEnvelope {
  HandlersGuidelineTagEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersGuidelineTagEnvelope.fromJson(Map<String, dynamic> json) =>
      HandlersGuidelineTagEnvelope(json);

  static const schemaName = 'handlers.GuidelineTagEnvelope';
  final Map<String, dynamic> value;

  ModelsGuidelineTag? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ModelsGuidelineTag.fromJson(_jsonMap(raw));
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

final class HandlersMarkdownDraftEnvelope {
  HandlersMarkdownDraftEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersMarkdownDraftEnvelope.fromJson(Map<String, dynamic> json) =>
      HandlersMarkdownDraftEnvelope(json);

  static const schemaName = 'handlers.MarkdownDraftEnvelope';
  final Map<String, dynamic> value;

  ServicesMarkdownDraft? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ServicesMarkdownDraft.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersMarkdownRegenerationEnvelope {
  HandlersMarkdownRegenerationEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersMarkdownRegenerationEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersMarkdownRegenerationEnvelope(json);

  static const schemaName = 'handlers.MarkdownRegenerationEnvelope';
  final Map<String, dynamic> value;

  ServicesMarkdownRegenerationResult? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ServicesMarkdownRegenerationResult.fromJson(_jsonMap(raw));
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

  String? get jobId => value['job_id']?.toString();

  bool? get queued => value['queued'] as bool?;

  int? get size => (value['size'] as num?)?.toInt();

  bool? get updated => value['updated'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersMedicalGuidelineEnvelope {
  HandlersMedicalGuidelineEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersMedicalGuidelineEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersMedicalGuidelineEnvelope(json);

  static const schemaName = 'handlers.MedicalGuidelineEnvelope';
  final Map<String, dynamic> value;

  ModelsMedicalGuideline? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ModelsMedicalGuideline.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersMessageEnvelope {
  HandlersMessageEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersMessageEnvelope.fromJson(Map<String, dynamic> json) =>
      HandlersMessageEnvelope(json);

  static const schemaName = 'handlers.MessageEnvelope';
  final Map<String, dynamic> value;

  ServicesMessageView? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ServicesMessageView.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersMinistryDirectoryEnvelope {
  HandlersMinistryDirectoryEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersMinistryDirectoryEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersMinistryDirectoryEnvelope(json);

  static const schemaName = 'handlers.MinistryDirectoryEnvelope';
  final Map<String, dynamic> value;

  ModelsMinistryDirectoryEntry? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ModelsMinistryDirectoryEntry.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersNotificationCampaignEnvelope {
  HandlersNotificationCampaignEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersNotificationCampaignEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersNotificationCampaignEnvelope(json);

  static const schemaName = 'handlers.NotificationCampaignEnvelope';
  final Map<String, dynamic> value;

  ModelsNotificationCampaign? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ModelsNotificationCampaign.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersNotificationEnvelope {
  HandlersNotificationEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersNotificationEnvelope.fromJson(Map<String, dynamic> json) =>
      HandlersNotificationEnvelope(json);

  static const schemaName = 'handlers.NotificationEnvelope';
  final Map<String, dynamic> value;

  ModelsNotification? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ModelsNotification.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersNotificationStatusInput {
  HandlersNotificationStatusInput(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersNotificationStatusInput.fromJson(Map<String, dynamic> json) =>
      HandlersNotificationStatusInput(json);

  static const schemaName = 'handlers.NotificationStatusInput';
  final Map<String, dynamic> value;

  String? get status => value['status']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersNotificationTemplateEnvelope {
  HandlersNotificationTemplateEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersNotificationTemplateEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersNotificationTemplateEnvelope(json);

  static const schemaName = 'handlers.NotificationTemplateEnvelope';
  final Map<String, dynamic> value;

  ModelsNotificationTemplate? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ModelsNotificationTemplate.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPaginatedAbbreviationsEnvelope {
  HandlersPaginatedAbbreviationsEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedAbbreviationsEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersPaginatedAbbreviationsEnvelope(json);

  static const schemaName = 'handlers.PaginatedAbbreviationsEnvelope';
  final Map<String, dynamic> value;

  ServicesPageResultModelsAbbreviation? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ServicesPageResultModelsAbbreviation.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

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

final class HandlersPaginatedConversationsEnvelope {
  HandlersPaginatedConversationsEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedConversationsEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersPaginatedConversationsEnvelope(json);

  static const schemaName = 'handlers.PaginatedConversationsEnvelope';
  final Map<String, dynamic> value;

  ServicesPageResultServicesConversationView? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ServicesPageResultServicesConversationView.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPaginatedDocumentationEnvelope {
  HandlersPaginatedDocumentationEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedDocumentationEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersPaginatedDocumentationEnvelope(json);

  static const schemaName = 'handlers.PaginatedDocumentationEnvelope';
  final Map<String, dynamic> value;

  ServicesPageResultModelsDocumentation? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ServicesPageResultModelsDocumentation.fromJson(_jsonMap(raw));
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

final class HandlersPaginatedEmergencyProtocolsEnvelope {
  HandlersPaginatedEmergencyProtocolsEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedEmergencyProtocolsEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersPaginatedEmergencyProtocolsEnvelope(json);

  static const schemaName = 'handlers.PaginatedEmergencyProtocolsEnvelope';
  final Map<String, dynamic> value;

  ServicesPageResultModelsEmergencyProtocol? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ServicesPageResultModelsEmergencyProtocol.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPaginatedFAQTagsEnvelope {
  HandlersPaginatedFAQTagsEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedFAQTagsEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersPaginatedFAQTagsEnvelope(json);

  static const schemaName = 'handlers.PaginatedFAQTagsEnvelope';
  final Map<String, dynamic> value;

  ServicesPageResultModelsFAQTag? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ServicesPageResultModelsFAQTag.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPaginatedFAQsEnvelope {
  HandlersPaginatedFAQsEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedFAQsEnvelope.fromJson(Map<String, dynamic> json) =>
      HandlersPaginatedFAQsEnvelope(json);

  static const schemaName = 'handlers.PaginatedFAQsEnvelope';
  final Map<String, dynamic> value;

  ServicesPageResultModelsFAQ? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ServicesPageResultModelsFAQ.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPaginatedGenericPagesEnvelope {
  HandlersPaginatedGenericPagesEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedGenericPagesEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersPaginatedGenericPagesEnvelope(json);

  static const schemaName = 'handlers.PaginatedGenericPagesEnvelope';
  final Map<String, dynamic> value;

  ServicesPageResultModelsGenericPage? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ServicesPageResultModelsGenericPage.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPaginatedGuidelineCategoriesEnvelope {
  HandlersPaginatedGuidelineCategoriesEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedGuidelineCategoriesEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersPaginatedGuidelineCategoriesEnvelope(json);

  static const schemaName = 'handlers.PaginatedGuidelineCategoriesEnvelope';
  final Map<String, dynamic> value;

  ServicesPageResultModelsGuidelineCategory? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ServicesPageResultModelsGuidelineCategory.fromJson(_jsonMap(raw));
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

final class HandlersPaginatedGuidelineCollectionItems {
  HandlersPaginatedGuidelineCollectionItems(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedGuidelineCollectionItems.fromJson(
    Map<String, dynamic> json,
  ) => HandlersPaginatedGuidelineCollectionItems(json);

  static const schemaName = 'handlers.PaginatedGuidelineCollectionItems';
  final Map<String, dynamic> value;

  List<ServicesGuidelineCollectionItemDTO> get items {
    final raw = value['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (item) => ServicesGuidelineCollectionItemDTO.fromJson(_jsonMap(item)),
        )
        .toList(growable: false);
  }

  int? get page => (value['page'] as num?)?.toInt();

  int? get perPage => (value['per_page'] as num?)?.toInt();

  int? get totalItems => (value['total_items'] as num?)?.toInt();

  int? get totalPages => (value['total_pages'] as num?)?.toInt();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPaginatedGuidelineCollectionItemsEnvelope {
  HandlersPaginatedGuidelineCollectionItemsEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedGuidelineCollectionItemsEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersPaginatedGuidelineCollectionItemsEnvelope(json);

  static const schemaName =
      'handlers.PaginatedGuidelineCollectionItemsEnvelope';
  final Map<String, dynamic> value;

  HandlersPaginatedGuidelineCollectionItems? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return HandlersPaginatedGuidelineCollectionItems.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPaginatedGuidelineCollections {
  HandlersPaginatedGuidelineCollections(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedGuidelineCollections.fromJson(
    Map<String, dynamic> json,
  ) => HandlersPaginatedGuidelineCollections(json);

  static const schemaName = 'handlers.PaginatedGuidelineCollections';
  final Map<String, dynamic> value;

  List<ServicesGuidelineCollectionDTO> get items {
    final raw = value['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ServicesGuidelineCollectionDTO.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  int? get page => (value['page'] as num?)?.toInt();

  int? get perPage => (value['per_page'] as num?)?.toInt();

  int? get totalItems => (value['total_items'] as num?)?.toInt();

  int? get totalPages => (value['total_pages'] as num?)?.toInt();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPaginatedGuidelineCollectionsEnvelope {
  HandlersPaginatedGuidelineCollectionsEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedGuidelineCollectionsEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersPaginatedGuidelineCollectionsEnvelope(json);

  static const schemaName = 'handlers.PaginatedGuidelineCollectionsEnvelope';
  final Map<String, dynamic> value;

  HandlersPaginatedGuidelineCollections? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return HandlersPaginatedGuidelineCollections.fromJson(_jsonMap(raw));
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

final class HandlersPaginatedGuidelineDownloads {
  HandlersPaginatedGuidelineDownloads(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedGuidelineDownloads.fromJson(
    Map<String, dynamic> json,
  ) => HandlersPaginatedGuidelineDownloads(json);

  static const schemaName = 'handlers.PaginatedGuidelineDownloads';
  final Map<String, dynamic> value;

  List<ServicesGuidelineDownloadDTO> get items {
    final raw = value['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ServicesGuidelineDownloadDTO.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  int? get page => (value['page'] as num?)?.toInt();

  int? get perPage => (value['per_page'] as num?)?.toInt();

  int? get totalItems => (value['total_items'] as num?)?.toInt();

  int? get totalPages => (value['total_pages'] as num?)?.toInt();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPaginatedGuidelineDownloadsEnvelope {
  HandlersPaginatedGuidelineDownloadsEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedGuidelineDownloadsEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersPaginatedGuidelineDownloadsEnvelope(json);

  static const schemaName = 'handlers.PaginatedGuidelineDownloadsEnvelope';
  final Map<String, dynamic> value;

  HandlersPaginatedGuidelineDownloads? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return HandlersPaginatedGuidelineDownloads.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPaginatedGuidelineIndexEnvelope {
  HandlersPaginatedGuidelineIndexEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedGuidelineIndexEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersPaginatedGuidelineIndexEnvelope(json);

  static const schemaName = 'handlers.PaginatedGuidelineIndexEnvelope';
  final Map<String, dynamic> value;

  ServicesPageResultModelsGuidelineIndexEntry? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ServicesPageResultModelsGuidelineIndexEntry.fromJson(_jsonMap(raw));
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

final class HandlersPaginatedGuidelineTagsEnvelope {
  HandlersPaginatedGuidelineTagsEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedGuidelineTagsEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersPaginatedGuidelineTagsEnvelope(json);

  static const schemaName = 'handlers.PaginatedGuidelineTagsEnvelope';
  final Map<String, dynamic> value;

  ServicesPageResultModelsGuidelineTag? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ServicesPageResultModelsGuidelineTag.fromJson(_jsonMap(raw));
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

final class HandlersPaginatedMarkdownRevisions {
  HandlersPaginatedMarkdownRevisions(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedMarkdownRevisions.fromJson(
    Map<String, dynamic> json,
  ) => HandlersPaginatedMarkdownRevisions(json);

  static const schemaName = 'handlers.PaginatedMarkdownRevisions';
  final Map<String, dynamic> value;

  List<ModelsGuidelineMarkdownRevision> get items {
    final raw = value['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ModelsGuidelineMarkdownRevision.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  int? get page => (value['page'] as num?)?.toInt();

  int? get perPage => (value['per_page'] as num?)?.toInt();

  int? get totalItems => (value['total_items'] as num?)?.toInt();

  int? get totalPages => (value['total_pages'] as num?)?.toInt();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPaginatedMarkdownRevisionsEnvelope {
  HandlersPaginatedMarkdownRevisionsEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedMarkdownRevisionsEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersPaginatedMarkdownRevisionsEnvelope(json);

  static const schemaName = 'handlers.PaginatedMarkdownRevisionsEnvelope';
  final Map<String, dynamic> value;

  HandlersPaginatedMarkdownRevisions? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return HandlersPaginatedMarkdownRevisions.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPaginatedMedicalGuidelinesEnvelope {
  HandlersPaginatedMedicalGuidelinesEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedMedicalGuidelinesEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersPaginatedMedicalGuidelinesEnvelope(json);

  static const schemaName = 'handlers.PaginatedMedicalGuidelinesEnvelope';
  final Map<String, dynamic> value;

  ServicesPageResultModelsMedicalGuideline? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ServicesPageResultModelsMedicalGuideline.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPaginatedMessagesEnvelope {
  HandlersPaginatedMessagesEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedMessagesEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersPaginatedMessagesEnvelope(json);

  static const schemaName = 'handlers.PaginatedMessagesEnvelope';
  final Map<String, dynamic> value;

  ServicesPageResultServicesMessageView? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ServicesPageResultServicesMessageView.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPaginatedMinistryDirectoryEnvelope {
  HandlersPaginatedMinistryDirectoryEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedMinistryDirectoryEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersPaginatedMinistryDirectoryEnvelope(json);

  static const schemaName = 'handlers.PaginatedMinistryDirectoryEnvelope';
  final Map<String, dynamic> value;

  ServicesPageResultModelsMinistryDirectoryEntry? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ServicesPageResultModelsMinistryDirectoryEntry.fromJson(
      _jsonMap(raw),
    );
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPaginatedNotificationCampaigns {
  HandlersPaginatedNotificationCampaigns(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedNotificationCampaigns.fromJson(
    Map<String, dynamic> json,
  ) => HandlersPaginatedNotificationCampaigns(json);

  static const schemaName = 'handlers.PaginatedNotificationCampaigns';
  final Map<String, dynamic> value;

  List<ModelsNotificationCampaign> get items {
    final raw = value['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ModelsNotificationCampaign.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  int? get page => (value['page'] as num?)?.toInt();

  int? get perPage => (value['per_page'] as num?)?.toInt();

  int? get totalItems => (value['total_items'] as num?)?.toInt();

  int? get totalPages => (value['total_pages'] as num?)?.toInt();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPaginatedNotificationCampaignsEnvelope {
  HandlersPaginatedNotificationCampaignsEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedNotificationCampaignsEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersPaginatedNotificationCampaignsEnvelope(json);

  static const schemaName = 'handlers.PaginatedNotificationCampaignsEnvelope';
  final Map<String, dynamic> value;

  HandlersPaginatedNotificationCampaigns? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return HandlersPaginatedNotificationCampaigns.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPaginatedNotificationTemplates {
  HandlersPaginatedNotificationTemplates(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedNotificationTemplates.fromJson(
    Map<String, dynamic> json,
  ) => HandlersPaginatedNotificationTemplates(json);

  static const schemaName = 'handlers.PaginatedNotificationTemplates';
  final Map<String, dynamic> value;

  List<ModelsNotificationTemplate> get items {
    final raw = value['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ModelsNotificationTemplate.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  int? get page => (value['page'] as num?)?.toInt();

  int? get perPage => (value['per_page'] as num?)?.toInt();

  int? get totalItems => (value['total_items'] as num?)?.toInt();

  int? get totalPages => (value['total_pages'] as num?)?.toInt();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPaginatedNotificationTemplatesEnvelope {
  HandlersPaginatedNotificationTemplatesEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedNotificationTemplatesEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersPaginatedNotificationTemplatesEnvelope(json);

  static const schemaName = 'handlers.PaginatedNotificationTemplatesEnvelope';
  final Map<String, dynamic> value;

  HandlersPaginatedNotificationTemplates? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return HandlersPaginatedNotificationTemplates.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPaginatedNotifications {
  HandlersPaginatedNotifications(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedNotifications.fromJson(Map<String, dynamic> json) =>
      HandlersPaginatedNotifications(json);

  static const schemaName = 'handlers.PaginatedNotifications';
  final Map<String, dynamic> value;

  List<ModelsNotification> get items {
    final raw = value['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ModelsNotification.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  int? get page => (value['page'] as num?)?.toInt();

  int? get perPage => (value['per_page'] as num?)?.toInt();

  int? get totalItems => (value['total_items'] as num?)?.toInt();

  int? get totalPages => (value['total_pages'] as num?)?.toInt();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPaginatedNotificationsEnvelope {
  HandlersPaginatedNotificationsEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedNotificationsEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersPaginatedNotificationsEnvelope(json);

  static const schemaName = 'handlers.PaginatedNotificationsEnvelope';
  final Map<String, dynamic> value;

  HandlersPaginatedNotifications? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return HandlersPaginatedNotifications.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPaginatedPublicGuidelineAlgorithms {
  HandlersPaginatedPublicGuidelineAlgorithms(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedPublicGuidelineAlgorithms.fromJson(
    Map<String, dynamic> json,
  ) => HandlersPaginatedPublicGuidelineAlgorithms(json);

  static const schemaName = 'handlers.PaginatedPublicGuidelineAlgorithms';
  final Map<String, dynamic> value;

  List<ServicesPublicGuidelineAlgorithm> get items {
    final raw = value['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (item) => ServicesPublicGuidelineAlgorithm.fromJson(_jsonMap(item)),
        )
        .toList(growable: false);
  }

  int? get page => (value['page'] as num?)?.toInt();

  int? get perPage => (value['per_page'] as num?)?.toInt();

  int? get totalItems => (value['total_items'] as num?)?.toInt();

  int? get totalPages => (value['total_pages'] as num?)?.toInt();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPaginatedPublicGuidelineAlgorithmsEnvelope {
  HandlersPaginatedPublicGuidelineAlgorithmsEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedPublicGuidelineAlgorithmsEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersPaginatedPublicGuidelineAlgorithmsEnvelope(json);

  static const schemaName =
      'handlers.PaginatedPublicGuidelineAlgorithmsEnvelope';
  final Map<String, dynamic> value;

  HandlersPaginatedPublicGuidelineAlgorithms? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return HandlersPaginatedPublicGuidelineAlgorithms.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPaginatedPublicGuidelineFigures {
  HandlersPaginatedPublicGuidelineFigures(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedPublicGuidelineFigures.fromJson(
    Map<String, dynamic> json,
  ) => HandlersPaginatedPublicGuidelineFigures(json);

  static const schemaName = 'handlers.PaginatedPublicGuidelineFigures';
  final Map<String, dynamic> value;

  List<ServicesPublicGuidelineFigure> get items {
    final raw = value['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ServicesPublicGuidelineFigure.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  int? get page => (value['page'] as num?)?.toInt();

  int? get perPage => (value['per_page'] as num?)?.toInt();

  int? get totalItems => (value['total_items'] as num?)?.toInt();

  int? get totalPages => (value['total_pages'] as num?)?.toInt();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPaginatedPublicGuidelineFiguresEnvelope {
  HandlersPaginatedPublicGuidelineFiguresEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedPublicGuidelineFiguresEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersPaginatedPublicGuidelineFiguresEnvelope(json);

  static const schemaName = 'handlers.PaginatedPublicGuidelineFiguresEnvelope';
  final Map<String, dynamic> value;

  HandlersPaginatedPublicGuidelineFigures? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return HandlersPaginatedPublicGuidelineFigures.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPaginatedPublicGuidelineSections {
  HandlersPaginatedPublicGuidelineSections(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedPublicGuidelineSections.fromJson(
    Map<String, dynamic> json,
  ) => HandlersPaginatedPublicGuidelineSections(json);

  static const schemaName = 'handlers.PaginatedPublicGuidelineSections';
  final Map<String, dynamic> value;

  List<ServicesPublicGuidelineSection> get items {
    final raw = value['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ServicesPublicGuidelineSection.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  int? get page => (value['page'] as num?)?.toInt();

  int? get perPage => (value['per_page'] as num?)?.toInt();

  int? get totalItems => (value['total_items'] as num?)?.toInt();

  int? get totalPages => (value['total_pages'] as num?)?.toInt();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPaginatedPublicGuidelineSectionsEnvelope {
  HandlersPaginatedPublicGuidelineSectionsEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedPublicGuidelineSectionsEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersPaginatedPublicGuidelineSectionsEnvelope(json);

  static const schemaName = 'handlers.PaginatedPublicGuidelineSectionsEnvelope';
  final Map<String, dynamic> value;

  HandlersPaginatedPublicGuidelineSections? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return HandlersPaginatedPublicGuidelineSections.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPaginatedPublicGuidelineTables {
  HandlersPaginatedPublicGuidelineTables(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedPublicGuidelineTables.fromJson(
    Map<String, dynamic> json,
  ) => HandlersPaginatedPublicGuidelineTables(json);

  static const schemaName = 'handlers.PaginatedPublicGuidelineTables';
  final Map<String, dynamic> value;

  List<ServicesPublicGuidelineTable> get items {
    final raw = value['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ServicesPublicGuidelineTable.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  int? get page => (value['page'] as num?)?.toInt();

  int? get perPage => (value['per_page'] as num?)?.toInt();

  int? get totalItems => (value['total_items'] as num?)?.toInt();

  int? get totalPages => (value['total_pages'] as num?)?.toInt();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPaginatedPublicGuidelineTablesEnvelope {
  HandlersPaginatedPublicGuidelineTablesEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedPublicGuidelineTablesEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersPaginatedPublicGuidelineTablesEnvelope(json);

  static const schemaName = 'handlers.PaginatedPublicGuidelineTablesEnvelope';
  final Map<String, dynamic> value;

  HandlersPaginatedPublicGuidelineTables? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return HandlersPaginatedPublicGuidelineTables.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPaginatedPublicGuidelines {
  HandlersPaginatedPublicGuidelines(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedPublicGuidelines.fromJson(
    Map<String, dynamic> json,
  ) => HandlersPaginatedPublicGuidelines(json);

  static const schemaName = 'handlers.PaginatedPublicGuidelines';
  final Map<String, dynamic> value;

  List<ServicesPublicGuideline> get items {
    final raw = value['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ServicesPublicGuideline.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  int? get page => (value['page'] as num?)?.toInt();

  int? get perPage => (value['per_page'] as num?)?.toInt();

  int? get totalItems => (value['total_items'] as num?)?.toInt();

  int? get totalPages => (value['total_pages'] as num?)?.toInt();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPaginatedPublicGuidelinesEnvelope {
  HandlersPaginatedPublicGuidelinesEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedPublicGuidelinesEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersPaginatedPublicGuidelinesEnvelope(json);

  static const schemaName = 'handlers.PaginatedPublicGuidelinesEnvelope';
  final Map<String, dynamic> value;

  HandlersPaginatedPublicGuidelines? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return HandlersPaginatedPublicGuidelines.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPaginatedReadingProgressEnvelope {
  HandlersPaginatedReadingProgressEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedReadingProgressEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersPaginatedReadingProgressEnvelope(json);

  static const schemaName = 'handlers.PaginatedReadingProgressEnvelope';
  final Map<String, dynamic> value;

  ServicesPageResultModelsReadingProgress? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ServicesPageResultModelsReadingProgress.fromJson(_jsonMap(raw));
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

final class HandlersPaginatedSupportRepliesEnvelope {
  HandlersPaginatedSupportRepliesEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedSupportRepliesEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersPaginatedSupportRepliesEnvelope(json);

  static const schemaName = 'handlers.PaginatedSupportRepliesEnvelope';
  final Map<String, dynamic> value;

  ServicesPageResultModelsSupportTicketReply? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ServicesPageResultModelsSupportTicketReply.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPaginatedSupportTicketsEnvelope {
  HandlersPaginatedSupportTicketsEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPaginatedSupportTicketsEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersPaginatedSupportTicketsEnvelope(json);

  static const schemaName = 'handlers.PaginatedSupportTicketsEnvelope';
  final Map<String, dynamic> value;

  ServicesPageResultModelsSupportTicket? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ServicesPageResultModelsSupportTicket.fromJson(_jsonMap(raw));
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

final class HandlersPublicGuidelineAssetEnvelope {
  HandlersPublicGuidelineAssetEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPublicGuidelineAssetEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersPublicGuidelineAssetEnvelope(json);

  static const schemaName = 'handlers.PublicGuidelineAssetEnvelope';
  final Map<String, dynamic> value;

  ServicesPublicGuidelineAssetLink? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ServicesPublicGuidelineAssetLink.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPublicGuidelineEnvelope {
  HandlersPublicGuidelineEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPublicGuidelineEnvelope.fromJson(Map<String, dynamic> json) =>
      HandlersPublicGuidelineEnvelope(json);

  static const schemaName = 'handlers.PublicGuidelineEnvelope';
  final Map<String, dynamic> value;

  ServicesPublicGuideline? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ServicesPublicGuideline.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPublicGuidelineManifestEnvelope {
  HandlersPublicGuidelineManifestEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPublicGuidelineManifestEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersPublicGuidelineManifestEnvelope(json);

  static const schemaName = 'handlers.PublicGuidelineManifestEnvelope';
  final Map<String, dynamic> value;

  ServicesPublicGuidelineManifest? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ServicesPublicGuidelineManifest.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersPublicGuidelineSectionEnvelope {
  HandlersPublicGuidelineSectionEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersPublicGuidelineSectionEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersPublicGuidelineSectionEnvelope(json);

  static const schemaName = 'handlers.PublicGuidelineSectionEnvelope';
  final Map<String, dynamic> value;

  ServicesPublicGuidelineSectionDetail? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ServicesPublicGuidelineSectionDetail.fromJson(_jsonMap(raw));
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

final class HandlersReadingProgressEnvelope {
  HandlersReadingProgressEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersReadingProgressEnvelope.fromJson(Map<String, dynamic> json) =>
      HandlersReadingProgressEnvelope(json);

  static const schemaName = 'handlers.ReadingProgressEnvelope';
  final Map<String, dynamic> value;

  ModelsReadingProgress? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ModelsReadingProgress.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

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

final class HandlersRestoreMarkdownRevisionInput {
  HandlersRestoreMarkdownRevisionInput(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersRestoreMarkdownRevisionInput.fromJson(
    Map<String, dynamic> json,
  ) => HandlersRestoreMarkdownRevisionInput(json);

  static const schemaName = 'handlers.RestoreMarkdownRevisionInput';
  final Map<String, dynamic> value;

  String? get expectedRevision => value['expected_revision']?.toString();

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

final class HandlersSupportReplyEnvelope {
  HandlersSupportReplyEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersSupportReplyEnvelope.fromJson(Map<String, dynamic> json) =>
      HandlersSupportReplyEnvelope(json);

  static const schemaName = 'handlers.SupportReplyEnvelope';
  final Map<String, dynamic> value;

  ModelsSupportTicketReply? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ModelsSupportTicketReply.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersSupportTicketEnvelope {
  HandlersSupportTicketEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersSupportTicketEnvelope.fromJson(Map<String, dynamic> json) =>
      HandlersSupportTicketEnvelope(json);

  static const schemaName = 'handlers.SupportTicketEnvelope';
  final Map<String, dynamic> value;

  ModelsSupportTicket? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return ModelsSupportTicket.fromJson(_jsonMap(raw));
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

final class HandlersTagUsageRecalculationEnvelope {
  HandlersTagUsageRecalculationEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersTagUsageRecalculationEnvelope.fromJson(
    Map<String, dynamic> json,
  ) => HandlersTagUsageRecalculationEnvelope(json);

  static const schemaName = 'handlers.TagUsageRecalculationEnvelope';
  final Map<String, dynamic> value;

  HandlersTagUsageRecalculationResult? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return HandlersTagUsageRecalculationResult.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersTagUsageRecalculationResult {
  HandlersTagUsageRecalculationResult(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersTagUsageRecalculationResult.fromJson(
    Map<String, dynamic> json,
  ) => HandlersTagUsageRecalculationResult(json);

  static const schemaName = 'handlers.TagUsageRecalculationResult';
  final Map<String, dynamic> value;

  bool? get updated => value['updated'] as bool?;

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

final class HandlersUpdatedEnvelope {
  HandlersUpdatedEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersUpdatedEnvelope.fromJson(Map<String, dynamic> json) =>
      HandlersUpdatedEnvelope(json);

  static const schemaName = 'handlers.UpdatedEnvelope';
  final Map<String, dynamic> value;

  HandlersUpdatedResult? get data {
    final raw = value['data'];
    if (raw is! Map) return null;
    return HandlersUpdatedResult.fromJson(_jsonMap(raw));
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersUpdatedResult {
  HandlersUpdatedResult(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersUpdatedResult.fromJson(Map<String, dynamic> json) =>
      HandlersUpdatedResult(json);

  static const schemaName = 'handlers.UpdatedResult';
  final Map<String, dynamic> value;

  bool? get updated => value['updated'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersUsageAggregatesEnvelope {
  HandlersUsageAggregatesEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersUsageAggregatesEnvelope.fromJson(Map<String, dynamic> json) =>
      HandlersUsageAggregatesEnvelope(json);

  static const schemaName = 'handlers.UsageAggregatesEnvelope';
  final Map<String, dynamic> value;

  List<ServicesUsageAggregate> get data {
    final raw = value['data'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ServicesUsageAggregate.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class HandlersUsageEventEnvelope {
  HandlersUsageEventEnvelope(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HandlersUsageEventEnvelope.fromJson(Map<String, dynamic> json) =>
      HandlersUsageEventEnvelope(json);

  static const schemaName = 'handlers.UsageEventEnvelope';
  final Map<String, dynamic> value;

  Object? get data => value['data'];

  bool? get success => value['success'] as bool?;

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

final class HttpxResponse {
  HttpxResponse(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory HttpxResponse.fromJson(Map<String, dynamic> json) =>
      HttpxResponse(json);

  static const schemaName = 'httpx.Response';
  final Map<String, dynamic> value;

  Object? get data => value['data'];

  String? get error => value['error']?.toString();

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ModelsAbbreviation {
  ModelsAbbreviation(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ModelsAbbreviation.fromJson(Map<String, dynamic> json) =>
      ModelsAbbreviation(json);

  static const schemaName = 'models.Abbreviation';
  final Map<String, dynamic> value;

  String? get abbreviation => value['abbreviation']?.toString();

  List<String> get categories {
    final raw = value['categories'];
    if (raw is! List) return const [];
    return raw.whereType<String>().toList(growable: false);
  }

  bool? get commonUsage => value['common_usage'] as bool?;

  String? get createdAt => value['created_at']?.toString();

  String? get description => value['description']?.toString();

  String? get id => value['id']?.toString();

  String? get meaning => value['meaning']?.toString();

  List<String> get tags {
    final raw = value['tags'];
    if (raw is! List) return const [];
    return raw.whereType<String>().toList(growable: false);
  }

  String? get updatedAt => value['updated_at']?.toString();

  int? get usageCount => (value['usage_count'] as num?)?.toInt();

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

final class ModelsDocumentation {
  ModelsDocumentation(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ModelsDocumentation.fromJson(Map<String, dynamic> json) =>
      ModelsDocumentation(json);

  static const schemaName = 'models.Documentation';
  final Map<String, dynamic> value;

  String? get category => value['category']?.toString();

  String? get content => value['content']?.toString();

  String? get createdAt => value['created_at']?.toString();

  String? get description => value['description']?.toString();

  String? get id => value['id']?.toString();

  String? get status => value['status']?.toString();

  String? get tags => value['tags']?.toString();

  String? get title => value['title']?.toString();

  String? get updatedAt => value['updated_at']?.toString();

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

  List<ModelsDrugCategory> get categoryDetails {
    final raw = value['category_details'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ModelsDrugCategory.fromJson(_jsonMap(item)))
        .toList(growable: false);
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

  List<ModelsDrugTag> get tagDetails {
    final raw = value['tag_details'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ModelsDrugTag.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

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

final class ModelsEmergencyProtocol {
  ModelsEmergencyProtocol(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ModelsEmergencyProtocol.fromJson(Map<String, dynamic> json) =>
      ModelsEmergencyProtocol(json);

  static const schemaName = 'models.EmergencyProtocol';
  final Map<String, dynamic> value;

  int? get accessCount => (value['access_count'] as num?)?.toInt();

  String? get category => value['category']?.toString();

  Map<String, dynamic> get contactInfo => _jsonMap(value['contact_info']);

  String? get createdAt => value['created_at']?.toString();

  Map<String, dynamic> get criticalActions =>
      _jsonMap(value['critical_actions']);

  String? get description => value['description']?.toString();

  String? get id => value['id']?.toString();

  Map<String, dynamic> get medications => _jsonMap(value['medications']);

  String? get priority => value['priority']?.toString();

  String? get status => value['status']?.toString();

  Map<String, dynamic> get steps => _jsonMap(value['steps']);

  List<String> get tags {
    final raw = value['tags'];
    if (raw is! List) return const [];
    return raw.whereType<String>().toList(growable: false);
  }

  String? get timeframe => value['timeframe']?.toString();

  String? get title => value['title']?.toString();

  Map<String, dynamic> get transferChecklist =>
      _jsonMap(value['transfer_checklist']);

  String? get updatedAt => value['updated_at']?.toString();

  Map<String, dynamic> get vitalSigns => _jsonMap(value['vital_signs']);

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ModelsFAQ {
  ModelsFAQ(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ModelsFAQ.fromJson(Map<String, dynamic> json) => ModelsFAQ(json);

  static const schemaName = 'models.FAQ';
  final Map<String, dynamic> value;

  String? get answer => value['answer']?.toString();

  String? get authorEmail => value['author_email']?.toString();

  String? get authorId => value['author_id']?.toString();

  String? get authorName => value['author_name']?.toString();

  String? get createdAt => value['created_at']?.toString();

  String? get id => value['id']?.toString();

  bool? get isFeatured => value['is_featured'] as bool?;

  String? get keywords => value['keywords']?.toString();

  String? get priority => value['priority']?.toString();

  String? get publishedAt => value['published_at']?.toString();

  String? get question => value['question']?.toString();

  List<String> get relatedFaqs {
    final raw = value['related_faqs'];
    if (raw is! List) return const [];
    return raw.whereType<String>().toList(growable: false);
  }

  String? get reviewDue => value['review_due']?.toString();

  String? get reviewerEmail => value['reviewer_email']?.toString();

  String? get reviewerId => value['reviewer_id']?.toString();

  String? get reviewerName => value['reviewer_name']?.toString();

  int? get sortOrder => (value['sort_order'] as num?)?.toInt();

  String? get status => value['status']?.toString();

  List<String> get tags {
    final raw = value['tags'];
    if (raw is! List) return const [];
    return raw.whereType<String>().toList(growable: false);
  }

  String? get targetAudience => value['target_audience']?.toString();

  String? get updatedAt => value['updated_at']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ModelsFAQTag {
  ModelsFAQTag(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ModelsFAQTag.fromJson(Map<String, dynamic> json) =>
      ModelsFAQTag(json);

  static const schemaName = 'models.FAQTag';
  final Map<String, dynamic> value;

  String? get color => value['color']?.toString();

  String? get createdAt => value['created_at']?.toString();

  String? get description => value['description']?.toString();

  String? get icon => value['icon']?.toString();

  String? get id => value['id']?.toString();

  bool? get isActive => value['is_active'] as bool?;

  String? get name => value['name']?.toString();

  String? get slug => value['slug']?.toString();

  int? get sortOrder => (value['sort_order'] as num?)?.toInt();

  String? get updatedAt => value['updated_at']?.toString();

  int? get usageCount => (value['usage_count'] as num?)?.toInt();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ModelsFacilityUsageLog {
  ModelsFacilityUsageLog(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ModelsFacilityUsageLog.fromJson(Map<String, dynamic> json) =>
      ModelsFacilityUsageLog(json);

  static const schemaName = 'models.FacilityUsageLog';
  final Map<String, dynamic> value;

  String? get createdAt => value['created_at']?.toString();

  String? get facilityId => value['facility_id']?.toString();

  String? get id => value['id']?.toString();

  String? get updatedAt => value['updated_at']?.toString();

  String? get userId => value['user_id']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ModelsGenericPage {
  ModelsGenericPage(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ModelsGenericPage.fromJson(Map<String, dynamic> json) =>
      ModelsGenericPage(json);

  static const schemaName = 'models.GenericPage';
  final Map<String, dynamic> value;

  Map<String, dynamic> get content => _jsonMap(value['content']);

  String? get createdAt => value['created_at']?.toString();

  String? get description => value['description']?.toString();

  String? get id => value['id']?.toString();

  String? get key => value['key']?.toString();

  String? get title => value['title']?.toString();

  String? get updatedAt => value['updated_at']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ModelsGuidelineAlgorithmBlockPayload {
  ModelsGuidelineAlgorithmBlockPayload(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ModelsGuidelineAlgorithmBlockPayload.fromJson(
    Map<String, dynamic> json,
  ) => ModelsGuidelineAlgorithmBlockPayload(json);

  static const schemaName = 'models.GuidelineAlgorithmBlockPayload';
  final Map<String, dynamic> value;

  List<ModelsGuidelineAlgorithmNode> get nodes {
    final raw = value['nodes'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ModelsGuidelineAlgorithmNode.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  String? get title => value['title']?.toString();

  ModelsGuidelineBlockType? get type {
    final raw = value['type'];
    if (raw is! Map) return null;
    return ModelsGuidelineBlockType.fromJson(_jsonMap(raw));
  }

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ModelsGuidelineAlgorithmNode {
  ModelsGuidelineAlgorithmNode(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ModelsGuidelineAlgorithmNode.fromJson(Map<String, dynamic> json) =>
      ModelsGuidelineAlgorithmNode(json);

  static const schemaName = 'models.GuidelineAlgorithmNode';
  final Map<String, dynamic> value;

  String? get id => value['id']?.toString();

  String? get kind => value['kind']?.toString();

  String? get label => value['label']?.toString();

  List<String> get next {
    final raw = value['next'];
    if (raw is! List) return const [];
    return raw.whereType<String>().toList(growable: false);
  }

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ModelsGuidelineAsset {
  ModelsGuidelineAsset(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ModelsGuidelineAsset.fromJson(Map<String, dynamic> json) =>
      ModelsGuidelineAsset(json);

  static const schemaName = 'models.GuidelineAsset';
  final Map<String, dynamic> value;

  String? get checksum => value['checksum']?.toString();

  String? get createdAt => value['created_at']?.toString();

  String? get id => value['id']?.toString();

  String? get mimeType => value['mime_type']?.toString();

  String? get originalFilename => value['original_filename']?.toString();

  int? get pageEnd => (value['page_end'] as num?)?.toInt();

  int? get pageStart => (value['page_start'] as num?)?.toInt();

  Map<String, dynamic> get provenance => _jsonMap(value['provenance']);

  ModelsGuidelineBlockReviewStatus? get reviewStatus {
    final raw = value['review_status'];
    if (raw is! Map) return null;
    return ModelsGuidelineBlockReviewStatus.fromJson(_jsonMap(raw));
  }

  String? get reviewedAt => value['reviewed_at']?.toString();

  String? get reviewedBy => value['reviewed_by']?.toString();

  String? get sectionId => value['section_id']?.toString();

  int? get sizeBytes => (value['size_bytes'] as num?)?.toInt();

  String? get sourceFingerprint => value['source_fingerprint']?.toString();

  String? get storageKey => value['storage_key']?.toString();

  ModelsGuidelineAssetType? get type {
    final raw = value['type'];
    if (raw is! Map) return null;
    return ModelsGuidelineAssetType.fromJson(_jsonMap(raw));
  }

  String? get updatedAt => value['updated_at']?.toString();

  String? get versionId => value['version_id']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ModelsGuidelineAssetType {
  ModelsGuidelineAssetType(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ModelsGuidelineAssetType.fromJson(Map<String, dynamic> json) =>
      ModelsGuidelineAssetType(json);

  static const schemaName = 'models.GuidelineAssetType';
  final Map<String, dynamic> value;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ModelsGuidelineBlockReviewStatus {
  ModelsGuidelineBlockReviewStatus(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ModelsGuidelineBlockReviewStatus.fromJson(
    Map<String, dynamic> json,
  ) => ModelsGuidelineBlockReviewStatus(json);

  static const schemaName = 'models.GuidelineBlockReviewStatus';
  final Map<String, dynamic> value;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ModelsGuidelineBlockType {
  ModelsGuidelineBlockType(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ModelsGuidelineBlockType.fromJson(Map<String, dynamic> json) =>
      ModelsGuidelineBlockType(json);

  static const schemaName = 'models.GuidelineBlockType';
  final Map<String, dynamic> value;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ModelsGuidelineCategory {
  ModelsGuidelineCategory(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ModelsGuidelineCategory.fromJson(Map<String, dynamic> json) =>
      ModelsGuidelineCategory(json);

  static const schemaName = 'models.GuidelineCategory';
  final Map<String, dynamic> value;

  String? get color => value['color']?.toString();

  String? get createdAt => value['created_at']?.toString();

  String? get description => value['description']?.toString();

  String? get icon => value['icon']?.toString();

  String? get id => value['id']?.toString();

  String? get name => value['name']?.toString();

  String? get parentCategoryId => value['parent_category_id']?.toString();

  String? get parentName => value['parent_name']?.toString();

  String? get slug => value['slug']?.toString();

  int? get sortOrder => (value['sort_order'] as num?)?.toInt();

  String? get status => value['status']?.toString();

  String? get updatedAt => value['updated_at']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ModelsGuidelineChunk {
  ModelsGuidelineChunk(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ModelsGuidelineChunk.fromJson(Map<String, dynamic> json) =>
      ModelsGuidelineChunk(json);

  static const schemaName = 'models.GuidelineChunk';
  final Map<String, dynamic> value;

  String? get blockId => value['block_id']?.toString();

  String? get content => value['content']?.toString();

  String? get createdAt => value['created_at']?.toString();

  String? get documentId => value['document_id']?.toString();

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

final class ModelsGuidelineContentBlock {
  ModelsGuidelineContentBlock(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ModelsGuidelineContentBlock.fromJson(Map<String, dynamic> json) =>
      ModelsGuidelineContentBlock(json);

  static const schemaName = 'models.GuidelineContentBlock';
  final Map<String, dynamic> value;

  Map<String, dynamic> get content => _jsonMap(value['content']);

  String? get createdAt => value['created_at']?.toString();

  num? get extractionConfidence => value['extraction_confidence'] as num?;

  String? get id => value['id']?.toString();

  int? get pageEnd => (value['page_end'] as num?)?.toInt();

  int? get pageStart => (value['page_start'] as num?)?.toInt();

  Map<String, dynamic> get provenance => _jsonMap(value['provenance']);

  ModelsGuidelineBlockReviewStatus? get reviewStatus {
    final raw = value['review_status'];
    if (raw is! Map) return null;
    return ModelsGuidelineBlockReviewStatus.fromJson(_jsonMap(raw));
  }

  String? get reviewedAt => value['reviewed_at']?.toString();

  String? get reviewedBy => value['reviewed_by']?.toString();

  String? get sectionId => value['section_id']?.toString();

  int? get sortOrder => (value['sort_order'] as num?)?.toInt();

  String? get sourceFingerprint => value['source_fingerprint']?.toString();

  ModelsGuidelineBlockType? get type {
    final raw = value['type'];
    if (raw is! Map) return null;
    return ModelsGuidelineBlockType.fromJson(_jsonMap(raw));
  }

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

final class ModelsGuidelineExtractionQuality {
  ModelsGuidelineExtractionQuality(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ModelsGuidelineExtractionQuality.fromJson(
    Map<String, dynamic> json,
  ) => ModelsGuidelineExtractionQuality(json);

  static const schemaName = 'models.GuidelineExtractionQuality';
  final Map<String, dynamic> value;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ModelsGuidelineFigureBlockPayload {
  ModelsGuidelineFigureBlockPayload(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ModelsGuidelineFigureBlockPayload.fromJson(
    Map<String, dynamic> json,
  ) => ModelsGuidelineFigureBlockPayload(json);

  static const schemaName = 'models.GuidelineFigureBlockPayload';
  final Map<String, dynamic> value;

  String? get alternativeText => value['alternative_text']?.toString();

  String? get assetId => value['asset_id']?.toString();

  String? get caption => value['caption']?.toString();

  ModelsGuidelineBlockType? get type {
    final raw = value['type'];
    if (raw is! Map) return null;
    return ModelsGuidelineBlockType.fromJson(_jsonMap(raw));
  }

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ModelsGuidelineIndexEntry {
  ModelsGuidelineIndexEntry(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ModelsGuidelineIndexEntry.fromJson(Map<String, dynamic> json) =>
      ModelsGuidelineIndexEntry(json);

  static const schemaName = 'models.GuidelineIndexEntry';
  final Map<String, dynamic> value;

  String? get createdAt => value['created_at']?.toString();

  String? get description => value['description']?.toString();

  bool? get hasChildren => value['has_children'] as bool?;

  String? get id => value['id']?.toString();

  int? get level => (value['level'] as num?)?.toInt();

  String? get parentId => value['parent_id']?.toString();

  String? get parentTitle => value['parent_title']?.toString();

  int? get sortOrder => (value['sort_order'] as num?)?.toInt();

  String? get title => value['title']?.toString();

  String? get updatedAt => value['updated_at']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ModelsGuidelineMarkdownRevision {
  ModelsGuidelineMarkdownRevision(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ModelsGuidelineMarkdownRevision.fromJson(Map<String, dynamic> json) =>
      ModelsGuidelineMarkdownRevision(json);

  static const schemaName = 'models.GuidelineMarkdownRevision';
  final Map<String, dynamic> value;

  String? get changeSummary => value['change_summary']?.toString();

  String? get checkpointName => value['checkpoint_name']?.toString();

  String? get checksum => value['checksum']?.toString();

  String? get createdAt => value['created_at']?.toString();

  String? get createdBy => value['created_by']?.toString();

  String? get documentId => value['document_id']?.toString();

  String? get id => value['id']?.toString();

  bool? get isCurrent => value['is_current'] as bool?;

  String? get parentRevisionId => value['parent_revision_id']?.toString();

  String? get publicationState => value['publication_state']?.toString();

  String? get regenerationJobId => value['regeneration_job_id']?.toString();

  String? get reviewState => value['review_state']?.toString();

  int? get revisionNumber => (value['revision_number'] as num?)?.toInt();

  int? get sizeBytes => (value['size_bytes'] as num?)?.toInt();

  String? get sourceIngestionJobId =>
      value['source_ingestion_job_id']?.toString();

  String? get sourceType => value['source_type']?.toString();

  String? get structuredContentStatus =>
      value['structured_content_status']?.toString();

  String? get updatedAt => value['updated_at']?.toString();

  String? get versionId => value['version_id']?.toString();

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

final class ModelsGuidelineTableBlockPayload {
  ModelsGuidelineTableBlockPayload(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ModelsGuidelineTableBlockPayload.fromJson(
    Map<String, dynamic> json,
  ) => ModelsGuidelineTableBlockPayload(json);

  static const schemaName = 'models.GuidelineTableBlockPayload';
  final Map<String, dynamic> value;

  List<String> get columns {
    final raw = value['columns'];
    if (raw is! List) return const [];
    return raw.whereType<String>().toList(growable: false);
  }

  List<String> get footnotes {
    final raw = value['footnotes'];
    if (raw is! List) return const [];
    return raw.whereType<String>().toList(growable: false);
  }

  List<Object?> get rows {
    final raw = value['rows'];
    if (raw is! List) return const [];
    return raw.whereType<Object?>().toList(growable: false);
  }

  String? get title => value['title']?.toString();

  ModelsGuidelineBlockType? get type {
    final raw = value['type'];
    if (raw is! Map) return null;
    return ModelsGuidelineBlockType.fromJson(_jsonMap(raw));
  }

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ModelsGuidelineTag {
  ModelsGuidelineTag(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ModelsGuidelineTag.fromJson(Map<String, dynamic> json) =>
      ModelsGuidelineTag(json);

  static const schemaName = 'models.GuidelineTag';
  final Map<String, dynamic> value;

  String? get createdAt => value['created_at']?.toString();

  String? get description => value['description']?.toString();

  String? get id => value['id']?.toString();

  String? get name => value['name']?.toString();

  String? get updatedAt => value['updated_at']?.toString();

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

  List<ModelsGuidelineAsset> get assets {
    final raw = value['assets'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ModelsGuidelineAsset.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  String? get checksum => value['checksum']?.toString();

  List<ModelsGuidelineContentBlock> get contentBlocks {
    final raw = value['content_blocks'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ModelsGuidelineContentBlock.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  String? get createdAt => value['created_at']?.toString();

  String? get currentMarkdownRevisionId =>
      value['current_markdown_revision_id']?.toString();

  String? get documentId => value['document_id']?.toString();

  Map<String, dynamic> get extractionMetadata =>
      _jsonMap(value['extraction_metadata']);

  int? get extractionSchemaVersion =>
      (value['extraction_schema_version'] as num?)?.toInt();

  List<String> get extractionWarnings {
    final raw = value['extraction_warnings'];
    if (raw is! List) return const [];
    return raw.whereType<String>().toList(growable: false);
  }

  String? get htmlFileKey => value['html_file_key']?.toString();

  String? get id => value['id']?.toString();

  ModelsGuidelineVersionManifest? get manifest {
    final raw = value['manifest'];
    if (raw is! Map) return null;
    return ModelsGuidelineVersionManifest.fromJson(_jsonMap(raw));
  }

  String? get markdownFileKey => value['markdown_file_key']?.toString();

  String? get originalFileKey => value['original_file_key']?.toString();

  String? get publicationDate => value['publication_date']?.toString();

  String? get publishedMarkdownRevisionId =>
      value['published_markdown_revision_id']?.toString();

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

  String? get structuredContentStatus =>
      value['structured_content_status']?.toString();

  String? get structuredMarkdownRevisionId =>
      value['structured_markdown_revision_id']?.toString();

  String? get updatedAt => value['updated_at']?.toString();

  String? get version => value['version']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ModelsGuidelineVersionManifest {
  ModelsGuidelineVersionManifest(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ModelsGuidelineVersionManifest.fromJson(Map<String, dynamic> json) =>
      ModelsGuidelineVersionManifest(json);

  static const schemaName = 'models.GuidelineVersionManifest';
  final Map<String, dynamic> value;

  int? get algorithmCount => (value['algorithm_count'] as num?)?.toInt();

  int? get blockCount => (value['block_count'] as num?)?.toInt();

  String? get checksum => value['checksum']?.toString();

  String? get createdAt => value['created_at']?.toString();

  String? get etag => value['etag']?.toString();

  ModelsGuidelineExtractionQuality? get extractionQuality {
    final raw = value['extraction_quality'];
    if (raw is! Map) return null;
    return ModelsGuidelineExtractionQuality.fromJson(_jsonMap(raw));
  }

  int? get figureCount => (value['figure_count'] as num?)?.toInt();

  String? get generatedAt => value['generated_at']?.toString();

  String? get guidelineId => value['guideline_id']?.toString();

  bool? get hasAlgorithms => value['has_algorithms'] as bool?;

  bool? get hasChapters => value['has_chapters'] as bool?;

  bool? get hasFigures => value['has_figures'] as bool?;

  bool? get hasKeyPoints => value['has_key_points'] as bool?;

  bool? get hasOfflinePackage => value['has_offline_package'] as bool?;

  bool? get hasOriginalPdf => value['has_original_pdf'] as bool?;

  bool? get hasTables => value['has_tables'] as bool?;

  String? get id => value['id']?.toString();

  int? get packageVersion => (value['package_version'] as num?)?.toInt();

  int? get schemaVersion => (value['schema_version'] as num?)?.toInt();

  int? get sectionCount => (value['section_count'] as num?)?.toInt();

  int? get tableCount => (value['table_count'] as num?)?.toInt();

  String? get updatedAt => value['updated_at']?.toString();

  String? get version => value['version']?.toString();

  String? get versionId => value['version_id']?.toString();

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

final class ModelsMedicalGuideline {
  ModelsMedicalGuideline(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ModelsMedicalGuideline.fromJson(Map<String, dynamic> json) =>
      ModelsMedicalGuideline(json);

  static const schemaName = 'models.MedicalGuideline';
  final Map<String, dynamic> value;

  List<String> get categories {
    final raw = value['categories'];
    if (raw is! List) return const [];
    return raw.whereType<String>().toList(growable: false);
  }

  List<ModelsGuidelineCategory> get categoryDetails {
    final raw = value['category_details'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ModelsGuidelineCategory.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  String? get causes => value['causes']?.toString();

  String? get classificationCritical =>
      value['classification_critical']?.toString();

  String? get classificationMild => value['classification_mild']?.toString();

  String? get classificationModerate =>
      value['classification_moderate']?.toString();

  String? get classificationSevere =>
      value['classification_severe']?.toString();

  String? get clinicalFeatures => value['clinical_features']?.toString();

  String? get conditionName => value['condition_name']?.toString();

  String? get contraindications => value['contraindications']?.toString();

  String? get createdAt => value['created_at']?.toString();

  String? get definition => value['definition']?.toString();

  String? get differentialDiagnosis =>
      value['differential_diagnosis']?.toString();

  String? get dosageAdult => value['dosage_adult']?.toString();

  String? get dosagePediatric => value['dosage_pediatric']?.toString();

  String? get dosageSecondaryAdult =>
      value['dosage_secondary_adult']?.toString();

  String? get dosageSecondaryPediatric =>
      value['dosage_secondary_pediatric']?.toString();

  String? get generalManagement => value['general_management']?.toString();

  String? get healthcareLevelRequired =>
      value['healthcare_level_required']?.toString();

  String? get icd10Code => value['icd10_code']?.toString();

  String? get id => value['id']?.toString();

  String? get indexItemId => value['index_item_id']?.toString();

  String? get indexItemTitle => value['index_item_title']?.toString();

  bool? get isPublished => value['is_published'] as bool?;

  String? get medicationPrimary => value['medication_primary']?.toString();

  String? get medicationSecondary => value['medication_secondary']?.toString();

  String? get monitoringRequirements =>
      value['monitoring_requirements']?.toString();

  String? get preventionMeasures => value['prevention_measures']?.toString();

  String? get priority => value['priority']?.toString();

  String? get routeAdministration => value['route_administration']?.toString();

  String? get specialNotes => value['special_notes']?.toString();

  String? get status => value['status']?.toString();

  List<ModelsGuidelineTag> get tagDetails {
    final raw = value['tag_details'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ModelsGuidelineTag.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  List<String> get tags {
    final raw = value['tags'];
    if (raw is! List) return const [];
    return raw.whereType<String>().toList(growable: false);
  }

  String? get targetPopulation => value['target_population']?.toString();

  String? get updatedAt => value['updated_at']?.toString();

  int? get usageCount => (value['usage_count'] as num?)?.toInt();

  String? get version => value['version']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ModelsMinistryDirectoryEntry {
  ModelsMinistryDirectoryEntry(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ModelsMinistryDirectoryEntry.fromJson(Map<String, dynamic> json) =>
      ModelsMinistryDirectoryEntry(json);

  static const schemaName = 'models.MinistryDirectoryEntry';
  final Map<String, dynamic> value;

  String? get alternativePhone => value['alternative_phone']?.toString();

  String? get availabilityHours => value['availability_hours']?.toString();

  String? get createdAt => value['created_at']?.toString();

  String? get department => value['department']?.toString();

  String? get districtId => value['district_id']?.toString();

  String? get districtName => value['district_name']?.toString();

  String? get email => value['email']?.toString();

  String? get id => value['id']?.toString();

  String? get ministry => value['ministry']?.toString();

  String? get name => value['name']?.toString();

  String? get notes => value['notes']?.toString();

  String? get officeAddress => value['office_address']?.toString();

  String? get phone => value['phone']?.toString();

  int? get priorityLevel => (value['priority_level'] as num?)?.toInt();

  String? get regionId => value['region_id']?.toString();

  String? get regionName => value['region_name']?.toString();

  String? get specialization => value['specialization']?.toString();

  String? get status => value['status']?.toString();

  String? get title => value['title']?.toString();

  String? get updatedAt => value['updated_at']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ModelsNotification {
  ModelsNotification(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ModelsNotification.fromJson(Map<String, dynamic> json) =>
      ModelsNotification(json);

  static const schemaName = 'models.Notification';
  final Map<String, dynamic> value;

  String? get actionUrl => value['action_url']?.toString();

  String? get createdAt => value['created_at']?.toString();

  String? get id => value['id']?.toString();

  bool? get isRead => value['is_read'] as bool?;

  String? get message => value['message']?.toString();

  String? get priority => value['priority']?.toString();

  String? get title => value['title']?.toString();

  String? get type => value['type']?.toString();

  String? get updatedAt => value['updated_at']?.toString();

  String? get userId => value['user_id']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ModelsNotificationCampaign {
  ModelsNotificationCampaign(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ModelsNotificationCampaign.fromJson(Map<String, dynamic> json) =>
      ModelsNotificationCampaign(json);

  static const schemaName = 'models.NotificationCampaign';
  final Map<String, dynamic> value;

  List<String> get audienceCountries {
    final raw = value['audience_countries'];
    if (raw is! List) return const [];
    return raw.whereType<String>().toList(growable: false);
  }

  List<String> get audienceRoles {
    final raw = value['audience_roles'];
    if (raw is! List) return const [];
    return raw.whereType<String>().toList(growable: false);
  }

  int? get audienceTotal => (value['audience_total'] as num?)?.toInt();

  List<String> get channels {
    final raw = value['channels'];
    if (raw is! List) return const [];
    return raw.whereType<String>().toList(growable: false);
  }

  String? get createdAt => value['created_at']?.toString();

  String? get id => value['id']?.toString();

  int? get metricsClicked => (value['metrics_clicked'] as num?)?.toInt();

  int? get metricsDelivered => (value['metrics_delivered'] as num?)?.toInt();

  int? get metricsOpened => (value['metrics_opened'] as num?)?.toInt();

  int? get metricsSent => (value['metrics_sent'] as num?)?.toInt();

  String? get name => value['name']?.toString();

  String? get scheduleEnd => value['schedule_end']?.toString();

  String? get scheduleStart => value['schedule_start']?.toString();

  String? get status => value['status']?.toString();

  String? get type => value['type']?.toString();

  String? get updatedAt => value['updated_at']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ModelsNotificationTemplate {
  ModelsNotificationTemplate(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ModelsNotificationTemplate.fromJson(Map<String, dynamic> json) =>
      ModelsNotificationTemplate(json);

  static const schemaName = 'models.NotificationTemplate';
  final Map<String, dynamic> value;

  String? get audience => value['audience']?.toString();

  String? get category => value['category']?.toString();

  int? get clickedCount => (value['clicked_count'] as num?)?.toInt();

  String? get content => value['content']?.toString();

  String? get createdAt => value['created_at']?.toString();

  String? get id => value['id']?.toString();

  String? get lastSent => value['last_sent']?.toString();

  String? get name => value['name']?.toString();

  int? get openedCount => (value['opened_count'] as num?)?.toInt();

  int? get sentCount => (value['sent_count'] as num?)?.toInt();

  String? get status => value['status']?.toString();

  String? get subject => value['subject']?.toString();

  String? get type => value['type']?.toString();

  String? get updatedAt => value['updated_at']?.toString();

  Map<String, dynamic> get variables => _jsonMap(value['variables']);

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

final class ModelsReadingProgress {
  ModelsReadingProgress(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ModelsReadingProgress.fromJson(Map<String, dynamic> json) =>
      ModelsReadingProgress(json);

  static const schemaName = 'models.ReadingProgress';
  final Map<String, dynamic> value;

  String? get createdAt => value['created_at']?.toString();

  String? get currentSection => value['current_section']?.toString();

  String? get guidelineDocumentId => value['guideline_document_id']?.toString();

  String? get id => value['id']?.toString();

  bool? get isBookmarked => value['is_bookmarked'] as bool?;

  bool? get isCompleted => value['is_completed'] as bool?;

  String? get lastReadAt => value['last_read_at']?.toString();

  String? get notes => value['notes']?.toString();

  num? get progressPercentage => value['progress_percentage'] as num?;

  int? get readingTimeSeconds =>
      (value['reading_time_seconds'] as num?)?.toInt();

  int? get totalSections => (value['total_sections'] as num?)?.toInt();

  String? get updatedAt => value['updated_at']?.toString();

  String? get userId => value['user_id']?.toString();

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

final class ModelsSupportTicket {
  ModelsSupportTicket(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ModelsSupportTicket.fromJson(Map<String, dynamic> json) =>
      ModelsSupportTicket(json);

  static const schemaName = 'models.SupportTicket';
  final Map<String, dynamic> value;

  String? get assignedTo => value['assigned_to']?.toString();

  String? get assigneeName => value['assignee_name']?.toString();

  String? get category => value['category']?.toString();

  String? get createdAt => value['created_at']?.toString();

  String? get description => value['description']?.toString();

  String? get id => value['id']?.toString();

  String? get priority => value['priority']?.toString();

  String? get status => value['status']?.toString();

  String? get subject => value['subject']?.toString();

  String? get updatedAt => value['updated_at']?.toString();

  String? get userEmail => value['user_email']?.toString();

  String? get userId => value['user_id']?.toString();

  String? get userName => value['user_name']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ModelsSupportTicketReply {
  ModelsSupportTicketReply(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ModelsSupportTicketReply.fromJson(Map<String, dynamic> json) =>
      ModelsSupportTicketReply(json);

  static const schemaName = 'models.SupportTicketReply';
  final Map<String, dynamic> value;

  String? get createdAt => value['created_at']?.toString();

  String? get id => value['id']?.toString();

  bool? get isInternal => value['is_internal'] as bool?;

  String? get message => value['message']?.toString();

  String? get ticketId => value['ticket_id']?.toString();

  String? get updatedAt => value['updated_at']?.toString();

  String? get userEmail => value['user_email']?.toString();

  String? get userId => value['user_id']?.toString();

  String? get userName => value['user_name']?.toString();

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

final class ServicesAbbreviationInput {
  ServicesAbbreviationInput(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesAbbreviationInput.fromJson(Map<String, dynamic> json) =>
      ServicesAbbreviationInput(json);

  static const schemaName = 'services.AbbreviationInput';
  final Map<String, dynamic> value;

  String? get abbreviation => value['abbreviation']?.toString();

  List<String> get categories {
    final raw = value['categories'];
    if (raw is! List) return const [];
    return raw.whereType<String>().toList(growable: false);
  }

  bool? get commonUsage => value['common_usage'] as bool?;

  String? get description => value['description']?.toString();

  String? get meaning => value['meaning']?.toString();

  List<String> get tags {
    final raw = value['tags'];
    if (raw is! List) return const [];
    return raw.whereType<String>().toList(growable: false);
  }

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

final class ServicesConsultantInput {
  ServicesConsultantInput(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesConsultantInput.fromJson(Map<String, dynamic> json) =>
      ServicesConsultantInput(json);

  static const schemaName = 'services.ConsultantInput';
  final Map<String, dynamic> value;

  String? get address => value['address']?.toString();

  String? get alternativePhone => value['alternative_phone']?.toString();

  Map<String, dynamic> get availability => _jsonMap(value['availability']);

  Map<String, dynamic> get avatar => _jsonMap(value['avatar']);

  String? get certifications => value['certifications']?.toString();

  String? get city => value['city']?.toString();

  List<String> get consultationTypes {
    final raw = value['consultation_types'];
    if (raw is! List) return const [];
    return raw.whereType<String>().toList(growable: false);
  }

  String? get country => value['country']?.toString();

  String? get department => value['department']?.toString();

  String? get email => value['email']?.toString();

  bool? get isVerified => value['is_verified'] as bool?;

  String? get licenseNumber => value['license_number']?.toString();

  String? get name => value['name']?.toString();

  String? get notes => value['notes']?.toString();

  String? get organization => value['organization']?.toString();

  String? get phone => value['phone']?.toString();

  String? get postalCode => value['postal_code']?.toString();

  String? get preferredLanguage => value['preferred_language']?.toString();

  Map<String, dynamic> get profilePicture => _jsonMap(value['profile_picture']);

  List<String> get qualifications {
    final raw = value['qualifications'];
    if (raw is! List) return const [];
    return raw.whereType<String>().toList(growable: false);
  }

  num? get rating => value['rating'] as num?;

  String? get region => value['region']?.toString();

  String? get specialty => value['specialty']?.toString();

  String? get status => value['status']?.toString();

  String? get timezone => value['timezone']?.toString();

  int? get totalConsultations =>
      (value['total_consultations'] as num?)?.toInt();

  String? get userId => value['user_id']?.toString();

  num? get yearsOfExperience => value['years_of_experience'] as num?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesConsultantItem {
  ServicesConsultantItem(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesConsultantItem.fromJson(Map<String, dynamic> json) =>
      ServicesConsultantItem(json);

  static const schemaName = 'services.ConsultantItem';
  final Map<String, dynamic> value;

  ServicesConsultantView? get item {
    final raw = value['item'];
    if (raw is! Map) return null;
    return ServicesConsultantView.fromJson(_jsonMap(raw));
  }

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesConsultantPage {
  ServicesConsultantPage(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesConsultantPage.fromJson(Map<String, dynamic> json) =>
      ServicesConsultantPage(json);

  static const schemaName = 'services.ConsultantPage';
  final Map<String, dynamic> value;

  List<ServicesConsultantView> get items {
    final raw = value['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ServicesConsultantView.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  int? get page => (value['page'] as num?)?.toInt();

  int? get perPage => (value['per_page'] as num?)?.toInt();

  int? get totalItems => (value['total_items'] as num?)?.toInt();

  int? get totalPages => (value['total_pages'] as num?)?.toInt();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesConsultantUserView {
  ServicesConsultantUserView(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesConsultantUserView.fromJson(Map<String, dynamic> json) =>
      ServicesConsultantUserView(json);

  static const schemaName = 'services.ConsultantUserView';
  final Map<String, dynamic> value;

  String? get avatar => value['avatar']?.toString();

  String? get email => value['email']?.toString();

  String? get id => value['id']?.toString();

  String? get name => value['name']?.toString();

  bool? get verified => value['verified'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesConsultantView {
  ServicesConsultantView(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesConsultantView.fromJson(Map<String, dynamic> json) =>
      ServicesConsultantView(json);

  static const schemaName = 'services.ConsultantView';
  final Map<String, dynamic> value;

  String? get address => value['address']?.toString();

  String? get alternativePhone => value['alternative_phone']?.toString();

  Map<String, dynamic> get availability => _jsonMap(value['availability']);

  Map<String, dynamic> get avatar => _jsonMap(value['avatar']);

  String? get certifications => value['certifications']?.toString();

  String? get city => value['city']?.toString();

  List<String> get consultationTypes {
    final raw = value['consultation_types'];
    if (raw is! List) return const [];
    return raw.whereType<String>().toList(growable: false);
  }

  String? get country => value['country']?.toString();

  String? get createdAt => value['created_at']?.toString();

  String? get department => value['department']?.toString();

  String? get email => value['email']?.toString();

  String? get id => value['id']?.toString();

  bool? get isVerified => value['is_verified'] as bool?;

  String? get licenseNumber => value['license_number']?.toString();

  String? get name => value['name']?.toString();

  String? get notes => value['notes']?.toString();

  String? get organization => value['organization']?.toString();

  String? get phone => value['phone']?.toString();

  String? get postalCode => value['postal_code']?.toString();

  String? get preferredLanguage => value['preferred_language']?.toString();

  Map<String, dynamic> get profilePicture => _jsonMap(value['profile_picture']);

  List<String> get qualifications {
    final raw = value['qualifications'];
    if (raw is! List) return const [];
    return raw.whereType<String>().toList(growable: false);
  }

  num? get rating => value['rating'] as num?;

  String? get region => value['region']?.toString();

  String? get specialty => value['specialty']?.toString();

  String? get status => value['status']?.toString();

  String? get timezone => value['timezone']?.toString();

  int? get totalConsultations =>
      (value['total_consultations'] as num?)?.toInt();

  String? get updatedAt => value['updated_at']?.toString();

  int? get usageCount => (value['usage_count'] as num?)?.toInt();

  ServicesConsultantUserView? get user {
    final raw = value['user'];
    if (raw is! Map) return null;
    return ServicesConsultantUserView.fromJson(_jsonMap(raw));
  }

  String? get userId => value['user_id']?.toString();

  num? get yearsOfExperience => value['years_of_experience'] as num?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesConversationCreate {
  ServicesConversationCreate(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesConversationCreate.fromJson(Map<String, dynamic> json) =>
      ServicesConversationCreate(json);

  static const schemaName = 'services.ConversationCreate';
  final Map<String, dynamic> value;

  String? get otherParticipantId => value['other_participant_id']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesConversationView {
  ServicesConversationView(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesConversationView.fromJson(Map<String, dynamic> json) =>
      ServicesConversationView(json);

  static const schemaName = 'services.ConversationView';
  final Map<String, dynamic> value;

  String? get createdAt => value['created_at']?.toString();

  String? get id => value['id']?.toString();

  String? get lastActivity => value['last_activity']?.toString();

  String? get lastMessage => value['last_message']?.toString();

  String? get lastMessageId => value['last_message_id']?.toString();

  String? get participant1Avatar => value['participant1_avatar']?.toString();

  String? get participant1Email => value['participant1_email']?.toString();

  String? get participant1Name => value['participant1_name']?.toString();

  String? get participant1UserId => value['participant1_user_id']?.toString();

  bool? get participant1Verified => value['participant1_verified'] as bool?;

  String? get participant2Avatar => value['participant2_avatar']?.toString();

  String? get participant2Email => value['participant2_email']?.toString();

  String? get participant2Name => value['participant2_name']?.toString();

  String? get participant2UserId => value['participant2_user_id']?.toString();

  bool? get participant2Verified => value['participant2_verified'] as bool?;

  String? get updatedAt => value['updated_at']?.toString();

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

final class ServicesCreateGuidelineBlockInput {
  ServicesCreateGuidelineBlockInput(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesCreateGuidelineBlockInput.fromJson(
    Map<String, dynamic> json,
  ) => ServicesCreateGuidelineBlockInput(json);

  static const schemaName = 'services.CreateGuidelineBlockInput';
  final Map<String, dynamic> value;

  Map<String, dynamic> get content => _jsonMap(value['content']);

  String? get sectionId => value['section_id']?.toString();

  int? get sortOrder => (value['sort_order'] as num?)?.toInt();

  ModelsGuidelineBlockType? get type {
    final raw = value['type'];
    if (raw is! Map) return null;
    return ModelsGuidelineBlockType.fromJson(_jsonMap(raw));
  }

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

final class ServicesCreateGuidelineSectionInput {
  ServicesCreateGuidelineSectionInput(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesCreateGuidelineSectionInput.fromJson(
    Map<String, dynamic> json,
  ) => ServicesCreateGuidelineSectionInput(json);

  static const schemaName = 'services.CreateGuidelineSectionInput';
  final Map<String, dynamic> value;

  int? get level => (value['level'] as num?)?.toInt();

  String? get parentId => value['parent_id']?.toString();

  String? get slug => value['slug']?.toString();

  int? get sortOrder => (value['sort_order'] as num?)?.toInt();

  String? get title => value['title']?.toString();

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

final class ServicesDocumentationInput {
  ServicesDocumentationInput(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesDocumentationInput.fromJson(Map<String, dynamic> json) =>
      ServicesDocumentationInput(json);

  static const schemaName = 'services.DocumentationInput';
  final Map<String, dynamic> value;

  String? get category => value['category']?.toString();

  String? get content => value['content']?.toString();

  String? get description => value['description']?.toString();

  String? get status => value['status']?.toString();

  String? get tags => value['tags']?.toString();

  String? get title => value['title']?.toString();

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

final class ServicesEmergencyProtocolInput {
  ServicesEmergencyProtocolInput(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesEmergencyProtocolInput.fromJson(Map<String, dynamic> json) =>
      ServicesEmergencyProtocolInput(json);

  static const schemaName = 'services.EmergencyProtocolInput';
  final Map<String, dynamic> value;

  String? get category => value['category']?.toString();

  Map<String, dynamic> get contactInfo => _jsonMap(value['contact_info']);

  Map<String, dynamic> get criticalActions =>
      _jsonMap(value['critical_actions']);

  String? get description => value['description']?.toString();

  Map<String, dynamic> get medications => _jsonMap(value['medications']);

  String? get priority => value['priority']?.toString();

  String? get status => value['status']?.toString();

  Map<String, dynamic> get steps => _jsonMap(value['steps']);

  List<String> get tags {
    final raw = value['tags'];
    if (raw is! List) return const [];
    return raw.whereType<String>().toList(growable: false);
  }

  String? get timeframe => value['timeframe']?.toString();

  String? get title => value['title']?.toString();

  Map<String, dynamic> get transferChecklist =>
      _jsonMap(value['transfer_checklist']);

  Map<String, dynamic> get vitalSigns => _jsonMap(value['vital_signs']);

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesFAQInput {
  ServicesFAQInput(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesFAQInput.fromJson(Map<String, dynamic> json) =>
      ServicesFAQInput(json);

  static const schemaName = 'services.FAQInput';
  final Map<String, dynamic> value;

  String? get answer => value['answer']?.toString();

  String? get authorId => value['author_id']?.toString();

  bool? get isFeatured => value['is_featured'] as bool?;

  String? get keywords => value['keywords']?.toString();

  String? get priority => value['priority']?.toString();

  String? get publishedAt => value['published_at']?.toString();

  String? get question => value['question']?.toString();

  List<String> get relatedFaqs {
    final raw = value['related_faqs'];
    if (raw is! List) return const [];
    return raw.whereType<String>().toList(growable: false);
  }

  String? get reviewDue => value['review_due']?.toString();

  String? get reviewerId => value['reviewer_id']?.toString();

  int? get sortOrder => (value['sort_order'] as num?)?.toInt();

  String? get status => value['status']?.toString();

  List<String> get tags {
    final raw = value['tags'];
    if (raw is! List) return const [];
    return raw.whereType<String>().toList(growable: false);
  }

  String? get targetAudience => value['target_audience']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesFAQTagInput {
  ServicesFAQTagInput(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesFAQTagInput.fromJson(Map<String, dynamic> json) =>
      ServicesFAQTagInput(json);

  static const schemaName = 'services.FAQTagInput';
  final Map<String, dynamic> value;

  String? get color => value['color']?.toString();

  String? get description => value['description']?.toString();

  String? get icon => value['icon']?.toString();

  bool? get isActive => value['is_active'] as bool?;

  String? get name => value['name']?.toString();

  String? get slug => value['slug']?.toString();

  int? get sortOrder => (value['sort_order'] as num?)?.toInt();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesFacilityInput {
  ServicesFacilityInput(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesFacilityInput.fromJson(Map<String, dynamic> json) =>
      ServicesFacilityInput(json);

  static const schemaName = 'services.FacilityInput';
  final Map<String, dynamic> value;

  String? get authorityId => value['authority_id']?.toString();

  String? get countyId => value['county_id']?.toString();

  String? get districtId => value['district_id']?.toString();

  String? get facilityLevelId => value['facility_level_id']?.toString();

  String? get healthSubDistrictId =>
      value['health_sub_district_id']?.toString();

  String? get healthSubRegionId => value['health_sub_region_id']?.toString();

  String? get hsdtCode => value['hsdt_code']?.toString();

  String? get name => value['name']?.toString();

  String? get nhpiCode => value['nhpi_code']?.toString();

  String? get ownershipTypeId => value['ownership_type_id']?.toString();

  String? get parishId => value['parish_id']?.toString();

  String? get regionId => value['region_id']?.toString();

  String? get subcountyId => value['subcounty_id']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesFacilityItem {
  ServicesFacilityItem(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesFacilityItem.fromJson(Map<String, dynamic> json) =>
      ServicesFacilityItem(json);

  static const schemaName = 'services.FacilityItem';
  final Map<String, dynamic> value;

  ServicesFacilityView? get item {
    final raw = value['item'];
    if (raw is! Map) return null;
    return ServicesFacilityView.fromJson(_jsonMap(raw));
  }

  String? get resource => value['resource']?.toString();

  bool? get success => value['success'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesFacilityPage {
  ServicesFacilityPage(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesFacilityPage.fromJson(Map<String, dynamic> json) =>
      ServicesFacilityPage(json);

  static const schemaName = 'services.FacilityPage';
  final Map<String, dynamic> value;

  List<ServicesFacilityView> get items {
    final raw = value['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ServicesFacilityView.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  int? get page => (value['page'] as num?)?.toInt();

  int? get perPage => (value['per_page'] as num?)?.toInt();

  String? get resource => value['resource']?.toString();

  bool? get success => value['success'] as bool?;

  int? get totalItems => (value['total_items'] as num?)?.toInt();

  int? get totalPages => (value['total_pages'] as num?)?.toInt();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesFacilityReferenceView {
  ServicesFacilityReferenceView(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesFacilityReferenceView.fromJson(Map<String, dynamic> json) =>
      ServicesFacilityReferenceView(json);

  static const schemaName = 'services.FacilityReferenceView';
  final Map<String, dynamic> value;

  String? get code => value['code']?.toString();

  String? get countyId => value['county_id']?.toString();

  String? get countyName => value['county_name']?.toString();

  String? get createdAt => value['created_at']?.toString();

  String? get districtId => value['district_id']?.toString();

  String? get districtName => value['district_name']?.toString();

  String? get healthSubRegionId => value['health_sub_region_id']?.toString();

  String? get healthSubRegionName =>
      value['health_sub_region_name']?.toString();

  String? get hsdtCode => value['hsdt_code']?.toString();

  String? get id => value['id']?.toString();

  String? get name => value['name']?.toString();

  String? get nhpiCode => value['nhpi_code']?.toString();

  String? get ownershipTypeId => value['ownership_type_id']?.toString();

  String? get ownershipTypeName => value['ownership_type_name']?.toString();

  String? get regionId => value['region_id']?.toString();

  String? get regionName => value['region_name']?.toString();

  String? get subcountyId => value['subcounty_id']?.toString();

  String? get subcountyName => value['subcounty_name']?.toString();

  String? get updatedAt => value['updated_at']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesFacilityView {
  ServicesFacilityView(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesFacilityView.fromJson(Map<String, dynamic> json) =>
      ServicesFacilityView(json);

  static const schemaName = 'services.FacilityView';
  final Map<String, dynamic> value;

  String? get authorityCode => value['authority_code']?.toString();

  String? get authorityId => value['authority_id']?.toString();

  String? get authorityName => value['authority_name']?.toString();

  String? get countyId => value['county_id']?.toString();

  String? get countyName => value['county_name']?.toString();

  String? get createdAt => value['created_at']?.toString();

  String? get districtId => value['district_id']?.toString();

  String? get districtName => value['district_name']?.toString();

  String? get facilityLevelCode => value['facility_level_code']?.toString();

  String? get facilityLevelId => value['facility_level_id']?.toString();

  String? get facilityLevelName => value['facility_level_name']?.toString();

  String? get healthSubDistrictId =>
      value['health_sub_district_id']?.toString();

  String? get healthSubDistrictName =>
      value['health_sub_district_name']?.toString();

  String? get healthSubRegionId => value['health_sub_region_id']?.toString();

  String? get healthSubRegionName =>
      value['health_sub_region_name']?.toString();

  String? get hsdtCode => value['hsdt_code']?.toString();

  String? get id => value['id']?.toString();

  String? get name => value['name']?.toString();

  String? get nhpiCode => value['nhpi_code']?.toString();

  String? get ownershipTypeCode => value['ownership_type_code']?.toString();

  String? get ownershipTypeId => value['ownership_type_id']?.toString();

  String? get ownershipTypeName => value['ownership_type_name']?.toString();

  String? get parishId => value['parish_id']?.toString();

  String? get parishName => value['parish_name']?.toString();

  String? get regionId => value['region_id']?.toString();

  String? get regionName => value['region_name']?.toString();

  String? get subcountyId => value['subcounty_id']?.toString();

  String? get subcountyName => value['subcounty_name']?.toString();

  String? get updatedAt => value['updated_at']?.toString();

  int? get usageCount => (value['usage_count'] as num?)?.toInt();

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

final class ServicesGenericPageInput {
  ServicesGenericPageInput(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesGenericPageInput.fromJson(Map<String, dynamic> json) =>
      ServicesGenericPageInput(json);

  static const schemaName = 'services.GenericPageInput';
  final Map<String, dynamic> value;

  Map<String, dynamic> get content => _jsonMap(value['content']);

  String? get description => value['description']?.toString();

  String? get key => value['key']?.toString();

  String? get title => value['title']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesGuidelineBlockOrderInput {
  ServicesGuidelineBlockOrderInput(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesGuidelineBlockOrderInput.fromJson(
    Map<String, dynamic> json,
  ) => ServicesGuidelineBlockOrderInput(json);

  static const schemaName = 'services.GuidelineBlockOrderInput';
  final Map<String, dynamic> value;

  String? get id => value['id']?.toString();

  String? get sectionId => value['section_id']?.toString();

  int? get sortOrder => (value['sort_order'] as num?)?.toInt();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesGuidelineCategoryInput {
  ServicesGuidelineCategoryInput(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesGuidelineCategoryInput.fromJson(Map<String, dynamic> json) =>
      ServicesGuidelineCategoryInput(json);

  static const schemaName = 'services.GuidelineCategoryInput';
  final Map<String, dynamic> value;

  String? get color => value['color']?.toString();

  String? get description => value['description']?.toString();

  String? get icon => value['icon']?.toString();

  String? get name => value['name']?.toString();

  String? get parentCategoryId => value['parent_category_id']?.toString();

  String? get slug => value['slug']?.toString();

  int? get sortOrder => (value['sort_order'] as num?)?.toInt();

  String? get status => value['status']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesGuidelineCollectionDTO {
  ServicesGuidelineCollectionDTO(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesGuidelineCollectionDTO.fromJson(Map<String, dynamic> json) =>
      ServicesGuidelineCollectionDTO(json);

  static const schemaName = 'services.GuidelineCollectionDTO';
  final Map<String, dynamic> value;

  String? get createdAt => value['created_at']?.toString();

  String? get description => value['description']?.toString();

  String? get id => value['id']?.toString();

  int? get itemCount => (value['item_count'] as num?)?.toInt();

  String? get name => value['name']?.toString();

  String? get updatedAt => value['updated_at']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesGuidelineCollectionInput {
  ServicesGuidelineCollectionInput(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesGuidelineCollectionInput.fromJson(
    Map<String, dynamic> json,
  ) => ServicesGuidelineCollectionInput(json);

  static const schemaName = 'services.GuidelineCollectionInput';
  final Map<String, dynamic> value;

  String? get description => value['description']?.toString();

  String? get name => value['name']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesGuidelineCollectionItemDTO {
  ServicesGuidelineCollectionItemDTO(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesGuidelineCollectionItemDTO.fromJson(
    Map<String, dynamic> json,
  ) => ServicesGuidelineCollectionItemDTO(json);

  static const schemaName = 'services.GuidelineCollectionItemDTO';
  final Map<String, dynamic> value;

  String? get addedAt => value['added_at']?.toString();

  ServicesPublicGuideline? get guideline {
    final raw = value['guideline'];
    if (raw is! Map) return null;
    return ServicesPublicGuideline.fromJson(_jsonMap(raw));
  }

  String? get id => value['id']?.toString();

  int? get sortOrder => (value['sort_order'] as num?)?.toInt();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesGuidelineCollectionItemInput {
  ServicesGuidelineCollectionItemInput(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesGuidelineCollectionItemInput.fromJson(
    Map<String, dynamic> json,
  ) => ServicesGuidelineCollectionItemInput(json);

  static const schemaName = 'services.GuidelineCollectionItemInput';
  final Map<String, dynamic> value;

  String? get guidelineId => value['guideline_id']?.toString();

  int? get sortOrder => (value['sort_order'] as num?)?.toInt();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesGuidelineDownloadDTO {
  ServicesGuidelineDownloadDTO(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesGuidelineDownloadDTO.fromJson(Map<String, dynamic> json) =>
      ServicesGuidelineDownloadDTO(json);

  static const schemaName = 'services.GuidelineDownloadDTO';
  final Map<String, dynamic> value;

  String? get assetType => value['asset_type']?.toString();

  String? get downloadedAt => value['downloaded_at']?.toString();

  String? get guidelineId => value['guideline_id']?.toString();

  String? get id => value['id']?.toString();

  String? get versionId => value['version_id']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesGuidelineDownloadInput {
  ServicesGuidelineDownloadInput(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesGuidelineDownloadInput.fromJson(Map<String, dynamic> json) =>
      ServicesGuidelineDownloadInput(json);

  static const schemaName = 'services.GuidelineDownloadInput';
  final Map<String, dynamic> value;

  String? get assetType => value['asset_type']?.toString();

  String? get guidelineId => value['guideline_id']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesGuidelineExtractionStatus {
  ServicesGuidelineExtractionStatus(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesGuidelineExtractionStatus.fromJson(
    Map<String, dynamic> json,
  ) => ServicesGuidelineExtractionStatus(json);

  static const schemaName = 'services.GuidelineExtractionStatus';
  final Map<String, dynamic> value;

  int? get assetCount => (value['asset_count'] as num?)?.toInt();

  int? get attemptCount => (value['attempt_count'] as num?)?.toInt();

  int? get blockCount => (value['block_count'] as num?)?.toInt();

  String? get completedAt => value['completed_at']?.toString();

  String? get error => value['error']?.toString();

  int? get extractionSchemaVersion =>
      (value['extraction_schema_version'] as num?)?.toInt();

  String? get jobStatus => value['job_status']?.toString();

  int? get sectionCount => (value['section_count'] as num?)?.toInt();

  String? get startedAt => value['started_at']?.toString();

  String? get versionId => value['version_id']?.toString();

  String? get versionStatus => value['version_status']?.toString();

  List<String> get warnings {
    final raw = value['warnings'];
    if (raw is! List) return const [];
    return raw.whereType<String>().toList(growable: false);
  }

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesGuidelineIndexInput {
  ServicesGuidelineIndexInput(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesGuidelineIndexInput.fromJson(Map<String, dynamic> json) =>
      ServicesGuidelineIndexInput(json);

  static const schemaName = 'services.GuidelineIndexInput';
  final Map<String, dynamic> value;

  String? get description => value['description']?.toString();

  String? get parentId => value['parent_id']?.toString();

  int? get sortOrder => (value['sort_order'] as num?)?.toInt();

  String? get title => value['title']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesGuidelinePreview {
  ServicesGuidelinePreview(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesGuidelinePreview.fromJson(Map<String, dynamic> json) =>
      ServicesGuidelinePreview(json);

  static const schemaName = 'services.GuidelinePreview';
  final Map<String, dynamic> value;

  List<ServicesPublicGuidelineBlock> get blocks {
    final raw = value['blocks'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ServicesPublicGuidelineBlock.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  List<ServicesPublicGuidelineSection> get sections {
    final raw = value['sections'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ServicesPublicGuidelineSection.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  String? get status => value['status']?.toString();

  ServicesGuidelinePublicationValidation? get validation {
    final raw = value['validation'];
    if (raw is! Map) return null;
    return ServicesGuidelinePublicationValidation.fromJson(_jsonMap(raw));
  }

  String? get versionId => value['version_id']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesGuidelinePublicationValidation {
  ServicesGuidelinePublicationValidation(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesGuidelinePublicationValidation.fromJson(
    Map<String, dynamic> json,
  ) => ServicesGuidelinePublicationValidation(json);

  static const schemaName = 'services.GuidelinePublicationValidation';
  final Map<String, dynamic> value;

  List<ServicesGuidelineReviewIssue> get errors {
    final raw = value['errors'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ServicesGuidelineReviewIssue.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  bool? get valid => value['valid'] as bool?;

  List<ServicesGuidelineReviewIssue> get warnings {
    final raw = value['warnings'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ServicesGuidelineReviewIssue.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesGuidelineReviewIssue {
  ServicesGuidelineReviewIssue(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesGuidelineReviewIssue.fromJson(Map<String, dynamic> json) =>
      ServicesGuidelineReviewIssue(json);

  static const schemaName = 'services.GuidelineReviewIssue';
  final Map<String, dynamic> value;

  String? get blockId => value['block_id']?.toString();

  String? get code => value['code']?.toString();

  String? get message => value['message']?.toString();

  String? get sectionId => value['section_id']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesGuidelineReviewWorkspace {
  ServicesGuidelineReviewWorkspace(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesGuidelineReviewWorkspace.fromJson(
    Map<String, dynamic> json,
  ) => ServicesGuidelineReviewWorkspace(json);

  static const schemaName = 'services.GuidelineReviewWorkspace';
  final Map<String, dynamic> value;

  List<ModelsGuidelineAsset> get assets {
    final raw = value['assets'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ModelsGuidelineAsset.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  List<ModelsGuidelineContentBlock> get blocks {
    final raw = value['blocks'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ModelsGuidelineContentBlock.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  List<String> get extractionWarnings {
    final raw = value['extraction_warnings'];
    if (raw is! List) return const [];
    return raw.whereType<String>().toList(growable: false);
  }

  List<ModelsGuidelineSection> get sections {
    final raw = value['sections'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ModelsGuidelineSection.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  ServicesGuidelinePublicationValidation? get validation {
    final raw = value['validation'];
    if (raw is! Map) return null;
    return ServicesGuidelinePublicationValidation.fromJson(_jsonMap(raw));
  }

  ModelsGuidelineVersion? get version {
    final raw = value['version'];
    if (raw is! Map) return null;
    return ModelsGuidelineVersion.fromJson(_jsonMap(raw));
  }

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesGuidelineSectionOrderInput {
  ServicesGuidelineSectionOrderInput(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesGuidelineSectionOrderInput.fromJson(
    Map<String, dynamic> json,
  ) => ServicesGuidelineSectionOrderInput(json);

  static const schemaName = 'services.GuidelineSectionOrderInput';
  final Map<String, dynamic> value;

  String? get id => value['id']?.toString();

  int? get level => (value['level'] as num?)?.toInt();

  String? get parentId => value['parent_id']?.toString();

  int? get sortOrder => (value['sort_order'] as num?)?.toInt();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesGuidelineTagInput {
  ServicesGuidelineTagInput(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesGuidelineTagInput.fromJson(Map<String, dynamic> json) =>
      ServicesGuidelineTagInput(json);

  static const schemaName = 'services.GuidelineTagInput';
  final Map<String, dynamic> value;

  String? get description => value['description']?.toString();

  String? get name => value['name']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesLanguageInput {
  ServicesLanguageInput(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesLanguageInput.fromJson(Map<String, dynamic> json) =>
      ServicesLanguageInput(json);

  static const schemaName = 'services.LanguageInput';
  final Map<String, dynamic> value;

  String? get code => value['code']?.toString();

  bool? get enabledForUsers => value['enabled_for_users'] as bool?;

  bool? get isActive => value['is_active'] as bool?;

  bool? get isDefault => value['is_default'] as bool?;

  String? get name => value['name']?.toString();

  String? get nativeName => value['native_name']?.toString();

  num? get progress => value['progress'] as num?;

  String? get status => value['status']?.toString();

  Map<String, dynamic> get translations => _jsonMap(value['translations']);

  String? get translationsUrl => value['translations_url']?.toString();

  num? get version => value['version'] as num?;

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

final class ServicesMarkdownDraft {
  ServicesMarkdownDraft(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesMarkdownDraft.fromJson(Map<String, dynamic> json) =>
      ServicesMarkdownDraft(json);

  static const schemaName = 'services.MarkdownDraft';
  final Map<String, dynamic> value;

  String? get content => value['content']?.toString();

  String? get etag => value['etag']?.toString();

  ModelsGuidelineMarkdownRevision? get revision {
    final raw = value['revision'];
    if (raw is! Map) return null;
    return ModelsGuidelineMarkdownRevision.fromJson(_jsonMap(raw));
  }

  bool? get saved => value['saved'] as bool?;

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesMarkdownDraftInput {
  ServicesMarkdownDraftInput(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesMarkdownDraftInput.fromJson(Map<String, dynamic> json) =>
      ServicesMarkdownDraftInput(json);

  static const schemaName = 'services.MarkdownDraftInput';
  final Map<String, dynamic> value;

  String? get changeSummary => value['change_summary']?.toString();

  String? get checkpointName => value['checkpoint_name']?.toString();

  String? get content => value['content']?.toString();

  String? get expectedRevision => value['expected_revision']?.toString();

  String? get parentRevisionId => value['parent_revision_id']?.toString();

  String? get sourceType => value['source_type']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesMarkdownRegenerationInput {
  ServicesMarkdownRegenerationInput(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesMarkdownRegenerationInput.fromJson(
    Map<String, dynamic> json,
  ) => ServicesMarkdownRegenerationInput(json);

  static const schemaName = 'services.MarkdownRegenerationInput';
  final Map<String, dynamic> value;

  String? get idempotencyKey => value['idempotency_key']?.toString();

  List<String> get operations {
    final raw = value['operations'];
    if (raw is! List) return const [];
    return raw.whereType<String>().toList(growable: false);
  }

  String? get revisionId => value['revision_id']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesMarkdownRegenerationResult {
  ServicesMarkdownRegenerationResult(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesMarkdownRegenerationResult.fromJson(
    Map<String, dynamic> json,
  ) => ServicesMarkdownRegenerationResult(json);

  static const schemaName = 'services.MarkdownRegenerationResult';
  final Map<String, dynamic> value;

  ModelsIngestionJob? get job {
    final raw = value['job'];
    if (raw is! Map) return null;
    return ModelsIngestionJob.fromJson(_jsonMap(raw));
  }

  List<String> get operations {
    final raw = value['operations'];
    if (raw is! List) return const [];
    return raw.whereType<String>().toList(growable: false);
  }

  String? get queuedAt => value['queued_at']?.toString();

  String? get revisionId => value['revision_id']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesMedicalGuidelineInput {
  ServicesMedicalGuidelineInput(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesMedicalGuidelineInput.fromJson(Map<String, dynamic> json) =>
      ServicesMedicalGuidelineInput(json);

  static const schemaName = 'services.MedicalGuidelineInput';
  final Map<String, dynamic> value;

  List<String> get categories {
    final raw = value['categories'];
    if (raw is! List) return const [];
    return raw.whereType<String>().toList(growable: false);
  }

  String? get causes => value['causes']?.toString();

  String? get classificationCritical =>
      value['classification_critical']?.toString();

  String? get classificationMild => value['classification_mild']?.toString();

  String? get classificationModerate =>
      value['classification_moderate']?.toString();

  String? get classificationSevere =>
      value['classification_severe']?.toString();

  String? get clinicalFeatures => value['clinical_features']?.toString();

  String? get conditionName => value['condition_name']?.toString();

  String? get contraindications => value['contraindications']?.toString();

  String? get definition => value['definition']?.toString();

  String? get differentialDiagnosis =>
      value['differential_diagnosis']?.toString();

  String? get dosageAdult => value['dosage_adult']?.toString();

  String? get dosagePediatric => value['dosage_pediatric']?.toString();

  String? get dosageSecondaryAdult =>
      value['dosage_secondary_adult']?.toString();

  String? get dosageSecondaryPediatric =>
      value['dosage_secondary_pediatric']?.toString();

  String? get generalManagement => value['general_management']?.toString();

  String? get healthcareLevelRequired =>
      value['healthcare_level_required']?.toString();

  String? get icd10Code => value['icd10_code']?.toString();

  String? get indexItemId => value['index_item_id']?.toString();

  bool? get isPublished => value['is_published'] as bool?;

  String? get medicationPrimary => value['medication_primary']?.toString();

  String? get medicationSecondary => value['medication_secondary']?.toString();

  String? get monitoringRequirements =>
      value['monitoring_requirements']?.toString();

  String? get preventionMeasures => value['prevention_measures']?.toString();

  String? get priority => value['priority']?.toString();

  String? get routeAdministration => value['route_administration']?.toString();

  String? get specialNotes => value['special_notes']?.toString();

  String? get status => value['status']?.toString();

  List<String> get tags {
    final raw = value['tags'];
    if (raw is! List) return const [];
    return raw.whereType<String>().toList(growable: false);
  }

  String? get targetPopulation => value['target_population']?.toString();

  String? get version => value['version']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesMergeGuidelineSectionInput {
  ServicesMergeGuidelineSectionInput(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesMergeGuidelineSectionInput.fromJson(
    Map<String, dynamic> json,
  ) => ServicesMergeGuidelineSectionInput(json);

  static const schemaName = 'services.MergeGuidelineSectionInput';
  final Map<String, dynamic> value;

  String? get targetSectionId => value['target_section_id']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesMessageCreate {
  ServicesMessageCreate(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesMessageCreate.fromJson(Map<String, dynamic> json) =>
      ServicesMessageCreate(json);

  static const schemaName = 'services.MessageCreate';
  final Map<String, dynamic> value;

  List<String> get attachments {
    final raw = value['attachments'];
    if (raw is! List) return const [];
    return raw.whereType<String>().toList(growable: false);
  }

  String? get content => value['content']?.toString();

  String? get messageType => value['message_type']?.toString();

  String? get replyToId => value['reply_to_id']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesMessageReactionInput {
  ServicesMessageReactionInput(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesMessageReactionInput.fromJson(Map<String, dynamic> json) =>
      ServicesMessageReactionInput(json);

  static const schemaName = 'services.MessageReactionInput';
  final Map<String, dynamic> value;

  bool? get active => value['active'] as bool?;

  String? get emoji => value['emoji']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesMessageReadInput {
  ServicesMessageReadInput(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesMessageReadInput.fromJson(Map<String, dynamic> json) =>
      ServicesMessageReadInput(json);

  static const schemaName = 'services.MessageReadInput';
  final Map<String, dynamic> value;

  String? get readAt => value['read_at']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesMessageView {
  ServicesMessageView(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesMessageView.fromJson(Map<String, dynamic> json) =>
      ServicesMessageView(json);

  static const schemaName = 'services.MessageView';
  final Map<String, dynamic> value;

  List<String> get attachments {
    final raw = value['attachments'];
    if (raw is! List) return const [];
    return raw.whereType<String>().toList(growable: false);
  }

  String? get content => value['content']?.toString();

  String? get conversationId => value['conversation_id']?.toString();

  String? get createdAt => value['created_at']?.toString();

  String? get editedAt => value['edited_at']?.toString();

  String? get id => value['id']?.toString();

  bool? get isEdited => value['is_edited'] as bool?;

  String? get messageType => value['message_type']?.toString();

  Map<String, dynamic> get reactions => _jsonMap(value['reactions']);

  Map<String, dynamic> get readBy => _jsonMap(value['read_by']);

  String? get replyToId => value['reply_to_id']?.toString();

  String? get senderAvatar => value['sender_avatar']?.toString();

  String? get senderEmail => value['sender_email']?.toString();

  String? get senderName => value['sender_name']?.toString();

  String? get senderUserId => value['sender_user_id']?.toString();

  bool? get senderVerified => value['sender_verified'] as bool?;

  String? get updatedAt => value['updated_at']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesMinistryDirectoryInput {
  ServicesMinistryDirectoryInput(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesMinistryDirectoryInput.fromJson(Map<String, dynamic> json) =>
      ServicesMinistryDirectoryInput(json);

  static const schemaName = 'services.MinistryDirectoryInput';
  final Map<String, dynamic> value;

  String? get alternativePhone => value['alternative_phone']?.toString();

  String? get availabilityHours => value['availability_hours']?.toString();

  String? get department => value['department']?.toString();

  String? get districtId => value['district_id']?.toString();

  String? get email => value['email']?.toString();

  String? get ministry => value['ministry']?.toString();

  String? get name => value['name']?.toString();

  String? get notes => value['notes']?.toString();

  String? get officeAddress => value['office_address']?.toString();

  String? get phone => value['phone']?.toString();

  int? get priorityLevel => (value['priority_level'] as num?)?.toInt();

  String? get regionId => value['region_id']?.toString();

  String? get specialization => value['specialization']?.toString();

  String? get status => value['status']?.toString();

  String? get title => value['title']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesNotificationCampaignInput {
  ServicesNotificationCampaignInput(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesNotificationCampaignInput.fromJson(
    Map<String, dynamic> json,
  ) => ServicesNotificationCampaignInput(json);

  static const schemaName = 'services.NotificationCampaignInput';
  final Map<String, dynamic> value;

  List<String> get audienceCountries {
    final raw = value['audience_countries'];
    if (raw is! List) return const [];
    return raw.whereType<String>().toList(growable: false);
  }

  List<String> get audienceRoles {
    final raw = value['audience_roles'];
    if (raw is! List) return const [];
    return raw.whereType<String>().toList(growable: false);
  }

  List<String> get channels {
    final raw = value['channels'];
    if (raw is! List) return const [];
    return raw.whereType<String>().toList(growable: false);
  }

  String? get name => value['name']?.toString();

  String? get scheduleEnd => value['schedule_end']?.toString();

  String? get scheduleStart => value['schedule_start']?.toString();

  String? get status => value['status']?.toString();

  String? get type => value['type']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesNotificationInput {
  ServicesNotificationInput(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesNotificationInput.fromJson(Map<String, dynamic> json) =>
      ServicesNotificationInput(json);

  static const schemaName = 'services.NotificationInput';
  final Map<String, dynamic> value;

  String? get actionUrl => value['action_url']?.toString();

  String? get message => value['message']?.toString();

  String? get priority => value['priority']?.toString();

  String? get title => value['title']?.toString();

  String? get type => value['type']?.toString();

  String? get userId => value['user_id']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesNotificationTemplateInput {
  ServicesNotificationTemplateInput(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesNotificationTemplateInput.fromJson(
    Map<String, dynamic> json,
  ) => ServicesNotificationTemplateInput(json);

  static const schemaName = 'services.NotificationTemplateInput';
  final Map<String, dynamic> value;

  String? get audience => value['audience']?.toString();

  String? get category => value['category']?.toString();

  String? get content => value['content']?.toString();

  String? get name => value['name']?.toString();

  String? get status => value['status']?.toString();

  String? get subject => value['subject']?.toString();

  String? get type => value['type']?.toString();

  Map<String, dynamic> get variables => _jsonMap(value['variables']);

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesPageResultModelsAbbreviation {
  ServicesPageResultModelsAbbreviation(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesPageResultModelsAbbreviation.fromJson(
    Map<String, dynamic> json,
  ) => ServicesPageResultModelsAbbreviation(json);

  static const schemaName = 'services.PageResult-models_Abbreviation';
  final Map<String, dynamic> value;

  List<ModelsAbbreviation> get items {
    final raw = value['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ModelsAbbreviation.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  int? get page => (value['page'] as num?)?.toInt();

  int? get perPage => (value['per_page'] as num?)?.toInt();

  int? get totalItems => (value['total_items'] as num?)?.toInt();

  int? get totalPages => (value['total_pages'] as num?)?.toInt();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesPageResultModelsDocumentation {
  ServicesPageResultModelsDocumentation(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesPageResultModelsDocumentation.fromJson(
    Map<String, dynamic> json,
  ) => ServicesPageResultModelsDocumentation(json);

  static const schemaName = 'services.PageResult-models_Documentation';
  final Map<String, dynamic> value;

  List<ModelsDocumentation> get items {
    final raw = value['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ModelsDocumentation.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  int? get page => (value['page'] as num?)?.toInt();

  int? get perPage => (value['per_page'] as num?)?.toInt();

  int? get totalItems => (value['total_items'] as num?)?.toInt();

  int? get totalPages => (value['total_pages'] as num?)?.toInt();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesPageResultModelsEmergencyProtocol {
  ServicesPageResultModelsEmergencyProtocol(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesPageResultModelsEmergencyProtocol.fromJson(
    Map<String, dynamic> json,
  ) => ServicesPageResultModelsEmergencyProtocol(json);

  static const schemaName = 'services.PageResult-models_EmergencyProtocol';
  final Map<String, dynamic> value;

  List<ModelsEmergencyProtocol> get items {
    final raw = value['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ModelsEmergencyProtocol.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  int? get page => (value['page'] as num?)?.toInt();

  int? get perPage => (value['per_page'] as num?)?.toInt();

  int? get totalItems => (value['total_items'] as num?)?.toInt();

  int? get totalPages => (value['total_pages'] as num?)?.toInt();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesPageResultModelsFAQ {
  ServicesPageResultModelsFAQ(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesPageResultModelsFAQ.fromJson(Map<String, dynamic> json) =>
      ServicesPageResultModelsFAQ(json);

  static const schemaName = 'services.PageResult-models_FAQ';
  final Map<String, dynamic> value;

  List<ModelsFAQ> get items {
    final raw = value['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ModelsFAQ.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  int? get page => (value['page'] as num?)?.toInt();

  int? get perPage => (value['per_page'] as num?)?.toInt();

  int? get totalItems => (value['total_items'] as num?)?.toInt();

  int? get totalPages => (value['total_pages'] as num?)?.toInt();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesPageResultModelsFAQTag {
  ServicesPageResultModelsFAQTag(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesPageResultModelsFAQTag.fromJson(Map<String, dynamic> json) =>
      ServicesPageResultModelsFAQTag(json);

  static const schemaName = 'services.PageResult-models_FAQTag';
  final Map<String, dynamic> value;

  List<ModelsFAQTag> get items {
    final raw = value['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ModelsFAQTag.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  int? get page => (value['page'] as num?)?.toInt();

  int? get perPage => (value['per_page'] as num?)?.toInt();

  int? get totalItems => (value['total_items'] as num?)?.toInt();

  int? get totalPages => (value['total_pages'] as num?)?.toInt();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesPageResultModelsGenericPage {
  ServicesPageResultModelsGenericPage(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesPageResultModelsGenericPage.fromJson(
    Map<String, dynamic> json,
  ) => ServicesPageResultModelsGenericPage(json);

  static const schemaName = 'services.PageResult-models_GenericPage';
  final Map<String, dynamic> value;

  List<ModelsGenericPage> get items {
    final raw = value['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ModelsGenericPage.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  int? get page => (value['page'] as num?)?.toInt();

  int? get perPage => (value['per_page'] as num?)?.toInt();

  int? get totalItems => (value['total_items'] as num?)?.toInt();

  int? get totalPages => (value['total_pages'] as num?)?.toInt();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesPageResultModelsGuidelineCategory {
  ServicesPageResultModelsGuidelineCategory(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesPageResultModelsGuidelineCategory.fromJson(
    Map<String, dynamic> json,
  ) => ServicesPageResultModelsGuidelineCategory(json);

  static const schemaName = 'services.PageResult-models_GuidelineCategory';
  final Map<String, dynamic> value;

  List<ModelsGuidelineCategory> get items {
    final raw = value['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ModelsGuidelineCategory.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  int? get page => (value['page'] as num?)?.toInt();

  int? get perPage => (value['per_page'] as num?)?.toInt();

  int? get totalItems => (value['total_items'] as num?)?.toInt();

  int? get totalPages => (value['total_pages'] as num?)?.toInt();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesPageResultModelsGuidelineIndexEntry {
  ServicesPageResultModelsGuidelineIndexEntry(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesPageResultModelsGuidelineIndexEntry.fromJson(
    Map<String, dynamic> json,
  ) => ServicesPageResultModelsGuidelineIndexEntry(json);

  static const schemaName = 'services.PageResult-models_GuidelineIndexEntry';
  final Map<String, dynamic> value;

  List<ModelsGuidelineIndexEntry> get items {
    final raw = value['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ModelsGuidelineIndexEntry.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  int? get page => (value['page'] as num?)?.toInt();

  int? get perPage => (value['per_page'] as num?)?.toInt();

  int? get totalItems => (value['total_items'] as num?)?.toInt();

  int? get totalPages => (value['total_pages'] as num?)?.toInt();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesPageResultModelsGuidelineTag {
  ServicesPageResultModelsGuidelineTag(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesPageResultModelsGuidelineTag.fromJson(
    Map<String, dynamic> json,
  ) => ServicesPageResultModelsGuidelineTag(json);

  static const schemaName = 'services.PageResult-models_GuidelineTag';
  final Map<String, dynamic> value;

  List<ModelsGuidelineTag> get items {
    final raw = value['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ModelsGuidelineTag.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  int? get page => (value['page'] as num?)?.toInt();

  int? get perPage => (value['per_page'] as num?)?.toInt();

  int? get totalItems => (value['total_items'] as num?)?.toInt();

  int? get totalPages => (value['total_pages'] as num?)?.toInt();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesPageResultModelsMedicalGuideline {
  ServicesPageResultModelsMedicalGuideline(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesPageResultModelsMedicalGuideline.fromJson(
    Map<String, dynamic> json,
  ) => ServicesPageResultModelsMedicalGuideline(json);

  static const schemaName = 'services.PageResult-models_MedicalGuideline';
  final Map<String, dynamic> value;

  List<ModelsMedicalGuideline> get items {
    final raw = value['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ModelsMedicalGuideline.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  int? get page => (value['page'] as num?)?.toInt();

  int? get perPage => (value['per_page'] as num?)?.toInt();

  int? get totalItems => (value['total_items'] as num?)?.toInt();

  int? get totalPages => (value['total_pages'] as num?)?.toInt();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesPageResultModelsMinistryDirectoryEntry {
  ServicesPageResultModelsMinistryDirectoryEntry(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesPageResultModelsMinistryDirectoryEntry.fromJson(
    Map<String, dynamic> json,
  ) => ServicesPageResultModelsMinistryDirectoryEntry(json);

  static const schemaName = 'services.PageResult-models_MinistryDirectoryEntry';
  final Map<String, dynamic> value;

  List<ModelsMinistryDirectoryEntry> get items {
    final raw = value['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ModelsMinistryDirectoryEntry.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  int? get page => (value['page'] as num?)?.toInt();

  int? get perPage => (value['per_page'] as num?)?.toInt();

  int? get totalItems => (value['total_items'] as num?)?.toInt();

  int? get totalPages => (value['total_pages'] as num?)?.toInt();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesPageResultModelsReadingProgress {
  ServicesPageResultModelsReadingProgress(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesPageResultModelsReadingProgress.fromJson(
    Map<String, dynamic> json,
  ) => ServicesPageResultModelsReadingProgress(json);

  static const schemaName = 'services.PageResult-models_ReadingProgress';
  final Map<String, dynamic> value;

  List<ModelsReadingProgress> get items {
    final raw = value['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ModelsReadingProgress.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  int? get page => (value['page'] as num?)?.toInt();

  int? get perPage => (value['per_page'] as num?)?.toInt();

  int? get totalItems => (value['total_items'] as num?)?.toInt();

  int? get totalPages => (value['total_pages'] as num?)?.toInt();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesPageResultModelsSupportTicket {
  ServicesPageResultModelsSupportTicket(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesPageResultModelsSupportTicket.fromJson(
    Map<String, dynamic> json,
  ) => ServicesPageResultModelsSupportTicket(json);

  static const schemaName = 'services.PageResult-models_SupportTicket';
  final Map<String, dynamic> value;

  List<ModelsSupportTicket> get items {
    final raw = value['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ModelsSupportTicket.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  int? get page => (value['page'] as num?)?.toInt();

  int? get perPage => (value['per_page'] as num?)?.toInt();

  int? get totalItems => (value['total_items'] as num?)?.toInt();

  int? get totalPages => (value['total_pages'] as num?)?.toInt();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesPageResultModelsSupportTicketReply {
  ServicesPageResultModelsSupportTicketReply(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesPageResultModelsSupportTicketReply.fromJson(
    Map<String, dynamic> json,
  ) => ServicesPageResultModelsSupportTicketReply(json);

  static const schemaName = 'services.PageResult-models_SupportTicketReply';
  final Map<String, dynamic> value;

  List<ModelsSupportTicketReply> get items {
    final raw = value['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ModelsSupportTicketReply.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  int? get page => (value['page'] as num?)?.toInt();

  int? get perPage => (value['per_page'] as num?)?.toInt();

  int? get totalItems => (value['total_items'] as num?)?.toInt();

  int? get totalPages => (value['total_pages'] as num?)?.toInt();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesPageResultServicesConversationView {
  ServicesPageResultServicesConversationView(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesPageResultServicesConversationView.fromJson(
    Map<String, dynamic> json,
  ) => ServicesPageResultServicesConversationView(json);

  static const schemaName = 'services.PageResult-services_ConversationView';
  final Map<String, dynamic> value;

  List<ServicesConversationView> get items {
    final raw = value['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ServicesConversationView.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  int? get page => (value['page'] as num?)?.toInt();

  int? get perPage => (value['per_page'] as num?)?.toInt();

  int? get totalItems => (value['total_items'] as num?)?.toInt();

  int? get totalPages => (value['total_pages'] as num?)?.toInt();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesPageResultServicesMessageView {
  ServicesPageResultServicesMessageView(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesPageResultServicesMessageView.fromJson(
    Map<String, dynamic> json,
  ) => ServicesPageResultServicesMessageView(json);

  static const schemaName = 'services.PageResult-services_MessageView';
  final Map<String, dynamic> value;

  List<ServicesMessageView> get items {
    final raw = value['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ServicesMessageView.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  int? get page => (value['page'] as num?)?.toInt();

  int? get perPage => (value['per_page'] as num?)?.toInt();

  int? get totalItems => (value['total_items'] as num?)?.toInt();

  int? get totalPages => (value['total_pages'] as num?)?.toInt();

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

final class ServicesPublicGuideline {
  ServicesPublicGuideline(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesPublicGuideline.fromJson(Map<String, dynamic> json) =>
      ServicesPublicGuideline(json);

  static const schemaName = 'services.PublicGuideline';
  final Map<String, dynamic> value;

  String? get country => value['country']?.toString();

  String? get description => value['description']?.toString();

  String? get id => value['id']?.toString();

  String? get language => value['language']?.toString();

  String? get lastUpdated => value['last_updated']?.toString();

  String? get programArea => value['program_area']?.toString();

  String? get publicationDate => value['publication_date']?.toString();

  String? get reviewDate => value['review_date']?.toString();

  String? get slug => value['slug']?.toString();

  String? get sourceOrg => value['source_org']?.toString();

  String? get title => value['title']?.toString();

  String? get version => value['version']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesPublicGuidelineAlgorithm {
  ServicesPublicGuidelineAlgorithm(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesPublicGuidelineAlgorithm.fromJson(
    Map<String, dynamic> json,
  ) => ServicesPublicGuidelineAlgorithm(json);

  static const schemaName = 'services.PublicGuidelineAlgorithm';
  final Map<String, dynamic> value;

  ModelsGuidelineAlgorithmBlockPayload? get content {
    final raw = value['content'];
    if (raw is! Map) return null;
    return ModelsGuidelineAlgorithmBlockPayload.fromJson(_jsonMap(raw));
  }

  String? get id => value['id']?.toString();

  int? get pageEnd => (value['page_end'] as num?)?.toInt();

  int? get pageStart => (value['page_start'] as num?)?.toInt();

  String? get sectionId => value['section_id']?.toString();

  int? get sortOrder => (value['sort_order'] as num?)?.toInt();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesPublicGuidelineAssetLink {
  ServicesPublicGuidelineAssetLink(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesPublicGuidelineAssetLink.fromJson(
    Map<String, dynamic> json,
  ) => ServicesPublicGuidelineAssetLink(json);

  static const schemaName = 'services.PublicGuidelineAssetLink';
  final Map<String, dynamic> value;

  String? get assetId => value['asset_id']?.toString();

  String? get checksum => value['checksum']?.toString();

  String? get expiresAt => value['expires_at']?.toString();

  String? get mimeType => value['mime_type']?.toString();

  String? get originalFilename => value['original_filename']?.toString();

  int? get sizeBytes => (value['size_bytes'] as num?)?.toInt();

  String? get type => value['type']?.toString();

  String? get url => value['url']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesPublicGuidelineBlock {
  ServicesPublicGuidelineBlock(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesPublicGuidelineBlock.fromJson(Map<String, dynamic> json) =>
      ServicesPublicGuidelineBlock(json);

  static const schemaName = 'services.PublicGuidelineBlock';
  final Map<String, dynamic> value;

  Map<String, dynamic> get content => _jsonMap(value['content']);

  String? get id => value['id']?.toString();

  int? get pageEnd => (value['page_end'] as num?)?.toInt();

  int? get pageStart => (value['page_start'] as num?)?.toInt();

  String? get sectionId => value['section_id']?.toString();

  int? get sortOrder => (value['sort_order'] as num?)?.toInt();

  ModelsGuidelineBlockType? get type {
    final raw = value['type'];
    if (raw is! Map) return null;
    return ModelsGuidelineBlockType.fromJson(_jsonMap(raw));
  }

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesPublicGuidelineFigure {
  ServicesPublicGuidelineFigure(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesPublicGuidelineFigure.fromJson(Map<String, dynamic> json) =>
      ServicesPublicGuidelineFigure(json);

  static const schemaName = 'services.PublicGuidelineFigure';
  final Map<String, dynamic> value;

  ServicesPublicGuidelineAssetLink? get asset {
    final raw = value['asset'];
    if (raw is! Map) return null;
    return ServicesPublicGuidelineAssetLink.fromJson(_jsonMap(raw));
  }

  ModelsGuidelineFigureBlockPayload? get content {
    final raw = value['content'];
    if (raw is! Map) return null;
    return ModelsGuidelineFigureBlockPayload.fromJson(_jsonMap(raw));
  }

  String? get id => value['id']?.toString();

  int? get pageEnd => (value['page_end'] as num?)?.toInt();

  int? get pageStart => (value['page_start'] as num?)?.toInt();

  String? get sectionId => value['section_id']?.toString();

  int? get sortOrder => (value['sort_order'] as num?)?.toInt();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesPublicGuidelineManifest {
  ServicesPublicGuidelineManifest(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesPublicGuidelineManifest.fromJson(Map<String, dynamic> json) =>
      ServicesPublicGuidelineManifest(json);

  static const schemaName = 'services.PublicGuidelineManifest';
  final Map<String, dynamic> value;

  int? get algorithmCount => (value['algorithm_count'] as num?)?.toInt();

  int? get blockCount => (value['block_count'] as num?)?.toInt();

  String? get checksum => value['checksum']?.toString();

  String? get etag => value['etag']?.toString();

  ModelsGuidelineExtractionQuality? get extractionQuality {
    final raw = value['extraction_quality'];
    if (raw is! Map) return null;
    return ModelsGuidelineExtractionQuality.fromJson(_jsonMap(raw));
  }

  int? get figureCount => (value['figure_count'] as num?)?.toInt();

  String? get generatedAt => value['generated_at']?.toString();

  String? get guidelineId => value['guideline_id']?.toString();

  bool? get hasAlgorithms => value['has_algorithms'] as bool?;

  bool? get hasChapters => value['has_chapters'] as bool?;

  bool? get hasFigures => value['has_figures'] as bool?;

  bool? get hasKeyPoints => value['has_key_points'] as bool?;

  bool? get hasOfflinePackage => value['has_offline_package'] as bool?;

  bool? get hasOriginalPdf => value['has_original_pdf'] as bool?;

  bool? get hasTables => value['has_tables'] as bool?;

  int? get packageVersion => (value['package_version'] as num?)?.toInt();

  int? get schemaVersion => (value['schema_version'] as num?)?.toInt();

  int? get sectionCount => (value['section_count'] as num?)?.toInt();

  int? get tableCount => (value['table_count'] as num?)?.toInt();

  String? get version => value['version']?.toString();

  String? get versionId => value['version_id']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesPublicGuidelineSection {
  ServicesPublicGuidelineSection(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesPublicGuidelineSection.fromJson(Map<String, dynamic> json) =>
      ServicesPublicGuidelineSection(json);

  static const schemaName = 'services.PublicGuidelineSection';
  final Map<String, dynamic> value;

  String? get id => value['id']?.toString();

  int? get level => (value['level'] as num?)?.toInt();

  int? get pageEnd => (value['page_end'] as num?)?.toInt();

  int? get pageStart => (value['page_start'] as num?)?.toInt();

  String? get parentId => value['parent_id']?.toString();

  String? get slug => value['slug']?.toString();

  int? get sortOrder => (value['sort_order'] as num?)?.toInt();

  String? get title => value['title']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesPublicGuidelineSectionDetail {
  ServicesPublicGuidelineSectionDetail(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesPublicGuidelineSectionDetail.fromJson(
    Map<String, dynamic> json,
  ) => ServicesPublicGuidelineSectionDetail(json);

  static const schemaName = 'services.PublicGuidelineSectionDetail';
  final Map<String, dynamic> value;

  List<ServicesPublicGuidelineBlock> get blocks {
    final raw = value['blocks'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ServicesPublicGuidelineBlock.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  ServicesPublicGuidelineSection? get section {
    final raw = value['section'];
    if (raw is! Map) return null;
    return ServicesPublicGuidelineSection.fromJson(_jsonMap(raw));
  }

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesPublicGuidelineTable {
  ServicesPublicGuidelineTable(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesPublicGuidelineTable.fromJson(Map<String, dynamic> json) =>
      ServicesPublicGuidelineTable(json);

  static const schemaName = 'services.PublicGuidelineTable';
  final Map<String, dynamic> value;

  ModelsGuidelineTableBlockPayload? get content {
    final raw = value['content'];
    if (raw is! Map) return null;
    return ModelsGuidelineTableBlockPayload.fromJson(_jsonMap(raw));
  }

  String? get id => value['id']?.toString();

  int? get pageEnd => (value['page_end'] as num?)?.toInt();

  int? get pageStart => (value['page_start'] as num?)?.toInt();

  String? get sectionId => value['section_id']?.toString();

  int? get sortOrder => (value['sort_order'] as num?)?.toInt();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesReadingProgressInput {
  ServicesReadingProgressInput(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesReadingProgressInput.fromJson(Map<String, dynamic> json) =>
      ServicesReadingProgressInput(json);

  static const schemaName = 'services.ReadingProgressInput';
  final Map<String, dynamic> value;

  String? get currentSection => value['current_section']?.toString();

  bool? get isBookmarked => value['is_bookmarked'] as bool?;

  bool? get isCompleted => value['is_completed'] as bool?;

  String? get lastReadAt => value['last_read_at']?.toString();

  String? get notes => value['notes']?.toString();

  num? get progressPercentage => value['progress_percentage'] as num?;

  int? get readingTimeSeconds =>
      (value['reading_time_seconds'] as num?)?.toInt();

  int? get totalSections => (value['total_sections'] as num?)?.toInt();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesRegionChildren {
  ServicesRegionChildren(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesRegionChildren.fromJson(Map<String, dynamic> json) =>
      ServicesRegionChildren(json);

  static const schemaName = 'services.RegionChildren';
  final Map<String, dynamic> value;

  List<ServicesFacilityReferenceView> get districts {
    final raw = value['districts'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ServicesFacilityReferenceView.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  List<ServicesFacilityReferenceView> get healthSubRegions {
    final raw = value['health_sub_regions'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => ServicesFacilityReferenceView.fromJson(_jsonMap(item)))
        .toList(growable: false);
  }

  ServicesFacilityReferenceView? get region {
    final raw = value['region'];
    if (raw is! Map) return null;
    return ServicesFacilityReferenceView.fromJson(_jsonMap(raw));
  }

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesReorderGuidelineBlocksInput {
  ServicesReorderGuidelineBlocksInput(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesReorderGuidelineBlocksInput.fromJson(
    Map<String, dynamic> json,
  ) => ServicesReorderGuidelineBlocksInput(json);

  static const schemaName = 'services.ReorderGuidelineBlocksInput';
  final Map<String, dynamic> value;

  List<ServicesGuidelineBlockOrderInput> get blocks {
    final raw = value['blocks'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (item) => ServicesGuidelineBlockOrderInput.fromJson(_jsonMap(item)),
        )
        .toList(growable: false);
  }

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesReorderGuidelineSectionsInput {
  ServicesReorderGuidelineSectionsInput(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesReorderGuidelineSectionsInput.fromJson(
    Map<String, dynamic> json,
  ) => ServicesReorderGuidelineSectionsInput(json);

  static const schemaName = 'services.ReorderGuidelineSectionsInput';
  final Map<String, dynamic> value;

  List<ServicesGuidelineSectionOrderInput> get sections {
    final raw = value['sections'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (item) => ServicesGuidelineSectionOrderInput.fromJson(_jsonMap(item)),
        )
        .toList(growable: false);
  }

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesReviewGuidelineAssetInput {
  ServicesReviewGuidelineAssetInput(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesReviewGuidelineAssetInput.fromJson(
    Map<String, dynamic> json,
  ) => ServicesReviewGuidelineAssetInput(json);

  static const schemaName = 'services.ReviewGuidelineAssetInput';
  final Map<String, dynamic> value;

  ModelsGuidelineBlockReviewStatus? get status {
    final raw = value['status'];
    if (raw is! Map) return null;
    return ModelsGuidelineBlockReviewStatus.fromJson(_jsonMap(raw));
  }

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesReviewGuidelineBlockInput {
  ServicesReviewGuidelineBlockInput(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesReviewGuidelineBlockInput.fromJson(
    Map<String, dynamic> json,
  ) => ServicesReviewGuidelineBlockInput(json);

  static const schemaName = 'services.ReviewGuidelineBlockInput';
  final Map<String, dynamic> value;

  ModelsGuidelineBlockReviewStatus? get status {
    final raw = value['status'];
    if (raw is! Map) return null;
    return ModelsGuidelineBlockReviewStatus.fromJson(_jsonMap(raw));
  }

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

final class ServicesSplitGuidelineSectionInput {
  ServicesSplitGuidelineSectionInput(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesSplitGuidelineSectionInput.fromJson(
    Map<String, dynamic> json,
  ) => ServicesSplitGuidelineSectionInput(json);

  static const schemaName = 'services.SplitGuidelineSectionInput';
  final Map<String, dynamic> value;

  String? get blockId => value['block_id']?.toString();

  int? get level => (value['level'] as num?)?.toInt();

  String? get slug => value['slug']?.toString();

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

final class ServicesSupportReplyCreate {
  ServicesSupportReplyCreate(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesSupportReplyCreate.fromJson(Map<String, dynamic> json) =>
      ServicesSupportReplyCreate(json);

  static const schemaName = 'services.SupportReplyCreate';
  final Map<String, dynamic> value;

  bool? get isInternal => value['is_internal'] as bool?;

  String? get message => value['message']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesSupportTicketCreate {
  ServicesSupportTicketCreate(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesSupportTicketCreate.fromJson(Map<String, dynamic> json) =>
      ServicesSupportTicketCreate(json);

  static const schemaName = 'services.SupportTicketCreate';
  final Map<String, dynamic> value;

  String? get category => value['category']?.toString();

  String? get description => value['description']?.toString();

  String? get priority => value['priority']?.toString();

  String? get subject => value['subject']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesSupportTicketUpdate {
  ServicesSupportTicketUpdate(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesSupportTicketUpdate.fromJson(Map<String, dynamic> json) =>
      ServicesSupportTicketUpdate(json);

  static const schemaName = 'services.SupportTicketUpdate';
  final Map<String, dynamic> value;

  String? get assignedTo => value['assigned_to']?.toString();

  String? get category => value['category']?.toString();

  String? get description => value['description']?.toString();

  String? get priority => value['priority']?.toString();

  String? get status => value['status']?.toString();

  String? get subject => value['subject']?.toString();

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

final class ServicesUpdateGuidelineBlockInput {
  ServicesUpdateGuidelineBlockInput(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesUpdateGuidelineBlockInput.fromJson(
    Map<String, dynamic> json,
  ) => ServicesUpdateGuidelineBlockInput(json);

  static const schemaName = 'services.UpdateGuidelineBlockInput';
  final Map<String, dynamic> value;

  Map<String, dynamic> get content => _jsonMap(value['content']);

  String? get sectionId => value['section_id']?.toString();

  int? get sortOrder => (value['sort_order'] as num?)?.toInt();

  String? get type => value['type']?.toString();

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

final class ServicesUpdateGuidelineSectionInput {
  ServicesUpdateGuidelineSectionInput(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesUpdateGuidelineSectionInput.fromJson(
    Map<String, dynamic> json,
  ) => ServicesUpdateGuidelineSectionInput(json);

  static const schemaName = 'services.UpdateGuidelineSectionInput';
  final Map<String, dynamic> value;

  int? get level => (value['level'] as num?)?.toInt();

  String? get parentId => value['parent_id']?.toString();

  String? get slug => value['slug']?.toString();

  int? get sortOrder => (value['sort_order'] as num?)?.toInt();

  String? get title => value['title']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesUsageAggregate {
  ServicesUsageAggregate(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesUsageAggregate.fromJson(Map<String, dynamic> json) =>
      ServicesUsageAggregate(json);

  static const schemaName = 'services.UsageAggregate';
  final Map<String, dynamic> value;

  int? get count => (value['count'] as num?)?.toInt();

  String? get eventType => value['event_type']?.toString();

  Map<String, dynamic> toJson() => Map.of(value);
}

final class ServicesUsageEventInput {
  ServicesUsageEventInput(Map<String, dynamic> value)
    : value = UnmodifiableMapView<String, dynamic>(Map.of(value));

  factory ServicesUsageEventInput.fromJson(Map<String, dynamic> json) =>
      ServicesUsageEventInput(json);

  static const schemaName = 'services.UsageEventInput';
  final Map<String, dynamic> value;

  String? get idempotencyKey => value['idempotency_key']?.toString();

  String? get resourceId => value['resource_id']?.toString();

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
