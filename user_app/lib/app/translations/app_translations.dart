import 'package:flutter/material.dart';
import 'package:user_app/app/translations/en_us.dart';

class AppTranslationKey {
  AppTranslationKey._();
  static String get welcomeToMediGuide => "welcomeToMediGuide".tr;
  static String get welcomeBody => "welcomeBody".tr;
  static String get clinicalGuidelines => "clinicalGuidelines".tr;
  static String get clinicalGuidelinesBody => "clinicalGuidelinesBody".tr;
  static String get worksOffline => "worksOffline".tr;
  static String get worksOfflineBody => "worksOfflineBody".tr;
  static String get decisionSupportTools => "decisionSupportTools".tr;
  static String get decisionSupportToolsBody => "decisionSupportToolsBody".tr;
  static String get readyToTransformCare => "readyToTransformCare".tr;
  static String get readyToTransformCareBody => "readyToTransformCareBody".tr;
  static String get skip => "skip".tr;
  static String get getStarted => "getStarted".tr;
  static String get username => "username".tr;
  static String get password => "password".tr;
  static String get signIn => "signIn".tr;
  static String get forgotPassword => "forgotPassword".tr;
  static String get termsOfService => "termsOfService".tr;
  static String get privacyPolicy => "privacyPolicy".tr;
  static String get signingIn => "signingIn".tr;
  static String get createAccount => "createAccount".tr;
  static String get fullName => "fullName".tr;
  static String get email => "email".tr;
  static String get phoneNumber => "phoneNumber".tr;
  static String get confirmPassword => "confirmPassword".tr;
  static String get agreeToTerms => "agreeToTerms".tr;
  static String get creatingAccount => "creatingAccount".tr;
  static String get backToLogin => "backToLogin".tr;
  static String get resetPassword => "resetPassword".tr;
  static String get resetPasswordDescription => "resetPasswordDescription".tr;
  static String get enterYourEmail => "enterYourEmail".tr;
  static String get sendResetLink => "sendResetLink".tr;
  static String get sendingResetLink => "sendingResetLink".tr;
  static String get licenseNumber => "licenseNumber".tr;
  static String get userRole => "userRole".tr;
  static String get selectUserRole => "selectUserRole".tr;
  static String get doctor => "doctor".tr;
  static String get nurse => "nurse".tr;
  static String get clinicalOfficer => "clinicalOfficer".tr;
  static String get midwife => "midwife".tr;
  static String get appName => "appName".tr;
  static String get unknown => "unknown".tr;
  static String get loginError => "loginError".tr;
  static String get invalidUsernameOrPassword => "invalidUsernameOrPassword".tr;
  static String get registrationError => "registrationError".tr;
  static String get pleaseAgreeToTerms => "pleaseAgreeToTerms".tr;
  static String get registrationSuccessful => "registrationSuccessful".tr;
  static String get passwordResetSent => "passwordResetSent".tr;
  static String get passwordResetError => "passwordResetError".tr;
  static String get doctorDescription => "doctorDescription".tr;
  static String get clinicalOfficerDescription =>
      "clinicalOfficerDescription".tr;
  static String get nurseDescription => "nurseDescription".tr;
  static String get midwifeDescription => "midwifeDescription".tr;
  static String get communityHealthWorkerDescription =>
      "communityHealthWorkerDescription".tr;
  static String get medicalStudentDescription => "medicalStudentDescription".tr;
  static String get invalidUserRole => "invalidUserRole".tr;
  static String get authenticationRequired => "authenticationRequired".tr;
  static String get accountCreated => "accountCreated".tr;
  static String get checkEmailForReset => "checkEmailForReset".tr;
  static String get insufficientPermissions => "insufficientPermissions".tr;
  static String get roleRequired => "roleRequired".tr;
  static String get oneOfTheseRolesRequired => "oneOfTheseRolesRequired".tr;
  static String get home => "home".tr;
  static String get guidelines => "guidelines".tr;
  static String get tools => "tools".tr;
  static String get profile => "profile".tr;

  /// Parameters: name app
  static String userGreeting(Map<String, String> params) =>
      "userGreeting".trParams(params);

  /// Parameters: name date time
  static String loginSuccess(Map<String, String> params) =>
      "loginSuccess".trParams(params);
  static String get editProfile => "editProfile".tr;
  static String get changePassword => "changePassword".tr;
  static String get notifications => "notifications".tr;
  static String get language => "language".tr;
  static String get theme => "theme".tr;
  static String get lightMode => "lightMode".tr;
  static String get darkMode => "darkMode".tr;
  static String get systemDefault => "systemDefault".tr;
  static String get aboutApp => "aboutApp".tr;
  static String get privacySettings => "privacySettings".tr;
  static String get offlineContent => "offlineContent".tr;
  static String get clinicalSettings => "clinicalSettings".tr;
  static String get emergencyProtocols => "emergencyProtocols".tr;
  static String get logout => "logout".tr;
  static String get accountSettings => "accountSettings".tr;
  static String get appPreferences => "appPreferences".tr;
  static String get dataAndPrivacy => "dataAndPrivacy".tr;
  static String get supportAndAbout => "supportAndAbout".tr;
  static String get accountActions => "accountActions".tr;
  static String get updatePersonalInformation => "updatePersonalInformation".tr;
  static String get updateSecurityCredentials => "updateSecurityCredentials".tr;
  static String get authentication => "authentication".tr;
  static String get receiveAppNotifications => "receiveAppNotifications".tr;
  static String get notificationsDisabled => "notificationsDisabled".tr;
  static String get soundAndVibration => "soundAndVibration".tr;
  static String get dataBackup => "dataBackup".tr;
  static String get autoBackupEnabled => "autoBackupEnabled".tr;
  static String get autoBackupDisabled => "autoBackupDisabled".tr;
  static String get analytics => "analytics".tr;
  static String get helpImproveApp => "helpImproveApp".tr;
  static String get analyticsDisabled => "analyticsDisabled".tr;
  static String get storageUsage => "storageUsage".tr;
  static String get storage => "storage".tr;
  static String get storageManagementComingSoon =>
      "storageManagementComingSoon".tr;
  static String get syncData => "syncData".tr;
  static String get manualSync => "manualSync".tr;
  static String get syncInProgress => "syncInProgress".tr;
  static String get syncCompleted => "syncCompleted".tr;
  static String get syncError => "syncError".tr;
  static String get syncStarted => "syncStarted".tr;
  static String get syncFailed => "syncFailed".tr;
  static String get lastSyncTime => "lastSyncTime".tr;
  static String get clearOfflineData => "clearOfflineData".tr;
  static String get clearingOfflineData => "clearingOfflineData".tr;
  static String get syncingCollections => "syncingCollections".tr;
  static String get dataCleared => "dataCleared".tr;
  static String get clearDataFailed => "clearDataFailed".tr;
  static String get dataSyncSection => "dataSyncSection".tr;
  static String get storageInfo => "storageInfo".tr;
  static String get calculatingStorage => "calculatingStorage".tr;
  static String get syncNow => "syncNow".tr;
  static String get resyncAfterClear => "resyncAfterClear".tr;
  static String get manageDownloadedGuidelines =>
      "manageDownloadedGuidelines".tr;
  static String get offlineContentFeature => "offlineContentFeature".tr;
  static String get featureComingSoon => "featureComingSoon".tr;
  static String get helpCenter => "helpCenter".tr;
  static String get getHelpAndSupport => "getHelpAndSupport".tr;
  static String get help => "help".tr;
  static String get helpCenterComingSoon => "helpCenterComingSoon".tr;
  static String get contactSupport => "contactSupport".tr;
  static String get getInTouchWithTeam => "getInTouchWithTeam".tr;
  static String get contact => "contact".tr;
  static String get supportContactComingSoon => "supportContactComingSoon".tr;
  static String get aboutMediGuide => "aboutMediGuide".tr;
  static String get appVersionAndInfo => "appVersionAndInfo".tr;
  static String get termsAndPrivacy => "termsAndPrivacy".tr;
  static String get legalInformation => "legalInformation".tr;
  static String get legal => "legal".tr;
  static String get termsAndPrivacyComingSoon => "termsAndPrivacyComingSoon".tr;
  static String get rateApp => "rateApp".tr;
  static String get rateUsOnAppStore => "rateUsOnAppStore".tr;
  static String get rate => "rate".tr;
  static String get ratingFeatureComingSoon => "ratingFeatureComingSoon".tr;
  static String get signOut => "signOut".tr;
  static String get signOutOfAccount => "signOutOfAccount".tr;
  static String get deleteAccount => "deleteAccount".tr;
  static String get permanentlyDeleteAccount => "permanentlyDeleteAccount".tr;
  static String get user => "user".tr;
  static String get healthcareWorker => "healthcareWorker".tr;
  static String get verified => "verified".tr;
  static String get pendingVerification => "pendingVerification".tr;
  static String get chooseTheme => "chooseTheme".tr;
  static String get cancel => "cancel".tr;
  static String get chooseLanguage => "chooseLanguage".tr;
  static String get english => "english".tr;
  static String get kiswahili => "kiswahili".tr;
  static String get luganda => "luganda".tr;
  static String get sound => "sound".tr;
  static String get playSoundsForNotifications =>
      "playSoundsForNotifications".tr;
  static String get vibration => "vibration".tr;
  static String get vibrateForNotifications => "vibrateForNotifications".tr;
  static String get done => "done".tr;
  static String get soundAndVibrationEnabled => "soundAndVibrationEnabled".tr;
  static String get soundOnly => "soundOnly".tr;
  static String get vibrationOnly => "vibrationOnly".tr;
  static String get soundAndVibrationDisabled => "soundAndVibrationDisabled".tr;
  static String get twoFactorEnabled => "twoFactorEnabled".tr;
  static String get twoFactorAuthActive => "twoFactorAuthActive".tr;
  static String get failedToSaveSettings => "failedToSaveSettings".tr;
  static String get thisActionCannotBeUndone => "thisActionCannotBeUndone".tr;
  static String get areYouSureDeleteAccount => "areYouSureDeleteAccount".tr;
  static String get finalConfirmation => "finalConfirmation".tr;
  static String get permanentlyDeleteAccountAndData =>
      "permanentlyDeleteAccountAndData".tr;
  static String get typeDeleteToConfirm => "typeDeleteToConfirm".tr;
  static String get typeDelete => "typeDelete".tr;
  static String get accountDeleted => "accountDeleted".tr;
  static String get accountDeletedPermanently => "accountDeletedPermanently".tr;
  static String get failedToDeleteAccount => "failedToDeleteAccount".tr;
  static String get failedToSignOut => "failedToSignOut".tr;
  static String get mediGuideVersion => "mediGuideVersion".tr;
  static String get digitalCompanionDescription =>
      "digitalCompanionDescription".tr;
  static String get copyrightMediGuide => "copyrightMediGuide".tr;
  static String get error => "error".tr;
  static String get ok => "ok".tr;
  static String get welcomeBack => "welcomeBack".tr;
  static String get quickActions => "quickActions".tr;
  static String get chatWithConsultant => "chatWithConsultant".tr;
  static String get connectWithExpert => "connectWithExpert".tr;
  static String get healthInfrastructure => "healthInfrastructure".tr;
  static String get findNearbyFacilities => "findNearbyFacilities".tr;
  static String get aiChatAssistant => "aiChatAssistant".tr;
  static String get askMediGuideAi => "askMediGuideAi".tr;
  static String get emergencyContacts => "emergencyContacts".tr;
  static String get ministryDirectory => "ministryDirectory".tr;
  static String get continueReading => "continueReading".tr;
  static String get resumeWhereYouLeftOff => "resumeWhereYouLeftOff".tr;
  static String get medicalNews => "medicalNews".tr;
  static String get latestUpdates => "latestUpdates".tr;
  static String get trainingCertification => "trainingCertification".tr;
  static String get yourLearningProgress => "yourLearningProgress".tr;
  static String get available => "available".tr;
  static String get busy => "busy".tr;
  static String get inProgress => "inProgress".tr;
  static String get completed => "completed".tr;
  static String get notStarted => "notStarted".tr;
  static String get openingNotifications => "openingNotifications".tr;
  static String get accessEssentialFeatures => "accessEssentialFeatures".tr;
  static String get openingReadingLibrary => "openingReadingLibrary".tr;
  static String get openingNewsFeed => "openingNewsFeed".tr;
  static String get latestHealthUpdates => "latestHealthUpdates".tr;
  static String get yourLearningProgressAndModules =>
      "yourLearningProgressAndModules".tr;
  static String get seeAll => "seeAll".tr;
  static String get searchMediguide => "searchMediguide".tr;
  static String get quickStats => "quickStats".tr;
  static String get drugs => "drugs".tr;
  static String get healthcareFacilities => "healthcareFacilities".tr;
  static String get drugIndex => "drugIndex".tr;
  static String get browseComprehensiveDrugDatabase =>
      "browseComprehensiveDrugDatabase".tr;
  static String get pregnancyCategory => "pregnancyCategory".tr;
  static String get allActions => "allActions".tr;
  static String get accessAllEssentialFeatures =>
      "accessAllEssentialFeatures".tr;
  static String get getInstantMedicalAssistance =>
      "getInstantMedicalAssistance".tr;
  static String get medicalCalculators => "medicalCalculators".tr;
  static String get accessClinicalCalculators => "accessClinicalCalculators".tr;
  static String get accessTreatmentGuidelines => "accessTreatmentGuidelines".tr;
  static String get diagnosticTools => "diagnosticTools".tr;
  static String get accessDiagnosticTools => "accessDiagnosticTools".tr;
  static String get medicalAbbreviations => "medicalAbbreviations".tr;
  static String get lookupMedicalTerms => "lookupMedicalTerms".tr;
  static String get failedToLoadAbbreviations => "failedToLoadAbbreviations".tr;
  static String get pleaseCheckConnectionAndTryAgain =>
      "pleaseCheckConnectionAndTryAgain".tr;
  static String get failedToLoadMoreAbbreviations =>
      "failedToLoadMoreAbbreviations".tr;
  static String get noAbbreviationsMatchFilters =>
      "noAbbreviationsMatchFilters".tr;
  static String get tryAdjustingSearchOrFilters =>
      "tryAdjustingSearchOrFilters".tr;
  static String get noAbbreviationsFound => "noAbbreviationsFound".tr;
  static String get abbreviationsWillAppearHere =>
      "abbreviationsWillAppearHere".tr;
  static String get clearFilters => "clearFilters".tr;
  static String get failedToLoadGuidelines => "failedToLoadGuidelines".tr;
  static String get failedToLoadMoreGuidelines =>
      "failedToLoadMoreGuidelines".tr;
  static String get noGuidelinesMatchFilters => "noGuidelinesMatchFilters".tr;
  static String get noGuidelinesFound => "noGuidelinesFound".tr;
  static String get guidelinesWillAppearHere => "guidelinesWillAppearHere".tr;
  static String get searchGuidelines => "searchGuidelines".tr;
  static String get filterGuidelines => "filterGuidelines".tr;
  static String get showHighPriorityOnly => "showHighPriorityOnly".tr;
  static String get priority => "priority".tr;
  static String get healthcareLevel => "healthcareLevel".tr;
  static String get targetPopulation => "targetPopulation".tr;
  static String get filterByTargetPopulation => "filterByTargetPopulation".tr;
  static String get allPriorities => "allPriorities".tr;
  static String get allLevels => "allLevels".tr;
  static String get allCategories => "allCategories".tr;
  static String get errorLoadingGuidelines => "errorLoadingGuidelines".tr;
  static String get guidelineDetails => "guidelineDetails".tr;
  static String get failedToLoadFacilities => "failedToLoadFacilities".tr;
  static String get failedToLoadMoreFacilities =>
      "failedToLoadMoreFacilities".tr;
  static String get noFacilitiesMatchFilters => "noFacilitiesMatchFilters".tr;
  static String get noFacilitiesFound => "noFacilitiesFound".tr;
  static String get facilitiesWillAppearHere => "facilitiesWillAppearHere".tr;
  static String get searchFacilities => "searchFacilities".tr;
  static String get filterFacilities => "filterFacilities".tr;
  static String get region => "region".tr;
  static String get district => "district".tr;
  static String get facilityLevel => "facilityLevel".tr;
  static String get ownershipType => "ownershipType".tr;
  static String get filterDrugs => "filterDrugs".tr;
  static String get whoEmlOnly => "whoEmlOnly".tr;
  static String get antimicrobialOnly => "antimicrobialOnly".tr;
  static String get noDrugsMatchFilters => "noDrugsMatchFilters".tr;
  static String get drugsWillAppearHere => "drugsWillAppearHere".tr;
  static String get consultants => "consultants".tr;
  static String get consultantDetails => "consultantDetails".tr;
  static String get viewDetails => "viewDetails".tr;
  static String get startChat => "startChat".tr;
  static String get professionalInfo => "professionalInfo".tr;
  static String get contactLocation => "contactLocation".tr;
  static String get additionalInfo => "additionalInfo".tr;
  static String get preferredLanguage => "preferredLanguage".tr;
  static String get consultantAvailable => "consultantAvailable".tr;
  static String get consultantOffline => "consultantOffline".tr;
  static String get failedToLoadConsultants => "failedToLoadConsultants".tr;
  static String get failedToLoadMoreConsultants =>
      "failedToLoadMoreConsultants".tr;
  static String get noConsultantsMatchFilters => "noConsultantsMatchFilters".tr;
  static String get noConsultantsFound => "noConsultantsFound".tr;
  static String get consultantsWillAppearHere => "consultantsWillAppearHere".tr;
  static String get filterConsultants => "filterConsultants".tr;
  static String get searchConsultants => "searchConsultants".tr;
  static String get showOnlineOnly => "showOnlineOnly".tr;
  static String get showVerifiedOnly => "showVerifiedOnly".tr;
  static String get errorLoadingConsultants => "errorLoadingConsultants".tr;
  static String get termsAndConditions => "termsAndConditions".tr;
  static String get lastUpdated => "lastUpdated".tr;
  static String get acceptanceOfTerms => "acceptanceOfTerms".tr;
  static String get acceptanceOfTermsContent => "acceptanceOfTermsContent".tr;
  static String get appDescription => "appDescription".tr;
  static String get appDescriptionContent => "appDescriptionContent".tr;
  static String get userObligations => "userObligations".tr;
  static String get userObligationsContent => "userObligationsContent".tr;
  static String get dataCollection => "dataCollection".tr;
  static String get dataCollectionContent => "dataCollectionContent".tr;
  static String get contactInformation => "contactInformation".tr;
  static String get contactInformationContent => "contactInformationContent".tr;
  static String get aboutUs => "aboutUs".tr;
  static String get appVersion => "appVersion".tr;
  static String get ourMission => "ourMission".tr;
  static String get missionDescription => "missionDescription".tr;
  static String get keyFeatures => "keyFeatures".tr;
  static String get developmentTeam => "developmentTeam".tr;
  static String get builtWith => "builtWith".tr;
  static String get accessToClinicGuidelines => "accessToClinicGuidelines".tr;
  static String get comprehensiveMedicationDatabase =>
      "comprehensiveMedicationDatabase".tr;
  static String get medicalExpertsDirectory => "medicalExpertsDirectory".tr;
  static String get healthcareFacilitiesList => "healthcareFacilitiesList".tr;
  static String get emailSupport => "emailSupport".tr;
  static String get shareYourFeedback => "shareYourFeedback".tr;
  static String get feedback => "feedback".tr;
  static String get all => "all".tr;
  static String get calculator => "calculator".tr;
  static String get decisionTool => "decisionTool".tr;
  static String get checklist => "checklist".tr;
  static String get featuredTools => "featuredTools".tr;
  static String get essentialCalculatorsAndTools =>
      "essentialCalculatorsAndTools".tr;
  static String get blueChannel => "blueChannel".tr;
  static String get redChannel => "redChannel".tr;
  static String get primaryGuidelines => "primaryGuidelines".tr;
  static String get guidelinesIndex => "guidelinesIndex".tr;
  static String get selectChannel => "selectChannel".tr;
  static String get allChannels => "allChannels".tr;
  static String get nameRequired => "nameRequired".tr;
  static String get invalidPhoneFormat => "invalidPhoneFormat".tr;
  static String get invalidAlternativePhoneFormat =>
      "invalidAlternativePhoneFormat".tr;
  static String get profileUpdated => "profileUpdated".tr;
  static String get profileUpdatedSuccessfully =>
      "profileUpdatedSuccessfully".tr;
  static String get failedToUpdateProfile => "failedToUpdateProfile".tr;
  static String get discardChanges => "discardChanges".tr;
  static String get discardChangesConfirmation =>
      "discardChangesConfirmation".tr;
  static String get discard => "discard".tr;
  static String get french => "french".tr;
  static String get spanish => "spanish".tr;
  static String get portuguese => "portuguese".tr;
  static String get arabic => "arabic".tr;
  static String get amharic => "amharic".tr;
  static String get save => "save".tr;
  static String get close => "close".tr;
  static String get currentPassword => "currentPassword".tr;
  static String get enterCurrentPassword => "enterCurrentPassword".tr;
  static String get currentPasswordRequired => "currentPasswordRequired".tr;
  static String get newPassword => "newPassword".tr;
  static String get enterNewPassword => "enterNewPassword".tr;
  static String get newPasswordRequired => "newPasswordRequired".tr;
  static String get passwordMinLength => "passwordMinLength".tr;
  static String get newPasswordSameAsCurrent => "newPasswordSameAsCurrent".tr;
  static String get confirmNewPassword => "confirmNewPassword".tr;
  static String get enterConfirmPassword => "enterConfirmPassword".tr;
  static String get confirmPasswordRequired => "confirmPasswordRequired".tr;
  static String get passwordsDoNotMatch => "passwordsDoNotMatch".tr;
  static String get passwordRequirements => "passwordRequirements".tr;
  static String get passwordRequirementsDetails =>
      "passwordRequirementsDetails".tr;
  static String get changing => "changing".tr;
  static String get success => "success".tr;
  static String get passwordChangedSuccessfully =>
      "passwordChangedSuccessfully".tr;
  static String get passwordChangeError => "passwordChangeError".tr;
  static String get currentPasswordIncorrect => "currentPasswordIncorrect".tr;
  static String get passwordValidationError => "passwordValidationError".tr;
  static String get networkError => "networkError".tr;
  static String get biometricAuthentication => "biometricAuthentication".tr;
  static String get biometricAuthDesc => "biometricAuthDesc".tr;
  static String get useFaceIdToAccess => "useFaceIdToAccess".tr;
  static String get useFingerprintToAccess => "useFingerprintToAccess".tr;
  static String get pleaseAuthenticateToAccess =>
      "pleaseAuthenticateToAccess".tr;
  static String get biometricNotAvailable => "biometricNotAvailable".tr;
  static String get biometricEnabled => "biometricEnabled".tr;
  static String get biometricDisabled => "biometricDisabled".tr;
  static String get failedToUpdateBiometricSettings =>
      "failedToUpdateBiometricSettings".tr;
  static String get lightModeDesc => "lightModeDesc".tr;
  static String get darkModeDesc => "darkModeDesc".tr;
  static String get systemDefaultDesc => "systemDefaultDesc".tr;
  static String get moreActions => "moreActions".tr;
  static String get moreInfo => "moreInfo".tr;
  static String get update => "update".tr;
  static String get updateAvailable => "updateAvailable".tr;
  static String get newVersionAvailable => "newVersionAvailable".tr;
  static String get upToDate => "upToDate".tr;
  static String get appIsUpToDate => "appIsUpToDate".tr;
  static String get failedToCheckForUpdates => "failedToCheckForUpdates".tr;
  static String get noUpdateAvailable => "noUpdateAvailable".tr;
  static String get updateFailed => "updateFailed".tr;
  static String get downloadingUpdate => "downloadingUpdate".tr;
  static String get updateDownloadingInBackground =>
      "updateDownloadingInBackground".tr;
  static String get noUpdateReady => "noUpdateReady".tr;
  static String get updateComplete => "updateComplete".tr;
  static String get appWillRestart => "appWillRestart".tr;
  static String get checkingForUpdates => "checkingForUpdates".tr;
  static String get updateReadyToInstall => "updateReadyToInstall".tr;
  static String get checkForUpdate => "checkForUpdate".tr;
  static String get installUpdate => "installUpdate".tr;
  static String get downloadUpdate => "downloadUpdate".tr;
  static String get thankYouForRating => "thankYouForRating".tr;
  static String get redirectedToAppStore => "redirectedToAppStore".tr;
  static String get ratingFailed => "ratingFailed".tr;
  static String get supportTickets => "supportTickets".tr;
  static String get mySupportCenter => "mySupportCenter".tr;
  static String get filterTickets => "filterTickets".tr;
  static String get createNewTicket => "createNewTicket".tr;
  static String get searchMyTickets => "searchMyTickets".tr;
  static String get myTicketsOverview => "myTicketsOverview".tr;
  static String get noSupportTicketsYet => "noSupportTicketsYet".tr;
  static String get createYourFirstSupportTicket =>
      "createYourFirstSupportTicket".tr;
  static String get createSupportTicket => "createSupportTicket".tr;
  static String get specialization => "specialization".tr;
  static String get selectSpecialization => "selectSpecialization".tr;
  static String get filterOptions => "filterOptions".tr;

  // FAQ related translations
  static String get frequentlyAskedQuestions => "frequentlyAskedQuestions".tr;
  static String get getAnswersToCommonQuestions =>
      "getAnswersToCommonQuestions".tr;
  static String get searchFAQs => "searchFAQs".tr;
  static String get enterKeywords => "enterKeywords".tr;
  static String get noFAQsFound => "noFAQsFound".tr;
  static String get noFAQsAvailable => "noFAQsAvailable".tr;
  static String get tryDifferentSearchTerm => "tryDifferentSearchTerm".tr;
  static String get faqsWillAppearHere => "faqsWillAppearHere".tr;
  static String get clearSearch => "clearSearch".tr;
  static String get failedToLoadFAQs => "failedToLoadFAQs".tr;
  static String get checkInternetAndRetry => "checkInternetAndRetry".tr;
  static String get errorLoadingMore => "errorLoadingMore".tr;
  static String get featured => "featured".tr;
  static String get retry => "retry".tr;

  // Chat list translations
  static String get chatList => "chatList".tr;
  static String get conversations => "conversations".tr;
  static String get noConversationsFound => "noConversationsFound".tr;
  static String get searchConversations => "searchConversations".tr;
  static String get startNewConversation => "startNewConversation".tr;
  static String get lastMessage => "lastMessage".tr;
  static String get noMessagesYet => "noMessagesYet".tr;
  static String get searchGuidelinesHint => "searchGuidelinesHint".tr;
  static String get level => "level".tr;
  static String get showOnlyParents => "showOnlyParents".tr;
}

class AppTranslation {
  AppTranslation._();

  static Locale locale = WidgetsBinding.instance.platformDispatcher.locale;
  static String currentLanguageCode = locale.languageCode;
  static final Map<String, Map<String, String>> translations = {'en': enUS};

  /// Update translations dynamically
  static void updateTranslations(
    String languageCode,
    Map<String, String> newTranslations,
  ) {
    if (newTranslations.isNotEmpty) {
      translations[languageCode] = newTranslations;
    }
  }

  static void setLocale(Locale value) {
    locale = value;
    currentLanguageCode = value.languageCode;
  }

  /// Get available translations
  static Map<String, Map<String, String>> get availableTranslations =>
      translations;

  /// Check if language is available
  static bool hasLanguage(String languageCode) {
    return translations.containsKey(languageCode);
  }

  /// Get fallback translation
  static String getTranslation(String key, String languageCode) {
    // First try the requested language
    if (translations[languageCode]?.containsKey(key) == true) {
      return translations[languageCode]![key]!;
    }

    // Fallback to English
    if (translations['en']?.containsKey(key) == true) {
      return translations['en']![key]!;
    }

    // Return the key if no translation found
    return key;
  }
}

extension AppTranslationStringExtension on String {
  String get tr =>
      AppTranslation.getTranslation(this, AppTranslation.currentLanguageCode);

  String trParams(Map<String, String> parameters) {
    var value = tr;
    for (final entry in parameters.entries) {
      value = value
          .replaceAll('@${entry.key}', entry.value)
          .replaceAll('{${entry.key}}', entry.value);
    }
    return value;
  }
}
