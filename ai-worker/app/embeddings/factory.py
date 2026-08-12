from app.core.config import get_settings
from app.embeddings.base import EmbeddingProvider
from app.embeddings.hash_provider import HashEmbeddingProvider


def get_embedding_provider() -> EmbeddingProvider:
    settings = get_settings()
    provider = settings.embedding_provider.lower()
    if provider == "hash":
        return HashEmbeddingProvider(settings.embedding_dim)
    if provider == "ollama":
        from app.embeddings.ollama_provider import OllamaEmbeddingProvider

        return OllamaEmbeddingProvider()
    if provider == "sentence_transformers":
        from app.embeddings.sentence_transformers_provider import SentenceTransformersProvider

        return SentenceTransformersProvider()
    if provider == "openai":
        from app.embeddings.openai_provider import OpenAIEmbeddingProvider

        return OpenAIEmbeddingProvider()
    raise ValueError(f"Unsupported EMBEDDING_PROVIDER={settings.embedding_provider}")


def to_pgvector(vector: list[float]) -> str:
    return "[" + ",".join(f"{x:.8f}" for x in vector) + "]"
