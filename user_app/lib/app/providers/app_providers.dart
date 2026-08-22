import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

import 'package:user_app/features/calculators/data/repositories/calculator_repository.dart';
import 'package:user_app/features/calculators/data/repositories/calculator_local_repository.dart';
import 'package:user_app/features/consultants/data/repositories/consultant_repository.dart';
import 'package:user_app/features/consultants/data/repositories/consultant_local_repository.dart';
import 'package:user_app/features/content/data/repositories/content_reference_repository.dart';
import 'package:user_app/features/conversations/data/repositories/conversation_repository.dart';
import 'package:user_app/features/conversations/data/repositories/conversation_local_repository.dart';
import 'package:user_app/features/drugs/data/repositories/drug_reference_repository.dart';
import 'package:user_app/features/drugs/data/repositories/drug_reference_local_repository.dart';
import 'package:user_app/features/drugs/data/repositories/drug_repository.dart';
import 'package:user_app/features/drugs/data/repositories/drug_local_repository.dart';
import 'package:user_app/features/facilities/data/repositories/facility_repository.dart';
import 'package:user_app/features/facilities/data/repositories/facility_local_repository.dart';
import 'package:user_app/features/guidelines/data/repositories/guideline_content_repository.dart';
import 'package:user_app/features/guidelines/data/repositories/guideline_publication_repository.dart';
import 'package:user_app/features/guidelines/data/repositories/guildline_content_local_repository.dart';
import 'package:user_app/features/abbreviations/data/repositories/abbreviation_local_repository.dart';
import 'package:user_app/features/support/data/repositories/help_content_repository.dart';
import 'package:user_app/features/support/data/repositories/help_content_local_repository.dart';
import 'package:user_app/features/notifications/data/repositories/notification_repository.dart';
import 'package:user_app/features/notifications/data/repositories/notification_local_repository.dart';
import 'package:user_app/features/guidelines/data/repositories/progress_usage_repository.dart';
import 'package:user_app/features/library/data/repositories/guideline_library_repository.dart';
import 'package:user_app/features/outbreaks/data/repositories/outbreak_repository.dart';
import 'package:user_app/features/ai_assistant/data/repositories/rag_repository.dart';
import 'package:user_app/features/support/data/repositories/support_repository.dart';
import 'package:user_app/features/support/data/repositories/support_local_repository.dart';
import 'package:user_app/features/authentication/data/repositories/user_repository.dart';
import 'package:user_app/features/ai_assistant/data/services/ai_context_service.dart';
import 'package:user_app/features/authentication/data/datasources/auth_remote_datasource.dart';
import 'package:user_app/core/network/api_client.dart';
import 'package:user_app/core/network/ttl_response_cache.dart';
import 'package:user_app/core/storage/database/database_provider.dart';
import 'package:user_app/core/storage/local_cache_service.dart';
import 'package:user_app/core/services/download_service.dart';
import 'package:user_app/features/content/data/repositories/generic_page_local_repository.dart';
import 'package:user_app/features/content/data/repositories/ministry_directory_local_repository.dart';
import 'package:user_app/core/services/firebase_service.dart';
import 'package:user_app/core/debug/network_inspector.dart';

/// Core dependency graph. Runtime services are constructed once during
/// bootstrap and injected through ProviderScope overrides.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw StateError('SharedPreferences must be overridden at startup'),
);

final backendApiServiceProvider = Provider<BackendApiService>(
  (ref) => throw StateError('BackendApiService must be overridden at startup'),
);

final authServiceProvider = Provider<AuthService>(
  (ref) => throw StateError('AuthService must be overridden at startup'),
);

final aiContextServiceProvider = Provider<AiContextService>(
  (ref) => throw StateError('AiContextService must be overridden at startup'),
);

final firebaseServiceProvider = Provider<MediGuideFirebaseService>(
  (ref) => throw StateError('Firebase service must be overridden at startup'),
);

final networkInspectorProvider = Provider<NetworkInspectorStore>(
  (ref) => throw StateError('Network inspector must be overridden at startup'),
);

final firebaseOpenedMessageProvider = StreamProvider<RemoteMessage>(
  (ref) => ref.watch(firebaseServiceProvider).openedMessages,
);

final firebaseForegroundMessageProvider = StreamProvider<RemoteMessage>(
  (ref) => ref.watch(firebaseServiceProvider).foregroundMessages,
);

final outbreakBannerEnabledProvider = StreamProvider<bool>((ref) {
  return ref.watch(firebaseServiceProvider).outbreakBannerStates;
});

final outbreakFeatureEnabledProvider = Provider<bool>((ref) {
  return ref.watch(outbreakBannerEnabledProvider).valueOrNull ??
      ref.watch(firebaseServiceProvider).outbreakBannerEnabled;
});

final notificationPermissionProvider =
    StreamProvider<AppNotificationPermissionState>((ref) async* {
      final service = ref.watch(firebaseServiceProvider);
      yield service.permissionState;
      yield* service.permissionStates;
    });

final notificationInboxRefreshProvider = StateProvider<int>((ref) => 0);

final ragRepositoryProvider = Provider.autoDispose<RagAssistant>(
  (ref) => RagRepository(
    ref.watch(backendApiServiceProvider),
    ref.watch(sharedPreferencesProvider),
  ),
);

final ttlResponseCacheProvider = Provider<TtlResponseCache>(
  (ref) => TtlResponseCache(database: ref.watch(appDatabaseProvider)),
);

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepository(ref.watch(backendApiServiceProvider)),
);

final calculatorRepositoryProvider = Provider<CalculatorRepository>(
  (ref) => CalculatorRepository(
    ref.watch(backendApiServiceProvider),
    ref.watch(calculatorLocalRepositoryProvider),
  ),
);

final drugRepositoryProvider = Provider<DrugRepository>(
  (ref) => DrugRepository(
    ref.watch(backendApiServiceProvider),
    ref.watch(drugLocalRepositoryProvider),
  ),
);

final drugReferenceRepositoryProvider = Provider<DrugReferenceRepository>(
  (ref) => DrugReferenceRepository(
    ref.watch(backendApiServiceProvider),
    ref.watch(drugReferenceLocalRepositoryProvider),
    cache: ref.watch(ttlResponseCacheProvider),
  ),
);

final guidelineContentRepositoryProvider = Provider<GuidelineContentRepository>(
  (ref) => GuidelineContentRepository(
    ref.watch(backendApiServiceProvider),
    ref.watch(guidelineContentLocalRepositoryProvider),
    ref.watch(abbreviationLocalRepositoryProvider),
  ),
);

final guidelinePublicationRepositoryProvider =
    Provider<GuidelinePublicationRepository>(
      (ref) => GuidelinePublicationRepository(
        ref.watch(backendApiServiceProvider),
        ref.watch(localCacheServiceProvider),
      ),
    );

final facilityRepositoryProvider = Provider<FacilityRepository>(
  (ref) => FacilityRepository(
    ref.watch(backendApiServiceProvider),
    ref.watch(facilityLocalRepositoryProvider),
    cache: ref.watch(ttlResponseCacheProvider),
  ),
);

final consultantRepositoryProvider = Provider<ConsultantRepository>(
  (ref) => ConsultantRepository(
    ref.watch(backendApiServiceProvider),
    ref.watch(consultantLocalRepositoryProvider),
  ),
);

final supportRepositoryProvider = Provider<SupportRepository>(
  (ref) => SupportRepository(
    ref.watch(backendApiServiceProvider),
    ref.watch(supportLocalRepositoryProvider),
    userId: ref.watch(authServiceProvider).currentUser.value?.id ?? '',
  ),
);

final helpContentRepositoryProvider = Provider<HelpContentRepository>(
  (ref) => HelpContentRepository(
    ref.watch(backendApiServiceProvider),
    ref.watch(helpContentLocalRepositoryProvider),
    cache: ref.watch(ttlResponseCacheProvider),
  ),
);

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepository(
    ref.watch(backendApiServiceProvider),
    ref.watch(notificationLocalRepositoryProvider),
    userId: ref.watch(authServiceProvider).currentUser.value?.id ?? '',
  ),
);

final notificationUnreadCountProvider = StreamProvider.autoDispose<int>((
  ref,
) async* {
  final repository = ref.watch(notificationRepositoryProvider);
  if (repository.userId.trim().isEmpty) {
    yield 0;
    return;
  }
  yield await repository.unreadCount();
  yield* repository.watchUnreadCount();
});

final genericPageRepositoryProvider = Provider<GenericPageRepository>(
  (ref) => GenericPageRepository(
    ref.watch(backendApiServiceProvider),
    ref.watch(genericPageLocalRepositoryProvider),
  ),
);

final ministryDirectoryRepositoryProvider =
    Provider<MinistryDirectoryRepository>(
      (ref) => MinistryDirectoryRepository(
        ref.watch(backendApiServiceProvider),
        ref.watch(ministryDirectoryLocalRepositoryProvider),
      ),
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
    ref.watch(localCacheServiceProvider),
  ),
);

final guidelineLibraryRepositoryProvider = Provider<GuidelineLibraryRepository>(
  (ref) => GuidelineLibraryRepository(
    ref.watch(backendApiServiceProvider),
    ref.watch(localCacheServiceProvider),
  ),
);

final outbreakRepositoryProvider = Provider<OutbreakRepository>(
  (ref) => OutbreakRepository(
    ref.watch(backendApiServiceProvider),
    ref.watch(localCacheServiceProvider),
  ),
);

final guidelineDownloadServiceProvider = Provider<GuidelineDownloadService>((
  ref,
) {
  final service = GuidelineDownloadService(
    Dio(),
    ref.watch(localCacheServiceProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

final usageRepositoryProvider = Provider<UsageRepository>(
  (ref) => UsageRepository(ref.watch(backendApiServiceProvider)),
);

final conversationRepositoryProvider = Provider<ConversationRepository>(
  (ref) => ConversationRepository(
    ref.watch(backendApiServiceProvider),
    ref.watch(conversationLocalRepositoryProvider),
    userId: ref.watch(authServiceProvider).currentUser.value?.id ?? '',
  ),
);
