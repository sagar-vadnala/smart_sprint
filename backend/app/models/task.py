"""Task + its assignees + recursive SubTasks (and their assignees)."""

from datetime import datetime

from sqlalchemy import (
    DateTime,
    ForeignKey,
    Integer,
    String,
    Table,
    Column,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
from app.models.common import new_id, utcnow

# ── Association tables (M:N) ──────────────────────────────────────────────────

task_assignees = Table(
    "task_assignees",
    Base.metadata,
    Column("task_id", String, ForeignKey("tasks.id", ondelete="CASCADE"), primary_key=True),
    Column("user_id", String, ForeignKey("users.id", ondelete="CASCADE"), primary_key=True),
)

subtask_assignees = Table(
    "subtask_assignees",
    Base.metadata,
    Column("subtask_id", String, ForeignKey("subtasks.id", ondelete="CASCADE"), primary_key=True),
    Column("user_id", String, ForeignKey("users.id", ondelete="CASCADE"), primary_key=True),
)


class Task(Base):
    __tablename__ = "tasks"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=new_id)
    workspace_id: Mapped[str] = mapped_column(
        String, ForeignKey("workspaces.id", ondelete="CASCADE"), nullable=False, index=True
    )
    sprint_id: Mapped[str | None] = mapped_column(
        String, ForeignKey("sprints.id", ondelete="SET NULL"), nullable=True
    )
    title: Mapped[str] = mapped_column(String, nullable=False)
    description: Mapped[str] = mapped_column(String, default="", nullable=False)
    status: Mapped[str] = mapped_column(String, default="todo", nullable=False)
    priority: Mapped[str] = mapped_column(String, default="normal", nullable=False)
    due_date: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_by: Mapped[str] = mapped_column(String, ForeignKey("users.id"), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, nullable=False
    )

    assignees = relationship("User", secondary=task_assignees, lazy="selectin")
    subtasks: Mapped[list["SubTask"]] = relationship(
        back_populates="task", cascade="all, delete-orphan", lazy="selectin"
    )


class SubTask(Base):
    __tablename__ = "subtasks"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=new_id)
    task_id: Mapped[str] = mapped_column(
        String, ForeignKey("tasks.id", ondelete="CASCADE"), nullable=False, index=True
    )
    parent_subtask_id: Mapped[str | None] = mapped_column(
        String, ForeignKey("subtasks.id", ondelete="CASCADE"), nullable=True
    )
    title: Mapped[str] = mapped_column(String, nullable=False)
    description: Mapped[str] = mapped_column(String, default="", nullable=False)
    status: Mapped[str] = mapped_column(String, default="todo", nullable=False)
    priority: Mapped[str | None] = mapped_column(String, nullable=True)
    due_date: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    position: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, nullable=False
    )

    task: Mapped[Task] = relationship(back_populates="subtasks")
    assignees = relationship("User", secondary=subtask_assignees, lazy="selectin")
