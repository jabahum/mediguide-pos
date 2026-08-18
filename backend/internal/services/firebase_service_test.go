package services

import (
	"testing"

	"mediguide/internal/models"

	"github.com/google/uuid"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func firebaseTestService(t *testing.T) FirebaseService {
	t.Helper()
	db, err := gorm.Open(sqlite.Open("file:"+t.Name()+"?mode=memory&cache=shared"), &gorm.Config{})
	if err != nil {
		t.Fatal(err)
	}
	if err := db.AutoMigrate(&models.FirebaseDevice{}); err != nil {
		t.Fatal(err)
	}
	return FirebaseService{DB: db}
}

func TestFirebaseDeviceRegistrationIsOwnedAndHidesToken(t *testing.T) {
	service := firebaseTestService(t)
	owner := uuid.New()
	other := uuid.New()
	version := "2.0.24+51"

	device, err := service.RegisterDevice(owner, FirebaseDeviceInput{
		InstallationID:    "installation-one",
		RegistrationToken: "private-registration-token",
		Platform:          "IOS",
		AppVersion:        &version,
	})
	if err != nil {
		t.Fatal(err)
	}
	if device.UserID != owner || device.Platform != "ios" || device.RegistrationToken == "" {
		t.Fatalf("unexpected registered device: %#v", device)
	}
	if err := service.DeleteDevice(other, device.ID); err != gorm.ErrRecordNotFound {
		t.Fatalf("another user must not delete the device, got %v", err)
	}
	if err := service.DeleteDevice(owner, device.ID); err != nil {
		t.Fatal(err)
	}
}

func TestFirebaseDeviceRegistrationUpsertsAndMovesRefreshedToken(t *testing.T) {
	service := firebaseTestService(t)
	firstOwner := uuid.New()
	secondOwner := uuid.New()

	first, err := service.RegisterDevice(firstOwner, FirebaseDeviceInput{
		InstallationID:    "first-installation",
		RegistrationToken: "refreshed-token",
		Platform:          "android",
	})
	if err != nil {
		t.Fatal(err)
	}
	if _, err := service.RegisterDevice(firstOwner, FirebaseDeviceInput{
		InstallationID:    "first-installation",
		RegistrationToken: "replacement-token",
		Platform:          "android",
	}); err != nil {
		t.Fatal(err)
	}
	if _, err := service.RegisterDevice(secondOwner, FirebaseDeviceInput{
		InstallationID:    "second-installation",
		RegistrationToken: "refreshed-token",
		Platform:          "ios",
	}); err != nil {
		t.Fatal(err)
	}

	var count int64
	if err := service.DB.Model(&models.FirebaseDevice{}).Where("user_id = ?", firstOwner).Count(&count).Error; err != nil {
		t.Fatal(err)
	}
	if count != 1 {
		t.Fatalf("expected one active installation for first owner, got %d", count)
	}
	var updated models.FirebaseDevice
	if err := service.DB.First(&updated, "id = ?", first.ID).Error; err != nil {
		t.Fatal(err)
	}
	if updated.RegistrationToken != "replacement-token" {
		t.Fatalf("expected refreshed token, got %q", updated.RegistrationToken)
	}
	var moved models.FirebaseDevice
	if err := service.DB.Where("registration_token = ?", "refreshed-token").First(&moved).Error; err != nil {
		t.Fatal(err)
	}
	if moved.UserID != secondOwner {
		t.Fatal("refreshed token must belong only to its latest authenticated owner")
	}
}

func TestFirebaseDeviceRegistrationRejectsInvalidInput(t *testing.T) {
	service := firebaseTestService(t)
	cases := []FirebaseDeviceInput{
		{RegistrationToken: "token", Platform: "android"},
		{InstallationID: "installation", Platform: "android"},
		{InstallationID: "installation", RegistrationToken: "token", Platform: "web"},
	}
	for _, input := range cases {
		if _, err := service.RegisterDevice(uuid.New(), input); err != ErrFirebaseInvalid {
			t.Fatalf("expected ErrFirebaseInvalid for %#v, got %v", input, err)
		}
	}
}

func TestFirebaseRemoteOperationsFailWhenDisabled(t *testing.T) {
	service := firebaseTestService(t)
	if _, _, err := service.GetRemoteConfig(t.Context()); err != ErrFirebaseDisabled {
		t.Fatalf("expected disabled Remote Config error, got %v", err)
	}
	if _, err := service.SendToUser(t.Context(), FirebasePushInput{}); err != ErrFirebaseDisabled {
		t.Fatalf("expected disabled push error, got %v", err)
	}
}
