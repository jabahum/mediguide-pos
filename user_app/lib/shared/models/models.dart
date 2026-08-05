/// Export all model classes for easy importing
/// Usage: import 'package:user_app/shared/models/models.dart'; to access all models
library;

// Core models
export 'package:user_app/shared/models/paginated_response.dart';
export 'package:user_app/features/authentication/data/models/user.dart';
export 'package:user_app/features/authentication/data/models/role.dart';

// Drug-related models
export 'package:user_app/features/drugs/data/models/drug.dart';
export 'package:user_app/features/drugs/data/models/drug_category.dart';
export 'package:user_app/features/drugs/data/models/drug_tag.dart';
export 'package:user_app/features/drugs/data/models/drug_class.dart';
export 'package:user_app/features/drugs/data/models/therapeutic_category.dart';

// Consultant model
export 'package:user_app/features/consultants/data/models/consultant.dart';
export 'package:user_app/features/content/data/models/ministry_directory.dart';

// Geographic models
export 'package:user_app/features/facilities/data/models/region.dart';
export 'package:user_app/features/facilities/data/models/health_sub_region.dart';
export 'package:user_app/features/facilities/data/models/district.dart';
export 'package:user_app/features/facilities/data/models/county.dart';
export 'package:user_app/features/facilities/data/models/subcounty.dart';
export 'package:user_app/features/facilities/data/models/parish.dart';
export 'package:user_app/features/facilities/data/models/health_sub_district.dart';

// Administrative models
export 'package:user_app/features/facilities/data/models/facility_level.dart';
export 'package:user_app/features/facilities/data/models/ownership_type.dart';
export 'package:user_app/features/facilities/data/models/authority.dart';
export 'package:user_app/features/facilities/data/models/health_facility.dart';

// Guideline-related models
export 'package:user_app/features/abbreviations/data/models/abbreviation.dart';
export 'package:user_app/features/guidelines/data/models/guideline.dart';
export 'package:user_app/features/guidelines/data/models/guideline_category.dart';
export 'package:user_app/features/guidelines/data/models/guideline_tag.dart';
export 'package:user_app/features/guidelines/data/models/guideline_index.dart';

// Calculator model
export 'package:user_app/features/calculators/data/models/calculator.dart';
export 'package:user_app/features/calculators/data/models/calculator_usage_log.dart';

// Usage tracking models
export 'package:user_app/features/guidelines/data/models/guideline_usage_log.dart';
export 'package:user_app/features/drugs/data/models/drug_usage_log.dart';
export 'package:user_app/features/abbreviations/data/models/abbreviation_usage_log.dart';
export 'package:user_app/features/consultants/data/models/consultant_usage_log.dart';
export 'package:user_app/features/facilities/data/models/facility_usage_log.dart';
export 'package:user_app/features/ai_assistant/data/models/ai_usage_log.dart';

// Notification model
export 'package:user_app/features/notifications/data/models/my_notification.dart';

// Reading progress model
export 'package:user_app/features/guidelines/data/models/reading_progress.dart';

// Settings model
export 'package:user_app/features/settings/data/models/settings.dart';

// Language model
export 'package:user_app/features/content/data/models/language_model.dart';

// Support/Help models
export 'package:user_app/features/support/data/models/support_ticket.dart';
export 'package:user_app/features/support/data/models/support_ticket_reply.dart';
export 'package:user_app/features/support/data/models/faq.dart';
export 'package:user_app/features/support/data/models/documentation.dart';

// Chat models
export 'package:user_app/features/conversations/data/models/conversation.dart';
export 'package:user_app/features/conversations/data/models/message.dart';

// Enums
export 'package:user_app/features/authentication/data/models/user_enums.dart';
export 'package:user_app/features/drugs/data/models/drug_enums.dart';
export 'package:user_app/features/consultants/data/models/consultant_enums.dart';
export 'package:user_app/features/content/data/models/ministry_directory_enums.dart';
export 'package:user_app/shared/models/common_enums.dart';
export 'package:user_app/features/calculators/data/models/calculator_enums.dart';

// Extensions
export 'package:user_app/shared/models/enum_extensions.dart';
