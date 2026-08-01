package handlers

import (
	"encoding/json"

	"mediguide/internal/models"
	"mediguide/internal/services"
)

type RegisterRequest struct {
	Name              string   `json:"name" example:"Admin User"`
	Email             string   `json:"email" example:"admin@mediguide.local"`
	Password          string   `json:"password" example:"Admin123!"`
	Phone             string   `json:"phone" example:"+256700000001"`
	AlternativePhone  string   `json:"alternative_phone" example:"+256700000002"`
	FacilityID        string   `json:"facility_id" example:"3fa85f64-5717-4562-b3fc-2c963f66afa6"`
	Address           string   `json:"address" example:"Plot 12 Kampala Road"`
	City              string   `json:"city" example:"Kampala"`
	Country           string   `json:"country" example:"Uganda"`
	PostalCode        string   `json:"postal_code" example:"256"`
	LicenseNumber     string   `json:"license_number" example:"MD-12345"`
	Organization      string   `json:"organization" example:"Mulago Hospital"`
	Department        string   `json:"department" example:"Emergency"`
	JobTitle          string   `json:"job_title" example:"Medical Officer"`
	PreferredLanguage string   `json:"preferred_language" example:"English"`
	Timezone          string   `json:"timezone" example:"Africa/Kampala"`
	Notes             string   `json:"notes" example:"Night shift clinician"`
	Specialization    []string `json:"specialization" swaggertype:"array,string" example:"Internal Medicine,Pediatrics"`
	Avatar            string   `json:"avatar" example:"https://example.com/avatar.png"`
}

type LoginRequest struct {
	Email    string `json:"email" example:"admin@mediguide.local"`
	Password string `json:"password" example:"Admin123!"`
}

type RefreshRequest struct {
	RefreshToken string `json:"refresh_token" example:"Gm8m3Wq2oJ7l6p4XnYx9QbT2f1WvL0H1v2z3k4m5n6o"`
}

type PasswordResetRequest struct {
	Email string `json:"email" example:"user@example.com"`
}

type PasswordResetConfirmRequest struct {
	Token           string `json:"token"`
	Password        string `json:"password"`
	PasswordConfirm string `json:"password_confirm"`
}

type EmailVerificationRequest struct {
	Email string `json:"email" example:"user@example.com"`
}

type EmailVerificationConfirmRequest struct {
	Token string `json:"token"`
}

type PasswordChangeRequest struct {
	CurrentPassword    string `json:"current_password"`
	NewPassword        string `json:"new_password"`
	NewPasswordConfirm string `json:"new_password_confirm"`
}

type PublishResult struct {
	Published bool `json:"published" example:"true"`
}

type MarkdownUpdateResult struct {
	Updated bool `json:"updated" example:"true"`
	Size    int  `json:"size" example:"1024"`
}

type LogoutResult struct {
	LoggedOut bool `json:"logged_out" example:"true"`
}

type VerificationResult struct {
	Verified bool `json:"verified" example:"true"`
}

type VerificationResultEnvelope struct {
	Success bool               `json:"success" example:"true"`
	Data    VerificationResult `json:"data"`
}

type TagUsageRecalculationResult struct {
	Updated bool `json:"updated" example:"true"`
}

type TagUsageRecalculationEnvelope struct {
	Success bool                        `json:"success" example:"true"`
	Data    TagUsageRecalculationResult `json:"data"`
}

type DownloadURLResult struct {
	URL string `json:"url" example:"https://storage.example.com/path/to/package.zip"`
}

type JSONMap map[string]any

type HealthResult struct {
	OK      bool   `json:"ok" example:"true"`
	Service string `json:"service" example:"mediguide-backend"`
}

type ErrorResponse struct {
	Success bool   `json:"success" example:"false"`
	Error   string `json:"error" example:"invalid request"`
}

type SupportTicketEnvelope struct {
	Success bool                 `json:"success"`
	Data    models.SupportTicket `json:"data"`
}

type SupportReplyEnvelope struct {
	Success bool                      `json:"success"`
	Data    models.SupportTicketReply `json:"data"`
}

type PaginatedSupportTicketsEnvelope struct {
	Success bool                                      `json:"success"`
	Data    services.PageResult[models.SupportTicket] `json:"data"`
}

type PaginatedSupportRepliesEnvelope struct {
	Success bool                                           `json:"success"`
	Data    services.PageResult[models.SupportTicketReply] `json:"data"`
}

type FAQEnvelope struct {
	Success bool       `json:"success"`
	Data    models.FAQ `json:"data"`
}
type FAQTagEnvelope struct {
	Success bool          `json:"success"`
	Data    models.FAQTag `json:"data"`
}
type DocumentationEnvelope struct {
	Success bool                 `json:"success"`
	Data    models.Documentation `json:"data"`
}
type PaginatedFAQsEnvelope struct {
	Success bool                            `json:"success"`
	Data    services.PageResult[models.FAQ] `json:"data"`
}
type PaginatedFAQTagsEnvelope struct {
	Success bool                               `json:"success"`
	Data    services.PageResult[models.FAQTag] `json:"data"`
}
type PaginatedDocumentationEnvelope struct {
	Success bool                                      `json:"success"`
	Data    services.PageResult[models.Documentation] `json:"data"`
}

type UserEnvelope struct {
	Success bool        `json:"success" example:"true"`
	Data    models.User `json:"data"`
}

type UserViewEnvelope struct {
	Success bool              `json:"success" example:"true"`
	Data    services.UserView `json:"data"`
}

type PaginatedUsersEnvelope struct {
	Success bool                                   `json:"success" example:"true"`
	Data    services.PageResult[services.UserView] `json:"data"`
}

type RoleViewEnvelope struct {
	Success bool              `json:"success" example:"true"`
	Data    services.RoleView `json:"data"`
}

type PaginatedRolesEnvelope struct {
	Success bool                                   `json:"success" example:"true"`
	Data    services.PageResult[services.RoleView] `json:"data"`
}

type PermissionsEnvelope struct {
	Success bool                `json:"success" example:"true"`
	Data    []models.Permission `json:"data"`
}

type PermissionDocumentEnvelope struct {
	Success bool            `json:"success" example:"true"`
	Data    json.RawMessage `json:"data" swaggertype:"object"`
}

type RolePermissionsRequest struct {
	Permissions json.RawMessage `json:"permissions" swaggertype:"object"`
}

type LoginEnvelope struct {
	Success bool                 `json:"success" example:"true"`
	Data    services.LoginResult `json:"data"`
}

type LogoutEnvelope struct {
	Success bool         `json:"success" example:"true"`
	Data    LogoutResult `json:"data"`
}

type GuidelineDocumentEnvelope struct {
	Success bool                     `json:"success" example:"true"`
	Data    models.GuidelineDocument `json:"data"`
}

type CalculatorEnvelope struct {
	Success bool              `json:"success" example:"true"`
	Data    models.Calculator `json:"data"`
}

type PaginatedCalculators struct {
	Items      []models.Calculator `json:"items"`
	Page       int                 `json:"page" example:"1"`
	PerPage    int                 `json:"per_page" example:"20"`
	TotalItems int64               `json:"total_items" example:"1"`
	TotalPages int                 `json:"total_pages" example:"1"`
}

type PaginatedCalculatorsEnvelope struct {
	Success bool                 `json:"success" example:"true"`
	Data    PaginatedCalculators `json:"data"`
}

type CalculatorUsageEnvelope struct {
	Success bool                      `json:"success" example:"true"`
	Data    models.CalculatorUsageLog `json:"data"`
}

type DrugEnvelope struct {
	Success bool        `json:"success" example:"true"`
	Data    models.Drug `json:"data"`
}

type PaginatedDrugs struct {
	Items      []models.Drug `json:"items"`
	Page       int           `json:"page" example:"1"`
	PerPage    int           `json:"per_page" example:"20"`
	TotalItems int64         `json:"total_items" example:"1"`
	TotalPages int           `json:"total_pages" example:"1"`
}

type PaginatedDrugsEnvelope struct {
	Success bool           `json:"success" example:"true"`
	Data    PaginatedDrugs `json:"data"`
}

type DrugUsageEnvelope struct {
	Success bool                `json:"success" example:"true"`
	Data    models.DrugUsageLog `json:"data"`
}

type DrugCategoryEnvelope struct {
	Success bool                `json:"success" example:"true"`
	Data    models.DrugCategory `json:"data"`
}

type DrugTagEnvelope struct {
	Success bool           `json:"success" example:"true"`
	Data    models.DrugTag `json:"data"`
}

type DrugClassEnvelope struct {
	Success bool             `json:"success" example:"true"`
	Data    models.DrugClass `json:"data"`
}

type TherapeuticCategoryEnvelope struct {
	Success bool                       `json:"success" example:"true"`
	Data    models.TherapeuticCategory `json:"data"`
}

type PaginatedDrugCategoriesEnvelope struct {
	Success bool `json:"success" example:"true"`
	Data    struct {
		Items      []models.DrugCategory `json:"items"`
		Page       int                   `json:"page"`
		PerPage    int                   `json:"per_page"`
		TotalItems int64                 `json:"total_items"`
		TotalPages int                   `json:"total_pages"`
	} `json:"data"`
}

type PaginatedDrugTagsEnvelope struct {
	Success bool `json:"success" example:"true"`
	Data    struct {
		Items      []models.DrugTag `json:"items"`
		Page       int              `json:"page"`
		PerPage    int              `json:"per_page"`
		TotalItems int64            `json:"total_items"`
		TotalPages int              `json:"total_pages"`
	} `json:"data"`
}

type PaginatedDrugClassesEnvelope struct {
	Success bool `json:"success" example:"true"`
	Data    struct {
		Items      []models.DrugClass `json:"items"`
		Page       int                `json:"page"`
		PerPage    int                `json:"per_page"`
		TotalItems int64              `json:"total_items"`
		TotalPages int                `json:"total_pages"`
	} `json:"data"`
}

type PaginatedTherapeuticCategoriesEnvelope struct {
	Success bool `json:"success" example:"true"`
	Data    struct {
		Items      []models.TherapeuticCategory `json:"items"`
		Page       int                          `json:"page"`
		PerPage    int                          `json:"per_page"`
		TotalItems int64                        `json:"total_items"`
		TotalPages int                          `json:"total_pages"`
	} `json:"data"`
}

type PaginatedGuidelineDocuments struct {
	Items      []models.GuidelineDocument `json:"items"`
	Page       int                        `json:"page" example:"1"`
	PerPage    int                        `json:"per_page" example:"20"`
	TotalItems int64                      `json:"total_items" example:"1"`
	TotalPages int                        `json:"total_pages" example:"1"`
}

type PaginatedGuidelineDocumentsEnvelope struct {
	Success bool                        `json:"success" example:"true"`
	Data    PaginatedGuidelineDocuments `json:"data"`
}

type GuidelineVersionEnvelope struct {
	Success bool                    `json:"success" example:"true"`
	Data    models.GuidelineVersion `json:"data"`
}

type IngestionJobEnvelope struct {
	Success bool                `json:"success" example:"true"`
	Data    models.IngestionJob `json:"data"`
}

type PublishEnvelope struct {
	Success bool          `json:"success" example:"true"`
	Data    PublishResult `json:"data"`
}

type MarkdownUpdateEnvelope struct {
	Success bool                 `json:"success" example:"true"`
	Data    MarkdownUpdateResult `json:"data"`
}

type PaginatedGuidelineSections struct {
	Items      []models.GuidelineSection `json:"items"`
	Page       int                       `json:"page" example:"1"`
	PerPage    int                       `json:"per_page" example:"100"`
	TotalItems int64                     `json:"total_items" example:"1"`
	TotalPages int                       `json:"total_pages" example:"1"`
}

type PaginatedGuidelineSectionsEnvelope struct {
	Success bool                       `json:"success" example:"true"`
	Data    PaginatedGuidelineSections `json:"data"`
}

type PaginatedGuidelineChunks struct {
	Items      []models.GuidelineChunk `json:"items"`
	Page       int                     `json:"page" example:"1"`
	PerPage    int                     `json:"per_page" example:"100"`
	TotalItems int64                   `json:"total_items" example:"1"`
	TotalPages int                     `json:"total_pages" example:"1"`
}

type PaginatedGuidelineChunksEnvelope struct {
	Success bool                     `json:"success" example:"true"`
	Data    PaginatedGuidelineChunks `json:"data"`
}

type SearchResultsEnvelope struct {
	Success bool                    `json:"success" example:"true"`
	Data    []services.SearchResult `json:"data"`
}

type AskEnvelope struct {
	Success bool                 `json:"success" example:"true"`
	Data    services.AskResponse `json:"data"`
}

type ClinicalProtocolEnvelope struct {
	Success bool                    `json:"success" example:"true"`
	Data    models.ClinicalProtocol `json:"data"`
}

type PaginatedClinicalProtocols struct {
	Items      []models.ClinicalProtocol `json:"items"`
	Page       int                       `json:"page" example:"1"`
	PerPage    int                       `json:"per_page" example:"20"`
	TotalItems int64                     `json:"total_items" example:"1"`
	TotalPages int                       `json:"total_pages" example:"1"`
}

type PaginatedClinicalProtocolsEnvelope struct {
	Success bool                       `json:"success" example:"true"`
	Data    PaginatedClinicalProtocols `json:"data"`
}

type ProtocolRunEnvelope struct {
	Success bool                       `json:"success" example:"true"`
	Data    services.RunProtocolResult `json:"data"`
}

type ManifestEnvelope struct {
	Success bool                    `json:"success" example:"true"`
	Data    services.ManifestResult `json:"data"`
}

type SyncPackageEnvelope struct {
	Success bool               `json:"success" example:"true"`
	Data    models.SyncPackage `json:"data"`
}

type SettingEnvelope struct {
	Success bool           `json:"success" example:"true"`
	Data    models.Setting `json:"data"`
}

type PaginatedSettings struct {
	Items      []models.Setting `json:"items"`
	Page       int              `json:"page" example:"1"`
	PerPage    int              `json:"per_page" example:"20"`
	TotalItems int64            `json:"total_items" example:"1"`
	TotalPages int              `json:"total_pages" example:"1"`
}

type PaginatedSettingsEnvelope struct {
	Success bool              `json:"success" example:"true"`
	Data    PaginatedSettings `json:"data"`
}

type LanguageEnvelope struct {
	Success bool            `json:"success" example:"true"`
	Data    models.Language `json:"data"`
}

type PaginatedLanguages struct {
	Items      []models.Language `json:"items"`
	Page       int               `json:"page" example:"1"`
	PerPage    int               `json:"per_page" example:"20"`
	TotalItems int64             `json:"total_items" example:"1"`
	TotalPages int               `json:"total_pages" example:"1"`
}

type PaginatedLanguagesEnvelope struct {
	Success bool               `json:"success" example:"true"`
	Data    PaginatedLanguages `json:"data"`
}

type NotificationEnvelope struct {
	Success bool                `json:"success" example:"true"`
	Data    models.Notification `json:"data"`
}

type PaginatedNotifications struct {
	Items      []models.Notification `json:"items"`
	Page       int                   `json:"page" example:"1"`
	PerPage    int                   `json:"per_page" example:"20"`
	TotalItems int64                 `json:"total_items" example:"1"`
	TotalPages int                   `json:"total_pages" example:"1"`
}

type PaginatedNotificationsEnvelope struct {
	Success bool                   `json:"success" example:"true"`
	Data    PaginatedNotifications `json:"data"`
}

type NotificationTemplateEnvelope struct {
	Success bool                        `json:"success" example:"true"`
	Data    models.NotificationTemplate `json:"data"`
}
type PaginatedNotificationTemplates struct {
	Items      []models.NotificationTemplate `json:"items"`
	Page       int                           `json:"page"`
	PerPage    int                           `json:"per_page"`
	TotalItems int64                         `json:"total_items"`
	TotalPages int                           `json:"total_pages"`
}
type PaginatedNotificationTemplatesEnvelope struct {
	Success bool                           `json:"success"`
	Data    PaginatedNotificationTemplates `json:"data"`
}
type NotificationCampaignEnvelope struct {
	Success bool                        `json:"success"`
	Data    models.NotificationCampaign `json:"data"`
}
type PaginatedNotificationCampaigns struct {
	Items      []models.NotificationCampaign `json:"items"`
	Page       int                           `json:"page"`
	PerPage    int                           `json:"per_page"`
	TotalItems int64                         `json:"total_items"`
	TotalPages int                           `json:"total_pages"`
}
type PaginatedNotificationCampaignsEnvelope struct {
	Success bool                           `json:"success"`
	Data    PaginatedNotificationCampaigns `json:"data"`
}

type LegacyTreeNode = services.TreeNode
type LegacyTreeResult = services.TreeResult
type LegacyOverviewResult = services.OverviewResult
type LegacyStatsResult = services.StatsResult

type ResourceListResult struct {
	Success    bool      `json:"success" example:"true"`
	Collection string    `json:"collection" example:"medical_guidelines"`
	Page       int       `json:"page" example:"1"`
	PerPage    int       `json:"per_page" example:"20"`
	TotalItems int64     `json:"total_items" example:"1"`
	Items      []JSONMap `json:"items"`
}

type ResourceItemResult struct {
	Success    bool    `json:"success" example:"true"`
	Collection string  `json:"collection" example:"medical_guidelines"`
	Item       JSONMap `json:"item"`
}

type DownloadURLEnvelope struct {
	Success bool              `json:"success" example:"true"`
	Data    DownloadURLResult `json:"data"`
}

type UserResponse = models.User
type GuidelineDocumentResponse = models.GuidelineDocument
type GuidelineVersionResponse = models.GuidelineVersion
type GuidelineSectionResponse = models.GuidelineSection
type GuidelineChunkResponse = models.GuidelineChunk
type IngestionJobResponse = models.IngestionJob
type ClinicalProtocolResponse = models.ClinicalProtocol
type SyncPackageResponse = models.SyncPackage
type LoginResult = services.LoginResult
type GuidelineInput = services.CreateGuidelineInput
type GuidelineVersionInput = services.CreateVersionInput
type AskRequest = services.AskRequest
type AskResponse = services.AskResponse
type CreateProtocolInput = services.CreateProtocolInput
type RunProtocolResult = services.RunProtocolResult
type CreateSyncPackageInput = services.CreateSyncPackageInput
type ManifestResult = services.ManifestResult
type CreateSettingInput = services.CreateSettingInput
type CreateLanguageInput = services.CreateLanguageInput
