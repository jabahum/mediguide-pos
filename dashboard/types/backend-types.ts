/**
 * Legacy collection response contracts used by the Go backend compatibility API.
 *
 * These types are intentionally framework-neutral. Replace each collection
 * contract with an OpenAPI-generated domain DTO as dedicated endpoints mature.
 */

export const Collections = {
	Authorigins: "_authOrigins",
	Externalauths: "_externalAuths",
	Mfas: "_mfas",
	Otps: "_otps",
	Superusers: "_superusers",
	AbbreviationUsageLogs: "abbreviation_usage_logs",
	Abbreviations: "abbreviations",
	AiUsageLogs: "ai_usage_logs",
	Authorities: "authorities",
	CalculatorUsageLogs: "calculator_usage_logs",
	Calculators: "calculators",
	ConsultantUsageLogs: "consultant_usage_logs",
	Consultants: "consultants",
	Conversations: "conversations",
	Counties: "counties",
	Districts: "districts",
	Documentation: "documentation",
	DrugCategories: "drug_categories",
	DrugClasses: "drug_classes",
	DrugTags: "drug_tags",
	DrugUsageLogs: "drug_usage_logs",
	Drugs: "drugs",
	EmergencyProtocols: "emergency_protocols",
	FacilityLevels: "facility_levels",
	FacilityUsageLogs: "facility_usage_logs",
	FaqTags: "faq_tags",
	Faqs: "faqs",
	GenericPages: "generic_pages",
	GuidelineCategories: "guideline_categories",
	GuidelineIndex: "guideline_index",
	GuidelineTags: "guideline_tags",
	GuidelineUsageLogs: "guideline_usage_logs",
	HealthFacilities: "health_facilities",
	HealthSubDistricts: "health_sub_districts",
	HealthSubRegions: "health_sub_regions",
	Languages: "languages",
	MedicalGuidelines: "medical_guidelines",
	Messages: "messages",
	MinistryDirectory: "ministry_directory",
	NotificationCampaigns: "notification_campaigns",
	NotificationTemplates: "notification_templates",
	Notifications: "notifications",
	OwnershipTypes: "ownership_types",
	Parishes: "parishes",
	ReadingProgress: "reading_progress",
	Regions: "regions",
	Roles: "roles",
	Settings: "settings",
	Subcounties: "subcounties",
	SupportTicketReplies: "support_ticket_replies",
	SupportTickets: "support_tickets",
	TherapeuticCategories: "therapeutic_categories",
	Users: "users",
} as const
export type Collections = typeof Collections[keyof typeof Collections]

// Alias types for improved usability
export type IsoDateString = string
export type IsoAutoDateString = string & { readonly autodate: unique symbol }
export type RecordIdString = string
export type FileNameString = string & { readonly filename: unique symbol }
export type HTMLString = string

type ExpandType<T> = unknown extends T
	? T extends unknown
		? { expand?: unknown }
		: { expand: T }
	: { expand: T }

// System fields
export type BaseSystemFields<T = unknown> = {
	id: RecordIdString
	collectionId: string
	collectionName: Collections
} & ExpandType<T>

export type AuthSystemFields<T = unknown> = {
	email: string
	emailVisibility: boolean
	username: string
	verified: boolean
} & BaseSystemFields<T>

// Record types for each collection

export type AuthoriginsRecord = {
	collectionRef: string
	created: IsoAutoDateString
	fingerprint: string
	id: string
	recordRef: string
	updated: IsoAutoDateString
}

export type ExternalauthsRecord = {
	collectionRef: string
	created: IsoAutoDateString
	id: string
	provider: string
	providerId: string
	recordRef: string
	updated: IsoAutoDateString
}

export type MfasRecord = {
	collectionRef: string
	created: IsoAutoDateString
	id: string
	method: string
	recordRef: string
	updated: IsoAutoDateString
}

export type OtpsRecord = {
	collectionRef: string
	created: IsoAutoDateString
	id: string
	password: string
	recordRef: string
	sentTo?: string
	updated: IsoAutoDateString
}

export type SuperusersRecord = {
	created: IsoAutoDateString
	email: string
	emailVisibility?: boolean
	id: string
	password: string
	tokenKey: string
	updated: IsoAutoDateString
	verified?: boolean
}

export type AbbreviationUsageLogsRecord = {
	abbreviation_id: RecordIdString
	created: IsoAutoDateString
	id: string
	updated: IsoAutoDateString
	user_id: RecordIdString
}

export type AbbreviationsRecord = {
	abbreviation: string
	category?: RecordIdString
	common_usage?: boolean
	created: IsoAutoDateString
	description?: string
	id: string
	meaning: string
	tags?: RecordIdString[]
	updated: IsoAutoDateString
	usageCount?: number
}

export type AiUsageLogsRecord = {
	created: IsoAutoDateString
	id: string
	updated: IsoAutoDateString
	user_id: RecordIdString
}

export type AuthoritiesRecord = {
	code?: string
	created: IsoAutoDateString
	id: string
	name: string
	ownership_type: RecordIdString
	updated: IsoAutoDateString
}

export const CalculatorUsageLogsCalculatorTypeOptions = {
	"calculator": "calculator",
	"decision_tool": "decision_tool",
	"checklist": "checklist",
} as const
export type CalculatorUsageLogsCalculatorTypeOptions = typeof CalculatorUsageLogsCalculatorTypeOptions[keyof typeof CalculatorUsageLogsCalculatorTypeOptions]
export type CalculatorUsageLogsRecord = {
	calculator_id: RecordIdString
	calculator_type: CalculatorUsageLogsCalculatorTypeOptions
	created: IsoAutoDateString
	id: string
	session_end?: IsoDateString
	session_start: IsoDateString
	updated: IsoAutoDateString
	user_id: RecordIdString
}

export const CalculatorsTypeOptions = {
	"calculator": "calculator",
	"decision_tool": "decision_tool",
	"checklist": "checklist",
} as const
export type CalculatorsTypeOptions = typeof CalculatorsTypeOptions[keyof typeof CalculatorsTypeOptions]

export const CalculatorsStatusOptions = {
	"active": "active",
	"draft": "draft",
	"archived": "archived",
} as const
export type CalculatorsStatusOptions = typeof CalculatorsStatusOptions[keyof typeof CalculatorsStatusOptions]

export const CalculatorsCategoryOptions = {
	"surgical": "surgical",
	"emergency": "emergency",
	"maternal": "maternal",
	"pediatric": "pediatric",
	"cardiology": "cardiology",
	"neurology": "neurology",
	"pharmacy": "pharmacy",
	"nutrition": "nutrition",
	"infection_control": "infection_control",
	"safety": "safety",
	"general": "general",
} as const
export type CalculatorsCategoryOptions = typeof CalculatorsCategoryOptions[keyof typeof CalculatorsCategoryOptions]

export const CalculatorsPriorityOptions = {
	"critical": "critical",
	"high": "high",
	"medium": "medium",
	"low": "low",
} as const
export type CalculatorsPriorityOptions = typeof CalculatorsPriorityOptions[keyof typeof CalculatorsPriorityOptions]

export type CalculatorsRecord = {
	addedBy: RecordIdString
	appFile: FileNameString
	backgroundColor?: string
	category?: CalculatorsCategoryOptions
	color?: string
	created: IsoAutoDateString
	description?: string
	featured?: boolean
	icon?: string
	id: string
	name: string
	priority?: CalculatorsPriorityOptions
	status?: CalculatorsStatusOptions
	type: CalculatorsTypeOptions
	updated: IsoAutoDateString
	usageCount?: number
	version: string
}

export type ConsultantUsageLogsRecord = {
	consultant_id: RecordIdString
	created: IsoAutoDateString
	id: string
	updated: IsoAutoDateString
	user_id: RecordIdString
}

export const ConsultantsSpecialtyOptions = {
	"General Practice": "General Practice",
	"Internal Medicine": "Internal Medicine",
	"Pediatrics": "Pediatrics",
	"Surgery": "Surgery",
	"Cardiology": "Cardiology",
	"Neurology": "Neurology",
	"Psychiatry": "Psychiatry",
	"Orthopedics": "Orthopedics",
	"Dermatology": "Dermatology",
	"Ophthalmology": "Ophthalmology",
	"Emergency Medicine": "Emergency Medicine",
	"Radiology": "Radiology",
	"Anesthesiology": "Anesthesiology",
	"Pathology": "Pathology",
	"Oncology": "Oncology",
	"Endocrinology": "Endocrinology",
	"Gastroenterology": "Gastroenterology",
	"Pulmonology": "Pulmonology",
	"Nephrology": "Nephrology",
	"Infectious Diseases": "Infectious Diseases",
	"Rheumatology": "Rheumatology",
	"Public Health": "Public Health",
	"Nursing": "Nursing",
	"Pharmacy": "Pharmacy",
	"Laboratory Medicine": "Laboratory Medicine",
	"Other": "Other",
} as const
export type ConsultantsSpecialtyOptions = typeof ConsultantsSpecialtyOptions[keyof typeof ConsultantsSpecialtyOptions]

export const ConsultantsQualificationsOptions = {
	"MD": "MD",
	"MBBS": "MBBS",
	"DDS": "DDS",
	"PharmD": "PharmD",
	"RN": "RN",
	"BSN": "BSN",
	"MSN": "MSN",
	"DNP": "DNP",
	"PhD": "PhD",
	"MPH": "MPH",
	"MS": "MS",
	"MA": "MA",
	"Diploma": "Diploma",
	"Certificate": "Certificate",
	"Fellowship": "Fellowship",
	"Residency": "Residency",
	"Other": "Other",
	"DO_DEGREE": "DO_DEGREE",
} as const
export type ConsultantsQualificationsOptions = typeof ConsultantsQualificationsOptions[keyof typeof ConsultantsQualificationsOptions]

export const ConsultantsPreferredLanguageOptions = {
	"English": "English",
	"French": "French",
	"Spanish": "Spanish",
	"Portuguese": "Portuguese",
	"Arabic": "Arabic",
	"Swahili": "Swahili",
	"Amharic": "Amharic",
	"Other": "Other",
} as const
export type ConsultantsPreferredLanguageOptions = typeof ConsultantsPreferredLanguageOptions[keyof typeof ConsultantsPreferredLanguageOptions]

export const ConsultantsConsultationTypesOptions = {
	"In-Person": "In-Person",
	"Telemedicine": "Telemedicine",
	"Phone Consultation": "Phone Consultation",
	"Emergency Consultation": "Emergency Consultation",
	"Second Opinion": "Second Opinion",
	"Follow-up": "Follow-up",
	"Diagnostic Review": "Diagnostic Review",
	"Treatment Planning": "Treatment Planning",
	"Medication Review": "Medication Review",
	"Health Education": "Health Education",
} as const
export type ConsultantsConsultationTypesOptions = typeof ConsultantsConsultationTypesOptions[keyof typeof ConsultantsConsultationTypesOptions]

export const ConsultantsStatusOptions = {
	"active": "active",
	"inactive": "inactive",
	"pendingApproval": "pendingApproval",
	"suspended": "suspended",
} as const
export type ConsultantsStatusOptions = typeof ConsultantsStatusOptions[keyof typeof ConsultantsStatusOptions]
export type ConsultantsRecord<Tavailability = unknown> = {
	address?: string
	alternativePhone?: string
	availability?: null | Tavailability
	avatar?: FileNameString
	certifications?: string
	city?: string
	consultationTypes?: ConsultantsConsultationTypesOptions
	country: string
	created: IsoAutoDateString
	department?: string
	email: string
	id: string
	isVerified?: boolean
	licenseNumber?: string
	name: string
	notes?: string
	organization?: string
	phone: string
	postalCode?: string
	preferredLanguage?: ConsultantsPreferredLanguageOptions
	profilePicture?: FileNameString
	qualifications?: ConsultantsQualificationsOptions[]
	rating?: number
	region?: string
	specialty: ConsultantsSpecialtyOptions
	status: ConsultantsStatusOptions
	timezone?: string
	totalConsultations?: number
	updated: IsoAutoDateString
	usageCount?: number
	user?: RecordIdString
	yearsOfExperience?: number
}

export type ConversationsRecord = {
	created: IsoAutoDateString
	id: string
	last_activity?: IsoDateString
	participant1: RecordIdString
	participant2: RecordIdString
	updated: IsoAutoDateString
}

export type CountiesRecord = {
	created: IsoAutoDateString
	district: RecordIdString
	hsdt_code?: string
	id: string
	name: string
	nhpi_code?: string
	updated: IsoAutoDateString
}

export type DistrictsRecord = {
	created: IsoAutoDateString
	health_sub_region: RecordIdString
	hsdt_code?: string
	id: string
	name: string
	nhpi_code?: string
	region: RecordIdString
	updated: IsoAutoDateString
}

export const DocumentationStatusOptions = {
	"draft": "draft",
	"published": "published",
	"archived": "archived",
} as const
export type DocumentationStatusOptions = typeof DocumentationStatusOptions[keyof typeof DocumentationStatusOptions]
export type DocumentationRecord = {
	category?: string
	content: HTMLString
	created: IsoAutoDateString
	description?: string
	id: string
	status?: DocumentationStatusOptions
	tags?: string
	title: string
	updated: IsoAutoDateString
}

export const DrugCategoriesStatusOptions = {
	"active": "active",
	"inactive": "inactive",
} as const
export type DrugCategoriesStatusOptions = typeof DrugCategoriesStatusOptions[keyof typeof DrugCategoriesStatusOptions]
export type DrugCategoriesRecord = {
	color?: string
	created: IsoAutoDateString
	description?: string
	icon?: string
	id: string
	name: string
	parent_category?: RecordIdString
	sort_order?: number
	status: DrugCategoriesStatusOptions
	updated: IsoAutoDateString
}

export const DrugClassesStatusOptions = {
	"active": "active",
	"inactive": "inactive",
} as const
export type DrugClassesStatusOptions = typeof DrugClassesStatusOptions[keyof typeof DrugClassesStatusOptions]
export type DrugClassesRecord = {
	created: IsoAutoDateString
	description?: string
	id: string
	name: string
	sort_order?: number
	status: DrugClassesStatusOptions
	updated: IsoAutoDateString
}

export const DrugTagsTagCategoryOptions = {
	"clinical": "clinical",
	"administrative": "administrative",
	"regulatory": "regulatory",
	"safety": "safety",
} as const
export type DrugTagsTagCategoryOptions = typeof DrugTagsTagCategoryOptions[keyof typeof DrugTagsTagCategoryOptions]

export const DrugTagsStatusOptions = {
	"active": "active",
	"inactive": "inactive",
} as const
export type DrugTagsStatusOptions = typeof DrugTagsStatusOptions[keyof typeof DrugTagsStatusOptions]
export type DrugTagsRecord = {
	color?: string
	created: IsoAutoDateString
	description?: string
	id: string
	name: string
	sort_order?: number
	status: DrugTagsStatusOptions
	tag_category: DrugTagsTagCategoryOptions
	updated: IsoAutoDateString
}

export type DrugUsageLogsRecord = {
	created: IsoAutoDateString
	drug_id: RecordIdString
	id: string
	updated: IsoAutoDateString
	user_id: RecordIdString
}

export const DrugsRouteOfAdministrationOptions = {
	"oral": "oral",
	"IV": "IV",
	"IM": "IM",
	"topical": "topical",
	"inhaled": "inhaled",
	"sublingual": "sublingual",
	"rectal": "rectal",
	"transdermal": "transdermal",
	"intranasal": "intranasal",
	"subcutaneous": "subcutaneous",
} as const
export type DrugsRouteOfAdministrationOptions = typeof DrugsRouteOfAdministrationOptions[keyof typeof DrugsRouteOfAdministrationOptions]

export const DrugsPregnancyCategoryOptions = {
	"A": "A",
	"B": "B",
	"C": "C",
	"D": "D",
	"X": "X",
	"Unknown": "Unknown",
} as const
export type DrugsPregnancyCategoryOptions = typeof DrugsPregnancyCategoryOptions[keyof typeof DrugsPregnancyCategoryOptions]

export const DrugsControlledSubstanceOptions = {
	"None": "None",
	"Schedule I": "Schedule I",
	"Schedule II": "Schedule II",
	"Schedule III": "Schedule III",
	"Schedule IV": "Schedule IV",
	"Schedule V": "Schedule V",
} as const
export type DrugsControlledSubstanceOptions = typeof DrugsControlledSubstanceOptions[keyof typeof DrugsControlledSubstanceOptions]

export const DrugsStatusOptions = {
	"active": "active",
	"inactive": "inactive",
	"under_review": "under_review",
	"archived": "archived",
} as const
export type DrugsStatusOptions = typeof DrugsStatusOptions[keyof typeof DrugsStatusOptions]

export const DrugsReviewStatusOptions = {
	"approved": "approved",
	"pending": "pending",
	"needs_update": "needs_update",
} as const
export type DrugsReviewStatusOptions = typeof DrugsReviewStatusOptions[keyof typeof DrugsReviewStatusOptions]
export type DrugsRecord = {
	adult_dose?: string
	antimicrobial_status?: boolean
	brand_names?: string
	categories?: RecordIdString[]
	clinical_notes?: HTMLString
	contraindications?: HTMLString
	controlled_substance?: DrugsControlledSubstanceOptions
	created: IsoAutoDateString
	description?: HTMLString
	drug_class?: RecordIdString
	duration?: string
	elderly_dose?: string
	frequency?: string
	id: string
	indications?: HTMLString
	max_daily_dose?: string
	mechanism_of_action?: HTMLString
	monitoring_parameters?: string
	name: string
	pediatric_dose?: string
	pregnancy_category?: DrugsPregnancyCategoryOptions
	references?: HTMLString
	review_status: DrugsReviewStatusOptions
	route_of_administration?: DrugsRouteOfAdministrationOptions[]
	search_keywords?: string
	side_effects?: HTMLString
	status: DrugsStatusOptions
	tags?: RecordIdString[]
	therapeutic_category?: RecordIdString
	updated: IsoAutoDateString
	usageCount?: number
	warnings?: HTMLString
	who_eml_status?: boolean
}

export const EmergencyProtocolsCategoryOptions = {
	"Resuscitation": "Resuscitation",
	"Trauma": "Trauma",
	"Emergency Medicine": "Emergency Medicine",
	"Critical Care": "Critical Care",
	"Toxicology": "Toxicology",
	"Environmental": "Environmental",
	"Pediatric": "Pediatric",
	"Obstetric": "Obstetric",
	"Cardiac": "Cardiac",
	"Neurology": "Neurology",
} as const
export type EmergencyProtocolsCategoryOptions = typeof EmergencyProtocolsCategoryOptions[keyof typeof EmergencyProtocolsCategoryOptions]

export const EmergencyProtocolsPriorityOptions = {
	"critical": "critical",
	"high": "high",
	"medium": "medium",
	"low": "low",
} as const
export type EmergencyProtocolsPriorityOptions = typeof EmergencyProtocolsPriorityOptions[keyof typeof EmergencyProtocolsPriorityOptions]

export const EmergencyProtocolsStatusOptions = {
	"active": "active",
	"draft": "draft",
	"archived": "archived",
} as const
export type EmergencyProtocolsStatusOptions = typeof EmergencyProtocolsStatusOptions[keyof typeof EmergencyProtocolsStatusOptions]
export type EmergencyProtocolsRecord<Tcontact_info = unknown, Tcritical_actions = unknown, Tmedications = unknown, Tsteps = unknown, Ttags = unknown, Ttransfer_checklist = unknown, Tvital_signs = unknown> = {
	access_count?: number
	category: EmergencyProtocolsCategoryOptions
	contact_info?: null | Tcontact_info
	created: IsoAutoDateString
	critical_actions?: null | Tcritical_actions
	description?: string
	id: string
	medications?: null | Tmedications
	priority: EmergencyProtocolsPriorityOptions
	status: EmergencyProtocolsStatusOptions
	steps?: null | Tsteps
	tags?: null | Ttags
	timeframe?: string
	title: string
	transfer_checklist?: null | Ttransfer_checklist
	updated: IsoAutoDateString
	vital_signs?: null | Tvital_signs
}

export type FacilityLevelsRecord = {
	code: string
	created: IsoAutoDateString
	id: string
	name: string
	updated: IsoAutoDateString
}

export type FacilityUsageLogsRecord = {
	created: IsoAutoDateString
	facility_id: RecordIdString
	id: string
	updated: IsoAutoDateString
	user_id: RecordIdString
}

export type FaqTagsRecord = {
	color?: string
	created: IsoAutoDateString
	description?: string
	icon?: string
	id: string
	is_active?: boolean
	name: string
	slug: string
	sort_order?: number
	updated: IsoAutoDateString
	usage_count?: number
}

export const FaqsStatusOptions = {
	"draft": "draft",
	"review": "review",
	"published": "published",
	"archived": "archived",
} as const
export type FaqsStatusOptions = typeof FaqsStatusOptions[keyof typeof FaqsStatusOptions]

export const FaqsPriorityOptions = {
	"low": "low",
	"normal": "normal",
	"high": "high",
	"critical": "critical",
} as const
export type FaqsPriorityOptions = typeof FaqsPriorityOptions[keyof typeof FaqsPriorityOptions]

export const FaqsTargetAudienceOptions = {
	"all": "all",
	"admin": "admin",
	"health_worker": "health_worker",
	"patient": "patient",
} as const
export type FaqsTargetAudienceOptions = typeof FaqsTargetAudienceOptions[keyof typeof FaqsTargetAudienceOptions]
export type FaqsRecord = {
	answer: HTMLString
	author?: RecordIdString
	created: IsoAutoDateString
	id: string
	is_featured?: boolean
	keywords?: string
	priority?: FaqsPriorityOptions
	published_at?: IsoDateString
	question: string
	related_faqs?: RecordIdString[]
	review_due?: IsoDateString
	reviewer?: RecordIdString
	sort_order?: number
	status?: FaqsStatusOptions
	tags?: RecordIdString[]
	target_audience?: FaqsTargetAudienceOptions
	updated: IsoAutoDateString
}

export type GenericPagesRecord<Tcontent = unknown> = {
	content?: null | Tcontent
	created: IsoAutoDateString
	description?: string
	id: string
	key: string
	title: string
	updated: IsoAutoDateString
}

export const GuidelineCategoriesStatusOptions = {
	"active": "active",
	"inactive": "inactive",
} as const
export type GuidelineCategoriesStatusOptions = typeof GuidelineCategoriesStatusOptions[keyof typeof GuidelineCategoriesStatusOptions]
export type GuidelineCategoriesRecord = {
	color?: string
	created: IsoAutoDateString
	description?: string
	icon?: string
	id: string
	name: string
	parent_category?: RecordIdString
	slug?: string
	sort_order?: number
	status: GuidelineCategoriesStatusOptions
	updated: IsoAutoDateString
}

export type GuidelineIndexRecord = {
	created: IsoAutoDateString
	description?: string
	hasChildren?: boolean
	id: string
	level?: number
	order?: number
	parent?: RecordIdString
	title: string
	updated: IsoAutoDateString
}

export type GuidelineTagsRecord = {
	created: IsoAutoDateString
	description?: string
	id: string
	name: string
	updated: IsoAutoDateString
}

export type GuidelineUsageLogsRecord = {
	created: IsoAutoDateString
	guideline_id: RecordIdString
	id: string
	updated: IsoAutoDateString
	user_id: RecordIdString
}

export type HealthFacilitiesRecord = {
	authority: RecordIdString
	county: RecordIdString
	created: IsoAutoDateString
	district: RecordIdString
	facility_level: RecordIdString
	health_sub_district: RecordIdString
	health_sub_region: RecordIdString
	hsdt_code: string
	id: string
	name: string
	nhpi_code: string
	ownership_type: RecordIdString
	parish: RecordIdString
	region: RecordIdString
	subcounty: RecordIdString
	updated: IsoAutoDateString
	usageCount?: number
}

export type HealthSubDistrictsRecord = {
	created: IsoAutoDateString
	district: RecordIdString
	hsdt_code: string
	id: string
	name: string
	nhpi_code: string
	updated: IsoAutoDateString
}

export type HealthSubRegionsRecord = {
	created: IsoAutoDateString
	hsdt_code: string
	id: string
	name: string
	nhpi_code: string
	region: RecordIdString
	updated: IsoAutoDateString
}

export const LanguagesStatusOptions = {
	"draft": "draft",
	"in_progress": "in_progress",
	"complete": "complete",
	"review": "review",
} as const
export type LanguagesStatusOptions = typeof LanguagesStatusOptions[keyof typeof LanguagesStatusOptions]
export type LanguagesRecord<Ttranslations = unknown> = {
	code: string
	created: IsoAutoDateString
	enabled_for_users?: boolean
	id: string
	is_active?: boolean
	is_default?: boolean
	name: string
	native_name: string
	progress?: number
	status?: LanguagesStatusOptions
	translations?: null | Ttranslations
	translations_url?: string
	updated: IsoAutoDateString
	version?: number
}

export type MedicalGuidelinesRecord = {
	categories?: RecordIdString[]
	causes?: HTMLString
	classification_critical?: HTMLString
	classification_mild?: HTMLString
	classification_moderate?: HTMLString
	classification_severe?: HTMLString
	clinical_features?: HTMLString
	condition_name: string
	contraindications?: HTMLString
	created: IsoAutoDateString
	definition?: HTMLString
	differential_diagnosis?: HTMLString
	dosage_adult?: HTMLString
	dosage_pediatric?: HTMLString
	dosage_secondary_adult?: HTMLString
	dosage_secondary_pediatric?: HTMLString
	general_management?: HTMLString
	healthcare_level_required?: string
	icd10_code?: string
	id: string
	index_item?: RecordIdString
	is_published?: boolean
	medication_primary?: string
	medication_secondary?: string
	monitoring_requirements?: HTMLString
	prevention_measures?: HTMLString
	priority?: string
	route_administration?: string
	special_notes?: HTMLString
	status?: string
	tags?: RecordIdString[]
	target_population?: string
	updated: IsoAutoDateString
	usageCount?: number
	version?: string
}

export const MessagesMessageTypeOptions = {
	"text": "text",
	"image": "image",
	"file": "file",
	"voice": "voice",
} as const
export type MessagesMessageTypeOptions = typeof MessagesMessageTypeOptions[keyof typeof MessagesMessageTypeOptions]
export type MessagesRecord<Treactions = unknown, Tread_by = unknown> = {
	attachments?: FileNameString
	content: string
	conversation: RecordIdString
	created: IsoAutoDateString
	edited_at?: IsoDateString
	id: string
	is_edited?: boolean
	message_type?: MessagesMessageTypeOptions
	reactions?: null | Treactions
	read_by?: null | Tread_by
	reply_to?: RecordIdString
	sender: RecordIdString
	updated: IsoAutoDateString
}

export const MinistryDirectoryMinistryOptions = {
	"Ministry of Health": "Ministry of Health",
	"Ministry of Education": "Ministry of Education",
	"Ministry of Local Government": "Ministry of Local Government",
	"Ministry of Agriculture": "Ministry of Agriculture",
	"Ministry of Water and Environment": "Ministry of Water and Environment",
	"Ministry of Internal Affairs": "Ministry of Internal Affairs",
	"Ministry of Gender, Labour and Social Development": "Ministry of Gender, Labour and Social Development",
	"Ministry of Finance": "Ministry of Finance",
	"Ministry of Trade": "Ministry of Trade",
	"Ministry of Transport": "Ministry of Transport",
	"Other": "Other",
} as const
export type MinistryDirectoryMinistryOptions = typeof MinistryDirectoryMinistryOptions[keyof typeof MinistryDirectoryMinistryOptions]

export const MinistryDirectoryStatusOptions = {
	"active": "active",
	"inactive": "inactive",
	"pending": "pending",
} as const
export type MinistryDirectoryStatusOptions = typeof MinistryDirectoryStatusOptions[keyof typeof MinistryDirectoryStatusOptions]
export type MinistryDirectoryRecord = {
	alternativePhone?: string
	availability_hours?: string
	created: IsoAutoDateString
	department?: string
	district: RecordIdString
	email?: string
	id: string
	ministry: MinistryDirectoryMinistryOptions
	name: string
	notes?: string
	office_address?: string
	phone: string
	priority_level?: number
	region?: RecordIdString
	specialization?: string
	status: MinistryDirectoryStatusOptions
	title: string
	updated: IsoAutoDateString
}

export const NotificationCampaignsTypeOptions = {
	"emergency": "emergency",
	"update": "update",
	"reminder": "reminder",
	"marketing": "marketing",
	"announcement": "announcement",
} as const
export type NotificationCampaignsTypeOptions = typeof NotificationCampaignsTypeOptions[keyof typeof NotificationCampaignsTypeOptions]

export const NotificationCampaignsStatusOptions = {
	"scheduled": "scheduled",
	"running": "running",
	"completed": "completed",
	"paused": "paused",
	"draft": "draft",
} as const
export type NotificationCampaignsStatusOptions = typeof NotificationCampaignsStatusOptions[keyof typeof NotificationCampaignsStatusOptions]
export type NotificationCampaignsRecord<Taudience_countries = unknown, Taudience_roles = unknown, Tchannels = unknown> = {
	audience_countries?: null | Taudience_countries
	audience_roles?: null | Taudience_roles
	audience_total?: number
	channels: null | Tchannels
	created: IsoAutoDateString
	id: string
	metrics_clicked?: number
	metrics_delivered?: number
	metrics_opened?: number
	metrics_sent?: number
	name: string
	schedule_end?: IsoDateString
	schedule_start?: IsoDateString
	status: NotificationCampaignsStatusOptions
	type: NotificationCampaignsTypeOptions
	updated: IsoAutoDateString
}

export const NotificationTemplatesTypeOptions = {
	"push": "push",
	"email": "email",
	"sms": "sms",
	"in-app": "in-app",
} as const
export type NotificationTemplatesTypeOptions = typeof NotificationTemplatesTypeOptions[keyof typeof NotificationTemplatesTypeOptions]

export const NotificationTemplatesCategoryOptions = {
	"Content Updates": "Content Updates",
	"Emergency": "Emergency",
	"Training": "Training",
	"System": "System",
	"Marketing": "Marketing",
	"Reminder": "Reminder",
} as const
export type NotificationTemplatesCategoryOptions = typeof NotificationTemplatesCategoryOptions[keyof typeof NotificationTemplatesCategoryOptions]

export const NotificationTemplatesStatusOptions = {
	"active": "active",
	"draft": "draft",
	"inactive": "inactive",
} as const
export type NotificationTemplatesStatusOptions = typeof NotificationTemplatesStatusOptions[keyof typeof NotificationTemplatesStatusOptions]
export type NotificationTemplatesRecord<Tvariables = unknown> = {
	audience?: string
	category: NotificationTemplatesCategoryOptions
	clicked_count?: number
	content: HTMLString
	created: IsoAutoDateString
	id: string
	last_sent?: IsoDateString
	name: string
	opened_count?: number
	sent_count?: number
	status: NotificationTemplatesStatusOptions
	subject?: string
	type: NotificationTemplatesTypeOptions
	updated: IsoAutoDateString
	variables?: null | Tvariables
}

export const NotificationsTypeOptions = {
	"info": "info",
	"success": "success",
	"warning": "warning",
	"error": "error",
} as const
export type NotificationsTypeOptions = typeof NotificationsTypeOptions[keyof typeof NotificationsTypeOptions]

export const NotificationsPriorityOptions = {
	"low": "low",
	"normal": "normal",
	"high": "high",
	"urgent": "urgent",
} as const
export type NotificationsPriorityOptions = typeof NotificationsPriorityOptions[keyof typeof NotificationsPriorityOptions]
export type NotificationsRecord = {
	action_url?: string
	created: IsoAutoDateString
	id: string
	message: string
	priority: NotificationsPriorityOptions
	title: string
	type: NotificationsTypeOptions
	updated: IsoAutoDateString
	user_id?: RecordIdString
}

export type OwnershipTypesRecord = {
	code: string
	created: IsoAutoDateString
	id: string
	name: string
	updated: IsoAutoDateString
}

export type ParishesRecord = {
	created: IsoAutoDateString
	hsdt_code: string
	id: string
	name: string
	nhpi_code: string
	subcounty: RecordIdString
	updated: IsoAutoDateString
}

export type ReadingProgressRecord = {
	created: IsoAutoDateString
	current_section?: string
	guideline_id: RecordIdString
	id: string
	is_bookmarked?: boolean
	last_read_at?: IsoDateString
	progress_percentage: number
	reading_time_seconds?: number
	updated: IsoAutoDateString
	user_id: RecordIdString
}

export type RegionsRecord = {
	created: IsoAutoDateString
	hsdt_code?: string
	id: string
	name: string
	nhpi_code?: string
	updated: IsoAutoDateString
}

export type RolesRecord<Tpermissions = unknown> = {
	created: IsoAutoDateString
	description?: string
	id: string
	isActive?: boolean
	key: string
	name: string
	permissions?: null | Tpermissions
	updated: IsoAutoDateString
}

export type SettingsRecord<Tvalue = unknown> = {
	category?: string
	created: IsoAutoDateString
	description?: string
	id: string
	is_public?: boolean
	key: string
	updated: IsoAutoDateString
	value: null | Tvalue
}

export type SubcountiesRecord = {
	county: RecordIdString
	created: IsoAutoDateString
	district: RecordIdString
	hsdt_code: string
	id: string
	name: string
	nhpi_code: string
	updated: IsoAutoDateString
}

export type SupportTicketRepliesRecord = {
	created: IsoAutoDateString
	id: string
	is_internal?: boolean
	message: HTMLString
	ticket_id: RecordIdString
	updated: IsoAutoDateString
	user_id: RecordIdString
}

export const SupportTicketsStatusOptions = {
	"open": "open",
	"in_progress": "in_progress",
	"resolved": "resolved",
	"closed": "closed",
} as const
export type SupportTicketsStatusOptions = typeof SupportTicketsStatusOptions[keyof typeof SupportTicketsStatusOptions]

export const SupportTicketsPriorityOptions = {
	"low": "low",
	"normal": "normal",
	"high": "high",
	"urgent": "urgent",
} as const
export type SupportTicketsPriorityOptions = typeof SupportTicketsPriorityOptions[keyof typeof SupportTicketsPriorityOptions]
export type SupportTicketsRecord = {
	assigned_to?: RecordIdString
	category?: string
	created: IsoAutoDateString
	description: HTMLString
	id: string
	priority: SupportTicketsPriorityOptions
	status: SupportTicketsStatusOptions
	subject: string
	updated: IsoAutoDateString
	user_id: RecordIdString
}

export const TherapeuticCategoriesStatusOptions = {
	"active": "active",
	"inactive": "inactive",
} as const
export type TherapeuticCategoriesStatusOptions = typeof TherapeuticCategoriesStatusOptions[keyof typeof TherapeuticCategoriesStatusOptions]
export type TherapeuticCategoriesRecord = {
	created: IsoAutoDateString
	description?: string
	id: string
	name: string
	sort_order?: number
	status: TherapeuticCategoriesStatusOptions
	updated: IsoAutoDateString
}

export const UsersRoleOptions = {
	"superAdmin": "superAdmin",
	"admin": "admin",
	"contentManager": "contentManager",
	"reviewer": "reviewer",
	"healthcareProvider": "healthcareProvider",
	"observer": "observer",
} as const
export type UsersRoleOptions = typeof UsersRoleOptions[keyof typeof UsersRoleOptions]

export const UsersStatusOptions = {
	"active": "active",
	"inactive": "inactive",
	"suspended": "suspended",
	"pendingActivation": "pendingActivation",
} as const
export type UsersStatusOptions = typeof UsersStatusOptions[keyof typeof UsersStatusOptions]

export const UsersPreferredLanguageOptions = {
	"english": "english",
	"french": "french",
	"spanish": "spanish",
	"portuguese": "portuguese",
	"arabic": "arabic",
	"swahili": "swahili",
	"amharic": "amharic",
} as const
export type UsersPreferredLanguageOptions = typeof UsersPreferredLanguageOptions[keyof typeof UsersPreferredLanguageOptions]
export type UsersRecord = {
	address?: string
	alternativePhone?: string
	avatar?: FileNameString
	city?: string
	country?: string
	created: IsoAutoDateString
	department?: string
	email: string
	emailVisibility?: boolean
	id: string
	jobTitle?: string
	licenseNumber?: string
	name?: string
	notes?: string
	organization?: string
	password: string
	phone?: string
	postalCode?: string
	preferredLanguage?: UsersPreferredLanguageOptions
	role?: UsersRoleOptions
	specialization?: string
	state?: string
	status?: UsersStatusOptions
	timezone?: string
	tokenKey: string
	updated: IsoAutoDateString
	verified?: boolean
}

// Response types include system fields and match responses from the legacy collection API API
export type AuthoriginsResponse<Texpand = unknown> = Required<AuthoriginsRecord> & BaseSystemFields<Texpand>
export type ExternalauthsResponse<Texpand = unknown> = Required<ExternalauthsRecord> & BaseSystemFields<Texpand>
export type MfasResponse<Texpand = unknown> = Required<MfasRecord> & BaseSystemFields<Texpand>
export type OtpsResponse<Texpand = unknown> = Required<OtpsRecord> & BaseSystemFields<Texpand>
export type SuperusersResponse<Texpand = unknown> = Required<SuperusersRecord> & AuthSystemFields<Texpand>
export type AbbreviationUsageLogsResponse<Texpand = unknown> = Required<AbbreviationUsageLogsRecord> & BaseSystemFields<Texpand>
export type AbbreviationsResponse<Texpand = unknown> = Required<AbbreviationsRecord> & BaseSystemFields<Texpand>
export type AiUsageLogsResponse<Texpand = unknown> = Required<AiUsageLogsRecord> & BaseSystemFields<Texpand>
export type AuthoritiesResponse<Texpand = unknown> = Required<AuthoritiesRecord> & BaseSystemFields<Texpand>
export type CalculatorUsageLogsResponse<Texpand = unknown> = Required<CalculatorUsageLogsRecord> & BaseSystemFields<Texpand>
export type CalculatorsResponse<Texpand = unknown> = Required<CalculatorsRecord> & BaseSystemFields<Texpand>
export type ConsultantUsageLogsResponse<Texpand = unknown> = Required<ConsultantUsageLogsRecord> & BaseSystemFields<Texpand>
export type ConsultantsResponse<Tavailability = unknown, Texpand = unknown> = Required<ConsultantsRecord<Tavailability>> & BaseSystemFields<Texpand>
export type ConversationsResponse<Texpand = unknown> = Required<ConversationsRecord> & BaseSystemFields<Texpand>
export type CountiesResponse<Texpand = unknown> = Required<CountiesRecord> & BaseSystemFields<Texpand>
export type DistrictsResponse<Texpand = unknown> = Required<DistrictsRecord> & BaseSystemFields<Texpand>
export type DocumentationResponse<Texpand = unknown> = Required<DocumentationRecord> & BaseSystemFields<Texpand>
export type DrugCategoriesResponse<Texpand = unknown> = Required<DrugCategoriesRecord> & BaseSystemFields<Texpand>
export type DrugClassesResponse<Texpand = unknown> = Required<DrugClassesRecord> & BaseSystemFields<Texpand>
export type DrugTagsResponse<Texpand = unknown> = Required<DrugTagsRecord> & BaseSystemFields<Texpand>
export type DrugUsageLogsResponse<Texpand = unknown> = Required<DrugUsageLogsRecord> & BaseSystemFields<Texpand>
export type DrugsResponse<Texpand = unknown> = Required<DrugsRecord> & BaseSystemFields<Texpand>
export type EmergencyProtocolsResponse<Tcontact_info = unknown, Tcritical_actions = unknown, Tmedications = unknown, Tsteps = unknown, Ttags = unknown, Ttransfer_checklist = unknown, Tvital_signs = unknown, Texpand = unknown> = Required<EmergencyProtocolsRecord<Tcontact_info, Tcritical_actions, Tmedications, Tsteps, Ttags, Ttransfer_checklist, Tvital_signs>> & BaseSystemFields<Texpand>
export type FacilityLevelsResponse<Texpand = unknown> = Required<FacilityLevelsRecord> & BaseSystemFields<Texpand>
export type FacilityUsageLogsResponse<Texpand = unknown> = Required<FacilityUsageLogsRecord> & BaseSystemFields<Texpand>
export type FaqTagsResponse<Texpand = unknown> = Required<FaqTagsRecord> & BaseSystemFields<Texpand>
export type FaqsResponse<Texpand = unknown> = Required<FaqsRecord> & BaseSystemFields<Texpand>
export type GenericPagesResponse<Tcontent = unknown, Texpand = unknown> = Required<GenericPagesRecord<Tcontent>> & BaseSystemFields<Texpand>
export type GuidelineCategoriesResponse<Texpand = unknown> = Required<GuidelineCategoriesRecord> & BaseSystemFields<Texpand>
export type GuidelineIndexResponse<Texpand = unknown> = Required<GuidelineIndexRecord> & BaseSystemFields<Texpand>
export type GuidelineTagsResponse<Texpand = unknown> = Required<GuidelineTagsRecord> & BaseSystemFields<Texpand>
export type GuidelineUsageLogsResponse<Texpand = unknown> = Required<GuidelineUsageLogsRecord> & BaseSystemFields<Texpand>
export type HealthFacilitiesResponse<Texpand = unknown> = Required<HealthFacilitiesRecord> & BaseSystemFields<Texpand>
export type HealthSubDistrictsResponse<Texpand = unknown> = Required<HealthSubDistrictsRecord> & BaseSystemFields<Texpand>
export type HealthSubRegionsResponse<Texpand = unknown> = Required<HealthSubRegionsRecord> & BaseSystemFields<Texpand>
export type LanguagesResponse<Ttranslations = unknown, Texpand = unknown> = Required<LanguagesRecord<Ttranslations>> & BaseSystemFields<Texpand>
export type MedicalGuidelinesResponse<Texpand = unknown> = Required<MedicalGuidelinesRecord> & BaseSystemFields<Texpand>
export type MessagesResponse<Treactions = unknown, Tread_by = unknown, Texpand = unknown> = Required<MessagesRecord<Treactions, Tread_by>> & BaseSystemFields<Texpand>
export type MinistryDirectoryResponse<Texpand = unknown> = Required<MinistryDirectoryRecord> & BaseSystemFields<Texpand>
export type NotificationCampaignsResponse<Taudience_countries = unknown, Taudience_roles = unknown, Tchannels = unknown, Texpand = unknown> = Required<NotificationCampaignsRecord<Taudience_countries, Taudience_roles, Tchannels>> & BaseSystemFields<Texpand>
export type NotificationTemplatesResponse<Tvariables = unknown, Texpand = unknown> = Required<NotificationTemplatesRecord<Tvariables>> & BaseSystemFields<Texpand>
export type NotificationsResponse<Texpand = unknown> = Required<NotificationsRecord> & BaseSystemFields<Texpand>
export type OwnershipTypesResponse<Texpand = unknown> = Required<OwnershipTypesRecord> & BaseSystemFields<Texpand>
export type ParishesResponse<Texpand = unknown> = Required<ParishesRecord> & BaseSystemFields<Texpand>
export type ReadingProgressResponse<Texpand = unknown> = Required<ReadingProgressRecord> & BaseSystemFields<Texpand>
export type RegionsResponse<Texpand = unknown> = Required<RegionsRecord> & BaseSystemFields<Texpand>
export type RolesResponse<Tpermissions = unknown, Texpand = unknown> = Required<RolesRecord<Tpermissions>> & BaseSystemFields<Texpand>
export type SettingsResponse<Tvalue = unknown, Texpand = unknown> = Required<SettingsRecord<Tvalue>> & BaseSystemFields<Texpand>
export type SubcountiesResponse<Texpand = unknown> = Required<SubcountiesRecord> & BaseSystemFields<Texpand>
export type SupportTicketRepliesResponse<Texpand = unknown> = Required<SupportTicketRepliesRecord> & BaseSystemFields<Texpand>
export type SupportTicketsResponse<Texpand = unknown> = Required<SupportTicketsRecord> & BaseSystemFields<Texpand>
export type TherapeuticCategoriesResponse<Texpand = unknown> = Required<TherapeuticCategoriesRecord> & BaseSystemFields<Texpand>
export type UsersResponse<Texpand = unknown> = Required<UsersRecord> & AuthSystemFields<Texpand>

// Types containing all Records and Responses, useful for creating typing helper functions

export type CollectionRecords = {
	_authOrigins: AuthoriginsRecord
	_externalAuths: ExternalauthsRecord
	_mfas: MfasRecord
	_otps: OtpsRecord
	_superusers: SuperusersRecord
	abbreviation_usage_logs: AbbreviationUsageLogsRecord
	abbreviations: AbbreviationsRecord
	ai_usage_logs: AiUsageLogsRecord
	authorities: AuthoritiesRecord
	calculator_usage_logs: CalculatorUsageLogsRecord
	calculators: CalculatorsRecord
	consultant_usage_logs: ConsultantUsageLogsRecord
	consultants: ConsultantsRecord
	conversations: ConversationsRecord
	counties: CountiesRecord
	districts: DistrictsRecord
	documentation: DocumentationRecord
	drug_categories: DrugCategoriesRecord
	drug_classes: DrugClassesRecord
	drug_tags: DrugTagsRecord
	drug_usage_logs: DrugUsageLogsRecord
	drugs: DrugsRecord
	emergency_protocols: EmergencyProtocolsRecord
	facility_levels: FacilityLevelsRecord
	facility_usage_logs: FacilityUsageLogsRecord
	faq_tags: FaqTagsRecord
	faqs: FaqsRecord
	generic_pages: GenericPagesRecord
	guideline_categories: GuidelineCategoriesRecord
	guideline_index: GuidelineIndexRecord
	guideline_tags: GuidelineTagsRecord
	guideline_usage_logs: GuidelineUsageLogsRecord
	health_facilities: HealthFacilitiesRecord
	health_sub_districts: HealthSubDistrictsRecord
	health_sub_regions: HealthSubRegionsRecord
	languages: LanguagesRecord
	medical_guidelines: MedicalGuidelinesRecord
	messages: MessagesRecord
	ministry_directory: MinistryDirectoryRecord
	notification_campaigns: NotificationCampaignsRecord
	notification_templates: NotificationTemplatesRecord
	notifications: NotificationsRecord
	ownership_types: OwnershipTypesRecord
	parishes: ParishesRecord
	reading_progress: ReadingProgressRecord
	regions: RegionsRecord
	roles: RolesRecord
	settings: SettingsRecord
	subcounties: SubcountiesRecord
	support_ticket_replies: SupportTicketRepliesRecord
	support_tickets: SupportTicketsRecord
	therapeutic_categories: TherapeuticCategoriesRecord
	users: UsersRecord
}

export type CollectionResponses = {
	_authOrigins: AuthoriginsResponse
	_externalAuths: ExternalauthsResponse
	_mfas: MfasResponse
	_otps: OtpsResponse
	_superusers: SuperusersResponse
	abbreviation_usage_logs: AbbreviationUsageLogsResponse
	abbreviations: AbbreviationsResponse
	ai_usage_logs: AiUsageLogsResponse
	authorities: AuthoritiesResponse
	calculator_usage_logs: CalculatorUsageLogsResponse
	calculators: CalculatorsResponse
	consultant_usage_logs: ConsultantUsageLogsResponse
	consultants: ConsultantsResponse
	conversations: ConversationsResponse
	counties: CountiesResponse
	districts: DistrictsResponse
	documentation: DocumentationResponse
	drug_categories: DrugCategoriesResponse
	drug_classes: DrugClassesResponse
	drug_tags: DrugTagsResponse
	drug_usage_logs: DrugUsageLogsResponse
	drugs: DrugsResponse
	emergency_protocols: EmergencyProtocolsResponse
	facility_levels: FacilityLevelsResponse
	facility_usage_logs: FacilityUsageLogsResponse
	faq_tags: FaqTagsResponse
	faqs: FaqsResponse
	generic_pages: GenericPagesResponse
	guideline_categories: GuidelineCategoriesResponse
	guideline_index: GuidelineIndexResponse
	guideline_tags: GuidelineTagsResponse
	guideline_usage_logs: GuidelineUsageLogsResponse
	health_facilities: HealthFacilitiesResponse
	health_sub_districts: HealthSubDistrictsResponse
	health_sub_regions: HealthSubRegionsResponse
	languages: LanguagesResponse
	medical_guidelines: MedicalGuidelinesResponse
	messages: MessagesResponse
	ministry_directory: MinistryDirectoryResponse
	notification_campaigns: NotificationCampaignsResponse
	notification_templates: NotificationTemplatesResponse
	notifications: NotificationsResponse
	ownership_types: OwnershipTypesResponse
	parishes: ParishesResponse
	reading_progress: ReadingProgressResponse
	regions: RegionsResponse
	roles: RolesResponse
	settings: SettingsResponse
	subcounties: SubcountiesResponse
	support_ticket_replies: SupportTicketRepliesResponse
	support_tickets: SupportTicketsResponse
	therapeutic_categories: TherapeuticCategoriesResponse
	users: UsersResponse
}

// Utility types for create/update operations

type ProcessCreateAndUpdateFields<T> = Omit<{
	// Omit AutoDate fields
	[K in keyof T as Extract<T[K], IsoAutoDateString> extends never ? K : never]: 
		// Convert FileNameString to File
		T[K] extends infer U ? 
			U extends (FileNameString | FileNameString[]) ? 
				U extends any[] ? File[] : File 
			: U
		: never
}, 'id'>

// Create type for Auth collections
export type CreateAuth<T> = {
	id?: RecordIdString
	email: string
	emailVisibility?: boolean
	password: string
	passwordConfirm: string
	verified?: boolean
} & ProcessCreateAndUpdateFields<T>

// Create type for Base collections
export type CreateBase<T> = {
	id?: RecordIdString
} & ProcessCreateAndUpdateFields<T>

// Update type for Auth collections
export type UpdateAuth<T> = Partial<
	Omit<ProcessCreateAndUpdateFields<T>, keyof AuthSystemFields>
> & {
	email?: string
	emailVisibility?: boolean
	oldPassword?: string
	password?: string
	passwordConfirm?: string
	verified?: boolean
}

// Update type for Base collections
export type UpdateBase<T> = Partial<
	Omit<ProcessCreateAndUpdateFields<T>, keyof BaseSystemFields>
>

// Get the correct create type for any collection
export type Create<T extends keyof CollectionResponses> =
	CollectionResponses[T] extends AuthSystemFields
		? CreateAuth<CollectionRecords[T]>
		: CreateBase<CollectionRecords[T]>

// Get the correct update type for any collection
export type Update<T extends keyof CollectionResponses> =
	CollectionResponses[T] extends AuthSystemFields
		? UpdateAuth<CollectionRecords[T]>
		: UpdateBase<CollectionRecords[T]>
