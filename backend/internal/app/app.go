package app

import (
	"net/http"
	"strings"
	"time"

	"mediguide/internal/config"
	"mediguide/internal/db"
	"mediguide/internal/handlers"
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

	authSvc := services.AuthService{DB: database, Cfg: cfg}
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
	legacyAPISvc := services.LegacyAPIService{DB: database}
	resourceSvc := services.ResourceService{DB: database}

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
	legacyAPIH := handlers.LegacyAPIHandler{Service: legacyAPISvc, Cfg: cfg}
	resourceH := handlers.ResourceHandler{Service: resourceSvc, Cfg: cfg}
	facilityH := handlers.NewFacilityHandler(resourceSvc, cfg)

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
		protected.GET("/languages", referenceH.ListLanguages)
		protected.POST("/languages", middleware.RequirePermission("admin.all"), referenceH.CreateLanguage)

		protected.GET("/facilities", facilityH.ListFacilities)
		protected.GET("/facilities/:id", facilityH.GetFacility)
		protected.POST("/facilities", middleware.RequireAnyPermission("admin.all", "guideline.write"), facilityH.CreateFacility)
		protected.PATCH("/facilities/:id", middleware.RequireAnyPermission("admin.all", "guideline.write"), facilityH.UpdateFacility)
		protected.DELETE("/facilities/:id", middleware.RequireAnyPermission("admin.all", "guideline.write"), facilityH.DeleteFacility)

		protected.GET("/health-sub-regions", facilityH.ListHealthSubRegions)
		protected.POST("/health-sub-regions", middleware.RequireAnyPermission("admin.all", "guideline.write"), facilityH.CreateHealthSubRegion)
		protected.PATCH("/health-sub-regions/:id", middleware.RequireAnyPermission("admin.all", "guideline.write"), facilityH.UpdateHealthSubRegion)
		protected.DELETE("/health-sub-regions/:id", middleware.RequireAnyPermission("admin.all", "guideline.write"), facilityH.DeleteHealthSubRegion)
		protected.GET("/regions", facilityH.ListRegions)
		protected.POST("/regions", middleware.RequireAnyPermission("admin.all", "guideline.write"), facilityH.CreateRegion)
		protected.PATCH("/regions/:id", middleware.RequireAnyPermission("admin.all", "guideline.write"), facilityH.UpdateRegion)
		protected.DELETE("/regions/:id", middleware.RequireAnyPermission("admin.all", "guideline.write"), facilityH.DeleteRegion)
		protected.GET("/districts", facilityH.ListDistricts)
		protected.POST("/districts", middleware.RequireAnyPermission("admin.all", "guideline.write"), facilityH.CreateDistrict)
		protected.PATCH("/districts/:id", middleware.RequireAnyPermission("admin.all", "guideline.write"), facilityH.UpdateDistrict)
		protected.DELETE("/districts/:id", middleware.RequireAnyPermission("admin.all", "guideline.write"), facilityH.DeleteDistrict)
		protected.GET("/health-sub-districts", facilityH.ListHealthSubDistricts)
		protected.POST("/health-sub-districts", middleware.RequireAnyPermission("admin.all", "guideline.write"), facilityH.CreateHealthSubDistrict)
		protected.PATCH("/health-sub-districts/:id", middleware.RequireAnyPermission("admin.all", "guideline.write"), facilityH.UpdateHealthSubDistrict)
		protected.DELETE("/health-sub-districts/:id", middleware.RequireAnyPermission("admin.all", "guideline.write"), facilityH.DeleteHealthSubDistrict)
		protected.GET("/counties", facilityH.ListCounties)
		protected.POST("/counties", middleware.RequireAnyPermission("admin.all", "guideline.write"), facilityH.CreateCounty)
		protected.PATCH("/counties/:id", middleware.RequireAnyPermission("admin.all", "guideline.write"), facilityH.UpdateCounty)
		protected.DELETE("/counties/:id", middleware.RequireAnyPermission("admin.all", "guideline.write"), facilityH.DeleteCounty)
		protected.GET("/subcounties", facilityH.ListSubcounties)
		protected.POST("/subcounties", middleware.RequireAnyPermission("admin.all", "guideline.write"), facilityH.CreateSubcounty)
		protected.PATCH("/subcounties/:id", middleware.RequireAnyPermission("admin.all", "guideline.write"), facilityH.UpdateSubcounty)
		protected.DELETE("/subcounties/:id", middleware.RequireAnyPermission("admin.all", "guideline.write"), facilityH.DeleteSubcounty)
		protected.GET("/parishes", facilityH.ListParishes)
		protected.POST("/parishes", middleware.RequireAnyPermission("admin.all", "guideline.write"), facilityH.CreateParish)
		protected.PATCH("/parishes/:id", middleware.RequireAnyPermission("admin.all", "guideline.write"), facilityH.UpdateParish)
		protected.DELETE("/parishes/:id", middleware.RequireAnyPermission("admin.all", "guideline.write"), facilityH.DeleteParish)
		protected.GET("/facility-levels", facilityH.ListFacilityLevels)
		protected.POST("/facility-levels", middleware.RequireAnyPermission("admin.all", "guideline.write"), facilityH.CreateFacilityLevel)
		protected.PATCH("/facility-levels/:id", middleware.RequireAnyPermission("admin.all", "guideline.write"), facilityH.UpdateFacilityLevel)
		protected.DELETE("/facility-levels/:id", middleware.RequireAnyPermission("admin.all", "guideline.write"), facilityH.DeleteFacilityLevel)
		protected.GET("/ownership-types", facilityH.ListOwnershipTypes)
		protected.POST("/ownership-types", middleware.RequireAnyPermission("admin.all", "guideline.write"), facilityH.CreateOwnershipType)
		protected.PATCH("/ownership-types/:id", middleware.RequireAnyPermission("admin.all", "guideline.write"), facilityH.UpdateOwnershipType)
		protected.DELETE("/ownership-types/:id", middleware.RequireAnyPermission("admin.all", "guideline.write"), facilityH.DeleteOwnershipType)
		protected.GET("/authorities", facilityH.ListAuthorities)
		protected.POST("/authorities", middleware.RequireAnyPermission("admin.all", "guideline.write"), facilityH.CreateAuthority)
		protected.PATCH("/authorities/:id", middleware.RequireAnyPermission("admin.all", "guideline.write"), facilityH.UpdateAuthority)
		protected.DELETE("/authorities/:id", middleware.RequireAnyPermission("admin.all", "guideline.write"), facilityH.DeleteAuthority)

		protected.GET("/sync/manifest", middleware.RequirePermission("sync.read"), syncH.Manifest)
		protected.POST("/sync/packages", middleware.RequirePermission("admin.all"), syncH.CreatePackage)
		protected.GET("/sync/packages/:id/download", middleware.RequirePermission("sync.read"), syncH.Download)

		registerResourceRoutes(protected, resourceH)
	}
	return &App{Router: r, DB: database}, nil
}

func registerResourceRoutes(group *gin.RouterGroup, handler handlers.ResourceHandler) {
	resourcePaths := map[string]string{
		"medical_guidelines":      "/medical-guidelines",
		"abbreviations":           "/abbreviations",
		"emergency_protocols":     "/emergency-protocols",
		"faqs":                    "/faqs",
		"faq_tags":                "/faq-tags",
		"documentation":           "/documentation",
		"generic_pages":           "/pages",
		"guideline_categories":    "/guideline-categories",
		"guideline_tags":          "/guideline-tags",
		"guideline_index":         "/guideline-index",
		"consultants":             "/consultants",
		"ministry_directory":      "/ministry-directory",
		"languages":               "/reference-languages",
		"notifications":           "/notifications",
		"notification_templates":  "/notification-templates",
		"notification_campaigns":  "/notification-campaigns",
		"support_tickets":         "/support-tickets",
		"support_ticket_replies":  "/support-ticket-replies",
		"conversations":           "/conversations",
		"messages":                "/messages",
		"reading_progress":        "/reading-progress",
		"guideline_usage_logs":    "/guideline-usage",
		"abbreviation_usage_logs": "/abbreviation-usage",
		"consultant_usage_logs":   "/consultant-usage",
		"facility_usage_logs":     "/facility-usage",
		"ai_usage_logs":           "/ai-usage",
	}

	for resource, path := range resourcePaths {
		resourceName := resource
		setResource := func(next gin.HandlerFunc) gin.HandlerFunc {
			return func(c *gin.Context) {
				c.Set("resource", resourceName)
				next(c)
			}
		}
		group.GET(path, setResource(handler.List))
		group.GET(path+"/:id", setResource(handler.Get))
		group.POST(path, setResource(handler.Create))
		group.PATCH(path+"/:id", setResource(handler.Update))
		group.DELETE(path+"/:id", setResource(handler.Delete))
	}
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
