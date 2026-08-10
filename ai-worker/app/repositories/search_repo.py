from typing import Any
from app.core.db import db_conn
from app.embeddings.factory import to_pgvector


class SearchRepository:
    def vector_search(
        self,
        query_embedding: list[float],
        top_k: int,
        program_area: str | None = None,
        language: str | None = None,
        country: str | None = None,
        national_first: bool = True,
    ) -> list[dict[str, Any]]:
        vector = to_pgvector(query_embedding)
        filters = [
            "gc.deleted_at IS NULL",
            "gc.review_status = 'approved'",
            "gc.embedding IS NOT NULL",
            "gv.deleted_at IS NULL",
            "gv.status = 'published'",
            "gd.deleted_at IS NULL",
            "gd.current_version_id = gv.id",
        ]
        select_params: list[Any] = []
        filter_params: list[Any] = []
        order_by: list[str] = []
        if program_area:
            filters.append("lower(gc.program_area) = lower(%s)")
            filter_params.append(program_area)
        if language:
            filters.append("lower(gc.language) = lower(%s)")
            filter_params.append(language)
        country_select = "gd.country,"
        if country:
            if national_first:
                country_select = (
                    "gd.country,"
                    " CASE WHEN lower(coalesce(gd.country, '')) = lower(%s) THEN 0 ELSE 1 END AS country_rank,"
                )
                select_params.append(country)
                order_by.append("country_rank ASC")
            else:
                filters.append("lower(coalesce(gd.country, '')) = lower(%s)")
                filter_params.append(country)
        params = select_params + [vector] + filter_params + [vector, top_k]
        sql = f"""
            SELECT
              gc.id, gc.document_id, gc.version_id, gc.section_id, gc.block_id,
              gc.title, gc.content, gc.page_start, gc.page_end, gc.language,
              gc.program_area, gc.source_name, gc.source_version,
              {country_select}
              1 - (gc.embedding <=> %s::vector) AS similarity
            FROM guideline_chunks gc
            JOIN guideline_versions gv ON gv.id = gc.version_id
            JOIN guideline_documents gd ON gd.id = gv.document_id
            WHERE {' AND '.join(filters)}
            ORDER BY {', '.join(order_by + ['gc.embedding <=> %s::vector'])}
            LIMIT %s
        """
        with db_conn() as conn, conn.cursor() as cur:
            cur.execute(sql, tuple(params))
            return cur.fetchall()

    def keyword_search(
        self,
        query: str,
        top_k: int,
        program_area: str | None = None,
        language: str | None = None,
        country: str | None = None,
        national_first: bool = True,
    ) -> list[dict[str, Any]]:
        filters = [
            "gc.deleted_at IS NULL",
            "gc.review_status = 'approved'",
            "gv.deleted_at IS NULL",
            "gv.status = 'published'",
            "gd.deleted_at IS NULL",
            "gd.current_version_id = gv.id",
            "gc.search_vector @@ plainto_tsquery('simple', %s)",
        ]
        select_params: list[Any] = []
        filter_params: list[Any] = [query]
        order_by: list[str] = []
        if program_area:
            filters.append("lower(gc.program_area) = lower(%s)")
            filter_params.append(program_area)
        if language:
            filters.append("lower(gc.language) = lower(%s)")
            filter_params.append(language)
        country_select = "gd.country,"
        if country:
            if national_first:
                country_select = (
                    "gd.country,"
                    " CASE WHEN lower(coalesce(gd.country, '')) = lower(%s) THEN 0 ELSE 1 END AS country_rank,"
                )
                select_params.append(country)
                order_by.append("country_rank ASC")
            else:
                filters.append("lower(coalesce(gd.country, '')) = lower(%s)")
                filter_params.append(country)

        sql = f"""
            SELECT
                gc.id, gc.document_id, gc.version_id, gc.section_id, gc.block_id,
                gc.title, gc.content, gc.page_start, gc.page_end, gc.language,
                gc.program_area, gc.source_name, gc.source_version,
                {country_select}
                ts_rank(gc.search_vector, plainto_tsquery('simple', %s)) AS similarity
            FROM guideline_chunks gc
            JOIN guideline_versions gv ON gv.id = gc.version_id
            JOIN guideline_documents gd ON gd.id = gv.document_id
            WHERE {' AND '.join(filters)}
            ORDER BY {', '.join(order_by + ['similarity DESC'])}
            LIMIT %s
        """
        exec_params = select_params + [query] + filter_params + [top_k]
        with db_conn() as conn, conn.cursor() as cur:
            cur.execute(sql, tuple(exec_params))
            return cur.fetchall()
