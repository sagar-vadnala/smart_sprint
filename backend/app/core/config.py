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

    # ── Google SSO ────────────────────────────────────────────────────────────
    # The OAuth 2.0 **Web** client ID from Google Cloud Console. We verify that
    # incoming Google ID tokens were issued for this client (the `aud` claim).
    # Leave blank to disable Google sign-in (endpoint returns 503).
    google_client_id: str = ""

    # ── App URLs ──────────────────────────────────────────────────────────────
    # Public base URL of the FRONTEND (Flutter web). Used to build invite accept
    # links: {app_base_url}/#/invite/{token}. Override in production.
    app_base_url: str = "http://localhost:8080"

    # ── Email / SMTP (invitations) ────────────────────────────────────────────
    # Leave SMTP_HOST blank to disable real email sending — invites are still
    # created and the accept link is returned in the API response + logged, so
    # the flow works end-to-end without an email provider. Fill these in (e.g. a
    # Gmail address + app password) to start delivering real emails.
    smtp_host: str = ""
    smtp_port: int = 587
    smtp_user: str = ""
    smtp_password: str = ""
    smtp_from: str = ""  # falls back to smtp_user if blank
    smtp_use_tls: bool = True  # STARTTLS (port 587). Set False for 465/SSL.

    @property
    def email_from_address(self) -> str:
        return self.smtp_from or self.smtp_user

    @property
    def email_enabled(self) -> bool:
        # Need a host and a sender address to send anything.
        return bool(self.smtp_host and self.email_from_address)

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
