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
  static const String publicGuidelines = '/public/guidelines';
  static const String tools = '/tools';
  static const String profile = '/profile';
  static const String search = '/search';
  static const String library = '/library';
  static const String collections = '/library/collections';
  static const String collectionDetails = '/library/collections/:collectionId';
  static const String offlineContent = '/offline-content';
  static const String documentReader = '/document-reader';
  static const String more = '/more';
  static const String outbreakHub = '/outbreak-hub';
  static const String situationReports = '/situation-reports';
  static const String outbreakDetails = '/outbreak-hub/:outbreakId';
  static const String outbreakDocuments = '/outbreak-hub/:outbreakId/documents';
  static const String outbreakSection =
      '/outbreak-hub/:outbreakId/sections/:sectionId';
  static const String outbreakDocumentDetails =
      '/outbreak-hub/:outbreakId/documents/:documentId';
  static const String situationReportDetails = '/situation-reports/:reportId';

  // Clinical content
  static const String drugIndex = '/drug-index';
  static const String abbreviations = '/abbreviations';
  static const String guidelinesIndexer = '/guidelines-indexer';
  static const String genericViewer = '/generic-viewer';

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
  static const String notificationPreferences = '/notification-preferences';
  static const String termsAndConditions = '/terms-and-conditions';
  static const String aboutUs = '/about-us';
  static const String helpCenter = '/help-center';
  static const String faq = '/faq';
  static const String editProfile = '/profile/edit';

  // Parameterized route templates
  static const String guidelineDetails = '/guidelines/:guidelineId';
  static const String publicGuidelineDetails =
      '/public/guidelines/:guidelineId';
  static const String publicGuidelineReader =
      '/public/guidelines/:guidelineId/read';
  static const String publicGuidelineTable =
      '/public/guidelines/:guidelineId/tables/:blockId';
  static const String publicGuidelineAlgorithm =
      '/public/guidelines/:guidelineId/algorithms/:blockId';
  static const String calculatorDetails = '/calculators/:calculatorId';
  static const String calculatorReview = '/clinical-tools/review/:versionId';
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
    main,
    home,
    search,
    more,
    publicGuidelines,
    offlineContent,
    documentReader,
    aiAssistant,
    outbreakHub,
    situationReports,
    drugIndex,
    abbreviations,
    healthInfrastructure,
    healthFacilities,
    helpCenter,
    faq,
    aboutUs,
    termsAndConditions,
  };

  static bool isPublic(String location) {
    final path = Uri.tryParse(location)?.path ?? location;
    return publicRoutes.contains(path) ||
        path.startsWith('$publicGuidelines/') ||
        path.startsWith('$outbreakHub/') ||
        path.startsWith('$situationReports/') ||
        path.startsWith('$healthFacilities/');
  }

  /// Accepts only in-app absolute paths for post-authentication navigation.
  /// This prevents external redirects and redirect loops from crafted links.
  static String safeDestination(String? value, {String fallback = main}) {
    if (value == null || value.isEmpty) return fallback;
    final uri = Uri.tryParse(value);
    if (uri == null ||
        uri.hasScheme ||
        uri.hasAuthority ||
        !value.startsWith('/') ||
        value.startsWith('//') ||
        uri.path == login ||
        uri.path == register ||
        uri.path == onboarding) {
      return fallback;
    }
    return value;
  }

  // Route builders

  static String guideline(String guidelineId) {
    return '/guidelines/${Uri.encodeComponent(guidelineId)}';
  }

  static String collection(String collectionId) {
    return '$collections/${Uri.encodeComponent(collectionId)}';
  }

  static String publicGuideline(String guidelineId) {
    return '$publicGuidelines/${Uri.encodeComponent(guidelineId)}';
  }

  static String publicGuidelinesForProgramArea(String programArea) {
    return Uri(
      path: publicGuidelines,
      queryParameters: {'program_area': programArea.trim()},
    ).toString();
  }

  static String publicGuidelinesForCategory(String categoryId, String name) {
    return Uri(
      path: publicGuidelines,
      queryParameters: {
        'category_id': categoryId.trim(),
        if (name.trim().isNotEmpty) 'category_name': name.trim(),
      },
    ).toString();
  }

  static String readPublicGuideline(String guidelineId) {
    return '${publicGuideline(guidelineId)}/read';
  }

  static String publicGuidelineTableView(String guidelineId, String blockId) {
    return '${publicGuideline(guidelineId)}/tables/${Uri.encodeComponent(blockId)}';
  }

  static String publicGuidelineAlgorithmView(
    String guidelineId,
    String blockId,
  ) {
    return '${publicGuideline(guidelineId)}/algorithms/${Uri.encodeComponent(blockId)}';
  }

  static String outbreak(String outbreakId) {
    return '$outbreakHub/${Uri.encodeComponent(outbreakId)}';
  }

  static String outbreakDocumentsFor(String outbreakId) {
    return '$outbreakHub/${Uri.encodeComponent(outbreakId)}/documents';
  }

  static String outbreakSectionFor(String outbreakId, String sectionId) {
    return '$outbreakHub/${Uri.encodeComponent(outbreakId)}/sections/${Uri.encodeComponent(sectionId)}';
  }

  static String outbreakDocument(String outbreakId, String documentId) {
    return '${outbreakDocumentsFor(outbreakId)}/${Uri.encodeComponent(documentId)}';
  }

  static String situationReport(String reportId) {
    return '$situationReports/${Uri.encodeComponent(reportId)}';
  }

  static String calculator(String calculatorId) {
    return '/calculators/${Uri.encodeComponent(calculatorId)}';
  }

  static String reviewCalculator(String versionId) {
    return '/clinical-tools/review/${Uri.encodeComponent(versionId)}';
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
