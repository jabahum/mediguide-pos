abstract final class AppRoutes {
  AppRoutes._();

  // Root
  static const String initial = '/';

  // Authentication
  static const String login = '/login';
  static const String register = '/register';
  static const String onboarding = '/onboarding';
  static const String forgotPassword = '/forgot-password';

  // Main navigation
  static const String main = '/main';
  static const String home = '/home';
  static const String guidelines = '/guidelines';
  static const String tools = '/tools';
  static const String profile = '/profile';

  // Clinical content
  static const String drugIndex = '/drug-index';
  static const String abbreviations = '/abbreviations';
  static const String guidelinesIndexer = '/guidelines-indexer';
  static const String genericViewer = '/generic-viewer';
  static const String readGuideline = '/read-guideline';

  // Health directory
  static const String healthInfrastructure = '/health-infrastructure';
  static const String healthFacilities = '/health-facilities';
  static const String consultants = '/consultants';
  static const String ministryDirectory = '/ministry-directory';

  // Calculators
  static const String calculators = '/calculators';

  // AI and chat
  static const String aiAssistant = '/ai-assistant';
  static const String chatList = '/chats';

  // General application pages
  static const String allActions = '/all-actions';
  static const String notifications = '/notifications';
  static const String termsAndConditions = '/terms-and-conditions';
  static const String aboutUs = '/about-us';
  static const String helpCenter = '/help-center';
  static const String faq = '/faq';

  // Parameterized route templates
  static const String guidelineDetails = '/guidelines/:guidelineId';
  static const String calculatorDetails = '/calculators/:calculatorId';
  static const String healthFacilityDetails = '/health-facilities/:facilityId';
  static const String consultantDetails = '/consultants/:consultantId';
  static const String chatDetails = '/chats/:conversationId';
  static const String viewerDetails = '/viewer/:contentType/:contentId';

  /// Routes accessible without authentication.
  static const Set<String> publicRoutes = <String>{
    initial,
    login,
    register,
    onboarding,
    forgotPassword,
    termsAndConditions,
  };

  static bool isPublic(String location) {
    return publicRoutes.any(
      (route) => location == route || location.startsWith('$route?'),
    );
  }

  // Route builders

  static String guideline(String guidelineId) {
    return '/guidelines/${Uri.encodeComponent(guidelineId)}';
  }

  static String calculator(String calculatorId) {
    return '/calculators/${Uri.encodeComponent(calculatorId)}';
  }

  static String healthFacility(String facilityId) {
    return '/health-facilities/${Uri.encodeComponent(facilityId)}';
  }

  static String consultant(String consultantId) {
    return '/consultants/${Uri.encodeComponent(consultantId)}';
  }

  static String chat(String conversationId) {
    return '/chats/${Uri.encodeComponent(conversationId)}';
  }

  static String viewer({
    required String contentType,
    required String contentId,
  }) {
    return '/viewer/'
        '${Uri.encodeComponent(contentType)}/'
        '${Uri.encodeComponent(contentId)}';
  }
}
