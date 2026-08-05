abstract final class AppRoutes {
  AppRoutes._();
  static const initial = '/';
  static const home = '/home'; // Home page
  static const login = '/login'; // Login page
  static const register = '/register'; // Register page
  static const onboarding = '/onboarding'; // Onboarding page
  static const forgotPassword = '/forgotPassword'; // Forgot Password page
  static const main = '/main'; // Main page
  static const guidelines = '/guidelines'; // Guidelines page
  static const tools = '/tools'; // Tools page
  static const profile = '/profile'; // Profile page
  static const drugIndex = '/drugIndex'; // Drug Index page
  static const allActions = '/allActions'; // All Actions page
  static const abbreviations = '/abbreviations'; // Abbreviations page
  static const healthInfrastructure =
      '/healthInfrastructure'; // Health Infrastructure page
  static const healthFacility = '/healthFacility';
  static const consultants = '/consultants'; // Consultants page
  static const termsAndConditions =
      '/termsAndConditions'; // Terms And Conditions page
  static const aboutUs = '/aboutUs'; // About Us page
  static const notifications = '/notifications'; // Notifications page
  static const useCalculator = '/useCalculator'; // Use Calculator page
  static const readGuideline = '/readGuideline'; // Read Guideline page
  static const aiAssistant = '/aiAssistant'; // Ai Assistant page
  static const ministryDirectory =
      '/ministryDirectory'; // Ministry Directory page
  static const guidelinesIndexer =
      '/guidelinesIndexer'; // Guidelines Indexer page
  static const helpCenter = '/helpCenter'; // Help Center page
  static const chatInterface = '/chatInterface'; // Chat Interface page
  static const chatList = '/chatList'; // Chat List page
  static const genericViewer = '/genericViewer'; // Generic Viewer page
  static const faq = '/faq'; // Frequently Asked Questions page

  static const publicRoutes = {
    login,
    register,
    onboarding,
    forgotPassword,
    termsAndConditions,
  };
}
