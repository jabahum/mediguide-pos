package services

import (
	"errors"
	"testing"

	"mediguide/internal/models"

	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func consultantTestService(t *testing.T) ConsultantService {
	t.Helper()
	db, err := gorm.Open(sqlite.Open("file:"+t.Name()+"?mode=memory&cache=shared"), &gorm.Config{DisableForeignKeyConstraintWhenMigrating: true})
	if err != nil {
		t.Fatal(err)
	}
	if err := db.AutoMigrate(&models.User{}, &models.Consultant{}); err != nil {
		t.Fatal(err)
	}
	return ConsultantService{DB: db}
}

func TestConsultantVisibilityAndTypedFilters(t *testing.T) {
	s := consultantTestService(t)
	active, pending := "active", "pending_approval"
	name, email, phone, specialty, country := "Amina", "amina@example.com", "+256700000000", "Cardiology", "Uganda"
	verified := true
	created, err := s.Create(ConsultantInput{Name: &name, Email: &email, Phone: &phone, Specialty: &specialty, Country: &country, Status: &active, IsVerified: &verified})
	if err != nil {
		t.Fatal(err)
	}
	name, email = "Hidden", "hidden@example.com"
	if _, err = s.Create(ConsultantInput{Name: &name, Email: &email, Phone: &phone, Specialty: &specialty, Country: &country, Status: &pending}); err != nil {
		t.Fatal(err)
	}
	public, err := s.List(ConsultantQuery{Page: PageInput{Page: 1, PerPage: 20}, Verified: &verified})
	if err != nil {
		t.Fatal(err)
	}
	if len(public.Items) != 1 || public.Items[0].ID != created.Item.ID {
		t.Fatalf("expected only verified active consultant, got %#v", public.Items)
	}
	admin, err := s.List(ConsultantQuery{Page: PageInput{Page: 1, PerPage: 20}, IncludeInactive: true})
	if err != nil || admin.TotalItems != 2 {
		t.Fatalf("expected editor visibility, got %#v, %v", admin, err)
	}
}

func TestConsultantValidationAndSoftDelete(t *testing.T) {
	s := consultantTestService(t)
	name, email, phone, specialty, country := "Amina", "invalid", "+256700000000", "Cardiology", "Uganda"
	if _, err := s.Create(ConsultantInput{Name: &name, Email: &email, Phone: &phone, Specialty: &specialty, Country: &country}); !errors.Is(err, ErrConsultantInvalid) {
		t.Fatalf("expected invalid email, got %v", err)
	}
	email = "amina@example.com"
	created, err := s.Create(ConsultantInput{Name: &name, Email: &email, Phone: &phone, Specialty: &specialty, Country: &country})
	if err != nil {
		t.Fatal(err)
	}
	if err := s.Delete(created.Item.ID); err != nil {
		t.Fatal(err)
	}
	if _, err := s.Get(created.Item.ID, true); !errors.Is(err, gorm.ErrRecordNotFound) {
		t.Fatalf("expected soft-deleted consultant to be hidden, got %v", err)
	}
}
