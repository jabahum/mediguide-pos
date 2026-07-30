/// Export all model classes for easy importing
/// Usage: import 'models.dart'; to access all models
library;

// Core models
export 'api_record.dart';
export 'base_model.dart';
export 'user.dart';
export 'role.dart';

// Drug-related models
export 'drug.dart';
export 'drug_category.dart';
export 'drug_tag.dart';
export 'drug_class.dart';
export 'therapeutic_category.dart';

// Consultant model
export 'consultant.dart';
export 'ministry_directory.dart';

// Geographic models
export 'region.dart';
export 'health_sub_region.dart';
export 'district.dart';
export 'county.dart';
export 'subcounty.dart';
export 'parish.dart';
export 'health_sub_district.dart';

// Administrative models
export 'facility_level.dart';
export 'ownership_type.dart';
export 'authority.dart';
export 'health_facility.dart';

// Guideline-related models
export 'abbreviation.dart';
export 'guideline.dart';
export 'guideline_category.dart';
export 'guideline_tag.dart';
export 'guideline_index.dart';

// Calculator model
export 'calculator.dart';
export 'calculator_usage_log.dart';

// Usage tracking models
export 'guideline_usage_log.dart';
export 'drug_usage_log.dart';
export 'abbreviation_usage_log.dart';
export 'consultant_usage_log.dart';
export 'facility_usage_log.dart';
export 'ai_usage_log.dart';

// Notification model
export 'my_notification.dart';

// Reading progress model
export 'reading_progress.dart';

// Settings model
export 'settings.dart';

// Language model
export 'language_model.dart';

// Support/Help models
export 'support_ticket.dart';
export 'support_ticket_reply.dart';
export 'faq.dart';

// Chat models
export 'conversation.dart';
export 'message.dart';

// Enums
export '../enums/user_enums.dart';
export '../enums/drug_enums.dart';
export '../enums/consultant_enums.dart';
export '../enums/ministry_directory_enums.dart';
export '../enums/common_enums.dart';
export '../enums/calculator_enums.dart';

// Extensions
export '../extensions/enum_extensions.dart';
