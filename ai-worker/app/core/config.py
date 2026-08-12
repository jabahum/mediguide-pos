from functools import lru_cache
from pydantic import AliasChoices, Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    app_name: str = Field(default="mediguide-ai-worker", validation_alias=AliasChoices("APP_NAME"))
    env: str = Field(default="development", validation_alias=AliasChoices("APP_ENV", "ENV"))
    log_level: str = "INFO"
    api_host: str = "0.0.0.0"
    api_port: int = Field(default=8090, validation_alias=AliasChoices("API_PORT", "HTTP_PORT"))
    grpc_host: str = Field(default="0.0.0.0", validation_alias=AliasChoices("GRPC_HOST"))
    grpc_port: int = Field(
        default=50051, validation_alias=AliasChoices("GRPC_PORT", "WORKER_GRPC_PORT")
    )

    # Comma-separated list of allowed CORS origins. Use "*" only for local dev.
    allowed_origins: str = Field(
        default="http://localhost:3000",
        validation_alias=AliasChoices("ALLOWED_ORIGINS", "CORS_ORIGINS"),
    )

    # Shared secret for internal worker API endpoints (set the same value in backend AI_WORKER_SECRET).
    worker_api_secret: str = Field(
        default="",
        validation_alias=AliasChoices("WORKER_API_SECRET"),
    )

    database_url: str = Field(
        default="postgresql://mediguide:mediguide@localhost:5432/mediguide",
        validation_alias=AliasChoices("DATABASE_URL"),
    )
    # PostgreSQL statement timeout in milliseconds (0 = disabled).
    db_statement_timeout_ms: int = Field(
        default=30000,
        validation_alias=AliasChoices("DB_STATEMENT_TIMEOUT_MS"),
    )
    redis_url: str = Field(
        default="redis://localhost:6379", validation_alias=AliasChoices("REDIS_URL")
    )

    minio_endpoint: str = Field(
        default="localhost:9000",
        validation_alias=AliasChoices("MINIO_ENDPOINT", "S3_ENDPOINT"),
    )
    minio_access_key: str = Field(
        default="mediguide",
        validation_alias=AliasChoices("MINIO_ACCESS_KEY", "S3_ACCESS_KEY"),
    )
    minio_secret_key: str = Field(
        default="mediguide123",
        validation_alias=AliasChoices("MINIO_SECRET_KEY", "S3_SECRET_KEY"),
    )
    minio_bucket: str = Field(
        default="mediguide",
        validation_alias=AliasChoices("MINIO_BUCKET", "S3_BUCKET"),
    )
    minio_secure: bool = Field(
        default=False,
        validation_alias=AliasChoices("MINIO_SECURE", "S3_USE_SSL"),
    )

    worker_enabled: bool = True
    worker_poll_interval_seconds: int = 5
    worker_batch_size: int = 2
    # Maximum ingestion attempts before a job is permanently marked failed.
    worker_max_attempts: int = Field(
        default=3, validation_alias=AliasChoices("WORKER_MAX_ATTEMPTS")
    )
    # Back-off multiplier (seconds) between attempts: attempt * worker_retry_backoff_seconds.
    worker_retry_backoff_seconds: int = Field(
        default=30, validation_alias=AliasChoices("WORKER_RETRY_BACKOFF_SECONDS")
    )

    # Maximum PDF upload size in bytes for the preview endpoint (default 50 MB).
    max_upload_bytes: int = Field(
        default=50 * 1024 * 1024,
        validation_alias=AliasChoices("MAX_UPLOAD_BYTES", "MAX_UPLOAD_MB"),
    )

    # These chunk values are in words, not characters. Keep them conservative
    # so local Ollama embedding endpoints do not receive oversized prompts.
    chunk_size: int = Field(default=320, validation_alias=AliasChoices("CHUNK_SIZE"))
    chunk_overlap: int = Field(default=60, validation_alias=AliasChoices("CHUNK_OVERLAP"))
    min_chunk_chars: int = Field(default=120, validation_alias=AliasChoices("MIN_CHUNK_CHARS"))
    embedding_request_batch_size: int = Field(
        default=8,
        validation_alias=AliasChoices("EMBEDDING_REQUEST_BATCH_SIZE"),
    )

    embedding_provider: str = "ollama"  # hash, sentence_transformers, openai, ollama
    embedding_model: str = "sentence-transformers/paraphrase-multilingual-mpnet-base-v2"
    embedding_dim: int = 1024
    openai_api_key: str | None = None
    openai_embedding_model: str = Field(
        default="text-embedding-3-small",
        validation_alias=AliasChoices("OPENAI_EMBEDDING_MODEL"),
    )

    llm_provider: str = "ollama"  # extractive, ollama, openai
    openai_chat_model: str = "gpt-4o-mini"
    ollama_base_url: str = "http://localhost:11434"
    ollama_model: str = "qwen2.5:7b-instruct"
    ollama_embedding_model: str = Field(
        default="mxbai-embed-large:latest",
        validation_alias=AliasChoices("OLLAMA_EMBEDDING_MODEL"),
    )

    rag_top_k: int = 6
    rag_min_similarity: float = 0.15
    rag_national_first: bool = True

    @property
    def allowed_origins_list(self) -> list[str]:
        return [o.strip() for o in self.allowed_origins.split(",") if o.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
