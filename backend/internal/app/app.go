package app

import (
	"context"
	"net/http"
	"strings"
	"time"

	"mediguide/internal/buildinfo"
	cachepkg "mediguide/internal/cache"
	"mediguide/internal/config"
	"mediguide/internal/db"
	"mediguide/internal/handlers"
	"mediguide/internal/mailer"
	"mediguide/internal/middleware"
	"mediguide/internal/observability"
	"mediguide/internal/redisx"
	"mediguide/internal/services"
	"mediguide/internal/storage"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/redis/go-redis/v9"
	"github.com/rs/zerolog/log"
	"gorm.io/gorm"

	swaggerFiles "github.com/swaggo/files"
	ginSwagger "github.com/swaggo/gin-swagger"
)

type App struct {
	Router *gin.Engine
	DB     *gorm.DB
	Redis  *redis.Client
	Cache  *cachepkg.Store
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
	redisClient, err := redisx.NewClient(cfg)
	if err != nil {
		return nil, err
	}
	redisContext, cancelRedis := context.WithTimeout(context.Background(), 3*time.Second)
	if err := redisx.Ping(redisContext, redisClient); err != nil {
		log.Warn().Err(err).Msg("redis unavailable during startup; fallbacks will be used")
	}
	cancelRedis()
	cacheStore := cachepkg.New(redisClient, cfg.RedisKeyPrefix, cfg.CacheEnabled, cfg.CacheMaxItemBytes)
	rateLimiter := middleware.NewRateLimiter(redisClient, cfg.RedisKeyPrefix, cfg.RateLimitEnabled).WithAuditDB(database)

	r := gin.New()
	if err := r.SetTrustedProxies(cfg.TrustedProxies); err != nil {
		return nil, err
	}
	r.Use(gin.Recovery(), middleware.RequestLogger(), observability.OutbreakHTTP())

	// Build CORS allow-list from config (comma-separated).
	allowedOrigins := []string{}
	for _, o := range strings.Split(cfg.AllowedOrigins, ",") {
		if trimmed := strings.TrimSpace(o); trimmed != "" {
			allowedOrigins = append(allowedOrigins, trimmed)
		}
	}
	r.Use(cors.New(cors.Config{
		AllowOrigins:  allowedOrigins,
		AllowHeaders:  []string{"Accept", "Authorization", "Content-Type", "If-Match", "If-None-Match"},
		ExposeHeaders: []string{"ETag", "Last-Modified", "Retry-After", "RateLimit-Limit", "RateLimit-Remaining", "RateLimit-Reset"},
		AllowMethods:  []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"},
	}))

	r.GET("/swagger", func(c *gin.Context) {
		c.Data(http.StatusOK, "text/html; charset=utf-8", []byte(swaggerChooserHTML))
	})
	r.GET("/swagger/all/*any", ginSwagger.WrapHandler(swaggerFiles.NewHandler(), ginSwagger.InstanceName("all"), ginSwagger.URL("/swagger/all/doc.json")))
	r.GET("/swagger/v1/*any", ginSwagger.WrapHandler(swaggerFiles.NewHandler(), ginSwagger.InstanceName("v1"), ginSwagger.URL("/swagger/v1/doc.json")))
	r.GET("/swagger/v2/*any", ginSwagger.WrapHandler(swaggerFiles.NewHandler(), ginSwagger.InstanceName("v2"), ginSwagger.URL("/swagger/v2/doc.json")))
	r.GET("/api/healthz", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"ok":       true,
			"service":  cfg.AppName,
			"version":  buildinfo.Version,
			"revision": buildinfo.Revision,
		})
	})
	r.GET("/api/metrics", handlers.OperationsHandler{DB: database, Cache: cacheStore, Store: store}.Metrics)

	// Readiness probe: verify DB connectivity.
	r.GET("/api/readyz", func(c *gin.Context) {
		sqlDB, err := database.DB()
		if err != nil || sqlDB.Ping() != nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"ok": false, "reason": "db_unavailable"})
			return
		}
		if cfg.RateLimitEnabled || cfg.CacheEnabled {
			ctx, cancel := context.WithTimeout(c.Request.Context(), time.Second)
			defer cancel()
			if err := redisx.Ping(ctx, redisClient); err != nil {
				c.JSON(http.StatusServiceUnavailable, gin.H{"ok": false, "reason": "redis_unavailable"})
				return
			}
		}
		storageContext, cancelStorage := context.WithTimeout(c.Request.Context(), 2*time.Second)
		defer cancelStorage()
		if checker, ok := any(store).(interface{ Health(context.Context) error }); ok && checker.Health(storageContext) != nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"ok": false, "reason": "managed_storage_unavailable"})
			return
		}
		c.JSON(http.StatusOK, gin.H{
			"ok":       true,
			"service":  cfg.AppName,
			"version":  buildinfo.Version,
			"revision": buildinfo.Revision,
		})
	})

	authSvc := services.AuthService{DB: database, Cfg: cfg, Mailer: emailSender}
	guidelineSvc := services.GuidelineService{DB: database, Store: store, Cache: cacheStore}
	publicGuidelineSvc := services.PublicGuidelineService{DB: database, Store: store, Cache: cacheStore}
	outbreakSvc := services.OutbreakService{DB: database, Store: store}
	outbreakAdminSvc := services.OutbreakAdminService{DB: database, Store: store, AllowedExternalHosts: cfg.NotificationActionExternalHosts}
	searchSvc := services.SearchService{DB: database, Cache: cacheStore}
	ragSvc := services.RAGService{DB: database, Search: searchSvc, Cfg: cfg}
	protocolSvc := services.ProtocolService{DB: database}
	syncSvc := services.SyncService{DB: database, Store: store, Cfg: cfg}
	referenceSvc := services.ReferenceService{DB: database}
	calculatorSvc := services.CalculatorService{DB: database, LegacyClinicalToolsDir: cfg.LegacyClinicalToolsDir}
	calculatorVersionSvc := services.CalculatorVersionService{DB: database}
	drugSvc := services.DrugService{DB: database}
	drugReferenceSvc := services.DrugReferenceService{DB: database, Cache: cacheStore}
	userSvc := services.UserService{DB: database}
	notificationSvc := services.NotificationService{DB: database, AllowedActionHosts: cfg.NotificationActionExternalHosts, DeviceStaleAfter: time.Duration(cfg.FirebaseDeviceStaleDays) * 24 * time.Hour}
	supportSvc := services.SupportService{DB: database}
	helpContentSvc := services.HelpContentService{DB: database, Cache: cacheStore}
	guidelineContentSvc := services.GuidelineContentService{DB: database, Cache: cacheStore}
	emergencyProtocolSvc := services.EmergencyProtocolService{DB: database}
	contentReferenceSvc := services.ContentReferenceService{DB: database, Cache: cacheStore}
	consultantSvc := services.ConsultantService{DB: database}
	legacyAPISvc := services.LegacyAPIService{DB: database, Cache: cacheStore}
	facilitySvc := services.FacilityService{DB: database, Cache: cacheStore}
	firebaseSvc, err := services.NewFirebaseService(database, cfg)
	if err != nil {
		return nil, err
	}

	authH := handlers.AuthHandler{Service: authSvc}
	guidelineH := handlers.GuidelineHandler{Service: guidelineSvc, MaxUploadMB: cfg.MaxUploadMB}
	publicGuidelineH := handlers.PublicGuidelineHandler{Service: publicGuidelineSvc, Content: publicGuidelineSvc}
	outbreakH := handlers.OutbreakHandler{Service: outbreakSvc}
	outbreakAdminH := handlers.OutbreakAdminHandler{Service: outbreakAdminSvc, MaxUploadMB: cfg.MaxUploadMB}
	searchH := handlers.SearchHandler{Service: searchSvc}
	ragH := handlers.RAGHandler{Service: ragSvc}
	protocolH := handlers.ProtocolHandler{Service: protocolSvc}
	syncH := handlers.SyncHandler{Service: syncSvc}
	referenceH := handlers.ReferenceHandler{Service: referenceSvc}
	calculatorH := handlers.CalculatorHandler{Service: calculatorSvc, Versions: calculatorVersionSvc}
	drugH := handlers.DrugHandler{Service: drugSvc}
	drugReferenceH := handlers.DrugReferenceHandler{Service: drugReferenceSvc}
	userH := handlers.UserHandler{Service: userSvc}
	notificationH := handlers.NotificationHandler{Service: notificationSvc, Outbox: services.NotificationOutboxService{DB: database}}
	supportH := handlers.SupportHandler{Service: supportSvc}
	helpContentH := handlers.HelpContentHandler{Service: helpContentSvc}
	guidelineContentH := handlers.GuidelineContentHandler{Service: guidelineContentSvc}
	emergencyProtocolH := handlers.EmergencyProtocolHandler{Service: emergencyProtocolSvc}
	contentReferenceH := handlers.ContentReferenceHandler{Service: contentReferenceSvc}
	progressUsageH := handlers.ProgressUsageHandler{Service: services.ProgressUsageService{DB: database}}
	guidelineLibraryH := handlers.GuidelineLibraryHandler{Service: services.GuidelineLibraryService{DB: database}}
	conversationH := handlers.ConversationHandler{Service: services.ConversationService{DB: database}}
	consultantH := handlers.ConsultantHandler{Service: consultantSvc}
	legacyAPIH := handlers.LegacyAPIHandler{Service: legacyAPISvc, Cfg: cfg}
	facilityH := handlers.NewFacilityHandler(facilitySvc)
	firebaseH := handlers.FirebaseHandler{Service: firebaseSvc}

	legacyV1 := r.Group("/api/v1")
	legacyV1.GET("/stats", rateLimiter.Limit(middleware.Policy("legacy-public", 60, time.Minute, 10), middleware.IPIdentity), legacyAPIH.Stats)
	legacyV1.GET("/consultants/tree", rateLimiter.Limit(middleware.Policy("legacy-public", 60, time.Minute, 10), middleware.IPIdentity), legacyAPIH.ConsultantsTree)
	legacyV1.GET("/health-facilities/tree", rateLimiter.Limit(middleware.Policy("legacy-public", 60, time.Minute, 10), middleware.IPIdentity), legacyAPIH.HealthFacilitiesTree)
	legacyV1.GET("/ministry-directory/tree", rateLimiter.Limit(middleware.Policy("legacy-public", 60, time.Minute, 10), middleware.IPIdentity), legacyAPIH.MinistryDirectoryTree)
	legacyProtected := legacyV1.Group("")
	legacyProtected.Use(middleware.AuthRequired(cfg, database), middleware.PrivateNoStore())
	legacyProtected.GET("/overview", legacyAPIH.Overview)

	legacyCompat := r.Group("/api")
	legacyCompat.Use(middleware.AuthRequired(cfg, database), middleware.PrivateNoStore())
	legacyCompat.GET("/overview", legacyAPIH.Overview)

	public := r.Group("/api/public")
	public.Use(rateLimiter.Limit(middleware.Policy("public-guidelines", 120, time.Minute, 20), middleware.IPIdentity))
	{
		public.GET("/guidelines", publicGuidelineH.List)
		public.GET("/search", rateLimiter.Limit(middleware.Policy("public-search", 60, time.Minute, 10), middleware.IPIdentity), searchH.PublicSearch)
		public.GET("/guidelines/:id", publicGuidelineH.Get)
		public.GET("/guidelines/:id/manifest", publicGuidelineH.Manifest)
		public.GET("/guidelines/:id/sections", publicGuidelineH.Sections)
		public.GET("/guidelines/:id/sections/:sectionId", publicGuidelineH.Section)
		public.GET("/guidelines/:id/tables", publicGuidelineH.Tables)
		public.GET("/guidelines/:id/figures", publicGuidelineH.Figures)
		public.GET("/guidelines/:id/algorithms", publicGuidelineH.Algorithms)
		public.GET("/guidelines/:id/original", rateLimiter.Limit(middleware.Policy("public-guideline-original", 30, time.Minute, 5), middleware.IPIdentity), publicGuidelineH.Original)
		public.GET("/guidelines/:id/offline-package", rateLimiter.Limit(middleware.Policy("public-guideline-offline", 20, time.Minute, 3), middleware.IPIdentity), publicGuidelineH.OfflinePackage)
		public.GET("/guidelines/:id/markdown", rateLimiter.Limit(middleware.Policy("public-markdown", 60, time.Minute, 10), middleware.IPIdentity), publicGuidelineH.Markdown)
		outbreakReadLimit := rateLimiter.Limit(middleware.Policy("public-outbreaks", 90, time.Minute, 15), middleware.IPIdentity)
		public.GET("/outbreaks", outbreakReadLimit, outbreakH.List)
		public.GET("/outbreaks/:id", outbreakReadLimit, outbreakH.Get)
		public.GET("/outbreaks/:id/updates", outbreakReadLimit, outbreakH.Updates)
		public.GET("/outbreaks/:id/resources", outbreakReadLimit, outbreakH.Resources)
		public.GET("/situation-reports", outbreakReadLimit, outbreakH.ListReports)
		public.GET("/situation-reports/:id", outbreakReadLimit, outbreakH.GetReport)
		public.GET("/situation-reports/:id/asset", outbreakReadLimit, outbreakH.ReportAsset)
	}

	v2 := r.Group("/api/v2")
	{
		privateNoStore := middleware.PrivateNoStore()
		v2.POST("/auth/register", privateNoStore, rateLimiter.Limit(middleware.Policy("auth-register", 5, time.Hour, 1), middleware.IPIdentity), authH.Register)
		v2.POST("/auth/login",
			privateNoStore,
			rateLimiter.Limit(middleware.Policy("auth-login-ip", 10, 5*time.Minute, 2), middleware.IPIdentity),
			rateLimiter.Limit(middleware.Policy("auth-login-account", 5, 15*time.Minute, 0), middleware.IPAndJSONFieldIdentity("email")), authH.Login)
		v2.POST("/auth/refresh",
			privateNoStore,
			rateLimiter.Limit(middleware.Policy("auth-refresh-ip", 60, time.Minute, 5), middleware.IPIdentity),
			rateLimiter.Limit(middleware.Policy("auth-refresh-session", 30, time.Minute, 5), middleware.IPAndJSONFieldIdentity("refresh_token")), authH.Refresh)
		v2.POST("/auth/password-reset/request",
			privateNoStore,
			rateLimiter.Limit(middleware.Policy("password-reset-ip", 5, 15*time.Minute, 0), middleware.IPIdentity),
			rateLimiter.Limit(middleware.Policy("password-reset-account", 3, time.Hour, 0), middleware.IPAndJSONFieldIdentity("email")), authH.RequestPasswordReset)
		v2.POST("/auth/password-reset/confirm",
			privateNoStore,
			rateLimiter.Limit(middleware.Policy("password-reset-confirm-ip", 10, 15*time.Minute, 0), middleware.IPIdentity),
			rateLimiter.Limit(middleware.Policy("password-reset-confirm-token", 5, 15*time.Minute, 0), middleware.IPAndJSONFieldIdentity("token")), authH.ConfirmPasswordReset)
		v2.POST("/auth/email-verification/request", privateNoStore, rateLimiter.Limit(middleware.Policy("email-verification-request", 5, 15*time.Minute, 0), middleware.IPAndJSONFieldIdentity("email")), authH.RequestEmailVerification)
		v2.POST("/auth/email-verification/confirm", privateNoStore, rateLimiter.Limit(middleware.Policy("email-verification-confirm", 10, 15*time.Minute, 0), middleware.IPAndJSONFieldIdentity("token")), authH.ConfirmEmailVerification)
		protected := v2.Group("")
		protected.Use(
			middleware.AuthRequired(cfg, database),
			privateNoStore,
			middleware.ByMethod(
				rateLimiter.Limit(middleware.Policy("authenticated-read", 300, time.Minute, 30), middleware.UserIdentity),
				rateLimiter.Limit(middleware.Policy("authenticated-write", 120, time.Minute, 20), middleware.UserIdentity),
			),
		)
		protected.POST("/auth/logout", authH.Logout)
		protected.GET("/me", authH.Me)
		protected.POST("/me/password", rateLimiter.Limit(middleware.Policy("password-change", 5, time.Hour, 0), middleware.UserIdentity), authH.ChangePassword)

		protected.GET("/outbreaks", middleware.RequirePermission("outbreak.read"), outbreakAdminH.ListOutbreaks)
		protected.POST("/outbreaks", middleware.RequirePermission("outbreak.manage"), outbreakAdminH.CreateOutbreak)
		protected.GET("/outbreaks/:id", middleware.RequirePermission("outbreak.read"), outbreakAdminH.GetOutbreak)
		protected.PATCH("/outbreaks/:id", middleware.RequirePermission("outbreak.manage"), outbreakAdminH.UpdateOutbreak)
		protected.DELETE("/outbreaks/:id", middleware.RequirePermission("outbreak.manage"), outbreakAdminH.DeleteOutbreak)
		protected.POST("/outbreaks/:id/submit", middleware.RequirePermission("outbreak.manage"), outbreakAdminH.TransitionOutbreak("submit"))
		protected.POST("/outbreaks/:id/approve", middleware.RequirePermission("outbreak.review"), outbreakAdminH.TransitionOutbreak("approve"))
		protected.POST("/outbreaks/:id/publish", middleware.RequirePermission("outbreak.publish"), outbreakAdminH.TransitionOutbreak("publish"))
		protected.POST("/outbreaks/:id/withdraw", middleware.RequirePermission("outbreak.withdraw"), outbreakAdminH.TransitionOutbreak("withdraw"))
		protected.POST("/outbreaks/:id/correct", middleware.RequirePermission("outbreak.manage"), outbreakAdminH.CorrectOutbreak)
		protected.GET("/outbreaks/:id/audit", middleware.RequirePermission("outbreak.read"), outbreakAdminH.ListAudit("outbreak"))
		protected.POST("/outbreaks/:id/review-comments", middleware.RequirePermission("outbreak.review"), outbreakAdminH.AddReviewComment("outbreak"))
		protected.GET("/outbreaks/:id/updates", middleware.RequirePermission("outbreak.read"), outbreakAdminH.ListUpdates)
		protected.POST("/outbreaks/:id/updates", middleware.RequirePermission("outbreak.manage"), outbreakAdminH.CreateUpdate)
		protected.GET("/outbreaks/:id/updates/:updateId", middleware.RequirePermission("outbreak.read"), outbreakAdminH.GetUpdate)
		protected.PATCH("/outbreaks/:id/updates/:updateId", middleware.RequirePermission("outbreak.manage"), outbreakAdminH.UpdateUpdate)
		protected.DELETE("/outbreaks/:id/updates/:updateId", middleware.RequirePermission("outbreak.manage"), outbreakAdminH.DeleteUpdate)
		protected.POST("/outbreaks/:id/updates/:updateId/submit", middleware.RequirePermission("outbreak.manage"), outbreakAdminH.TransitionUpdate("submit"))
		protected.POST("/outbreaks/:id/updates/:updateId/approve", middleware.RequirePermission("outbreak.review"), outbreakAdminH.TransitionUpdate("approve"))
		protected.POST("/outbreaks/:id/updates/:updateId/publish", middleware.RequirePermission("outbreak.publish"), outbreakAdminH.TransitionUpdate("publish"))
		protected.POST("/outbreaks/:id/updates/:updateId/withdraw", middleware.RequirePermission("outbreak.withdraw"), outbreakAdminH.TransitionUpdate("withdraw"))
		protected.POST("/outbreaks/:id/updates/:updateId/correct", middleware.RequirePermission("outbreak.manage"), outbreakAdminH.CorrectUpdate)
		protected.GET("/outbreaks/:id/resources", middleware.RequirePermission("outbreak.read"), outbreakAdminH.ListResources)
		protected.POST("/outbreaks/:id/resources", middleware.RequirePermission("outbreak.manage"), outbreakAdminH.CreateResource)
		protected.GET("/outbreaks/:id/resources/:resourceId", middleware.RequirePermission("outbreak.read"), outbreakAdminH.GetResource)
		protected.PATCH("/outbreaks/:id/resources/:resourceId", middleware.RequirePermission("outbreak.manage"), outbreakAdminH.UpdateResource)
		protected.DELETE("/outbreaks/:id/resources/:resourceId", middleware.RequirePermission("outbreak.manage"), outbreakAdminH.DeleteResource)
		protected.POST("/outbreaks/:id/resources/:resourceId/submit", middleware.RequirePermission("outbreak.manage"), outbreakAdminH.TransitionResource("submit"))
		protected.POST("/outbreaks/:id/resources/:resourceId/approve", middleware.RequirePermission("outbreak.review"), outbreakAdminH.TransitionResource("approve"))
		protected.POST("/outbreaks/:id/resources/:resourceId/publish", middleware.RequirePermission("outbreak.publish"), outbreakAdminH.TransitionResource("publish"))
		protected.POST("/outbreaks/:id/resources/:resourceId/withdraw", middleware.RequirePermission("outbreak.withdraw"), outbreakAdminH.TransitionResource("withdraw"))
		protected.POST("/outbreaks/:id/resources/:resourceId/correct", middleware.RequirePermission("outbreak.manage"), outbreakAdminH.CorrectResource)
		protected.GET("/situation-reports", middleware.RequirePermission("situation_report.read"), outbreakAdminH.ListReports)
		protected.POST("/situation-reports", middleware.RequirePermission("situation_report.manage"), outbreakAdminH.CreateReport)
		protected.GET("/situation-reports/:id", middleware.RequirePermission("situation_report.read"), outbreakAdminH.GetReport)
		protected.PATCH("/situation-reports/:id", middleware.RequirePermission("situation_report.manage"), outbreakAdminH.UpdateReport)
		protected.DELETE("/situation-reports/:id", middleware.RequirePermission("situation_report.manage"), outbreakAdminH.DeleteReport)
		protected.POST("/situation-reports/:id/submit", middleware.RequirePermission("situation_report.manage"), outbreakAdminH.TransitionReport("submit"))
		protected.POST("/situation-reports/:id/approve", middleware.RequirePermission("situation_report.review"), outbreakAdminH.TransitionReport("approve"))
		protected.POST("/situation-reports/:id/publish", middleware.RequirePermission("situation_report.publish"), outbreakAdminH.TransitionReport("publish"))
		protected.POST("/situation-reports/:id/withdraw", middleware.RequirePermission("situation_report.withdraw"), outbreakAdminH.TransitionReport("withdraw"))
		protected.POST("/situation-reports/:id/correct", middleware.RequirePermission("situation_report.manage"), outbreakAdminH.CorrectReport)
		protected.POST("/situation-reports/:id/asset", middleware.RequirePermission("situation_report.manage"), outbreakAdminH.UploadReportAsset)
		protected.GET("/situation-reports/:id/audit", middleware.RequirePermission("situation_report.read"), outbreakAdminH.ListAudit("situation_report"))
		protected.POST("/situation-reports/:id/review-comments", middleware.RequirePermission("situation_report.review"), outbreakAdminH.AddReviewComment("situation_report"))

		protected.GET("/calculators", middleware.RequireAnyPermission("calculator.read", "guideline.read"), calculatorH.List)
		protected.GET("/calculators/:id", middleware.RequireAnyPermission("calculator.read", "guideline.read"), calculatorH.Get)
		protected.POST("/calculators", middleware.RequireAnyPermission("calculator.write", "guideline.write"), calculatorH.Create)
		protected.PATCH("/calculators/:id", middleware.RequireAnyPermission("calculator.write", "guideline.write"), calculatorH.Update)
		protected.DELETE("/calculators/:id", middleware.RequireAnyPermission("calculator.write", "guideline.write"), calculatorH.Delete)
		protected.GET("/calculators/:id/content", middleware.RequireAnyPermission("calculator.read", "guideline.read"), calculatorH.Content)
		protected.GET("/calculators/:id/definition", middleware.RequireAnyPermission("calculator.read", "guideline.read"), calculatorH.Definition)
		protected.GET("/calculators/:id/versions", middleware.RequirePermission("calculator.write"), calculatorH.ListVersions)
		protected.POST("/calculators/:id/versions", middleware.RequirePermission("calculator.write"), calculatorH.CreateVersion)
		protected.GET("/calculator-versions/review-queue", middleware.RequirePermission("calculator.review"), calculatorH.ReviewQueue)
		protected.GET("/calculator-versions/:id", middleware.RequirePermission("calculator.write"), calculatorH.GetVersion)
		protected.GET("/calculator-versions/:id/preview", middleware.RequirePermission("calculator.review"), calculatorH.PreviewVersion)
		protected.PATCH("/calculator-versions/:id", middleware.RequirePermission("calculator.write"), calculatorH.UpdateVersion)
		protected.DELETE("/calculator-versions/:id", middleware.RequirePermission("calculator.write"), calculatorH.DeleteVersion)
		protected.POST("/calculator-versions/:id/duplicate", middleware.RequirePermission("calculator.write"), calculatorH.DuplicateVersion)
		protected.POST("/calculator-versions/:id/validate", middleware.RequirePermission("calculator.write"), rateLimiter.Limit(middleware.Policy("calculator-version-validate", 30, time.Minute, 5), middleware.UserIdentity), calculatorH.ValidateVersion)
		protected.POST("/calculator-versions/:id/test", middleware.RequirePermission("calculator.write"), rateLimiter.Limit(middleware.Policy("calculator-version-test", 20, time.Minute, 3), middleware.UserIdentity), calculatorH.TestVersion)
		protected.POST("/calculator-versions/:id/submit", middleware.RequirePermission("calculator.write"), calculatorH.SubmitVersion)
		protected.POST("/calculator-versions/:id/approve", middleware.RequirePermission("calculator.review"), calculatorH.ApproveVersion)
		protected.POST("/calculator-versions/:id/publish", middleware.RequirePermission("calculator.publish"), rateLimiter.Limit(middleware.Policy("calculator-version-publish", 10, time.Hour, 1), middleware.UserIdentity), calculatorH.PublishVersion)
		protected.POST("/calculators/:id/runtime/legacy", middleware.RequirePermission("calculator.publish"), rateLimiter.Limit(middleware.Policy("calculator-runtime-rollback", 10, time.Hour, 1), middleware.UserIdentity), calculatorH.SelectLegacyRuntime)
		protected.POST("/calculator-versions/:id/withdraw", middleware.RequirePermission("calculator.withdraw"), calculatorH.WithdrawVersion)
		protected.GET("/calculator-versions/:id/audit", middleware.RequirePermission("calculator.review"), calculatorH.VersionAudit)
		protected.POST("/calculator-versions/:id/review-comments", middleware.RequirePermission("calculator.review"), calculatorH.AddVersionReviewComment)
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

		protected.GET("/notifications", middleware.RequirePermission("notification.read"), notificationH.List)
		protected.GET("/notifications/:id", middleware.RequirePermission("notification.read"), notificationH.Get)
		protected.POST("/notifications", middleware.RequirePermission("notification.publish"), rateLimiter.Limit(middleware.Policy("notification-publication", 20, time.Hour, 0), middleware.UserIdentity), rateLimiter.LimitWhen(middleware.Policy("notification-urgent-publication", 3, time.Hour, 0), middleware.UserIdentity, middleware.JSONFieldEquals("priority", "urgent")), notificationH.Create)
		protected.POST("/notifications/read-all", middleware.RequirePermission("notification.read"), notificationH.MarkAllRead)
		protected.POST("/notifications/:id/read", middleware.RequirePermission("notification.read"), notificationH.MarkRead)
		protected.POST("/notifications/:id/unread", middleware.RequirePermission("notification.read"), notificationH.MarkUnread)
		protected.POST("/notification-deliveries/:id/open", middleware.RequirePermission("notification.read"), rateLimiter.Limit(middleware.Policy("notification-delivery-event", 120, time.Hour, 10), middleware.UserIdentity), notificationH.RecordDeliveryOpen)
		protected.POST("/notification-deliveries/:id/click", middleware.RequirePermission("notification.read"), rateLimiter.Limit(middleware.Policy("notification-delivery-event", 120, time.Hour, 10), middleware.UserIdentity), notificationH.RecordDeliveryClick)
		protected.GET("/firebase/status", middleware.RequirePermission("firebase.status.read"), firebaseH.Status)
		protected.GET("/firebase/devices", firebaseH.ListDevices)
		protected.POST("/firebase/devices", firebaseH.RegisterDevice)
		protected.PATCH("/firebase/devices/:id", firebaseH.UpdateDevice)
		protected.DELETE("/firebase/devices/:id", firebaseH.DeleteDevice)
		protected.POST("/firebase/push/test", middleware.RequirePermission("firebase.push.test"), rateLimiter.Limit(middleware.Policy("firebase-test-push", 10, time.Hour, 0), middleware.UserIdentity), firebaseH.SendTestPush)
		protected.GET("/firebase/test-recipients", middleware.RequirePermission("firebase.push.test"), firebaseH.SearchTestRecipients)
		protected.GET("/firebase/remote-config", middleware.RequirePermission("firebase.config.manage"), firebaseH.GetRemoteConfig)
		protected.PUT("/firebase/remote-config", middleware.RequirePermission("firebase.config.manage"), rateLimiter.Limit(middleware.Policy("firebase-remote-config-write", 10, time.Hour, 0), middleware.UserIdentity), firebaseH.PutRemoteConfig)
		protected.GET("/notification-preferences", notificationH.GetPreferences)
		protected.PATCH("/notification-preferences", rateLimiter.Limit(middleware.Policy("notification-preference-write", 30, time.Hour, 0), middleware.UserIdentity), notificationH.UpdatePreferences)
		protected.GET("/notification-preferences/aggregates", middleware.RequirePermission("notification.analytics.read"), notificationH.PreferenceAggregates)

		protected.GET("/notification-templates", middleware.RequirePermission("notification.template.read"), notificationH.ListTemplates)
		protected.GET("/notification-templates/:id", middleware.RequirePermission("notification.template.read"), notificationH.GetTemplate)
		protected.POST("/notification-templates", middleware.RequirePermission("notification.template.manage"), notificationH.CreateTemplate)
		protected.PATCH("/notification-templates/:id", middleware.RequirePermission("notification.template.manage"), notificationH.UpdateTemplate)
		protected.PATCH("/notification-templates/:id/status", middleware.RequirePermission("notification.template.manage"), notificationH.UpdateTemplateStatus)
		protected.GET("/notification-templates/:id/versions", middleware.RequirePermission("notification.template.read"), notificationH.ListTemplateVersions)
		protected.POST("/notification-template-versions/:id/preview", middleware.RequirePermission("notification.template.read"), notificationH.PreviewTemplateVersion)
		protected.POST("/notification-templates/:id/clone", middleware.RequirePermission("notification.template.manage"), notificationH.CloneTemplate)
		protected.DELETE("/notification-templates/:id", middleware.RequirePermission("notification.template.manage"), notificationH.DeleteTemplate)
		protected.GET("/notification-campaigns", middleware.RequirePermission("notification.campaign.read"), notificationH.ListCampaigns)
		protected.POST("/notification-campaigns/audience-estimate", middleware.RequirePermission("notification.campaign.manage"), rateLimiter.Limit(middleware.Policy("notification-audience-estimate", 60, time.Hour, 10), middleware.UserIdentity), notificationH.EstimateAudience)
		protected.GET("/notification-campaigns/:id", middleware.RequirePermission("notification.campaign.read"), notificationH.GetCampaign)
		campaignCreateLimit := rateLimiter.Limit(middleware.Policy("notification-campaign-creation", 10, time.Hour, 0), middleware.UserIdentity)
		urgentCampaignCreateLimit := rateLimiter.LimitWhen(middleware.Policy("notification-urgent-campaign-creation", 3, time.Hour, 0), middleware.UserIdentity, middleware.JSONFieldEquals("priority", "urgent"))
		protected.POST("/notification-campaigns", middleware.RequirePermission("notification.campaign.manage"), campaignCreateLimit, urgentCampaignCreateLimit, notificationH.CreateCampaign)
		protected.POST("/guidelines/:id/notification-campaign", middleware.RequirePermission("notification.campaign.manage"), campaignCreateLimit, urgentCampaignCreateLimit, notificationH.CreateGuidelineCampaign)
		protected.POST("/outbreaks/:id/notification-campaign", middleware.RequirePermission("notification.campaign.manage"), middleware.RequirePermission("outbreak.publish"), campaignCreateLimit, urgentCampaignCreateLimit, notificationH.CreateOutbreakCampaign)
		protected.POST("/situation-reports/:id/notification-campaign", middleware.RequirePermission("notification.campaign.manage"), middleware.RequirePermission("situation_report.publish"), campaignCreateLimit, urgentCampaignCreateLimit, notificationH.CreateSituationReportCampaign)
		protected.PATCH("/notification-campaigns/:id", middleware.RequirePermission("notification.campaign.manage"), notificationH.UpdateCampaign)
		protected.POST("/notification-campaigns/:id/submit", middleware.RequirePermission("notification.campaign.manage"), rateLimiter.Limit(middleware.Policy("notification-campaign-write", 10, time.Hour, 0), middleware.UserIdentity), notificationH.TransitionCampaign)
		protected.POST("/notification-campaigns/:id/approve", middleware.RequirePermission("notification.campaign.approve"), rateLimiter.Limit(middleware.Policy("notification-campaign-approval", 20, time.Hour, 0), middleware.UserIdentity), rateLimiter.LimitWhen(middleware.Policy("notification-urgent-campaign-approval", 3, time.Hour, 0), middleware.UserIdentity, middleware.CampaignIsUrgent(database)), notificationH.TransitionCampaign)
		protected.POST("/notification-campaigns/:id/reject", middleware.RequirePermission("notification.campaign.approve"), notificationH.TransitionCampaign)
		protected.POST("/notification-campaigns/:id/schedule", middleware.RequirePermission("notification.campaign.manage"), rateLimiter.Limit(middleware.Policy("notification-campaign-scheduling", 10, time.Hour, 0), middleware.UserIdentity), rateLimiter.LimitWhen(middleware.Policy("notification-urgent-campaign-scheduling", 3, time.Hour, 0), middleware.UserIdentity, middleware.CampaignIsUrgent(database)), notificationH.TransitionCampaign)
		protected.POST("/notification-campaigns/:id/cancel", middleware.RequirePermission("notification.campaign.manage"), notificationH.TransitionCampaign)
		protected.POST("/notification-campaigns/:id/pause", middleware.RequirePermission("notification.campaign.manage"), notificationH.TransitionCampaign)
		protected.POST("/notification-campaigns/:id/resume", middleware.RequirePermission("notification.campaign.manage"), notificationH.TransitionCampaign)
		protected.DELETE("/notification-campaigns/:id", middleware.RequirePermission("notification.campaign.manage"), notificationH.DeleteCampaign)
		protected.GET("/notification-delivery-jobs", middleware.RequirePermission("notification.analytics.read"), notificationH.ListDeliveryJobs)
		protected.GET("/notification-deliveries", middleware.RequirePermission("notification.analytics.read"), notificationH.ListDeliveries)
		protected.GET("/notification-delivery-analytics/daily", middleware.RequirePermission("notification.analytics.read"), notificationH.DeliveryAnalytics)
		protected.POST("/notification-delivery-jobs/:id/requeue", middleware.RequirePermission("notification.campaign.manage"), rateLimiter.Limit(middleware.Policy("notification-delivery-requeue", 20, time.Hour, 0), middleware.UserIdentity), notificationH.RequeueDeliveryJob)

		protected.GET("/support/tickets", supportH.ListTickets)
		protected.GET("/support/tickets/:id", supportH.GetTicket)
		protected.POST("/support/tickets", rateLimiter.Limit(middleware.Policy("support-ticket-create", 5, time.Hour, 1), middleware.UserIdentity), supportH.CreateTicket)
		protected.PATCH("/support/tickets/:id", supportH.UpdateTicket)
		protected.DELETE("/support/tickets/:id", supportH.DeleteTicket)
		protected.GET("/support/tickets/:id/replies", supportH.ListReplies)
		protected.POST("/support/tickets/:id/replies", rateLimiter.Limit(middleware.Policy("support-reply-create", 30, time.Minute, 5), middleware.UserIdentity), supportH.CreateReply)

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
		protected.POST("/faq-tags/recalculate-usage", middleware.RequireAnyPermission("admin.all", "content.write", "guideline.write"), rateLimiter.Limit(middleware.Policy("faq-tag-recalculation", 5, 15*time.Minute, 0), middleware.UserIdentity), helpContentH.RecalculateTagUsage)
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
		protected.GET("/guidelines", middleware.RequireAnyPermission("guideline.write", "guideline.markdown.read"), guidelineH.List)
		protected.GET("/guidelines/:id", middleware.RequireAnyPermission("guideline.write", "guideline.markdown.read"), guidelineH.Get)
		protected.PATCH("/guidelines/:id", middleware.RequirePermission("guideline.write"), guidelineH.Update)
		protected.POST("/guidelines/:id/versions", middleware.RequirePermission("guideline.write"), guidelineH.CreateVersion)
		protected.POST("/guideline-versions/:id/upload", middleware.RequirePermission("guideline.markdown.upload"), rateLimiter.Limit(middleware.Policy("guideline-upload", 10, time.Hour, 0), middleware.UserIdentity), rateLimiter.Concurrency("guideline-upload", 1, 15*time.Minute, middleware.UserIdentity), guidelineH.UploadPDF)
		protected.POST("/guideline-versions/:id/publish", middleware.RequirePermission("guideline.publish"), rateLimiter.Limit(middleware.Policy("guideline-publish", 10, time.Hour, 0), middleware.UserIdentity), guidelineH.Publish)
		protected.GET("/guideline-versions/:id/review", middleware.RequirePermission("guideline.review"), guidelineH.ReviewWorkspace)
		protected.GET("/guideline-versions/:id/extraction-status", middleware.RequirePermission("guideline.markdown.read"), guidelineH.ExtractionStatus)
		protected.GET("/guideline-versions/:id/preview", middleware.RequirePermission("guideline.markdown.read"), guidelineH.PreviewVersion)
		protected.POST("/guideline-versions/:id/assets", middleware.RequirePermission("guideline.asset.manage"), rateLimiter.Limit(middleware.Policy("guideline-asset-upload", 60, time.Hour, 10), middleware.UserIdentity), guidelineH.CreateGuidelineAsset)
		protected.GET("/guideline-versions/:id/assets", middleware.RequirePermission("guideline.markdown.read"), guidelineH.ListGuidelineAssets)
		protected.GET("/guideline-versions/:id/assets/:assetId", middleware.RequirePermission("guideline.markdown.read"), guidelineH.GetGuidelineAsset)
		protected.GET("/guideline-versions/:id/assets/:assetId/content", middleware.RequirePermission("guideline.markdown.read"), guidelineH.ReviewAsset)
		protected.PATCH("/guideline-versions/:id/assets/:assetId", middleware.RequirePermission("guideline.asset.manage"), guidelineH.UpdateGuidelineAsset)
		protected.DELETE("/guideline-versions/:id/assets/:assetId", middleware.RequirePermission("guideline.asset.manage"), guidelineH.DeleteGuidelineAsset)
		protected.POST("/guideline-versions/:id/assets/:assetId/review", middleware.RequirePermission("guideline.high_risk.approve"), guidelineH.ReviewGuidelineAsset)
		protected.POST("/guideline-versions/:id/validate-publication", middleware.RequirePermission("guideline.publish"), guidelineH.ValidatePublication)
		protected.GET("/guideline-versions/:id/sections", middleware.RequirePermission("guideline.write"), guidelineH.Sections)
		protected.POST("/guideline-versions/:id/sections", middleware.RequirePermission("guideline.markdown.edit"), guidelineH.CreateReviewSection)
		protected.PUT("/guideline-versions/:id/sections/reorder", middleware.RequirePermission("guideline.markdown.edit"), guidelineH.ReorderReviewSections)
		protected.PATCH("/guideline-versions/:id/sections/:sectionId", middleware.RequirePermission("guideline.markdown.edit"), guidelineH.UpdateReviewSection)
		protected.DELETE("/guideline-versions/:id/sections/:sectionId", middleware.RequirePermission("guideline.markdown.edit"), guidelineH.DeleteReviewSection)
		protected.POST("/guideline-versions/:id/sections/:sectionId/split", middleware.RequirePermission("guideline.markdown.edit"), guidelineH.SplitReviewSection)
		protected.POST("/guideline-versions/:id/sections/:sectionId/merge", middleware.RequirePermission("guideline.markdown.edit"), guidelineH.MergeReviewSection)
		protected.PATCH("/guideline-versions/:id/blocks/:blockId", middleware.RequirePermission("guideline.markdown.edit"), guidelineH.UpdateReviewBlock)
		protected.POST("/guideline-versions/:id/blocks", middleware.RequirePermission("guideline.markdown.edit"), guidelineH.CreateReviewBlock)
		protected.PUT("/guideline-versions/:id/blocks/reorder", middleware.RequirePermission("guideline.markdown.edit"), guidelineH.ReorderReviewBlocks)
		protected.DELETE("/guideline-versions/:id/blocks/:blockId", middleware.RequirePermission("guideline.markdown.edit"), guidelineH.DeleteReviewBlock)
		protected.POST("/guideline-versions/:id/blocks/:blockId/review", middleware.RequirePermission("guideline.high_risk.approve"), guidelineH.ReviewBlock)
		protected.GET("/guideline-versions/:id/chunks", middleware.RequirePermission("guideline.write"), guidelineH.Chunks)
		protected.GET("/guideline-versions/:id/extracted/:format", middleware.RequirePermission("guideline.write"), guidelineH.ExtractedAsset)
		protected.PUT("/guideline-versions/:id/extracted/markdown", middleware.RequirePermission("guideline.write"), guidelineH.UpdateMarkdown)
		protected.GET("/guideline-versions/:id/markdown-draft", middleware.RequirePermission("guideline.markdown.read"), guidelineH.GetMarkdownDraft)
		protected.PUT("/guideline-versions/:id/markdown-draft", middleware.RequirePermission("guideline.markdown.edit"), rateLimiter.Limit(middleware.Policy("guideline-markdown-save", 120, time.Hour, 20), middleware.UserIdentity), guidelineH.SaveMarkdownDraft)
		protected.GET("/guideline-versions/:id/markdown-revisions", middleware.RequirePermission("guideline.markdown.read"), guidelineH.ListMarkdownRevisions)
		protected.POST("/guideline-versions/:id/markdown-revisions", middleware.RequirePermission("guideline.markdown.edit"), rateLimiter.Limit(middleware.Policy("guideline-markdown-checkpoint", 60, time.Hour, 10), middleware.UserIdentity), guidelineH.CreateMarkdownRevision)
		protected.GET("/guideline-versions/:id/markdown-revisions/:revisionId", middleware.RequirePermission("guideline.markdown.read"), guidelineH.GetMarkdownRevision)
		protected.GET("/guideline-versions/:id/markdown-revisions/:revisionId/validation", middleware.RequirePermission("guideline.markdown.read"), guidelineH.ValidateMarkdownRevision)
		protected.GET("/guideline-versions/:id/markdown-revisions/:revisionId/download", middleware.RequirePermission("guideline.markdown.read"), guidelineH.DownloadMarkdownRevision)
		protected.POST("/guideline-versions/:id/markdown-revisions/:revisionId/restore", middleware.RequirePermission("guideline.revision.restore"), guidelineH.RestoreMarkdownRevision)
		protected.POST("/guideline-versions/:id/duplicate", middleware.RequirePermission("guideline.markdown.edit"), rateLimiter.Limit(middleware.Policy("guideline-markdown-duplicate", 30, time.Hour, 5), middleware.UserIdentity), guidelineH.DuplicateMarkdownVersion)
		protected.POST("/guideline-versions/:id/regenerate", middleware.RequirePermission("guideline.structure.regenerate"), rateLimiter.Limit(middleware.Policy("guideline-regenerate", 20, time.Hour, 2), middleware.UserIdentity), rateLimiter.Concurrency("guideline-regenerate", 1, 15*time.Minute, middleware.UserIdentity), guidelineH.RegenerateMarkdown)
		protected.GET("/guideline-versions/:id/regeneration-jobs/:jobId", middleware.RequirePermission("guideline.markdown.read"), guidelineH.GetRegenerationJob)
		protected.POST("/guideline-versions/:id/regeneration-jobs/:jobId/cancel", middleware.RequirePermission("guideline.structure.regenerate"), guidelineH.CancelRegenerationJob)
		protected.POST("/guideline-versions/:id/regeneration-jobs/:jobId/retry", middleware.RequirePermission("guideline.structure.regenerate"), guidelineH.RetryRegenerationJob)
		protected.GET("/guideline-versions/:id/regeneration-reviews/:jobId", middleware.RequirePermission("guideline.review"), guidelineH.GetRegenerationReview)
		protected.POST("/guideline-versions/:id/regeneration-reviews/:jobId/accept", middleware.RequirePermission("guideline.high_risk.approve"), guidelineH.AcceptRegeneration)
		protected.POST("/guideline-versions/:id/regeneration-reviews/:jobId/reject", middleware.RequirePermission("guideline.review"), guidelineH.RejectRegeneration)
		protected.GET("/guideline-versions/:id/regeneration-reviews/:jobId/comments", middleware.RequirePermission("guideline.review"), guidelineH.ListRegenerationComments)
		protected.POST("/guideline-versions/:id/regeneration-reviews/:jobId/comments", middleware.RequirePermission("guideline.review"), guidelineH.AddRegenerationComment)
		protected.GET("/guideline-versions/:id/reviewers", middleware.RequirePermission("guideline.review"), guidelineH.ListGuidelineReviewAssignments)
		protected.POST("/guideline-versions/:id/reviewers", middleware.RequirePermission("guideline.review"), guidelineH.AssignGuidelineReviewer)
		protected.PATCH("/guideline-versions/:id/reviewers/:assignmentId", middleware.RequirePermission("guideline.review"), guidelineH.UpdateGuidelineReviewAssignment)
		protected.GET("/guideline-versions/:id/review-comments", middleware.RequirePermission("guideline.review"), guidelineH.ListGuidelineEditorComments)
		protected.POST("/guideline-versions/:id/review-comments", middleware.RequirePermission("guideline.review"), guidelineH.CreateGuidelineEditorComment)
		protected.PATCH("/guideline-versions/:id/review-comments/:commentId", middleware.RequirePermission("guideline.review"), guidelineH.ResolveGuidelineEditorComment)
		protected.GET("/guideline-versions/:id/activity", middleware.RequirePermission("guideline.review"), guidelineH.GuidelineActivity)

		protected.GET("/search", middleware.RequirePermission("guideline.read"), rateLimiter.Limit(middleware.Policy("guideline-search", 60, time.Minute, 10), middleware.UserIdentity), searchH.Search)
		protected.POST("/chat/ask", middleware.RequirePermission("chat.ask"),
			rateLimiter.Limit(middleware.Policy("ai-chat-minute", 10, time.Minute, 2), middleware.UserIdentity),
			rateLimiter.Limit(middleware.Policy("ai-chat-daily", 100, 24*time.Hour, 0), middleware.UserIdentity),
			rateLimiter.Concurrency("ai-chat-user", 2, 3*time.Minute, middleware.UserIdentity),
			rateLimiter.Concurrency("ai-chat-global", 20, 3*time.Minute, middleware.StaticIdentity("global")), ragH.Ask)

		protected.POST("/protocols", middleware.RequirePermission("protocol.write"), protocolH.Create)
		protected.GET("/protocols", middleware.RequirePermission("protocol.read"), protocolH.List)
		protected.GET("/protocols/:id", middleware.RequirePermission("protocol.read"), protocolH.Get)
		protected.POST("/protocols/:id/run", middleware.RequirePermission("protocol.read"), rateLimiter.Limit(middleware.Policy("protocol-run", 60, time.Minute, 10), middleware.UserIdentity), protocolH.Run)

		protected.GET("/settings", middleware.RequirePermission("admin.all"), referenceH.ListSettings)
		protected.POST("/settings", middleware.RequirePermission("admin.all"), referenceH.CreateSetting)
		protected.GET("/languages", contentReferenceH.ListLanguages)
		protected.GET("/languages/:id", contentReferenceH.GetLanguage)
		protected.POST("/languages", middleware.RequirePermission("admin.all"), contentReferenceH.CreateLanguage)
		protected.PATCH("/languages/:id", middleware.RequirePermission("admin.all"), contentReferenceH.UpdateLanguage)
		protected.DELETE("/languages/:id", middleware.RequirePermission("admin.all"), contentReferenceH.DeleteLanguage)
		protected.GET("/reading-progress", progressUsageH.ListProgress)
		protected.GET("/reading-progress/:guidelineId", progressUsageH.GetProgress)
		protected.PUT("/reading-progress/:guidelineId", rateLimiter.Limit(middleware.Policy("reading-progress-write", 120, time.Minute, 20), middleware.UserIdentity), progressUsageH.UpsertProgress)
		protected.DELETE("/reading-progress/:guidelineId", progressUsageH.DeleteProgress)
		protected.GET("/library/collections", guidelineLibraryH.ListCollections)
		protected.POST("/library/collections", guidelineLibraryH.CreateCollection)
		protected.GET("/library/collections/:id", guidelineLibraryH.GetCollection)
		protected.PATCH("/library/collections/:id", guidelineLibraryH.UpdateCollection)
		protected.DELETE("/library/collections/:id", guidelineLibraryH.DeleteCollection)
		protected.POST("/library/collections/:id/items", guidelineLibraryH.AddCollectionItem)
		protected.GET("/library/collections/:id/items", guidelineLibraryH.ListCollectionItems)
		protected.DELETE("/library/collections/:id/items/:guidelineId", guidelineLibraryH.RemoveCollectionItem)
		protected.GET("/library/downloads", guidelineLibraryH.ListDownloads)
		protected.POST("/library/downloads", rateLimiter.Limit(middleware.Policy("guideline-download-record", 120, time.Minute, 20), middleware.UserIdentity), guidelineLibraryH.RecordDownload)
		protected.POST("/usage/guidelines", rateLimiter.Limit(middleware.Policy("usage-event-write", 120, time.Minute, 20), middleware.UserIdentity), progressUsageH.RecordGuidelineUsage)
		protected.POST("/usage/abbreviations", rateLimiter.Limit(middleware.Policy("usage-event-write", 120, time.Minute, 20), middleware.UserIdentity), progressUsageH.RecordAbbreviationUsage)
		protected.POST("/usage/consultants", rateLimiter.Limit(middleware.Policy("usage-event-write", 120, time.Minute, 20), middleware.UserIdentity), progressUsageH.RecordConsultantUsage)
		protected.POST("/usage/ai", rateLimiter.Limit(middleware.Policy("usage-event-write", 120, time.Minute, 20), middleware.UserIdentity), progressUsageH.RecordAIUsage)
		protected.GET("/analytics/usage", middleware.RequireAnyPermission("admin.all", "analytics.read", "sync.read"), rateLimiter.Limit(middleware.Policy("analytics-read", 30, time.Minute, 5), middleware.UserIdentity), progressUsageH.UsageAggregates)
		protected.GET("/conversations", conversationH.List)
		protected.POST("/conversations", rateLimiter.Limit(middleware.Policy("conversation-create", 10, time.Hour, 2), middleware.UserIdentity), conversationH.Create)
		protected.GET("/conversations/:id", conversationH.Get)
		protected.DELETE("/conversations/:id", conversationH.Delete)
		protected.GET("/conversations/:id/messages", conversationH.ListMessages)
		protected.POST("/conversations/:id/messages", rateLimiter.Limit(middleware.Policy("conversation-message", 30, time.Minute, 5), middleware.UserIdentity), conversationH.CreateMessage)
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
		protected.POST("/sync/packages", middleware.RequirePermission("admin.all"), rateLimiter.Limit(middleware.Policy("sync-package-create", 5, time.Hour, 0), middleware.UserIdentity), rateLimiter.Concurrency("sync-package-create", 1, 30*time.Minute, middleware.UserIdentity), syncH.CreatePackage)
		protected.GET("/sync/packages/:id/download", middleware.RequirePermission("sync.read"), rateLimiter.Limit(middleware.Policy("sync-download-url", 30, time.Minute, 5), middleware.UserIdentity), syncH.Download)

	}
	return &App{Router: r, DB: database, Redis: redisClient, Cache: cacheStore}, nil
}

func (a *App) Close() error {
	if a == nil || a.Redis == nil {
		return nil
	}
	return a.Redis.Close()
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
