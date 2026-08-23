package clinicaltools

import "testing"

func TestValidateRehearsalTargetAcceptsIsolatedTestDatabase(t *testing.T) {
	err := ValidateRehearsalTarget(
		"postgres://mediguide:secret@postgres:5432/mediguide_rehearsal?sslmode=disable",
		"test",
		RehearsalProjectPrefix+"test-123",
		"1",
	)
	if err != nil {
		t.Fatal(err)
	}
}

func TestValidateRehearsalTargetRejectsUnsafeTargets(t *testing.T) {
	cases := map[string]struct {
		url, environment, project, marker string
	}{
		"production environment": {"postgres://mediguide:x@postgres/db_rehearsal", "production", RehearsalProjectPrefix + "x", "1"},
		"staging environment":    {"postgres://mediguide:x@postgres/db_rehearsal", "staging", RehearsalProjectPrefix + "x", "1"},
		"shared database":        {"postgres://mediguide:x@postgres/mediguide", "test", RehearsalProjectPrefix + "x", "1"},
		"remote host":            {"postgres://mediguide:x@db.example.org/db_rehearsal", "test", RehearsalProjectPrefix + "x", "1"},
		"shared project":         {"postgres://mediguide:x@postgres/db_rehearsal", "test", "mediguide", "1"},
		"missing opt in":         {"postgres://mediguide:x@postgres/db_rehearsal", "test", RehearsalProjectPrefix + "x", ""},
	}
	for name, testCase := range cases {
		t.Run(name, func(t *testing.T) {
			if err := ValidateRehearsalTarget(testCase.url, testCase.environment, testCase.project, testCase.marker); err == nil {
				t.Fatal("unsafe rehearsal target was accepted")
			}
		})
	}
}

func TestValidateDevelopmentActivationTarget(t *testing.T) {
	valid := "postgres://mediguide:secret@postgres:5432/mediguide?sslmode=disable"
	if err := ValidateDevelopmentActivationTarget(valid, "development", "1"); err != nil {
		t.Fatalf("expected local development target to pass: %v", err)
	}
	for name, values := range map[string][3]string{
		"requires opt in":       {valid, "development", ""},
		"rejects test":          {valid, "test", "1"},
		"rejects staging":       {valid, "staging", "1"},
		"rejects production":    {valid, "production", "1"},
		"rejects remote host":   {"postgres://user:secret@database.example.com:5432/mediguide", "development", "1"},
		"rejects staging db":    {"postgres://user:secret@localhost:5432/mediguide_staging", "development", "1"},
		"rejects production db": {"postgres://user:secret@localhost:5432/mediguide_production", "development", "1"},
	} {
		t.Run(name, func(t *testing.T) {
			if err := ValidateDevelopmentActivationTarget(values[0], values[1], values[2]); err == nil {
				t.Fatal("expected unsafe development activation target to be rejected")
			}
		})
	}
}
