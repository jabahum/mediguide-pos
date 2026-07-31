package mailer

import (
	"context"
	"errors"
	"testing"

	"mediguide/internal/config"
)

func TestNewSelectsExplicitMailDriver(t *testing.T) {
	disabled, err := New(config.Config{MailDriver: "disabled"})
	if err != nil {
		t.Fatal(err)
	}
	if !errors.Is(disabled.Send(context.Background(), Message{}), ErrDisabled) {
		t.Fatal("disabled mailer must reject delivery honestly")
	}

	development, err := New(config.Config{MailDriver: "development"})
	if err != nil {
		t.Fatal(err)
	}
	if err := development.Send(context.Background(), Message{To: "user@example.test", Subject: "subject", Text: "body"}); err != nil {
		t.Fatal(err)
	}
}

func TestSMTPConfigurationIsValidated(t *testing.T) {
	if _, err := New(config.Config{MailDriver: "smtp"}); err == nil {
		t.Fatal("expected incomplete SMTP configuration to fail")
	}
	if _, err := New(config.Config{MailDriver: "unknown"}); err == nil {
		t.Fatal("expected unknown mail driver to fail")
	}
}
