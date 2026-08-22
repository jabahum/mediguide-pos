package config

import (
	"os"
	"strconv"
	"strings"

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
	AllowedOrigins                  string
	PublicAppURL                    string
	MailDriver                      string
	MailFrom                        string
	SMTPHost                        string
	SMTPPort                        int
	SMTPUsername                    string
	SMTPPassword                    string
	RedisURL                        string
	RedisKeyPrefix                  string
	RedisConnectTimeout             int
	RedisReadTimeout                int
	RedisWriteTimeout               int
	RateLimitEnabled                bool
	CacheEnabled                    bool
	CacheDefaultTTL                 int
	CacheMaxItemBytes               int
	TrustedProxies                  []string
	FirebaseProjectID               string
	FirebaseCredentials             string
	FirebaseDeviceStaleDays         int
	NotificationWorkerPort          string
	NotificationWorkerBatchSize     int
	NotificationWorkerConcurrency   int
	NotificationWorkerPollMS        int
	NotificationWorkerMaxAgeHours   int
	NotificationWorkerLeaseSeconds  int
	NotificationActionExternalHosts []string
}

func Load() Config {
	_ = godotenv.Load()
	return Config{
		AppName:                         get("APP_NAME", "mediguide-api"),
		AppEnv:                          get("APP_ENV", "development"),
		Port:                            getAny([]string{"PORT", "HTTP_PORT"}, "8080"),
		StaticSamplesDir:                get("STATIC_SAMPLES_DIR", "../dashboard/samples"),
		DatabaseURL:                     get("DATABASE_URL", "postgres://mediguide:mediguide@localhost:5432/mediguide?sslmode=disable"),
		JWTSecret:                       get("JWT_SECRET", "change-this-secret-ernrjtjtpckrmcjwieutalldjjr8373n1y1y2n2y3y4bdnzmzmz2u"),
		JWTIssuer:                       get("JWT_ISSUER", "mediguide"),
		JWTTTLMinutes:                   getIntAny([]string{"JWT_TTL_MINUTES", "JWT_ACCESS_TTL_MINUTES"}, 1440),
		JWTRefreshTTLMinutes:            getInt("JWT_REFRESH_TTL_MINUTES", 43200),
		StorageDriver:                   get("STORAGE_DRIVER", "minio"),
		S3Endpoint:                      get("S3_ENDPOINT", "localhost:9000"),
		S3AccessKey:                     get("S3_ACCESS_KEY", "mediguide"),
		S3SecretKey:                     get("S3_SECRET_KEY", "mediguide123"),
		S3Bucket:                        get("S3_BUCKET", "mediguide"),
		S3UseSSL:                        getBool("S3_USE_SSL", false),
		S3PresignMinutes:                getInt("S3_PRESIGN_MINUTES", 60),
		MaxUploadMB:                     int64(getInt("MAX_UPLOAD_MB", 100)),
		AIRAGProvider:                   get("AI_RAG_PROVIDER", "local"),
		AIWorkerWebhook:                 getAny([]string{"AI_WORKER_WEBHOOK_URL", "AI_WORKER_URL"}, ""),
		AIWorkerGRPCAddr:                get("AI_WORKER_GRPC_ADDR", ""),
		AIWorkerTimeoutSecs:             getInt("AI_WORKER_TIMEOUT_SECONDS", 120),
		AIWorkerSecret:                  get("AI_WORKER_SECRET", ""),
		AllowedOrigins:                  get("ALLOWED_ORIGINS", "http://localhost:3000,*"), // Adjust for production domains
		PublicAppURL:                    get("PUBLIC_APP_URL", "http://localhost:3000"),
		MailDriver:                      get("MAIL_DRIVER", "disabled"),
		MailFrom:                        get("MAIL_FROM", ""),
		SMTPHost:                        get("SMTP_HOST", ""),
		SMTPPort:                        getInt("SMTP_PORT", 587),
		SMTPUsername:                    get("SMTP_USERNAME", ""),
		SMTPPassword:                    get("SMTP_PASSWORD", ""),
		RedisURL:                        get("REDIS_URL", "redis://localhost:6379"),
		RedisKeyPrefix:                  get("REDIS_KEY_PREFIX", "mediguide:"+get("APP_ENV", "development")),
		RedisConnectTimeout:             getInt("REDIS_CONNECT_TIMEOUT_MS", 2000),
		RedisReadTimeout:                getInt("REDIS_READ_TIMEOUT_MS", 1000),
		RedisWriteTimeout:               getInt("REDIS_WRITE_TIMEOUT_MS", 1000),
		RateLimitEnabled:                getBool("RATE_LIMIT_ENABLED", true),
		CacheEnabled:                    getBool("CACHE_ENABLED", true),
		CacheDefaultTTL:                 getInt("CACHE_DEFAULT_TTL_SECONDS", 300),
		CacheMaxItemBytes:               getInt("CACHE_MAX_ITEM_BYTES", 1_048_576),
		TrustedProxies:                  getCSV("TRUSTED_PROXIES"),
		FirebaseProjectID:               get("FIREBASE_PROJECT_ID", ""),
		FirebaseCredentials:             get("FIREBASE_SERVICE_ACCOUNT_BASE64", ""),
		FirebaseDeviceStaleDays:         getInt("FIREBASE_DEVICE_STALE_DAYS", 90),
		NotificationWorkerPort:          get("NOTIFICATION_WORKER_PORT", "8082"),
		NotificationWorkerBatchSize:     getInt("NOTIFICATION_WORKER_BATCH_SIZE", 100),
		NotificationWorkerConcurrency:   getInt("NOTIFICATION_WORKER_CONCURRENCY", 10),
		NotificationWorkerPollMS:        getInt("NOTIFICATION_WORKER_POLL_MS", 1000),
		NotificationWorkerMaxAgeHours:   getInt("NOTIFICATION_WORKER_MAX_AGE_HOURS", 168),
		NotificationWorkerLeaseSeconds:  getInt("NOTIFICATION_WORKER_LEASE_SECONDS", 120),
		NotificationActionExternalHosts: getCSVWithFallback("NOTIFICATION_ACTION_EXTERNAL_HOSTS", "mediguide.health.go.ug,health.go.ug,www.health.go.ug,who.int,www.who.int,afro.who.int,www.afro.who.int,iris.who.int"),
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

func getCSV(key string) []string {
	values := []string{}
	for _, value := range strings.Split(get(key, ""), ",") {
		if trimmed := strings.TrimSpace(value); trimmed != "" {
			values = append(values, trimmed)
		}
	}
	return values
}

func getCSVWithFallback(key, fallback string) []string {
	value := get(key, fallback)
	values := []string{}
	for _, item := range strings.Split(value, ",") {
		if trimmed := strings.TrimSpace(item); trimmed != "" {
			values = append(values, trimmed)
		}
	}
	return values
}
