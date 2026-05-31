"""Workspace — called "Project" in the Flutter code, "Space" in the UI."""

from datetime import datetime

from sqlalchemy import BigInteger, DateTime, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base
from app.models.common import new_id, utcnow


class Workspace(Base):
    __tablename__ = "workspaces"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=new_id)
    organization_id: Mapped[str] = mapped_column(
        String, ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False, index=True
    )
    name: Mapped[str] = mapped_column(String, nullable=False)
    description: Mapped[str] = mapped_column(String, default="", nullable=False)
    # ARGB colour value — BigInteger (0xFFxxxxxx overflows Postgres INTEGER).
    color: Mapped[int] = mapped_column(BigInteger, default=0xFF6C47FF, nullable=False)
    icon: Mapped[str] = mapped_column(String, default="rocket", nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, nullable=False
    )
