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

export interface HandlersErrorResponse {
  /** @example "invalid request" */
  error?: string;
  /** @example false */
  success?: boolean;
}

export interface HandlersGuidelineDocumentEnvelope {
  data?: ModelsGuidelineDocument;
  /** @example true */
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

export interface HandlersMarkdownUpdateEnvelope {
  data?: HandlersMarkdownUpdateResult;
  /** @example true */
  success?: boolean;
}

export interface HandlersMarkdownUpdateResult {
  /** @example 1024 */
  size?: number;
  /** @example true */
  updated?: boolean;
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

export interface HandlersPasswordResetConfirmRequest {
  password?: string;
  password_confirm?: string;
  token?: string;
}

export interface HandlersPasswordResetRequest {
  /** @example "user@example.com" */
  email?: string;
}

export interface HandlersProtocolRunEnvelope {
  data?: ServicesRunProtocolResult;
  /** @example true */
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

export interface HandlersRefreshRequest {
  /** @example "Gm8m3Wq2oJ7l6p4XnYx9QbT2f1WvL0H1v2z3k4m5n6o" */
  refresh_token?: string;
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

export interface HandlersSyncPackageEnvelope {
  data?: ModelsSyncPackage;
  /** @example true */
  success?: boolean;
}

export interface HandlersTherapeuticCategoryEnvelope {
  data?: ModelsTherapeuticCategory;
  /** @example true */
  success?: boolean;
}

export interface HandlersUpdateMarkdownInput {
  content: string;
}

export interface HandlersUserEnvelope {
  data?: ModelsUser;
  /** @example true */
  success?: boolean;
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

export interface ModelsDrug {
  adult_dose?: string;
  antimicrobial_status?: boolean;
  brand_names?: string;
  categories_json?: string[];
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

export interface ModelsGuidelineChunk {
  content?: string;
  created_at?: string;
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

export interface ModelsGuidelineVersion {
  approved_at?: string;
  approved_by?: string;
  checksum?: string;
  created_at?: string;
  document_id?: string;
  html_file_key?: string;
  id?: string;
  markdown_file_key?: string;
  original_file_key?: string;
  publication_date?: string;
  review_date?: string;
  sections?: ModelsGuidelineSection[];
  status?: string;
  updated_at?: string;
  version?: string;
}

export interface ModelsIngestionJob {
  attempt_count?: number;
  completed_at?: string;
  created_at?: string;
  error?: string;
  id?: string;
  job_type?: string;
  payload_json?: string;
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

export interface ModelsPermission {
  code?: string;
  created_at?: string;
  id?: string;
  name?: string;
  updated_at?: string;
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

export interface ServicesAccountActionResult {
  accepted?: boolean;
  delivery_required?: boolean;
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

export interface ServicesCreateGuidelineInput {
  country?: string;
  description?: string;
  language?: string;
  program_area?: string;
  source_org?: string;
  title?: string;
}

export interface ServicesCreateLanguageInput {
  code?: string;
  enabled_for_users?: boolean;
  is_active?: boolean;
  is_default?: boolean;
  name?: string;
  native_name?: string;
  progress?: number;
  status?: string;
  translations_json?: object;
  translations_url?: string;
  version?: number;
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

export interface ServicesFinishCalculatorUsageInput {
  session_end?: string;
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

export interface ServicesProtocolStep {
  citation?: Record<string, string>;
  id?: string;
  message?: string;
  next?: Record<string, any>;
  options?: string[];
  question?: string;
  type?: string;
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

export interface ServicesStartCalculatorUsageInput {
  calculator_type?: string;
  session_start?: string;
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
