"""
Application configuration, read from environment variables.

Everything has a sensible default so the app boots with ZERO setup locally
(SQLite + a dev JWT secret). For deployment you override these via real
environment variables on Render / Neon — never hard-code secrets.
"""

from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    # Read from a .env file if present (local dev). On Render you set real env vars.
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    # ── App ───────────────────────────────────────────────────────────────────
    app_name: str = "SmartSprint API"
    environment: str = "development"  # "development" | "production"

    # ── Database ──────────────────────────────────────────────────────────────
    # Local default = SQLite file (no DB account needed to start).
    # Deploy: set DATABASE_URL to your Neon Postgres connection string, e.g.
    #   postgresql+psycopg://user:pass@host/dbname?sslmode=require
    database_url: str = "sqlite:///./smart_sprint.db"

    # ── Auth / JWT ────────────────────────────────────────────────────────────
    # CHANGE THIS IN PRODUCTION. Generate one with:  openssl rand -hex 32
    jwt_secret: str = "dev-secret-change-me-please-0123456789abcdef"
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 60 * 24 * 7  # 7 days

    # ── CORS ──────────────────────────────────────────────────────────────────
    # Comma-separated origins allowed to call the API. "*" = allow any (fine for
    # this app because we use Bearer tokens in headers, not cookies).
    cors_origins: str = "*"

    @property
    def cors_origin_list(self) -> list[str]:
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
