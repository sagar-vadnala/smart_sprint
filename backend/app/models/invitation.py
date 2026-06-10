"""Invitation — a pending request for someone (by email) to join an org.

Unlike the old "add member" flow, the invitee does NOT need an account yet.
They receive an email with a tokenised accept link; accepting (after signing
up / logging in) turns the invitation into a Membership.
"""

from datetime import datetime, timedelta

from sqlalchemy import DateTime, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.common import new_id, utcnow

# How long an invite link stays valid.
INVITE_TTL = timedelta(days=14)


def _default_expiry() -> datetime:
    return utcnow() + INVITE_TTL


def new_invite_token() -> str:
    # URL-safe, unguessable. Imported lazily to keep module import cheap.
    import secrets

    return secrets.token_urlsafe(32)


class Invitation(Base):
    __tablename__ = "invitations"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=new_id)
    organization_id: Mapped[str] = mapped_column(
        String, ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False
    )
    # Lower-cased email the invite was addressed to.
    email: Mapped[str] = mapped_column(String, nullable=False, index=True)
    role: Mapped[str] = mapped_column(String, default="member", nullable=False)
    # Secret used in the accept link.
    token: Mapped[str] = mapped_column(
        String, unique=True, index=True, default=new_invite_token, nullable=False
    )
    # pending | accepted | revoked
    status: Mapped[str] = mapped_column(String, default="pending", nullable=False)
    invited_by: Mapped[str] = mapped_column(
        String, ForeignKey("users.id"), nullable=False
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, nullable=False
    )
    expires_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=_default_expiry, nullable=False
    )
    accepted_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    accepted_user_id: Mapped[str | None] = mapped_column(
        String, ForeignKey("users.id"), nullable=True
    )

    organization = relationship("Organization")

    def is_expired(self, now: datetime | None = None) -> bool:
        ref = now or utcnow()
        expires = self.expires_at
        # SQLite may hand back naive datetimes; treat them as UTC for comparison.
        if expires.tzinfo is None:
            from datetime import timezone

            expires = expires.replace(tzinfo=timezone.utc)
        return expires < ref
