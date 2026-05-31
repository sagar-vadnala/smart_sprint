"""
SQLAlchemy engine + session setup.

`Base` is the declarative base every model inherits from. `get_db` is a FastAPI
dependency that yields a session per-request and closes it afterwards.
"""

from collections.abc import Generator

from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker

from app.core.config import settings

# SQLite needs this flag for use across FastAPI's threadpool; Postgres ignores it.
_connect_args = (
    {"check_same_thread": False}
    if settings.database_url.startswith("sqlite")
    else {}
)

engine = create_engine(
    settings.database_url,
    connect_args=_connect_args,
    pool_pre_ping=True,  # drop dead connections (important on free-tier Postgres)
)

SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)


class Base(DeclarativeBase):
    """Base class for all ORM models."""


def get_db() -> Generator[Session, None, None]:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def init_db() -> None:
    """Create tables that don't exist yet.

    Simple approach for a learning project. When the schema starts changing in
    production, graduate to Alembic migrations instead of create_all.
    """
    # Import models so they're registered on Base.metadata before create_all.
    from app.models import user  # noqa: F401

    Base.metadata.create_all(bind=engine)
