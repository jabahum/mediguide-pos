from __future__ import annotations
from pathlib import Path
import hashlib
import json
import mimetypes
import tempfile
import time
import structlog
from app.core.config import get_settings
from app.core.storage import ObjectStorage
from app.document_processing.pdf_extractor import extract_pdf
from app.document_processing.markdown_extractor import extract_markdown
from app.document_processing.chunker import chunk_blocks, chunk_sections
from app.document_processing.types import ExtractedAsset
from app.embeddings.factory import get_embedding_provider
from app.repositories.guideline_repo import GuidelineRepository
from app.repositories.ingestion_repo import IngestionRepository

log = structlog.get_logger()

class IngestionCanceled(Exception):
    pass

class IngestionSuperseded(Exception):
    pass


class IngestionService:
    def __init__(self):
        self.settings = get_settings()
        self.jobs = IngestionRepository()
        self.guidelines = GuidelineRepository()
        self.storage = ObjectStorage()
        self.embedder = get_embedding_provider()

    def run_job(self, job_id: str) -> None:
        job = self.jobs.get_job(job_id)
        if not job:
            raise ValueError(f"Ingestion job not found: {job_id}")
        if job.get("status") in {"completed", "canceled"}:
            return
        if job.get("status") == "cancel_requested":
            self.jobs.mark_canceled(job_id)
            return
        # For API-triggered runs the job may not be in 'running' state yet.
        self.jobs.mark_running(job_id)
        try:
            self._process(job)
            self.jobs.mark_completed(job_id)
        except IngestionCanceled:
            self.jobs.mark_canceled(job_id)
            log.info("ingestion_job_canceled", job_id=job_id)
        except IngestionSuperseded:
            self.jobs.mark_superseded(job_id)
            log.info("ingestion_job_superseded", job_id=job_id)
        except Exception as exc:
            log.exception("ingestion_job_failed", job_id=job_id, error=str(exc))
            self.jobs.mark_failed(job_id, str(exc))
            raise

    def _process(self, job: dict) -> None:
        job_id = str(job["id"])
        def stage(name: str, percent: int) -> None:
            if self.jobs.cancellation_requested(job_id):
                raise IngestionCanceled()
            self.jobs.set_progress(job_id, name, percent)

        version_id = str(job["version_id"])
        version = self.guidelines.get_version_with_document(version_id)
        if not version:
            raise ValueError(f"Guideline version not found: {version_id}")
        payload = self._job_payload(job)
        source_format = str(payload.get("source_format") or "").strip().lower()
        if not source_format:
            source_format = "markdown" if job.get("job_type") == "markdown_ingestion" else "pdf"
        if source_format not in {"pdf", "markdown"}:
            raise ValueError(f"Unsupported guideline source format: {source_format}")
        source_field = "markdown_file_key" if source_format == "markdown" else "original_file_key"
        source_key = str(payload.get("file_key") or version.get(source_field) or "").strip()
        if not source_key:
            raise ValueError(f"Guideline version has no {source_format} source file")
        if str(version.get(source_field) or "").strip() != source_key:
            log.info(
                "ingestion_skipped_superseded_source",
                job_id=str(job["id"]),
                version_id=version_id,
                source_format=source_format,
            )
            raise IngestionSuperseded()

        with tempfile.TemporaryDirectory(prefix="mediguide-ingest-") as tmp:
            tmp_path = Path(tmp)
            source_path = tmp_path / ("source.md" if source_format == "markdown" else "source.pdf")

            stage("downloading", 5)
            started = time.perf_counter()
            self.storage.download_file(source_key, source_path)
            document_checksum = self._file_checksum(source_path)
            log.info(
                "ingestion_download_completed",
                job_id=str(job["id"]),
                version_id=version_id,
                seconds=round(time.perf_counter() - started, 2),
                file_key=source_key,
                source_format=source_format,
                checksum=document_checksum,
            )

            if self.guidelines.is_extraction_current(version_id, document_checksum):
                log.info(
                    "ingestion_skipped_current_checksum",
                    job_id=str(job["id"]),
                    version_id=version_id,
                    checksum=document_checksum,
                    extraction_schema_version=self.guidelines.EXTRACTION_SCHEMA_VERSION,
                )
                self.jobs.complete_noop_comparison(job_id)
                return

            stage("parsing", 20)
            started = time.perf_counter()
            extracted = (
                extract_markdown(source_path, fallback_title=version.get("document_title") or "Guideline")
                if source_format == "markdown"
                else extract_pdf(source_path)
            )
            markdown_bytes = extracted.markdown.encode("utf-8")
            markdown_checksum = hashlib.sha256(markdown_bytes).hexdigest()
            log.info(
                "ingestion_extract_completed",
                job_id=str(job["id"]),
                version_id=version_id,
                seconds=round(time.perf_counter() - started, 2),
                pages=extracted.pages,
                source_format=source_format,
                sections=len(extracted.sections),
                tables=len(extracted.tables),
            )

            stage("building_structure", 40)
            started = time.perf_counter()
            chunks = chunk_blocks(extracted.blocks)
            if not chunks:
                chunks = chunk_sections(extracted.sections)
            log.info(
                "ingestion_chunking_completed",
                job_id=str(job["id"]),
                version_id=version_id,
                seconds=round(time.perf_counter() - started, 2),
                chunks=len(chunks),
            )

            schema_version = self.guidelines.EXTRACTION_SCHEMA_VERSION
            html_key = f"guidelines/{version_id}/extracted/{document_checksum}.v{schema_version}.html"
            markdown_key = f"guidelines/{version_id}/extracted/{document_checksum}.v{schema_version}.md"

            started = time.perf_counter()
            self.storage.upload_bytes(extracted.html.encode("utf-8"), html_key, "text/html; charset=utf-8")
            self.storage.upload_bytes(markdown_bytes, markdown_key, "text/markdown; charset=utf-8")
            uploaded_asset_keys: set[str] = set()
            for asset in extracted.assets:
                if not asset.data:
                    continue
                extension = self._extension_for_asset(asset)
                asset.storage_key = (
                    f"guidelines/{version_id}/assets/{asset.checksum}.{extension}"
                )
                if asset.storage_key not in uploaded_asset_keys:
                    self.storage.upload_bytes(asset.data, asset.storage_key, asset.mime_type)
                    uploaded_asset_keys.add(asset.storage_key)
                asset.data = None

            if source_format == "pdf":
                original_asset = ExtractedAsset(
                    type="original_pdf",
                    source_key="original-pdf",
                    source_fingerprint=document_checksum,
                    mime_type="application/pdf",
                    checksum=document_checksum,
                    size_bytes=source_path.stat().st_size,
                    storage_key=source_key,
                    original_filename=Path(source_key).name,
                    page_start=1,
                    page_end=extracted.pages,
                    provenance={
                        "source": "uploaded_original",
                        "immutable": True,
                        "review_required": False,
                    },
                )
                extracted.assets.insert(0, original_asset)
            log.info(
                "ingestion_asset_upload_completed",
                job_id=str(job["id"]),
                version_id=version_id,
                seconds=round(time.perf_counter() - started, 2),
                extracted_assets=len(extracted.assets),
                unique_stored_assets=len(uploaded_asset_keys) + (1 if source_format == "pdf" else 0),
            )

            stage("chunking", 55)
            texts = [c.content for c in chunks]
            embeddings = []
            batch_size = max(1, self.settings.embedding_request_batch_size)
            started = time.perf_counter()
            stage("embeddings", 65)
            for i in range(0, len(texts), batch_size):
                stage("embeddings", min(84, 65 + int((i / max(1, len(texts))) * 19)))
                batch_started = time.perf_counter()
                batch = texts[i:i + batch_size]
                embeddings.extend(self.embedder.embed(batch))
                log.info(
                    "ingestion_embedding_batch_completed",
                    job_id=str(job["id"]),
                    version_id=version_id,
                    batch_index=(i // batch_size) + 1,
                    batch_count=((len(texts) + batch_size - 1) // batch_size) if texts else 0,
                    batch_size=len(batch),
                    seconds=round(time.perf_counter() - batch_started, 2),
                )
            log.info(
                "ingestion_embedding_completed",
                job_id=str(job["id"]),
                version_id=version_id,
                seconds=round(time.perf_counter() - started, 2),
                chunks=len(chunks),
            )

            # Cancellation is deliberately no longer accepted after persistence
            # starts: replacement is one database transaction.
            stage("persisting", 90)
            started = time.perf_counter()
            latest = self.guidelines.get_version_with_document(version_id)
            if not latest or str(latest.get(source_field) or "").strip() != source_key:
                log.info(
                    "ingestion_skipped_superseded_source",
                    job_id=str(job["id"]),
                    version_id=version_id,
                    source_format=source_format,
                )
                raise IngestionSuperseded()
            self.guidelines.replace_extraction(
                version_id=version_id,
                version=version,
                sections=extracted.sections,
                tables=extracted.tables,
                chunks=chunks,
                embeddings=embeddings,
                html_key=html_key,
                markdown_key=markdown_key,
                blocks=extracted.blocks,
                assets=extracted.assets,
                checksum=document_checksum,
                metadata={
                    **extracted.metadata,
                    "source_format": source_format,
                    "source_file_key": source_key,
                    "markdown_checksum": markdown_checksum,
                    "markdown_size_bytes": len(markdown_bytes),
                    "toc_entries": extracted.toc_entries,
                    "structured_block_count": len(extracted.blocks),
                    "asset_count": len(extracted.assets),
                    "unique_asset_count": len(uploaded_asset_keys) + (1 if source_format == "pdf" else 0),
                },
                warnings=extracted.warnings,
                markdown_revision_id=str(payload.get("revision_id") or "").strip() or None,
                ingestion_job_id=str(job["id"]),
            )
            self.jobs.set_progress(job_id, "review_required", 98)
            log.info(
                "ingestion_persist_completed",
                job_id=str(job["id"]),
                version_id=version_id,
                seconds=round(time.perf_counter() - started, 2),
                sections=len(extracted.sections),
                chunks=len(chunks),
                tables=len(extracted.tables),
                blocks=len(extracted.blocks),
                assets=len(extracted.assets),
                source_format=source_format,
            )
            log.info(
                "ingestion_job_completed",
                job_id=str(job["id"]),
                version_id=version_id,
                sections=len(extracted.sections),
                chunks=len(chunks),
                tables=len(extracted.tables),
                blocks=len(extracted.blocks),
                assets=len(extracted.assets),
                source_format=source_format,
            )

    @staticmethod
    def _job_payload(job: dict) -> dict:
        value = job.get("payload_json") or {}
        if isinstance(value, dict):
            return value
        try:
            parsed = json.loads(str(value))
        except (TypeError, ValueError) as exc:
            raise ValueError("Ingestion job payload is invalid JSON") from exc
        if not isinstance(parsed, dict):
            raise ValueError("Ingestion job payload must be an object")
        return parsed

    @staticmethod
    def _file_checksum(path: Path) -> str:
        digest = hashlib.sha256()
        with path.open("rb") as source:
            for chunk in iter(lambda: source.read(1024 * 1024), b""):
                digest.update(chunk)
        return digest.hexdigest()

    @staticmethod
    def _extension_for_asset(asset: ExtractedAsset) -> str:
        if asset.original_filename and "." in asset.original_filename:
            return asset.original_filename.rsplit(".", 1)[-1].lower()
        guessed = mimetypes.guess_extension(asset.mime_type) or ".bin"
        return guessed.lstrip(".")
