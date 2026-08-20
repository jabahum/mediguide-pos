package services

import (
	"encoding/json"
	"testing"
	"time"

	"mediguide/internal/models"

	"github.com/google/uuid"
)

func TestNotificationAudienceUsesTypedFiltersPreferencesAndActiveDevices(t *testing.T) {
	service := notificationTestService(t)
	region := models.Region{Name: "Central"}
	district := models.District{Name: "Kampala"}
	level := models.FacilityLevel{Name: "Hospital", Code: "HOSP"}
	if err := service.DB.Create(&region).Error; err != nil {
		t.Fatal(err)
	}
	district.RegionID = region.ID
	if err := service.DB.Create(&district).Error; err != nil {
		t.Fatal(err)
	}
	if err := service.DB.Create(&level).Error; err != nil {
		t.Fatal(err)
	}
	facility := models.HealthFacility{Name: "National Hospital", RegionID: region.ID, DistrictID: district.ID, FacilityLevelID: level.ID}
	if err := service.DB.Create(&facility).Error; err != nil {
		t.Fatal(err)
	}
	role := models.Role{Name: "Clinician", IsActive: true}
	if err := service.DB.Create(&role).Error; err != nil {
		t.Fatal(err)
	}
	country, language, job, facilityID := "Uganda", "en", "Nurse", facility.ID.String()
	user := models.User{Name: "Audience member", Email: uuid.NewString() + "@example.test", PasswordHash: "hash", IsActive: true, Status: "active", Country: &country, PreferredLanguage: &language, JobTitle: &job, FacilityID: &facilityID}
	if err := service.DB.Create(&user).Error; err != nil {
		t.Fatal(err)
	}
	if err := service.DB.Exec("INSERT INTO user_roles (user_id, role_id) VALUES (?, ?)", user.ID, role.ID).Error; err != nil {
		t.Fatal(err)
	}
	device := models.FirebaseDevice{UserID: user.ID, InstallationID: uuid.NewString(), RegistrationToken: uuid.NewString(), Platform: "ios", AppVersion: notificationString("2.0.24"), NotificationsEnabled: true, LastSeenAt: time.Now().UTC()}
	if err := service.DB.Create(&device).Error; err != nil {
		t.Fatal(err)
	}
	audience := NotificationAudienceDefinition{RoleIDs: []string{role.ID.String()}, Countries: []string{"UGANDA"}, RegionIDs: []string{region.ID.String()}, DistrictIDs: []string{district.ID.String()}, FacilityIDs: []string{facility.ID.String()}, FacilityLevelIDs: []string{level.ID.String()}, ProfessionalCategories: []string{"nurse"}, Languages: []string{"EN"}, Platforms: []string{"ios"}, ApplicationVersions: []string{"2.0.24"}, PreferenceCategories: []string{"clinical_content_updates"}}
	estimate, err := service.EstimateAudience(audience)
	if err != nil {
		t.Fatal(err)
	}
	if estimate.EligibleUsers != 1 || estimate.ActiveDevices != 1 {
		t.Fatalf("unexpected filtered estimate: %#v", estimate)
	}
	preference := models.NotificationPreference{UserID: user.ID, Category: "clinical_content_updates", Enabled: false}
	if err := service.DB.Create(&preference).Error; err != nil {
		t.Fatal(err)
	}
	if err := service.DB.Model(&preference).Update("enabled", false).Error; err != nil {
		t.Fatal(err)
	}
	estimate, err = service.EstimateAudience(audience)
	if err != nil {
		t.Fatal(err)
	}
	if estimate.EligibleUsers != 0 || estimate.ActiveDevices != 0 {
		t.Fatalf("opted-out user must be excluded: %#v", estimate)
	}
}

func TestNotificationAudienceRejectsAmbiguousAndUnsafeDefinitions(t *testing.T) {
	service := notificationTestService(t)
	cases := []NotificationAudienceDefinition{
		{},
		{AllEligible: true, Countries: []string{"Uganda"}},
		{Platforms: []string{"web"}},
		{UserIDs: []string{"not-a-uuid"}},
		{PreferenceCategories: []string{"unknown"}},
	}
	for _, audience := range cases {
		if _, err := service.EstimateAudience(audience); err != ErrNotificationInvalid {
			t.Fatalf("expected invalid audience for %#v, got %v", audience, err)
		}
	}
}

func TestNotificationAudienceDeviceFiltersApplyToTheSameActiveDeliveryDevice(t *testing.T) {
	service := notificationTestService(t)
	user := models.User{Name: "Multi-device user", Email: uuid.NewString() + "@example.test", PasswordHash: "hash", IsActive: true, Status: "active"}
	if err := service.DB.Create(&user).Error; err != nil {
		t.Fatal(err)
	}
	devices := []models.FirebaseDevice{
		{UserID: user.ID, InstallationID: uuid.NewString(), RegistrationToken: uuid.NewString(), Platform: "android", AppVersion: notificationString("1.0.0"), NotificationsEnabled: true, LastSeenAt: time.Now().UTC()},
		{UserID: user.ID, InstallationID: uuid.NewString(), RegistrationToken: uuid.NewString(), Platform: "ios", AppVersion: notificationString("2.0.0"), NotificationsEnabled: true, LastSeenAt: time.Now().UTC()},
		{UserID: user.ID, InstallationID: uuid.NewString(), RegistrationToken: uuid.NewString(), Platform: "android", AppVersion: notificationString("2.0.0"), NotificationsEnabled: true, LastSeenAt: time.Now().UTC().Add(-100 * 24 * time.Hour)},
	}
	if err := service.DB.Create(&devices).Error; err != nil {
		t.Fatal(err)
	}

	estimate, err := service.EstimateAudience(NotificationAudienceDefinition{Platforms: []string{"android"}, ApplicationVersions: []string{"2.0.0"}})
	if err != nil {
		t.Fatal(err)
	}
	if estimate.EligibleUsers != 0 || estimate.ActiveDevices != 0 {
		t.Fatalf("filters must match the same non-stale device: %#v", estimate)
	}

	estimate, err = service.EstimateAudience(NotificationAudienceDefinition{Platforms: []string{"ios"}, ApplicationVersions: []string{"2.0.0"}})
	if err != nil {
		t.Fatal(err)
	}
	if estimate.EligibleUsers != 1 || estimate.ActiveDevices != 1 {
		t.Fatalf("only the matching delivery device should be counted: %#v", estimate)
	}
}

func TestNotificationCampaignOutboxIsTransactionalRetryableAndIdempotent(t *testing.T) {
	service := notificationTestService(t)
	author, reviewer := uuid.New(), uuid.New()
	template := createPublishedNotificationTemplate(t, service, author, reviewer)
	expires := time.Now().UTC().Add(24 * time.Hour)
	campaign, err := service.SaveCampaign(nil, NotificationCampaignInput{Name: "Outbox campaign", Type: "update", TemplateVersionID: template.Version.ID, Variables: map[string]any{"topic": "Malaria"}, Audience: NotificationAudienceDefinition{AllEligible: true}, Timezone: "UTC", ExpiresAt: &expires, Priority: "normal", RequestedChannels: []string{"in-app", "push"}, IdempotencyKey: "outbox-campaign"}, author, "127.0.0.1")
	if err != nil {
		t.Fatal(err)
	}
	campaign, err = service.TransitionCampaign(campaign.ID, "submit", NotificationCampaignTransitionInput{LockVersion: campaign.LockVersion}, author, "127.0.0.1")
	if err != nil {
		t.Fatal(err)
	}
	campaign, err = service.TransitionCampaign(campaign.ID, "approve", NotificationCampaignTransitionInput{LockVersion: campaign.LockVersion}, reviewer, "127.0.0.1")
	if err != nil {
		t.Fatal(err)
	}
	snapshotCampaign, _ := campaign.DispatchSnapshot["campaign"].(map[string]any)
	if campaign.ResolvedRecipientCount != 1 || snapshotCampaign["status"] != "approved" {
		t.Fatalf("approval must freeze the resolved approved snapshot: %#v", campaign)
	}
	var recipientCount, jobCount, notificationCount int64
	service.DB.Model(&models.NotificationCampaignRecipient{}).Where("campaign_id = ?", campaign.ID).Count(&recipientCount)
	service.DB.Model(&models.NotificationOutboxJob{}).Where("campaign_id = ?", campaign.ID).Count(&jobCount)
	service.DB.Model(&models.Notification{}).Where("campaign_id = ?", campaign.ID).Count(&notificationCount)
	if recipientCount != 1 || jobCount != 2 || notificationCount != 1 {
		t.Fatalf("approval transaction incomplete: recipients=%d jobs=%d notifications=%d", recipientCount, jobCount, notificationCount)
	}
	campaign, err = service.TransitionCampaign(campaign.ID, "schedule", NotificationCampaignTransitionInput{LockVersion: campaign.LockVersion}, author, "127.0.0.1")
	if err != nil {
		t.Fatal(err)
	}
	messenger := &firebaseMockMessenger{results: []firebaseMockResult{{err: mockFirebaseError("invalid_argument")}}}
	firebase := &FirebaseService{DB: service.DB, Project: "test-project", Messenger: messenger}
	worker := NotificationOutboxService{DB: service.DB, Firebase: firebase, WorkerID: "test-worker", MaxConcurrency: 1, Now: func() time.Time { return time.Now().UTC().Add(time.Minute) }}
	result, err := worker.ProcessBatch(t.Context())
	if err != nil {
		t.Fatal(err)
	}
	if result.Accepted != 1 || result.Failed != 1 {
		t.Fatalf("unexpected first delivery result: %#v", result)
	}
	var push models.NotificationOutboxJob
	if err := service.DB.First(&push, "campaign_id = ? AND channel = 'push'", campaign.ID).Error; err != nil {
		t.Fatal(err)
	}
	if push.Status != "failed" {
		t.Fatalf("permanent provider rejection must fail: %#v", push)
	}
	requeued, err := worker.Requeue(push.ID, reviewer, NotificationOutboxRequeueInput{Confirm: true, Reason: "Provider configuration repaired"}, "127.0.0.1")
	if err != nil || requeued.Status != "pending" {
		t.Fatalf("failed job should requeue with confirmation: %#v %v", requeued, err)
	}
	messenger.results = []firebaseMockResult{{id: "messages/retried"}}
	result, err = worker.ProcessBatch(t.Context())
	if err != nil || result.Accepted != 1 {
		t.Fatalf("requeued job should be accepted: %#v %v", result, err)
	}
	var final models.NotificationCampaign
	if err := service.DB.First(&final, "id = ?", campaign.ID).Error; err != nil {
		t.Fatal(err)
	}
	if final.Status != "completed" {
		t.Fatalf("campaign should recover to completed, got %s", final.Status)
	}
	var attempts int64
	service.DB.Model(&models.NotificationDeliveryAttempt{}).Where("outbox_job_id = ?", push.ID).Count(&attempts)
	if attempts != 2 {
		t.Fatalf("each attempt must be inspectable, got %d", attempts)
	}
	var jobs []models.NotificationOutboxJob
	if err := service.DB.Where("campaign_id = ?", campaign.ID).Find(&jobs).Error; err != nil {
		t.Fatal(err)
	}
	keys := map[string]bool{}
	for _, job := range jobs {
		if keys[job.IdempotencyKey] {
			t.Fatalf("duplicate idempotency key %q", job.IdempotencyKey)
		}
		keys[job.IdempotencyKey] = true
		var payload NotificationDeliveryPayload
		if err := json.Unmarshal(job.PayloadJSON, &payload); err != nil {
			t.Fatal(err)
		}
	}
}

func notificationString(value string) *string { return &value }
