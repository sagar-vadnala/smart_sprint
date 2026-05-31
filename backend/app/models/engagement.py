"""Comment + Activity (the timeline feed)."""

from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base
from app.models.common import new_id, utcnow


class Comment(Base):
    __tablename__ = "comments"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=new_id)
    task_id: Mapped[str] = mapped_column(
        String, ForeignKey("tasks.id", ondelete="CASCADE"), nullable=False, index=True
    )
    author_id: Mapped[str] = mapped_column(String, ForeignKey("users.id"), nullable=False)
    body: Mapped[str] = mapped_column(String, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, nullable=False
    )


class Activity(Base):
    __tablename__ = "activities"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=new_id)
    organization_id: Mapped[str] = mapped_column(
        String, ForeignKey("organizations.id", ondelete="CASCADE"), nullable=False, index=True
    )
    workspace_id: Mapped[str | None] = mapped_column(String, nullable=True)
    task_id: Mapped[str | None] = mapped_column(String, nullable=True, index=True)
    actor_id: Mapped[str] = mapped_column(String, ForeignKey("users.id"), nullable=False)
    kind: Mapped[str] = mapped_column(String, nullable=False)
    text: Mapped[str] = mapped_column(String, nullable=False)
    task_title: Mapped[str | None] = mapped_column(String, nullable=True)
    body: Mapped[str | None] = mapped_column(String, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, nullable=False
    )
