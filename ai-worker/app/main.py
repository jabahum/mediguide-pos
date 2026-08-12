from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.routes import router
from app.core.config import get_settings
from app.core.db import get_pool
from app.core.logging import configure_logging
from app.grpc_server import build_grpc_server

configure_logging()
settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Initialise the connection pool at startup so all requests share one pool.
    get_pool()
    grpc_server = build_grpc_server()
    grpc_server.start()
    yield
    grpc_server.stop(grace=5)
    # Gracefully close the pool on shutdown.
    from app.core import db as _db

    if _db._pool is not None:
        _db._pool.close()


app = FastAPI(title=settings.app_name, version="0.1.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins_list,
    allow_credentials=False,  # never use credentials with a public worker API
    allow_methods=["GET", "POST"],
    allow_headers=["Content-Type", "X-Worker-Secret"],
)
app.include_router(router)
