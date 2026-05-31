"""Organization (top tenant) + Membership (user ↔ org)."""

from datetime import datetime

from sqlalchemy import BigInteger, DateTime, ForeignKey, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.common import new_id, utcnow


class Organization(Base):
    __tablename__ = "organizations"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=new_id)
    name: Mapped[str] = mapped_column(String, nullable=False)
    type: Mapped[str] = mapped_column(String, default="team", nullable=False)  # personal | team
    # ARGB colour value — BigInteger because 0xFFxxxxxx overflows Postgres INTEGER.
    color: Mapped[int] = mapped_column(BigInteger, default=0xFF6C47FF, nullable=False)
    icon: Mapped[str] = mapped_column(String, default="groups", nullable=False)
    owner_id: Mapped[str] = mapped_column(
        String, ForeignKey("users.id"), nullable=False
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, nullable=False
    )

    memberships: Mapped[list["Membership"]] = relationship(
        back_populates="organization", cascade="all, delete-orphan"
    )


class Membership(Base):
    __tablename__ = "memberships"
    __table_args__ = (
        UniqueConstraint("organization_id", "user_id", name="uq_member_org_user"),
    )

    id: Mapped[str] = mapped_column(String, primary_key=True, default=new_id)
    organization_id: Mapped[str] = mapped_column(
        String, ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False
    )
    user_id: Mapped[str] = mapped_column(
        String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    role: Mapped[str] = mapped_column(String, default="member", nullable=False)  # owner|admin|member
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, nullable=False
    )

    organization: Mapped[Organization] = relationship(back_populates="memberships")
