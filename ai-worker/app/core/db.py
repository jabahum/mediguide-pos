from __future__ import annotations

import threading
from contextlib import contextmanager

from psycopg.rows import dict_row
from psycopg_pool import ConnectionPool

from app.core.config import get_settings

_pool: ConnectionPool | None = None
_pool_lock = threading.Lock()


def get_pool() -> ConnectionPool:
    global _pool
    if _pool is None:
        with _pool_lock:
            if _pool is None:
                settings = get_settings()
                connect_kwargs: dict = {"row_factory": dict_row}
                if settings.db_statement_timeout_ms > 0:
                    connect_kwargs["options"] = (
                        f"-c statement_timeout={settings.db_statement_timeout_ms}ms"
                    )
                _pool = ConnectionPool(
                    settings.database_url,
                    min_size=1,
                    max_size=8,
                    kwargs=connect_kwargs,
                )
    return _pool


@contextmanager
def db_conn():
    pool = get_pool()
    with pool.connection() as conn:
        yield conn
