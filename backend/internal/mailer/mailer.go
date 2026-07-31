package mailer

import (
	"context"
	"errors"
	"fmt"
	"log"
	"net/smtp"
	"strings"

	"mediguide/internal/config"
)

var ErrDisabled = errors.New("email delivery is disabled")

type Message struct {
	To      string
	Subject string
	Text    string
}

type Sender interface {
	Send(context.Context, Message) error
}

func New(cfg config.Config) (Sender, error) {
	switch strings.ToLower(strings.TrimSpace(cfg.MailDriver)) {
	case "", "disabled":
		return DisabledSender{}, nil
	case "development":
		return DevelopmentSender{}, nil
	case "smtp":
		if cfg.SMTPHost == "" || cfg.SMTPPort == 0 || cfg.MailFrom == "" {
			return nil, errors.New("MAIL_DRIVER=smtp requires SMTP_HOST, SMTP_PORT, and MAIL_FROM")
		}
		return SMTPSender{
			Address:  fmt.Sprintf("%s:%d", cfg.SMTPHost, cfg.SMTPPort),
			Host:     cfg.SMTPHost,
			Username: cfg.SMTPUsername,
			Password: cfg.SMTPPassword,
			From:     cfg.MailFrom,
		}, nil
	default:
		return nil, fmt.Errorf("unsupported MAIL_DRIVER %q", cfg.MailDriver)
	}
}

type DisabledSender struct{}

func (DisabledSender) Send(context.Context, Message) error { return ErrDisabled }

// DevelopmentSender accepts messages locally and writes their content to the
// development log. It must never be enabled in production.
type DevelopmentSender struct{}

func (DevelopmentSender) Send(_ context.Context, message Message) error {
	log.Printf("development email accepted to=%q subject=%q body=%q", message.To, message.Subject, message.Text)
	return nil
}

type SMTPSender struct {
	Address  string
	Host     string
	Username string
	Password string
	From     string
}

func (sender SMTPSender) Send(_ context.Context, message Message) error {
	var auth smtp.Auth
	if sender.Username != "" {
		auth = smtp.PlainAuth("", sender.Username, sender.Password, sender.Host)
	}
	payload := []byte("From: " + sender.From + "\r\n" +
		"To: " + message.To + "\r\n" +
		"Subject: " + message.Subject + "\r\n" +
		"MIME-Version: 1.0\r\n" +
		"Content-Type: text/plain; charset=UTF-8\r\n\r\n" + message.Text)
	return smtp.SendMail(sender.Address, auth, sender.From, []string{message.To}, payload)
}
