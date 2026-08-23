package clinicaltools

import (
	"errors"
	"net"
	"net/url"
	"strings"
)

const RehearsalProjectPrefix = "mediguide-clinical-tools-rehearsal-"

// ValidateDevelopmentActivationTarget protects the persistent synthetic
// activation workflow. Unlike a rehearsal, this workflow intentionally changes
// the normal local database, so it requires a separate, explicit opt-in marker.
func ValidateDevelopmentActivationTarget(databaseURL, appEnvironment, marker string) error {
	if marker != "1" {
		return errors.New("CLINICAL_TOOLS_DEVELOPMENT_ACTIVATION=1 is required")
	}
	if strings.ToLower(strings.TrimSpace(appEnvironment)) != "development" {
		return errors.New("APP_ENV must be development for synthetic clinical-tool activation")
	}
	parsed, err := url.Parse(strings.TrimSpace(databaseURL))
	if err != nil || (parsed.Scheme != "postgres" && parsed.Scheme != "postgresql") {
		return errors.New("development activation requires a PostgreSQL URL")
	}
	host := strings.ToLower(parsed.Hostname())
	if host != "postgres" && host != "localhost" && !isLoopback(host) {
		return errors.New("development activation database host must be the local Compose service or loopback")
	}
	databaseName := strings.ToLower(strings.TrimPrefix(parsed.EscapedPath(), "/"))
	if databaseName == "" || strings.Contains(databaseName, "prod") || strings.Contains(databaseName, "stag") {
		return errors.New("development activation database name is missing or resembles a staging/production database")
	}
	return nil
}

// ValidateRehearsalTarget makes the destructive synthetic workflow opt-in and
// confines it to a purpose-named local/container PostgreSQL database.
func ValidateRehearsalTarget(databaseURL, appEnvironment, composeProject, marker string) error {
	if marker != "1" {
		return errors.New("CLINICAL_TOOLS_REHEARSAL=1 is required")
	}
	if strings.ToLower(strings.TrimSpace(appEnvironment)) != "test" {
		return errors.New("APP_ENV must be test for a clinical-tool rehearsal")
	}
	if !strings.HasPrefix(composeProject, RehearsalProjectPrefix) || len(composeProject) <= len(RehearsalProjectPrefix) {
		return errors.New("Compose project name is not disposable")
	}
	parsed, err := url.Parse(strings.TrimSpace(databaseURL))
	if err != nil || (parsed.Scheme != "postgres" && parsed.Scheme != "postgresql") {
		return errors.New("rehearsal requires a PostgreSQL URL")
	}
	host := strings.ToLower(parsed.Hostname())
	if host != "postgres" && host != "localhost" && !isLoopback(host) {
		return errors.New("rehearsal database host must be the isolated Compose service or loopback")
	}
	databaseName := strings.TrimPrefix(parsed.EscapedPath(), "/")
	if !strings.Contains(strings.ToLower(databaseName), "rehearsal") {
		return errors.New("rehearsal database name must contain rehearsal")
	}
	return nil
}

func isLoopback(host string) bool {
	ip := net.ParseIP(host)
	return ip != nil && ip.IsLoopback()
}
