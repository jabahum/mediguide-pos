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

export interface ClinicaltoolsAction {
  message_key?: string;
  target?: string;
  type?: string;
  value?: ClinicaltoolsExpression;
}

export interface ClinicaltoolsCalculation {
  expression?: ClinicaltoolsExpression;
  key?: string;
  precision?: number;
  rounding_mode?: string;
  unit?: string;
}

export interface ClinicaltoolsCitation {
  accessed_at?: string;
  key?: string;
  organization?: string;
  published_at?: string;
  title?: string;
  url?: string;
}

export interface ClinicaltoolsCompletion {
  allow_resume?: boolean;
  expression?: ClinicaltoolsExpression;
  mode?: string;
  require_review?: boolean;
  reset_confirmation?: boolean;
  show_percentage?: boolean;
}

export interface ClinicaltoolsDefinition {
  calculation?: ClinicaltoolsCalculation[];
  citations?: ClinicaltoolsCitation[];
  clinical_owner?: string;
  clinical_reviewer?: string;
  completion?: ClinicaltoolsCompletion;
  description?: string;
  effective_at?: string;
  exclusions?: string[];
  inputs?: ClinicaltoolsInput[];
  interpretations?: ClinicaltoolsInterpretation[];
  locale?: string;
  minimum_app_version?: string;
  outputs?: ClinicaltoolsOutput[];
  review_at?: string;
  rules?: ClinicaltoolsRule[];
  schema_version?: string;
  sections?: ClinicaltoolsSection[];
  supported_population?: string[];
  test_cases?: ClinicaltoolsTestCase[];
  title?: string;
  tool_type?: string;
  version?: string;
  warnings?: ClinicaltoolsMessage[];
}

export interface ClinicaltoolsEvaluationError {
  code?: string;
  message?: string;
  path?: string;
}

export interface ClinicaltoolsExpression {
  args?: ClinicaltoolsExpression[];
  date_unit?: string;
  field?: string;
  from_unit?: string;
  op?: string;
  precision?: number;
  rounding_mode?: string;
  to_unit?: string;
  value?: object;
}

export interface ClinicaltoolsInput {
  accessibility_label?: string;
  allow_note?: boolean;
  allowed_units?: string[];
  checklist_kind?: string;
  clinical_warning?: string;
  critical?: boolean;
  default?: object;
  default_unit?: string;
  depends_on?: string[];
  description?: string;
  escalation_message_keys?: string[];
  help_text?: string;
  key?: string;
  label?: string;
  maximum?: number;
  minimum?: number;
  options?: ClinicaltoolsOption[];
  required?: boolean;
  section_key?: string;
  step?: number;
  stop_when?: ClinicaltoolsExpression;
  type?: string;
  visible_when?: ClinicaltoolsExpression;
}

export interface ClinicaltoolsInterpretation {
  description?: string;
  key?: string;
  label?: string;
  order?: number;
  recommendations?: string[];
  severity?: string;
  when?: ClinicaltoolsExpression;
}

export interface ClinicaltoolsMessage {
  key?: string;
  severity?: string;
  text?: string;
  when?: ClinicaltoolsExpression;
}

export interface ClinicaltoolsOption {
  description?: string;
  label?: string;
  score?: number;
  value?: object;
}

export interface ClinicaltoolsOutput {
  accessibility_label?: string;
  key?: string;
  label?: string;
  precision?: number;
  rounding_mode?: string;
  unit?: string;
  value?: ClinicaltoolsExpression;
}

export interface ClinicaltoolsRule {
  actions?: ClinicaltoolsAction[];
  key?: string;
  order?: number;
  stop?: boolean;
  when?: ClinicaltoolsExpression;
}

export interface ClinicaltoolsSection {
  description?: string;
  key?: string;
  order?: number;
  review_before_completion?: boolean;
  title?: string;
  visible_when?: ClinicaltoolsExpression;
}

export interface ClinicaltoolsTestCase {
  description?: string;
  expected?: object;
  fixed_now?: string;
  inputs?: object;
  key?: string;
  numeric_tolerance?: number;
}

export interface ClinicaltoolsTestCaseResult {
  actual?: Record<string, any>;
  errors?: ClinicaltoolsEvaluationError[];
  expected?: Record<string, any>;
  key?: string;
  passed?: boolean;
}

export interface ClinicaltoolsTestReport {
  cases?: ClinicaltoolsTestCaseResult[];
  passed?: boolean;
}

export interface ClinicaltoolsValidationError {
  code?: string;
  message?: string;
  path?: string;
}

export interface HandlersAbbreviationEnvelope {
  data?: ModelsAbbreviation;
  success?: boolean;
}

export interface HandlersAskEnvelope {
  data?: ServicesAskResponse;
  /** @example true */
  success?: boolean;
}

export interface HandlersCalculatorDefinitionEnvelope {
  data?: ServicesCalculatorDefinitionDTO;
  success?: boolean;
}

export interface HandlersCalculatorEnvelope {
  data?: ModelsCalculator;
  /** @example true */
  success?: boolean;
}

export interface HandlersCalculatorReviewQueueEnvelope {
  data?: ServicesPageResultServicesCalculatorReviewQueueItem;
  success?: boolean;
}

export interface HandlersCalculatorUsageEnvelope {
  data?: ModelsCalculatorUsageLog;
  /** @example true */
  success?: boolean;
}

export interface HandlersCalculatorVersionAuditEnvelope {
  data?: ServicesCalculatorVersionAuditDTO[];
  success?: boolean;
}

export interface HandlersCalculatorVersionEnvelope {
  data?: ServicesCalculatorVersionDTO;
  success?: boolean;
}

export interface HandlersCalculatorVersionLockRequest {
  /** @min 1 */
  lock_version: number;
}

export interface HandlersCalculatorVersionPreviewEnvelope {
  data?: ServicesCalculatorVersionPreviewDTO;
  success?: boolean;
}

export interface HandlersCalculatorVersionTestEnvelope {
  data?: ServicesCalculatorVersionTestDTO;
  success?: boolean;
}

export interface HandlersCalculatorVersionValidationEnvelope {
  data?: ServicesCalculatorVersionValidationDTO;
  success?: boolean;
}

export interface HandlersCalculatorVersionsEnvelope {
  data?: ServicesCalculatorVersionDTO[];
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

export interface HandlersDeletedEnvelope {
  data?: HandlersDeletedResult;
  /** @example true */
  success?: boolean;
}

export interface HandlersDeletedResult {
  /** @example true */
  deleted?: boolean;
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

export interface HandlersFirebaseDeviceDTOEnvelope {
  data?: ServicesFirebaseDeviceDTO;
  /** @example true */
  success?: boolean;
}

export interface HandlersFirebaseDeviceEnvelope {
  data?: ModelsFirebaseDevice;
  /** @example true */
  success?: boolean;
}

export interface HandlersFirebaseDevicesEnvelope {
  data?: ServicesFirebaseDeviceDTO[];
  /** @example true */
  success?: boolean;
}

export interface HandlersFirebasePushResultEnvelope {
  data?: ServicesFirebasePushResult;
  /** @example true */
  success?: boolean;
}

export interface HandlersFirebaseRemoteConfigEnvelope {
  data?: HandlersFirebaseRemoteConfigResult;
  /** @example true */
  success?: boolean;
}

export interface HandlersFirebaseRemoteConfigResult {
  /** @example "etag-123" */
  etag?: string;
  template?: HandlersJSONMap;
}

export interface HandlersFirebaseRemoteConfigUpdateRequest {
  template?: HandlersJSONMap;
  /** @example true */
  validate_only?: boolean;
}

export interface HandlersFirebaseStatusEnvelope {
  data?: HandlersFirebaseStatusResult;
  /** @example true */
  success?: boolean;
}

export interface HandlersFirebaseStatusResult {
  active_device_count?: number;
  delivery_reporting?: string;
  email_status?: string;
  enabled?: boolean;
  last_successful_health_check_at?: string;
  platforms?: Record<string, number>;
  project_id?: string;
  sms_status?: string;
  stale_device_count?: number;
}

export interface HandlersFirebaseTestRecipientsEnvelope {
  data?: ServicesFirebaseTestRecipient[];
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

export interface HandlersNotificationAudienceEstimateEnvelope {
  data?: ServicesNotificationAudienceEstimate;
  success?: boolean;
}

export interface HandlersNotificationAudienceEstimateInput {
  audience?: ServicesNotificationAudienceDefinition;
}

export interface HandlersNotificationCampaignEnvelope {
  data?: ServicesNotificationCampaignDTO;
  success?: boolean;
}

export interface HandlersNotificationDeliveryAnalyticsEnvelope {
  data?: ServicesNotificationDeliveryAnalytics;
  success?: boolean;
}

export interface HandlersNotificationDeliveryEnvelope {
  data?: ServicesNotificationDeliveryDTO;
  success?: boolean;
}

export interface HandlersNotificationEnvelope {
  data?: ModelsNotification;
  /** @example true */
  success?: boolean;
}

export interface HandlersNotificationOutboxJobEnvelope {
  data?: ServicesNotificationOutboxJobDTO;
  success?: boolean;
}

export interface HandlersNotificationPreferenceAggregatesEnvelope {
  data?: ServicesNotificationPreferenceAggregates;
  /** @example true */
  success?: boolean;
}

export interface HandlersNotificationPreferencesEnvelope {
  data?: ServicesNotificationPreferences;
  /** @example true */
  success?: boolean;
}

export interface HandlersNotificationStatusInput {
  status?: string;
}

export interface HandlersNotificationTemplateEnvelope {
  data?: ServicesNotificationTemplateDTO;
  /** @example true */
  success?: boolean;
}

export interface HandlersNotificationTemplatePreviewEnvelope {
  data?: ServicesNotificationTemplatePreview;
  success?: boolean;
}

export interface HandlersNotificationTemplateVersionsEnvelope {
  data?: ServicesNotificationTemplateVersionDTO[];
  success?: boolean;
}

export interface HandlersOutbreakDocumentContentEnvelope {
  data?: ServicesPublicOutbreakDocumentContent;
  success?: boolean;
}

export interface HandlersOutbreakDocumentEnvelope {
  data?: ServicesPublicOutbreakDocument;
  success?: boolean;
}

export interface HandlersOutbreakDocumentInlineError {
  code?: string;
  message?: string;
}

export interface HandlersOutbreakDocumentInlineUnsupportedEnvelope {
  data?: ServicesPublicOutbreakDocumentContent;
  error?: HandlersOutbreakDocumentInlineError;
  success?: boolean;
}

export interface HandlersOutbreakEnvelope {
  data?: ServicesPublicOutbreak;
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
  items?: ServicesNotificationCampaignDTO[];
  page?: number;
  per_page?: number;
  total_items?: number;
  total_pages?: number;
}

export interface HandlersPaginatedNotificationCampaignsEnvelope {
  data?: HandlersPaginatedNotificationCampaigns;
  success?: boolean;
}

export interface HandlersPaginatedNotificationDeliveriesEnvelope {
  data?: ServicesPageResultServicesNotificationDeliveryDTO;
  success?: boolean;
}

export interface HandlersPaginatedNotificationOutboxJobs {
  items?: ServicesNotificationOutboxJobDTO[];
  page?: number;
  per_page?: number;
  total_items?: number;
  total_pages?: number;
}

export interface HandlersPaginatedNotificationOutboxJobsEnvelope {
  data?: HandlersPaginatedNotificationOutboxJobs;
  success?: boolean;
}

export interface HandlersPaginatedNotificationTemplates {
  items?: ServicesNotificationTemplateDTO[];
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

export interface HandlersPaginatedOutbreakDocumentsEnvelope {
  data?: ServicesPageResultServicesPublicOutbreakDocument;
  success?: boolean;
}

export interface HandlersPaginatedOutbreakResourcesEnvelope {
  data?: ServicesPageResultServicesPublicOutbreakResource;
  success?: boolean;
}

export interface HandlersPaginatedOutbreakUpdatesEnvelope {
  data?: ServicesPageResultServicesPublicOutbreakUpdate;
  success?: boolean;
}

export interface HandlersPaginatedOutbreaksEnvelope {
  data?: ServicesPageResultServicesPublicOutbreak;
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

export interface HandlersPaginatedSituationReportsEnvelope {
  data?: ServicesPageResultServicesPublicSituationReport;
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

export interface HandlersRateLimitErrorResponse {
  /** @example "rate limit exceeded" */
  error?: string;
  meta?: HttpxRateLimitMetadata;
  /** @example false */
  success?: boolean;
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

export interface HandlersSituationReportEnvelope {
  data?: ServicesPublicSituationReport;
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

export interface HttpxRateLimitMetadata {
  limit?: number;
  remaining?: number;
  reset_after_seconds?: number;
  retry_after_seconds?: number;
}

export interface HttpxResponse {
  data?: any;
  error?: string;
  meta?: any;
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

export interface ModelsAuditLog {
  action?: string;
  actor_id?: string;
  created_at?: string;
  entity_id?: string;
  entity_type?: string;
  id?: string;
  ip_address?: string;
  metadata_json?: string;
  updated_at?: string;
}

export interface ModelsCalculator {
  added_by_user_id?: string;
  app_file_json?: object;
  background_color?: string;
  color?: string;
  created_at?: string;
  current_version_id?: string;
  description?: string;
  featured?: boolean;
  icon?: string;
  id?: string;
  name?: string;
  runtime_type?: string;
  status?: string;
  type?: string;
  updated_at?: string;
  usage_count?: number;
  version?: string;
}

export interface ModelsCalculatorUsageLog {
  calculator_id?: string;
  calculator_type?: string;
  calculator_version_id?: string;
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

export interface ModelsFirebaseDevice {
  app_version?: string;
  created_at?: string;
  id?: string;
  installation_id?: string;
  last_seen_at?: string;
  locale?: string;
  notifications_enabled?: boolean;
  platform?: string;
  updated_at?: string;
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
  healthcare_level?: string;
  id?: string;
  intended_population?: string;
  language?: string;
  program_area?: string;
  source_org?: string;
  title?: string;
  updated_at?: string;
  versions?: ModelsGuidelineVersion[];
}

export interface ModelsGuidelineEditorComment {
  author_id?: string;
  block_id?: string;
  body?: string;
  created_at?: string;
  id?: string;
  resolved?: boolean;
  resolved_at?: string;
  resolved_by?: string;
  revision_id?: string;
  section_id?: string;
  updated_at?: string;
  version_id?: string;
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

export interface ModelsGuidelineReviewAssignment {
  assigned_by?: string;
  completed_at?: string;
  created_at?: string;
  due_at?: string;
  id?: string;
  reviewer_id?: string;
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
  action?: ModelsNotificationAction;
  action_url?: string;
  campaign_id?: string;
  created_at?: string;
  created_by?: string;
  deduplication_key?: string;
  delivery_id?: string;
  expires_at?: string;
  id?: string;
  is_read?: boolean;
  message?: string;
  priority?: string;
  publish_at?: string;
  published_by?: string;
  source_id?: string;
  source_type?: string;
  title?: string;
  type?: string;
  updated_at?: string;
  user_id?: string;
}

export interface ModelsNotificationAction {
  parameters?: Record<string, string>;
  resource_id?: string;
  route?: string;
  type?: ModelsNotificationActionTypeEnum;
}

export type ModelsNotificationActionTypeEnum =
  | "none"
  | "guideline"
  | "outbreak"
  | "outbreak_document"
  | "situation_report"
  | "drug"
  | "calculator"
  | "facility"
  | "support_ticket"
  | "internal_route"
  | "approved_external_url";

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

export interface ServicesAssignGuidelineReviewerInput {
  due_at?: string;
  reviewer_id: string;
}

export interface ServicesCalculatorDefinitionDTO {
  calculator_id?: string;
  definition?: ClinicaltoolsDefinition;
  definition_checksum?: string;
  runtime_type?: string;
  semantic_version?: string;
  version_id?: string;
}

export interface ServicesCalculatorFixtureReviewDTO {
  description?: string;
  expected?: Record<string, any>;
  input?: Record<string, any>;
  key?: string;
  last_passed?: boolean;
  last_result?: Record<string, any>;
  last_run_at?: string;
  numeric_tolerance?: number;
}

export interface ServicesCalculatorReviewQueueItem {
  author_id?: string;
  calculator_id?: string;
  clinical_owner?: string;
  clinical_reviewer?: string;
  created_at?: string;
  definition_checksum?: string;
  fixture_count?: number;
  fixture_passed_count?: number;
  last_audit_action?: string;
  last_audit_at?: string;
  lock_version?: number;
  review_evidence_status?: string;
  reviewer_id?: string;
  semantic_version?: string;
  tests_passed?: boolean;
  tool_name?: string;
  tool_status?: string;
  tool_type?: string;
  updated_at?: string;
  validation_passed?: boolean;
  version_id?: string;
  version_status?: string;
}

export interface ServicesCalculatorVersionAuditDTO {
  action?: string;
  actor_id?: string;
  calculator_id?: string;
  calculator_version_id?: string;
  created_at?: string;
  from_status?: string;
  id?: string;
  metadata?: Record<string, any>;
  to_status?: string;
}

export interface ServicesCalculatorVersionDTO {
  approved_at?: string;
  approved_by?: string;
  calculator_id?: string;
  change_summary?: string;
  created_at?: string;
  created_by?: string;
  definition?: ClinicaltoolsDefinition;
  definition_checksum?: string;
  effective_at?: string;
  id?: string;
  lock_version?: number;
  published_at?: string;
  published_by?: string;
  review_at?: string;
  reviewed_at?: string;
  reviewed_by?: string;
  schema_version?: string;
  semantic_version?: string;
  status?: string;
  tests_passed?: boolean;
  updated_at?: string;
  validation_passed?: boolean;
}

export interface ServicesCalculatorVersionPreviewDTO {
  audit?: ServicesCalculatorVersionAuditDTO[];
  fixtures?: ServicesCalculatorFixtureReviewDTO[];
  review_evidence_status?: string;
  runtime_type?: string;
  tool_name?: string;
  tool_status?: string;
  tool_type?: string;
  version?: ServicesCalculatorVersionDTO;
}

export interface ServicesCalculatorVersionReviewCommentInput {
  /** @maxLength 4000 */
  comment: string;
}

export interface ServicesCalculatorVersionTestDTO {
  lock_version?: number;
  report?: ClinicaltoolsTestReport;
}

export interface ServicesCalculatorVersionValidationDTO {
  errors?: ClinicaltoolsValidationError[];
  lock_version?: number;
  valid?: boolean;
}

export interface ServicesChildContentInput {
  asset_url?: string;
  description?: string;
  issuing_organization?: string;
  lock_version?: number;
  resource_type?: string;
  sort_order?: number;
  summary?: string;
  title?: string;
  url?: string;
}

export interface ServicesCitation {
  block_id?: string;
  chunk_id?: string;
  guideline_id?: string;
  page_end?: number;
  page_start?: number;
  section_id?: string;
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

export interface ServicesCreateCalculatorVersionInput {
  change_summary?: string;
  definition?: object;
}

export interface ServicesCreateGuidelineBlockInput {
  content: object;
  section_id?: string;
  sort_order?: number;
  type: ModelsGuidelineBlockType;
}

export interface ServicesCreateGuidelineEditorCommentInput {
  block_id?: string;
  body: string;
  revision_id?: string;
  section_id?: string;
}

export interface ServicesCreateGuidelineInput {
  country?: string;
  description?: string;
  healthcare_level?: string;
  intended_population?: string;
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

export interface ServicesDuplicateCalculatorVersionInput {
  change_summary?: string;
  semantic_version: string;
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

export interface ServicesFirebaseDeviceDTO {
  app_version?: string;
  id?: string;
  installation_id?: string;
  last_seen_at?: string;
  locale?: string;
  notifications_enabled?: boolean;
  platform?: string;
}

export interface ServicesFirebaseDeviceInput {
  app_version?: string;
  installation_id?: string;
  locale?: string;
  notifications_enabled?: boolean;
  platform?: string;
  registration_token?: string;
}

export interface ServicesFirebaseDeviceUpdateInput {
  notifications_enabled?: boolean;
}

export interface ServicesFirebasePushDeviceResult {
  app_version?: string;
  device_id?: string;
  error_category?: string;
  platform?: string;
  provider_message_id?: string;
  state?: string;
}

export interface ServicesFirebasePushInput {
  action?: ServicesNotificationAction;
  action_url?: string;
  body?: string;
  current_user?: boolean;
  data?: Record<string, string>;
  dry_run?: boolean;
  title?: string;
  user_id?: string;
}

export interface ServicesFirebasePushResult {
  accepted?: number;
  attempted?: number;
  devices?: ServicesFirebasePushDeviceResult[];
  failed?: number;
  validated?: number;
}

export interface ServicesFirebaseTestRecipient {
  device_count?: number;
  email?: string;
  id?: string;
  name?: string;
  platforms?: string[];
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

export interface ServicesGuidelineNotificationCampaignInput {
  audience?: ServicesNotificationAudienceDefinition;
  idempotency_key?: string;
  priority?: string;
  requested_channels?: string[];
  scheduled_at?: string;
  timezone?: string;
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

export interface ServicesGuidelineReviewAssignmentStatusInput {
  status: string;
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

export interface ServicesNotificationAction {
  parameters?: Record<string, string>;
  resource_id?: string;
  route?: string;
  type?: ServicesNotificationActionTypeEnum;
}

export type ServicesNotificationActionTypeEnum =
  | "none"
  | "guideline"
  | "outbreak"
  | "outbreak_document"
  | "situation_report"
  | "drug"
  | "calculator"
  | "facility"
  | "support_ticket"
  | "internal_route"
  | "approved_external_url";

export interface ServicesNotificationAudienceDefinition {
  all_eligible?: boolean;
  application_versions?: string[];
  countries?: string[];
  district_ids?: string[];
  facility_ids?: string[];
  facility_level_ids?: string[];
  languages?: string[];
  platforms?: string[];
  preference_categories?: string[];
  professional_categories?: string[];
  region_ids?: string[];
  role_ids?: string[];
  user_ids?: string[];
}

export interface ServicesNotificationAudienceEstimate {
  active_devices?: number;
  eligible_users?: number;
}

export interface ServicesNotificationCampaignDTO {
  action_snapshot?: ServicesNotificationAction;
  approved_at?: string;
  approved_by?: string;
  audience?: ServicesNotificationAudienceDefinition;
  cancelled_at?: string;
  collapse_key?: string;
  completed_at?: string;
  created_at?: string;
  created_by?: string;
  dispatch_snapshot?: Record<string, any>;
  expires_at?: string;
  failure_reason?: string;
  id?: string;
  idempotency_key?: string;
  lock_version?: number;
  name?: string;
  priority?: string;
  rendered_body?: string;
  rendered_title?: string;
  requested_channels?: string[];
  resolved_recipient_count?: number;
  reviewed_at?: string;
  reviewed_by?: string;
  scheduled_at?: string;
  started_at?: string;
  status?: string;
  template_version_id?: string;
  timezone?: string;
  ttl_seconds?: number;
  type?: string;
  updated_at?: string;
  variables?: Record<string, any>;
}

export interface ServicesNotificationCampaignInput {
  audience?: ServicesNotificationAudienceDefinition;
  collapse_key?: string;
  expires_at?: string;
  idempotency_key?: string;
  lock_version?: number;
  name?: string;
  priority?: string;
  requested_channels?: string[];
  scheduled_at?: string;
  template_version_id?: string;
  timezone?: string;
  ttl_seconds?: number;
  type?: string;
  variables?: Record<string, any>;
}

export interface ServicesNotificationCampaignTransitionInput {
  lock_version?: number;
  reason?: string;
  scheduled_at?: string;
  timezone?: string;
}

export interface ServicesNotificationDeliveryAnalytics {
  bigquery_export_note?: string;
  delivery_reporting?: Record<string, string>;
  from?: string;
  items?: ServicesNotificationDeliveryDailyMetric[];
  to?: string;
}

export interface ServicesNotificationDeliveryDTO {
  accepted_at?: string;
  attempt_count?: number;
  attempted_at?: string;
  campaign_id?: string;
  channel?: string;
  clicked_at?: string;
  created_at?: string;
  delivered_at?: string;
  device_id?: string;
  error_category?: string;
  expired_at?: string;
  failed_at?: string;
  id?: string;
  notification_id?: string;
  opened_at?: string;
  outbox_job_id?: string;
  provider_message_id?: string;
  state?: string;
  updated_at?: string;
  user_id?: string;
}

export interface ServicesNotificationDeliveryDailyMetric {
  accepted?: number;
  attempted?: number;
  channel?: string;
  clicked?: number;
  date?: string;
  delivered?: number;
  expired?: number;
  opened?: number;
  queued?: number;
  rejected?: number;
}

export interface ServicesNotificationDeliveryEventInput {
  event_id?: string;
  occurred_at?: string;
}

export interface ServicesNotificationInput {
  action?: ServicesNotificationAction;
  action_url?: string;
  deduplication_key?: string;
  expires_at?: string;
  message?: string;
  priority?: string;
  publish_at?: string;
  source_id?: string;
  source_type?: string;
  title?: string;
  type?: string;
  user_id?: string;
}

export interface ServicesNotificationOutboxJobDTO {
  accepted_at?: string;
  attempt_count?: number;
  campaign_id?: string;
  channel?: string;
  completed_at?: string;
  created_at?: string;
  id?: string;
  last_error_code?: string;
  last_error_message?: string;
  max_attempts?: number;
  next_attempt_at?: string;
  provider_message_id?: string;
  status?: string;
}

export interface ServicesNotificationOutboxRequeueInput {
  confirm?: boolean;
  reason?: string;
}

export interface ServicesNotificationPreferenceAggregates {
  active_devices?: number;
  category_opt_in_counts?: Record<string, number>;
  devices_by_platform?: Record<string, number>;
  eligible_users?: number;
  in_app_enabled_users?: number;
  push_enabled_devices?: number;
  push_enabled_users?: number;
  quiet_hours_users?: number;
}

export interface ServicesNotificationPreferences {
  clinical_content_updates?: boolean;
  emergency_alerts?: boolean;
  in_app_enabled?: boolean;
  outbreak_alerts?: boolean;
  preferred_language?: string;
  product_announcements?: boolean;
  push_enabled?: boolean;
  quiet_hours_enabled?: boolean;
  quiet_hours_end?: string;
  quiet_hours_start?: string;
  quiet_hours_timezone?: string;
  reminders?: boolean;
  system_notices?: boolean;
  updated_at?: string;
}

export interface ServicesNotificationPreferencesInput {
  clinical_content_updates?: boolean;
  emergency_alerts?: boolean;
  in_app_enabled?: boolean;
  outbreak_alerts?: boolean;
  preferred_language?: string;
  product_announcements?: boolean;
  push_enabled?: boolean;
  quiet_hours_enabled?: boolean;
  quiet_hours_end?: string;
  quiet_hours_start?: string;
  quiet_hours_timezone?: string;
  reminders?: boolean;
  system_notices?: boolean;
}

export interface ServicesNotificationTemplateCloneInput {
  name?: string;
  template_key?: string;
}

export interface ServicesNotificationTemplateDTO {
  created_at?: string;
  created_by?: string;
  current_version?: number;
  id?: string;
  locale?: string;
  name?: string;
  reviewed_by?: string;
  status?: string;
  template_key?: string;
  updated_at?: string;
  version?: ServicesNotificationTemplateVersionDTO;
}

export interface ServicesNotificationTemplateInput {
  action_template?: ServicesNotificationAction;
  body_template?: string;
  category?: string;
  channel?: string;
  locale?: string;
  name?: string;
  template_key?: string;
  title_template?: string;
  variable_schema?: Record<string, ServicesTemplateVariableRule>;
}

export interface ServicesNotificationTemplatePreview {
  action?: ServicesNotificationAction;
  body?: string;
  title?: string;
}

export interface ServicesNotificationTemplatePreviewInput {
  variables?: Record<string, any>;
}

export interface ServicesNotificationTemplateVersionDTO {
  action_template?: ServicesNotificationAction;
  body_template?: string;
  category?: string;
  channel?: string;
  created_at?: string;
  created_by?: string;
  id?: string;
  locale?: string;
  published_at?: string;
  reviewed_by?: string;
  status?: string;
  template_id?: string;
  title_template?: string;
  variable_schema?: Record<string, ServicesTemplateVariableRule>;
  version?: number;
}

export interface ServicesOutbreakAdminDTO {
  approved_at?: string;
  approved_by?: string;
  author_id?: string;
  created_at?: string;
  data_as_of?: string;
  disease_type?: string;
  district_id?: string;
  effective_at?: string;
  geographic_area?: string;
  id?: string;
  last_update?: string;
  last_verified_at?: string;
  lock_version?: number;
  metrics?: ServicesOutbreakMetric[];
  published_at?: string;
  region_id?: string;
  reviewed_at?: string;
  reviewed_by?: string;
  source_organization?: string;
  source_reference?: string;
  source_url?: string;
  start_date?: string;
  status?: string;
  summary?: string;
  supersedes_id?: string;
  title?: string;
  updated_at?: string;
  visual_tone?: string;
  withdrawal_reason?: string;
  withdrawn_at?: string;
}

export interface ServicesOutbreakAuditDTO {
  action?: string;
  actor_id?: string;
  created_at?: string;
  entity_id?: string;
  entity_type?: string;
  id?: string;
  metadata?: Record<string, any>;
}

export interface ServicesOutbreakDocumentAdminDTO {
  checksum_sha256?: string;
  approved_at?: string;
  approved_by?: string;
  asset_url?: string;
  audience?: string;
  author_id?: string;
  content_format?: string;
  created_at?: string;
  derived_content_checksum?: string;
  description?: string;
  document_kind?: string;
  document_number?: string;
  effective_date?: string;
  expires_at?: string;
  extracted_at?: string;
  extraction_error?: string;
  extraction_source_checksum?: string;
  extraction_status?: string;
  file_size?: number;
  id?: string;
  indexed_at?: string;
  issuing_authority?: string;
  language?: string;
  lock_version?: number;
  mime_type?: string;
  original_filename?: string;
  outbreak_id?: string;
  page_count?: number;
  published_at?: string;
  resource_type?: string;
  review_date?: string;
  reviewed_at?: string;
  reviewed_by?: string;
  search_index_status?: string;
  search_schema_version?: number;
  sort_order?: number;
  status?: string;
  supersedes_id?: string;
  supports_preview?: boolean;
  title?: string;
  updated_at?: string;
  version?: string;
  withdrawal_reason?: string;
  withdrawn_at?: string;
}

export interface ServicesOutbreakDocumentInput {
  asset_url?: string;
  audience?: string;
  description?: string;
  document_kind?: string;
  document_number?: string;
  effective_date?: string;
  expires_at?: string;
  issuing_authority?: string;
  language?: string;
  lock_version?: number;
  resource_type?: string;
  review_date?: string;
  sort_order?: number;
  title?: string;
  version?: string;
}

export interface ServicesOutbreakDocumentSearchPreview {
  document_id?: string;
  indexed_at?: string;
  matching_heading?: string;
  matching_pdf_page?: number;
  matching_section_id?: string;
  query?: string;
  search_index_status?: string;
  searchable?: boolean;
  snippet?: string;
}

export interface ServicesOutbreakInput {
  data_as_of?: string;
  disease_type?: string;
  district_id?: string;
  effective_at?: string;
  geographic_area?: string;
  last_update?: string;
  last_verified_at?: string;
  lock_version?: number;
  metrics?: ServicesOutbreakMetric[];
  region_id?: string;
  source_organization?: string;
  source_reference?: string;
  source_url?: string;
  start_date?: string;
  summary?: string;
  title?: string;
  visual_tone?: string;
}

export interface ServicesOutbreakMetric {
  as_of?: string;
  key?: string;
  label?: string;
  numeric_value?: number;
  sort_order?: number;
  source_reference?: string;
  unit?: string;
  value?: string;
}

export interface ServicesOutbreakNotificationCampaignInput {
  audience?: ServicesNotificationAudienceDefinition;
  confirmed_urgent?: boolean;
  idempotency_key?: string;
  kind?: ServicesOutbreakNotificationCampaignInputKindEnum;
  priority?: ServicesOutbreakNotificationCampaignInputPriorityEnum;
  requested_channels?: string[];
  scheduled_at?: string;
  timezone?: string;
}

export type ServicesOutbreakNotificationCampaignInputKindEnum =
  | "alert"
  | "update"
  | "status_change"
  | "closure"
  | "publication";

export type ServicesOutbreakNotificationCampaignInputPriorityEnum =
  | "low"
  | "normal"
  | "high"
  | "urgent";

export interface ServicesOutbreakResourceAdminDTO {
  approved_at?: string;
  approved_by?: string;
  asset_url?: string;
  author_id?: string;
  created_at?: string;
  description?: string;
  id?: string;
  issuing_organization?: string;
  lock_version?: number;
  outbreak_id?: string;
  published_at?: string;
  resource_type?: string;
  reviewed_at?: string;
  reviewed_by?: string;
  sort_order?: number;
  status?: string;
  supersedes_id?: string;
  title?: string;
  updated_at?: string;
  url?: string;
  withdrawal_reason?: string;
  withdrawn_at?: string;
}

export interface ServicesOutbreakReviewCommentInput {
  /** @maxLength 4000 */
  comment: string;
}

export interface ServicesOutbreakUpdateAdminDTO {
  approved_at?: string;
  approved_by?: string;
  author_id?: string;
  created_at?: string;
  id?: string;
  lock_version?: number;
  outbreak_id?: string;
  published_at?: string;
  reviewed_at?: string;
  reviewed_by?: string;
  status?: string;
  summary?: string;
  supersedes_id?: string;
  title?: string;
  updated_at?: string;
  withdrawal_reason?: string;
  withdrawn_at?: string;
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

export interface ServicesPageResultServicesCalculatorReviewQueueItem {
  items?: ServicesCalculatorReviewQueueItem[];
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

export interface ServicesPageResultServicesNotificationDeliveryDTO {
  items?: ServicesNotificationDeliveryDTO[];
  page?: number;
  per_page?: number;
  total_items?: number;
  total_pages?: number;
}

export interface ServicesPageResultServicesOutbreakAdminDTO {
  items?: ServicesOutbreakAdminDTO[];
  page?: number;
  per_page?: number;
  total_items?: number;
  total_pages?: number;
}

export interface ServicesPageResultServicesOutbreakAuditDTO {
  items?: ServicesOutbreakAuditDTO[];
  page?: number;
  per_page?: number;
  total_items?: number;
  total_pages?: number;
}

export interface ServicesPageResultServicesOutbreakDocumentAdminDTO {
  items?: ServicesOutbreakDocumentAdminDTO[];
  page?: number;
  per_page?: number;
  total_items?: number;
  total_pages?: number;
}

export interface ServicesPageResultServicesOutbreakResourceAdminDTO {
  items?: ServicesOutbreakResourceAdminDTO[];
  page?: number;
  per_page?: number;
  total_items?: number;
  total_pages?: number;
}

export interface ServicesPageResultServicesOutbreakUpdateAdminDTO {
  items?: ServicesOutbreakUpdateAdminDTO[];
  page?: number;
  per_page?: number;
  total_items?: number;
  total_pages?: number;
}

export interface ServicesPageResultServicesPublicOutbreak {
  items?: ServicesPublicOutbreak[];
  page?: number;
  per_page?: number;
  total_items?: number;
  total_pages?: number;
}

export interface ServicesPageResultServicesPublicOutbreakDocument {
  items?: ServicesPublicOutbreakDocument[];
  page?: number;
  per_page?: number;
  total_items?: number;
  total_pages?: number;
}

export interface ServicesPageResultServicesPublicOutbreakResource {
  items?: ServicesPublicOutbreakResource[];
  page?: number;
  per_page?: number;
  total_items?: number;
  total_pages?: number;
}

export interface ServicesPageResultServicesPublicOutbreakUpdate {
  items?: ServicesPublicOutbreakUpdate[];
  page?: number;
  per_page?: number;
  total_items?: number;
  total_pages?: number;
}

export interface ServicesPageResultServicesPublicSituationReport {
  items?: ServicesPublicSituationReport[];
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

export interface ServicesPageResultServicesSituationReportAdminDTO {
  items?: ServicesSituationReportAdminDTO[];
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
  healthcare_level?: string;
  id?: string;
  intended_population?: string;
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
  recommended_mode?: ServicesPublicGuidelineManifestRecommendedModeEnum;
  schema_version?: number;
  section_count?: number;
  table_count?: number;
  version?: string;
  version_id?: string;
}

export type ServicesPublicGuidelineManifestRecommendedModeEnum =
  | "structured"
  | "partial"
  | "original_document";

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

export interface ServicesPublicOutbreak {
  data_as_of?: string;
  disease_type?: string;
  district_id?: string;
  effective_at?: string;
  geographic_area?: string;
  id?: string;
  last_update?: string;
  last_verified_at?: string;
  metrics?: ServicesOutbreakMetric[];
  published_at?: string;
  region_id?: string;
  source_organization?: string;
  source_reference?: string;
  source_url?: string;
  start_date?: string;
  status?: string;
  summary?: string;
  title?: string;
  visual_tone?: string;
}

export interface ServicesPublicOutbreakDocument {
  checksum_sha256?: string;
  audience?: string;
  content_format?: string;
  content_url?: string;
  description?: string;
  document_kind?: string;
  document_number?: string;
  download_url?: string;
  effective_date?: string;
  expires_at?: string;
  file_size?: number;
  id?: string;
  issuing_authority?: string;
  language?: string;
  matching_heading?: string;
  matching_pdf_page?: number;
  matching_section_id?: string;
  mime_type?: string;
  original_filename?: string;
  outbreak_area?: string;
  outbreak_disease?: string;
  outbreak_id?: string;
  outbreak_title?: string;
  page_count?: number;
  published_at?: string;
  reader_url?: string;
  review_date?: string;
  search_relevance_score?: number;
  search_snippet?: string;
  supports_inline?: boolean;
  supports_offline_download?: boolean;
  title?: string;
  version?: string;
}

export interface ServicesPublicOutbreakDocumentContent {
  checksum_sha256?: string;
  can_read_inline?: boolean;
  content?: string;
  document_id?: string;
  download_url?: string;
  effective_date?: string;
  expires_at?: string;
  format?: string;
  mime_type?: string;
  original_available?: boolean;
  outbreak_id?: string;
  published_at?: string;
  review_date?: string;
  sections?: ServicesPublicOutbreakDocumentSection[];
  title?: string;
}

export interface ServicesPublicOutbreakDocumentSection {
  heading?: string;
  id?: string;
  level?: number;
  page?: number;
  text?: string;
}

export interface ServicesPublicOutbreakResource {
  asset_url?: string;
  description?: string;
  download_capability?: boolean;
  id?: string;
  issuing_organization?: string;
  outbreak_id?: string;
  outbreak_title?: string;
  publication_date?: string;
  published_at?: string;
  reader_capability?: string;
  resource_type?: string;
  sort_order?: number;
  target_type?: string;
  target_url?: string;
  title?: string;
  url?: string;
}

export interface ServicesPublicOutbreakUpdate {
  id?: string;
  outbreak_id?: string;
  published_at?: string;
  summary?: string;
  title?: string;
}

export interface ServicesPublicSituationReport {
  data_as_of?: string;
  district_id?: string;
  effective_at?: string;
  geographic_area?: string;
  id?: string;
  key_highlights?: string[];
  last_verified_at?: string;
  metrics?: ServicesOutbreakMetric[];
  outbreak_id?: string;
  publication_date?: string;
  published_at?: string;
  region_id?: string;
  report_asset_id?: string;
  report_asset_url?: string;
  source_organization?: string;
  source_reference?: string;
  source_url?: string;
  summary?: string;
  title?: string;
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

export interface ServicesResolveGuidelineEditorCommentInput {
  resolved?: boolean;
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
  block_id?: string;
  content_type?: string;
  guideline_id?: string;
  id?: string;
  is_stale?: boolean;
  last_verified_at?: string;
  page_end?: number;
  page_start?: number;
  result_type?: string;
  section_id?: string;
  snippet?: string;
  source_name?: string;
  source_version?: string;
  status?: string;
  title?: string;
}

export interface ServicesSituationReportAdminDTO {
  approved_at?: string;
  approved_by?: string;
  author_id?: string;
  correction_reason?: string;
  created_at?: string;
  data_as_of?: string;
  district_id?: string;
  effective_at?: string;
  geographic_area?: string;
  id?: string;
  key_highlights?: string[];
  last_verified_at?: string;
  lock_version?: number;
  metrics?: ServicesOutbreakMetric[];
  outbreak_id?: string;
  publication_date?: string;
  published_at?: string;
  region_id?: string;
  report_asset_id?: string;
  report_asset_url?: string;
  reviewed_at?: string;
  reviewed_by?: string;
  source_organization?: string;
  source_reference?: string;
  source_url?: string;
  standalone_allowed?: boolean;
  status?: string;
  summary?: string;
  supersedes_id?: string;
  title?: string;
  updated_at?: string;
  withdrawal_reason?: string;
  withdrawn_at?: string;
}

export interface ServicesSituationReportAssetDTO {
  checksum_sha256?: string;
  content_type?: string;
  created_at?: string;
  file_name?: string;
  id?: string;
  situation_report_id?: string;
  size_bytes?: number;
}

export interface ServicesSituationReportInput {
  data_as_of?: string;
  district_id?: string;
  effective_at?: string;
  geographic_area?: string;
  key_highlights?: string[];
  last_verified_at?: string;
  lock_version?: number;
  metrics?: ServicesOutbreakMetric[];
  outbreak_id?: string;
  publication_date?: string;
  region_id?: string;
  source_organization?: string;
  source_reference?: string;
  source_url?: string;
  standalone_allowed?: boolean;
  summary?: string;
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

export interface ServicesTemplateVariableRule {
  required?: boolean;
  sample_value?: any;
  type?: string;
}

export interface ServicesTransitionInput {
  lock_version?: number;
  operational_status?: string;
  reason?: string;
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

export interface ServicesUpdateCalculatorVersionInput {
  change_summary?: string;
  definition?: object;
  lock_version?: number;
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
  healthcare_level?: string;
  intended_population?: string;
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
