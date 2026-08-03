import 'package:get/get.dart';
import 'package:user_app/app/modules/ai_assistant_module/ai_assistant_binding.dart';
import 'package:user_app/app/modules/ai_assistant_module/ai_assistant_page.dart';
import 'package:user_app/app/modules/generic_viewer_module/generic_viewer_binding.dart';
import 'package:user_app/app/modules/generic_viewer_module/generic_viewer_page.dart';
import 'package:user_app/app/modules/chat_interface_module/chat_interface_binding.dart';
import 'package:user_app/app/modules/chat_interface_module/chat_interface_page.dart';
import 'package:user_app/app/modules/chat_list_module/chat_list_binding.dart';
import 'package:user_app/app/modules/chat_list_module/chat_list_page.dart';
import 'package:user_app/app/modules/help_center_module/help_center_binding.dart';
import 'package:user_app/app/modules/help_center_module/help_center_page.dart';
import 'package:user_app/app/modules/faq_module/faq_binding.dart';
import 'package:user_app/app/modules/faq_module/faq_page.dart';
import 'package:user_app/app/modules/guidelines_indexer_module/guidelines_indexer_binding.dart';
import 'package:user_app/app/modules/guidelines_indexer_module/guidelines_indexer_page.dart';
import 'package:user_app/app/modules/ministry_directory_module/ministry_directory_binding.dart';
import 'package:user_app/app/modules/ministry_directory_module/ministry_directory_page.dart';
import 'package:user_app/app/modules/read_guideline_module/read_guideline_page.dart';
import 'package:user_app/app/modules/use_calculator_module/use_calculator_binding.dart';
import 'package:user_app/app/modules/use_calculator_module/use_calculator_page.dart';
import 'package:user_app/app/modules/notifications_module/notifications_binding.dart';
import 'package:user_app/app/modules/notifications_module/notifications_page.dart';
import 'package:user_app/app/modules/about_us_module/about_us_binding.dart';
import 'package:user_app/app/modules/about_us_module/about_us_page.dart';
import 'package:user_app/app/modules/terms_and_conditions_module/terms_and_conditions_page.dart';
import 'package:user_app/app/modules/consultants_module/consultants_binding.dart';
import 'package:user_app/app/modules/consultants_module/consultants_page.dart';
import 'package:user_app/app/modules/health_infrastructure_module/health_infrastructure_binding.dart';
import 'package:user_app/app/modules/health_infrastructure_module/health_infrastructure_page.dart';
import 'package:user_app/app/modules/abbreviations_module/abbreviations_binding.dart';
import 'package:user_app/app/modules/abbreviations_module/abbreviations_page.dart';
import 'package:user_app/app/modules/all_actions_module/all_actions_binding.dart';
import 'package:user_app/app/modules/all_actions_module/all_actions_page.dart';
import 'package:user_app/app/modules/drug_index_module/drug_index_binding.dart';
import 'package:user_app/app/modules/drug_index_module/drug_index_page.dart';
import 'package:user_app/app/modules/profile_module/profile_page.dart';
import 'package:user_app/app/modules/tools_module/tools_binding.dart';
import 'package:user_app/app/modules/tools_module/tools_page.dart';
import 'package:user_app/app/modules/guidelines_module/guidelines_page.dart';
import 'package:user_app/app/modules/home_module/home_page.dart';
import 'package:user_app/app/middleware/auth.dart';
import 'package:user_app/app/middleware/onboarding.dart';
import 'package:user_app/app/modules/main_module/main_page.dart';
import 'package:user_app/app/modules/forgot_password_module/forgot_password_page.dart';
import 'package:user_app/app/modules/register_module/register_page.dart';
import 'package:user_app/app/modules/onboarding_module/onboarding_binding.dart';
import 'package:user_app/app/modules/onboarding_module/onboarding_page.dart';
import 'package:user_app/app/modules/login_module/login_page.dart';
part './app_routes.dart';

class AppPages {
  AppPages._();
  static final pages = [
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginPage(),
      middlewares: [OnboardingMiddleware()],
    ),
    GetPage(
      name: AppRoutes.onboarding,
      page: () => const OnboardingPage(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterPage(),
      middlewares: [OnboardingMiddleware()],
    ),
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const ForgotPasswordPage(),
    ),
    GetPage(
      name: AppRoutes.main,
      page: () => const MainPage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(name: AppRoutes.home, page: () => const HomePage()),
    GetPage(name: AppRoutes.guidelines, page: () => const GuidelinesPage()),
    GetPage(
      name: AppRoutes.tools,
      page: () => const ToolsPage(),
      binding: ToolsBinding(),
    ),
    GetPage(name: AppRoutes.profile, page: () => const ProfilePage()),
    GetPage(
      name: AppRoutes.drugIndex,
      page: () => const DrugIndexPage(),
      binding: DrugIndexBinding(),
    ),
    GetPage(
      name: AppRoutes.allActions,
      page: () => const AllActionsPage(),
      binding: AllActionsBinding(),
    ),
    GetPage(
      name: AppRoutes.abbreviations,
      page: () => const AbbreviationsPage(),
      binding: AbbreviationsBinding(),
    ),
    GetPage(
      name: AppRoutes.healthInfrastructure,
      page: () => const HealthInfrastructurePage(),
      binding: HealthInfrastructureBinding(),
    ),
    GetPage(
      name: AppRoutes.consultants,
      page: () => const ConsultantsPage(),
      binding: ConsultantsBinding(),
    ),
    GetPage(
      name: AppRoutes.termsAndConditions,
      page: () => const TermsAndConditionsPage(),
    ),
    GetPage(
      name: AppRoutes.aboutUs,
      page: () => const AboutUsPage(),
      binding: AboutUsBinding(),
    ),
    GetPage(
      name: AppRoutes.notifications,
      page: () => const NotificationsPage(),
      binding: NotificationsBinding(),
    ),
    GetPage(
      name: AppRoutes.useCalculator,
      page: () => const UseCalculatorPage(),
      binding: UseCalculatorBinding(),
    ),
    GetPage(
      name: AppRoutes.readGuideline,
      page: () => const ReadGuidelinePage(),
    ),
    GetPage(
      name: AppRoutes.aiAssistant,
      page: () => const AiAssistantPage(),
      binding: AiAssistantBinding(),
    ),
    GetPage(
      name: AppRoutes.ministryDirectory,
      page: () => const MinistryDirectoryPage(),
      binding: MinistryDirectoryBinding(),
    ),
    GetPage(
      name: AppRoutes.guidelinesIndexer,
      page: () => const GuidelinesIndexerPage(),
      binding: GuidelinesIndexerBinding(),
    ),
    GetPage(
      name: AppRoutes.helpCenter,
      page: () => const HelpCenterPage(),
      binding: HelpCenterBinding(),
    ),
    GetPage(
      name: AppRoutes.faq,
      page: () => const FaqPage(),
      binding: FaqBinding(),
    ),
    GetPage(
      name: AppRoutes.chatInterface,
      page: () => const ChatInterfacePage(),
      binding: ChatInterfaceBinding(),
    ),
    GetPage(
      name: AppRoutes.chatList,
      page: () => const ChatListPage(),
      binding: ChatListBinding(),
    ),
    GetPage(
      name: AppRoutes.genericViewer,
      page: () => const GenericViewerPage(),
      binding: GenericViewerBinding(),
    ),
    GetPage(
      name: AppRoutes.aiAssistant,
      page: () => const AiAssistantPage(),
      binding: AiAssistantBinding(),
    ),
  ];
}
