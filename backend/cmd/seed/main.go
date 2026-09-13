package main

import (
	"context"
	"encoding/csv"
	"encoding/json"
	"errors"
	"fmt"
	"net/mail"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"
	"unicode"

	"mediguide/internal/clinicaltools"
	"mediguide/internal/config"
	"mediguide/internal/db"
	"mediguide/internal/models"
	"mediguide/internal/security"
	"mediguide/internal/storage"

	"github.com/google/uuid"
	"github.com/rs/zerolog/log"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

var (
	regionID                = uuid.MustParse("11111111-1111-1111-1111-111111111111")
	healthSubRegionID       = uuid.MustParse("11111111-1111-1111-1111-111111111112")
	districtID              = uuid.MustParse("11111111-1111-1111-1111-111111111113")
	countyID                = uuid.MustParse("11111111-1111-1111-1111-111111111114")
	healthSubDistrictID     = uuid.MustParse("11111111-1111-1111-1111-111111111115")
	subcountyID             = uuid.MustParse("11111111-1111-1111-1111-111111111116")
	facilityLevelHC3ID      = uuid.MustParse("11111111-1111-1111-1111-111111111118")
	facilityLevelHospitalID = uuid.MustParse("11111111-1111-1111-1111-111111111119")
	ownershipTypeGovID      = uuid.MustParse("11111111-1111-1111-1111-111111111120")
	authorityMOHID          = uuid.MustParse("11111111-1111-1111-1111-111111111121")
	authorityDistrictID     = uuid.MustParse("11111111-1111-1111-1111-111111111122")
	facilityID              = uuid.MustParse("11111111-1111-1111-1111-111111111123")
	referralFacilityID      = uuid.MustParse("11111111-1111-1111-1111-111111111124")
	guidelineCategoryID     = uuid.MustParse("11111111-1111-1111-1111-111111111125")
	guidelineTagID          = uuid.MustParse("11111111-1111-1111-1111-111111111126")
	guidelineIndexID        = uuid.MustParse("11111111-1111-1111-1111-111111111127")
	medicalGuidelineID      = uuid.MustParse("11111111-1111-1111-1111-111111111128")
	drugCategoryID          = uuid.MustParse("11111111-1111-1111-1111-111111111129")
	drugTagID               = uuid.MustParse("11111111-1111-1111-1111-111111111130")
	drugClassID             = uuid.MustParse("11111111-1111-1111-1111-111111111131")
	therapeuticCategoryID   = uuid.MustParse("11111111-1111-1111-1111-111111111132")
	drugID                  = uuid.MustParse("11111111-1111-1111-1111-111111111133")
	calculatorID            = uuid.MustParse("11111111-1111-1111-1111-111111111134")
	abbreviationID          = uuid.MustParse("11111111-1111-1111-1111-111111111135")
	emergencyProtocolID     = uuid.MustParse("11111111-1111-1111-1111-111111111136")
	genericPageID           = uuid.MustParse("11111111-1111-1111-1111-111111111137")
	faqTagID                = uuid.MustParse("11111111-1111-1111-1111-111111111138")
	faqID                   = uuid.MustParse("11111111-1111-1111-1111-111111111139")
	documentationID         = uuid.MustParse("11111111-1111-1111-1111-111111111140")
	settingID               = uuid.MustParse("11111111-1111-1111-1111-111111111141")
	languageENID            = uuid.MustParse("11111111-1111-1111-1111-111111111142")
	languageSWID            = uuid.MustParse("11111111-1111-1111-1111-111111111143")
	consultantOneID         = uuid.MustParse("11111111-1111-1111-1111-111111111144")
	consultantTwoID         = uuid.MustParse("11111111-1111-1111-1111-111111111145")
	ministryDirectoryID     = uuid.MustParse("11111111-1111-1111-1111-111111111146")
	notificationID          = uuid.MustParse("11111111-1111-1111-1111-111111111147")
	notificationTemplateID  = uuid.MustParse("11111111-1111-1111-1111-111111111148")
	notificationCampaignID  = uuid.MustParse("11111111-1111-1111-1111-111111111149")
	supportTicketID         = uuid.MustParse("11111111-1111-1111-1111-111111111150")
	supportReplyID          = uuid.MustParse("11111111-1111-1111-1111-111111111151")
	conversationID          = uuid.MustParse("11111111-1111-1111-1111-111111111152")
	messageID               = uuid.MustParse("11111111-1111-1111-1111-111111111153")
	guidelineDocumentID     = uuid.MustParse("11111111-1111-1111-1111-111111111154")
	guidelineVersionID      = uuid.MustParse("11111111-1111-1111-1111-111111111155")
	guidelineSectionIntroID = uuid.MustParse("11111111-1111-1111-1111-111111111164")
	guidelineSectionMgmtID  = uuid.MustParse("11111111-1111-1111-1111-111111111165")
	guidelineChunkIntroID   = uuid.MustParse("11111111-1111-1111-1111-111111111166")
	guidelineChunkTreatID   = uuid.MustParse("11111111-1111-1111-1111-111111111167")
	guidelineTableID        = uuid.MustParse("11111111-1111-1111-1111-111111111168")
	guidelineIngestionJobID = uuid.MustParse("11111111-1111-1111-1111-111111111169")
	readingProgressID       = uuid.MustParse("11111111-1111-1111-1111-111111111156")
	calculatorUsageLogID    = uuid.MustParse("11111111-1111-1111-1111-111111111157")
	guidelineUsageLogID     = uuid.MustParse("11111111-1111-1111-1111-111111111158")
	drugUsageLogID          = uuid.MustParse("11111111-1111-1111-1111-111111111159")
	abbreviationUsageLogID  = uuid.MustParse("11111111-1111-1111-1111-111111111160")
	consultantUsageLogID    = uuid.MustParse("11111111-1111-1111-1111-111111111161")
	facilityUsageLogID      = uuid.MustParse("11111111-1111-1111-1111-111111111162")
	aiUsageLogID            = uuid.MustParse("11111111-1111-1111-1111-111111111163")
)

var seedIDAliases = map[uuid.UUID]uuid.UUID{}

func main() {
	cfg := config.Load()
	database, err := db.Connect(cfg.DatabaseURL)
	if err != nil {
		log.Fatal().Err(err).Msg("db connect failed")
	}

	scope := strings.ToLower(strings.TrimSpace(os.Getenv("SEED_SCOPE")))
	switch scope {
	case "clinical-tools-rehearsal":
		if err := clinicaltools.ValidateRehearsalTarget(cfg.DatabaseURL, cfg.AppEnv, os.Getenv("COMPOSE_PROJECT_NAME"), os.Getenv("CLINICAL_TOOLS_REHEARSAL")); err != nil {
			log.Fatal().Err(err).Msg("unsafe clinical-tool rehearsal seed target")
		}
		admin, _, _, err := seedSecurity(database)
		if err != nil {
			log.Fatal().Err(err).Msg("seed rehearsal actors failed")
		}
		if err = database.Transaction(func(tx *gorm.DB) error { return seedDemoCalculators(tx, admin.ID) }); err != nil {
			log.Fatal().Err(err).Msg("seed rehearsal calculators failed")
		}
		log.Info().Msg("clinical-tool rehearsal seed completed")
		return
	case "admin":
		input, err := productionAdminInputFromEnv()
		if err != nil {
			log.Fatal().Err(err).Msg("invalid production admin configuration")
		}
		if err := database.Transaction(func(tx *gorm.DB) error {
			return seedProductionAdmin(tx, input)
		}); err != nil {
			log.Fatal().Err(err).Msg("production admin seed failed")
		}
		log.Info().Str("email", input.Email).Msg("production admin seed completed")
		return
	case "facilities":
		if err := database.Transaction(func(tx *gorm.DB) error {
			return seedLegacyData(tx, nil, nil)
		}); err != nil {
			log.Fatal().Err(err).Msg("facility reference seed failed")
		}
		log.Info().Msg("facility reference seed completed")
		return
	case "notifications":
		if strings.EqualFold(cfg.AppEnv, "production") {
			log.Fatal().Msg("demo notification seeding is disabled in production")
		}
		var clinician models.User
		if err := database.Where("email = ?", "clinician@mediguide.local").First(&clinician).Error; err != nil {
			log.Fatal().Err(err).Msg("notification seed user lookup failed")
		}
		if err := database.Transaction(func(tx *gorm.DB) error {
			return seedDemoNotifications(tx, clinician.ID)
		}); err != nil {
			log.Fatal().Err(err).Msg("seed notification data failed")
		}
		log.Info().Msg("notification seed completed")
		return
	case "outbreaks":
		if strings.EqualFold(cfg.AppEnv, "production") {
			log.Fatal().Msg("demo outbreak seeding is disabled in production")
		}
		admin, clinician, _, err := seedSecurity(database)
		if err != nil {
			log.Fatal().Err(err).Msg("seed outbreak actors failed")
		}
		store, err := storage.NewMinioStore(cfg)
		if err != nil {
			log.Fatal().Err(err).Msg("seed outbreak object storage connection failed")
		}
		if err := database.Transaction(func(tx *gorm.DB) error {
			return seedDemoOutbreaks(context.Background(), tx, store, admin.ID, clinician.ID)
		}); err != nil {
			log.Fatal().Err(err).Msg("seed outbreak data failed")
		}
		log.Info().Msg("outbreak demo seed completed")
		return
	case "", "demo":
		if strings.EqualFold(cfg.AppEnv, "production") && !strings.EqualFold(strings.TrimSpace(os.Getenv("SEED_ALLOW_DEMO")), "true") {
			log.Fatal().Msg("demo seeding is disabled in production; use SEED_SCOPE=admin or SEED_SCOPE=facilities")
		}
	default:
		log.Fatal().Str("scope", scope).Msg("unsupported seed scope")
	}

	admin, clinician, reviewer, err := seedSecurity(database)
	if err != nil {
		log.Fatal().Err(err).Msg("seed security failed")
	}
	if err := seedLegacyData(database, admin, clinician); err != nil {
		log.Fatal().Err(err).Msg("seed legacy data failed")
	}
	if err := database.Transaction(func(tx *gorm.DB) error {
		return seedDemoNotifications(tx, clinician.ID)
	}); err != nil {
		log.Fatal().Err(err).Msg("seed notification data failed")
	}
	store, err := storage.NewMinioStore(cfg)
	if err != nil {
		log.Fatal().Err(err).Msg("seed object storage connection failed")
	}
	if err := seedDemoData(context.Background(), database, store, admin, clinician, reviewer); err != nil {
		log.Fatal().Err(err).Msg("seed demo data failed")
	}

	log.Info().Msg("seed completed")
}

type productionAdminInput struct {
	Name          string
	Email         string
	Password      string
	ResetPassword bool
}

func productionAdminInputFromEnv() (productionAdminInput, error) {
	input := productionAdminInput{
		Name:          strings.TrimSpace(os.Getenv("DEFAULT_ADMIN_NAME")),
		Email:         strings.ToLower(strings.TrimSpace(os.Getenv("DEFAULT_ADMIN_EMAIL"))),
		Password:      os.Getenv("DEFAULT_ADMIN_PASSWORD"),
		ResetPassword: strings.EqualFold(strings.TrimSpace(os.Getenv("SEED_ADMIN_RESET_PASSWORD")), "true"),
	}
	if input.Name == "" {
		input.Name = "MediGuide Administrator"
	}
	if input.Email == "" || input.Password == "" {
		return productionAdminInput{}, fmt.Errorf("DEFAULT_ADMIN_EMAIL and DEFAULT_ADMIN_PASSWORD are required")
	}
	parsed, err := mail.ParseAddress(input.Email)
	if err != nil || !strings.EqualFold(parsed.Address, input.Email) {
		return productionAdminInput{}, fmt.Errorf("DEFAULT_ADMIN_EMAIL is invalid")
	}
	if err := validateBootstrapPassword(input.Password); err != nil {
		return productionAdminInput{}, err
	}
	return input, nil
}

func validateBootstrapPassword(password string) error {
	if len(password) < 12 {
		return fmt.Errorf("DEFAULT_ADMIN_PASSWORD must contain at least 12 characters")
	}
	var upper, lower, digit, symbol bool
	for _, character := range password {
		switch {
		case unicode.IsUpper(character):
			upper = true
		case unicode.IsLower(character):
			lower = true
		case unicode.IsDigit(character):
			digit = true
		case unicode.IsPunct(character) || unicode.IsSymbol(character):
			symbol = true
		}
	}
	if !upper || !lower || !digit || !symbol {
		return fmt.Errorf("DEFAULT_ADMIN_PASSWORD must include uppercase, lowercase, numeric, and symbol characters")
	}
	return nil
}

type seedAuthorizationState struct {
	AdminRole     models.Role
	ClinicianRole models.Role
	ReviewerRole  models.Role
}

func seedAuthorization(database *gorm.DB) (seedAuthorizationState, error) {
	permissions := []models.Permission{
		{Code: "guideline.read", Name: "Read guidelines"},
		{Code: "guideline.write", Name: "Create/update guidelines"},
		{Code: "guideline.publish", Name: "Publish guidelines"},
		{Code: "guideline.markdown.read", Name: "Read private guideline Markdown drafts and revisions"},
		{Code: "guideline.markdown.edit", Name: "Edit guideline Markdown drafts"},
		{Code: "guideline.markdown.upload", Name: "Upload guideline Markdown and source documents"},
		{Code: "guideline.asset.manage", Name: "Manage private guideline assets"},
		{Code: "guideline.structure.regenerate", Name: "Regenerate structured guideline content"},
		{Code: "guideline.review", Name: "Review guidelines"},
		{Code: "guideline.high_risk.approve", Name: "Approve high-risk guideline content"},
		{Code: "guideline.revision.restore", Name: "Restore guideline revisions"},
		{Code: "protocol.read", Name: "Read protocols"},
		{Code: "protocol.write", Name: "Create/update protocols"},
		{Code: "chat.ask", Name: "Ask RAG chatbot"},
		{Code: "calculator.read", Name: "Read clinical tools"},
		{Code: "calculator.write", Name: "Author clinical tools"},
		{Code: "calculator.review", Name: "Review clinical tools"},
		{Code: "calculator.publish", Name: "Publish clinical tools"},
		{Code: "calculator.withdraw", Name: "Withdraw clinical tools"},
		{Code: "sync.read", Name: "Read sync packages"},
		{Code: "notification.read", Name: "Read own and global notifications"},
		{Code: "notification.compose", Name: "Compose notification drafts"},
		{Code: "notification.publish", Name: "Publish in-app notifications"},
		{Code: "notification.template.read", Name: "Read notification templates"},
		{Code: "notification.template.manage", Name: "Manage notification templates"},
		{Code: "notification.campaign.read", Name: "Read notification campaigns"},
		{Code: "notification.campaign.manage", Name: "Manage notification campaigns"},
		{Code: "notification.campaign.approve", Name: "Approve notification campaigns"},
		{Code: "notification.analytics.read", Name: "Read notification analytics"},
		{Code: "firebase.status.read", Name: "Read Firebase integration status"},
		{Code: "firebase.push.test", Name: "Send Firebase test pushes"},
		{Code: "firebase.config.manage", Name: "Manage Firebase Remote Config"},
		{Code: "admin.all", Name: "All administration permissions"},
		{Code: "disease.taxonomy.read", Name: "Read the disease taxonomy"},
		{Code: "disease.taxonomy.manage", Name: "Manage diseases, aliases and codes"},
		{Code: "disease.assignment.read", Name: "Read disease-content assignments"},
		{Code: "disease.assignment.manage", Name: "Manage disease-content assignments"},
		{Code: "content_hub.read", Name: "Read content hub administration data"},
		{Code: "content_hub.manage", Name: "Manage content hub metadata and disease relationships"},
		{Code: "content_hub.publish", Name: "Publish content hubs"},
		{Code: "content_hub.archive", Name: "Archive content hubs"},
		{Code: "content_pillar.read", Name: "Read content pillars and assignments"},
		{Code: "content_pillar.manage", Name: "Manage content pillars and assignments"},
		{Code: "content_hub.template.read", Name: "Read content hub templates"},
		{Code: "content_hub.template.manage", Name: "Apply and manage content hub templates"},
	}
	for i := range permissions {
		if err := database.Where(models.Permission{Code: permissions[i].Code}).Assign(permissions[i]).FirstOrCreate(&permissions[i]).Error; err != nil {
			return seedAuthorizationState{}, err
		}
	}
	permissionByCode := make(map[string]models.Permission, len(permissions))
	for _, permission := range permissions {
		permissionByCode[permission.Code] = permission
	}

	adminRoleKey := "admin"
	adminRole, err := ensureRole(database, adminRoleKey, models.Role{
		Name:        "admin",
		RoleKey:     &adminRoleKey,
		Description: "System administrator",
		IsActive:    true,
	})
	if err != nil {
		return seedAuthorizationState{}, err
	}
	if err := database.Model(&adminRole).Association("Permissions").Replace(&permissions); err != nil {
		return seedAuthorizationState{}, err
	}

	clinicianRoleKey := "healthcare_provider"
	clinicianRole, err := ensureRole(database, clinicianRoleKey, models.Role{
		Name:        "clinician",
		RoleKey:     &clinicianRoleKey,
		Description: "Frontline clinician",
		IsActive:    true,
	})
	if err != nil {
		return seedAuthorizationState{}, err
	}
	clinicianPerms := []models.Permission{
		permissions[0],
		permissions[3],
		permissions[5],
		permissions[6],
	}
	if err := database.Model(&clinicianRole).Association("Permissions").Replace(&clinicianPerms); err != nil {
		return seedAuthorizationState{}, err
	}

	reviewerRoleKey := "reviewer"
	reviewerRole, err := ensureRole(database, reviewerRoleKey, models.Role{
		Name:        "reviewer",
		RoleKey:     &reviewerRoleKey,
		Description: "Clinical guideline reviewer",
		IsActive:    true,
	})
	if err != nil {
		return seedAuthorizationState{}, err
	}
	reviewerPerms := make([]models.Permission, 0)
	for _, code := range deriveBackendPermissions(reviewerRoleKey, "") {
		if permission, ok := permissionByCode[code]; ok {
			reviewerPerms = append(reviewerPerms, permission)
		}
	}
	if err := database.Model(&reviewerRole).Association("Permissions").Replace(&reviewerPerms); err != nil {
		return seedAuthorizationState{}, err
	}
	if err := syncImportedRolePermissions(database, permissionByCode); err != nil {
		return seedAuthorizationState{}, err
	}
	return seedAuthorizationState{AdminRole: adminRole, ClinicianRole: clinicianRole, ReviewerRole: reviewerRole}, nil
}

func seedProductionAdmin(database *gorm.DB, input productionAdminInput) error {
	authorization, err := seedAuthorization(database)
	if err != nil {
		return err
	}

	var user models.User
	err = database.Where("LOWER(email) = ?", input.Email).First(&user).Error
	switch {
	case errors.Is(err, gorm.ErrRecordNotFound):
		hash, hashErr := security.HashPassword(input.Password)
		if hashErr != nil {
			return hashErr
		}
		user = models.User{
			Name:         input.Name,
			Email:        input.Email,
			PasswordHash: hash,
			IsActive:     true,
			Verified:     true,
			Status:       "active",
		}
		if err := database.Create(&user).Error; err != nil {
			return err
		}
	case err != nil:
		return err
	default:
		updates := map[string]any{"is_active": true, "verified": true, "status": "active"}
		if strings.TrimSpace(user.Name) == "" {
			updates["name"] = input.Name
		}
		if input.ResetPassword {
			hash, hashErr := security.HashPassword(input.Password)
			if hashErr != nil {
				return hashErr
			}
			updates["password_hash"] = hash
			now := time.Now().UTC()
			if err := database.Model(&models.AuthSession{}).
				Where("user_id = ? AND revoked_at IS NULL", user.ID).
				Update("revoked_at", now).Error; err != nil {
				return err
			}
		}
		if err := database.Model(&user).Updates(updates).Error; err != nil {
			return err
		}
	}

	return database.Model(&user).Association("Roles").Append(&authorization.AdminRole)
}

func seedSecurity(database *gorm.DB) (*models.User, *models.User, *models.User, error) {
	authorization, err := seedAuthorization(database)
	if err != nil {
		return nil, nil, nil, err
	}
	adminRole := authorization.AdminRole
	clinicianRole := authorization.ClinicianRole
	reviewerRole := authorization.ReviewerRole

	adminHash, err := security.HashPassword("Admin123!")
	if err != nil {
		return nil, nil, nil, err
	}
	admin := models.User{Email: "admin@mediguide.health.go.ug"}
	if err := database.Where(models.User{Email: admin.Email}).Assign(models.User{
		Name:         "MediGuide Admin",
		Email:        admin.Email,
		Phone:        "+256700000001",
		PasswordHash: adminHash,
		IsActive:     true,
		Verified:     true,
		Status:       "active",
	}).FirstOrCreate(&admin).Error; err != nil {
		return nil, nil, nil, err
	}
	if err := database.Model(&admin).Association("Roles").Replace(&adminRole); err != nil {
		return nil, nil, nil, err
	}

	clinicianHash, err := security.HashPassword("Clinician123!")
	if err != nil {
		return nil, nil, nil, err
	}
	clinician := models.User{Email: "clinician@mediguide.health.go.ug"}
	preferredLanguage := "English"
	organization := "Kampala Central Health Centre III"
	specialization := "General Practice"
	if err := database.Where(models.User{Email: clinician.Email}).Assign(models.User{
		Name:              "MediGuide Clinician",
		Email:             clinician.Email,
		Phone:             "+256700000002",
		PasswordHash:      clinicianHash,
		IsActive:          true,
		Verified:          true,
		Status:            "active",
		Organization:      &organization,
		PreferredLanguage: &preferredLanguage,
		Specialization:    models.StringList{specialization},
	}).FirstOrCreate(&clinician).Error; err != nil {
		return nil, nil, nil, err
	}
	if err := database.Model(&clinician).Association("Roles").Replace(&clinicianRole); err != nil {
		return nil, nil, nil, err
	}

	reviewerHash, err := security.HashPassword("Reviewer123!")
	if err != nil {
		return nil, nil, nil, err
	}
	reviewer := models.User{Email: "reviewer@mediguide.health.go.ug"}
	reviewerOrganization := "Ministry of Health Uganda"
	reviewerSpecialization := "Public Health"
	if err := database.Where(models.User{Email: reviewer.Email}).Assign(models.User{
		Name:              "Dr. Amina Clinical Reviewer",
		Email:             reviewer.Email,
		Phone:             "+256700000004",
		PasswordHash:      reviewerHash,
		IsActive:          true,
		Verified:          true,
		Status:            "active",
		Organization:      &reviewerOrganization,
		PreferredLanguage: &preferredLanguage,
		Specialization:    models.StringList{reviewerSpecialization},
	}).FirstOrCreate(&reviewer).Error; err != nil {
		return nil, nil, nil, err
	}
	if err := database.Model(&reviewer).Association("Roles").Replace(&reviewerRole); err != nil {
		return nil, nil, nil, err
	}

	assistantHash, err := security.HashPassword("Assistant123!")
	if err != nil {
		return nil, nil, nil, err
	}
	assistant := models.User{Email: "assistant@mediguide.health.go.ug"}
	assistantOrg := "MediGuide"
	if err := database.Where(models.User{Email: assistant.Email}).Assign(models.User{
		Name:         "MediGuide AI",
		Email:        assistant.Email,
		Phone:        "+256700000003",
		PasswordHash: assistantHash,
		IsActive:     true,
		Verified:     true,
		Status:       "active",
		Organization: &assistantOrg,
	}).FirstOrCreate(&assistant).Error; err != nil {
		return nil, nil, nil, err
	}
	if err := database.Model(&assistant).Association("Roles").Replace(&clinicianRole); err != nil {
		return nil, nil, nil, err
	}

	return &admin, &clinician, &reviewer, nil
}

func syncImportedRolePermissions(database *gorm.DB, permissionByCode map[string]models.Permission) error {
	var roles []models.Role
	if err := database.Find(&roles).Error; err != nil {
		return err
	}

	for _, role := range roles {
		roleKey := ""
		if role.RoleKey != nil {
			roleKey = strings.TrimSpace(*role.RoleKey)
		}

		codes := deriveBackendPermissions(roleKey, string(role.PermissionsJSON))
		if len(codes) == 0 {
			continue
		}

		mapped := make([]models.Permission, 0, len(codes))
		for _, code := range codes {
			permission, ok := permissionByCode[code]
			if !ok {
				continue
			}
			mapped = append(mapped, permission)
		}
		if len(mapped) == 0 {
			continue
		}

		if err := database.Model(&role).Association("Permissions").Replace(&mapped); err != nil {
			return err
		}
	}

	return nil
}

func deriveBackendPermissions(roleKey, permissionsJSON string) []string {
	switch roleKey {
	case "super_admin", "admin":
		return []string{
			"admin.all",
			"chat.ask",
			"calculator.read", "calculator.write", "calculator.review", "calculator.publish", "calculator.withdraw",
			"guideline.publish",
			"guideline.read",
			"guideline.write",
			"guideline.markdown.read", "guideline.markdown.edit", "guideline.markdown.upload",
			"guideline.asset.manage", "guideline.structure.regenerate", "guideline.review",
			"guideline.high_risk.approve", "guideline.revision.restore",
			"protocol.read",
			"protocol.write",
			"sync.read",
			"notification.read", "notification.compose", "notification.publish",
			"notification.template.read", "notification.template.manage",
			"notification.campaign.read", "notification.campaign.manage",
			"notification.campaign.approve", "notification.analytics.read",
			"firebase.status.read", "firebase.push.test", "firebase.config.manage",
			"disease.taxonomy.read", "disease.taxonomy.manage", "disease.assignment.read", "disease.assignment.manage",
			"content_hub.read", "content_hub.manage", "content_hub.publish", "content_hub.archive",
			"content_pillar.read", "content_pillar.manage", "content_hub.template.read", "content_hub.template.manage",
		}
	case "content_manager":
		return []string{
			"chat.ask",
			"calculator.read", "calculator.write",
			"guideline.publish",
			"guideline.read",
			"guideline.write",
			"guideline.markdown.read", "guideline.markdown.edit", "guideline.markdown.upload",
			"guideline.asset.manage", "guideline.structure.regenerate", "guideline.review",
			"guideline.revision.restore",
			"protocol.read",
			"protocol.write",
			"sync.read",
			"notification.read", "notification.compose",
			"notification.template.read", "notification.template.manage",
			"notification.campaign.read", "notification.campaign.manage",
			"firebase.status.read",
			"disease.taxonomy.read", "disease.taxonomy.manage", "disease.assignment.read", "disease.assignment.manage",
			"content_hub.read", "content_hub.manage", "content_pillar.read", "content_pillar.manage",
			"content_hub.template.read", "content_hub.template.manage",
		}
	case "reviewer":
		return []string{
			"chat.ask", "calculator.read", "calculator.review", "guideline.publish", "guideline.read", "guideline.markdown.read",
			"guideline.review", "guideline.high_risk.approve", "protocol.read", "sync.read",
			"notification.read", "notification.template.read", "notification.campaign.read",
			"notification.campaign.approve", "notification.analytics.read", "firebase.status.read",
			"disease.taxonomy.read", "disease.assignment.read", "content_hub.read", "content_pillar.read", "content_hub.template.read",
		}
	case "healthcare_provider":
		return []string{
			"chat.ask",
			"calculator.read",
			"guideline.read",
			"protocol.read",
			"sync.read",
			"notification.read",
		}
	case "observer":
		return []string{
			"calculator.read",
			"guideline.read",
			"protocol.read",
			"sync.read",
			"notification.read",
		}
	}

	var payload map[string]map[string][]string
	if err := json.Unmarshal([]byte(permissionsJSON), &payload); err != nil {
		return nil
	}

	perms := map[string]bool{}
	for resource, actions := range payload {
		_, hasReadAny := actions["read:any"]
		_, hasReadOwn := actions["read:own"]
		_, hasCreateAny := actions["create:any"]
		_, hasUpdateAny := actions["update:any"]
		_, hasDeleteAny := actions["delete:any"]

		switch resource {
		case "content":
			if hasReadAny || hasReadOwn {
				perms["guideline.read"] = true
				perms["protocol.read"] = true
			}
			if hasCreateAny || hasUpdateAny || hasDeleteAny {
				perms["guideline.write"] = true
				perms["guideline.publish"] = true
				perms["protocol.write"] = true
			}
		case "reports":
			if hasReadAny || hasReadOwn {
				perms["sync.read"] = true
			}
		}
	}

	if len(perms) == 0 {
		return nil
	}

	result := make([]string, 0, len(perms))
	for code := range perms {
		result = append(result, code)
	}
	sort.Strings(result)
	return result
}

func ensureRole(database *gorm.DB, roleKey string, desired models.Role) (models.Role, error) {
	role := models.Role{}
	err := database.
		Where("role_key = ?", roleKey).
		Or("name = ?", desired.Name).
		First(&role).Error
	if err != nil && err != gorm.ErrRecordNotFound {
		return models.Role{}, err
	}

	if err == gorm.ErrRecordNotFound {
		role = desired
		if err := database.Create(&role).Error; err != nil {
			return models.Role{}, err
		}
		return role, nil
	}

	updates := map[string]any{
		"description": desired.Description,
		"is_active":   desired.IsActive,
	}
	if role.RoleKey == nil || strings.TrimSpace(*role.RoleKey) == "" {
		updates["role_key"] = roleKey
	}
	if err := database.Model(&role).Updates(updates).Error; err != nil {
		return models.Role{}, err
	}
	if err := database.First(&role, "id = ?", role.ID).Error; err != nil {
		return models.Role{}, err
	}
	return role, nil
}

func seedLegacyData(database *gorm.DB, _ *models.User, _ *models.User) error {
	// Seed only facility-related baseline data:
	// - normalize facility level aliases
	// - seed ownership types and authorities used by facilities
	// - seed facility hierarchy and health facilities from the master CSV
	if err := harmonizeFacilityLevels(database); err != nil {
		return err
	}
	if strings.EqualFold(strings.TrimSpace(os.Getenv("SEED_SKIP_MASTER_FACILITIES")), "true") {
		log.Info().Msg("skipped master facility import by request")
		return nil
	}
	return seedMasterFacilities(database)
}

type masterFacilityRow struct {
	OrganisationUnitID string
	UID                string
	Name               string
	ShortName          string
	NHFRID             string
	SubcountyUID       string
	Subcounty          string
	AdminUnitUID       string
	AdminUnit          string
	DistrictUID        string
	District           string
	RegionUID          string
	Region             string
	HFLevel            string
	Ownership          string
	Status             string
	Reporting          string
}

func seedMasterFacilities(database *gorm.DB) error {
	rows, err := loadMasterFacilityRows()
	if err != nil {
		return err
	}

	ownershipTypeIDs := map[string]uuid.UUID{}
	for _, ownership := range []struct {
		ID   uuid.UUID
		Code string
		Name string
	}{
		{ID: ownershipTypeGovID, Code: "GOV", Name: "Government"},
		{ID: masterDataUUID("ownership-type", "PNFP"), Code: "PNFP", Name: "Private Not For Profit"},
		{ID: masterDataUUID("ownership-type", "PFP"), Code: "PFP", Name: "Private For Profit"},
		{ID: masterDataUUID("ownership-type", "UNK"), Code: "UNK", Name: "Unknown Ownership"},
	} {
		id := ownership.ID
		ownershipTypeIDs[ownership.Code] = id
		if err := upsertByID(database, "ownership_types", map[string]any{
			"id":   id,
			"code": ownership.Code,
			"name": ownership.Name,
		}); err != nil {
			return err
		}
	}

	levelNames := map[string]string{
		"HCII":     "Health Centre II",
		"HCIII":    "Health Centre III",
		"HCIV":     "Health Centre IV",
		"HOSP":     "Hospital",
		"CLINIC":   "Clinic",
		"DRUGSHOP": "Drug Shop",
		"RRH":      "Regional Referral Hospital",
		"NRH":      "National Referral Hospital",
		"RBB":      "Regional Blood Bank",
		"NBB":      "National Blood Bank",
		"BCDP":     "Blood Collection and Distribution Point",
	}
	seededLevels := map[string]uuid.UUID{}
	seededAuthorities := map[string]uuid.UUID{}

	for _, row := range rows {
		regionUID := strings.TrimSpace(row.RegionUID)
		districtUID := strings.TrimSpace(row.DistrictUID)
		adminUID := strings.TrimSpace(row.AdminUnitUID)
		subcountyUID := strings.TrimSpace(row.SubcountyUID)
		facilityUID := strings.TrimSpace(row.UID)
		regionName := strings.TrimSpace(row.Region)
		districtName := strings.TrimSpace(row.District)
		adminName := strings.TrimSpace(row.AdminUnit)
		subcountyName := strings.TrimSpace(row.Subcounty)
		facilityName := strings.TrimSpace(row.Name)
		if regionUID == "" || districtUID == "" || adminUID == "" || subcountyUID == "" || facilityUID == "" {
			continue
		}
		if regionName == "" || districtName == "" || adminName == "" || subcountyName == "" || facilityName == "" {
			continue
		}

		regionID := masterDataUUID("region", regionUID)
		healthSubRegionID := masterDataUUID("health-sub-region", regionUID)
		districtID := masterDataUUID("district", districtUID)
		countyID := masterDataUUID("county", adminUID)
		healthSubDistrictID := masterDataUUID("health-sub-district", adminUID)
		subcountyID := masterDataUUID("subcounty", subcountyUID)
		facilityID := masterDataUUID("facility", facilityUID)

		if err := upsertByID(database, "regions", map[string]any{
			"id":        regionID,
			"name":      regionName,
			"nhpi_code": "REG-" + regionUID,
			"hsdt_code": "HSDT-REG-" + regionUID,
		}); err != nil {
			return err
		}
		if err := upsertByID(database, "health_sub_regions", map[string]any{
			"id":        healthSubRegionID,
			"region_id": regionID,
			"name":      regionName,
			"nhpi_code": "HSR-" + regionUID,
			"hsdt_code": "HSDT-HSR-" + regionUID,
		}); err != nil {
			return err
		}
		if err := upsertByID(database, "districts", map[string]any{
			"id":                   districtID,
			"health_sub_region_id": healthSubRegionID,
			"region_id":            regionID,
			"name":                 districtName,
			"nhpi_code":            "DST-" + districtUID,
			"hsdt_code":            "HSDT-DST-" + districtUID,
		}); err != nil {
			return err
		}
		if err := upsertByID(database, "counties", map[string]any{
			"id":          countyID,
			"district_id": districtID,
			"name":        adminName,
			"nhpi_code":   "CNT-" + adminUID,
			"hsdt_code":   "HSDT-CNT-" + adminUID,
		}); err != nil {
			return err
		}
		if err := upsertByID(database, "health_sub_districts", map[string]any{
			"id":          healthSubDistrictID,
			"district_id": districtID,
			"name":        adminName,
			"nhpi_code":   "HSD-" + adminUID,
			"hsdt_code":   "HSDT-HSD-" + adminUID,
		}); err != nil {
			return err
		}
		if err := upsertByID(database, "subcounties", map[string]any{
			"id":          subcountyID,
			"county_id":   countyID,
			"district_id": districtID,
			"name":        subcountyName,
			"nhpi_code":   "SUB-" + subcountyUID,
			"hsdt_code":   "HSDT-SUB-" + subcountyUID,
		}); err != nil {
			return err
		}
		levelCode := canonicalLevelCode(row.HFLevel)
		if levelCode == "" {
			levelCode = "UNSPECIFIED"
		}
		levelID, ok := seededLevels[levelCode]
		if !ok {
			levelName := levelNames[levelCode]
			if levelName == "" {
				levelName = titleFromCode(levelCode)
			}
			levelID = preferredFacilityLevelID(levelCode)
			if existingID, found, err := lookupRowIDByCodeOrName(database, "facility_levels", levelCode, levelName); err != nil {
				return err
			} else if found {
				levelID = existingID
			}
			seededLevels[levelCode] = levelID
			switch levelCode {
			case "HCIII":
				facilityLevelHC3ID = levelID
			case "HOSP":
				facilityLevelHospitalID = levelID
			}
			if err := upsertByID(database, "facility_levels", map[string]any{
				"id":   levelID,
				"code": levelCode,
				"name": levelName,
			}); err != nil {
				return err
			}
		}

		ownershipCode := strings.ToUpper(strings.TrimSpace(row.Ownership))
		if ownershipCode == "" {
			ownershipCode = "UNK"
		}
		ownershipID, ok := ownershipTypeIDs[ownershipCode]
		if !ok {
			ownershipID = ownershipTypeIDs["UNK"]
		}

		authorityKey, authorityName, authorityCode := authorityForRow(row)
		authorityID, ok := seededAuthorities[authorityKey]
		if !ok {
			authorityID = masterDataUUID("authority", authorityKey)
			if authorityKey == "gov:moh" {
				authorityID = authorityMOHID
			}
			seededAuthorities[authorityKey] = authorityID
			if err := upsertByID(database, "authorities", map[string]any{
				"id":                authorityID,
				"name":              authorityName,
				"code":              authorityCode,
				"ownership_type_id": ownershipID,
			}); err != nil {
				return err
			}
		}

		if err := upsertByID(database, "health_facilities", map[string]any{
			"id":                     facilityID,
			"name":                   facilityName,
			"nhpi_code":              "FAC-" + facilityUID,
			"hsdt_code":              "HSDT-FAC-" + strings.TrimSpace(row.OrganisationUnitID),
			"facility_level_id":      levelID,
			"authority_id":           authorityID,
			"ownership_type_id":      ownershipID,
			"health_sub_district_id": healthSubDistrictID,
			"subcounty_id":           subcountyID,
			"county_id":              countyID,
			"district_id":            districtID,
			"health_sub_region_id":   healthSubRegionID,
			"region_id":              regionID,
			"usage_count":            masterFacilityUsageCount(row),
		}); err != nil {
			return err
		}
	}

	log.Info().Int("rows", len(rows)).Msg("seeded master facility hierarchy from MoH CSV")
	return nil
}

func loadMasterFacilityRows() ([]masterFacilityRow, error) {
	paths := []string{
		filepath.Join("migrations", "data", "MasterFacility.csv"),
		filepath.Join("backend", "migrations", "data", "MasterFacility.csv"),
	}

	var file *os.File
	var err error
	for _, path := range paths {
		file, err = os.Open(path)
		if err == nil {
			defer file.Close()
			return parseMasterFacilityRows(file)
		}
	}
	return nil, fmt.Errorf("open MasterFacility.csv: %w", err)
}

func parseMasterFacilityRows(file *os.File) ([]masterFacilityRow, error) {
	reader := csv.NewReader(file)
	reader.FieldsPerRecord = -1

	records, err := reader.ReadAll()
	if err != nil {
		return nil, err
	}
	if len(records) < 2 {
		return nil, fmt.Errorf("MasterFacility.csv has no data rows")
	}

	headerIndex := map[string]int{}
	for i, name := range records[0] {
		headerIndex[strings.ToLower(strings.TrimSpace(name))] = i
	}
	get := func(row []string, key string) string {
		idx, ok := headerIndex[key]
		if !ok || idx >= len(row) {
			return ""
		}
		return strings.TrimSpace(row[idx])
	}

	rows := make([]masterFacilityRow, 0, len(records)-1)
	for _, record := range records[1:] {
		rows = append(rows, masterFacilityRow{
			OrganisationUnitID: get(record, "organisationunitid"),
			UID:                get(record, "uid"),
			Name:               get(record, "name"),
			ShortName:          get(record, "shortname"),
			NHFRID:             get(record, "nhfrid"),
			SubcountyUID:       get(record, "subcounty_uid"),
			Subcounty:          get(record, "subcounty"),
			AdminUnitUID:       get(record, "admin_unit_uid"),
			AdminUnit:          get(record, "admin_unit"),
			DistrictUID:        get(record, "district_uid"),
			District:           get(record, "district"),
			RegionUID:          get(record, "region_uid"),
			Region:             get(record, "region"),
			HFLevel:            get(record, "hflevel"),
			Ownership:          get(record, "ownership"),
			Status:             get(record, "status"),
			Reporting:          get(record, "reporting"),
		})
	}

	return rows, nil
}

func masterDataUUID(kind, source string) uuid.UUID {
	return uuid.NewSHA1(uuid.NameSpaceURL, []byte("mediguide:"+kind+":"+strings.TrimSpace(source)))
}

var legacySeedSkippedTables = map[string]struct{}{
	"regions":                 {},
	"health_sub_regions":      {},
	"districts":               {},
	"counties":                {},
	"health_sub_districts":    {},
	"subcounties":             {},
	"parishes":                {},
	"health_facilities":       {},
	"consultants":             {},
	"ministry_directory":      {},
	"guideline_categories":    {},
	"guideline_tags":          {},
	"guideline_index":         {},
	"medical_guidelines":      {},
	"drug_categories":         {},
	"drug_tags":               {},
	"drug_classes":            {},
	"therapeutic_categories":  {},
	"drugs":                   {},
	"abbreviations":           {},
	"guideline_documents":     {},
	"guideline_versions":      {},
	"guideline_sections":      {},
	"guideline_tables":        {},
	"guideline_chunks":        {},
	"ingestion_jobs":          {},
	"reading_progress":        {},
	"guideline_usage_logs":    {},
	"drug_usage_logs":         {},
	"abbreviation_usage_logs": {},
	"consultant_usage_logs":   {},
	"facility_usage_logs":     {},
}

func shouldSeedLegacyTable(table string) bool {
	_, skip := legacySeedSkippedTables[table]
	return !skip
}

func canonicalLevelCode(raw string) string {
	level := strings.ToUpper(strings.TrimSpace(raw))
	switch level {
	case "HC II":
		return "HCII"
	case "HC III":
		return "HCIII"
	case "HC IV":
		return "HCIV"
	case "HOSP", "HOSPITAL", "GENERAL HOSPITAL", "DISTRICT HOSPITAL":
		return "HOSP"
	case "DRUG SHOP":
		return "DRUGSHOP"
	default:
		level = strings.ReplaceAll(level, " ", "")
		level = strings.ReplaceAll(level, "_", "")
		return level
	}
}

func preferredFacilityLevelID(code string) uuid.UUID {
	switch code {
	case "HCIII":
		return facilityLevelHC3ID
	case "HOSP":
		return facilityLevelHospitalID
	default:
		return masterDataUUID("facility-level", code)
	}
}

func harmonizeFacilityLevels(database *gorm.DB) error {
	type facilityLevelRow struct {
		ID   uuid.UUID `gorm:"column:id"`
		Code string    `gorm:"column:code"`
		Name string    `gorm:"column:name"`
	}

	return database.Transaction(func(tx *gorm.DB) error {
		var rows []facilityLevelRow
		if err := tx.Table("facility_levels").
			Select("id, code, name").
			Where("deleted_at IS NULL").
			Scan(&rows).Error; err != nil {
			return err
		}

		canonicalCode := "HOSP"
		canonicalName := "Hospital"
		canonicalID := uuid.Nil
		duplicateIDs := make([]uuid.UUID, 0)

		for _, row := range rows {
			if canonicalLevelCode(row.Code) != "HOSP" && canonicalLevelCode(row.Name) != "HOSP" {
				continue
			}

			if canonicalID == uuid.Nil || strings.EqualFold(strings.TrimSpace(row.Code), canonicalCode) {
				if canonicalID != uuid.Nil && canonicalID != row.ID {
					duplicateIDs = append(duplicateIDs, canonicalID)
				}
				canonicalID = row.ID
				continue
			}

			duplicateIDs = append(duplicateIDs, row.ID)
		}

		if canonicalID == uuid.Nil {
			canonicalID = preferredFacilityLevelID(canonicalCode)
			if err := upsertByID(tx, "facility_levels", map[string]any{
				"id":   canonicalID,
				"code": canonicalCode,
				"name": canonicalName,
			}); err != nil {
				return err
			}
			facilityLevelHospitalID = canonicalID
			return nil
		}

		for _, duplicateID := range duplicateIDs {
			if duplicateID == canonicalID {
				continue
			}
			if err := tx.Table("health_facilities").
				Where("facility_level_id = ?", duplicateID).
				Update("facility_level_id", canonicalID).Error; err != nil {
				return err
			}
			if err := tx.Table("facility_levels").
				Where("id = ?", duplicateID).
				Delete(nil).Error; err != nil {
				return err
			}
		}

		if err := tx.Table("facility_levels").
			Where("id = ?", canonicalID).
			Updates(map[string]any{
				"code": canonicalCode,
				"name": canonicalName,
			}).Error; err != nil {
			return err
		}

		facilityLevelHospitalID = canonicalID
		return nil
	})
}

func titleFromCode(code string) string {
	parts := strings.Split(strings.ToLower(strings.ReplaceAll(code, "_", " ")), " ")
	for i, part := range parts {
		if part == "" {
			continue
		}
		parts[i] = strings.ToUpper(part[:1]) + part[1:]
	}
	return strings.Join(parts, " ")
}

func authorityForRow(row masterFacilityRow) (key, name, code string) {
	ownership := strings.ToUpper(strings.TrimSpace(row.Ownership))
	level := strings.ToUpper(strings.TrimSpace(row.HFLevel))
	switch {
	case ownership == "GOV" && (level == "NRH" || level == "RRH" || level == "NBB" || level == "RBB" || level == "BCDP"):
		return "gov:moh", "Ministry of Health", "MOH"
	case ownership == "GOV":
		adminUID := strings.TrimSpace(row.AdminUnitUID)
		adminName := strings.TrimSpace(row.AdminUnit)
		if adminUID == "" || adminName == "" {
			return "gov:moh", "Ministry of Health", "MOH"
		}
		return "gov:" + adminUID, adminName, "ADM-" + adminUID
	case ownership == "PNFP":
		return "pnfp", "Private Not For Profit", "PNFP"
	case ownership == "PFP":
		return "pfp", "Private For Profit", "PFP"
	default:
		return "unknown", "Unknown Ownership Authority", "UNK"
	}
}

func masterFacilityUsageCount(row masterFacilityRow) int {
	var usage int
	if strings.EqualFold(strings.TrimSpace(row.Status), "Functional") {
		usage += 1
	}
	if strings.EqualFold(strings.TrimSpace(row.Reporting), "Reporting") {
		usage += 1
	}
	return usage
}

// seededCalculatorSamples covers standalone offline/sample tools and remains
// intentionally separate from imported facility and content domain data.
type calculatorSampleSeed struct {
	ID              uuid.UUID
	FileName        string
	Name            string
	Description     string
	Type            string
	Icon            string
	Color           string
	BackgroundColor string
	UsageCount      int
	Featured        bool
}

func seededCalculatorSamples() []calculatorSampleSeed {
	return []calculatorSampleSeed{
		{
			ID:              calculatorID,
			FileName:        "medication-dosage-calculator.html",
			Name:            "Medication Dosage Calculator",
			Description:     "Dose support for common medication calculations in routine and emergency care.",
			Type:            "calculator",
			Icon:            "calculator",
			Color:           "#0284c7",
			BackgroundColor: "#e0f2fe",
			UsageCount:      31,
			Featured:        true,
		},
		{
			ID:              sampleCalculatorUUID("apgar-score-calculator.html"),
			FileName:        "apgar-score-calculator.html",
			Name:            "APGAR Score Calculator",
			Description:     "Rapid newborn APGAR scoring support for immediate post-delivery assessment.",
			Type:            "calculator",
			Icon:            "baby",
			Color:           "#db2777",
			BackgroundColor: "#fce7f3",
			UsageCount:      18,
			Featured:        true,
		},
		{
			ID:              sampleCalculatorUUID("bmi-calculator.html"),
			FileName:        "bmi-calculator.html",
			Name:            "BMI Calculator",
			Description:     "Body mass index calculation and quick weight category interpretation.",
			Type:            "calculator",
			Icon:            "activity",
			Color:           "#16a34a",
			BackgroundColor: "#dcfce7",
			UsageCount:      15,
			Featured:        false,
		},
		{
			ID:              sampleCalculatorUUID("fluid-balance-calculator.html"),
			FileName:        "fluid-balance-calculator.html",
			Name:            "Fluid Balance Calculator",
			Description:     "Estimate intake, output, and fluid balance at the bedside.",
			Type:            "calculator",
			Icon:            "droplets",
			Color:           "#0ea5e9",
			BackgroundColor: "#e0f2fe",
			UsageCount:      17,
			Featured:        true,
		},
		{
			ID:              sampleCalculatorUUID("pregnancy-due-date-calculator.html"),
			FileName:        "pregnancy-due-date-calculator.html",
			Name:            "Pregnancy Due Date Calculator",
			Description:     "Estimate expected delivery date from last menstrual period or gestation.",
			Type:            "calculator",
			Icon:            "calendar-heart",
			Color:           "#ea580c",
			BackgroundColor: "#ffedd5",
			UsageCount:      12,
			Featured:        false,
		},
		{
			ID:              sampleCalculatorUUID("blood-pressure-assessment.html"),
			FileName:        "blood-pressure-assessment.html",
			Name:            "Blood Pressure Risk Assessment",
			Description:     "Assess elevated blood pressure readings and clinical risk response.",
			Type:            "calculator",
			Icon:            "heart-pulse",
			Color:           "#dc2626",
			BackgroundColor: "#fee2e2",
			UsageCount:      20,
			Featured:        true,
		},
		{
			ID:              sampleCalculatorUUID("cardiac-risk-assessment.html"),
			FileName:        "cardiac-risk-assessment.html",
			Name:            "Cardiac Risk Assessment Tool",
			Description:     "Decision support for identifying cardiovascular risk factors and escalation needs.",
			Type:            "calculator",
			Icon:            "heart",
			Color:           "#b91c1c",
			BackgroundColor: "#fee2e2",
			UsageCount:      13,
			Featured:        false,
		},
		{
			ID:              sampleCalculatorUUID("dehydration-assessment.html"),
			FileName:        "dehydration-assessment.html",
			Name:            "Dehydration Assessment Tool",
			Description:     "Structured dehydration severity assessment to guide fluid management decisions.",
			Type:            "calculator",
			Icon:            "droplet",
			Color:           "#0369a1",
			BackgroundColor: "#e0f2fe",
			UsageCount:      22,
			Featured:        true,
		},
		{
			ID:              sampleCalculatorUUID("emergency-triage-assessment.html"),
			FileName:        "emergency-triage-assessment.html",
			Name:            "Emergency Triage Assessment Tool",
			Description:     "Rapid triage support for sorting patients by urgency in acute care settings.",
			Type:            "decision_tool",
			Icon:            "siren",
			Color:           "#7c3aed",
			BackgroundColor: "#ede9fe",
			UsageCount:      24,
			Featured:        true,
		},
		{
			ID:              sampleCalculatorUUID("glasgow-coma-scale.html"),
			FileName:        "glasgow-coma-scale.html",
			Name:            "Glasgow Coma Scale Assessment",
			Description:     "Neurologic assessment support using the standard Glasgow Coma Scale.",
			Type:            "calculator",
			Icon:            "brain",
			Color:           "#4f46e5",
			BackgroundColor: "#e0e7ff",
			UsageCount:      19,
			Featured:        false,
		},
		{
			ID:              sampleCalculatorUUID("pain-assessment-scale.html"),
			FileName:        "pain-assessment-scale.html",
			Name:            "Comprehensive Pain Assessment Scale",
			Description:     "Structured pain scoring support for symptom assessment and monitoring.",
			Type:            "calculator",
			Icon:            "badge-alert",
			Color:           "#c2410c",
			BackgroundColor: "#ffedd5",
			UsageCount:      16,
			Featured:        false,
		},
		{
			ID:              sampleCalculatorUUID("pediatric-fever-management.html"),
			FileName:        "pediatric-fever-management.html",
			Name:            "Pediatric Fever Management Tool",
			Description:     "Clinical decision support for evaluating and managing fever in children.",
			Type:            "decision_tool",
			Icon:            "thermometer",
			Color:           "#d97706",
			BackgroundColor: "#fef3c7",
			UsageCount:      21,
			Featured:        true,
		},
		{
			ID:              sampleCalculatorUUID("wound-assessment-tool.html"),
			FileName:        "wound-assessment-tool.html",
			Name:            "Wound Assessment and Care Tool",
			Description:     "Structured wound review to guide classification and care planning.",
			Type:            "decision_tool",
			Icon:            "bandage",
			Color:           "#059669",
			BackgroundColor: "#d1fae5",
			UsageCount:      14,
			Featured:        false,
		},
		{
			ID:              sampleCalculatorUUID("immunization-schedule-checker.html"),
			FileName:        "immunization-schedule-checker.html",
			Name:            "Immunization Schedule Checker",
			Description:     "Checklist support for reviewing immunization status and schedule completeness.",
			Type:            "decision_tool",
			Icon:            "list-checks",
			Color:           "#0891b2",
			BackgroundColor: "#cffafe",
			UsageCount:      11,
			Featured:        false,
		},
	}
}

func sampleCalculatorUUID(fileName string) uuid.UUID {
	return masterDataUUID("calculator-sample", fileName)
}

func lookupRowIDByCodeOrName(database *gorm.DB, table, code, name string) (uuid.UUID, bool, error) {
	type row struct {
		ID uuid.UUID `gorm:"column:id"`
	}
	var found row
	err := database.Table(table).
		Select("id").
		Where("deleted_at IS NULL").
		Where("code = ? OR name = ?", code, name).
		Take(&found).Error
	if err == nil {
		return found.ID, true, nil
	}
	if err == gorm.ErrRecordNotFound {
		return uuid.Nil, false, nil
	}
	return uuid.Nil, false, err
}

func upsertByID(database *gorm.DB, table string, row map[string]any) error {
	rewriteSeedRowIDs(row)

	requestedID, _ := row["id"].(uuid.UUID)
	if existingID, found, err := lookupExistingSeedRowID(database, table, row); err != nil {
		return err
	} else if found {
		row["id"] = existingID
		if requestedID != uuid.Nil && requestedID != existingID {
			seedIDAliases[requestedID] = existingID
		}
		// Published notification template versions are immutable by database
		// trigger. Their natural key is (template_id, version), so an existing
		// row is already the idempotent seed result and must not be updated.
		if table == "notification_template_versions" {
			return nil
		}
	}

	assignments := map[string]any{}
	for key, value := range row {
		if key == "id" {
			continue
		}
		assignments[key] = value
	}
	return database.Table(table).
		Clauses(clause.OnConflict{
			Columns:   []clause.Column{{Name: "id"}},
			DoUpdates: clause.Assignments(assignments),
		}).
		Create(row).Error
}

func rewriteSeedRowIDs(row map[string]any) {
	for key, value := range row {
		switch typed := value.(type) {
		case uuid.UUID:
			if replacement, ok := seedIDAliases[typed]; ok {
				row[key] = replacement
			}
		case *uuid.UUID:
			if typed != nil {
				if replacement, ok := seedIDAliases[*typed]; ok {
					row[key] = replacement
				}
			}
		}
	}
}

func lookupExistingSeedRowID(database *gorm.DB, table string, row map[string]any) (uuid.UUID, bool, error) {
	switch table {
	case "settings", "generic_pages":
		return lookupRowIDByColumn(database, table, "key", row["key"])
	case "languages":
		return lookupRowIDByColumn(database, table, "code", row["code"])
	case "faq_tags":
		return lookupRowIDByColumn(database, table, "slug", row["slug"])
	case "diseases", "guideline_categories", "content_hubs":
		return lookupRowIDByColumn(database, table, "slug", row["slug"])
	case "disease_aliases":
		return lookupRowIDByColumns(database, table, map[string]any{
			"disease_id":       row["disease_id"],
			"normalized_alias": row["normalized_alias"],
		})
	case "disease_codes":
		return lookupRowIDByColumns(database, table, map[string]any{
			"code_system": row["code_system"],
			"code":        row["code"],
		})
	case "content_disease_assignments":
		return lookupRowIDByColumns(database, table, map[string]any{
			"disease_id":   row["disease_id"],
			"content_type": row["content_type"],
			"content_id":   row["content_id"],
		})
	case "content_pillars":
		return lookupRowIDByColumns(database, table, map[string]any{
			"hub_id": row["hub_id"],
			"slug":   row["slug"],
		})
	case "content_pillar_items":
		return lookupRowIDByColumns(database, table, map[string]any{
			"pillar_id":    row["pillar_id"],
			"content_type": row["content_type"],
			"content_id":   row["content_id"],
		})
	case "notification_template_versions":
		type versionRow struct {
			ID uuid.UUID `gorm:"column:id"`
		}
		var found versionRow
		err := database.Table(table).
			Select("id").
			Where("deleted_at IS NULL").
			Where("template_id = ? AND version = ?", row["template_id"], row["version"]).
			Take(&found).Error
		if err == nil {
			return found.ID, true, nil
		}
		if err == gorm.ErrRecordNotFound {
			return uuid.Nil, false, nil
		}
		return uuid.Nil, false, err
	case "ownership_types", "facility_levels":
		return lookupRowIDByCodeOrName(
			database,
			table,
			strings.TrimSpace(fmt.Sprint(row["code"])),
			strings.TrimSpace(fmt.Sprint(row["name"])),
		)
	case "authorities":
		if id, found, err := lookupRowIDByColumn(database, table, "code", row["code"]); err != nil || found {
			return id, found, err
		}
		return lookupRowIDByColumn(database, table, "name", row["name"])
	case "regions", "health_sub_regions", "districts", "counties", "health_sub_districts", "subcounties", "parishes", "health_facilities":
		if id, found, err := lookupRowIDByColumn(database, table, "nhpi_code", row["nhpi_code"]); err != nil || found {
			return id, found, err
		}
		return lookupRowIDByColumn(database, table, "hsdt_code", row["hsdt_code"])
	default:
		return uuid.Nil, false, nil
	}
}

func lookupRowIDByColumns(database *gorm.DB, table string, columns map[string]any) (uuid.UUID, bool, error) {
	type row struct {
		ID uuid.UUID `gorm:"column:id"`
	}
	var found row
	query := database.Table(table).Select("id").Where("deleted_at IS NULL")
	for column, value := range columns {
		query = query.Where(fmt.Sprintf("%s = ?", column), value)
	}
	err := query.Take(&found).Error
	if err == nil {
		return found.ID, true, nil
	}
	if err == gorm.ErrRecordNotFound {
		return uuid.Nil, false, nil
	}
	return uuid.Nil, false, err
}

func lookupRowIDByColumn(database *gorm.DB, table, column string, value any) (uuid.UUID, bool, error) {
	raw := strings.TrimSpace(fmt.Sprint(value))
	if raw == "" || raw == "<nil>" {
		return uuid.Nil, false, nil
	}

	type row struct {
		ID uuid.UUID `gorm:"column:id"`
	}
	var found row
	err := database.Table(table).
		Select("id").
		Where("deleted_at IS NULL").
		Where(fmt.Sprintf("%s = ?", column), raw).
		Take(&found).Error
	if err == nil {
		return found.ID, true, nil
	}
	if err == gorm.ErrRecordNotFound {
		return uuid.Nil, false, nil
	}
	return uuid.Nil, false, err
}

func mustJSON(raw string) json.RawMessage {
	return json.RawMessage(raw)
}

func upsertGuidelineChunk(
	database *gorm.DB,
	id uuid.UUID,
	versionID uuid.UUID,
	sectionID uuid.UUID,
	title string,
	content string,
	html string,
	pageStart int,
	pageEnd int,
	language string,
	programArea string,
	sourceName string,
	sourceVersion string,
	reviewStatus string,
	vectorSeed int,
) error {
	return database.Exec(
		`
		INSERT INTO guideline_chunks (
			id, version_id, section_id, title, content, html, page_start, page_end,
			language, program_area, source_name, source_version, review_status,
			embedding_text, embedding
		)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?::vector)
		ON CONFLICT (id) DO UPDATE SET
			version_id = EXCLUDED.version_id,
			section_id = EXCLUDED.section_id,
			title = EXCLUDED.title,
			content = EXCLUDED.content,
			html = EXCLUDED.html,
			page_start = EXCLUDED.page_start,
			page_end = EXCLUDED.page_end,
			language = EXCLUDED.language,
			program_area = EXCLUDED.program_area,
			source_name = EXCLUDED.source_name,
			source_version = EXCLUDED.source_version,
			review_status = EXCLUDED.review_status,
			embedding_text = EXCLUDED.embedding_text,
			embedding = EXCLUDED.embedding
		`,
		id,
		versionID,
		sectionID,
		title,
		content,
		html,
		pageStart,
		pageEnd,
		language,
		programArea,
		sourceName,
		sourceVersion,
		reviewStatus,
		content,
		seedVector(vectorSeed),
	).Error
}

func seedVector(seed int) string {
	values := make([]string, 1024)
	for i := range values {
		value := "0"
		switch {
		case i == seed:
			value = "1"
		case i == seed+1:
			value = "0.25"
		case i == seed+2:
			value = "0.1"
		}
		values[i] = value
	}
	return fmt.Sprintf("[%s]", strings.Join(values, ","))
}
