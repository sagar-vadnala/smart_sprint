"""
SmartSprint API entry point.

Run locally:   uvicorn app.main:app --reload
Interactive docs at:  http://127.0.0.1:8000/docs
"""

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.core.config import settings
from app.core.database import init_db

logger = logging.getLogger("smartsprint")
from app.routers import (
    auth,
    bootstrap,
    comments,
    organizations,
    sprints,
    subtasks,
    tasks,
    workspaces,
)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Create tables on startup (fine for now; switch to Alembic when schema grows).
    init_db()
    yield


app = FastAPI(
    title=settings.app_name,
    version="0.1.0",
    lifespan=lifespan,
)

# Allow the Flutter web/app frontends to call this API.
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origin_list,
    allow_credentials=False,  # we use Bearer tokens, not cookies
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.exception_handler(Exception)
async def _unhandled(request: Request, exc: Exception) -> JSONResponse:
    # Any uncaught error becomes a clean JSON 500 the client can parse, instead
    # of a plaintext "Internal Server Error". The traceback is logged server-side.
    logger.exception("Unhandled error on %s %s", request.method, request.url.path)
    return JSONResponse(
        status_code=500,
        content={"detail": "Something went wrong on our end. Please try again."},
    )


app.include_router(auth.router)
app.include_router(bootstrap.router)
app.include_router(organizations.router)
app.include_router(workspaces.router)
app.include_router(sprints.router)
app.include_router(tasks.router)
app.include_router(subtasks.router)
app.include_router(comments.router)


@app.get("/", tags=["health"])
def root() -> dict[str, str]:
    return {"service": settings.app_name, "status": "ok"}


@app.get("/health", tags=["health"])
def health() -> dict[str, str]:
    # Render pings this to know the service is alive.
    return {"status": "healthy"}
