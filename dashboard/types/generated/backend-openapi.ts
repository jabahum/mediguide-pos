/* eslint-disable */
/* tslint:disable */
// @ts-nocheck
/*
 * ---------------------------------------------------------------
 * ## THIS FILE WAS GENERATED VIA SWAGGER-TYPESCRIPT-API        ##
 * ##                                                           ##
 * ## AUTHOR: acacode                                           ##
 * ## SOURCE: https://github.com/acacode/swagger-typescript-api ##
 * ---------------------------------------------------------------
 */

export interface HandlersAbbreviationEnvelope {
  data?: ModelsAbbreviation;
  success?: boolean;
}

export interface HandlersAskEnvelope {
  data?: ServicesAskResponse;
  /** @example true */
  success?: boolean;
}

export interface HandlersCalculatorEnvelope {
  data?: ModelsCalculator;
  /** @example true */
  success?: boolean;
}

export interface HandlersCalculatorUsageEnvelope {
  data?: ModelsCalculatorUsageLog;
  /** @example true */
  success?: boolean;
}

export interface HandlersClinicalProtocolEnvelope {
  data?: ModelsClinicalProtocol;
  /** @example true */
  success?: boolean;
}

export interface HandlersConversationEnvelope {
  data?: ServicesConversationView;
  success?: boolean;
}

export interface HandlersDocumentationEnvelope {
  data?: ModelsDocumentation;
  success?: boolean;
}

export interface HandlersDownloadURLEnvelope {
  data?: HandlersDownloadURLResult;
  /** @example true */
  success?: boolean;
}

export interface HandlersDownloadURLResult {
  /** @example "https://storage.example.com/path/to/package.zip" */
  url?: string;
}

export interface HandlersDrugCategoryEnvelope {
  data?: ModelsDrugCategory;
  /** @example true */
  success?: boolean;
}

export interface HandlersDrugClassEnvelope {
  data?: ModelsDrugClass;
  /** @example true */
  success?: boolean;
}

export interface HandlersDrugEnvelope {
  data?: ModelsDrug;
  /** @example true */
  success?: boolean;
}

export interface HandlersDrugTagEnvelope {
  data?: ModelsDrugTag;
  /** @example true */
  success?: boolean;
}

export interface HandlersDrugUsageEnvelope {
  data?: ModelsDrugUsageLog;
  /** @example true */
  success?: boolean;
}

export interface HandlersDuplicatedMarkdownVersionEnvelope {
  data?: ServicesDuplicatedMarkdownVersion;
  /** @example true */
  success?: boolean;
}

export interface HandlersEmailVerificationConfirmRequest {
  token?: string;
}

export interface HandlersEmailVerificationRequest {
  /** @example "user@example.com" */
  email?: string;
}

export interface HandlersEmergencyProtocolEnvelope {
  data?: ModelsEmergencyProtocol;
  success?: boolean;
}

export interface HandlersErrorResponse {
  /** @example "invalid request" */
  error?: string;
  /** @example false */
  success?: boolean;
}

export interface HandlersFAQEnvelope {
  data?: ModelsFAQ;
  success?: boolean;
}

export interface HandlersFAQTagEnvelope {
  data?: ModelsFAQTag;
  success?: boolean;
}

export interface HandlersGenericPageEnvelope {
  data?: ModelsGenericPage;
  success?: boolean;
}

export interface HandlersGuidelineAssetEnvelope {
  data?: ModelsGuidelineAsset;
  success?: boolean;
}

export interface HandlersGuidelineCategoryEnvelope {
  data?: ModelsGuidelineCategory;
  success?: boolean;
}

export interface HandlersGuidelineCollectionEnvelope {
  data?: ServicesGuidelineCollectionDTO;
  success?: boolean;
}

export interface HandlersGuidelineContentBlockEnvelope {
  data?: ModelsGuidelineContentBlock;
  /** @example true */
  success?: boolean;
}

export interface HandlersGuidelineDocumentEnvelope {
  data?: ModelsGuidelineDocument;
  /** @example true */
  success?: boolean;
}

export interface HandlersGuidelineDownloadEnvelope {
  data?: ServicesGuidelineDownloadDTO;
  success?: boolean;
}

export interface HandlersGuidelineExtractionStatusEnvelope {
  data?: ServicesGuidelineExtractionStatus;
  success?: boolean;
}

export interface HandlersGuidelineIndexEnvelope {
  data?: ModelsGuidelineIndexEntry;
  success?: boolean;
}

export interface HandlersGuidelinePreviewEnvelope {
  data?: ServicesGuidelinePreview;
  success?: boolean;
}

export interface HandlersGuidelineSectionEnvelope {
  data?: ModelsGuidelineSection;
  /** @example true */
  success?: boolean;
}

export interface HandlersGuidelineTagEnvelope {
  data?: ModelsGuidelineTag;
  success?: boolean;
}

export interface HandlersGuidelineVersionEnvelope {
  data?: ModelsGuidelineVersion;
  /** @example true */
  success?: boolean;
}

export interface HandlersIngestionJobEnvelope {
  data?: ModelsIngestionJob;
  /** @example true */
  success?: boolean;
}

export interface HandlersIngestionJobResponse {
  attempt_count?: number;
  cancel_requested_at?: string;
  canceled_at?: string;
  completed_at?: string;
  created_at?: string;
  error?: string;
  id?: string;
  job_type?: string;
  payload_json?: string;
  progress_percent?: number;
  progress_stage?: string;
  started_at?: string;
  status?: string;
  updated_at?: string;
  version_id?: string;
}

export type HandlersJSONMap = Record<string, any>;

export interface HandlersLanguageEnvelope {
  data?: ModelsLanguage;
  /** @example true */
  success?: boolean;
}

export interface HandlersLegacyOverviewResult {
  cached_at?: string;
  contentHealth?: Record<string, number>;
  coverage?: Record<string, number>;
  engagement?: Record<string, number>;
  metrics?: Record<string, number>;
  pipeline?: Record<string, number>;
  series?: Record<string, any>;
  success?: boolean;
  support?: Record<string, number>;
  taxonomy?: Record<string, number>;
}

export interface HandlersLegacyStatsResult {
  abbreviations?: number;
  cached_at?: string;
  calculators?: number;
  consultants?: number;
  drugs?: number;
  faqs?: number;
  health_facilities?: number;
  medical_guidelines?: number;
  ministry_directory?: number;
  success?: boolean;
  total_users?: number;
  unread_messages_count?: number;
  user_conversations_count?: number;
}

export interface HandlersLegacyTreeResult {
  data?: ServicesTreeNode[];
  level?: number;
  success?: boolean;
}

export interface HandlersLoginEnvelope {
  data?: ServicesLoginResult;
  /** @example true */
  success?: boolean;
}

export interface HandlersLoginRequest {
  /** @example "admin@mediguide.local" */
  email?: string;
  /** @example "Admin123!" */
  password?: string;
}

export interface HandlersLogoutEnvelope {
  data?: HandlersLogoutResult;
  /** @example true */
  success?: boolean;
}

export interface HandlersLogoutResult {
  /** @example true */
  logged_out?: boolean;
}

export interface HandlersManifestEnvelope {
  data?: ServicesManifestResult;
  /** @example true */
  success?: boolean;
}

export interface HandlersMarkdownDraftEnvelope {
  data?: ServicesMarkdownDraft;
  /** @example true */
  success?: boolean;
}

export interface HandlersMarkdownRegenerationEnvelope {
  data?: ServicesMarkdownRegenerationResult;
  /** @example true */
  success?: boolean;
}

export interface HandlersMarkdownUpdateEnvelope {
  data?: HandlersMarkdownUpdateResult;
  /** @example true */
  success?: boolean;
}

export interface HandlersMarkdownUpdateResult {
  /** @format uuid */
  job_id?: string;
  /** @example true */
  queued?: boolean;
  /** @example 1024 */
  size?: number;
  /** @example true */
  updated?: boolean;
}

export interface HandlersMarkdownValidationEnvelope {
  data?: ServicesMarkdownValidationResult;
  success?: boolean;
}

export interface HandlersMedicalGuidelineEnvelope {
  data?: ModelsMedicalGuideline;
  success?: boolean;
}

export interface HandlersMessageEnvelope {
  data?: ServicesMessageView;
  success?: boolean;
}

export interface HandlersMinistryDirectoryEnvelope {
  data?: ModelsMinistryDirectoryEntry;
  success?: boolean;
}

export interface HandlersNotificationCampaignEnvelope {
  data?: ModelsNotificationCampaign;
  success?: boolean;
}

export interface HandlersNotificationEnvelope {
  data?: ModelsNotification;
  /** @example true */
  success?: boolean;
}

export interface HandlersNotificationStatusInput {
  status?: string;
}

export interface HandlersNotificationTemplateEnvelope {
  data?: ModelsNotificationTemplate;
  /** @example true */
  success?: boolean;
}

export interface HandlersPaginatedAbbreviationsEnvelope {
  data?: ServicesPageResultModelsAbbreviation;
  success?: boolean;
}

export interface HandlersPaginatedCalculators {
  items?: ModelsCalculator[];
  /** @example 1 */
  page?: number;
  /** @example 20 */
  per_page?: number;
  /** @example 1 */
  total_items?: number;
  /** @example 1 */
  total_pages?: number;
}

export interface HandlersPaginatedCalculatorsEnvelope {
  data?: HandlersPaginatedCalculators;
  /** @example true */
  success?: boolean;
}

export interface HandlersPaginatedClinicalProtocols {
  items?: ModelsClinicalProtocol[];
  /** @example 1 */
  page?: number;
  /** @example 20 */
  per_page?: number;
  /** @example 1 */
  total_items?: number;
  /** @example 1 */
  total_pages?: number;
}

export interface HandlersPaginatedClinicalProtocolsEnvelope {
  data?: HandlersPaginatedClinicalProtocols;
  /** @example true */
  success?: boolean;
}

export interface HandlersPaginatedConversationsEnvelope {
  data?: ServicesPageResultServicesConversationView;
  success?: boolean;
}

export interface HandlersPaginatedDocumentationEnvelope {
  data?: ServicesPageResultModelsDocumentation;
  success?: boolean;
}

export interface HandlersPaginatedDrugCategoriesEnvelope {
  data?: {
    items?: ModelsDrugCategory[];
    page?: number;
    per_page?: number;
    total_items?: number;
    total_pages?: number;
  };
  /** @example true */
  success?: boolean;
}

export interface HandlersPaginatedDrugClassesEnvelope {
  data?: {
    items?: ModelsDrugClass[];
    page?: number;
    per_page?: number;
    total_items?: number;
    total_pages?: number;
  };
  /** @example true */
  success?: boolean;
}

export interface HandlersPaginatedDrugTagsEnvelope {
  data?: {
    items?: ModelsDrugTag[];
    page?: number;
    per_page?: number;
    total_items?: number;
    total_pages?: number;
  };
  /** @example true */
  success?: boolean;
}

export interface HandlersPaginatedDrugs {
  items?: ModelsDrug[];
  /** @example 1 */
  page?: number;
  /** @example 20 */
  per_page?: number;
  /** @example 1 */
  total_items?: number;
  /** @example 1 */
  total_pages?: number;
}

export interface HandlersPaginatedDrugsEnvelope {
  data?: HandlersPaginatedDrugs;
  /** @example true */
  success?: boolean;
}

export interface HandlersPaginatedEmergencyProtocolsEnvelope {
  data?: ServicesPageResultModelsEmergencyProtocol;
  success?: boolean;
}

export interface HandlersPaginatedFAQTagsEnvelope {
  data?: ServicesPageResultModelsFAQTag;
  success?: boolean;
}

export interface HandlersPaginatedFAQsEnvelope {
  data?: ServicesPageResultModelsFAQ;
  success?: boolean;
}

export interface HandlersPaginatedGenericPagesEnvelope {
  data?: ServicesPageResultModelsGenericPage;
  success?: boolean;
}

export interface HandlersPaginatedGuidelineCategoriesEnvelope {
  data?: ServicesPageResultModelsGuidelineCategory;
  success?: boolean;
}

export interface HandlersPaginatedGuidelineChunks {
  items?: ModelsGuidelineChunk[];
  /** @example 1 */
  page?: number;
  /** @example 100 */
  per_page?: number;
  /** @example 1 */
  total_items?: number;
  /** @example 1 */
  total_pages?: number;
}

export interface HandlersPaginatedGuidelineChunksEnvelope {
  data?: HandlersPaginatedGuidelineChunks;
  /** @example true */
  success?: boolean;
}

export interface HandlersPaginatedGuidelineCollectionItems {
  items?: ServicesGuidelineCollectionItemDTO[];
  page?: number;
  per_page?: number;
  total_items?: number;
  total_pages?: number;
}

export interface HandlersPaginatedGuidelineCollectionItemsEnvelope {
  data?: HandlersPaginatedGuidelineCollectionItems;
  success?: boolean;
}

export interface HandlersPaginatedGuidelineCollections {
  items?: ServicesGuidelineCollectionDTO[];
  page?: number;
  per_page?: number;
  total_items?: number;
  total_pages?: number;
}

export interface HandlersPaginatedGuidelineCollectionsEnvelope {
  data?: HandlersPaginatedGuidelineCollections;
  success?: boolean;
}

export interface HandlersPaginatedGuidelineDocuments {
  items?: ModelsGuidelineDocument[];
  /** @example 1 */
  page?: number;
  /** @example 20 */
  per_page?: number;
  /** @example 1 */
  total_items?: number;
  /** @example 1 */
  total_pages?: number;
}

export interface HandlersPaginatedGuidelineDocumentsEnvelope {
  data?: HandlersPaginatedGuidelineDocuments;
  /** @example true */
  success?: boolean;
}

export interface HandlersPaginatedGuidelineDownloads {
  items?: ServicesGuidelineDownloadDTO[];
  page?: number;
  per_page?: number;
  total_items?: number;
  total_pages?: number;
}

export interface HandlersPaginatedGuidelineDownloadsEnvelope {
  data?: HandlersPaginatedGuidelineDownloads;
  success?: boolean;
}

export interface HandlersPaginatedGuidelineIndexEnvelope {
  data?: ServicesPageResultModelsGuidelineIndexEntry;
  success?: boolean;
}

export interface HandlersPaginatedGuidelineSections {
  items?: ModelsGuidelineSection[];
  /** @example 1 */
  page?: number;
  /** @example 100 */
  per_page?: number;
  /** @example 1 */
  total_items?: number;
  /** @example 1 */
  total_pages?: number;
}

export interface HandlersPaginatedGuidelineSectionsEnvelope {
  data?: HandlersPaginatedGuidelineSections;
  /** @example true */
  success?: boolean;
}

export interface HandlersPaginatedGuidelineTagsEnvelope {
  data?: ServicesPageResultModelsGuidelineTag;
  success?: boolean;
}

export interface HandlersPaginatedLanguages {
  items?: ModelsLanguage[];
  /** @example 1 */
  page?: number;
  /** @example 20 */
  per_page?: number;
  /** @example 1 */
  total_items?: number;
  /** @example 1 */
  total_pages?: number;
}

export interface HandlersPaginatedLanguagesEnvelope {
  data?: HandlersPaginatedLanguages;
  /** @example true */
  success?: boolean;
}

export interface HandlersPaginatedMarkdownRevisions {
  items?: ModelsGuidelineMarkdownRevision[];
  /** @example 1 */
  page?: number;
  /** @example 20 */
  per_page?: number;
  /** @example 1 */
  total_items?: number;
  /** @example 1 */
  total_pages?: number;
}

export interface HandlersPaginatedMarkdownRevisionsEnvelope {
  data?: HandlersPaginatedMarkdownRevisions;
  /** @example true */
  success?: boolean;
}

export interface HandlersPaginatedMedicalGuidelinesEnvelope {
  data?: ServicesPageResultModelsMedicalGuideline;
  success?: boolean;
}

export interface HandlersPaginatedMessagesEnvelope {
  data?: ServicesPageResultServicesMessageView;
  success?: boolean;
}

export interface HandlersPaginatedMinistryDirectoryEnvelope {
  data?: ServicesPageResultModelsMinistryDirectoryEntry;
  success?: boolean;
}

export interface HandlersPaginatedNotificationCampaigns {
  items?: ModelsNotificationCampaign[];
  page?: number;
  per_page?: number;
  total_items?: number;
  total_pages?: number;
}

export interface HandlersPaginatedNotificationCampaignsEnvelope {
  data?: HandlersPaginatedNotificationCampaigns;
  success?: boolean;
}

export interface HandlersPaginatedNotificationTemplates {
  items?: ModelsNotificationTemplate[];
  page?: number;
  per_page?: number;
  total_items?: number;
  total_pages?: number;
}

export interface HandlersPaginatedNotificationTemplatesEnvelope {
  data?: HandlersPaginatedNotificationTemplates;
  success?: boolean;
}

export interface HandlersPaginatedNotifications {
  items?: ModelsNotification[];
  /** @example 1 */
  page?: number;
  /** @example 20 */
  per_page?: number;
  /** @example 1 */
  total_items?: number;
  /** @example 1 */
  total_pages?: number;
}

export interface HandlersPaginatedNotificationsEnvelope {
  data?: HandlersPaginatedNotifications;
  /** @example true */
  success?: boolean;
}

export interface HandlersPaginatedPublicGuidelineAlgorithms {
  items?: ServicesPublicGuidelineAlgorithm[];
  page?: number;
  per_page?: number;
  total_items?: number;
  total_pages?: number;
}

export interface HandlersPaginatedPublicGuidelineAlgorithmsEnvelope {
  data?: HandlersPaginatedPublicGuidelineAlgorithms;
  success?: boolean;
}

export interface HandlersPaginatedPublicGuidelineFigures {
  items?: ServicesPublicGuidelineFigure[];
  page?: number;
  per_page?: number;
  total_items?: number;
  total_pages?: number;
}

export interface HandlersPaginatedPublicGuidelineFiguresEnvelope {
  data?: HandlersPaginatedPublicGuidelineFigures;
  success?: boolean;
}

export interface HandlersPaginatedPublicGuidelineSections {
  items?: ServicesPublicGuidelineSection[];
  page?: number;
  per_page?: number;
  total_items?: number;
  total_pages?: number;
}

export interface HandlersPaginatedPublicGuidelineSectionsEnvelope {
  data?: HandlersPaginatedPublicGuidelineSections;
  success?: boolean;
}

export interface HandlersPaginatedPublicGuidelineTables {
  items?: ServicesPublicGuidelineTable[];
  page?: number;
  per_page?: number;
  total_items?: number;
  total_pages?: number;
}

export interface HandlersPaginatedPublicGuidelineTablesEnvelope {
  data?: HandlersPaginatedPublicGuidelineTables;
  success?: boolean;
}

export interface HandlersPaginatedPublicGuidelines {
  items?: ServicesPublicGuideline[];
  page?: number;
  per_page?: number;
  total_items?: number;
  total_pages?: number;
}

export interface HandlersPaginatedPublicGuidelinesEnvelope {
  data?: HandlersPaginatedPublicGuidelines;
  success?: boolean;
}

export interface HandlersPaginatedReadingProgressEnvelope {
  data?: ServicesPageResultModelsReadingProgress;
  success?: boolean;
}

export interface HandlersPaginatedRolesEnvelope {
  data?: ServicesPageResultServicesRoleView;
  /** @example true */
  success?: boolean;
}

export interface HandlersPaginatedSettings {
  items?: ModelsSetting[];
  /** @example 1 */
  page?: number;
  /** @example 20 */
  per_page?: number;
  /** @example 1 */
  total_items?: number;
  /** @example 1 */
  total_pages?: number;
}

export interface HandlersPaginatedSettingsEnvelope {
  data?: HandlersPaginatedSettings;
  /** @example true */
  success?: boolean;
}

export interface HandlersPaginatedSupportRepliesEnvelope {
  data?: ServicesPageResultModelsSupportTicketReply;
  success?: boolean;
}

export interface HandlersPaginatedSupportTicketsEnvelope {
  data?: ServicesPageResultModelsSupportTicket;
  success?: boolean;
}

export interface HandlersPaginatedTherapeuticCategoriesEnvelope {
  data?: {
    items?: ModelsTherapeuticCategory[];
    page?: number;
    per_page?: number;
    total_items?: number;
    total_pages?: number;
  };
  /** @example true */
  success?: boolean;
}

export interface HandlersPaginatedUsersEnvelope {
  data?: ServicesPageResultServicesUserView;
  /** @example true */
  success?: boolean;
}

export interface HandlersPasswordChangeRequest {
  current_password?: string;
  new_password?: string;
  new_password_confirm?: string;
}

export interface HandlersPasswordResetConfirmRequest {
  password?: string;
  password_confirm?: string;
  token?: string;
}

export interface HandlersPasswordResetRequest {
  /** @example "user@example.com" */
  email?: string;
}

export interface HandlersPermissionDocumentEnvelope {
  data?: object;
  /** @example true */
  success?: boolean;
}

export interface HandlersPermissionsEnvelope {
  data?: ModelsPermission[];
  /** @example true */
  success?: boolean;
}

export interface HandlersProtocolRunEnvelope {
  data?: ServicesRunProtocolResult;
  /** @example true */
  success?: boolean;
}

export interface HandlersPublicGuidelineAssetEnvelope {
  data?: ServicesPublicGuidelineAssetLink;
  success?: boolean;
}

export interface HandlersPublicGuidelineEnvelope {
  data?: ServicesPublicGuideline;
  success?: boolean;
}

export interface HandlersPublicGuidelineManifestEnvelope {
  data?: ServicesPublicGuidelineManifest;
  success?: boolean;
}

export interface HandlersPublicGuidelineSectionEnvelope {
  data?: ServicesPublicGuidelineSectionDetail;
  success?: boolean;
}

export interface HandlersPublishEnvelope {
  data?: HandlersPublishResult;
  /** @example true */
  success?: boolean;
}

export interface HandlersPublishResult {
  /** @example true */
  published?: boolean;
}

export interface HandlersReadingProgressEnvelope {
  data?: ModelsReadingProgress;
  success?: boolean;
}

export interface HandlersRefreshRequest {
  /** @example "Gm8m3Wq2oJ7l6p4XnYx9QbT2f1WvL0H1v2z3k4m5n6o" */
  refresh_token?: string;
}

export interface HandlersRegenerationCommentEnvelope {
  data?: ModelsGuidelineReviewComment;
  success?: boolean;
}

export interface HandlersRegenerationCommentsEnvelope {
  data?: ModelsGuidelineReviewComment[];
  success?: boolean;
}

export interface HandlersRegenerationJobViewEnvelope {
  data?: ServicesRegenerationJobView;
  success?: boolean;
}

export interface HandlersRegenerationReviewEnvelope {
  data?: ModelsGuidelineRegenerationReview;
  success?: boolean;
}

export interface HandlersRegisterRequest {
  /** @example "Plot 12 Kampala Road" */
  address?: string;
  /** @example "+256700000002" */
  alternative_phone?: string;
  /** @example "https://example.com/avatar.png" */
  avatar?: string;
  /** @example "Kampala" */
  city?: string;
  /** @example "Uganda" */
  country?: string;
  /** @example "Emergency" */
  department?: string;
  /** @example "admin@mediguide.local" */
  email?: string;
  /** @example "3fa85f64-5717-4562-b3fc-2c963f66afa6" */
  facility_id?: string;
  /** @example "Medical Officer" */
  job_title?: string;
  /** @example "MD-12345" */
  license_number?: string;
  /** @example "Admin User" */
  name?: string;
  /** @example "Night shift clinician" */
  notes?: string;
  /** @example "Mulago Hospital" */
  organization?: string;
  /** @example "Admin123!" */
  password?: string;
  /** @example "+256700000001" */
  phone?: string;
  /** @example "256" */
  postal_code?: string;
  /** @example "English" */
  preferred_language?: string;
  /** @example ["Internal Medicine","Pediatrics"] */
  specialization?: string[];
  /** @example "Africa/Kampala" */
  timezone?: string;
}

export interface HandlersRestoreMarkdownRevisionInput {
  expected_revision?: string;
}

export interface HandlersRolePermissionsRequest {
  permissions?: object;
}

export interface HandlersRoleViewEnvelope {
  data?: ServicesRoleView;
  /** @example true */
  success?: boolean;
}

export interface HandlersSearchResultsEnvelope {
  data?: ServicesSearchResult[];
  /** @example true */
  success?: boolean;
}

export interface HandlersSettingEnvelope {
  data?: ModelsSetting;
  /** @example true */
  success?: boolean;
}

export interface HandlersSupportReplyEnvelope {
  data?: ModelsSupportTicketReply;
  success?: boolean;
}

export interface HandlersSupportTicketEnvelope {
  data?: ModelsSupportTicket;
  success?: boolean;
}

export interface HandlersSyncPackageEnvelope {
  data?: ModelsSyncPackage;
  /** @example true */
  success?: boolean;
}

export interface HandlersTagUsageRecalculationEnvelope {
  data?: HandlersTagUsageRecalculationResult;
  /** @example true */
  success?: boolean;
}

export interface HandlersTagUsageRecalculationResult {
  /** @example true */
  updated?: boolean;
}

export interface HandlersTherapeuticCategoryEnvelope {
  data?: ModelsTherapeuticCategory;
  /** @example true */
  success?: boolean;
}

export interface HandlersUpdateMarkdownInput {
  content: string;
}

export interface HandlersUpdatedEnvelope {
  data?: HandlersUpdatedResult;
  /** @example true */
  success?: boolean;
}

export interface HandlersUpdatedResult {
  /** @example true */
  updated?: boolean;
}

export interface HandlersUsageAggregatesEnvelope {
  data?: ServicesUsageAggregate[];
  success?: boolean;
}

export interface HandlersUsageEventEnvelope {
  data?: any;
  success?: boolean;
}

export interface HandlersUserEnvelope {
  data?: ModelsUser;
  /** @example true */
  success?: boolean;
}

export interface HandlersUserViewEnvelope {
  data?: ServicesUserView;
  /** @example true */
  success?: boolean;
}

export interface HandlersVerificationResult {
  /** @example true */
  verified?: boolean;
}

export interface HandlersVerificationResultEnvelope {
  data?: HandlersVerificationResult;
  /** @example true */
  success?: boolean;
}

export interface HttpxResponse {
  data?: any;
  error?: string;
  success?: boolean;
}

export interface ModelsAbbreviation {
  abbreviation?: string;
  categories?: string[];
  common_usage?: boolean;
  created_at?: string;
  description?: string;
  id?: string;
  meaning?: string;
  tags?: string[];
  updated_at?: string;
  usage_count?: number;
}

export interface ModelsCalculator {
  added_by_user_id?: string;
  app_file_json?: object;
  background_color?: string;
  color?: string;
  created_at?: string;
  description?: string;
  featured?: boolean;
  icon?: string;
  id?: string;
  name?: string;
  status?: string;
  type?: string;
  updated_at?: string;
  usage_count?: number;
  version?: string;
}

export interface ModelsCalculatorUsageLog {
  calculator_id?: string;
  calculator_type?: string;
  created_at?: string;
  id?: string;
  session_end?: string;
  session_start?: string;
  updated_at?: string;
  user_id?: string;
}

export interface ModelsClinicalProtocol {
  code?: string;
  created_at?: string;
  definition_json?: string;
  definition_yaml?: string;
  id?: string;
  language?: string;
  program_area?: string;
  status?: string;
  title?: string;
  updated_at?: string;
  version?: string;
}

export interface ModelsDocumentation {
  category?: string;
  content?: string;
  created_at?: string;
  description?: string;
  id?: string;
  status?: string;
  tags?: string;
  title?: string;
  updated_at?: string;
}

export interface ModelsDrug {
  adult_dose?: string;
  antimicrobial_status?: boolean;
  brand_names?: string;
  categories_json?: string[];
  category_details?: ModelsDrugCategory[];
  clinical_notes?: string;
  contraindications?: string;
  controlled_substance?: string;
  created_at?: string;
  description?: string;
  drug_class_id?: string;
  drug_class_name?: string;
  duration?: string;
  elderly_dose?: string;
  frequency?: string;
  id?: string;
  indications?: string;
  max_daily_dose?: string;
  mechanism_of_action?: string;
  monitoring_parameters?: string;
  name?: string;
  pediatric_dose?: string;
  pregnancy_category?: string;
  reference_text?: string;
  review_status?: string;
  route_of_administration?: string;
  search_keywords?: string;
  side_effects?: string;
  status?: string;
  tag_details?: ModelsDrugTag[];
  tags_json?: string[];
  therapeutic_category_id?: string;
  therapeutic_category_name?: string;
  updated_at?: string;
  usage_count?: number;
  warnings?: string;
  who_eml_status?: boolean;
}

export interface ModelsDrugCategory {
  color?: string;
  created_at?: string;
  description?: string;
  icon?: string;
  id?: string;
  name?: string;
  parent_category_id?: string;
  sort_order?: number;
  status?: string;
  updated_at?: string;
}

export interface ModelsDrugClass {
  created_at?: string;
  description?: string;
  id?: string;
  name?: string;
  sort_order?: number;
  status?: string;
  updated_at?: string;
}

export interface ModelsDrugTag {
  color?: string;
  created_at?: string;
  description?: string;
  id?: string;
  name?: string;
  sort_order?: number;
  status?: string;
  tag_category?: string;
  updated_at?: string;
}

export interface ModelsDrugUsageLog {
  created_at?: string;
  drug_id?: string;
  id?: string;
  updated_at?: string;
  user_id?: string;
}

export interface ModelsEmergencyProtocol {
  access_count?: number;
  category?: string;
  contact_info?: object;
  created_at?: string;
  critical_actions?: object;
  description?: string;
  id?: string;
  medications?: object;
  priority?: string;
  status?: string;
  steps?: object;
  tags?: string[];
  timeframe?: string;
  title?: string;
  transfer_checklist?: object;
  updated_at?: string;
  vital_signs?: object;
}

export interface ModelsFAQ {
  answer?: string;
  author_email?: string;
  author_id?: string;
  author_name?: string;
  created_at?: string;
  id?: string;
  is_featured?: boolean;
  keywords?: string;
  priority?: string;
  published_at?: string;
  question?: string;
  related_faqs?: string[];
  review_due?: string;
  reviewer_email?: string;
  reviewer_id?: string;
  reviewer_name?: string;
  sort_order?: number;
  status?: string;
  tags?: string[];
  target_audience?: string;
  updated_at?: string;
}

export interface ModelsFAQTag {
  color?: string;
  created_at?: string;
  description?: string;
  icon?: string;
  id?: string;
  is_active?: boolean;
  name?: string;
  slug?: string;
  sort_order?: number;
  updated_at?: string;
  usage_count?: number;
}

export interface ModelsFacilityUsageLog {
  created_at?: string;
  facility_id?: string;
  id?: string;
  updated_at?: string;
  user_id?: string;
}

export interface ModelsGenericPage {
  content?: object;
  created_at?: string;
  description?: string;
  id?: string;
  key?: string;
  title?: string;
  updated_at?: string;
}

export interface ModelsGuidelineAlgorithmBlockPayload {
  nodes?: ModelsGuidelineAlgorithmNode[];
  title?: string;
  type?: ModelsGuidelineBlockType;
}

export interface ModelsGuidelineAlgorithmNode {
  id?: string;
  kind?: string;
  label?: string;
  next?: string[];
}

export interface ModelsGuidelineAsset {
  alternative_text?: string;
  attribution?: string;
  caption?: string;
  checksum?: string;
  clinically_sensitive?: boolean;
  created_at?: string;
  figure_number?: number;
  id?: string;
  license?: string;
  mime_type?: string;
  original_filename?: string;
  page_end?: number;
  page_start?: number;
  provenance?: object;
  review_status?: ModelsGuidelineBlockReviewStatus;
  reviewed_at?: string;
  reviewed_by?: string;
  section_id?: string;
  size_bytes?: number;
  source?: string;
  source_fingerprint?: string;
  type?: ModelsGuidelineAssetType;
  updated_at?: string;
  uploaded_by?: string;
  version_id?: string;
}

export type ModelsGuidelineAssetType =
  | "original_pdf"
  | "figure"
  | "diagram"
  | "thumbnail"
  | "supplementary_document"
  | "offline_package";

export type ModelsGuidelineBlockReviewStatus =
  | "draft"
  | "reviewed"
  | "rejected";

export type ModelsGuidelineBlockType =
  | "heading"
  | "paragraph"
  | "ordered_list"
  | "unordered_list"
  | "table"
  | "figure"
  | "recommendation"
  | "warning"
  | "caution"
  | "key_point"
  | "contraindication"
  | "dosage"
  | "evidence"
  | "definition"
  | "procedure"
  | "clinical_note"
  | "referral_criteria"
  | "algorithm_reference"
  | "algorithm"
  | "reference"
  | "page_break"
  | "unknown";

export interface ModelsGuidelineCategory {
  color?: string;
  created_at?: string;
  description?: string;
  icon?: string;
  id?: string;
  name?: string;
  parent_category_id?: string;
  parent_name?: string;
  slug?: string;
  sort_order?: number;
  status?: string;
  updated_at?: string;
}

export interface ModelsGuidelineChunk {
  block_id?: string;
  content?: string;
  created_at?: string;
  document_id?: string;
  html?: string;
  id?: string;
  language?: string;
  page_end?: number;
  page_start?: number;
  program_area?: string;
  review_status?: string;
  section_id?: string;
  source_name?: string;
  source_version?: string;
  title?: string;
  updated_at?: string;
  version_id?: string;
}

export interface ModelsGuidelineContentBlock {
  content?: object;
  created_at?: string;
  extraction_confidence?: number;
  id?: string;
  page_end?: number;
  page_start?: number;
  provenance?: object;
  review_status?: ModelsGuidelineBlockReviewStatus;
  reviewed_at?: string;
  reviewed_by?: string;
  section_id?: string;
  sort_order?: number;
  source_fingerprint?: string;
  type?: ModelsGuidelineBlockType;
  updated_at?: string;
  version_id?: string;
}

export interface ModelsGuidelineDocument {
  country?: string;
  created_at?: string;
  current_version_id?: string;
  description?: string;
  id?: string;
  language?: string;
  program_area?: string;
  source_org?: string;
  title?: string;
  updated_at?: string;
  versions?: ModelsGuidelineVersion[];
}

export type ModelsGuidelineExtractionQuality =
  | "reviewed"
  | "partially_reviewed"
  | "unreviewed"
  | "markdown_fallback";

export interface ModelsGuidelineFigureBlockPayload {
  alternative_text?: string;
  asset_id?: string;
  caption?: string;
  type?: ModelsGuidelineBlockType;
}

export interface ModelsGuidelineIndexEntry {
  created_at?: string;
  description?: string;
  has_children?: boolean;
  id?: string;
  level?: number;
  parent_id?: string;
  parent_title?: string;
  sort_order?: number;
  title?: string;
  updated_at?: string;
}

export interface ModelsGuidelineMarkdownRevision {
  anchor_metadata?: object;
  change_summary?: string;
  checkpoint_name?: string;
  checksum?: string;
  created_at?: string;
  created_by?: string;
  document_id?: string;
  id?: string;
  is_current?: boolean;
  parent_revision_id?: string;
  publication_state?: string;
  regeneration_job_id?: string;
  review_state?: string;
  revision_number?: number;
  size_bytes?: number;
  source_ingestion_job_id?: string;
  source_type?: string;
  structured_content_status?: string;
  updated_at?: string;
  version_id?: string;
}

export interface ModelsGuidelineRegenerationReview {
  after_snapshot?: object;
  before_snapshot?: object;
  comparison?: object;
  created_at?: string;
  decision_comment?: string;
  id?: string;
  job_id?: string;
  reviewed_at?: string;
  reviewed_by?: string;
  revision_id?: string;
  status?: string;
  updated_at?: string;
  version_id?: string;
}

export interface ModelsGuidelineReviewComment {
  author_id?: string;
  block_id?: string;
  body?: string;
  created_at?: string;
  id?: string;
  job_id?: string;
  updated_at?: string;
  version_id?: string;
}

export interface ModelsGuidelineSection {
  created_at?: string;
  html?: string;
  id?: string;
  level?: number;
  page_end?: number;
  page_start?: number;
  parent_id?: string;
  slug?: string;
  sort_order?: number;
  text?: string;
  title?: string;
  updated_at?: string;
  version_id?: string;
}

export interface ModelsGuidelineTableBlockPayload {
  columns?: string[];
  footnotes?: string[];
  rows?: string[][];
  title?: string;
  type?: ModelsGuidelineBlockType;
}

export interface ModelsGuidelineTag {
  created_at?: string;
  description?: string;
  id?: string;
  name?: string;
  updated_at?: string;
}

export interface ModelsGuidelineVersion {
  approved_at?: string;
  approved_by?: string;
  assets?: ModelsGuidelineAsset[];
  checksum?: string;
  content_blocks?: ModelsGuidelineContentBlock[];
  created_at?: string;
  current_markdown_revision_id?: string;
  document_id?: string;
  extraction_metadata?: object;
  extraction_schema_version?: number;
  extraction_warnings?: string[];
  html_file_key?: string;
  id?: string;
  manifest?: ModelsGuidelineVersionManifest;
  markdown_file_key?: string;
  original_file_key?: string;
  publication_date?: string;
  published_markdown_revision_id?: string;
  review_date?: string;
  sections?: ModelsGuidelineSection[];
  status?: string;
  structured_content_status?: string;
  structured_markdown_revision_id?: string;
  updated_at?: string;
  version?: string;
}

export interface ModelsGuidelineVersionManifest {
  algorithm_count?: number;
  block_count?: number;
  checksum?: string;
  created_at?: string;
  etag?: string;
  extraction_quality?: ModelsGuidelineExtractionQuality;
  figure_count?: number;
  generated_at?: string;
  guideline_id?: string;
  has_algorithms?: boolean;
  has_chapters?: boolean;
  has_figures?: boolean;
  has_key_points?: boolean;
  has_offline_package?: boolean;
  has_original_pdf?: boolean;
  has_tables?: boolean;
  id?: string;
  package_version?: number;
  schema_version?: number;
  section_count?: number;
  table_count?: number;
  updated_at?: string;
  version?: string;
  version_id?: string;
}

export interface ModelsIngestionJob {
  attempt_count?: number;
  cancel_requested_at?: string;
  canceled_at?: string;
  completed_at?: string;
  created_at?: string;
  error?: string;
  id?: string;
  job_type?: string;
  payload_json?: string;
  progress_percent?: number;
  progress_stage?: string;
  started_at?: string;
  status?: string;
  updated_at?: string;
  version_id?: string;
}

export interface ModelsLanguage {
  code?: string;
  created_at?: string;
  enabled_for_users?: boolean;
  id?: string;
  is_active?: boolean;
  is_default?: boolean;
  name?: string;
  native_name?: string;
  progress?: number;
  status?: string;
  translations_json?: object;
  translations_url?: string;
  updated_at?: string;
  version?: number;
}

export interface ModelsMedicalGuideline {
  icd10_code?: string;
  categories?: string[];
  category_details?: ModelsGuidelineCategory[];
  causes?: string;
  classification_critical?: string;
  classification_mild?: string;
  classification_moderate?: string;
  classification_severe?: string;
  clinical_features?: string;
  condition_name?: string;
  contraindications?: string;
  created_at?: string;
  definition?: string;
  differential_diagnosis?: string;
  dosage_adult?: string;
  dosage_pediatric?: string;
  dosage_secondary_adult?: string;
  dosage_secondary_pediatric?: string;
  general_management?: string;
  healthcare_level_required?: string;
  id?: string;
  index_item_id?: string;
  index_item_title?: string;
  is_published?: boolean;
  medication_primary?: string;
  medication_secondary?: string;
  monitoring_requirements?: string;
  prevention_measures?: string;
  priority?: string;
  route_administration?: string;
  special_notes?: string;
  status?: string;
  tag_details?: ModelsGuidelineTag[];
  tags?: string[];
  target_population?: string;
  updated_at?: string;
  usage_count?: number;
  version?: string;
}

export interface ModelsMinistryDirectoryEntry {
  alternative_phone?: string;
  availability_hours?: string;
  created_at?: string;
  department?: string;
  district_id?: string;
  district_name?: string;
  email?: string;
  id?: string;
  ministry?: string;
  name?: string;
  notes?: string;
  office_address?: string;
  phone?: string;
  priority_level?: number;
  region_id?: string;
  region_name?: string;
  specialization?: string;
  status?: string;
  title?: string;
  updated_at?: string;
}

export interface ModelsNotification {
  action_url?: string;
  created_at?: string;
  id?: string;
  is_read?: boolean;
  message?: string;
  priority?: string;
  title?: string;
  type?: string;
  updated_at?: string;
  user_id?: string;
}

export interface ModelsNotificationCampaign {
  audience_countries?: string[];
  audience_roles?: string[];
  audience_total?: number;
  channels?: string[];
  created_at?: string;
  id?: string;
  metrics_clicked?: number;
  metrics_delivered?: number;
  metrics_opened?: number;
  metrics_sent?: number;
  name?: string;
  schedule_end?: string;
  schedule_start?: string;
  status?: string;
  type?: string;
  updated_at?: string;
}

export interface ModelsNotificationTemplate {
  audience?: string;
  category?: string;
  clicked_count?: number;
  content?: string;
  created_at?: string;
  id?: string;
  last_sent?: string;
  name?: string;
  opened_count?: number;
  sent_count?: number;
  status?: string;
  subject?: string;
  type?: string;
  updated_at?: string;
  variables?: object;
}

export interface ModelsPermission {
  code?: string;
  created_at?: string;
  id?: string;
  name?: string;
  updated_at?: string;
}

export interface ModelsReadingProgress {
  created_at?: string;
  current_section?: string;
  guideline_document_id?: string;
  id?: string;
  is_bookmarked?: boolean;
  is_completed?: boolean;
  last_read_at?: string;
  notes?: string;
  progress_percentage?: number;
  reading_time_seconds?: number;
  total_sections?: number;
  updated_at?: string;
  user_id?: string;
}

export interface ModelsRole {
  created_at?: string;
  description?: string;
  id?: string;
  is_active?: boolean;
  name?: string;
  permissions?: ModelsPermission[];
  permissions_json?: object;
  role_key?: string;
  updated_at?: string;
}

export interface ModelsSetting {
  category?: string;
  created_at?: string;
  description?: string;
  id?: string;
  is_public?: boolean;
  key?: string;
  updated_at?: string;
  value_json?: object;
}

export interface ModelsSupportTicket {
  assigned_to?: string;
  assignee_name?: string;
  category?: string;
  created_at?: string;
  description?: string;
  id?: string;
  priority?: string;
  status?: string;
  subject?: string;
  updated_at?: string;
  user_email?: string;
  user_id?: string;
  user_name?: string;
}

export interface ModelsSupportTicketReply {
  created_at?: string;
  id?: string;
  is_internal?: boolean;
  message?: string;
  ticket_id?: string;
  updated_at?: string;
  user_email?: string;
  user_id?: string;
  user_name?: string;
}

export interface ModelsSyncPackage {
  checksum?: string;
  created_at?: string;
  file_key?: string;
  id?: string;
  manifest_json?: string;
  name?: string;
  size_bytes?: number;
  status?: string;
  updated_at?: string;
  version?: string;
}

export interface ModelsTherapeuticCategory {
  created_at?: string;
  description?: string;
  id?: string;
  name?: string;
  sort_order?: number;
  status?: string;
  updated_at?: string;
}

export interface ModelsUser {
  address?: string;
  alternative_phone?: string;
  avatar?: string;
  city?: string;
  country?: string;
  created_at?: string;
  department?: string;
  email?: string;
  facility_id?: string;
  id?: string;
  is_active?: boolean;
  job_title?: string;
  license_number?: string;
  name?: string;
  notes?: string;
  organization?: string;
  phone?: string;
  postal_code?: string;
  preferred_language?: string;
  roles?: ModelsRole[];
  specialization?: string[];
  status?: string;
  timezone?: string;
  updated_at?: string;
  verified?: boolean;
}

export interface ServicesAbbreviationInput {
  abbreviation?: string;
  categories?: string[];
  common_usage?: boolean;
  description?: string;
  meaning?: string;
  tags?: string[];
}

export interface ServicesAccountActionResult {
  accepted?: boolean;
  delivery_accepted?: boolean;
  development_token?: string;
}

export interface ServicesAskRequest {
  country?: string;
  language?: string;
  program_area?: string;
  question?: string;
  session_id?: string;
}

export interface ServicesAskResponse {
  answer?: string;
  citations?: ServicesCitation[];
  session_id?: string;
}

export interface ServicesCitation {
  chunk_id?: string;
  page_end?: number;
  page_start?: number;
  source_name?: string;
  source_version?: string;
  title?: string;
}

export interface ServicesConsultantInput {
  address?: string;
  alternative_phone?: string;
  availability?: object;
  avatar?: object;
  certifications?: string;
  city?: string;
  consultation_types?: string[];
  country?: string;
  department?: string;
  email?: string;
  is_verified?: boolean;
  license_number?: string;
  name?: string;
  notes?: string;
  organization?: string;
  phone?: string;
  postal_code?: string;
  preferred_language?: string;
  profile_picture?: object;
  qualifications?: string[];
  rating?: number;
  region?: string;
  specialty?: string;
  status?: string;
  timezone?: string;
  total_consultations?: number;
  user_id?: string;
  years_of_experience?: number;
}

export interface ServicesConsultantItem {
  item?: ServicesConsultantView;
}

export interface ServicesConsultantPage {
  items?: ServicesConsultantView[];
  page?: number;
  per_page?: number;
  total_items?: number;
  total_pages?: number;
}

export interface ServicesConsultantUserView {
  avatar?: string;
  email?: string;
  id?: string;
  name?: string;
  verified?: boolean;
}

export interface ServicesConsultantView {
  address?: string;
  alternative_phone?: string;
  availability?: object;
  avatar?: object;
  certifications?: string;
  city?: string;
  consultation_types?: string[];
  country?: string;
  created_at?: string;
  department?: string;
  email?: string;
  id?: string;
  is_verified?: boolean;
  license_number?: string;
  name?: string;
  notes?: string;
  organization?: string;
  phone?: string;
  postal_code?: string;
  preferred_language?: string;
  profile_picture?: object;
  qualifications?: string[];
  rating?: number;
  region?: string;
  specialty?: string;
  status?: string;
  timezone?: string;
  total_consultations?: number;
  updated_at?: string;
  usage_count?: number;
  user?: ServicesConsultantUserView;
  user_id?: string;
  years_of_experience?: number;
}

export interface ServicesConversationCreate {
  other_participant_id?: string;
}

export interface ServicesConversationView {
  participant1_avatar?: string;
  participant1_email?: string;
  participant1_name?: string;
  participant1_user_id?: string;
  participant1_verified?: boolean;
  participant2_avatar?: string;
  participant2_email?: string;
  participant2_name?: string;
  participant2_user_id?: string;
  participant2_verified?: boolean;
  created_at?: string;
  id?: string;
  last_activity?: string;
  last_message?: string;
  last_message_id?: string;
  updated_at?: string;
}

export interface ServicesCreateCalculatorInput {
  app_file_json?: object;
  background_color?: string;
  color?: string;
  description?: string;
  featured?: boolean;
  icon?: string;
  name?: string;
  status?: string;
  type?: string;
  version?: string;
}

export interface ServicesCreateGuidelineBlockInput {
  content: object;
  section_id?: string;
  sort_order?: number;
  type: ModelsGuidelineBlockType;
}

export interface ServicesCreateGuidelineInput {
  country?: string;
  description?: string;
  language?: string;
  program_area?: string;
  source_org?: string;
  title?: string;
}

export interface ServicesCreateGuidelineSectionInput {
  level: number;
  parent_id?: string;
  slug?: string;
  sort_order?: number;
  title: string;
}

export interface ServicesCreateProtocolInput {
  code?: string;
  definition_yaml?: string;
  language?: string;
  program_area?: string;
  title?: string;
  version?: string;
}

export interface ServicesCreateSettingInput {
  category?: string;
  description?: string;
  is_public?: boolean;
  key?: string;
  value_json?: object;
}

export interface ServicesCreateSyncPackageInput {
  manifest_json?: string;
  name?: string;
  version?: string;
}

export interface ServicesCreateVersionInput {
  publication_date?: string;
  review_date?: string;
  version?: string;
}

export interface ServicesDocumentationInput {
  category?: string;
  content?: string;
  description?: string;
  status?: string;
  tags?: string;
  title?: string;
}

export interface ServicesDrugCategoryInput {
  color?: string;
  description?: string;
  icon?: string;
  name?: string;
  parent_category_id?: string;
  sort_order?: number;
  status?: string;
}

export interface ServicesDrugInput {
  adult_dose?: string;
  antimicrobial_status?: boolean;
  brand_names?: string;
  categories?: string[];
  clinical_notes?: string;
  contraindications?: string;
  controlled_substance?: string;
  description?: string;
  drug_class_id?: string;
  duration?: string;
  elderly_dose?: string;
  frequency?: string;
  indications?: string;
  max_daily_dose?: string;
  mechanism_of_action?: string;
  monitoring_parameters?: string;
  name?: string;
  pediatric_dose?: string;
  pregnancy_category?: string;
  reference_text?: string;
  review_status?: string;
  route_of_administration?: string;
  search_keywords?: string;
  side_effects?: string;
  status?: string;
  tags?: string[];
  therapeutic_category_id?: string;
  warnings?: string;
  who_eml_status?: boolean;
}

export interface ServicesDrugNamedReferenceInput {
  description?: string;
  name?: string;
  sort_order?: number;
  status?: string;
}

export interface ServicesDrugTagInput {
  color?: string;
  description?: string;
  name?: string;
  sort_order?: number;
  status?: string;
  tag_category?: string;
}

export interface ServicesDuplicateMarkdownVersionInput {
  publication_date?: string;
  review_date?: string;
  version?: string;
}

export interface ServicesDuplicatedGuidelineVersion {
  created_at?: string;
  current_markdown_revision_id?: string;
  document_id?: string;
  id?: string;
  publication_date?: string;
  review_date?: string;
  status?: string;
  structured_content_status?: string;
  updated_at?: string;
  version?: string;
}

export interface ServicesDuplicatedMarkdownVersion {
  draft?: ServicesMarkdownDraft;
  version?: ServicesDuplicatedGuidelineVersion;
}

export interface ServicesEmergencyProtocolInput {
  category?: string;
  contact_info?: object;
  critical_actions?: object;
  description?: string;
  medications?: object;
  priority?: string;
  status?: string;
  steps?: object;
  tags?: string[];
  timeframe?: string;
  title?: string;
  transfer_checklist?: object;
  vital_signs?: object;
}

export interface ServicesFAQInput {
  answer?: string;
  author_id?: string;
  is_featured?: boolean;
  keywords?: string;
  priority?: string;
  published_at?: string;
  question?: string;
  related_faqs?: string[];
  review_due?: string;
  reviewer_id?: string;
  sort_order?: number;
  status?: string;
  tags?: string[];
  target_audience?: string;
}

export interface ServicesFAQTagInput {
  color?: string;
  description?: string;
  icon?: string;
  is_active?: boolean;
  name?: string;
  slug?: string;
  sort_order?: number;
}

export interface ServicesFacilityInput {
  authority_id?: string;
  county_id?: string;
  district_id?: string;
  facility_level_id?: string;
  health_sub_district_id?: string;
  health_sub_region_id?: string;
  hsdt_code?: string;
  name?: string;
  nhpi_code?: string;
  ownership_type_id?: string;
  parish_id?: string;
  region_id?: string;
  subcounty_id?: string;
}

export interface ServicesFacilityItem {
  item?: ServicesFacilityView;
  resource?: string;
  success?: boolean;
}

export interface ServicesFacilityPage {
  items?: ServicesFacilityView[];
  page?: number;
  per_page?: number;
  resource?: string;
  success?: boolean;
  total_items?: number;
  total_pages?: number;
}

export interface ServicesFacilityReferenceView {
  code?: string;
  county_id?: string;
  county_name?: string;
  created_at?: string;
  district_id?: string;
  district_name?: string;
  health_sub_region_id?: string;
  health_sub_region_name?: string;
  hsdt_code?: string;
  id?: string;
  name?: string;
  nhpi_code?: string;
  ownership_type_id?: string;
  ownership_type_name?: string;
  region_id?: string;
  region_name?: string;
  subcounty_id?: string;
  subcounty_name?: string;
  updated_at?: string;
}

export interface ServicesFacilityView {
  authority_code?: string;
  authority_id?: string;
  authority_name?: string;
  county_id?: string;
  county_name?: string;
  created_at?: string;
  district_id?: string;
  district_name?: string;
  facility_level_code?: string;
  facility_level_id?: string;
  facility_level_name?: string;
  health_sub_district_id?: string;
  health_sub_district_name?: string;
  health_sub_region_id?: string;
  health_sub_region_name?: string;
  hsdt_code?: string;
  id?: string;
  name?: string;
  nhpi_code?: string;
  ownership_type_code?: string;
  ownership_type_id?: string;
  ownership_type_name?: string;
  parish_id?: string;
  parish_name?: string;
  region_id?: string;
  region_name?: string;
  subcounty_id?: string;
  subcounty_name?: string;
  updated_at?: string;
  usage_count?: number;
}

export interface ServicesFinishCalculatorUsageInput {
  session_end?: string;
}

export interface ServicesGenericPageInput {
  content?: object;
  description?: string;
  key?: string;
  title?: string;
}

export interface ServicesGuidelineAssetDTO {
  alternative_text?: string;
  attribution?: string;
  caption?: string;
  checksum?: string;
  clinically_sensitive?: boolean;
  created_at?: string;
  figure_number?: number;
  id?: string;
  license?: string;
  mime_type?: string;
  original_filename?: string;
  reference?: string;
  referenced?: boolean;
  review_status?: ModelsGuidelineBlockReviewStatus;
  reviewed_at?: string;
  reviewed_by?: string;
  size_bytes?: number;
  source?: string;
  type?: ModelsGuidelineAssetType;
  updated_at?: string;
  uploaded_by?: string;
  url?: string;
  url_expires_at?: string;
  version_id?: string;
}

export interface ServicesGuidelineAssetInput {
  alternative_text?: string;
  attribution?: string;
  caption?: string;
  clinically_sensitive?: boolean;
  figure_number?: number;
  license?: string;
  source?: string;
}

export interface ServicesGuidelineAssetList {
  broken_references?: string[];
  items?: ServicesGuidelineAssetDTO[];
}

export interface ServicesGuidelineBlockOrderInput {
  id: string;
  section_id?: string;
  sort_order?: number;
}

export interface ServicesGuidelineCategoryInput {
  color?: string;
  description?: string;
  icon?: string;
  name?: string;
  parent_category_id?: string;
  slug?: string;
  sort_order?: number;
  status?: string;
}

export interface ServicesGuidelineCollectionDTO {
  created_at?: string;
  description?: string;
  id?: string;
  item_count?: number;
  name?: string;
  updated_at?: string;
}

export interface ServicesGuidelineCollectionInput {
  description?: string;
  name: string;
}

export interface ServicesGuidelineCollectionItemDTO {
  added_at?: string;
  guideline?: ServicesPublicGuideline;
  id?: string;
  sort_order?: number;
}

export interface ServicesGuidelineCollectionItemInput {
  guideline_id: string;
  sort_order?: number;
}

export interface ServicesGuidelineDownloadDTO {
  asset_type?: string;
  downloaded_at?: string;
  guideline_id?: string;
  id?: string;
  version_id?: string;
}

export interface ServicesGuidelineDownloadInput {
  asset_type: string;
  guideline_id: string;
}

export interface ServicesGuidelineExtractionStatus {
  asset_count?: number;
  attempt_count?: number;
  block_count?: number;
  completed_at?: string;
  error?: string;
  extraction_schema_version?: number;
  job_status?: string;
  section_count?: number;
  started_at?: string;
  version_id?: string;
  version_status?: string;
  warnings?: string[];
}

export interface ServicesGuidelineIndexInput {
  description?: string;
  parent_id?: string;
  sort_order?: number;
  title?: string;
}

export interface ServicesGuidelinePreview {
  blocks?: ServicesPublicGuidelineBlock[];
  sections?: ServicesPublicGuidelineSection[];
  status?: string;
  validation?: ServicesGuidelinePublicationValidation;
  version_id?: string;
}

export interface ServicesGuidelinePublicationValidation {
  errors?: ServicesGuidelineReviewIssue[];
  valid?: boolean;
  warnings?: ServicesGuidelineReviewIssue[];
}

export interface ServicesGuidelineReviewCommentInput {
  block_id?: string;
  body?: string;
}

export interface ServicesGuidelineReviewIssue {
  asset_id?: string;
  block_id?: string;
  code?: string;
  message?: string;
  section_id?: string;
}

export interface ServicesGuidelineReviewWorkspace {
  assets?: ModelsGuidelineAsset[];
  blocks?: ModelsGuidelineContentBlock[];
  extraction_warnings?: string[];
  sections?: ModelsGuidelineSection[];
  validation?: ServicesGuidelinePublicationValidation;
  version?: ModelsGuidelineVersion;
}

export interface ServicesGuidelineSectionOrderInput {
  id: string;
  level?: number;
  parent_id?: string;
  sort_order?: number;
}

export interface ServicesGuidelineTagInput {
  description?: string;
  name?: string;
}

export interface ServicesLanguageInput {
  code?: string;
  enabled_for_users?: boolean;
  is_active?: boolean;
  is_default?: boolean;
  name?: string;
  native_name?: string;
  progress?: number;
  status?: string;
  translations?: object;
  translations_url?: string;
  version?: number;
}

export interface ServicesLoginResult {
  expires_at?: string;
  refresh_expires_at?: string;
  refresh_token?: string;
  session_id?: string;
  token?: string;
  user?: ModelsUser;
}

export interface ServicesManifestResult {
  generated_at?: string;
  packages?: ModelsSyncPackage[];
}

export interface ServicesMarkdownDraft {
  content?: string;
  etag?: string;
  revision?: ModelsGuidelineMarkdownRevision;
  saved?: boolean;
}

export interface ServicesMarkdownDraftInput {
  anchor_metadata?: object;
  change_summary?: string;
  checkpoint_name?: string;
  content?: string;
  expected_revision?: string;
  parent_revision_id?: string;
  source_type?: string;
}

export interface ServicesMarkdownRegenerationInput {
  idempotency_key?: string;
  operations?: string[];
  revision_id?: string;
}

export interface ServicesMarkdownRegenerationResult {
  job?: ModelsIngestionJob;
  operations?: string[];
  queued_at?: string;
  revision_id?: string;
}

export interface ServicesMarkdownValidationIssue {
  code?: string;
  column?: number;
  end_column?: number;
  end_line?: number;
  line?: number;
  message?: string;
  severity?: string;
}

export interface ServicesMarkdownValidationResult {
  errors?: number;
  info?: number;
  issues?: ServicesMarkdownValidationIssue[];
  revision_id?: string;
  valid?: boolean;
  warnings?: number;
}

export interface ServicesMedicalGuidelineInput {
  icd10_code?: string;
  categories?: string[];
  causes?: string;
  classification_critical?: string;
  classification_mild?: string;
  classification_moderate?: string;
  classification_severe?: string;
  clinical_features?: string;
  condition_name?: string;
  contraindications?: string;
  definition?: string;
  differential_diagnosis?: string;
  dosage_adult?: string;
  dosage_pediatric?: string;
  dosage_secondary_adult?: string;
  dosage_secondary_pediatric?: string;
  general_management?: string;
  healthcare_level_required?: string;
  index_item_id?: string;
  is_published?: boolean;
  medication_primary?: string;
  medication_secondary?: string;
  monitoring_requirements?: string;
  prevention_measures?: string;
  priority?: string;
  route_administration?: string;
  special_notes?: string;
  status?: string;
  tags?: string[];
  target_population?: string;
  version?: string;
}

export interface ServicesMergeGuidelineSectionInput {
  target_section_id: string;
}

export interface ServicesMessageCreate {
  attachments?: string[];
  content?: string;
  message_type?: string;
  reply_to_id?: string;
}

export interface ServicesMessageReactionInput {
  active?: boolean;
  emoji?: string;
}

export interface ServicesMessageReadInput {
  read_at?: string;
}

export interface ServicesMessageView {
  attachments?: string[];
  content?: string;
  conversation_id?: string;
  created_at?: string;
  edited_at?: string;
  id?: string;
  is_edited?: boolean;
  message_type?: string;
  reactions?: object;
  read_by?: object;
  reply_to_id?: string;
  sender_avatar?: string;
  sender_email?: string;
  sender_name?: string;
  sender_user_id?: string;
  sender_verified?: boolean;
  updated_at?: string;
}

export interface ServicesMinistryDirectoryInput {
  alternative_phone?: string;
  availability_hours?: string;
  department?: string;
  district_id?: string;
  email?: string;
  ministry?: string;
  name?: string;
  notes?: string;
  office_address?: string;
  phone?: string;
  priority_level?: number;
  region_id?: string;
  specialization?: string;
  status?: string;
  title?: string;
}

export interface ServicesNotificationCampaignInput {
  audience_countries?: string[];
  audience_roles?: string[];
  channels?: string[];
  name?: string;
  schedule_end?: string;
  schedule_start?: string;
  status?: string;
  type?: string;
}

export interface ServicesNotificationInput {
  action_url?: string;
  message?: string;
  priority?: string;
  title?: string;
  type?: string;
  user_id?: string;
}

export interface ServicesNotificationTemplateInput {
  audience?: string;
  category?: string;
  content?: string;
  name?: string;
  status?: string;
  subject?: string;
  type?: string;
  variables?: Record<string, any>;
}

export interface ServicesPageResultModelsAbbreviation {
  items?: ModelsAbbreviation[];
  page?: number;
  per_page?: number;
  total_items?: number;
  total_pages?: number;
}

export interface ServicesPageResultModelsDocumentation {
  items?: ModelsDocumentation[];
  page?: number;
  per_page?: number;
  total_items?: number;
  total_pages?: number;
}

export interface ServicesPageResultModelsEmergencyProtocol {
  items?: ModelsEmergencyProtocol[];
  page?: number;
  per_page?: number;
  total_items?: number;
  total_pages?: number;
}

export interface ServicesPageResultModelsFAQ {
  items?: ModelsFAQ[];
  page?: number;
  per_page?: number;
  total_items?: number;
  total_pages?: number;
}

export interface ServicesPageResultModelsFAQTag {
  items?: ModelsFAQTag[];
  page?: number;
  per_page?: number;
  total_items?: number;
  total_pages?: number;
}

export interface ServicesPageResultModelsGenericPage {
  items?: ModelsGenericPage[];
  page?: number;
  per_page?: number;
  total_items?: number;
  total_pages?: number;
}

export interface ServicesPageResultModelsGuidelineCategory {
  items?: ModelsGuidelineCategory[];
  page?: number;
  per_page?: number;
  total_items?: number;
  total_pages?: number;
}

export interface ServicesPageResultModelsGuidelineIndexEntry {
  items?: ModelsGuidelineIndexEntry[];
  page?: number;
  per_page?: number;
  total_items?: number;
  total_pages?: number;
}

export interface ServicesPageResultModelsGuidelineTag {
  items?: ModelsGuidelineTag[];
  page?: number;
  per_page?: number;
  total_items?: number;
  total_pages?: number;
}

export interface ServicesPageResultModelsMedicalGuideline {
  items?: ModelsMedicalGuideline[];
  page?: number;
  per_page?: number;
  total_items?: number;
  total_pages?: number;
}

export interface ServicesPageResultModelsMinistryDirectoryEntry {
  items?: ModelsMinistryDirectoryEntry[];
  page?: number;
  per_page?: number;
  total_items?: number;
  total_pages?: number;
}

export interface ServicesPageResultModelsReadingProgress {
  items?: ModelsReadingProgress[];
  page?: number;
  per_page?: number;
  total_items?: number;
  total_pages?: number;
}

export interface ServicesPageResultModelsSupportTicket {
  items?: ModelsSupportTicket[];
  page?: number;
  per_page?: number;
  total_items?: number;
  total_pages?: number;
}

export interface ServicesPageResultModelsSupportTicketReply {
  items?: ModelsSupportTicketReply[];
  page?: number;
  per_page?: number;
  total_items?: number;
  total_pages?: number;
}

export interface ServicesPageResultServicesConversationView {
  items?: ServicesConversationView[];
  page?: number;
  per_page?: number;
  total_items?: number;
  total_pages?: number;
}

export interface ServicesPageResultServicesMessageView {
  items?: ServicesMessageView[];
  page?: number;
  per_page?: number;
  total_items?: number;
  total_pages?: number;
}

export interface ServicesPageResultServicesRoleView {
  items?: ServicesRoleView[];
  page?: number;
  per_page?: number;
  total_items?: number;
  total_pages?: number;
}

export interface ServicesPageResultServicesUserView {
  items?: ServicesUserView[];
  page?: number;
  per_page?: number;
  total_items?: number;
  total_pages?: number;
}

export interface ServicesProtocolStep {
  citation?: Record<string, string>;
  id?: string;
  message?: string;
  next?: Record<string, any>;
  options?: string[];
  question?: string;
  type?: string;
}

export interface ServicesPublicGuideline {
  country?: string;
  description?: string;
  id?: string;
  language?: string;
  last_updated?: string;
  program_area?: string;
  publication_date?: string;
  review_date?: string;
  slug?: string;
  source_org?: string;
  title?: string;
  version?: string;
}

export interface ServicesPublicGuidelineAlgorithm {
  content?: ModelsGuidelineAlgorithmBlockPayload;
  id?: string;
  page_end?: number;
  page_start?: number;
  section_id?: string;
  sort_order?: number;
}

export interface ServicesPublicGuidelineAssetLink {
  asset_id?: string;
  checksum?: string;
  expires_at?: string;
  mime_type?: string;
  original_filename?: string;
  size_bytes?: number;
  type?: string;
  url?: string;
}

export interface ServicesPublicGuidelineBlock {
  content?: object;
  id?: string;
  page_end?: number;
  page_start?: number;
  section_id?: string;
  sort_order?: number;
  type?: ModelsGuidelineBlockType;
}

export interface ServicesPublicGuidelineFigure {
  asset?: ServicesPublicGuidelineAssetLink;
  content?: ModelsGuidelineFigureBlockPayload;
  id?: string;
  page_end?: number;
  page_start?: number;
  section_id?: string;
  sort_order?: number;
}

export interface ServicesPublicGuidelineManifest {
  algorithm_count?: number;
  block_count?: number;
  checksum?: string;
  etag?: string;
  extraction_quality?: ModelsGuidelineExtractionQuality;
  figure_count?: number;
  generated_at?: string;
  guideline_id?: string;
  has_algorithms?: boolean;
  has_chapters?: boolean;
  has_figures?: boolean;
  has_key_points?: boolean;
  has_offline_package?: boolean;
  has_original_pdf?: boolean;
  has_tables?: boolean;
  package_version?: number;
  schema_version?: number;
  section_count?: number;
  table_count?: number;
  version?: string;
  version_id?: string;
}

export interface ServicesPublicGuidelineSection {
  id?: string;
  level?: number;
  page_end?: number;
  page_start?: number;
  parent_id?: string;
  slug?: string;
  sort_order?: number;
  title?: string;
}

export interface ServicesPublicGuidelineSectionDetail {
  blocks?: ServicesPublicGuidelineBlock[];
  section?: ServicesPublicGuidelineSection;
}

export interface ServicesPublicGuidelineTable {
  content?: ModelsGuidelineTableBlockPayload;
  id?: string;
  page_end?: number;
  page_start?: number;
  section_id?: string;
  sort_order?: number;
}

export interface ServicesReadingProgressInput {
  current_section?: string;
  is_bookmarked?: boolean;
  is_completed?: boolean;
  last_read_at?: string;
  notes?: string;
  progress_percentage?: number;
  reading_time_seconds?: number;
  total_sections?: number;
}

export interface ServicesRegenerationDecisionInput {
  comment?: string;
}

export interface ServicesRegenerationJobView {
  job?: ModelsIngestionJob;
  operations?: string[];
  revision_id?: string;
}

export interface ServicesRegionChildren {
  districts?: ServicesFacilityReferenceView[];
  health_sub_regions?: ServicesFacilityReferenceView[];
  region?: ServicesFacilityReferenceView;
}

export interface ServicesReorderGuidelineBlocksInput {
  blocks: ServicesGuidelineBlockOrderInput[];
}

export interface ServicesReorderGuidelineSectionsInput {
  sections: ServicesGuidelineSectionOrderInput[];
}

export interface ServicesReviewGuidelineAssetInput {
  status: ModelsGuidelineBlockReviewStatus;
}

export interface ServicesReviewGuidelineBlockInput {
  status: ModelsGuidelineBlockReviewStatus;
}

export interface ServicesRoleInput {
  description?: string;
  isActive?: boolean;
  key?: string;
  name?: string;
  permissions?: object;
}

export interface ServicesRoleView {
  created_at?: string;
  description?: string;
  id?: string;
  isActive?: boolean;
  key?: string;
  name?: string;
  permissions?: object;
  updated_at?: string;
  user_count?: number;
}

export interface ServicesRunProtocolResult {
  current_step?: ServicesProtocolStep;
  input?: Record<string, any>;
  note?: string;
  protocol?: string;
}

export interface ServicesSearchResult {
  id?: string;
  page_end?: number;
  page_start?: number;
  snippet?: string;
  source_name?: string;
  source_version?: string;
  title?: string;
}

export interface ServicesSplitGuidelineSectionInput {
  block_id: string;
  level?: number;
  slug?: string;
  title: string;
}

export interface ServicesStartCalculatorUsageInput {
  calculator_type?: string;
  session_start?: string;
}

export interface ServicesSupportReplyCreate {
  is_internal?: boolean;
  message?: string;
}

export interface ServicesSupportTicketCreate {
  category?: string;
  description?: string;
  priority?: string;
  subject?: string;
}

export interface ServicesSupportTicketUpdate {
  assigned_to?: string;
  category?: string;
  description?: string;
  priority?: string;
  status?: string;
  subject?: string;
}

export interface ServicesTreeNode {
  count?: number;
  filters?: Record<string, string>;
  hasChildren?: boolean;
  id?: string;
  level?: number;
  subtitle?: string;
  title?: string;
}

export interface ServicesUpdateCalculatorInput {
  app_file_json?: object;
  background_color?: string;
  color?: string;
  description?: string;
  featured?: boolean;
  icon?: string;
  name?: string;
  status?: string;
  type?: string;
  version?: string;
}

export interface ServicesUpdateGuidelineBlockInput {
  content?: object;
  section_id?: string;
  sort_order?: number;
  type?: string;
}

export interface ServicesUpdateGuidelineInput {
  country?: string;
  description?: string;
  language?: string;
  program_area?: string;
  source_org?: string;
  title?: string;
}

export interface ServicesUpdateGuidelineSectionInput {
  level?: number;
  parent_id?: string;
  slug?: string;
  sort_order?: number;
  title?: string;
}

export interface ServicesUsageAggregate {
  count?: number;
  event_type?: string;
}

export interface ServicesUsageEventInput {
  idempotency_key?: string;
  resource_id?: string;
}

export interface ServicesUserCreateInput {
  email?: string;
  name?: string;
  password?: string;
  phone?: string;
  role?: string;
  role_id?: string;
  status?: string;
}

export interface ServicesUserUpdateInput {
  address?: string;
  alternative_phone?: string;
  avatar?: string;
  city?: string;
  country?: string;
  department?: string;
  email?: string;
  is_active?: boolean;
  job_title?: string;
  name?: string;
  notes?: string;
  organization?: string;
  password?: string;
  phone?: string;
  postal_code?: string;
  preferred_language?: string;
  role?: string;
  role_id?: string;
  specialization?: string[];
  status?: string;
  timezone?: string;
  verified?: boolean;
}

export interface ServicesUserView {
  address?: string;
  alternative_phone?: string;
  avatar?: string;
  city?: string;
  country?: string;
  created_at?: string;
  department?: string;
  email?: string;
  facility_id?: string;
  id?: string;
  is_active?: boolean;
  job_title?: string;
  license_number?: string;
  name?: string;
  notes?: string;
  organization?: string;
  phone?: string;
  postal_code?: string;
  preferred_language?: string;
  role?: string;
  role_id?: string;
  roles?: ModelsRole[];
  specialization?: string[];
  status?: string;
  timezone?: string;
  updated_at?: string;
  verified?: boolean;
}
