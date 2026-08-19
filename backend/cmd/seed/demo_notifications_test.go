package main

import (
	"testing"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func TestSeedDemoNotificationsIsIdempotentAndUserScoped(t *testing.T) {
	database, err := gorm.Open(
		sqlite.Open("file:"+t.Name()+"?mode=memory&cache=shared"),
		&gorm.Config{},
	)
	if err != nil {
		t.Fatal(err)
	}
	if err := database.AutoMigrate(
		&models.Notification{},
		&models.NotificationTemplate{},
		&models.NotificationTemplateVersion{},
		&models.NotificationCampaign{},
	); err != nil {
		t.Fatal(err)
	}

	clinicianID := uuid.New()
	for range 2 {
		if err := seedDemoNotifications(database, clinicianID); err != nil {
			t.Fatal(err)
		}
	}

	var total int64
	if err := database.Model(&models.Notification{}).Count(&total).Error; err != nil {
		t.Fatal(err)
	}
	if total != 4 {
		t.Fatalf("expected four idempotent notifications, got %d", total)
	}

	var global, owned int64
	if err := database.Model(&models.Notification{}).Where("user_id IS NULL").Count(&global).Error; err != nil {
		t.Fatal(err)
	}
	if err := database.Model(&models.Notification{}).Where("user_id = ?", clinicianID).Count(&owned).Error; err != nil {
		t.Fatal(err)
	}
	if global != 3 || owned != 1 {
		t.Fatalf("expected three global and one clinician notification, got %d and %d", global, owned)
	}

	var templates, versions, campaigns int64
	database.Model(&models.NotificationTemplate{}).Count(&templates)
	database.Model(&models.NotificationTemplateVersion{}).Count(&versions)
	database.Model(&models.NotificationCampaign{}).Count(&campaigns)
	if templates != 1 || versions != 1 || campaigns != 1 {
		t.Fatalf("expected one template version and campaign, got %d, %d and %d", templates, versions, campaigns)
	}
}
