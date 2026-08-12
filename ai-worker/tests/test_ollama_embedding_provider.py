import httpx
import pytest

from app.core.config import get_settings
from app.embeddings.ollama_provider import OllamaEmbeddingProvider


class FakeResponse:
    def __init__(
        self,
        embeddings: list[list[float]] | None = None,
        *,
        status_code: int = 200,
        embedding: list[float] | None = None,
    ):
        self._embeddings = embeddings
        self._embedding = embedding
        self.status_code = status_code
        self.text = f"status={status_code}"

    def raise_for_status(self) -> None:
        if self.status_code >= 400:
            request = httpx.Request("POST", "http://ollama.test")
            response = httpx.Response(self.status_code, request=request)
            raise httpx.HTTPStatusError("request failed", request=request, response=response)
        return None

    def json(self) -> dict:
        if self._embedding is not None:
            return {"embedding": self._embedding}
        return {"embeddings": self._embeddings}


class FakeClient:
    def __init__(self, responses: list[FakeResponse], calls: list[tuple[str, dict]], **_: object):
        self._responses = responses
        self._calls = calls

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc, tb):
        return False

    def post(self, url: str, json: dict):
        self._calls.append((url, json))
        if self._responses:
            return self._responses.pop(0)
        return FakeResponse([])


def clear_settings_cache() -> None:
    get_settings.cache_clear()


def test_ollama_embedding_provider_calls_embed_api(monkeypatch: pytest.MonkeyPatch):
    calls: list[tuple[str, dict]] = []
    monkeypatch.setenv("OLLAMA_BASE_URL", "http://ollama:11434")
    monkeypatch.setenv("OLLAMA_EMBEDDING_MODEL", "mxbai-embed-large:latest")
    monkeypatch.setenv("EMBEDDING_DIM", "4")
    monkeypatch.setattr(
        "app.embeddings.ollama_provider.httpx.Client",
        lambda **kwargs: FakeClient([FakeResponse([[0.1, 0.2, 0.3, 0.4]])], calls, **kwargs),
    )
    clear_settings_cache()

    try:
        provider = OllamaEmbeddingProvider()
        embeddings = provider.embed(["severe malaria treatment"])
    finally:
        clear_settings_cache()

    assert embeddings == [[0.1, 0.2, 0.3, 0.4]]
    assert calls == [
        (
            "http://ollama:11434/api/embed",
            {
                "model": "mxbai-embed-large:latest",
                "input": ["severe malaria treatment"],
                "truncate": True,
            },
        )
    ]


def test_ollama_embedding_provider_falls_back_to_legacy_embeddings_api(
    monkeypatch: pytest.MonkeyPatch,
):
    calls: list[tuple[str, dict]] = []
    monkeypatch.setenv("OLLAMA_BASE_URL", "http://ollama:11434")
    monkeypatch.setenv("OLLAMA_EMBEDDING_MODEL", "mxbai-embed-large:latest")
    monkeypatch.setenv("EMBEDDING_DIM", "4")
    monkeypatch.setattr(
        "app.embeddings.ollama_provider.httpx.Client",
        lambda **kwargs: FakeClient(
            [
                FakeResponse([], status_code=400),
                FakeResponse([], status_code=400),
                FakeResponse(embedding=[0.1, 0.2, 0.3, 0.4]),
            ],
            calls,
            **kwargs,
        ),
    )
    clear_settings_cache()

    try:
        provider = OllamaEmbeddingProvider()
        embeddings = provider.embed(["severe malaria treatment"])
    finally:
        clear_settings_cache()

    assert embeddings == [[0.1, 0.2, 0.3, 0.4]]
    assert calls == [
        (
            "http://ollama:11434/api/embed",
            {
                "model": "mxbai-embed-large:latest",
                "input": ["severe malaria treatment"],
                "truncate": True,
            },
        ),
        (
            "http://ollama:11434/api/embed",
            {
                "model": "mxbai-embed-large:latest",
                "input": "severe malaria treatment",
                "truncate": True,
            },
        ),
        (
            "http://ollama:11434/api/embeddings",
            {
                "model": "mxbai-embed-large:latest",
                "prompt": "severe malaria treatment",
            },
        ),
    ]


def test_ollama_embedding_provider_splits_failed_batch_before_fallback(
    monkeypatch: pytest.MonkeyPatch,
):
    calls: list[tuple[str, dict]] = []
    monkeypatch.setenv("OLLAMA_BASE_URL", "http://ollama:11434")
    monkeypatch.setenv("OLLAMA_EMBEDDING_MODEL", "mxbai-embed-large:latest")
    monkeypatch.setenv("EMBEDDING_DIM", "4")
    monkeypatch.setattr(
        "app.embeddings.ollama_provider.httpx.Client",
        lambda **kwargs: FakeClient(
            [
                FakeResponse([], status_code=400),
                FakeResponse([[0.1, 0.2, 0.3, 0.4]]),
                FakeResponse([[0.4, 0.3, 0.2, 0.1]]),
            ],
            calls,
            **kwargs,
        ),
    )
    clear_settings_cache()

    try:
        provider = OllamaEmbeddingProvider()
        embeddings = provider.embed(["first text", "second text"])
    finally:
        clear_settings_cache()

    assert embeddings == [[0.1, 0.2, 0.3, 0.4], [0.4, 0.3, 0.2, 0.1]]
    assert calls == [
        (
            "http://ollama:11434/api/embed",
            {
                "model": "mxbai-embed-large:latest",
                "input": ["first text", "second text"],
                "truncate": True,
            },
        ),
        (
            "http://ollama:11434/api/embed",
            {
                "model": "mxbai-embed-large:latest",
                "input": "first text",
                "truncate": True,
            },
        ),
        (
            "http://ollama:11434/api/embed",
            {
                "model": "mxbai-embed-large:latest",
                "input": "second text",
                "truncate": True,
            },
        ),
    ]


def test_ollama_embedding_provider_rejects_dimension_mismatch(monkeypatch: pytest.MonkeyPatch):
    calls: list[tuple[str, dict]] = []
    monkeypatch.setenv("OLLAMA_BASE_URL", "http://ollama:11434")
    monkeypatch.setenv("OLLAMA_EMBEDDING_MODEL", "mxbai-embed-large:latest")
    monkeypatch.setenv("EMBEDDING_DIM", "4")
    monkeypatch.setattr(
        "app.embeddings.ollama_provider.httpx.Client",
        lambda **kwargs: FakeClient([FakeResponse([[0.1, 0.2, 0.3]])], calls, **kwargs),
    )
    clear_settings_cache()

    try:
        provider = OllamaEmbeddingProvider()
        with pytest.raises(RuntimeError, match="EMBEDDING_DIM"):
            provider.embed(["severe malaria treatment"])
    finally:
        clear_settings_cache()
