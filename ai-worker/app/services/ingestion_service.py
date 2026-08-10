from __future__ import annotations
from pathlib import Path
import hashlib
import mimetypes
import tempfile
import time
import structlog
from app.core.config import get_settings
from app.core.storage import ObjectStorage
from app.document_processing.pdf_extractor import extract_pdf
from app.document_processing.chunker import chunk_blocks, chunk_sections
from app.document_processing.types import ExtractedAsset
from app.embeddings.factory import get_embedding_provider
from app.repositories.guideline_repo import GuidelineRepository
from app.repositories.ingestion_repo import IngestionRepository

log = structlog.get_logger()


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
        # For API-triggered runs the job may not be in 'running' state yet.
        self.jobs.mark_running(job_id)
        try:
            self._process(job)
            self.jobs.mark_completed(job_id)
        except Exception as exc:
            log.exception("ingestion_job_failed", job_id=job_id, error=str(exc))
            self.jobs.mark_failed(job_id, str(exc))
            raise

    def _process(self, job: dict) -> None:
        version_id = str(job["version_id"])
        version = self.guidelines.get_version_with_document(version_id)
        if not version:
            raise ValueError(f"Guideline version not found: {version_id}")
        original_key = version.get("original_file_key")
        if not original_key:
            raise ValueError("Guideline version has no original_file_key")

        with tempfile.TemporaryDirectory(prefix="mediguide-ingest-") as tmp:
            tmp_path = Path(tmp)
            pdf_path = tmp_path / "source.pdf"

            started = time.perf_counter()
            self.storage.download_file(original_key, pdf_path)
            document_checksum = self._file_checksum(pdf_path)
            log.info(
                "ingestion_download_completed",
                job_id=str(job["id"]),
                version_id=version_id,
                seconds=round(time.perf_counter() - started, 2),
                file_key=original_key,
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
                return

            started = time.perf_counter()
            extracted = extract_pdf(pdf_path)
            log.info(
                "ingestion_extract_completed",
                job_id=str(job["id"]),
                version_id=version_id,
                seconds=round(time.perf_counter() - started, 2),
                pages=extracted.pages,
                sections=len(extracted.sections),
                tables=len(extracted.tables),
            )

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
            self.storage.upload_bytes(extracted.markdown.encode("utf-8"), markdown_key, "text/markdown; charset=utf-8")
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

            original_asset = ExtractedAsset(
                type="original_pdf",
                source_key="original-pdf",
                source_fingerprint=document_checksum,
                mime_type="application/pdf",
                checksum=document_checksum,
                size_bytes=pdf_path.stat().st_size,
                storage_key=original_key,
                original_filename=Path(original_key).name,
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
                unique_stored_assets=len(uploaded_asset_keys) + 1,
            )

            texts = [c.content for c in chunks]
            embeddings = []
            batch_size = max(1, self.settings.embedding_request_batch_size)
            started = time.perf_counter()
            for i in range(0, len(texts), batch_size):
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

            started = time.perf_counter()
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
                    "toc_entries": extracted.toc_entries,
                    "structured_block_count": len(extracted.blocks),
                    "asset_count": len(extracted.assets),
                    "unique_asset_count": len(uploaded_asset_keys) + 1,
                },
                warnings=extracted.warnings,
            )
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
            )

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
