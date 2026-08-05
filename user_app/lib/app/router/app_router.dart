import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:user_app/app/router/app_navigator.dart';
import 'package:user_app/shared/models/models.dart';
import 'package:user_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:user_app/features/abbreviations/presentation/screens/abbreviations_page.dart';
import 'package:user_app/features/content/presentation/screens/about_us_page.dart';
import 'package:user_app/features/ai_assistant/presentation/screens/ai_assistant_page.dart';
import 'package:user_app/features/all_actions/presentation/screens/all_actions_page.dart';
import 'package:user_app/features/conversations/presentation/screens/chat_interface_page.dart';
import 'package:user_app/features/conversations/presentation/screens/chat_list_page.dart';
import 'package:user_app/features/consultants/presentation/screens/consultants_page.dart';
import 'package:user_app/features/drugs/presentation/screens/drug_index_page.dart';
import 'package:user_app/features/support/presentation/screens/faq_page.dart';
import 'package:user_app/features/authentication/presentation/screens/forgot_password_page.dart';
import 'package:user_app/features/content/presentation/screens/generic_viewer_page.dart';
import 'package:user_app/features/guidelines/presentation/screens/guidelines_indexer_page.dart';
import 'package:user_app/features/guidelines/presentation/screens/guidelines_page.dart';
import 'package:user_app/features/facilities/presentation/screens/health_facility_detail_page.dart';
import 'package:user_app/features/facilities/presentation/screens/health_infrastructure_page.dart';
import 'package:user_app/features/support/presentation/screens/help_center_page.dart';
import 'package:user_app/features/home/presentation/screens/home_page.dart';
import 'package:user_app/features/authentication/presentation/screens/login_page.dart';
import 'package:user_app/features/navigation/presentation/screens/main_page.dart';
import 'package:user_app/features/content/presentation/screens/ministry_directory_page.dart';
import 'package:user_app/features/notifications/presentation/screens/notifications_page.dart';
import 'package:user_app/features/authentication/presentation/screens/onboarding_page.dart';
import 'package:user_app/features/profile/presentation/screens/profile_page.dart';
import 'package:user_app/features/guidelines/presentation/screens/read_guideline_page.dart';
import 'package:user_app/features/authentication/presentation/screens/register_page.dart';
import 'package:user_app/features/content/presentation/screens/terms_and_conditions_page.dart';
import 'package:user_app/features/calculators/presentation/screens/tools_page.dart';
import 'package:user_app/features/calculators/presentation/screens/use_calculator_page.dart';
import 'package:user_app/app/router/route_guards.dart';
import 'package:user_app/app/router/route_names.dart';

export 'route_names.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefreshNotifier();
  ref
    ..onDispose(refresh.dispose)
    ..listen(authControllerProvider, (_, _) => refresh.notify());

  return GoRouter(
    navigatorKey: AppNavigator.navigatorKey,
    initialLocation: AppRoutes.main,
    refreshListenable: refresh,
    redirect: (_, state) => appRouteGuard(ref, state),
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
