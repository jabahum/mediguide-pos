from __future__ import annotations

from datetime import datetime, timezone
from typing import Any

from app.core.db import db_conn


class IngestionRepository:
    def _has_attempt_count(self) -> bool:
        with db_conn() as conn, conn.cursor() as cur:
            cur.execute(
                """
                SELECT EXISTS (
                    SELECT 1
                    FROM information_schema.columns
                    WHERE table_name = 'ingestion_jobs'
                      AND column_name = 'attempt_count'
                ) AS present
                """
            )
            row = cur.fetchone()
            return bool(row and row.get("present"))

    def claim_queued_jobs(self, limit: int = 1) -> list[dict[str, Any]]:
        """Atomically pick up queued jobs and mark them running."""
        with db_conn() as conn, conn.cursor() as cur:
            cur.execute(
                """
                WITH picked AS (
                    SELECT id
                    FROM ingestion_jobs
                    WHERE status = 'queued'
                      AND job_type IN ('pdf_ingestion', 'markdown_ingestion')
                      AND deleted_at IS NULL
                    ORDER BY created_at ASC
                    LIMIT %s
                    FOR UPDATE SKIP LOCKED
                )
                UPDATE ingestion_jobs j
                SET status = 'running', started_at = coalesce(started_at, now()), updated_at = now()
                FROM picked
                WHERE j.id = picked.id
                RETURNING j.*
                """,
                (limit,),
            )
            rows = cur.fetchall()
            conn.commit()
            return rows

    def claim_retryable_jobs(self, limit: int = 1, max_attempts: int = 3, backoff_seconds: int = 30) -> list[dict[str, Any]]:
        """Pick up previously-failed jobs that are within the retry limit and past their back-off window."""
        if not self._has_attempt_count():
            return []
        with db_conn() as conn, conn.cursor() as cur:
            cur.execute(
                """
                WITH picked AS (
                    SELECT id
                    FROM ingestion_jobs
                    WHERE status = 'failed'
                      AND job_type IN ('pdf_ingestion', 'markdown_ingestion')
                      AND deleted_at IS NULL
                      AND coalesce(attempt_count, 0) < %s
                      AND (completed_at IS NULL OR completed_at < now() - (coalesce(attempt_count, 1) * %s * interval '1 second'))
                    ORDER BY completed_at ASC NULLS FIRST
                    LIMIT %s
                    FOR UPDATE SKIP LOCKED
                )
                UPDATE ingestion_jobs j
                SET status = 'queued', error = NULL, updated_at = now()
                FROM picked
                WHERE j.id = picked.id
                RETURNING j.*
                """,
                (max_attempts, backoff_seconds, limit),
            )
            rows = cur.fetchall()
            conn.commit()
            return rows

    def get_job(self, job_id: str) -> dict[str, Any] | None:
        with db_conn() as conn, conn.cursor() as cur:
            cur.execute("SELECT * FROM ingestion_jobs WHERE id = %s", (job_id,))
            return cur.fetchone()

    def mark_running(self, job_id: str) -> None:
        """Safety guard: transitions a queued job to running if not already running.
        The worker loop already handles this atomically; this method is kept for
        API-triggered jobs (the /run endpoint) where the claim step is skipped."""
        with db_conn() as conn, conn.cursor() as cur:
            cur.execute(
                "UPDATE ingestion_jobs SET status='running', started_at=coalesce(started_at, now()), updated_at=now() WHERE id=%s AND status != 'running'",
                (job_id,),
            )
            conn.commit()

    def mark_completed(self, job_id: str) -> None:
        with db_conn() as conn, conn.cursor() as cur:
            cur.execute(
                "UPDATE ingestion_jobs SET status='completed', completed_at=now(), updated_at=now(), error=NULL WHERE id=%s",
                (job_id,),
            )
            conn.commit()

    def mark_failed(self, job_id: str, error: str) -> None:
        """Increment attempt_count and mark job failed."""
        if not self._has_attempt_count():
            with db_conn() as conn, conn.cursor() as cur:
                cur.execute(
                    """UPDATE ingestion_jobs
                       SET status='failed',
                           error=%s,
                           completed_at=now(),
                           updated_at=now()
                       WHERE id=%s""",
                    (error[:4000], job_id),
                )
                conn.commit()
            return
        with db_conn() as conn, conn.cursor() as cur:
            cur.execute(
                """UPDATE ingestion_jobs
                   SET status='failed',
                       error=%s,
                       completed_at=now(),
                       updated_at=now(),
                       attempt_count=coalesce(attempt_count, 0) + 1
                   WHERE id=%s""",
                (error[:4000], job_id),
            )
            conn.commit()
