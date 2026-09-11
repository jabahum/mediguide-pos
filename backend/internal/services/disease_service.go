package services

import (
	"encoding/json"
	"errors"
	"regexp"
	"strings"
	"unicode"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

var (
	ErrDiseaseInvalid     = errors.New("invalid disease taxonomy payload")
	ErrDiseaseConflict    = errors.New("disease taxonomy value already exists")
	ErrDiseaseCycle       = errors.New("disease hierarchy cycle")
	ErrDiseaseParentInUse = errors.New("disease has non-archived children")
)

type DiseaseService struct{ DB *gorm.DB }

type DiseaseActor struct {
	ID uuid.UUID
	IP string
}

type DiseaseQuery struct {
	Page                     PageInput
	Search, Status, ParentID string
	Sort, Order              string
	RootOnly                 *bool
}

type DiseaseAliasInput struct {
	Alias string `json:"alias"`
}

type DiseaseCodeInput struct {
	CodeSystem  string  `json:"code_system"`
	Code        string  `json:"code"`
	DisplayName *string `json:"display_name"`
}

type DiseaseInput struct {
	ParentID    *string              `json:"parent_id"`
	Name        *string              `json:"name"`
	Slug        *string              `json:"slug"`
	ShortName   *string              `json:"short_name"`
	Description *string              `json:"description"`
	Icon        *string              `json:"icon"`
	Color       *string              `json:"color"`
	Status      *string              `json:"status"`
	SortOrder   *int                 `json:"sort_order"`
	Aliases     *[]DiseaseAliasInput `json:"aliases"`
	Codes       *[]DiseaseCodeInput  `json:"codes"`
}

type DiseaseMigrationReportQuery struct {
	Page                PageInput
	Status, SourceTable string
}

func (s DiseaseService) List(editor bool, in DiseaseQuery) (*PageResult[models.Disease], error) {
	p := in.Page.Normalize(20, 100)
	q := s.DB.Model(&models.Disease{}).
		Select("diseases.*, parent.name AS parent_name").
		Joins("LEFT JOIN diseases parent ON parent.id = diseases.parent_id AND parent.deleted_at IS NULL").
		Where("diseases.deleted_at IS NULL").
		Preload("Aliases", func(db *gorm.DB) *gorm.DB { return db.Order("alias ASC") }).
		Preload("Codes", func(db *gorm.DB) *gorm.DB { return db.Order("code_system ASC, code ASC") })
	if editor {
		if in.Status != "" {
			if !validDiseaseStatus(in.Status) {
				return nil, ErrDiseaseInvalid
			}
			q = q.Where("diseases.status = ?", in.Status)
		}
	} else {
		q = q.Where("diseases.status = ?", models.DiseaseStatusActive)
	}
	if in.ParentID != "" {
		parentID, err := uuid.Parse(in.ParentID)
		if err != nil {
			return nil, ErrDiseaseInvalid
		}
		q = q.Where("diseases.parent_id = ?", parentID)
	} else if in.RootOnly != nil && *in.RootOnly {
		q = q.Where("diseases.parent_id IS NULL")
	}
	if search := normalizeDiseaseTerm(in.Search); search != "" {
		like := "%" + search + "%"
		q = q.Where(`diseases.normalized_name LIKE ? OR lower(diseases.slug) LIKE ? OR
			EXISTS (SELECT 1 FROM disease_aliases da WHERE da.disease_id = diseases.id AND da.deleted_at IS NULL AND da.normalized_alias LIKE ?)`, like, like, like)
	}
	return pageHelp[models.Disease](q, p,
		map[string]string{"name": "diseases.name", "sort_order": "diseases.sort_order", "created_at": "diseases.created_at", "updated_at": "diseases.updated_at"},
		in.Sort, in.Order, "diseases.sort_order ASC, diseases.name ASC")
}

func (s DiseaseService) Get(id uuid.UUID, editor bool) (*models.Disease, error) {
	q := s.DB.Model(&models.Disease{}).
		Select("diseases.*, parent.name AS parent_name").
		Joins("LEFT JOIN diseases parent ON parent.id = diseases.parent_id AND parent.deleted_at IS NULL").
		Where("diseases.id = ? AND diseases.deleted_at IS NULL", id).
		Preload("Aliases", func(db *gorm.DB) *gorm.DB { return db.Order("alias ASC") }).
		Preload("Codes", func(db *gorm.DB) *gorm.DB { return db.Order("code_system ASC, code ASC") })
	if !editor {
		q = q.Where("diseases.status = ?", models.DiseaseStatusActive)
	}
	var disease models.Disease
	if err := q.First(&disease).Error; err != nil {
		return nil, err
	}
	return &disease, nil
}

func (s DiseaseService) Save(actor DiseaseActor, id *uuid.UUID, in DiseaseInput) (*models.Disease, error) {
	var savedID uuid.UUID
	err := s.DB.Transaction(func(tx *gorm.DB) error {
		item := models.Disease{Status: models.DiseaseStatusActive}
		var originalParent *uuid.UUID
		if id != nil {
			if err := tx.Where("id = ? AND deleted_at IS NULL", *id).First(&item).Error; err != nil {
				return err
			}
			originalParent = item.ParentID
		}
		if in.Name != nil {
			item.Name = strings.TrimSpace(*in.Name)
		}
		item.NormalizedName = normalizeDiseaseTerm(item.Name)
		if in.Slug != nil {
			item.Slug = strings.ToLower(strings.TrimSpace(*in.Slug))
			if item.Slug == "" {
				item.Slug = taxonomySlugify(item.Name)
			}
		} else if id == nil || item.Slug == "" {
			item.Slug = taxonomySlugify(item.Name)
		}
		item.ShortName = diseaseOptional(item.ShortName, in.ShortName)
		item.Description = diseaseOptional(item.Description, in.Description)
		item.Icon = diseaseOptional(item.Icon, in.Icon)
		item.Color = diseaseOptional(item.Color, in.Color)
		if in.Status != nil {
			item.Status = strings.ToLower(strings.TrimSpace(*in.Status))
		}
		if in.SortOrder != nil {
			item.SortOrder = *in.SortOrder
		}
		if in.ParentID != nil {
			parentID, err := optionalUUIDInput(in.ParentID)
			if err != nil {
				return ErrDiseaseInvalid
			}
			item.ParentID = parentID
		}
		if actor.ID != uuid.Nil {
			item.UpdatedBy = &actor.ID
			if id == nil {
				item.CreatedBy = &actor.ID
			}
		}
		if err := validateDiseaseFields(item); err != nil {
			return err
		}
		parentChanged := !sameOptionalUUID(originalParent, item.ParentID)
		if item.ParentID != nil && (id == nil || parentChanged) {
			if err := validateDiseaseParent(tx, *item.ParentID, id); err != nil {
				return err
			}
		}

		aliases, err := normalizeDiseaseAliases(in.Aliases)
		if err != nil {
			return err
		}
		// A PATCH that omits aliases preserves them. Include the retained aliases
		// in identity validation, particularly when reactivating a disease.
		if id != nil && in.Aliases == nil {
			if err := tx.Where("disease_id = ?", item.ID).Find(&aliases).Error; err != nil {
				return err
			}
		}
		codes, err := normalizeDiseaseCodes(in.Codes)
		if err != nil {
			return err
		}
		if id != nil && in.Codes == nil {
			if err := tx.Where("disease_id = ?", item.ID).Find(&codes).Error; err != nil {
				return err
			}
		}
		if err := validateDiseaseIdentity(tx, id, item, aliases); err != nil {
			return err
		}
		if err := validateDiseaseCodesAvailable(tx, id, codes); err != nil {
			return err
		}
		if err := tx.Save(&item).Error; err != nil {
			return mapDiseaseConstraintError(err)
		}
		savedID = item.ID
		if in.Aliases != nil {
			if err := tx.Where("disease_id = ?", item.ID).Delete(&models.DiseaseAlias{}).Error; err != nil {
				return err
			}
			for i := range aliases {
				aliases[i].DiseaseID = item.ID
				if err := tx.Create(&aliases[i]).Error; err != nil {
					return mapDiseaseConstraintError(err)
				}
			}
		}
		if in.Codes != nil {
			if err := tx.Where("disease_id = ?", item.ID).Delete(&models.DiseaseCode{}).Error; err != nil {
				return err
			}
			for i := range codes {
				codes[i].DiseaseID = item.ID
				if err := tx.Create(&codes[i]).Error; err != nil {
					return mapDiseaseConstraintError(err)
				}
			}
		}
		if actor.ID != uuid.Nil && tx.Migrator().HasTable(&models.AuditLog{}) {
			action := "disease.created"
			if id != nil {
				action = "disease.updated"
			}
			if err := writeDiseaseAudit(tx, actor, action, item.ID, map[string]any{"name": item.Name, "status": item.Status}); err != nil {
				return err
			}
		}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return s.Get(savedID, true)
}

func (s DiseaseService) Archive(actor DiseaseActor, id uuid.UUID) error {
	return s.DB.Transaction(func(tx *gorm.DB) error {
		var item models.Disease
		if err := tx.Where("id = ? AND deleted_at IS NULL", id).First(&item).Error; err != nil {
			return err
		}
		var children int64
		if err := tx.Model(&models.Disease{}).Where("parent_id = ? AND status <> ? AND deleted_at IS NULL", id, models.DiseaseStatusArchived).Count(&children).Error; err != nil {
			return err
		}
		if children > 0 {
			return ErrDiseaseParentInUse
		}
		updates := map[string]any{"status": models.DiseaseStatusArchived}
		if actor.ID != uuid.Nil {
			updates["updated_by"] = actor.ID
		}
		if err := tx.Model(&item).Updates(updates).Error; err != nil {
			return err
		}
		if actor.ID != uuid.Nil && tx.Migrator().HasTable(&models.AuditLog{}) {
			return writeDiseaseAudit(tx, actor, "disease.archived", item.ID, map[string]any{"name": item.Name})
		}
		return nil
	})
}

func (s DiseaseService) ListMigrationReport(in DiseaseMigrationReportQuery) (*PageResult[models.DiseaseTaxonomyMigrationReport], error) {
	p := in.Page.Normalize(50, 500)
	q := s.DB.Model(&models.DiseaseTaxonomyMigrationReport{})
	if in.Status != "" {
		if !oneOf(in.Status, "matched", "ambiguous", "unmatched") {
			return nil, ErrDiseaseInvalid
		}
		q = q.Where("resolution_status = ?", in.Status)
	}
	if in.SourceTable != "" {
		if !oneOf(in.SourceTable, "outbreaks", "medical_guidelines", "guideline_documents") {
			return nil, ErrDiseaseInvalid
		}
		q = q.Where("source_table = ?", in.SourceTable)
	}
	return pageHelp[models.DiseaseTaxonomyMigrationReport](q, p, nil, "", "", "resolution_status ASC, source_table ASC, source_value ASC")
}

func (s DiseaseService) RefreshMigrationReport(actor DiseaseActor) error {
	if s.DB.Dialector.Name() != "postgres" {
		return ErrDiseaseInvalid
	}
	return s.DB.Transaction(func(tx *gorm.DB) error {
		if err := tx.Exec("SELECT refresh_disease_taxonomy_migration_report()").Error; err != nil {
			return err
		}
		if actor.ID != uuid.Nil && tx.Migrator().HasTable(&models.AuditLog{}) {
			return writeDiseaseAudit(tx, actor, "disease.migration_report.refreshed", uuid.Nil, nil)
		}
		return nil
	})
}

func validateDiseaseFields(item models.Disease) error {
	if len(item.Name) < 2 || len(item.Name) > 240 || item.NormalizedName == "" ||
		!validTaxonomySlug(item.Slug) || len(item.Slug) > 240 || !validDiseaseStatus(item.Status) || item.SortOrder < 0 ||
		diseaseStringTooLong(item.ShortName, 80) || diseaseStringTooLong(item.Description, 10_000) ||
		diseaseStringTooLong(item.Icon, 120) || diseaseStringTooLong(item.Color, 80) {
		return ErrDiseaseInvalid
	}
	return nil
}

func validateDiseaseParent(tx *gorm.DB, parentID uuid.UUID, id *uuid.UUID) error {
	if id != nil && parentID == *id {
		return ErrDiseaseCycle
	}
	var parent models.Disease
	if err := tx.Select("id", "parent_id", "status").Where("id = ? AND deleted_at IS NULL", parentID).First(&parent).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return ErrDiseaseInvalid
		}
		return err
	}
	if parent.Status != models.DiseaseStatusActive {
		return ErrDiseaseInvalid
	}
	seen := map[uuid.UUID]bool{parent.ID: true}
	current := parent
	for current.ParentID != nil {
		if id != nil && *current.ParentID == *id {
			return ErrDiseaseCycle
		}
		if seen[*current.ParentID] {
			return ErrDiseaseCycle
		}
		seen[*current.ParentID] = true
		if err := tx.Select("id", "parent_id").Where("id = ? AND deleted_at IS NULL", *current.ParentID).First(&current).Error; err != nil {
			return ErrDiseaseInvalid
		}
	}
	return nil
}

func validateDiseaseIdentity(tx *gorm.DB, id *uuid.UUID, item models.Disease, aliases []models.DiseaseAlias) error {
	q := tx.Model(&models.Disease{}).Where("deleted_at IS NULL AND status = ? AND normalized_name = ?", models.DiseaseStatusActive, item.NormalizedName)
	if id != nil {
		q = q.Where("id <> ?", *id)
	}
	var count int64
	if err := q.Count(&count).Error; err != nil {
		return err
	}
	if count > 0 {
		return ErrDiseaseConflict
	}
	aliasNameQuery := tx.Table("disease_aliases da").Joins("JOIN diseases d ON d.id = da.disease_id").
		Where("da.deleted_at IS NULL AND d.deleted_at IS NULL AND d.status = ? AND da.normalized_alias = ?", models.DiseaseStatusActive, item.NormalizedName)
	if id != nil {
		aliasNameQuery = aliasNameQuery.Where("d.id <> ?", *id)
	}
	if err := aliasNameQuery.Count(&count).Error; err != nil {
		return err
	}
	if count > 0 {
		return ErrDiseaseConflict
	}
	for _, alias := range aliases {
		if alias.NormalizedAlias == item.NormalizedName {
			return ErrDiseaseInvalid
		}
		nameQuery := tx.Model(&models.Disease{}).Where("deleted_at IS NULL AND status = ? AND normalized_name = ?", models.DiseaseStatusActive, alias.NormalizedAlias)
		aliasQuery := tx.Table("disease_aliases da").Joins("JOIN diseases d ON d.id = da.disease_id").
			Where("da.deleted_at IS NULL AND d.deleted_at IS NULL AND d.status = ? AND da.normalized_alias = ?", models.DiseaseStatusActive, alias.NormalizedAlias)
		if id != nil {
			nameQuery = nameQuery.Where("id <> ?", *id)
			aliasQuery = aliasQuery.Where("d.id <> ?", *id)
		}
		if err := nameQuery.Count(&count).Error; err != nil {
			return err
		}
		if count > 0 {
			return ErrDiseaseConflict
		}
		if err := aliasQuery.Count(&count).Error; err != nil {
			return err
		}
		if count > 0 {
			return ErrDiseaseConflict
		}
	}
	return nil
}

func validateDiseaseCodesAvailable(tx *gorm.DB, id *uuid.UUID, codes []models.DiseaseCode) error {
	for _, code := range codes {
		q := tx.Model(&models.DiseaseCode{}).Where("deleted_at IS NULL AND lower(code_system) = lower(?) AND lower(code) = lower(?)", code.CodeSystem, code.Code)
		if id != nil {
			q = q.Where("disease_id <> ?", *id)
		}
		var count int64
		if err := q.Count(&count).Error; err != nil {
			return err
		}
		if count > 0 {
			return ErrDiseaseConflict
		}
	}
	return nil
}

func normalizeDiseaseAliases(input *[]DiseaseAliasInput) ([]models.DiseaseAlias, error) {
	if input == nil {
		return nil, nil
	}
	if len(*input) > 100 {
		return nil, ErrDiseaseInvalid
	}
	seen := map[string]bool{}
	aliases := make([]models.DiseaseAlias, 0, len(*input))
	for _, raw := range *input {
		alias := strings.TrimSpace(raw.Alias)
		normalized := normalizeDiseaseTerm(alias)
		if alias == "" || len(alias) > 240 || normalized == "" || seen[normalized] {
			return nil, ErrDiseaseInvalid
		}
		seen[normalized] = true
		aliases = append(aliases, models.DiseaseAlias{Alias: alias, NormalizedAlias: normalized})
	}
	return aliases, nil
}

func normalizeDiseaseCodes(input *[]DiseaseCodeInput) ([]models.DiseaseCode, error) {
	if input == nil {
		return nil, nil
	}
	if len(*input) > 100 {
		return nil, ErrDiseaseInvalid
	}
	seen := map[string]bool{}
	codes := make([]models.DiseaseCode, 0, len(*input))
	for _, raw := range *input {
		system, code := strings.TrimSpace(raw.CodeSystem), strings.TrimSpace(raw.Code)
		key := strings.ToLower(system) + "\x00" + strings.ToLower(code)
		if system == "" || code == "" || len(system) > 80 || len(code) > 120 || seen[key] || diseaseStringTooLong(raw.DisplayName, 240) {
			return nil, ErrDiseaseInvalid
		}
		seen[key] = true
		codes = append(codes, models.DiseaseCode{CodeSystem: system, Code: code, DisplayName: diseaseOptional(nil, raw.DisplayName)})
	}
	return codes, nil
}

func normalizeDiseaseTerm(value string) string {
	var out strings.Builder
	space := true
	for _, r := range strings.ToLower(strings.TrimSpace(value)) {
		if unicode.IsLetter(r) || unicode.IsNumber(r) {
			out.WriteRune(r)
			space = false
		} else if !space {
			out.WriteByte(' ')
			space = true
		}
	}
	return strings.TrimSpace(out.String())
}

func validDiseaseStatus(value string) bool {
	return oneOf(value, models.DiseaseStatusActive, models.DiseaseStatusInactive, models.DiseaseStatusArchived)
}

func diseaseOptional(current, raw *string) *string {
	if raw == nil {
		return current
	}
	value := strings.TrimSpace(*raw)
	if value == "" {
		return nil
	}
	return &value
}

func diseaseStringTooLong(value *string, max int) bool {
	return value != nil && len(*value) > max
}

func sameOptionalUUID(left, right *uuid.UUID) bool {
	if left == nil || right == nil {
		return left == nil && right == nil
	}
	return *left == *right
}

func writeDiseaseAudit(tx *gorm.DB, actor DiseaseActor, action string, id uuid.UUID, metadata any) error {
	payload, err := json.Marshal(metadata)
	if err != nil {
		return err
	}
	return tx.Create(&models.AuditLog{ActorID: actor.ID.String(), Action: action, EntityType: "disease", EntityID: id.String(), MetadataJSON: string(payload), IPAddress: actor.IP}).Error
}

func mapDiseaseConstraintError(err error) error {
	message := strings.ToLower(err.Error())
	if regexp.MustCompile(`unique|duplicate`).MatchString(message) {
		return ErrDiseaseConflict
	}
	if strings.Contains(message, "cycle") {
		return ErrDiseaseCycle
	}
	return err
}
