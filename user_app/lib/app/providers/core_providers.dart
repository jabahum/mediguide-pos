import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/repositories/calculator_repository.dart';
import '../data/repositories/consultant_repository.dart';
import '../data/repositories/content_reference_repository.dart';
import '../data/repositories/conversation_repository.dart';
import '../data/repositories/drug_reference_repository.dart';
import '../data/repositories/facility_repository.dart';
import '../data/repositories/guideline_content_repository.dart';
import '../data/repositories/help_content_repository.dart';
import '../data/repositories/notification_repository.dart';
import '../data/repositories/progress_usage_repository.dart';
import '../data/repositories/support_repository.dart';
import '../data/repositories/user_repository.dart';
import '../data/services/ai_context_service.dart';
import '../data/services/auth_service.dart';
import '../data/services/backend_api_service.dart';
import '../data/services/main_service.dart';
import '../data/services/openai_service.dart';
import '../data/services/ttl_response_cache.dart';

/// Core dependency graph for the incremental Riverpod migration.
///
/// The service providers use the existing GetX registrations only as a
/// temporary compatibility bridge. They are intentionally overridable so
/// migrated features and tests no longer depend on the service locator. The
/// bridge can be deleted after the final GetX consumer has moved.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw StateError('SharedPreferences must be overridden at startup'),
);

final backendApiServiceProvider = Provider<BackendApiService>(
  (ref) => Get.find<BackendApiService>(),
);

final legacyAuthServiceProvider = Provider<AuthService>(
  (ref) => Get.find<AuthService>(),
);

final mainServiceProvider = Provider<MainService>(
  (ref) => Get.find<MainService>(),
);

final openAiServiceProvider = Provider<OpenAiService>(
  (ref) => Get.find<OpenAiService>(),
);

final aiContextServiceProvider = Provider<AiContextService>(
  (ref) => Get.find<AiContextService>(),
);

final ttlResponseCacheProvider = Provider<TtlResponseCache>(
  (ref) => TtlResponseCache(preferences: ref.watch(sharedPreferencesProvider)),
);

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepository(ref.watch(backendApiServiceProvider)),
);

final calculatorRepositoryProvider = Provider<CalculatorRepository>(
  (ref) => CalculatorRepository(ref.watch(backendApiServiceProvider)),
);

final drugRepositoryProvider = Provider<DrugRepository>(
  (ref) => DrugRepository(ref.watch(backendApiServiceProvider)),
);

final drugReferenceRepositoryProvider = Provider<DrugReferenceRepository>(
  (ref) => DrugReferenceRepository(
    ref.watch(backendApiServiceProvider),
    cache: ref.watch(ttlResponseCacheProvider),
  ),
);

final guidelineContentRepositoryProvider = Provider<GuidelineContentRepository>(
  (ref) => GuidelineContentRepository(ref.watch(backendApiServiceProvider)),
);

final facilityRepositoryProvider = Provider<FacilityRepository>(
  (ref) => FacilityRepository(
    ref.watch(backendApiServiceProvider),
    cache: ref.watch(ttlResponseCacheProvider),
  ),
);

final consultantRepositoryProvider = Provider<ConsultantRepository>(
  (ref) => ConsultantRepository(ref.watch(backendApiServiceProvider)),
);

final supportRepositoryProvider = Provider<SupportRepository>(
  (ref) => SupportRepository(ref.watch(backendApiServiceProvider)),
);

final helpContentRepositoryProvider = Provider<HelpContentRepository>(
  (ref) => HelpContentRepository(
    ref.watch(backendApiServiceProvider),
    cache: ref.watch(ttlResponseCacheProvider),
  ),
);

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepository(ref.watch(backendApiServiceProvider)),
);

final genericPageRepositoryProvider = Provider<GenericPageRepository>(
  (ref) => GenericPageRepository(ref.watch(backendApiServiceProvider)),
);

final ministryDirectoryRepositoryProvider =
    Provider<MinistryDirectoryRepository>(
      (ref) =>
          MinistryDirectoryRepository(ref.watch(backendApiServiceProvider)),
    );

final languageRepositoryProvider = Provider<LanguageRepository>(
  (ref) => LanguageRepository(
    ref.watch(backendApiServiceProvider),
    cache: ref.watch(ttlResponseCacheProvider),
  ),
);

final readingProgressRepositoryProvider = Provider<ReadingProgressRepository>(
  (ref) => ReadingProgressRepository(
    ref.watch(backendApiServiceProvider),
    preferences: ref.watch(sharedPreferencesProvider),
  ),
);

final usageRepositoryProvider = Provider<UsageRepository>(
  (ref) => UsageRepository(ref.watch(backendApiServiceProvider)),
);

final conversationRepositoryProvider = Provider<ConversationRepository>(
  (ref) => ConversationRepository(ref.watch(backendApiServiceProvider)),
);
