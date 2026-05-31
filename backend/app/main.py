"""
SmartSprint API entry point.

Run locally:   uvicorn app.main:app --reload
Interactive docs at:  http://127.0.0.1:8000/docs
"""

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.core.database import init_db
from app.routers import auth


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

app.include_router(auth.router)


@app.get("/", tags=["health"])
def root() -> dict[str, str]:
    return {"service": settings.app_name, "status": "ok"}


@app.get("/health", tags=["health"])
def health() -> dict[str, str]:
    # Render pings this to know the service is alive.
    return {"status": "healthy"}
