import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app_navigator.dart';
import '../../data/models/models.dart';
import '../../features/auth/auth_controller.dart';
import '../../features/auth/auth_state.dart';
import '../../features/abbreviations/abbreviations_page.dart';
import '../../features/about_us/about_us_page.dart';
import '../../features/ai_assistant/ai_assistant_page.dart';
import '../../features/all_actions/all_actions_page.dart';
import '../../features/chat_interface/chat_interface_page.dart';
import '../../features/chat_list/chat_list_page.dart';
import '../../features/consultants/consultants_page.dart';
import '../../features/drug_index/drug_index_page.dart';
import '../../features/faq/faq_page.dart';
import '../../features/forgot_password/forgot_password_page.dart';
import '../../features/generic_viewer/generic_viewer_page.dart';
import '../../features/guidelines_indexer/guidelines_indexer_page.dart';
import '../../features/guidelines/guidelines_page.dart';
import '../../features/health_infrastructure/health_facility_detail_page.dart';
import '../../features/health_infrastructure/health_infrastructure_page.dart';
import '../../features/help_center/help_center_page.dart';
import '../../features/home/home_page.dart';
import '../../features/login/login_page.dart';
import '../../features/navigation/main_page.dart';
import '../../features/ministry_directory/ministry_directory_page.dart';
import '../../features/notifications/notifications_page.dart';
import '../../features/onboarding/onboarding_page.dart';
import '../../features/profile/profile_page.dart';
import '../../features/read_guideline/read_guideline_page.dart';
import '../../features/register/register_page.dart';
import '../../features/terms_and_conditions/terms_and_conditions_page.dart';
import '../../features/tools/tools_page.dart';
import '../../features/use_calculator/use_calculator_page.dart';
import '../../utils/constants.dart';
import '../../utils/preference_utils.dart';

part 'app_routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefreshNotifier();
  ref
    ..onDispose(refresh.dispose)
    ..listen(authControllerProvider, (_, _) => refresh.notify());

  return GoRouter(
    navigatorKey: AppNavigator.navigatorKey,
    initialLocation: AppRoutes.main,
    refreshListenable: refresh,
    redirect: (_, state) {
      final auth = ref.read(authControllerProvider);
      if (auth.isLoading) return null;

      final phase = auth.valueOrNull?.phase ?? AuthPhase.unauthenticated;
      final authenticated = auth.valueOrNull?.isAuthenticated ?? false;
      final location = state.matchedLocation;
      final publicRoute = AppRoutes.publicRoutes.contains(location);

      if (!PreferenceUtils.containsKey(SharedPreferencesKeys.notFirstTime) &&
          location != AppRoutes.onboarding) {
        return AppRoutes.onboarding;
      }
      if (!authenticated && !publicRoute && phase != AuthPhase.authenticating) {
        return AppRoutes.login;
      }
      if (authenticated &&
          (location == AppRoutes.login || location == AppRoutes.register)) {
        return AppRoutes.main;
      }
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginPage()),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, _) => const OnboardingPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, _) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, _) => const ForgotPasswordPage(),
      ),
      GoRoute(path: AppRoutes.main, builder: (_, _) => const MainPage()),
      GoRoute(path: AppRoutes.home, builder: (_, _) => const HomePage()),
      GoRoute(
        path: AppRoutes.guidelines,
        builder: (_, state) => GuidelinesPage(arguments: state.extra),
      ),
      GoRoute(
        path: AppRoutes.tools,
        builder: (_, state) => ToolsPage(arguments: state.extra),
      ),
      GoRoute(path: AppRoutes.profile, builder: (_, _) => const ProfilePage()),
      GoRoute(
        path: AppRoutes.drugIndex,
        builder: (_, _) => const DrugIndexPage(),
      ),
      GoRoute(
        path: AppRoutes.allActions,
        builder: (_, _) => const AllActionsPage(),
      ),
      GoRoute(
        path: AppRoutes.abbreviations,
        builder: (_, _) => const AbbreviationsPage(),
      ),
      GoRoute(
        path: AppRoutes.healthInfrastructure,
        builder: (_, state) => HealthInfrastructurePage(arguments: state.extra),
      ),
      GoRoute(
        path: AppRoutes.healthFacility,
        builder: (_, state) => HealthFacilityDetailPage(
          facility: state.extra is HealthFacility
              ? state.extra! as HealthFacility
              : null,
        ),
      ),
      GoRoute(
        path: AppRoutes.consultants,
        builder: (_, state) => ConsultantsPage(arguments: state.extra),
      ),
      GoRoute(
        path: AppRoutes.termsAndConditions,
        builder: (_, _) => const TermsAndConditionsPage(),
      ),
      GoRoute(path: AppRoutes.aboutUs, builder: (_, _) => const AboutUsPage()),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (_, _) => const NotificationsPage(),
      ),
      GoRoute(
        path: AppRoutes.useCalculator,
        builder: (_, state) => UseCalculatorPage(arguments: state.extra),
      ),
      GoRoute(
        path: AppRoutes.readGuideline,
        builder: (_, state) => ReadGuidelinePage(arguments: state.extra),
      ),
      GoRoute(
        path: AppRoutes.aiAssistant,
        builder: (_, state) => AiAssistantPage(arguments: state.extra),
      ),
      GoRoute(
        path: AppRoutes.ministryDirectory,
        builder: (_, state) => MinistryDirectoryPage(arguments: state.extra),
      ),
      GoRoute(
        path: AppRoutes.guidelinesIndexer,
        builder: (_, state) => GuidelinesIndexerPage(arguments: state.extra),
      ),
      GoRoute(
        path: AppRoutes.helpCenter,
        builder: (_, _) => const HelpCenterPage(),
      ),
      GoRoute(path: AppRoutes.faq, builder: (_, _) => const FaqPage()),
      GoRoute(
        path: AppRoutes.chatInterface,
        builder: (_, state) => ChatInterfacePage(
          otherUser: state.extra is User ? state.extra! as User : null,
        ),
      ),
      GoRoute(
        path: AppRoutes.chatList,
        builder: (_, _) => const ChatListPage(),
      ),
      GoRoute(
        path: AppRoutes.genericViewer,
        builder: (_, state) => GenericViewerPage(
          argument: state.extra,
          pageKey: state.uri.queryParameters['key'],
        ),
      ),
    ],
  );
});

final class _RouterRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}
