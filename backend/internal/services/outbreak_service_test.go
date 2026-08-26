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
	if err != nil || len(all.Items) != 2 || all.TotalItems != 2 || all.TotalPages != 1 {
		t.Fatalf("unsafe or managed target leaked: %#v err=%v", all, err)
	}
	first, err := service.ListResources(OutbreakResourceQuery{Page: PageInput{Page: 1, PerPage: 1}, Sort: "title", Order: "asc"})
	if err != nil || len(first.Items) != 1 || first.TotalItems != 2 || first.TotalPages != 2 || first.Items[0].Title != "Clinical guidance" {
		t.Fatalf("validated first page is incorrect: %#v err=%v", first, err)
	}
	second, err := service.ListResources(OutbreakResourceQuery{Page: PageInput{Page: 2, PerPage: 1}, Sort: "title", Order: "asc"})
	if err != nil || len(second.Items) != 1 || second.Items[0].Title != "Official statement" || second.TotalItems != 2 {
		t.Fatalf("validated second page is incorrect: %#v err=%v", second, err)
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

func TestOutbreakDocumentDiscoveryEnforcesLifecycleAndSupersededVersionRules(t *testing.T) {
	service := outbreakTestService(t)
	now := time.Now().UTC().Truncate(time.Second)
	past, future, expired := now.Add(-time.Hour), now.Add(time.Hour), now.Add(-time.Minute)
	visibleParent := models.Outbreak{Title: "Visible response", DiseaseType: "EVD", Status: "active", PublishedAt: &past, LastUpdate: now}
	privateParent := models.Outbreak{Title: "Private response", Status: "draft", LastUpdate: now}
	withdrawnParent := models.Outbreak{Title: "Withdrawn response", Status: "active", PublishedAt: &past, WithdrawnAt: &past, LastUpdate: now}
	for _, parent := range []*models.Outbreak{&visibleParent, &privateParent, &withdrawnParent} {
		if err := service.DB.Create(parent).Error; err != nil {
			t.Fatal(err)
		}
	}
	current := models.OutbreakResource{OutbreakID: visibleParent.ID, Title: "Current protocol", ResourceType: "managed_document", DocumentKind: "protocol", Language: "en", Status: "published", ApprovedAt: &past, PublishedAt: &past, EffectiveDate: &past, SearchContent: "unique lifecycle phrase"}
	rows := []models.OutbreakResource{
		current,
		{OutbreakID: visibleParent.ID, Title: "Draft", ResourceType: "managed_document", Status: "draft", SearchContent: "unique lifecycle phrase"},
		{OutbreakID: visibleParent.ID, Title: "Unapproved", ResourceType: "managed_document", Status: "published", PublishedAt: &past, SearchContent: "unique lifecycle phrase"},
		{OutbreakID: visibleParent.ID, Title: "Future publication", ResourceType: "managed_document", Status: "published", ApprovedAt: &past, PublishedAt: &future, SearchContent: "unique lifecycle phrase"},
		{OutbreakID: visibleParent.ID, Title: "Future effective", ResourceType: "managed_document", Status: "published", ApprovedAt: &past, PublishedAt: &past, EffectiveDate: &future, SearchContent: "unique lifecycle phrase"},
		{OutbreakID: visibleParent.ID, Title: "Expired", ResourceType: "managed_document", Status: "published", ApprovedAt: &past, PublishedAt: &past, EffectiveDate: &past, ExpiresAt: &expired, SearchContent: "unique lifecycle phrase"},
		{OutbreakID: visibleParent.ID, Title: "Withdrawn", ResourceType: "managed_document", Status: "withdrawn", ApprovedAt: &past, PublishedAt: &past, EffectiveDate: &past, WithdrawnAt: &past, SearchContent: "unique lifecycle phrase"},
		{OutbreakID: privateParent.ID, Title: "Private parent document", ResourceType: "managed_document", Status: "published", ApprovedAt: &past, PublishedAt: &past, SearchContent: "unique lifecycle phrase"},
		{OutbreakID: withdrawnParent.ID, Title: "Withdrawn parent document", ResourceType: "managed_document", Status: "published", ApprovedAt: &past, PublishedAt: &past, SearchContent: "unique lifecycle phrase"},
	}
	for index := range rows {
		if err := service.DB.Create(&rows[index]).Error; err != nil {
			t.Fatal(err)
		}
	}
	page, err := service.SearchDocuments(OutbreakDocumentQuery{Page: PageInput{Page: 1, PerPage: 20}, Search: "unique lifecycle phrase"})
	if err != nil || page.TotalItems != 1 || len(page.Items) != 1 || page.Items[0].ID != rows[0].ID {
		t.Fatalf("non-public lifecycle state leaked: %#v err=%v", page, err)
	}

	// Publishing a correction withdraws the superseded public revision; public
	// discovery must then return only the replacement.
	if err := service.DB.Model(&models.OutbreakResource{}).Where("id = ?", rows[0].ID).Updates(map[string]any{"status": "withdrawn", "withdrawn_at": now, "search_index_status": "removed"}).Error; err != nil {
		t.Fatal(err)
	}
	replacement := models.OutbreakResource{OutbreakID: visibleParent.ID, Title: "Current protocol v2", ResourceType: "managed_document", DocumentKind: "protocol", Language: "en", Status: "published", ApprovedAt: &now, PublishedAt: &now, EffectiveDate: &past, SupersedesID: &rows[0].ID, SearchContent: "unique lifecycle phrase"}
	if err := service.DB.Create(&replacement).Error; err != nil {
		t.Fatal(err)
	}
	page, err = service.SearchDocuments(OutbreakDocumentQuery{Page: PageInput{Page: 1, PerPage: 20}, Search: "unique lifecycle phrase"})
	if err != nil || page.TotalItems != 1 || page.Items[0].ID != replacement.ID {
		t.Fatalf("superseded revision remained discoverable: %#v err=%v", page, err)
	}
}

func TestOutbreakDocumentDiscoveryFiltersPaginationPDFMatchAndSafeSort(t *testing.T) {
	service := outbreakTestService(t)
	now := time.Now().UTC().Add(-time.Hour)
	parent := models.Outbreak{Title: "Ebola response", DiseaseType: "EVD", GeographicArea: "Kampala", Status: "active", PublishedAt: &now, LastUpdate: now}
	if err := service.DB.Create(&parent).Error; err != nil {
		t.Fatal(err)
	}
	pageNumber := 4
	rows := []models.OutbreakResource{
		{OutbreakID: parent.ID, Title: "Alpha laboratory protocol", ResourceType: "managed_document", DocumentKind: "laboratory_protocol", IssuingAuthority: "Ministry of Health", Language: "en", Audience: "laboratory staff", MIMEType: "application/pdf", Status: "published", ApprovedAt: &now, PublishedAt: &now, EffectiveDate: &now, SortOrder: 1, SearchHeadings: "Specimen packaging", SearchContent: "triple package the specimen safely", ContentSections: []byte(`[{"id":"page-4","heading":"Page 4","level":1,"text":"Triple package the specimen safely.","page":4}]`)},
		{OutbreakID: parent.ID, Title: "Beta laboratory protocol", ResourceType: "managed_document", DocumentKind: "laboratory_protocol", IssuingAuthority: "Ministry of Health", Language: "en", Audience: "laboratory staff", MIMEType: "application/pdf", Status: "published", ApprovedAt: &now, PublishedAt: &now, EffectiveDate: &now, SortOrder: 2, SearchContent: "triple package the specimen safely"},
	}
	for index := range rows {
		if err := service.DB.Create(&rows[index]).Error; err != nil {
			t.Fatal(err)
		}
	}
	page, err := service.SearchDocuments(OutbreakDocumentQuery{Page: PageInput{Page: 1, PerPage: 1}, Search: "triple package", OutbreakID: &parent.ID, DocumentKind: "laboratory_protocol", Authority: "Ministry of Health", Language: "en", Audience: "laboratory staff", MIMEType: "application/pdf", Sort: "title", Order: "asc"})
	if err != nil || page.TotalItems != 2 || page.TotalPages != 2 || len(page.Items) != 1 || page.Items[0].ID != rows[0].ID || page.Items[0].MatchingPDFPage == nil || *page.Items[0].MatchingPDFPage != pageNumber {
		t.Fatalf("filters, pagination, or PDF match failed: %#v err=%v", page, err)
	}
	second, err := service.SearchDocuments(OutbreakDocumentQuery{Page: PageInput{Page: 2, PerPage: 1}, Search: "triple package", Sort: "title", Order: "asc"})
	if err != nil || len(second.Items) != 1 || second.Items[0].ID != rows[1].ID {
		t.Fatalf("deterministic second page failed: %#v err=%v", second, err)
	}
	for _, malicious := range []OutbreakDocumentQuery{
		{Sort: "title; DROP TABLE outbreak_resources;--"},
		{Sort: "deleted_at"},
		{Sort: "title", Order: "asc; SELECT pg_sleep(10)"},
	} {
		if _, err := service.SearchDocuments(malicious); !errors.Is(err, ErrOutbreakInvalid) {
			t.Fatalf("malicious sort/order accepted: %#v err=%v", malicious, err)
		}
	}
	var count int64
	if err := service.DB.Model(&models.OutbreakResource{}).Count(&count).Error; err != nil || count != 2 {
		t.Fatalf("injection attempt affected data: count=%d err=%v", count, err)
	}
}
