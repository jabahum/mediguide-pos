import json
import hashlib
import uuid
from datetime import datetime, timezone
from typing import Any
from app.core.db import db_conn
from app.embeddings.factory import to_pgvector


class GuidelineRepository:
    EXTRACTION_SCHEMA_VERSION = 1

    def get_version_with_document(self, version_id: str) -> dict[str, Any] | None:
        with db_conn() as conn, conn.cursor() as cur:
            cur.execute(
                """
                SELECT gv.*, gd.title AS document_title, gd.country, gd.source_org, gd.program_area, gd.language AS document_language
                FROM guideline_versions gv
                JOIN guideline_documents gd ON gd.id = gv.document_id
                WHERE gv.id = %s AND gv.deleted_at IS NULL
                """,
                (version_id,),
            )
            return cur.fetchone()

    def clear_existing_extraction(self, version_id: str) -> None:
        with db_conn() as conn, conn.cursor() as cur:
            cur.execute("DELETE FROM guideline_chunks WHERE version_id = %s", (version_id,))
            cur.execute("DELETE FROM guideline_tables WHERE version_id = %s", (version_id,))
            cur.execute("DELETE FROM guideline_sections WHERE version_id = %s", (version_id,))
            conn.commit()

    def is_extraction_current(self, version_id: str, checksum: str) -> bool:
        with db_conn() as conn, conn.cursor() as cur:
            cur.execute(
                """
                SELECT
                  gv.checksum = %s
                  AND gv.extraction_schema_version = %s
                  AND gv.status = 'review_required'
                  AND coalesce(gv.html_file_key, '') <> ''
                  AND coalesce(gv.markdown_file_key, '') <> ''
                  AND EXISTS (SELECT 1 FROM guideline_sections gs WHERE gs.version_id = gv.id AND gs.deleted_at IS NULL)
                  AND EXISTS (SELECT 1 FROM guideline_content_blocks gb WHERE gb.version_id = gv.id AND gb.deleted_at IS NULL)
                  AND EXISTS (SELECT 1 FROM guideline_chunks gc WHERE gc.version_id = gv.id AND gc.deleted_at IS NULL)
                  AS current
                FROM guideline_versions gv
                WHERE gv.id = %s AND gv.deleted_at IS NULL
                """,
                (checksum, self.EXTRACTION_SCHEMA_VERSION, version_id),
            )
            row = cur.fetchone()
            return bool(row and row.get("current"))

    def insert_section(self, version_id: str, section, parent_id: str | None = None) -> str:
        with db_conn() as conn, conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO guideline_sections(version_id, parent_id, title, slug, level, html, text, page_start, page_end, sort_order)
                VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
                RETURNING id
                """,
                (
                    version_id,
                    parent_id,
                    section.title,
                    self._slug(section.breadcrumb or section.title),
                    section.level,
                    section.html,
                    section.text,
                    section.page_start,
                    section.page_end,
                    section.sort_order,
                ),
            )
            section_id = str(cur.fetchone()["id"])
            conn.commit()
            return section_id

    def insert_chunk(self, *, version: dict[str, Any], section_id: str | None, chunk, embedding: list[float]) -> str:
        review_status = self._chunk_review_status(version.get("status"))
        with db_conn() as conn, conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO guideline_chunks(
                  document_id, version_id, section_id, title, content, html, page_start, page_end,
                  language, program_area, source_name, source_version, review_status,
                  embedding_text, embedding
                )
                VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s::vector)
                RETURNING id
                """,
                (
                    version["document_id"],
                    version["id"],
                    section_id,
                    chunk.title,
                    chunk.content,
                    chunk.html,
                    chunk.page_start,
                    chunk.page_end,
                    version.get("document_language") or "en",
                    version.get("program_area"),
                    version.get("source_org") or version.get("document_title"),
                    version.get("version"),
                    review_status,
                    chunk.content,
                    to_pgvector(embedding),
                ),
            )
            chunk_id = str(cur.fetchone()["id"])
            conn.commit()
            return chunk_id

    def insert_table(self, version_id: str, section_id: str | None, table) -> str:
        with db_conn() as conn, conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO guideline_tables(version_id, section_id, title, html, data_json, page)
                VALUES (%s,%s,%s,%s,%s::jsonb,%s)
                RETURNING id
                """,
                (version_id, section_id, table.title, table.html, json.dumps(table.data), table.page),
            )
            table_id = str(cur.fetchone()["id"])
            conn.commit()
            return table_id

    def update_version_assets(self, version_id: str, html_key: str, markdown_key: str, status: str = "extracted") -> None:
        with db_conn() as conn, conn.cursor() as cur:
            cur.execute(
                """
                UPDATE guideline_versions
                SET html_file_key=%s, markdown_file_key=%s, status=%s, updated_at=now()
                WHERE id=%s
                """,
                (html_key, markdown_key, status, version_id),
            )
            conn.commit()

    def replace_extraction(
        self,
        *,
        version_id: str,
        version: dict[str, Any],
        sections: list[Any],
        tables: list[Any],
        chunks: list[Any],
        embeddings: list[list[float]],
        html_key: str,
        markdown_key: str,
        blocks: list[Any] | None = None,
        assets: list[Any] | None = None,
        checksum: str = "",
        metadata: dict[str, Any] | None = None,
        warnings: list[str] | None = None,
        markdown_revision_id: str | None = None,
        ingestion_job_id: str | None = None,
        extraction_schema_version: int = EXTRACTION_SCHEMA_VERSION,
        status: str = "review_required",
    ) -> None:
        if len(chunks) != len(embeddings):
            raise ValueError(
                "Embedding count does not match chunk count "
                f"({len(embeddings)} embeddings for {len(chunks)} chunks)"
            )

        blocks = blocks or []
        assets = assets or []
        metadata = metadata or {}
        warnings = warnings or []
        with db_conn() as conn, conn.cursor() as cur:
            # A job retry or duplicate delivery may reach persistence while an
            # earlier run for the same version is still finishing. Serialize
            # the destructive replacement so both transactions cannot insert
            # the same version-scoped assets concurrently.
            cur.execute(
                "SELECT pg_advisory_xact_lock(hashtext('guideline-extraction'), hashtext(%s))",
                (version_id,),
            )
            before_snapshot = self._projection_snapshot(cur, version_id)
            cur.execute(
                """
                SELECT source_fingerprint, provenance_json, page_start, page_end
                FROM guideline_content_blocks
                WHERE version_id=%s AND deleted_at IS NULL
                  AND source_fingerprint <> '' AND page_start IS NOT NULL
                """,
                (version_id,),
            )
            previous_page_provenance = {
                str(row["source_fingerprint"]): row for row in cur.fetchall()
            }
            cur.execute("DELETE FROM guideline_chunks WHERE version_id = %s", (version_id,))
            cur.execute("DELETE FROM guideline_tables WHERE version_id = %s", (version_id,))
            cur.execute("DELETE FROM guideline_content_blocks WHERE version_id = %s", (version_id,))
            cur.execute(
                """
                SELECT id FROM guideline_assets
                WHERE version_id = %s AND deleted_at IS NULL
                  AND (source_fingerprint LIKE 'editor:%%' OR type='original_pdf')
                """,
                (version_id,),
            )
            authored_asset_ids = {str(row["id"]) for row in cur.fetchall()}
            cur.execute(
                """
                DELETE FROM guideline_assets
                WHERE version_id = %s AND source_fingerprint NOT LIKE 'editor:%%' AND type <> 'original_pdf'
                """,
                (version_id,),
            )
            cur.execute("DELETE FROM guideline_sections WHERE version_id = %s", (version_id,))

            section_id_by_order: dict[int, str] = {}
            section_rows: list[tuple[Any, ...]] = []
            for section in sections:
                section_id = str(uuid.uuid4())
                section_id_by_order[section.sort_order] = section_id
                parent_id = (
                    section_id_by_order.get(section.parent_sort_order)
                    if section.parent_sort_order is not None
                    else None
                )
                section_rows.append(
                    (
                        section_id,
                        version_id,
                        parent_id,
                        section.title,
                        self._slug(section.breadcrumb or section.title),
                        section.level,
                        section.html,
                        section.text,
                        section.page_start,
                        section.page_end,
                        section.sort_order,
                    )
                )
            if section_rows:
                cur.executemany(
                    """
                    INSERT INTO guideline_sections(
                      id, version_id, parent_id, title, slug, level, html, text, page_start, page_end, sort_order
                    )
                    VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
                    """,
                    section_rows,
                )

            asset_id_by_source_key, asset_rows = self._prepare_asset_rows(
                version_id=version_id,
                assets=assets,
                section_id_by_order=section_id_by_order,
            )
            if asset_rows:
                cur.executemany(
                    """
                    INSERT INTO guideline_assets(
                      id, version_id, section_id, type, mime_type, checksum, storage_key,
                      size_bytes, original_filename, source_fingerprint, provenance_json,
                      page_start, page_end
                    )
                    VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s::jsonb,%s,%s)
                    """,
                    asset_rows,
                )

            block_id_by_order: dict[int, str] = {}
            block_rows: list[tuple[Any, ...]] = []
            preserved_page_citations = 0
            for block in blocks:
                block_id = str(uuid.uuid4())
                block_id_by_order[block.sort_order] = block_id
                content = dict(block.content)
                asset_source_key = content.pop("asset_source_key", None)
                if asset_source_key:
                    asset_id = asset_id_by_source_key.get(asset_source_key)
                    if not asset_id:
                        raise ValueError(f"Structured block references missing asset: {asset_source_key}")
                    content["asset_id"] = asset_id
                direct_asset_id = str(content.get("asset_id") or "").strip()
                generated_asset_ids = asset_id_by_source_key.values()
                if (
                    direct_asset_id
                    and direct_asset_id not in authored_asset_ids
                    and direct_asset_id not in generated_asset_ids
                ):
                    raise ValueError(
                        "Structured block references an asset outside this version: "
                        f"{direct_asset_id}"
                    )
                page_start = block.page_start
                page_end = block.page_end
                provenance = dict(block.provenance)
                previous = previous_page_provenance.get(str(block.source_fingerprint or ""))
                if page_start is None and previous is not None:
                    page_start = previous.get("page_start")
                    page_end = previous.get("page_end")
                    provenance.update({
                        "pdf_mapping_preserved": True,
                        "pdf_mapping_method": "unchanged_source_fingerprint",
                    })
                    preserved_page_citations += 1
                block_rows.append(
                    (
                        block_id,
                        version_id,
                        section_id_by_order.get(block.section_order),
                        block.type,
                        block.sort_order,
                        json.dumps(content, ensure_ascii=False),
                        block.source_fingerprint,
                        json.dumps(provenance, ensure_ascii=False),
                        page_start,
                        page_end,
                        block.extraction_confidence,
                        "draft",
                    )
                )
            if block_rows:
                cur.executemany(
                    """
                    INSERT INTO guideline_content_blocks(
                      id, version_id, section_id, type, sort_order, content_json,
                      source_fingerprint, provenance_json, page_start, page_end,
                      extraction_confidence, review_status
                    )
                    VALUES (%s,%s,%s,%s,%s,%s::jsonb,%s,%s::jsonb,%s,%s,%s,%s)
                    """,
                    block_rows,
                )

            if str(metadata.get("source_format") or "") == "markdown":
                metadata["page_citations_available"] = preserved_page_citations > 0
                metadata["preserved_pdf_page_citation_count"] = preserved_page_citations
                warnings[:] = [item for item in warnings if "original-PDF access are unavailable" not in item]
                if previous_page_provenance:
                    warnings.append(
                        f"PDF page provenance was retained for {preserved_page_citations} unchanged fingerprint-matched block(s); edited blocks have no page citation."
                    )
                else:
                    warnings.append("Markdown source has no verified PDF page mappings; page citations are unavailable.")

            table_rows: list[tuple[Any, ...]] = []
            for table in tables:
                section_id = self._section_id_for_page(sections, section_id_by_order, table.page)
                table_rows.append(
                    (
                        str(uuid.uuid4()),
                        version_id,
                        section_id,
                        table.title,
                        table.html,
                        json.dumps(table.data),
                        table.page,
                    )
                )
            if table_rows:
                cur.executemany(
                    """
                    INSERT INTO guideline_tables(id, version_id, section_id, title, html, data_json, page)
                    VALUES (%s,%s,%s,%s,%s,%s::jsonb,%s)
                    """,
                    table_rows,
                )

            chunk_rows: list[tuple[Any, ...]] = []
            for chunk, embedding in zip(chunks, embeddings):
                section_id = section_id_by_order.get(chunk.section_order)
                block_id = block_id_by_order.get(chunk.block_order) if chunk.block_order is not None else None
                chunk_rows.append(
                    (
                        str(uuid.uuid4()),
                        version["document_id"],
                        version["id"],
                        section_id,
                        block_id,
                        chunk.title,
                        chunk.content,
                        chunk.html,
                        chunk.page_start,
                        chunk.page_end,
                        version.get("document_language") or "en",
                        version.get("program_area"),
                        version.get("source_org") or version.get("document_title"),
                        version.get("version"),
                        "draft",
                        chunk.content,
                        to_pgvector(embedding),
                    )
                )
            if chunk_rows:
                cur.executemany(
                    """
                    INSERT INTO guideline_chunks(
                      id, document_id, version_id, section_id, block_id, title, content, html, page_start, page_end,
                      language, program_area, source_name, source_version, review_status,
                      embedding_text, embedding
                    )
                    VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s::vector)
                    """,
                    chunk_rows,
                )

            resolved_revision_id = markdown_revision_id
            if resolved_revision_id:
                cur.execute(
                    """
                    UPDATE guideline_markdown_revisions
                    SET checksum=%s,
                        size_bytes=%s,
                        structured_content_status='review_required',
                        review_state='review_required',
                        regeneration_job_id=COALESCE(regeneration_job_id, %s),
                        updated_at=now()
                    WHERE id=%s AND version_id=%s AND deleted_at IS NULL
                    """,
                    (
                        str(metadata.get("markdown_checksum") or ""),
                        int(metadata.get("markdown_size_bytes") or 0),
                        ingestion_job_id,
                        resolved_revision_id,
                        version_id,
                    ),
                )
                if cur.rowcount != 1:
                    raise ValueError("Markdown revision was not found for ingestion")
            else:
                resolved_revision_id = str(uuid.uuid4())
                cur.execute(
                    "UPDATE guideline_markdown_revisions SET is_current=FALSE, updated_at=now() "
                    "WHERE version_id=%s AND is_current=TRUE AND deleted_at IS NULL",
                    (version_id,),
                )
                cur.execute(
                    "SELECT COALESCE(MAX(revision_number), 0) + 1 AS revision_number "
                    "FROM guideline_markdown_revisions WHERE version_id=%s AND deleted_at IS NULL",
                    (version_id,),
                )
                revision_number = int(cur.fetchone()["revision_number"])
                cur.execute(
                    """
                    INSERT INTO guideline_markdown_revisions(
                      id, document_id, version_id, revision_number, storage_key,
                      checksum, size_bytes, source_type, source_ingestion_job_id,
                      regeneration_job_id, is_current, structured_content_status,
                      review_state, publication_state
                    )
                    VALUES (%s,%s,%s,%s,%s,%s,%s,'pdf_generated',%s,%s,TRUE,
                            'review_required','review_required','draft')
                    """,
                    (
                        resolved_revision_id,
                        version["document_id"],
                        version_id,
                        revision_number,
                        markdown_key,
                        str(metadata.get("markdown_checksum") or ""),
                        int(metadata.get("markdown_size_bytes") or 0),
                        ingestion_job_id,
                        ingestion_job_id,
                    ),
                )

            cur.execute(
                """
                UPDATE guideline_versions
                SET html_file_key=%s,
                    markdown_file_key=%s,
                    checksum=%s,
                    extraction_schema_version=%s,
                    extraction_metadata_json=%s::jsonb,
                    extraction_warnings_json=%s::jsonb,
                    current_markdown_revision_id=%s,
                    structured_markdown_revision_id=%s,
                    structured_content_status='review_required',
                    status=%s,
                    updated_at=now()
                WHERE id=%s
                """,
                (
                    html_key,
                    markdown_key,
                    checksum,
                    extraction_schema_version,
                    json.dumps(metadata, ensure_ascii=False),
                    json.dumps(warnings, ensure_ascii=False),
                    resolved_revision_id,
                    resolved_revision_id,
                    status,
                    version_id,
                ),
            )
            self._upsert_draft_manifest(
                cur,
                version=version,
                has_original_pdf=bool(str(version.get("original_file_key") or "").strip())
                or any(asset.type == "original_pdf" for asset in assets),
            )
            if ingestion_job_id:
                after_snapshot = self._projection_snapshot(cur, version_id)
                comparison = self._compare_projection_snapshots(before_snapshot, after_snapshot)
                cur.execute(
                    """
                    UPDATE guideline_regeneration_reviews
                    SET after_snapshot=%s::jsonb, comparison=%s::jsonb, updated_at=now()
                    WHERE job_id=%s AND version_id=%s AND deleted_at IS NULL
                    """,
                    (json.dumps(after_snapshot, default=str), json.dumps(comparison, default=str), ingestion_job_id, version_id),
                )
            conn.commit()

    @staticmethod
    def _projection_snapshot(cur, version_id: str) -> dict[str, Any]:
        cur.execute("SELECT title, slug, level, sort_order FROM guideline_sections WHERE version_id=%s AND deleted_at IS NULL ORDER BY sort_order,id", (version_id,))
        sections = cur.fetchall()
        cur.execute("SELECT type, source_fingerprint, provenance_json, review_status, page_start, page_end FROM guideline_content_blocks WHERE version_id=%s AND deleted_at IS NULL ORDER BY sort_order,id", (version_id,))
        blocks = cur.fetchall()
        counts: dict[str, int] = {}
        for block in blocks:
            key = str(block.get("type") or "unknown")
            counts[key] = counts.get(key, 0) + 1
        cur.execute("SELECT count(*) AS count FROM guideline_tables WHERE version_id=%s AND deleted_at IS NULL", (version_id,)); table_count = int(cur.fetchone()["count"])
        cur.execute("SELECT count(*) AS count FROM guideline_chunks WHERE version_id=%s AND deleted_at IS NULL", (version_id,)); chunk_count = int(cur.fetchone()["count"])
        cur.execute("SELECT type, source_fingerprint, provenance_json FROM guideline_assets WHERE version_id=%s AND deleted_at IS NULL ORDER BY type,source_fingerprint", (version_id,)); assets = cur.fetchall()
        return {"sections": sections, "blocks": blocks, "block_type_counts": counts, "table_count": table_count, "chunk_count": chunk_count, "assets": assets}

    @staticmethod
    def _compare_projection_snapshots(before: dict[str, Any], after: dict[str, Any]) -> dict[str, Any]:
        before_sections = {str(row.get("slug")): row for row in before.get("sections", [])}
        after_sections = {str(row.get("slug")): row for row in after.get("sections", [])}
        before_types = before.get("block_type_counts", {})
        after_types = after.get("block_type_counts", {})
        all_types = sorted(set(before_types) | set(after_types))
        before_assets = {str(row.get("source_fingerprint")): row for row in before.get("assets", [])}
        after_assets = {str(row.get("source_fingerprint")): row for row in after.get("assets", [])}
        has_original_pdf = any(row.get("type") == "original_pdf" for row in after.get("assets", []))
        has_page_citations = any(row.get("page_start") is not None for row in after.get("blocks", []))
        return {
            "sections": {
                "added": [after_sections[key] for key in sorted(set(after_sections) - set(before_sections))],
                "removed": [before_sections[key] for key in sorted(set(before_sections) - set(after_sections))],
                "renamed": [{"before": before_sections[key], "after": after_sections[key]} for key in sorted(set(before_sections) & set(after_sections)) if before_sections[key].get("title") != after_sections[key].get("title")],
                "hierarchy_changed": [{"before": before_sections[key], "after": after_sections[key]} for key in sorted(set(before_sections) & set(after_sections)) if before_sections[key].get("level") != after_sections[key].get("level")],
            },
            "block_types": [{"type": key, "before": int(before_types.get(key, 0)), "after": int(after_types.get(key, 0))} for key in all_types if before_types.get(key, 0) != after_types.get(key, 0)],
            "tables": {"before": before.get("table_count", 0), "after": after.get("table_count", 0)},
            "chunks": {"before": before.get("chunk_count", 0), "after": after.get("chunk_count", 0)},
            "assets": {"added": [after_assets[key] for key in sorted(set(after_assets)-set(before_assets))], "removed": [before_assets[key] for key in sorted(set(before_assets)-set(after_assets))]},
            "provenance": {"before_fingerprints": len({row.get("source_fingerprint") for row in before.get("blocks", [])}), "after_fingerprints": len({row.get("source_fingerprint") for row in after.get("blocks", [])})},
            "original_pdf_available": has_original_pdf,
            "pdf_citations_unavailable": not has_original_pdf or not has_page_citations,
        }

    @staticmethod
    def _prepare_asset_rows(
        *,
        version_id: str,
        assets: list[Any],
        section_id_by_order: dict[int, str],
    ) -> tuple[dict[str, str], list[tuple[Any, ...]]]:
        """Create one row per stored object while retaining every source alias.

        Embedded images are content-addressed, so the same image can occur in
        several PDF locations with different source keys but one storage key.
        Blocks for all occurrences must reference the canonical asset row.
        """
        asset_id_by_source_key: dict[str, str] = {}
        canonical_by_storage_key: dict[str, tuple[str, Any]] = {}
        source_fingerprint_storage: dict[str, str] = {}
        asset_rows: list[tuple[Any, ...]] = []

        for asset in assets:
            source_key = str(asset.source_key or "").strip()
            storage_key = str(asset.storage_key or "").strip()
            source_fingerprint = str(asset.source_fingerprint or "").strip()
            if not source_key:
                raise ValueError("Extracted asset is missing its source key")
            if not storage_key:
                raise ValueError(f"Extracted asset {source_key} is missing its storage key")
            if not source_fingerprint:
                raise ValueError(f"Extracted asset {source_key} is missing its source fingerprint")

            existing_source_id = asset_id_by_source_key.get(source_key)
            canonical = canonical_by_storage_key.get(storage_key)
            if existing_source_id is not None:
                if canonical is None or canonical[0] != existing_source_id:
                    raise ValueError(
                        f"Extracted asset source key maps to multiple objects: {source_key}"
                    )
                GuidelineRepository._validate_asset_alias(canonical[1], asset, storage_key)
                continue

            previous_storage = source_fingerprint_storage.get(source_fingerprint)
            if previous_storage is not None and previous_storage != storage_key:
                raise ValueError(
                    "Extracted asset fingerprint maps to multiple objects: "
                    f"{source_fingerprint}"
                )

            if canonical is not None:
                asset_id, canonical_asset = canonical
                GuidelineRepository._validate_asset_alias(canonical_asset, asset, storage_key)
                asset_id_by_source_key[source_key] = asset_id
                source_fingerprint_storage[source_fingerprint] = storage_key
                continue

            asset_id = str(uuid.uuid4())
            asset_id_by_source_key[source_key] = asset_id
            canonical_by_storage_key[storage_key] = (asset_id, asset)
            source_fingerprint_storage[source_fingerprint] = storage_key
            asset_rows.append(
                (
                    asset_id,
                    version_id,
                    section_id_by_order.get(asset.section_order),
                    asset.type,
                    asset.mime_type,
                    asset.checksum,
                    storage_key,
                    asset.size_bytes,
                    asset.original_filename,
                    source_fingerprint,
                    json.dumps(asset.provenance),
                    asset.page_start,
                    asset.page_end,
                )
            )

        return asset_id_by_source_key, asset_rows

    @staticmethod
    def _validate_asset_alias(canonical: Any, alias: Any, storage_key: str) -> None:
        # The same binary may be heuristically classified as a figure in one
        # location and a diagram in another. Its storage identity is still the
        # checksum, MIME type and byte length; the canonical row keeps the
        # first classification while each block keeps its own context.
        comparable_fields = ("checksum", "mime_type", "size_bytes")
        mismatches = [
            field for field in comparable_fields
            if getattr(canonical, field) != getattr(alias, field)
        ]
        if mismatches:
            raise ValueError(
                f"Conflicting extracted asset metadata for {storage_key}: "
                + ", ".join(mismatches)
            )

    @staticmethod
    def _section_id_for_page(sections, section_id_by_order: dict[int, str], page: int) -> str | None:
        candidates = [
            section for section in sections
            if (section.page_start or 0) <= page <= (section.page_end or section.page_start or 0)
        ]
        if not candidates:
            return None
        return section_id_by_order.get(candidates[-1].sort_order)

    def _upsert_draft_manifest(self, cur, *, version: dict[str, Any], has_original_pdf: bool) -> None:
        payload = {
            "guideline_id": str(version["document_id"]),
            "version_id": str(version["id"]),
            "version": version.get("version") or "",
            "schema_version": 1,
            "package_version": 1,
            "extraction_quality": "unreviewed",
            "has_chapters": False,
            "has_key_points": False,
            "has_tables": False,
            "has_figures": False,
            "has_algorithms": False,
            "has_original_pdf": has_original_pdf,
            "has_offline_package": False,
            "section_count": 0,
            "block_count": 0,
            "table_count": 0,
            "figure_count": 0,
            "algorithm_count": 0,
        }
        checksum = hashlib.sha256(
            json.dumps(payload, sort_keys=True, separators=(",", ":")).encode("utf-8")
        ).hexdigest()
        generated_at = datetime.now(timezone.utc)
        cur.execute(
            """
            INSERT INTO guideline_version_manifests(
              guideline_id, version_id, version, schema_version, package_version,
              extraction_quality, has_chapters, has_key_points, has_tables,
              has_figures, has_algorithms, has_original_pdf, has_offline_package,
              section_count, block_count, table_count, figure_count, algorithm_count,
              checksum, etag, generated_at
            )
            VALUES (%s,%s,%s,1,1,'unreviewed',false,false,false,false,false,%s,false,0,0,0,0,0,%s,%s,%s)
            ON CONFLICT (version_id) DO UPDATE SET
              extraction_quality='unreviewed',
              has_chapters=false,
              has_key_points=false,
              has_tables=false,
              has_figures=false,
              has_algorithms=false,
              has_original_pdf=excluded.has_original_pdf,
              has_offline_package=false,
              section_count=0,
              block_count=0,
              table_count=0,
              figure_count=0,
              algorithm_count=0,
              checksum=excluded.checksum,
              etag=excluded.etag,
              generated_at=excluded.generated_at,
              updated_at=excluded.generated_at,
              deleted_at=NULL
            """,
            (
                version["document_id"],
                version["id"],
                version.get("version") or "",
                has_original_pdf,
                checksum,
                f'"sha256-{checksum}"',
                generated_at,
            ),
        )

    @staticmethod
    def _slug(value: str) -> str:
        from slugify import slugify
        return slugify(value or "section")

    @staticmethod
    def _chunk_review_status(version_status: str | None) -> str:
        if (version_status or "").lower() in {"approved", "published"}:
            return "approved"
        return "draft"
