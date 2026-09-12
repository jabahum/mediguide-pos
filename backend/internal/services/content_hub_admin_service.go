package services

import (
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

var defaultOutbreakHubTemplateID = uuid.MustParse("92000000-0000-4000-8000-000000000001")

type ConfigureOutbreakHubInput struct {
	Name       string     `json:"name"`
	Slug       string     `json:"slug"`
	TemplateID *uuid.UUID `json:"template_id"`
	Publish    bool       `json:"publish"`
}

type ContentHubWorkspace struct {
	Hub     models.ContentHub       `json:"hub"`
	Pillars []ContentHubAdminPillar `json:"pillars"`
}

type ContentHubAdminPillar struct {
	models.ContentPillar
	Items []models.ContentPillarItem `json:"items"`
}

type AssignableHubResource struct {
	ID          uuid.UUID `json:"id"`
	ContentType string    `json:"content_type"`
	Title       string    `json:"title"`
	Description string    `json:"description,omitempty"`
	Status      string    `json:"status"`
	Context     string    `json:"context,omitempty"`
}

type ContentHubResourceQuery struct {
	Page        PageInput
	Search      string
	ContentType string
	OutbreakID  string
}

type ContentHubAuditRecord struct {
	ID         uuid.UUID      `json:"id"`
	ActorID    string         `json:"actor_id"`
	Action     string         `json:"action"`
	EntityType string         `json:"entity_type"`
	EntityID   string         `json:"entity_id"`
	Metadata   map[string]any `json:"metadata"`
	IPAddress  string         `json:"ip_address"`
	CreatedAt  time.Time      `json:"created_at"`
}

// ConfigureOutbreakHub is deliberately idempotent. It creates the curated
// presentation from the seeded outbreak template and maps only already
// published resources. Existing outbreak APIs and records are never mutated.
func (s ContentHubService) ConfigureOutbreakHub(actor ContentHubActor, outbreakID uuid.UUID, in ConfigureOutbreakHubInput) (*ContentHubWorkspace, error) {
	if outbreakID == uuid.Nil {
		return nil, ErrContentHubInvalid
	}
	var existing models.ContentHub
	if err := s.DB.Joins("JOIN content_hub_outbreaks cho ON cho.content_hub_id = content_hubs.id").Where("cho.outbreak_id = ? AND content_hubs.deleted_at IS NULL", outbreakID).First(&existing).Error; err == nil {
		return s.GetWorkspace(existing.ID)
	} else if err != nil && err != gorm.ErrRecordNotFound {
		return nil, err
	}

	var outbreak models.Outbreak
	if err := s.DB.Where("id = ? AND deleted_at IS NULL", outbreakID).First(&outbreak).Error; err != nil {
		return nil, err
	}
	name := strings.TrimSpace(in.Name)
	if name == "" {
		name = strings.TrimSpace(outbreak.Title) + " Response Hub"
	}
	slug := strings.TrimSpace(in.Slug)
	if slug == "" {
		slug = normalizeHubSlug("", outbreak.Title+" response hub "+outbreak.ID.String()[:8])
	}
	hub, err := s.CreateHub(actor, CreateContentHubInput{Name: name, Slug: slug, Description: "Curated, approved response resources for " + outbreak.Title + ".", Icon: "warning", Color: "critical", Audience: "all", OutbreakIDs: []uuid.UUID{outbreakID}})
	if err != nil {
		return nil, err
	}
	templateID := defaultOutbreakHubTemplateID
	if in.TemplateID != nil {
		templateID = *in.TemplateID
	}
	if _, err = s.ApplyTemplate(actor, hub.ID, ApplyContentHubTemplateInput{TemplateID: templateID, LockVersion: hub.LockVersion}); err != nil {
		return nil, err
	}
	pillars, err := s.ListPillars(hub.ID)
	if err != nil {
		return nil, err
	}
	bySlug := map[string]models.ContentPillar{}
	for _, pillar := range pillars {
		bySlug[pillar.Slug] = pillar
	}

	documents := []models.OutbreakResource{}
	if err := s.DB.Where("outbreak_id = ? AND deleted_at IS NULL AND status = ? AND published_at IS NOT NULL AND approved_at IS NOT NULL AND withdrawn_at IS NULL", outbreakID, "published").Order("sort_order ASC, title ASC").Find(&documents).Error; err != nil {
		return nil, err
	}
	orders := map[uuid.UUID]int{}
	for _, document := range documents {
		pillar, ok := bySlug[outbreakDocumentPillar(document.DocumentKind)]
		if !ok {
			continue
		}
		orders[pillar.ID] += 10
		kind := models.ContentDiseaseOutbreakDocument
		if strings.EqualFold(document.DocumentKind, "form") {
			kind = models.ContentDiseaseForm
		}
		id := document.ID
		_, err = s.CreatePillarItem(actor, hub.ID, pillar.ID, ContentPillarItemInput{
			ContentType: kind, ContentID: &id, LabelOverride: document.Title,
			DescriptionOverride: document.Description, SortOrder: orders[pillar.ID],
			Status: models.ContentPillarItemStatusActive,
		})
		if err != nil && err != ErrContentHubDuplicate {
			return nil, err
		}
	}
	reports := []models.SituationReport{}
	if err := s.DB.Where("outbreak_id = ? AND deleted_at IS NULL AND status = ? AND published_at IS NOT NULL AND approved_at IS NOT NULL AND withdrawn_at IS NULL", outbreakID, "published").Order("publication_date DESC, title ASC").Find(&reports).Error; err != nil {
		return nil, err
	}
	if pillar, ok := bySlug["situation-reports"]; ok {
		for _, report := range reports {
			orders[pillar.ID] += 10
			id := report.ID
			if _, err = s.CreatePillarItem(actor, hub.ID, pillar.ID, ContentPillarItemInput{
				ContentType: models.ContentDiseaseSituationReport, ContentID: &id,
				LabelOverride: report.Title, DescriptionOverride: report.Summary,
				SortOrder: orders[pillar.ID], Status: models.ContentPillarItemStatusActive,
			}); err != nil && err != ErrContentHubDuplicate {
				return nil, err
			}
		}
	}
	if in.Publish {
		hub, err = s.GetHub(hub.ID)
		if err != nil {
			return nil, err
		}
		if _, err = s.TransitionHub(actor, hub.ID, "publish", ContentHubTransitionInput{LockVersion: hub.LockVersion}); err != nil {
			return nil, err
		}
	}
	return s.GetWorkspace(hub.ID)
}

func outbreakDocumentPillar(kind string) string {
	switch strings.ToLower(strings.TrimSpace(kind)) {
	case "case_definition":
		return "case-definition"
	case "surveillance_protocol":
		return "surveillance-guidance"
	case "checklist":
		return "screening-triage"
	case "ipc_protocol":
		return "ipc-ppe"
	case "laboratory_protocol":
		return "laboratory"
	case "form":
		return "forms"
	case "training_material", "communication_material":
		return "training"
	case "contact_tracing_guide":
		return "contacts"
	case "policy":
		return "medicines"
	case "situation_report_attachment":
		return "situation-reports"
	case "sop", "treatment_protocol", "referral_protocol":
		return "clinical-management"
	default:
		return "faqs"
	}
}

func (s ContentHubService) GetWorkspace(hubID uuid.UUID) (*ContentHubWorkspace, error) {
	hub, err := s.GetHub(hubID)
	if err != nil {
		return nil, err
	}
	pillars, err := s.ListPillars(hubID)
	if err != nil {
		return nil, err
	}
	out := &ContentHubWorkspace{Hub: *hub, Pillars: make([]ContentHubAdminPillar, 0, len(pillars))}
	for _, pillar := range pillars {
		items, itemErr := s.ListPillarItems(hubID, pillar.ID)
		if itemErr != nil {
			return nil, itemErr
		}
		out.Pillars = append(out.Pillars, ContentHubAdminPillar{ContentPillar: pillar, Items: items})
	}
	return out, nil
}

func (s ContentHubService) ListAudit(hubID uuid.UUID, page PageInput) (*PageResult[ContentHubAuditRecord], error) {
	if _, err := s.GetHub(hubID); err != nil {
		return nil, err
	}
	p := page.Normalize(50, 200)
	ids := []string{hubID.String()}
	var pillarIDs []uuid.UUID
	if err := s.DB.Model(&models.ContentPillar{}).Where("hub_id = ?", hubID).Pluck("id", &pillarIDs).Error; err != nil {
		return nil, err
	}
	for _, id := range pillarIDs {
		ids = append(ids, id.String())
	}
	if len(pillarIDs) > 0 {
		var itemIDs []uuid.UUID
		if err := s.DB.Model(&models.ContentPillarItem{}).Where("pillar_id IN ?", pillarIDs).Pluck("id", &itemIDs).Error; err != nil {
			return nil, err
		}
		for _, id := range itemIDs {
			ids = append(ids, id.String())
		}
	}
	q := s.DB.Model(&models.AuditLog{}).Where("entity_id IN ? AND (entity_type = ? OR entity_type = ? OR entity_type = ?)", ids, "content_hub", "content_pillar", "content_pillar_item")
	var total int64
	if err := q.Count(&total).Error; err != nil {
		return nil, err
	}
	rows := []models.AuditLog{}
	if err := q.Order("created_at DESC, id DESC").Limit(p.PerPage).Offset(p.Offset()).Find(&rows).Error; err != nil {
		return nil, err
	}
	out := make([]ContentHubAuditRecord, 0, len(rows))
	for _, row := range rows {
		metadata := map[string]any{}
		_ = json.Unmarshal([]byte(row.MetadataJSON), &metadata)
		out = append(out, ContentHubAuditRecord{ID: row.ID, ActorID: row.ActorID, Action: row.Action, EntityType: row.EntityType, EntityID: row.EntityID, Metadata: metadata, IPAddress: row.IPAddress, CreatedAt: row.CreatedAt})
	}
	return NewPageResult(out, p, total), nil
}

func (s ContentHubService) SearchAssignableResources(in ContentHubResourceQuery) (*PageResult[AssignableHubResource], error) {
	p := in.Page.Normalize(20, 100)
	kind := strings.ToLower(strings.TrimSpace(in.ContentType))
	if _, ok := supportedPillarItemTypes[kind]; !ok || kind == models.ContentPillarItemInternalRoute || kind == models.ContentPillarItemApprovedExternalURL {
		return nil, ErrContentPillarUnsupported
	}
	like := "%" + strings.ToLower(strings.TrimSpace(in.Search)) + "%"
	table, title, description, status, contextColumn, predicate := "", "", "", "", "''", "deleted_at IS NULL"
	switch kind {
	case models.ContentDiseaseGuideline:
		table, title, description, status, contextColumn = "guideline_documents", "title", "description", "CASE WHEN current_version_id IS NULL THEN 'draft' ELSE 'published' END", "COALESCE(source_org, '')"
	case models.ContentDiseaseOutbreakDocument, models.ContentDiseaseForm:
		table, title, description, status, contextColumn = "outbreak_resources", "title", "description", "status", "COALESCE(document_kind, '')"
		predicate += " AND resource_type IN ('managed_document','downloadable_asset')"
		if kind == models.ContentDiseaseForm {
			predicate += " AND lower(document_kind) = 'form'"
		}
	case models.ContentDiseaseSituationReport:
		table, title, description, status, contextColumn = "situation_reports", "title", "summary", "status", "COALESCE(geographic_area, '')"
	case models.ContentDiseaseAlgorithm:
		table, title, description, status, contextColumn = "guideline_content_blocks", "'Algorithm'", "COALESCE(content_json::text, '')", "review_status", "type"
		predicate += " AND type IN ('algorithm','algorithm_reference')"
	case models.ContentDiseaseClinicalTool:
		table, title, description, status, contextColumn = "calculators", "name", "COALESCE(description, '')", "status", "COALESCE(type, '')"
	case models.ContentDiseaseDrugReference:
		table, title, description, status, contextColumn = "drugs", "name", "COALESCE(description, '')", "status", "COALESCE(brand_names, '')"
	}
	if strings.TrimSpace(in.OutbreakID) != "" && (kind == models.ContentDiseaseOutbreakDocument || kind == models.ContentDiseaseForm || kind == models.ContentDiseaseSituationReport) {
		id, err := uuid.Parse(in.OutbreakID)
		if err != nil {
			return nil, ErrContentHubInvalid
		}
		predicate += fmt.Sprintf(" AND outbreak_id = '%s'", id.String())
	}
	base := s.DB.Table(table).Where(predicate)
	if strings.TrimSpace(in.Search) != "" {
		base = base.Where("lower("+title+") LIKE ? OR lower("+description+") LIKE ?", like, like)
	}
	var total int64
	if err := base.Count(&total).Error; err != nil {
		return nil, err
	}
	rows := []AssignableHubResource{}
	selectSQL := fmt.Sprintf("id, '%s' AS content_type, %s AS title, %s AS description, %s AS status, %s AS context", kind, title, description, status, contextColumn)
	if err := base.Select(selectSQL).Order("title ASC, id ASC").Limit(p.PerPage).Offset(p.Offset()).Scan(&rows).Error; err != nil {
		return nil, err
	}
	return NewPageResult(rows, p, total), nil
}
