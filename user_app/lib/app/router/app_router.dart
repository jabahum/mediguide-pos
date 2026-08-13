import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:user_app/app/router/app_navigator.dart';
import 'package:user_app/app/router/route_guards.dart';
import 'package:user_app/app/router/route_names.dart';

import 'package:user_app/shared/models/models.dart';

import 'package:user_app/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:user_app/features/authentication/presentation/screens/forgot_password_page.dart';
import 'package:user_app/features/authentication/presentation/screens/login_page.dart';
import 'package:user_app/features/authentication/presentation/screens/onboarding_page.dart';
import 'package:user_app/features/authentication/presentation/screens/register_page.dart';

import 'package:user_app/features/abbreviations/presentation/screens/abbreviations_page.dart';
import 'package:user_app/features/ai_assistant/presentation/screens/ai_assistant_page.dart';
import 'package:user_app/features/all_actions/presentation/screens/all_actions_page.dart';
import 'package:user_app/features/calculators/presentation/screens/tools_page.dart';
import 'package:user_app/features/calculators/presentation/screens/use_calculator_page.dart';
import 'package:user_app/features/consultants/presentation/screens/consultants_page.dart';
import 'package:user_app/features/content/presentation/screens/about_us_page.dart';
import 'package:user_app/features/content/presentation/screens/generic_viewer_page.dart';
import 'package:user_app/features/content/presentation/screens/ministry_directory_page.dart';
import 'package:user_app/features/content/presentation/screens/terms_and_conditions_page.dart';
import 'package:user_app/features/conversations/presentation/screens/chat_interface_page.dart';
import 'package:user_app/features/conversations/presentation/screens/chat_list_page.dart';
import 'package:user_app/features/drugs/presentation/screens/drug_index_page.dart';
import 'package:user_app/features/facilities/presentation/screens/health_facility_detail_page.dart';
import 'package:user_app/features/facilities/presentation/screens/health_infrastructure_page.dart';
import 'package:user_app/features/guidelines/presentation/screens/guidelines_indexer_page.dart';
import 'package:user_app/features/guidelines/presentation/screens/guidelines_page.dart';
import 'package:user_app/features/guidelines/presentation/screens/read_guideline_page.dart';
import 'package:user_app/features/guidelines/presentation/screens/publication_catalogue_page.dart';
import 'package:user_app/features/guidelines/presentation/screens/publication_guideline_page.dart';
import 'package:user_app/features/guidelines/presentation/screens/publication_clinical_viewers.dart';
import 'package:user_app/features/home/presentation/screens/home_page.dart';
import 'package:user_app/features/search/presentation/screens/global_search_page.dart';
import 'package:user_app/features/library/presentation/screens/my_library_page.dart';
import 'package:user_app/features/navigation/presentation/screens/guest_more_page.dart';
import 'package:user_app/features/navigation/presentation/screens/main_page.dart';
import 'package:user_app/features/outbreaks/presentation/screens/outbreak_screens.dart';
import 'package:user_app/features/notifications/presentation/screens/notifications_page.dart';
import 'package:user_app/features/profile/presentation/screens/profile_page.dart';
import 'package:user_app/features/downloads/presentation/screens/offline_content_page.dart';
import 'package:user_app/features/documents/presentation/screens/document_reader_page.dart';
import 'package:user_app/features/support/presentation/screens/faq_page.dart';
import 'package:user_app/features/support/presentation/screens/help_center_page.dart';

export 'route_names.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier();

  ref.onDispose(refreshNotifier.dispose);

  ref.listen(authControllerProvider, (_, _) => refreshNotifier.notify());

  return GoRouter(
    navigatorKey: AppNavigator.navigatorKey,
    initialLocation: AppRoutes.main,
    refreshListenable: refreshNotifier,
    redirect: (_, state) => appRouteGuard(ref, state),
    routes: <RouteBase>[
      // Authentication
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

      // Main navigation
      GoRoute(path: AppRoutes.main, builder: (_, _) => const MainPage()),
      GoRoute(path: AppRoutes.home, builder: (_, _) => const HomePage()),
      GoRoute(
        path: AppRoutes.search,
        builder: (_, _) => const GlobalSearchPage(),
      ),
      GoRoute(
        path: AppRoutes.library,
        builder: (_, _) => const MyLibraryPage(),
      ),
      GoRoute(
        path: AppRoutes.offlineContent,
        builder: (_, _) => const OfflineContentPage(),
      ),
      GoRoute(
        path: AppRoutes.documentReader,
        builder: (_, state) {
          final args = state.extra;
          if (args is! DocumentReaderArgs) {
            return const Scaffold(
              body: Center(child: Text('Document information is missing.')),
            );
          }
          return DocumentReaderPage(args: args);
        },
      ),
      GoRoute(path: AppRoutes.more, builder: (_, _) => const GuestMorePage()),
      GoRoute(path: AppRoutes.profile, builder: (_, _) => const ProfilePage()),

      // Guidelines
      GoRoute(
        path: AppRoutes.guidelines,
        builder: (_, state) {
          return GuidelinesPage(arguments: state.extra);
        },
      ),
      GoRoute(
        path: AppRoutes.publicGuidelines,
        builder: (_, _) => const PublicationCataloguePage(),
      ),
      GoRoute(
        path: AppRoutes.publicGuidelineDetails,
        builder: (_, state) => PublicationGuidelinePage(
          guidelineId: state.pathParameters['guidelineId'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.publicGuidelineReader,
        builder: (_, state) => PublicationGuidelinePage(
          guidelineId: state.pathParameters['guidelineId'] ?? '',
          readerOnly: true,
        ),
      ),
      GoRoute(
        path: AppRoutes.publicGuidelineTable,
        builder: (_, state) => PublicationTablePage(
          guidelineId: state.pathParameters['guidelineId'] ?? '',
          blockId: state.pathParameters['blockId'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.publicGuidelineAlgorithm,
        builder: (_, state) => PublicationAlgorithmPage(
          guidelineId: state.pathParameters['guidelineId'] ?? '',
          blockId: state.pathParameters['blockId'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.outbreakHub,
        builder: (_, _) => const OutbreakHubPage(),
      ),
      GoRoute(
        path: AppRoutes.outbreakDetails,
        builder: (_, state) => OutbreakDetailPage(
          outbreakId: state.pathParameters['outbreakId'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.situationReports,
        builder: (_, _) => const SituationReportsPage(),
      ),
      GoRoute(
        path: AppRoutes.situationReportDetails,
        builder: (_, state) => SituationReportDetailPage(
          reportId: state.pathParameters['reportId'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.guidelineDetails,
        builder: (_, state) {
          final guidelineId = state.pathParameters['guidelineId'];

          if (guidelineId == null || guidelineId.isEmpty) {
            return const _InvalidRoutePage(message: 'Guideline ID is missing.');
          }

          return ReadGuidelinePage(arguments: state.extra ?? guidelineId);
        },
      ),
      GoRoute(
        path: AppRoutes.guidelinesIndexer,
        builder: (_, state) {
          return GuidelinesIndexerPage(arguments: state.extra);
        },
      ),

      // Clinical content
      GoRoute(
        path: AppRoutes.drugIndex,
        builder: (_, _) => const DrugIndexPage(),
      ),
      GoRoute(
        path: AppRoutes.abbreviations,
        builder: (_, _) => const AbbreviationsPage(),
      ),
      GoRoute(
        path: AppRoutes.genericViewer,
        builder: (_, state) {
          return GenericViewerPage(
            argument: state.extra,
            pageKey: state.uri.queryParameters['key'],
          );
        },
      ),
      GoRoute(
        path: AppRoutes.viewerDetails,
        builder: (_, state) {
          final contentType = state.pathParameters['contentType'];
          final contentId = state.pathParameters['contentId'];

          if (contentType == null ||
              contentType.isEmpty ||
              contentId == null ||
              contentId.isEmpty) {
            return const _InvalidRoutePage(
              message: 'Viewer content information is missing.',
            );
          }

          return GenericViewerPage(
            argument: state.extra,
            pageKey: state.uri.queryParameters['key'],
          );
        },
      ),

      // Calculators
      GoRoute(
        path: AppRoutes.tools,
        builder: (_, state) {
          return ToolsPage(arguments: state.extra);
        },
      ),
      GoRoute(
        path: AppRoutes.calculators,
        builder: (_, state) {
          return UseCalculatorPage(arguments: state.extra);
        },
      ),
      GoRoute(
        path: AppRoutes.calculatorDetails,
        builder: (_, state) {
          final calculatorId = state.pathParameters['calculatorId'];

          if (calculatorId == null || calculatorId.isEmpty) {
            return const _InvalidRoutePage(
              message: 'Calculator ID is missing.',
            );
          }

          return UseCalculatorPage(arguments: state.extra ?? calculatorId);
        },
      ),

      // Health directory
      GoRoute(
        path: AppRoutes.healthInfrastructure,
        builder: (_, state) {
          return HealthInfrastructurePage(arguments: state.extra);
        },
      ),
      GoRoute(
        path: AppRoutes.healthFacilities,
        builder: (_, state) => HealthInfrastructurePage(arguments: state.extra),
      ),
      GoRoute(
        path: AppRoutes.healthFacilityDetails,
        builder: (_, state) {
          final facilityId = state.pathParameters['facilityId'];

          if (facilityId == null || facilityId.isEmpty) {
            return const _InvalidRoutePage(
              message: 'Health facility ID is missing.',
            );
          }

          return HealthFacilityDetailPage(
            facilityId: facilityId,
            facility: state.extra is HealthFacility
                ? state.extra as HealthFacility
                : null,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.consultants,
        builder: (_, state) {
          return ConsultantsPage(arguments: state.extra);
        },
      ),
      GoRoute(
        path: AppRoutes.consultantDetails,
        builder: (_, state) {
          final consultantId = state.pathParameters['consultantId'];

          if (consultantId == null || consultantId.isEmpty) {
            return const _InvalidRoutePage(
              message: 'Consultant ID is missing.',
            );
          }

          return ConsultantsPage(arguments: state.extra ?? consultantId);
        },
      ),
      GoRoute(
        path: AppRoutes.ministryDirectory,
        builder: (_, state) {
          return MinistryDirectoryPage(arguments: state.extra);
        },
      ),

      // AI and conversations
      GoRoute(
        path: AppRoutes.aiAssistant,
        builder: (_, state) {
          return AiAssistantPage(arguments: state.extra);
        },
      ),
      GoRoute(
        path: AppRoutes.chatList,
        builder: (_, _) => const ChatListPage(),
      ),
      GoRoute(
        path: AppRoutes.chatDetails,
        builder: (_, state) {
          final conversationId = state.pathParameters['conversationId'];

          if (conversationId == null || conversationId.isEmpty) {
            return const _InvalidRoutePage(
              message: 'Conversation ID is missing.',
            );
          }

          return ChatInterfacePage(
            otherUser: state.extra is User ? state.extra as User : null,
          );
        },
      ),

      // General pages
      GoRoute(
        path: AppRoutes.allActions,
        builder: (_, _) => const AllActionsPage(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (_, _) => const NotificationsPage(),
      ),
      GoRoute(
        path: AppRoutes.termsAndConditions,
        builder: (_, _) => const TermsAndConditionsPage(),
      ),
      GoRoute(path: AppRoutes.aboutUs, builder: (_, _) => const AboutUsPage()),
      GoRoute(
        path: AppRoutes.helpCenter,
        builder: (_, _) => const HelpCenterPage(),
      ),
      GoRoute(path: AppRoutes.faq, builder: (_, _) => const FaqPage()),
    ],
    errorBuilder: (BuildContext context, GoRouterState state) {
      return _InvalidRoutePage(
        message: state.error?.toString() ?? 'Page not found.',
      );
    },
  );
});

final class _RouterRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

final class _InvalidRoutePage extends StatelessWidget {
  const _InvalidRoutePage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page unavailable')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
