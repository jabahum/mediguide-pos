package services

import (
	"errors"
	"strings"
	"testing"
	"time"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func outbreakTestService(t *testing.T) OutbreakService {
	t.Helper()
	db, err := gorm.Open(sqlite.Open("file:"+uuid.NewString()+"?mode=memory&cache=shared"), &gorm.Config{})
	if err != nil {
		t.Fatal(err)
	}
	if err := db.AutoMigrate(&models.Outbreak{}, &models.OutbreakUpdate{}, &models.OutbreakResource{}, &models.SituationReport{}); err != nil {
		t.Fatal(err)
	}
	return OutbreakService{DB: db}
}

func TestOutbreakServiceExposesOnlyPublishedContent(t *testing.T) {
	service := outbreakTestService(t)
	now := time.Now().UTC()
	public := models.Outbreak{Title: "Published response", Status: "active", PublishedAt: &now, LastUpdate: now}
	draft := models.Outbreak{Title: "Internal draft", Status: "draft", LastUpdate: now}
	if err := service.DB.Create(&public).Error; err != nil {
		t.Fatal(err)
	}
	if err := service.DB.Create(&draft).Error; err != nil {
		t.Fatal(err)
	}

	page, err := service.List(OutbreakQuery{Page: PageInput{Page: 1, PerPage: 20}})
	if err != nil || page.TotalItems != 1 || page.Items[0].ID != public.ID {
		t.Fatalf("unexpected public outbreaks: %#v err=%v", page, err)
	}
	if _, err := service.Get(draft.ID); !errors.Is(err, gorm.ErrRecordNotFound) {
		t.Fatalf("draft outbreak became public: %v", err)
	}
}

func TestOutbreakServiceScopesChildrenAndReportsToPublishedParents(t *testing.T) {
	service := outbreakTestService(t)
	now := time.Now().UTC()
	public := models.Outbreak{Title: "Response", Status: "monitoring", PublishedAt: &now, LastUpdate: now}
	draft := models.Outbreak{Title: "Draft", Status: "draft", LastUpdate: now}
	for _, item := range []*models.Outbreak{&public, &draft} {
		if err := service.DB.Create(item).Error; err != nil {
			t.Fatal(err)
		}
	}
	if err := service.DB.Create(&models.OutbreakUpdate{OutbreakID: public.ID, Title: "Update", Status: "published", PublishedAt: &now}).Error; err != nil {
		t.Fatal(err)
	}
	if err := service.DB.Create(&models.OutbreakResource{OutbreakID: public.ID, Title: "Guidance", ResourceType: "internal_route", URL: "/guidelines", Status: "published", PublishedAt: &now, SortOrder: 1}).Error; err != nil {
		t.Fatal(err)
	}
	updates, err := service.Updates(public.ID, PageInput{})
	if err != nil || updates.TotalItems != 1 {
		t.Fatalf("updates: %#v %v", updates, err)
	}
	resources, err := service.Resources(public.ID, PageInput{})
	if err != nil || resources.TotalItems != 1 {
		t.Fatalf("resources: %#v %v", resources, err)
	}
	if _, err := service.Updates(draft.ID, PageInput{}); !errors.Is(err, gorm.ErrRecordNotFound) {
		t.Fatalf("draft updates exposed: %v", err)
	}

	if err := service.DB.Create(&models.SituationReport{Title: "Published report", Status: "published", PublicationDate: now, PublishedAt: &now, StandaloneAllowed: true}).Error; err != nil {
		t.Fatal(err)
	}
	if err := service.DB.Create(&models.SituationReport{Title: "Draft report", Status: "draft", PublicationDate: now}).Error; err != nil {
		t.Fatal(err)
	}
	reports, err := service.ListReports(SituationReportQuery{Page: PageInput{}})
	if err != nil || reports.TotalItems != 1 || reports.Items[0].Title != "Published report" {
		t.Fatalf("reports: %#v %v", reports, err)
	}
}

func TestOutbreakServiceDiscoversOnlySafeQuickResources(t *testing.T) {
	service := outbreakTestService(t)
	now := time.Now().UTC().Add(-time.Minute)
	parent := models.Outbreak{Title: "Ebola response", SourceOrganization: "Ministry of Health", Status: "active", PublishedAt: &now, LastUpdate: now}
	if err := service.DB.Create(&parent).Error; err != nil {
		t.Fatal(err)
	}
	rows := []models.OutbreakResource{
		{OutbreakID: parent.ID, Title: "Clinical guidance", Description: "Reviewed guidance", ResourceType: "internal_route", URL: "/guidelines", IssuingAuthority: "Clinical directorate", Status: "published", PublishedAt: &now},
		{OutbreakID: parent.ID, Title: "Official statement", ResourceType: "official_statement", URL: "https://health.go.ug/statement", Status: "published", PublishedAt: &now},
		{OutbreakID: parent.ID, Title: "Unsafe legacy link", ResourceType: "link", URL: "javascript:alert(1)", Status: "published", PublishedAt: &now},
		{OutbreakID: parent.ID, Title: "Managed SOP", ResourceType: "managed_document", Status: "published", PublishedAt: &now},
	}
	for index := range rows {
		if err := service.DB.Create(&rows[index]).Error; err != nil {
			t.Fatal(err)
		}
	}
	page, err := service.ListResources(OutbreakResourceQuery{Page: PageInput{Page: 1, PerPage: 20}, Search: "guidance"})
	if err != nil || len(page.Items) != 1 {
		t.Fatalf("quick resources: %#v err=%v", page, err)
	}
	item := page.Items[0]
	if item.TargetType != "internal_route" || item.TargetURL == "" || item.ReaderCapability != "in_app_route" || item.DownloadCapability || item.OutbreakTitle != parent.Title || item.IssuingOrganization != "Clinical directorate" {
		t.Fatalf("unexpected quick-resource DTO: %#v", item)
	}
	all, err := service.ListResources(OutbreakResourceQuery{Page: PageInput{Page: 1, PerPage: 20}})
	if err != nil || len(all.Items) != 2 {
		t.Fatalf("unsafe or managed target leaked: %#v err=%v", all, err)
	}
}

func TestOutbreakDocumentSearchPreviewReportsIndexReadiness(t *testing.T) {
	service := outbreakTestService(t)
	now := time.Now().UTC().Add(-time.Minute)
	parent := models.Outbreak{Title: "Response", Status: "active", PublishedAt: &now, LastUpdate: now}
	if err := service.DB.Create(&parent).Error; err != nil {
		t.Fatal(err)
	}
	document := models.OutbreakResource{OutbreakID: parent.ID, Title: "Isolation SOP", ResourceType: "managed_document", SearchContent: "Use the designated isolation room immediately.", SearchIndexStatus: "indexed", ExtractionStatus: "ready", IndexedAt: &now, ContentSections: []byte(`[{"id":"isolation","heading":"Isolation","level":2,"text":"Use the designated isolation room immediately."}]`)}
	if err := service.DB.Create(&document).Error; err != nil {
		t.Fatal(err)
	}
	preview, err := (OutbreakAdminService{DB: service.DB}).DocumentSearchPreview(parent.ID, document.ID, "isolation room")
	if err != nil || !preview.Searchable || preview.MatchingHeading != "Isolation" || preview.Snippet == "" || preview.IndexedAt == nil {
		t.Fatalf("unexpected search preview: %#v err=%v", preview, err)
	}
	if _, err := (OutbreakAdminService{DB: service.DB}).DocumentSearchPreview(parent.ID, document.ID, "x"); !errors.Is(err, ErrOutbreakInvalid) {
		t.Fatalf("short query accepted: %v", err)
	}
}

func TestOutbreakServiceExposesOnlyCurrentPublishedDocuments(t *testing.T) {
	service := outbreakTestService(t)
	now := time.Now().UTC().Truncate(time.Second)
	parent := models.Outbreak{Title: "Published response", Status: "active", PublishedAt: &now, LastUpdate: now}
	if err := service.DB.Create(&parent).Error; err != nil {
		t.Fatal(err)
	}
	past, future := now.Add(-time.Hour), now.Add(time.Hour)
	expired := now.Add(-time.Minute)
	rows := []models.OutbreakResource{
		{OutbreakID: parent.ID, Title: "Current Ebola SOP", ResourceType: "managed_document", DocumentKind: "sop", Language: "en", Status: "published", ApprovedAt: &past, PublishedAt: &past, EffectiveDate: &past, AssetURL: "https://health.go.ug/current.pdf", DocumentNumber: "SOP-1", Version: "1"},
		{OutbreakID: parent.ID, Title: "Draft SOP", ResourceType: "managed_document", DocumentKind: "sop", Language: "en", Status: "draft"},
		{OutbreakID: parent.ID, Title: "Future SOP", ResourceType: "managed_document", DocumentKind: "sop", Language: "en", Status: "published", ApprovedAt: &past, PublishedAt: &past, EffectiveDate: &future},
		{OutbreakID: parent.ID, Title: "Expired SOP", ResourceType: "managed_document", DocumentKind: "sop", Language: "en", Status: "published", ApprovedAt: &past, PublishedAt: &past, EffectiveDate: &past, ExpiresAt: &expired},
		{OutbreakID: parent.ID, Title: "Ordinary link", ResourceType: "approved_external_url", DocumentKind: "other", Language: "en", Status: "published", PublishedAt: &past},
	}
	for index := range rows {
		if err := service.DB.Create(&rows[index]).Error; err != nil {
			t.Fatal(err)
		}
	}
	page, err := service.Documents(parent.ID, OutbreakDocumentQuery{Search: "Ebola", DocumentKind: "sop"})
	if err != nil || page.TotalItems != 1 || page.Items[0].ID != rows[0].ID {
		t.Fatalf("public documents: %#v err=%v", page, err)
	}
	document, err := service.GetDocument(parent.ID, rows[0].ID)
	if err != nil || document.DownloadURL == "" || document.DocumentNumber != "SOP-1" {
		t.Fatalf("public document: %#v err=%v", document, err)
	}
	if _, err := service.GetDocument(parent.ID, rows[1].ID); !errors.Is(err, gorm.ErrRecordNotFound) {
		t.Fatalf("draft document exposed: %v", err)
	}
}

func TestOutbreakServiceDiscoversDocumentsAcrossPublishedOutbreaks(t *testing.T) {
	service := outbreakTestService(t)
	now := time.Now().UTC().Add(-time.Minute)
	publicParent := models.Outbreak{Title: "Ebola response", DiseaseType: "EVD", GeographicArea: "Kampala", Status: "active", PublishedAt: &now, LastUpdate: now}
	draftParent := models.Outbreak{Title: "Internal response", Status: "draft", LastUpdate: now}
	if err := service.DB.Create(&publicParent).Error; err != nil {
		t.Fatal(err)
	}
	if err := service.DB.Create(&draftParent).Error; err != nil {
		t.Fatal(err)
	}
	visible := models.OutbreakResource{OutbreakID: publicParent.ID, Title: "Case management SOP", Description: "Approved response protocol", ResourceType: "managed_document", DocumentKind: "sop", IssuingAuthority: "Ministry of Health", Language: "en", MIMEType: "text/markdown; charset=utf-8", StorageKey: "outbreaks/case.md", Status: "published", ApprovedAt: &now, PublishedAt: &now, SearchHeadings: "Immediate action", SearchContent: "isolate suspected cases immediately", RenderedContent: "# Immediate action\n\nIsolate suspected cases immediately.", ContentFormat: "markdown", ExtractionStatus: "ready", ContentSections: []byte(`[{"id":"immediate-action","heading":"Immediate action","level":1,"text":"Isolate suspected cases immediately."}]`), ChecksumSHA256: strings.Repeat("a", 64)}
	hidden := models.OutbreakResource{OutbreakID: draftParent.ID, Title: "Secret SOP", ResourceType: "managed_document", DocumentKind: "sop", Language: "en", Status: "published", PublishedAt: &now, SearchContent: "isolate suspected cases immediately"}
	unapproved := models.OutbreakResource{OutbreakID: publicParent.ID, Title: "Unapproved case SOP", ResourceType: "managed_document", DocumentKind: "sop", Language: "en", Status: "published", PublishedAt: &now, SearchContent: "isolate suspected cases immediately"}
	if err := service.DB.Create(&visible).Error; err != nil {
		t.Fatal(err)
	}
	if err := service.DB.Create(&hidden).Error; err != nil {
		t.Fatal(err)
	}
	if err := service.DB.Create(&unapproved).Error; err != nil {
		t.Fatal(err)
	}
	page, err := service.SearchDocuments(OutbreakDocumentQuery{Page: PageInput{Page: 1, PerPage: 10}, Search: "immediate action", OutbreakID: &publicParent.ID, MIMEType: "text/markdown"})
	if err != nil || page.TotalItems != 1 || page.Items[0].ID != visible.ID || page.Items[0].OutbreakTitle != publicParent.Title || !page.Items[0].SupportsInline || !page.Items[0].SupportsOfflineDownload || page.Items[0].ReaderURL == "" || page.Items[0].SearchSnippet == "" || page.Items[0].MatchingHeading != "Immediate action" || page.Items[0].MatchingSectionID != "immediate-action" || page.Items[0].SearchRelevanceScore <= 0 {
		t.Fatalf("unexpected discovery result: %#v err=%v", page, err)
	}
	content, err := service.DocumentContent(visible.ID)
	if err != nil || content.Format != "markdown" || content.DocumentID != visible.ID || !content.CanReadInline || !content.OriginalAvailable || content.DownloadURL == "" || len(content.Sections) != 1 || !strings.Contains(content.Content, "Immediate action") {
		t.Fatalf("unexpected public content: %#v err=%v", content, err)
	}
	if _, err := service.GetDocumentGlobal(hidden.ID); !errors.Is(err, gorm.ErrRecordNotFound) {
		t.Fatalf("document under draft outbreak became public: %v", err)
	}
}
