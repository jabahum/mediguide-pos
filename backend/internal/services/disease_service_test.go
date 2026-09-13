package services

import (
	"errors"
	"testing"

	"mediguide/internal/models"

	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func diseaseTestService(t *testing.T) DiseaseService {
	t.Helper()
	db, err := gorm.Open(sqlite.Open("file:"+t.Name()+"?mode=memory&cache=shared"), &gorm.Config{DisableForeignKeyConstraintWhenMigrating: true})
	if err != nil {
		t.Fatal(err)
	}
	if err := db.AutoMigrate(&models.Disease{}, &models.DiseaseAlias{}, &models.DiseaseCode{}); err != nil {
		t.Fatal(err)
	}
	return DiseaseService{DB: db}
}

func TestDiseaseTaxonomyCreatesSearchableAliasesAndCodes(t *testing.T) {
	service := diseaseTestService(t)
	aliases := []DiseaseAliasInput{{Alias: "EVD"}, {Alias: "Ebola"}}
	codes := []DiseaseCodeInput{{CodeSystem: "ICD-11", Code: "1D60"}}
	disease, err := service.Save(DiseaseActor{}, nil, DiseaseInput{
		Name: stringPtr("Ebola virus disease"), Aliases: &aliases, Codes: &codes,
	})
	if err != nil {
		t.Fatal(err)
	}
	if disease.Slug != "ebola-virus-disease" || len(disease.Aliases) != 2 || len(disease.Codes) != 1 {
		t.Fatalf("unexpected disease: %#v", disease)
	}
	result, err := service.List(false, DiseaseQuery{Search: "evd", Page: PageInput{Page: 1, PerPage: 20}})
	if err != nil || result.TotalItems != 1 || result.Items[0].ID != disease.ID {
		t.Fatalf("alias search result=%#v err=%v", result, err)
	}
}

func TestDiseaseHierarchyIsNestedAndDeterministic(t *testing.T) {
	service := diseaseTestService(t)
	parent, err := service.Save(DiseaseActor{}, nil, DiseaseInput{Name: stringPtr("Communicable diseases")})
	if err != nil {
		t.Fatal(err)
	}
	parentID := parent.ID.String()
	for _, name := range []string{"Malaria", "Ebola virus disease"} {
		if _, err := service.Save(DiseaseActor{}, nil, DiseaseInput{Name: stringPtr(name), ParentID: &parentID}); err != nil {
			t.Fatal(err)
		}
	}
	tree, err := service.Hierarchy(models.DiseaseStatusActive)
	if err != nil {
		t.Fatal(err)
	}
	if len(tree) != 1 || tree[0].ID != parent.ID || len(tree[0].Children) != 2 {
		t.Fatalf("unexpected hierarchy: %#v", tree)
	}
	if tree[0].Children[0].Name != "Ebola virus disease" || tree[0].Children[1].Name != "Malaria" {
		t.Fatalf("children are not deterministically ordered: %#v", tree[0].Children)
	}
}

func TestDiseaseTaxonomyRejectsHierarchyCyclesAndInactiveNewParents(t *testing.T) {
	service := diseaseTestService(t)
	parent, err := service.Save(DiseaseActor{}, nil, DiseaseInput{Name: stringPtr("Parent condition")})
	if err != nil {
		t.Fatal(err)
	}
	parentID := parent.ID.String()
	child, err := service.Save(DiseaseActor{}, nil, DiseaseInput{Name: stringPtr("Child condition"), ParentID: &parentID})
	if err != nil {
		t.Fatal(err)
	}
	childID := child.ID.String()
	if _, err := service.Save(DiseaseActor{}, &parent.ID, DiseaseInput{ParentID: &childID}); !errors.Is(err, ErrDiseaseCycle) {
		t.Fatalf("expected hierarchy cycle, got %v", err)
	}

	inactive := models.DiseaseStatusInactive
	if _, err := service.Save(DiseaseActor{}, &parent.ID, DiseaseInput{Status: &inactive}); err != nil {
		t.Fatal(err)
	}
	if _, err := service.Save(DiseaseActor{}, nil, DiseaseInput{Name: stringPtr("Another child"), ParentID: &parentID}); !errors.Is(err, ErrDiseaseInvalid) {
		t.Fatalf("expected inactive-parent rejection, got %v", err)
	}
}

func TestDiseaseTaxonomyPreventsAmbiguousActiveNamesAndAliases(t *testing.T) {
	service := diseaseTestService(t)
	aliases := []DiseaseAliasInput{{Alias: "High blood pressure"}}
	first, err := service.Save(DiseaseActor{}, nil, DiseaseInput{Name: stringPtr("Hypertension"), Aliases: &aliases})
	if err != nil {
		t.Fatal(err)
	}
	if _, err := service.Save(DiseaseActor{}, nil, DiseaseInput{Name: stringPtr("High-blood pressure")}); !errors.Is(err, ErrDiseaseConflict) {
		t.Fatalf("expected name-alias conflict, got %v", err)
	}
	conflictingAliases := []DiseaseAliasInput{{Alias: "Hypertension"}}
	if _, err := service.Save(DiseaseActor{}, nil, DiseaseInput{Name: stringPtr("Raised blood pressure"), Aliases: &conflictingAliases}); !errors.Is(err, ErrDiseaseConflict) {
		t.Fatalf("expected alias-name conflict, got %v", err)
	}
	archived := models.DiseaseStatusArchived
	if _, err := service.Save(DiseaseActor{}, &first.ID, DiseaseInput{Status: &archived}); err != nil {
		t.Fatal(err)
	}
	if _, err := service.Save(DiseaseActor{}, nil, DiseaseInput{Name: stringPtr("High blood pressure"), Slug: stringPtr("high-blood-pressure-active")}); err != nil {
		t.Fatalf("archived aliases must not block a new active canonical name: %v", err)
	}
}

func TestDiseaseTaxonomyRevalidatesRetainedAliasesWhenActivated(t *testing.T) {
	service := diseaseTestService(t)
	inactive := models.DiseaseStatusInactive
	aliases := []DiseaseAliasInput{{Alias: "HF"}}
	first, err := service.Save(DiseaseActor{}, nil, DiseaseInput{
		Name: stringPtr("Historic fever"), Status: &inactive, Aliases: &aliases,
	})
	if err != nil {
		t.Fatal(err)
	}
	if _, err := service.Save(DiseaseActor{}, nil, DiseaseInput{Name: stringPtr("HF")}); err != nil {
		t.Fatalf("an inactive alias should not reserve an active canonical name: %v", err)
	}
	active := models.DiseaseStatusActive
	if _, err := service.Save(DiseaseActor{}, &first.ID, DiseaseInput{Status: &active}); !errors.Is(err, ErrDiseaseConflict) {
		t.Fatalf("expected retained alias conflict during activation, got %v", err)
	}
}

func TestDiseaseTaxonomyRegeneratesAnExplicitlyClearedSlug(t *testing.T) {
	service := diseaseTestService(t)
	empty := ""
	disease, err := service.Save(DiseaseActor{}, nil, DiseaseInput{Name: stringPtr("Lassa fever"), Slug: &empty})
	if err != nil {
		t.Fatal(err)
	}
	if disease.Slug != "lassa-fever" {
		t.Fatalf("expected generated slug, got %q", disease.Slug)
	}
}

func TestDiseaseTaxonomyRejectsDuplicateCodes(t *testing.T) {
	service := diseaseTestService(t)
	code := []DiseaseCodeInput{{CodeSystem: "SNOMED CT", Code: "73211009"}}
	if _, err := service.Save(DiseaseActor{}, nil, DiseaseInput{Name: stringPtr("Diabetes mellitus"), Codes: &code}); err != nil {
		t.Fatal(err)
	}
	duplicate := []DiseaseCodeInput{{CodeSystem: "snomed ct", Code: "73211009"}}
	if _, err := service.Save(DiseaseActor{}, nil, DiseaseInput{Name: stringPtr("Other diabetes"), Codes: &duplicate}); !errors.Is(err, ErrDiseaseConflict) {
		t.Fatalf("expected duplicate code conflict, got %v", err)
	}
}

func TestDiseaseTaxonomyArchivePreservesEditorReadAndProtectsChildren(t *testing.T) {
	service := diseaseTestService(t)
	parent, err := service.Save(DiseaseActor{}, nil, DiseaseInput{Name: stringPtr("Parent")})
	if err != nil {
		t.Fatal(err)
	}
	parentID := parent.ID.String()
	child, err := service.Save(DiseaseActor{}, nil, DiseaseInput{Name: stringPtr("Child"), ParentID: &parentID})
	if err != nil {
		t.Fatal(err)
	}
	if err := service.Archive(DiseaseActor{}, parent.ID); !errors.Is(err, ErrDiseaseParentInUse) {
		t.Fatalf("expected child protection, got %v", err)
	}
	if err := service.Archive(DiseaseActor{}, child.ID); err != nil {
		t.Fatal(err)
	}
	if _, err := service.Get(child.ID, false); !errors.Is(err, gorm.ErrRecordNotFound) {
		t.Fatalf("reader should not see archived disease, got %v", err)
	}
	archived, err := service.Get(child.ID, true)
	if err != nil || archived.Status != models.DiseaseStatusArchived {
		t.Fatalf("editor archive read=%#v err=%v", archived, err)
	}
}
