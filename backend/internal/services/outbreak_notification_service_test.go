package services

import (
	"errors"
	"testing"
	"time"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/datatypes"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func outbreakNotificationTestService(t *testing.T) NotificationService {
	t.Helper()
	db, err := gorm.Open(sqlite.Open("file:"+uuid.NewString()+"?mode=memory&cache=shared"), &gorm.Config{})
	if err != nil {
		t.Fatal(err)
	}
	if err = db.AutoMigrate(&models.Outbreak{}, &models.SituationReport{}, &models.NotificationTemplate{}, &models.NotificationTemplateVersion{}, &models.NotificationCampaign{}, &models.AuditLog{}); err != nil {
		t.Fatal(err)
	}
	for _, value := range []struct{ key, action, idVariable string }{
		{"outbreak-alert", "outbreak", "outbreak_id"},
		{"outbreak-update", "outbreak", "outbreak_id"},
		{"outbreak-status-change", "outbreak", "outbreak_id"},
		{"situation-report-publication", "situation_report", "situation_report_id"},
	} {
		template := models.NotificationTemplate{Name: value.key, TemplateKey: value.key, Type: "push", Category: "Emergency Alerts", Status: "published", CurrentVersion: 1, Locale: "en"}
		if err := db.Create(&template).Error; err != nil {
			t.Fatal(err)
		}
		action := datatypes.JSON([]byte(`{"type":"` + value.action + `","resource_id":"{{` + value.idVariable + `}}","parameters":{}}`))
		rulesJSON := `{"` + value.idVariable + `":{"type":"string","required":true},"title":{"type":"string","required":true},"area":{"type":"string","required":true}`
		if value.action == "outbreak" {
			rulesJSON += `,"status":{"type":"string","required":true},"data_as_of":{"type":"string","required":false}`
		} else {
			rulesJSON += `,"publication_date":{"type":"string","required":true}`
		}
		rules := datatypes.JSON([]byte(rulesJSON + `}`))
		title := "{{title}}"
		version := models.NotificationTemplateVersion{TemplateID: template.ID, Version: 1, Channel: "push", TitleTemplate: &title, BodyTemplate: "{{title}} in {{area}}", ActionTemplate: action, VariableSchema: rules, Category: "Emergency Alerts", Locale: "en", Status: "published"}
		if err := db.Create(&version).Error; err != nil {
			t.Fatal(err)
		}
	}
	return NotificationService{DB: db}
}

func testOutbreakCampaignInput(key string) OutbreakNotificationCampaignInput {
	return OutbreakNotificationCampaignInput{Kind: "alert", Audience: NotificationAudienceDefinition{AllEligible: true, PreferenceCategories: []string{"outbreak_alerts"}}, Timezone: "Africa/Kampala", Priority: "high", RequestedChannels: []string{"push", "in-app"}, IdempotencyKey: key}
}

func TestOutbreakCampaignRequiresPublishedContentAndCreatesDraftIdempotently(t *testing.T) {
	service := outbreakNotificationTestService(t)
	actor := uuid.New()
	draft := models.Outbreak{Title: "Draft event", DiseaseType: "Ebola", GeographicArea: "Kampala", Status: "draft", LastUpdate: time.Now(), VisualTone: "critical", Metrics: datatypes.JSON(`[]`), LockVersion: 1}
	if err := service.DB.Create(&draft).Error; err != nil {
		t.Fatal(err)
	}
	if _, err := service.CreateOutbreakCampaign(draft.ID, testOutbreakCampaignInput("draft-rejected"), actor, "127.0.0.1"); err != ErrNotificationInvalid {
		t.Fatalf("expected invalid draft, got %v", err)
	}

	now := time.Now().UTC()
	published := models.Outbreak{Title: "Ebola", DiseaseType: "Ebola", GeographicArea: "Kampala", Status: "active", PublishedAt: &now, LastUpdate: now, VisualTone: "critical", Metrics: datatypes.JSON(`[]`), LockVersion: 1}
	if err := service.DB.Create(&published).Error; err != nil {
		t.Fatal(err)
	}
	first, err := service.CreateOutbreakCampaign(published.ID, testOutbreakCampaignInput("outbreak:ebola:v1"), actor, "127.0.0.1")
	if err != nil {
		t.Fatal(err)
	}
	if first.Status != "draft" || first.ActionSnapshot.Type != "outbreak" {
		t.Fatalf("unexpected campaign: %#v", first)
	}
	second, err := service.CreateOutbreakCampaign(published.ID, testOutbreakCampaignInput("outbreak:ebola:v1"), actor, "127.0.0.1")
	if err != nil {
		t.Fatal(err)
	}
	if second.ID != first.ID {
		t.Fatal("idempotent retry created another campaign")
	}

	published.WithdrawnAt = &now
	published.Status = "withdrawn"
	if err := service.DB.Save(&published).Error; err != nil {
		t.Fatal(err)
	}
	if _, err := service.CreateOutbreakCampaign(published.ID, testOutbreakCampaignInput("withdrawn-rejected"), actor, "127.0.0.1"); err != ErrNotificationInvalid {
		t.Fatalf("expected withdrawn rejection, got %v", err)
	}
}

func TestSituationReportCampaignRequiresVisiblePublishedParent(t *testing.T) {
	service := outbreakNotificationTestService(t)
	now := time.Now().UTC()
	parent := models.Outbreak{Title: "Private", DiseaseType: "Ebola", GeographicArea: "Kampala", Status: "draft", LastUpdate: now, VisualTone: "critical", Metrics: datatypes.JSON(`[]`), LockVersion: 1}
	if err := service.DB.Create(&parent).Error; err != nil {
		t.Fatal(err)
	}
	report := models.SituationReport{OutbreakID: &parent.ID, Title: "Report", GeographicArea: "Kampala", SourceOrganization: "MoH", PublicationDate: now, Status: "published", PublishedAt: &now, KeyHighlights: datatypes.JSON(`[]`), Metrics: datatypes.JSON(`[]`), LockVersion: 1}
	if err := service.DB.Create(&report).Error; err != nil {
		t.Fatal(err)
	}
	in := testOutbreakCampaignInput("report:v1")
	in.Kind = "publication"
	if _, err := service.CreateSituationReportCampaign(report.ID, in, uuid.New(), "127.0.0.1"); err != ErrNotificationInvalid {
		t.Fatalf("expected hidden-parent rejection, got %v", err)
	}
}

func TestSituationReportCampaignRejectsUnsupportedKind(t *testing.T) {
	service := outbreakNotificationTestService(t)
	now := time.Now().UTC()
	report := models.SituationReport{Title: "Report", GeographicArea: "Uganda", Status: "published", PublishedAt: &now, PublicationDate: now, KeyHighlights: datatypes.JSON(`[]`), Metrics: datatypes.JSON(`[]`), LockVersion: 1}
	if err := service.DB.Create(&report).Error; err != nil {
		t.Fatal(err)
	}
	_, err := service.CreateSituationReportCampaign(report.ID, OutbreakNotificationCampaignInput{Kind: "alert"}, uuid.New(), "127.0.0.1")
	if !errors.Is(err, ErrNotificationInvalid) {
		t.Fatalf("unsupported report campaign kind accepted: %v", err)
	}
}
