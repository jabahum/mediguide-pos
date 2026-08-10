from __future__ import annotations

import io
from functools import lru_cache
from pathlib import Path
import tempfile

from fastapi import APIRouter, Depends, Header, HTTPException, UploadFile, File

from app.core.config import Settings, get_settings
from app.core.storage import ObjectStorage
from app.document_processing.chunker import chunk_blocks, chunk_sections
from app.document_processing.pdf_extractor import extract_pdf
from app.models.schemas import (
    ExtractionPreviewResponse,
    HealthResponse,
    ReadinessResponse,
    RagAskRequest,
    RagAskResponse,
    RunJobResponse,
)
from app.services.ingestion_service import IngestionService
from app.services.rag_service import RagService

router = APIRouter()


# ---------------------------------------------------------------------------
# Singleton service factories
# ---------------------------------------------------------------------------

@lru_cache(maxsize=1)
def _get_ingestion_service() -> IngestionService:
    return IngestionService()


@lru_cache(maxsize=1)
def _get_rag_service() -> RagService:
    return RagService()


# ---------------------------------------------------------------------------
# Internal-API auth dependency
# ---------------------------------------------------------------------------

def _require_worker_secret(
    x_worker_secret: str | None = Header(default=None, alias="X-Worker-Secret"),
    settings: Settings = Depends(get_settings),
) -> None:
    """Validates the shared secret sent by the backend for internal endpoints.
    If WORKER_API_SECRET is not configured the check is skipped (dev mode).
    """
    secret = (settings.worker_api_secret or "").strip()
    if secret and x_worker_secret != secret:
        raise HTTPException(status_code=401, detail="invalid or missing X-Worker-Secret header")


# ---------------------------------------------------------------------------
# Routes
# ---------------------------------------------------------------------------

@router.get("/healthz", response_model=HealthResponse)
def healthz():
    return HealthResponse()


@router.get("/readyz", response_model=ReadinessResponse)
def readyz(settings: Settings = Depends(get_settings)):
    """Readiness probe: verifies DB connectivity and MinIO bucket availability."""
    checks: dict[str, str] = {}

    # DB check
    try:
        from app.core.db import db_conn
        with db_conn() as conn, conn.cursor() as cur:
            cur.execute("SELECT 1")
        checks["db"] = "ok"
    except Exception as exc:
        checks["db"] = f"error: {exc}"

    # MinIO check
    try:
        store = ObjectStorage()
        checks["storage"] = "ok"
    except Exception as exc:
        checks["storage"] = f"error: {exc}"

    status = "ok" if all(v == "ok" for v in checks.values()) else "degraded"
    if status != "ok":
        raise HTTPException(status_code=503, detail=ReadinessResponse(status=status, checks=checks).model_dump())
    return ReadinessResponse(status=status, checks=checks)


@router.post("/api/v1/extract/preview", response_model=ExtractionPreviewResponse)
async def preview_pdf(
    file: UploadFile = File(...),
    settings: Settings = Depends(get_settings),
    _: None = Depends(_require_worker_secret),
):
    if not file.filename or not file.filename.lower().endswith(".pdf"):
        raise HTTPException(status_code=400, detail="Only PDF files are supported")

    # Enforce upload size limit before buffering.
    raw = await file.read(settings.max_upload_bytes + 1)
    if len(raw) > settings.max_upload_bytes:
        raise HTTPException(
            status_code=413,
            detail=f"PDF exceeds maximum allowed size of {settings.max_upload_bytes // (1024 * 1024)} MB",
        )

    with tempfile.TemporaryDirectory(prefix="mediguide-preview-") as tmp:
        path = Path(tmp) / "upload.pdf"
        path.write_bytes(raw)
        extracted = extract_pdf(path)
        chunks = chunk_blocks(extracted.blocks) or chunk_sections(extracted.sections)
        return ExtractionPreviewResponse(
            title=extracted.title,
            pages=extracted.pages,
            sections=len(extracted.sections),
            chunks=len(chunks),
            tables=len(extracted.tables),
            blocks=len(extracted.blocks),
            assets=len(extracted.assets),
            ocr_pages=extracted.ocr_pages,
            multi_column_pages=extracted.multi_column_pages,
            warnings=extracted.warnings,
            markdown_sample=extracted.markdown[:3000],
        )


@router.post(
    "/api/v1/ingestion/jobs/{job_id}/run",
    response_model=RunJobResponse,
    dependencies=[Depends(_require_worker_secret)],
)
def run_job(
    job_id: str,
    service: IngestionService = Depends(_get_ingestion_service),
):
    try:
        service.run_job(job_id)
        return RunJobResponse(job_id=job_id, status="completed", message="Ingestion job completed")
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    except Exception as exc:
        raise HTTPException(status_code=500, detail="Ingestion job failed") from exc


@router.post(
    "/api/v1/rag/ask",
    response_model=RagAskResponse,
    dependencies=[Depends(_require_worker_secret)],
)
def ask(
    request: RagAskRequest,
    service: RagService = Depends(_get_rag_service),
):
    return service.ask(
        question=request.question,
        language=request.language,
        program_area=request.program_area,
        country=request.country,
        top_k=request.top_k,
        history_summary=request.history_summary,
        recent_messages=[message.model_dump() for message in request.recent_messages],
    )
