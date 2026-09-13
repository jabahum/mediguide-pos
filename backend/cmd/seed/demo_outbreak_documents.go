package main

import (
	"bytes"
	"context"
	"crypto/sha256"
	"embed"
	"encoding/hex"
	"fmt"
	"io"
	"path"
	"strings"
	"time"

	"mediguide/internal/services"
	"mediguide/internal/storage"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// Repository-owned fixtures are embedded into /app/seed. A seed can therefore
// never create a published database row whose source file was omitted from the
// runtime image.
//
//go:embed fixtures/outbreak-documents/*.md
var demoOutbreakDocumentFiles embed.FS

type demoOutbreakDocument struct {
	Key            string
	Fixture        string
	Title          string
	Description    string
	Kind           string
	DocumentNumber string
	Version        string
	Audience       string
	EffectiveDate  time.Time
	ReviewDate     time.Time
	ExpiresAt      time.Time
	SortOrder      int
}

func demoOutbreakDocuments() []demoOutbreakDocument {
	effective := time.Date(2026, time.May, 16, 0, 0, 0, 0, time.UTC)
	review := time.Date(2027, time.May, 16, 0, 0, 0, 0, time.UTC)
	expires := time.Date(2028, time.May, 16, 0, 0, 0, 0, time.UTC)
	return []demoOutbreakDocument{
		{Key: "ebola-case-definition", Fixture: "ebola-case-definition.md", Title: "Ebola suspected-case definition", Description: "Demonstration case-definition reference for recognizing and escalating a possible Ebola case.", Kind: "case_definition", DocumentNumber: "DEMO-EVD-CASE-001", Version: "1.0", Audience: "Frontline clinicians and surveillance teams", EffectiveDate: effective, ReviewDate: review, ExpiresAt: expires, SortOrder: 5},
		{Key: "ebola-case-management-sop", Fixture: "ebola-case-management-sop.md", Title: "Ebola case-management standard operating procedure", Description: "Demonstration workflow for safe reception, isolation, assessment, escalation and referral of a suspected Ebola case.", Kind: "sop", DocumentNumber: "DEMO-EVD-SOP-001", Version: "1.0", Audience: "Clinicians and Ebola treatment-unit teams", EffectiveDate: effective, ReviewDate: review, ExpiresAt: expires, SortOrder: 10},
		{Key: "ebola-treatment-protocol", Fixture: "ebola-treatment-protocol.md", Title: "Ebola screening and clinical-management pathway", Description: "Demonstration decision pathway for screening, escalation and clinician-directed supportive care.", Kind: "treatment_protocol", DocumentNumber: "DEMO-EVD-TREAT-001", Version: "1.0", Audience: "Clinicians and Ebola treatment-unit teams", EffectiveDate: effective, ReviewDate: review, ExpiresAt: expires, SortOrder: 15},
		{Key: "ebola-ipc-sop", Fixture: "ebola-ipc-sop.md", Title: "Ebola infection prevention and control SOP", Description: "Demonstration operational controls for zoning, PPE, hand hygiene, environmental cleaning and exposure reporting.", Kind: "ipc_protocol", DocumentNumber: "DEMO-EVD-IPC-001", Version: "1.0", Audience: "Health workers, IPC focal persons and support staff", EffectiveDate: effective, ReviewDate: review, ExpiresAt: expires, SortOrder: 20},
		{Key: "ebola-discharge-referral", Fixture: "ebola-discharge-referral-protocol.md", Title: "Ebola discharge and referral protocol", Description: "Demonstration criteria and governed handover steps for discharge, referral and follow-up.", Kind: "referral_protocol", DocumentNumber: "DEMO-EVD-REF-001", Version: "1.0", Audience: "Clinicians and discharge coordinators", EffectiveDate: effective, ReviewDate: review, ExpiresAt: expires, SortOrder: 25},
		{Key: "ebola-specimen-handling", Fixture: "ebola-specimen-handling-protocol.md", Title: "Ebola laboratory specimen-handling protocol", Description: "Demonstration protocol for authorization, collection, triple packaging, transport and laboratory handover.", Kind: "laboratory_protocol", DocumentNumber: "DEMO-EVD-LAB-001", Version: "1.0", Audience: "Clinicians, laboratory personnel and specimen couriers", EffectiveDate: effective, ReviewDate: review, ExpiresAt: expires, SortOrder: 30},
		{Key: "ebola-medicines-reference", Fixture: "ebola-medicines-reference.md", Title: "Ebola medicines and supportive-care reference", Description: "Demonstration medicine-safety reference that directs clinicians to the currently approved treatment protocol.", Kind: "policy", DocumentNumber: "DEMO-EVD-MED-001", Version: "1.0", Audience: "Authorized clinicians and pharmacists", EffectiveDate: effective, ReviewDate: review, ExpiresAt: expires, SortOrder: 35},
		{Key: "ebola-contact-tracing", Fixture: "ebola-contact-tracing-guide.md", Title: "Ebola contact-tracing field guide", Description: "Demonstration guide for contact identification, registration, follow-up, alert escalation and closure.", Kind: "contact_tracing_guide", DocumentNumber: "DEMO-EVD-CT-001", Version: "1.0", Audience: "Surveillance officers and contact-tracing teams", EffectiveDate: effective, ReviewDate: review, ExpiresAt: expires, SortOrder: 40},
		{Key: "ebola-response-form", Fixture: "ebola-response-form.md", Title: "Ebola response forms and documentation guide", Description: "Demonstration index of approved response forms and minimum safe documentation practices.", Kind: "form", DocumentNumber: "DEMO-EVD-FORM-001", Version: "1.0", Audience: "Response teams and facility focal persons", EffectiveDate: effective, ReviewDate: review, ExpiresAt: expires, SortOrder: 45},
		{Key: "ebola-health-worker-checklist", Fixture: "ebola-health-worker-checklist.md", Title: "Suspected Ebola case health-worker checklist", Description: "Demonstration point-of-care checklist for immediate isolation, IPC, notification and safe referral actions.", Kind: "checklist", DocumentNumber: "DEMO-EVD-CHK-001", Version: "1.0", Audience: "Frontline health workers", EffectiveDate: effective, ReviewDate: review, ExpiresAt: expires, SortOrder: 50},
		{Key: "ebola-training-guide", Fixture: "ebola-training-guide.md", Title: "Ebola response training guide", Description: "Demonstration training pathway for role-based readiness, supervised practice and competency checks.", Kind: "training_material", DocumentNumber: "DEMO-EVD-TRAIN-001", Version: "1.0", Audience: "Response trainers and health workers", EffectiveDate: effective, ReviewDate: review, ExpiresAt: expires, SortOrder: 55},
		{Key: "ebola-communication-guide", Fixture: "ebola-communication-guide.md", Title: "Ebola outbreak risk-communication guide", Description: "Demonstration guide for coordinated, accessible and privacy-preserving public communication during an outbreak.", Kind: "communication_material", DocumentNumber: "DEMO-EVD-COMMS-001", Version: "1.0", Audience: "Risk-communication teams, spokespersons and district leaders", EffectiveDate: effective, ReviewDate: review, ExpiresAt: expires, SortOrder: 60},
		{Key: "ebola-faq", Fixture: "ebola-response-faq.md", Title: "Ebola response frequently asked questions", Description: "Demonstration answers to common response questions with explicit escalation to approved sources.", Kind: "other", DocumentNumber: "DEMO-EVD-FAQ-001", Version: "1.0", Audience: "Health workers and response partners", EffectiveDate: effective, ReviewDate: review, ExpiresAt: expires, SortOrder: 65},
	}
}

func demoCholeraOutbreakDocuments() []demoOutbreakDocument {
	effective := time.Date(2026, time.August, 10, 0, 0, 0, 0, time.UTC)
	review := time.Date(2027, time.August, 10, 0, 0, 0, 0, time.UTC)
	expires := time.Date(2028, time.August, 10, 0, 0, 0, 0, time.UTC)
	return []demoOutbreakDocument{
		{Key: "cholera-case-definition", Fixture: "cholera-case-definition.md", Title: "[Demo] Cholera case-definition reference", Description: "Synthetic governed-document fixture for case-definition discovery and review testing.", Kind: "case_definition", DocumentNumber: "DEMO-CHOL-CASE-001", Version: "1.0", Audience: "Frontline clinicians and surveillance teams", EffectiveDate: effective, ReviewDate: review, ExpiresAt: expires, SortOrder: 10},
		{Key: "cholera-case-management-sop", Fixture: "cholera-case-management-sop.md", Title: "[Demo] Cholera case-management SOP", Description: "Synthetic managed SOP containing no approved treatment or dosing instruction.", Kind: "sop", DocumentNumber: "DEMO-CHOL-SOP-001", Version: "1.0", Audience: "Clinical response teams", EffectiveDate: effective, ReviewDate: review, ExpiresAt: expires, SortOrder: 20},
		{Key: "cholera-ipc-sop", Fixture: "cholera-ipc-sop.md", Title: "[Demo] Cholera IPC SOP", Description: "Synthetic managed IPC document for workflow testing.", Kind: "ipc_protocol", DocumentNumber: "DEMO-CHOL-IPC-001", Version: "1.0", Audience: "IPC focal persons and health workers", EffectiveDate: effective, ReviewDate: review, ExpiresAt: expires, SortOrder: 30},
		{Key: "cholera-health-worker-checklist", Fixture: "cholera-health-worker-checklist.md", Title: "[Demo] Cholera health-worker checklist", Description: "Synthetic point-of-care checklist shell for managed-document testing.", Kind: "checklist", DocumentNumber: "DEMO-CHOL-CHK-001", Version: "1.0", Audience: "Frontline health workers", EffectiveDate: effective, ReviewDate: review, ExpiresAt: expires, SortOrder: 40},
		{Key: "cholera-response-form", Fixture: "cholera-response-form.md", Title: "[Demo] Cholera response form", Description: "Synthetic, non-identifiable response-form fixture.", Kind: "form", DocumentNumber: "DEMO-CHOL-FORM-001", Version: "1.0", Audience: "Response teams", EffectiveDate: effective, ReviewDate: review, ExpiresAt: expires, SortOrder: 50},
		{Key: "cholera-situation-report", Fixture: "cholera-situation-report.md", Title: "[Demo] Cholera situation-report attachment", Description: "Synthetic report attachment for preview, download, search and audit testing.", Kind: "situation_report_attachment", DocumentNumber: "DEMO-CHOL-SITREP-001", Version: "1.0", Audience: "Response coordinators", EffectiveDate: effective, ReviewDate: review, ExpiresAt: expires, SortOrder: 60},
	}
}

func demoMeaslesOutbreakDocuments() []demoOutbreakDocument {
	effective := time.Date(2026, time.June, 12, 0, 0, 0, 0, time.UTC)
	review := time.Date(2027, time.June, 12, 0, 0, 0, 0, time.UTC)
	expires := time.Date(2028, time.June, 12, 0, 0, 0, 0, time.UTC)
	return []demoOutbreakDocument{
		{Key: "measles-case-definition", Fixture: "measles-case-definition.md", Title: "[Demo] Measles case-definition reference", Description: "Synthetic governed-document fixture for case-definition discovery and review testing.", Kind: "case_definition", DocumentNumber: "DEMO-MEAS-CASE-001", Version: "1.0", Audience: "Frontline clinicians and surveillance teams", EffectiveDate: effective, ReviewDate: review, ExpiresAt: expires, SortOrder: 10},
		{Key: "measles-case-management-sop", Fixture: "measles-case-management-sop.md", Title: "[Demo] Measles case-management SOP", Description: "Synthetic managed SOP containing no approved treatment or dosing instruction.", Kind: "sop", DocumentNumber: "DEMO-MEAS-SOP-001", Version: "1.0", Audience: "Clinical response teams", EffectiveDate: effective, ReviewDate: review, ExpiresAt: expires, SortOrder: 20},
		{Key: "measles-ipc-sop", Fixture: "measles-ipc-sop.md", Title: "[Demo] Measles IPC SOP", Description: "Synthetic managed IPC document for workflow testing.", Kind: "ipc_protocol", DocumentNumber: "DEMO-MEAS-IPC-001", Version: "1.0", Audience: "IPC focal persons and health workers", EffectiveDate: effective, ReviewDate: review, ExpiresAt: expires, SortOrder: 30},
		{Key: "measles-health-worker-checklist", Fixture: "measles-health-worker-checklist.md", Title: "[Demo] Measles health-worker checklist", Description: "Synthetic point-of-care checklist shell for managed-document testing.", Kind: "checklist", DocumentNumber: "DEMO-MEAS-CHK-001", Version: "1.0", Audience: "Frontline health workers", EffectiveDate: effective, ReviewDate: review, ExpiresAt: expires, SortOrder: 40},
		{Key: "measles-response-form", Fixture: "measles-response-form.md", Title: "[Demo] Measles response form", Description: "Synthetic, non-identifiable response-form fixture.", Kind: "form", DocumentNumber: "DEMO-MEAS-FORM-001", Version: "1.0", Audience: "Response teams", EffectiveDate: effective, ReviewDate: review, ExpiresAt: expires, SortOrder: 50},
		{Key: "measles-situation-report", Fixture: "measles-situation-report.md", Title: "[Demo] Measles situation-report attachment", Description: "Synthetic report attachment for preview, download, search and audit testing.", Kind: "situation_report_attachment", DocumentNumber: "DEMO-MEAS-SITREP-001", Version: "1.0", Audience: "Response coordinators", EffectiveDate: effective, ReviewDate: review, ExpiresAt: expires, SortOrder: 60},
	}
}

func seedDemoOutbreakDocuments(ctx context.Context, database *gorm.DB, store storage.ObjectStore, outbreakID, authorID, clinicianID uuid.UUID) error {
	return seedDemoManagedOutbreakDocuments(ctx, database, store, outbreakID, authorID, clinicianID, demoOutbreakDocuments(), "environmental decontamination")
}

func seedDemoManagedOutbreakDocuments(ctx context.Context, database *gorm.DB, store storage.ObjectStore, outbreakID, authorID, clinicianID uuid.UUID, documents []demoOutbreakDocument, searchTerm string) error {
	if store == nil {
		return fmt.Errorf("outbreak document seed requires object storage")
	}
	if len(documents) == 0 {
		return fmt.Errorf("outbreak document seed requires at least one fixture")
	}
	publishedAt := time.Date(2026, time.May, 16, 12, 0, 0, 0, time.UTC)
	for _, document := range documents {
		fixturePath := path.Join("fixtures/outbreak-documents", document.Fixture)
		content, err := demoOutbreakDocumentFiles.ReadFile(fixturePath)
		if err != nil {
			return fmt.Errorf("read outbreak document fixture %q: %w", fixturePath, err)
		}
		if len(bytes.TrimSpace(content)) == 0 {
			return fmt.Errorf("outbreak document fixture %q is empty", fixturePath)
		}

		documentID := demoID("outbreak-document", document.Key)
		storageKey := fmt.Sprintf("demo/outbreaks/%s/documents/%s/%s", outbreakID, documentID, document.Fixture)
		checksum := sha256.Sum256(content)
		if err := store.Put(ctx, storageKey, bytes.NewReader(content), int64(len(content)), "text/markdown; charset=utf-8"); err != nil {
			return fmt.Errorf("store outbreak document fixture %q: %w", document.Fixture, err)
		}
		stored, err := store.Get(ctx, storageKey)
		if err != nil {
			return fmt.Errorf("read stored outbreak document fixture %q: %w", document.Fixture, err)
		}
		storedContent, readErr := io.ReadAll(stored)
		closeErr := stored.Close()
		if readErr != nil {
			return fmt.Errorf("verify stored outbreak document fixture %q: %w", document.Fixture, readErr)
		}
		if closeErr != nil {
			return fmt.Errorf("close stored outbreak document fixture %q: %w", document.Fixture, closeErr)
		}
		storedChecksum := sha256.Sum256(storedContent)
		if len(storedContent) == 0 || !bytes.Equal(content, storedContent) || storedChecksum != checksum {
			return fmt.Errorf("stored outbreak document fixture %q failed size or checksum verification", document.Fixture)
		}
		projection := services.DeriveOutbreakDocumentProjection(path.Ext(document.Fixture), content)
		if projection.Status != "ready" || projection.Format != "markdown" || strings.TrimSpace(projection.Search) == "" || strings.TrimSpace(projection.Rendered) == "" || projection.Checksum == "" {
			return fmt.Errorf("derive outbreak document fixture %q: status=%s error=%s", document.Fixture, projection.Status, projection.Error)
		}
		checksumValue := hex.EncodeToString(checksum[:])

		if err := upsertByID(database, "outbreak_resources", map[string]any{
			"id": documentID, "outbreak_id": outbreakID, "title": document.Title,
			"description": document.Description, "resource_type": "managed_document",
			"document_kind": document.Kind, "issuing_authority": "Ministry of Health Uganda",
			"document_number": document.DocumentNumber, "version": document.Version,
			"language": "en", "audience": document.Audience,
			"effective_date": document.EffectiveDate, "review_date": document.ReviewDate,
			"expires_at": document.ExpiresAt, "storage_key": storageKey,
			"original_filename": document.Fixture, "mime_type": "text/markdown; charset=utf-8",
			"file_size": int64(len(content)), "checksum_sha256": checksumValue,
			"url": "", "asset_url": "", "sort_order": document.SortOrder,
			"status": "published", "author_id": authorID, "reviewed_by": clinicianID,
			"reviewed_at": publishedAt, "approved_by": clinicianID, "approved_at": publishedAt,
			"published_at": publishedAt, "lock_version": 1,
			"search_content": projection.Search, "search_headings": projection.Headings,
			"rendered_content": projection.Rendered, "content_format": projection.Format,
			"extraction_status": projection.Status, "extraction_error": projection.Error,
			"extracted_at": publishedAt, "extraction_source_checksum": checksumValue,
			"derived_content_checksum": projection.Checksum,
			"search_index_status":      "indexed", "search_schema_version": services.OutbreakDocumentSearchSchemaVersion,
			"content_sections": projection.SectionsJSON, "source_page_map": projection.PageMapJSON,
			"indexed_at": publishedAt,
		}); err != nil {
			return fmt.Errorf("upsert outbreak document %q: %w", document.Key, err)
		}
	}
	service := services.OutbreakService{DB: database, Store: store}
	firstID := demoID("outbreak-document", documents[0].Key)
	if _, err := service.GetDocumentGlobal(firstID); err != nil {
		return fmt.Errorf("verify public outbreak document metadata: %w", err)
	}
	download, err := service.DocumentDownload(ctx, outbreakID, firstID)
	if err != nil || download == nil || download.Body == nil {
		return fmt.Errorf("verify public outbreak document download: %w", err)
	}
	if err := download.Body.Close(); err != nil {
		return fmt.Errorf("close verified outbreak document download: %w", err)
	}
	if content, err := service.DocumentContent(firstID); err != nil || !content.CanReadInline || strings.TrimSpace(content.Content) == "" {
		return fmt.Errorf("verify public outbreak document content: %w", err)
	}
	result, err := service.SearchDocuments(services.OutbreakDocumentQuery{Page: services.PageInput{Page: 1, PerPage: 10}, Search: searchTerm})
	if err != nil || result.TotalItems == 0 {
		return fmt.Errorf("verify body-only outbreak document search: %w", err)
	}
	return nil
}
