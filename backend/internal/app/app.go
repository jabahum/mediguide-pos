package app

import (
	"net/http"
	"strings"
	"time"

	"mediguide/internal/config"
	"mediguide/internal/db"
	"mediguide/internal/handlers"
	"mediguide/internal/mailer"
	"mediguide/internal/middleware"
	"mediguide/internal/services"
	"mediguide/internal/storage"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"

	swaggerFiles "github.com/swaggo/files"
	ginSwagger "github.com/swaggo/gin-swagger"
)

type App struct {
	Router *gin.Engine
	DB     *gorm.DB
}

func New(cfg config.Config) (*App, error) {
	database, err := db.Connect(cfg.DatabaseURL)
	if err != nil {
		return nil, err
	}
	store, err := storage.NewMinioStore(cfg)
	if err != nil {
		return nil, err
	}
	emailSender, err := mailer.New(cfg)
	if err != nil {
		return nil, err
	}

	r := gin.New()
	r.Use(gin.Recovery(), middleware.RequestLogger())

	// Build CORS allow-list from config (comma-separated).
	allowedOrigins := []string{}
	for _, o := range strings.Split(cfg.AllowedOrigins, ",") {
		if trimmed := strings.TrimSpace(o); trimmed != "" {
			allowedOrigins = append(allowedOrigins, trimmed)
		}
	}
	r.Use(cors.New(cors.Config{
		AllowOrigins:  allowedOrigins,
		AllowHeaders:  []string{"Accept", "Authorization", "Content-Type", "If-None-Match"},
		ExposeHeaders: []string{"ETag", "Last-Modified"},
		AllowMethods:  []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"},
	}))

	r.GET("/swagger", func(c *gin.Context) {
		c.Data(http.StatusOK, "text/html; charset=utf-8", []byte(swaggerChooserHTML))
	})
	r.GET("/swagger/all/*any", ginSwagger.WrapHandler(swaggerFiles.NewHandler(), ginSwagger.InstanceName("all"), ginSwagger.URL("/swagger/all/doc.json")))
	r.GET("/swagger/v1/*any", ginSwagger.WrapHandler(swaggerFiles.NewHandler(), ginSwagger.InstanceName("v1"), ginSwagger.URL("/swagger/v1/doc.json")))
	r.GET("/swagger/v2/*any", ginSwagger.WrapHandler(swaggerFiles.NewHandler(), ginSwagger.InstanceName("v2"), ginSwagger.URL("/swagger/v2/doc.json")))
	r.Static("/samples", cfg.StaticSamplesDir)
	r.Static("/dashboard/samples", cfg.StaticSamplesDir)

	r.GET("/api/healthz", func(c *gin.Context) { c.JSON(http.StatusOK, gin.H{"ok": true, "service": cfg.AppName}) })

	// Readiness probe: verify DB connectivity.
	r.GET("/api/readyz", func(c *gin.Context) {
		sqlDB, err := database.DB()
		if err != nil || sqlDB.Ping() != nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"ok": false, "reason": "db_unavailable"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"ok": true, "service": cfg.AppName})
	})

	authSvc := services.AuthService{DB: database, Cfg: cfg, Mailer: emailSender}
	guidelineSvc := services.GuidelineService{DB: database, Store: store}
	publicGuidelineSvc := services.PublicGuidelineService{DB: database, Store: store}
	searchSvc := services.SearchService{DB: database}
	ragSvc := services.RAGService{DB: database, Search: searchSvc, Cfg: cfg}
	protocolSvc := services.ProtocolService{DB: database}
	syncSvc := services.SyncService{DB: database, Store: store, Cfg: cfg}
	referenceSvc := services.ReferenceService{DB: database}
	calculatorSvc := services.CalculatorService{DB: database, StaticSamplesDir: cfg.StaticSamplesDir}
	drugSvc := services.DrugService{DB: database}
	drugReferenceSvc := services.DrugReferenceService{DB: database}
	userSvc := services.UserService{DB: database}
	notificationSvc := services.NotificationService{DB: database}
	supportSvc := services.SupportService{DB: database}
	helpContentSvc := services.HelpContentService{DB: database}
	guidelineContentSvc := services.GuidelineContentService{DB: database}
	emergencyProtocolSvc := services.EmergencyProtocolService{DB: database}
	contentReferenceSvc := services.ContentReferenceService{DB: database}
	consultantSvc := services.ConsultantService{DB: database}
	legacyAPISvc := services.LegacyAPIService{DB: database}
	facilitySvc := services.FacilityService{DB: database}

	authH := handlers.AuthHandler{Service: authSvc}
	guidelineH := handlers.GuidelineHandler{Service: guidelineSvc, MaxUploadMB: cfg.MaxUploadMB}
	publicGuidelineH := handlers.PublicGuidelineHandler{Service: publicGuidelineSvc}
	searchH := handlers.SearchHandler{Service: searchSvc}
	ragH := handlers.RAGHandler{Service: ragSvc}
	protocolH := handlers.ProtocolHandler{Service: protocolSvc}
	syncH := handlers.SyncHandler{Service: syncSvc}
	referenceH := handlers.ReferenceHandler{Service: referenceSvc}
	calculatorH := handlers.CalculatorHandler{Service: calculatorSvc}
	drugH := handlers.DrugHandler{Service: drugSvc}
	drugReferenceH := handlers.DrugReferenceHandler{Service: drugReferenceSvc}
	userH := handlers.UserHandler{Service: userSvc}
	notificationH := handlers.NotificationHandler{Service: notificationSvc}
	supportH := handlers.SupportHandler{Service: supportSvc}
	helpContentH := handlers.HelpContentHandler{Service: helpContentSvc}
	guidelineContentH := handlers.GuidelineContentHandler{Service: guidelineContentSvc}
	emergencyProtocolH := handlers.EmergencyProtocolHandler{Service: emergencyProtocolSvc}
	contentReferenceH := handlers.ContentReferenceHandler{Service: contentReferenceSvc}
	progressUsageH := handlers.ProgressUsageHandler{Service: services.ProgressUsageService{DB: database}}
	conversationH := handlers.ConversationHandler{Service: services.ConversationService{DB: database}}
	consultantH := handlers.ConsultantHandler{Service: consultantSvc}
	legacyAPIH := handlers.LegacyAPIHandler{Service: legacyAPISvc, Cfg: cfg}
	facilityH := handlers.NewFacilityHandler(facilitySvc)

	legacyV1 := r.Group("/api/v1")
	legacyV1.GET("/stats", legacyAPIH.Stats)
	legacyV1.GET("/consultants/tree", legacyAPIH.ConsultantsTree)
	legacyV1.GET("/health-facilities/tree", legacyAPIH.HealthFacilitiesTree)
	legacyV1.GET("/ministry-directory/tree", legacyAPIH.MinistryDirectoryTree)
	legacyProtected := legacyV1.Group("")
	legacyProtected.Use(middleware.AuthRequired(cfg, database))
	legacyProtected.GET("/overview", legacyAPIH.Overview)

	legacyCompat := r.Group("/api")
	legacyCompat.Use(middleware.AuthRequired(cfg, database))
	legacyCompat.GET("/overview", legacyAPIH.Overview)

	public := r.Group("/api/public")
	public.Use(middleware.PublicRateLimit(120, time.Minute))
	{
		public.GET("/guidelines", publicGuidelineH.List)
		public.GET("/guidelines/:id", publicGuidelineH.Get)
		public.GET("/guidelines/:id/markdown", publicGuidelineH.Markdown)
	}

	v2 := r.Group("/api/v2")
	{
		v2.POST("/auth/register", authH.Register)
		v2.POST("/auth/login", authH.Login)
		v2.POST("/auth/refresh", authH.Refresh)
		v2.POST("/auth/password-reset/request", middleware.PublicRateLimit(5, 15*time.Minute), authH.RequestPasswordReset)
		v2.POST("/auth/password-reset/confirm", middleware.PublicRateLimit(10, 15*time.Minute), authH.ConfirmPasswordReset)
		v2.POST("/auth/email-verification/request", middleware.PublicRateLimit(5, 15*time.Minute), authH.RequestEmailVerification)
		v2.POST("/auth/email-verification/confirm", middleware.PublicRateLimit(10, 15*time.Minute), authH.ConfirmEmailVerification)
		protected := v2.Group("")
		protected.Use(middleware.AuthRequired(cfg, database))
		protected.POST("/auth/logout", authH.Logout)
		protected.GET("/me", authH.Me)
		protected.POST("/me/password", authH.ChangePassword)

		protected.GET("/calculators", middleware.RequireAnyPermission("calculator.read", "guideline.read"), calculatorH.List)
		protected.GET("/calculators/:id", middleware.RequireAnyPermission("calculator.read", "guideline.read"), calculatorH.Get)
		protected.POST("/calculators", middleware.RequireAnyPermission("calculator.write", "guideline.write"), calculatorH.Create)
		protected.PATCH("/calculators/:id", middleware.RequireAnyPermission("calculator.write", "guideline.write"), calculatorH.Update)
		protected.DELETE("/calculators/:id", middleware.RequireAnyPermission("calculator.write", "guideline.write"), calculatorH.Delete)
		protected.GET("/calculators/:id/content", middleware.RequireAnyPermission("calculator.read", "guideline.read"), calculatorH.Content)
		protected.POST("/calculators/:id/usage", calculatorH.StartUsage)
		protected.PATCH("/calculator-usage/:usageId", calculatorH.FinishUsage)

		protected.GET("/drugs", middleware.RequireAnyPermission("drug.read", "guideline.read"), drugH.List)
		protected.GET("/drugs/:id", middleware.RequireAnyPermission("drug.read", "guideline.read"), drugH.Get)
		protected.POST("/drugs", middleware.RequireAnyPermission("drug.write", "guideline.write"), drugH.Create)
		protected.PATCH("/drugs/:id", middleware.RequireAnyPermission("drug.write", "guideline.write"), drugH.Update)
		protected.DELETE("/drugs/:id", middleware.RequireAnyPermission("drug.write", "guideline.write"), drugH.Delete)
		protected.POST("/drugs/:id/usage", drugH.RecordUsage)

		protected.GET("/users", middleware.RequirePermission("admin.all"), userH.List)
		protected.GET("/users/:id", userH.Get)
		protected.POST("/users", middleware.RequirePermission("admin.all"), userH.Create)
		protected.PATCH("/users/:id", userH.Update)
		protected.DELETE("/users/:id", middleware.RequirePermission("admin.all"), userH.Delete)
		protected.POST("/users/:id/verification", middleware.RequirePermission("admin.all"), userH.Verify)
		protected.GET("/roles", middleware.RequirePermission("admin.all"), userH.ListRoles)
		protected.GET("/roles/:id", middleware.RequirePermission("admin.all"), userH.GetRole)
		protected.POST("/roles", middleware.RequirePermission("admin.all"), userH.CreateRole)
		protected.PATCH("/roles/:id", middleware.RequirePermission("admin.all"), userH.UpdateRole)
		protected.DELETE("/roles/:id", middleware.RequirePermission("admin.all"), userH.DeleteRole)
		protected.GET("/permissions", middleware.RequirePermission("admin.all"), userH.ListPermissions)
		protected.GET("/roles/:id/permissions", middleware.RequirePermission("admin.all"), userH.GetRolePermissions)
		protected.PUT("/roles/:id/permissions", middleware.RequirePermission("admin.all"), userH.SetRolePermissions)

		protected.GET("/notifications", notificationH.List)
		protected.GET("/notifications/:id", notificationH.Get)
		protected.POST("/notifications", middleware.RequirePermission("admin.all"), notificationH.Create)
		protected.POST("/notifications/read-all", notificationH.MarkAllRead)
		protected.POST("/notifications/:id/read", notificationH.MarkRead)
		protected.POST("/notifications/:id/unread", notificationH.MarkUnread)

		protected.GET("/notification-templates", middleware.RequirePermission("admin.all"), notificationH.ListTemplates)
		protected.GET("/notification-templates/:id", middleware.RequirePermission("admin.all"), notificationH.GetTemplate)
		protected.POST("/notification-templates", middleware.RequirePermission("admin.all"), notificationH.CreateTemplate)
		protected.PATCH("/notification-templates/:id", middleware.RequirePermission("admin.all"), notificationH.UpdateTemplate)
		protected.PATCH("/notification-templates/:id/status", middleware.RequirePermission("admin.all"), notificationH.UpdateTemplateStatus)
		protected.DELETE("/notification-templates/:id", middleware.RequirePermission("admin.all"), notificationH.DeleteTemplate)
		protected.GET("/notification-campaigns", middleware.RequirePermission("admin.all"), notificationH.ListCampaigns)
		protected.GET("/notification-campaigns/:id", middleware.RequirePermission("admin.all"), notificationH.GetCampaign)
		protected.POST("/notification-campaigns", middleware.RequirePermission("admin.all"), notificationH.CreateCampaign)
		protected.PATCH("/notification-campaigns/:id", middleware.RequirePermission("admin.all"), notificationH.UpdateCampaign)
		protected.PATCH("/notification-campaigns/:id/status", middleware.RequirePermission("admin.all"), notificationH.UpdateCampaignStatus)
		protected.DELETE("/notification-campaigns/:id", middleware.RequirePermission("admin.all"), notificationH.DeleteCampaign)

		protected.GET("/support/tickets", supportH.ListTickets)
		protected.GET("/support/tickets/:id", supportH.GetTicket)
		protected.POST("/support/tickets", supportH.CreateTicket)
		protected.PATCH("/support/tickets/:id", supportH.UpdateTicket)
		protected.DELETE("/support/tickets/:id", supportH.DeleteTicket)
		protected.GET("/support/tickets/:id/replies", supportH.ListReplies)
		protected.POST("/support/tickets/:id/replies", supportH.CreateReply)

		protected.GET("/faqs", helpContentH.ListFAQs)
		protected.GET("/faqs/:id", helpContentH.GetFAQ)
		protected.POST("/faqs", middleware.RequireAnyPermission("admin.all", "content.write", "guideline.write"), helpContentH.CreateFAQ)
		protected.PATCH("/faqs/:id", middleware.RequireAnyPermission("admin.all", "content.write", "guideline.write"), helpContentH.UpdateFAQ)
		protected.DELETE("/faqs/:id", middleware.RequireAnyPermission("admin.all", "content.write", "guideline.write"), helpContentH.DeleteFAQ)
		protected.GET("/faq-tags", helpContentH.ListTags)
		protected.GET("/faq-tags/:id", helpContentH.GetTag)
		protected.POST("/faq-tags", middleware.RequireAnyPermission("admin.all", "content.write", "guideline.write"), helpContentH.CreateTag)
		protected.PATCH("/faq-tags/:id", middleware.RequireAnyPermission("admin.all", "content.write", "guideline.write"), helpContentH.UpdateTag)
		protected.DELETE("/faq-tags/:id", middleware.RequireAnyPermission("admin.all", "content.write", "guideline.write"), helpContentH.DeleteTag)
		protected.POST("/faq-tags/recalculate-usage", middleware.RequireAnyPermission("admin.all", "content.write", "guideline.write"), helpContentH.RecalculateTagUsage)
		protected.GET("/documentation", helpContentH.ListDocumentation)
		protected.GET("/documentation/:id", helpContentH.GetDocumentation)
		protected.POST("/documentation", middleware.RequireAnyPermission("admin.all", "content.write", "guideline.write"), helpContentH.CreateDocumentation)
		protected.PATCH("/documentation/:id", middleware.RequireAnyPermission("admin.all", "content.write", "guideline.write"), helpContentH.UpdateDocumentation)
		protected.DELETE("/documentation/:id", middleware.RequireAnyPermission("admin.all", "content.write", "guideline.write"), helpContentH.DeleteDocumentation)

		protected.GET("/medical-guidelines", middleware.RequirePermission("guideline.read"), guidelineContentH.ListMedicalGuidelines)
		protected.GET("/medical-guidelines/:id", middleware.RequirePermission("guideline.read"), guidelineContentH.GetMedicalGuideline)
		protected.POST("/medical-guidelines", middleware.RequirePermission("guideline.write"), guidelineContentH.CreateMedicalGuideline)
		protected.PATCH("/medical-guidelines/:id", middleware.RequirePermission("guideline.write"), guidelineContentH.UpdateMedicalGuideline)
		protected.DELETE("/medical-guidelines/:id", middleware.RequirePermission("guideline.write"), guidelineContentH.DeleteMedicalGuideline)
		protected.GET("/guideline-categories", middleware.RequirePermission("guideline.read"), guidelineContentH.ListCategories)
		protected.GET("/guideline-categories/:id", middleware.RequirePermission("guideline.read"), guidelineContentH.GetCategory)
		protected.POST("/guideline-categories", middleware.RequirePermission("guideline.write"), guidelineContentH.CreateCategory)
		protected.PATCH("/guideline-categories/:id", middleware.RequirePermission("guideline.write"), guidelineContentH.UpdateCategory)
		protected.DELETE("/guideline-categories/:id", middleware.RequirePermission("guideline.write"), guidelineContentH.DeleteCategory)
		protected.GET("/guideline-tags", middleware.RequirePermission("guideline.read"), guidelineContentH.ListTags)
		protected.GET("/guideline-tags/:id", middleware.RequirePermission("guideline.read"), guidelineContentH.GetTag)
		protected.POST("/guideline-tags", middleware.RequirePermission("guideline.write"), guidelineContentH.CreateTag)
		protected.PATCH("/guideline-tags/:id", middleware.RequirePermission("guideline.write"), guidelineContentH.UpdateTag)
		protected.DELETE("/guideline-tags/:id", middleware.RequirePermission("guideline.write"), guidelineContentH.DeleteTag)
		protected.GET("/guideline-index", middleware.RequirePermission("guideline.read"), guidelineContentH.ListIndex)
		protected.GET("/guideline-index/:id", middleware.RequirePermission("guideline.read"), guidelineContentH.GetIndex)
		protected.GET("/guideline-index/:id/children", middleware.RequirePermission("guideline.read"), guidelineContentH.IndexChildren)
		protected.POST("/guideline-index", middleware.RequirePermission("guideline.write"), guidelineContentH.CreateIndex)
		protected.PATCH("/guideline-index/:id", middleware.RequirePermission("guideline.write"), guidelineContentH.UpdateIndex)
		protected.DELETE("/guideline-index/:id", middleware.RequirePermission("guideline.write"), guidelineContentH.DeleteIndex)
		protected.GET("/abbreviations", middleware.RequirePermission("guideline.read"), guidelineContentH.ListAbbreviations)
		protected.GET("/abbreviations/:id", middleware.RequirePermission("guideline.read"), guidelineContentH.GetAbbreviation)
		protected.POST("/abbreviations", middleware.RequirePermission("guideline.write"), guidelineContentH.CreateAbbreviation)
		protected.PATCH("/abbreviations/:id", middleware.RequirePermission("guideline.write"), guidelineContentH.UpdateAbbreviation)
		protected.DELETE("/abbreviations/:id", middleware.RequirePermission("guideline.write"), guidelineContentH.DeleteAbbreviation)
		protected.GET("/emergency-protocols", middleware.RequireAnyPermission("protocol.read", "guideline.read"), emergencyProtocolH.List)
		protected.GET("/emergency-protocols/:id", middleware.RequireAnyPermission("protocol.read", "guideline.read"), emergencyProtocolH.Get)
		protected.POST("/emergency-protocols", middleware.RequireAnyPermission("protocol.write", "guideline.write"), emergencyProtocolH.Create)
		protected.PATCH("/emergency-protocols/:id", middleware.RequireAnyPermission("protocol.write", "guideline.write"), emergencyProtocolH.Update)
		protected.DELETE("/emergency-protocols/:id", middleware.RequireAnyPermission("protocol.write", "guideline.write"), emergencyProtocolH.Delete)
		protected.GET("/pages", contentReferenceH.ListPages)
		protected.GET("/pages/key/:key", contentReferenceH.GetPageByKey)
		protected.GET("/pages/:id", contentReferenceH.GetPage)
		protected.POST("/pages", middleware.RequireAnyPermission("content.write", "guideline.write"), contentReferenceH.CreatePage)
		protected.PATCH("/pages/:id", middleware.RequireAnyPermission("content.write", "guideline.write"), contentReferenceH.UpdatePage)
		protected.DELETE("/pages/:id", middleware.RequireAnyPermission("content.write", "guideline.write"), contentReferenceH.DeletePage)
		protected.GET("/ministry-directory", contentReferenceH.ListDirectory)
		protected.GET("/ministry-directory/:id", contentReferenceH.GetDirectory)
		protected.POST("/ministry-directory", middleware.RequireAnyPermission("content.write", "facility.write"), contentReferenceH.CreateDirectory)
		protected.PATCH("/ministry-directory/:id", middleware.RequireAnyPermission("content.write", "facility.write"), contentReferenceH.UpdateDirectory)
		protected.DELETE("/ministry-directory/:id", middleware.RequireAnyPermission("content.write", "facility.write"), contentReferenceH.DeleteDirectory)

		protected.GET("/drug-categories", middleware.RequireAnyPermission("drug.read", "guideline.read"), drugReferenceH.ListCategories)
		protected.GET("/drug-categories/:id", middleware.RequireAnyPermission("drug.read", "guideline.read"), drugReferenceH.GetCategory)
		protected.POST("/drug-categories", middleware.RequireAnyPermission("drug.write", "guideline.write"), drugReferenceH.CreateCategory)
		protected.PATCH("/drug-categories/:id", middleware.RequireAnyPermission("drug.write", "guideline.write"), drugReferenceH.UpdateCategory)
		protected.DELETE("/drug-categories/:id", middleware.RequireAnyPermission("drug.write", "guideline.write"), drugReferenceH.DeleteCategory)

		protected.GET("/drug-tags", middleware.RequireAnyPermission("drug.read", "guideline.read"), drugReferenceH.ListTags)
		protected.GET("/drug-tags/:id", middleware.RequireAnyPermission("drug.read", "guideline.read"), drugReferenceH.GetTag)
		protected.POST("/drug-tags", middleware.RequireAnyPermission("drug.write", "guideline.write"), drugReferenceH.CreateTag)
		protected.PATCH("/drug-tags/:id", middleware.RequireAnyPermission("drug.write", "guideline.write"), drugReferenceH.UpdateTag)
		protected.DELETE("/drug-tags/:id", middleware.RequireAnyPermission("drug.write", "guideline.write"), drugReferenceH.DeleteTag)

		protected.GET("/drug-classes", middleware.RequireAnyPermission("drug.read", "guideline.read"), drugReferenceH.ListClasses)
		protected.GET("/drug-classes/:id", middleware.RequireAnyPermission("drug.read", "guideline.read"), drugReferenceH.GetClass)
		protected.POST("/drug-classes", middleware.RequireAnyPermission("drug.write", "guideline.write"), drugReferenceH.CreateClass)
		protected.PATCH("/drug-classes/:id", middleware.RequireAnyPermission("drug.write", "guideline.write"), drugReferenceH.UpdateClass)
		protected.DELETE("/drug-classes/:id", middleware.RequireAnyPermission("drug.write", "guideline.write"), drugReferenceH.DeleteClass)

		protected.GET("/therapeutic-categories", middleware.RequireAnyPermission("drug.read", "guideline.read"), drugReferenceH.ListTherapeuticCategories)
		protected.GET("/therapeutic-categories/:id", middleware.RequireAnyPermission("drug.read", "guideline.read"), drugReferenceH.GetTherapeuticCategory)
		protected.POST("/therapeutic-categories", middleware.RequireAnyPermission("drug.write", "guideline.write"), drugReferenceH.CreateTherapeuticCategory)
		protected.PATCH("/therapeutic-categories/:id", middleware.RequireAnyPermission("drug.write", "guideline.write"), drugReferenceH.UpdateTherapeuticCategory)
		protected.DELETE("/therapeutic-categories/:id", middleware.RequireAnyPermission("drug.write", "guideline.write"), drugReferenceH.DeleteTherapeuticCategory)

		protected.POST("/guidelines", middleware.RequirePermission("guideline.write"), guidelineH.Create)
		protected.GET("/guidelines", middleware.RequirePermission("guideline.read"), guidelineH.List)
		protected.GET("/guidelines/:id", middleware.RequirePermission("guideline.read"), guidelineH.Get)
		protected.PATCH("/guidelines/:id", middleware.RequirePermission("guideline.write"), guidelineH.Update)
		protected.POST("/guidelines/:id/versions", middleware.RequirePermission("guideline.write"), guidelineH.CreateVersion)
		protected.POST("/guideline-versions/:id/upload", middleware.RequirePermission("guideline.write"), guidelineH.UploadPDF)
		protected.POST("/guideline-versions/:id/publish", middleware.RequirePermission("guideline.publish"), guidelineH.Publish)
		protected.GET("/guideline-versions/:id/sections", middleware.RequirePermission("guideline.read"), guidelineH.Sections)
		protected.GET("/guideline-versions/:id/chunks", middleware.RequirePermission("guideline.read"), guidelineH.Chunks)
		protected.GET("/guideline-versions/:id/extracted/:format", middleware.RequirePermission("guideline.read"), guidelineH.ExtractedAsset)
		protected.PUT("/guideline-versions/:id/extracted/markdown", middleware.RequirePermission("guideline.write"), guidelineH.UpdateMarkdown)

		protected.GET("/search", middleware.RequirePermission("guideline.read"), searchH.Search)
		protected.POST("/chat/ask", middleware.RequirePermission("chat.ask"), ragH.Ask)

		protected.POST("/protocols", middleware.RequirePermission("protocol.write"), protocolH.Create)
		protected.GET("/protocols", middleware.RequirePermission("protocol.read"), protocolH.List)
		protected.GET("/protocols/:id", middleware.RequirePermission("protocol.read"), protocolH.Get)
		protected.POST("/protocols/:id/run", middleware.RequirePermission("protocol.read"), protocolH.Run)

		protected.GET("/settings", middleware.RequirePermission("admin.all"), referenceH.ListSettings)
		protected.POST("/settings", middleware.RequirePermission("admin.all"), referenceH.CreateSetting)
		protected.GET("/languages", contentReferenceH.ListLanguages)
		protected.GET("/languages/:id", contentReferenceH.GetLanguage)
		protected.POST("/languages", middleware.RequirePermission("admin.all"), contentReferenceH.CreateLanguage)
		protected.PATCH("/languages/:id", middleware.RequirePermission("admin.all"), contentReferenceH.UpdateLanguage)
		protected.DELETE("/languages/:id", middleware.RequirePermission("admin.all"), contentReferenceH.DeleteLanguage)
		protected.GET("/reading-progress", progressUsageH.ListProgress)
		protected.GET("/reading-progress/:guidelineId", progressUsageH.GetProgress)
		protected.PUT("/reading-progress/:guidelineId", progressUsageH.UpsertProgress)
		protected.DELETE("/reading-progress/:guidelineId", progressUsageH.DeleteProgress)
		protected.POST("/usage/guidelines", progressUsageH.RecordGuidelineUsage)
		protected.POST("/usage/abbreviations", progressUsageH.RecordAbbreviationUsage)
		protected.POST("/usage/consultants", progressUsageH.RecordConsultantUsage)
		protected.POST("/usage/ai", progressUsageH.RecordAIUsage)
		protected.GET("/analytics/usage", middleware.RequireAnyPermission("admin.all", "analytics.read", "sync.read"), progressUsageH.UsageAggregates)
		protected.GET("/conversations", conversationH.List)
		protected.POST("/conversations", conversationH.Create)
		protected.GET("/conversations/:id", conversationH.Get)
		protected.DELETE("/conversations/:id", conversationH.Delete)
		protected.GET("/conversations/:id/messages", conversationH.ListMessages)
		protected.POST("/conversations/:id/messages", conversationH.CreateMessage)
		protected.POST("/conversations/:id/messages/:messageId/read", conversationH.MarkRead)
		protected.POST("/conversations/:id/messages/:messageId/reaction", conversationH.React)
		protected.GET("/consultants", consultantH.List)
		protected.GET("/consultants/:id", consultantH.Get)
		protected.POST("/consultants", middleware.RequireAnyPermission("admin.all", "content.write", "consultant.write"), consultantH.Create)
		protected.PATCH("/consultants/:id", middleware.RequireAnyPermission("admin.all", "content.write", "consultant.write"), consultantH.Update)
		protected.DELETE("/consultants/:id", middleware.RequireAnyPermission("admin.all", "content.write", "consultant.write"), consultantH.Delete)

		protected.GET("/facilities", facilityH.ListFacilities)
		protected.GET("/facilities/:id", facilityH.GetFacility)
		protected.POST("/facilities", middleware.RequireAnyPermission("admin.all", "facility.write"), facilityH.CreateFacility)
		protected.PATCH("/facilities/:id", middleware.RequireAnyPermission("admin.all", "facility.write"), facilityH.UpdateFacility)
		protected.DELETE("/facilities/:id", middleware.RequireAnyPermission("admin.all", "facility.write"), facilityH.DeleteFacility)
		protected.POST("/facilities/:id/usage", facilityH.RecordUsage)

		protected.GET("/health-sub-regions", facilityH.ListHealthSubRegions)
		protected.GET("/health-sub-regions/:id", facilityH.GetHealthSubRegion)
		protected.POST("/health-sub-regions", middleware.RequireAnyPermission("admin.all", "facility.write"), facilityH.CreateHealthSubRegion)
		protected.PATCH("/health-sub-regions/:id", middleware.RequireAnyPermission("admin.all", "facility.write"), facilityH.UpdateHealthSubRegion)
		protected.DELETE("/health-sub-regions/:id", middleware.RequireAnyPermission("admin.all", "facility.write"), facilityH.DeleteHealthSubRegion)
		protected.GET("/regions", facilityH.ListRegions)
		protected.GET("/regions/:id", facilityH.GetRegion)
		protected.GET("/regions/:id/children", facilityH.GetRegionChildren)
		protected.POST("/regions", middleware.RequireAnyPermission("admin.all", "facility.write"), facilityH.CreateRegion)
		protected.PATCH("/regions/:id", middleware.RequireAnyPermission("admin.all", "facility.write"), facilityH.UpdateRegion)
		protected.DELETE("/regions/:id", middleware.RequireAnyPermission("admin.all", "facility.write"), facilityH.DeleteRegion)
		protected.GET("/districts", facilityH.ListDistricts)
		protected.GET("/districts/:id", facilityH.GetDistrict)
		protected.POST("/districts", middleware.RequireAnyPermission("admin.all", "facility.write"), facilityH.CreateDistrict)
		protected.PATCH("/districts/:id", middleware.RequireAnyPermission("admin.all", "facility.write"), facilityH.UpdateDistrict)
		protected.DELETE("/districts/:id", middleware.RequireAnyPermission("admin.all", "facility.write"), facilityH.DeleteDistrict)
		protected.GET("/health-sub-districts", facilityH.ListHealthSubDistricts)
		protected.GET("/health-sub-districts/:id", facilityH.GetHealthSubDistrict)
		protected.POST("/health-sub-districts", middleware.RequireAnyPermission("admin.all", "facility.write"), facilityH.CreateHealthSubDistrict)
		protected.PATCH("/health-sub-districts/:id", middleware.RequireAnyPermission("admin.all", "facility.write"), facilityH.UpdateHealthSubDistrict)
		protected.DELETE("/health-sub-districts/:id", middleware.RequireAnyPermission("admin.all", "facility.write"), facilityH.DeleteHealthSubDistrict)
		protected.GET("/counties", facilityH.ListCounties)
		protected.GET("/counties/:id", facilityH.GetCounty)
		protected.POST("/counties", middleware.RequireAnyPermission("admin.all", "facility.write"), facilityH.CreateCounty)
		protected.PATCH("/counties/:id", middleware.RequireAnyPermission("admin.all", "facility.write"), facilityH.UpdateCounty)
		protected.DELETE("/counties/:id", middleware.RequireAnyPermission("admin.all", "facility.write"), facilityH.DeleteCounty)
		protected.GET("/subcounties", facilityH.ListSubcounties)
		protected.GET("/subcounties/:id", facilityH.GetSubcounty)
		protected.POST("/subcounties", middleware.RequireAnyPermission("admin.all", "facility.write"), facilityH.CreateSubcounty)
		protected.PATCH("/subcounties/:id", middleware.RequireAnyPermission("admin.all", "facility.write"), facilityH.UpdateSubcounty)
		protected.DELETE("/subcounties/:id", middleware.RequireAnyPermission("admin.all", "facility.write"), facilityH.DeleteSubcounty)
		protected.GET("/parishes", facilityH.ListParishes)
		protected.GET("/parishes/:id", facilityH.GetParish)
		protected.POST("/parishes", middleware.RequireAnyPermission("admin.all", "facility.write"), facilityH.CreateParish)
		protected.PATCH("/parishes/:id", middleware.RequireAnyPermission("admin.all", "facility.write"), facilityH.UpdateParish)
		protected.DELETE("/parishes/:id", middleware.RequireAnyPermission("admin.all", "facility.write"), facilityH.DeleteParish)
		protected.GET("/facility-levels", facilityH.ListFacilityLevels)
		protected.GET("/facility-levels/:id", facilityH.GetFacilityLevel)
		protected.POST("/facility-levels", middleware.RequireAnyPermission("admin.all", "facility.write"), facilityH.CreateFacilityLevel)
		protected.PATCH("/facility-levels/:id", middleware.RequireAnyPermission("admin.all", "facility.write"), facilityH.UpdateFacilityLevel)
		protected.DELETE("/facility-levels/:id", middleware.RequireAnyPermission("admin.all", "facility.write"), facilityH.DeleteFacilityLevel)
		protected.GET("/ownership-types", facilityH.ListOwnershipTypes)
		protected.GET("/ownership-types/:id", facilityH.GetOwnershipType)
		protected.POST("/ownership-types", middleware.RequireAnyPermission("admin.all", "facility.write"), facilityH.CreateOwnershipType)
		protected.PATCH("/ownership-types/:id", middleware.RequireAnyPermission("admin.all", "facility.write"), facilityH.UpdateOwnershipType)
		protected.DELETE("/ownership-types/:id", middleware.RequireAnyPermission("admin.all", "facility.write"), facilityH.DeleteOwnershipType)
		protected.GET("/authorities", facilityH.ListAuthorities)
		protected.GET("/authorities/:id", facilityH.GetAuthority)
		protected.POST("/authorities", middleware.RequireAnyPermission("admin.all", "facility.write"), facilityH.CreateAuthority)
		protected.PATCH("/authorities/:id", middleware.RequireAnyPermission("admin.all", "facility.write"), facilityH.UpdateAuthority)
		protected.DELETE("/authorities/:id", middleware.RequireAnyPermission("admin.all", "facility.write"), facilityH.DeleteAuthority)

		protected.GET("/sync/manifest", middleware.RequirePermission("sync.read"), syncH.Manifest)
		protected.POST("/sync/packages", middleware.RequirePermission("admin.all"), syncH.CreatePackage)
		protected.GET("/sync/packages/:id/download", middleware.RequirePermission("sync.read"), syncH.Download)

	}
	return &App{Router: r, DB: database}, nil
}

const swaggerChooserHTML = `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>MediGuide Swagger</title>
  <style>
    :root {
      color-scheme: light;
      --bg: #f3f4f6;
      --panel: #ffffff;
      --border: #d1d5db;
      --text: #111827;
      --muted: #4b5563;
      --accent: #0f766e;
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      min-height: 100vh;
      display: grid;
      place-items: center;
      background:
        radial-gradient(circle at top left, rgba(15,118,110,0.12), transparent 28rem),
        linear-gradient(180deg, #f8fafc 0%, var(--bg) 100%);
      color: var(--text);
      font-family: "IBM Plex Sans", "Segoe UI", sans-serif;
    }
    .panel {
      width: min(30rem, calc(100vw - 2rem));
      background: var(--panel);
      border: 1px solid var(--border);
      border-radius: 18px;
      padding: 1.5rem;
      box-shadow: 0 18px 40px rgba(15, 23, 42, 0.08);
    }
    h1 {
      margin: 0 0 0.5rem;
      font-size: 1.4rem;
    }
    p {
      margin: 0 0 1rem;
      color: var(--muted);
      line-height: 1.5;
    }
    label {
      display: block;
      margin-bottom: 0.5rem;
      font-weight: 600;
    }
    select, button {
      width: 100%;
      border-radius: 12px;
      border: 1px solid var(--border);
      font: inherit;
    }
    select {
      padding: 0.9rem 1rem;
      background: #fff;
      margin-bottom: 0.9rem;
    }
    button {
      padding: 0.9rem 1rem;
      background: var(--accent);
      color: #fff;
      border-color: var(--accent);
      font-weight: 700;
      cursor: pointer;
    }
    .links {
      margin-top: 1rem;
      display: flex;
      gap: 0.75rem;
      flex-wrap: wrap;
    }
    a {
      color: var(--accent);
      text-decoration: none;
      font-weight: 600;
    }
  </style>
</head>
<body>
  <main class="panel">
    <h1>Swagger Docs</h1>
    <p>Select which route set you want to inspect. <code>v1</code> shows legacy compatibility APIs, while <code>v2</code> shows the current backend API.</p>
    <label for="swagger-version">API Version</label>
    <select id="swagger-version">
      <option value="/swagger/v1/index.html">v1 legacy routes</option>
      <option value="/swagger/v2/index.html" selected>v2 current routes</option>
      <option value="/swagger/all/index.html">all routes</option>
    </select>
    <button type="button" onclick="window.location.href=document.getElementById('swagger-version').value">Open Swagger UI</button>
    <div class="links">
      <a href="/swagger/v1/index.html">Open v1</a>
      <a href="/swagger/v2/index.html">Open v2</a>
      <a href="/swagger/all/index.html">Open all</a>
    </div>
  </main>
</body>
</html>`
