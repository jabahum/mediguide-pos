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
                SET status = 'running', progress_stage='downloading', progress_percent=5,
                    started_at = coalesce(started_at, now()), updated_at = now()
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
                "UPDATE ingestion_jobs SET status='running', progress_stage='downloading', progress_percent=5, started_at=coalesce(started_at, now()), updated_at=now() WHERE id=%s AND status='queued'",
                (job_id,),
            )
            cur.execute(
                """
                UPDATE guideline_markdown_revisions
                SET structured_content_status='processing', updated_at=now()
                WHERE regeneration_job_id=%s AND deleted_at IS NULL
                """,
                (job_id,),
            )
            cur.execute(
                """
                UPDATE guideline_versions gv
                SET structured_content_status='processing', updated_at=now()
                FROM guideline_markdown_revisions revision
                WHERE revision.regeneration_job_id=%s
                  AND revision.id=gv.current_markdown_revision_id
                  AND revision.deleted_at IS NULL
                """,
                (job_id,),
            )
            conn.commit()

    def mark_completed(self, job_id: str) -> None:
        with db_conn() as conn, conn.cursor() as cur:
            cur.execute(
                "UPDATE ingestion_jobs SET status='completed', progress_stage='completed', progress_percent=100, completed_at=now(), updated_at=now(), error=NULL WHERE id=%s AND status='running'",
                (job_id,),
            )
            conn.commit()

    def set_progress(self, job_id: str, stage: str, percent: int) -> None:
        with db_conn() as conn, conn.cursor() as cur:
            cur.execute(
                "UPDATE ingestion_jobs SET progress_stage=%s, progress_percent=%s, updated_at=now() WHERE id=%s AND status='running'",
                (stage, max(0, min(100, percent)), job_id),
            )
            conn.commit()

    def cancellation_requested(self, job_id: str) -> bool:
        with db_conn() as conn, conn.cursor() as cur:
            cur.execute("SELECT status='cancel_requested' AS requested FROM ingestion_jobs WHERE id=%s", (job_id,))
            row = cur.fetchone()
            return bool(row and row.get("requested"))

    def mark_canceled(self, job_id: str) -> None:
        with db_conn() as conn, conn.cursor() as cur:
            cur.execute(
                "UPDATE ingestion_jobs SET status='canceled', progress_stage='canceled', canceled_at=now(), completed_at=now(), updated_at=now() WHERE id=%s AND status='cancel_requested'",
                (job_id,),
            )
            cur.execute("UPDATE guideline_markdown_revisions SET structured_content_status='canceled', review_state='draft', updated_at=now() WHERE regeneration_job_id=%s", (job_id,))
            cur.execute("UPDATE guideline_versions gv SET structured_content_status='canceled', updated_at=now() FROM guideline_markdown_revisions r WHERE r.regeneration_job_id=%s AND gv.current_markdown_revision_id=r.id", (job_id,))
            conn.commit()

    def mark_superseded(self, job_id: str) -> None:
        with db_conn() as conn, conn.cursor() as cur:
            cur.execute("UPDATE ingestion_jobs SET status='canceled', progress_stage='superseded', canceled_at=now(), completed_at=now(), updated_at=now() WHERE id=%s AND status='running'", (job_id,))
            cur.execute("UPDATE guideline_markdown_revisions SET structured_content_status='canceled', review_state='draft', updated_at=now() WHERE regeneration_job_id=%s", (job_id,))
            conn.commit()

    def complete_noop_comparison(self, job_id: str) -> None:
        with db_conn() as conn, conn.cursor() as cur:
            cur.execute(
                "UPDATE guideline_regeneration_reviews SET after_snapshot=before_snapshot, comparison='{\"no_changes\":true}'::jsonb, updated_at=now() WHERE job_id=%s AND deleted_at IS NULL",
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
                self._mark_revision_failed(cur, job_id)
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
            self._mark_revision_failed(cur, job_id)
            conn.commit()

    @staticmethod
    def _mark_revision_failed(cur, job_id: str) -> None:
        cur.execute(
            """
            UPDATE guideline_markdown_revisions
            SET structured_content_status='failed', updated_at=now()
            WHERE regeneration_job_id=%s AND deleted_at IS NULL
            """,
            (job_id,),
        )
        cur.execute(
            """
            UPDATE guideline_versions gv
            SET structured_content_status='failed', updated_at=now()
            FROM guideline_markdown_revisions revision
            WHERE revision.regeneration_job_id=%s
              AND revision.id=gv.current_markdown_revision_id
              AND revision.deleted_at IS NULL
            """,
            (job_id,),
        )
