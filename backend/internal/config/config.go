package config

import (
	"os"
	"strconv"

	"github.com/joho/godotenv"
)

type Config struct {
	AppName              string
	AppEnv               string
	Port                 string
	StaticSamplesDir     string
	DatabaseURL          string
	JWTSecret            string
	JWTIssuer            string
	JWTTTLMinutes        int
	JWTRefreshTTLMinutes int
	StorageDriver        string
	S3Endpoint           string
	S3AccessKey          string
	S3SecretKey          string
	S3Bucket             string
	S3UseSSL             bool
	S3PresignMinutes     int
	MaxUploadMB          int64
	AIRAGProvider        string
	AIWorkerWebhook      string
	AIWorkerGRPCAddr     string
	AIWorkerTimeoutSecs  int
	// Shared secret sent as X-Worker-Secret to the ai-worker API.
	AIWorkerSecret string
	// Comma-separated list of allowed CORS origins (use "*" for local dev only).
	AllowedOrigins string
	PublicAppURL   string
	MailDriver     string
	MailFrom       string
	SMTPHost       string
	SMTPPort       int
	SMTPUsername   string
	SMTPPassword   string
}

func Load() Config {
	_ = godotenv.Load()
	return Config{
		AppName:              get("APP_NAME", "mediguide-api"),
		AppEnv:               get("APP_ENV", "development"),
		Port:                 getAny([]string{"PORT", "HTTP_PORT"}, "8080"),
		StaticSamplesDir:     get("STATIC_SAMPLES_DIR", "../dashboard/samples"),
		DatabaseURL:          get("DATABASE_URL", "postgres://mediguide:mediguide@localhost:5432/mediguide?sslmode=disable"),
		JWTSecret:            get("JWT_SECRET", "change-this-secret-ernrjtjtpckrmcjwieutalldjjr8373n1y1y2n2y3y4bdnzmzmz2u"),
		JWTIssuer:            get("JWT_ISSUER", "mediguide"),
		JWTTTLMinutes:        getIntAny([]string{"JWT_TTL_MINUTES", "JWT_ACCESS_TTL_MINUTES"}, 1440),
		JWTRefreshTTLMinutes: getInt("JWT_REFRESH_TTL_MINUTES", 43200),
		StorageDriver:        get("STORAGE_DRIVER", "minio"),
		S3Endpoint:           get("S3_ENDPOINT", "localhost:9000"),
		S3AccessKey:          get("S3_ACCESS_KEY", "mediguide"),
		S3SecretKey:          get("S3_SECRET_KEY", "mediguide123"),
		S3Bucket:             get("S3_BUCKET", "mediguide"),
		S3UseSSL:             getBool("S3_USE_SSL", false),
		S3PresignMinutes:     getInt("S3_PRESIGN_MINUTES", 60),
		MaxUploadMB:          int64(getInt("MAX_UPLOAD_MB", 100)),
		AIRAGProvider:        get("AI_RAG_PROVIDER", "local"),
		AIWorkerWebhook:      getAny([]string{"AI_WORKER_WEBHOOK_URL", "AI_WORKER_URL"}, ""),
		AIWorkerGRPCAddr:     get("AI_WORKER_GRPC_ADDR", ""),
		AIWorkerTimeoutSecs:  getInt("AI_WORKER_TIMEOUT_SECONDS", 120),
		AIWorkerSecret:       get("AI_WORKER_SECRET", ""),
		AllowedOrigins:       get("ALLOWED_ORIGINS", "http://localhost:3000,*"), // Adjust for production domains
		PublicAppURL:         get("PUBLIC_APP_URL", "http://localhost:3000"),
		MailDriver:           get("MAIL_DRIVER", "disabled"),
		MailFrom:             get("MAIL_FROM", ""),
		SMTPHost:             get("SMTP_HOST", ""),
		SMTPPort:             getInt("SMTP_PORT", 587),
		SMTPUsername:         get("SMTP_USERNAME", ""),
		SMTPPassword:         get("SMTP_PASSWORD", ""),
	}
}

func get(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
func getAny(keys []string, fallback string) string {
	for _, key := range keys {
		if v := os.Getenv(key); v != "" {
			return v
		}
	}
	return fallback
}
func getInt(key string, fallback int) int {
	v, err := strconv.Atoi(get(key, ""))
	if err != nil {
		return fallback
	}
	return v
}
func getIntAny(keys []string, fallback int) int {
	v, err := strconv.Atoi(getAny(keys, ""))
	if err != nil {
		return fallback
	}
	return v
}
func getBool(key string, fallback bool) bool {
	v, err := strconv.ParseBool(get(key, ""))
	if err != nil {
		return fallback
	}
	return v
}
