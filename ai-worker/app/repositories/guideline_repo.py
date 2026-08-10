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
            cur.execute("DELETE FROM guideline_chunks WHERE version_id = %s", (version_id,))
            cur.execute("DELETE FROM guideline_tables WHERE version_id = %s", (version_id,))
            cur.execute("DELETE FROM guideline_content_blocks WHERE version_id = %s", (version_id,))
            cur.execute("DELETE FROM guideline_assets WHERE version_id = %s", (version_id,))
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

            asset_id_by_source_key: dict[str, str] = {}
            asset_rows: list[tuple[Any, ...]] = []
            for asset in assets:
                asset_id = str(uuid.uuid4())
                asset_id_by_source_key[asset.source_key] = asset_id
                section_id = section_id_by_order.get(asset.section_order)
                asset_rows.append(
                    (
                        asset_id,
                        version_id,
                        section_id,
                        asset.type,
                        asset.mime_type,
                        asset.checksum,
                        asset.storage_key,
                        asset.size_bytes,
                        asset.original_filename,
                        asset.source_fingerprint,
                        json.dumps(asset.provenance),
                        asset.page_start,
                        asset.page_end,
                    )
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
                block_rows.append(
                    (
                        block_id,
                        version_id,
                        section_id_by_order.get(block.section_order),
                        block.type,
                        block.sort_order,
                        json.dumps(content, ensure_ascii=False),
                        block.source_fingerprint,
                        json.dumps(block.provenance, ensure_ascii=False),
                        block.page_start,
                        block.page_end,
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

            cur.execute(
                """
                UPDATE guideline_versions
                SET html_file_key=%s,
                    markdown_file_key=%s,
                    checksum=%s,
                    extraction_schema_version=%s,
                    extraction_metadata_json=%s::jsonb,
                    extraction_warnings_json=%s::jsonb,
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
                    status,
                    version_id,
                ),
            )
            self._upsert_draft_manifest(
                cur,
                version=version,
                has_original_pdf=any(asset.type == "original_pdf" for asset in assets),
            )
            conn.commit()

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
