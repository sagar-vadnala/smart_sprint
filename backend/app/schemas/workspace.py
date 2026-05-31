"""Request bodies for the workspace/org domain. Responses are serialized by
`app.services.serializers` into the camelCase shapes the Flutter app parses."""

from datetime import datetime

from pydantic import BaseModel, Field


# ── Organizations ─────────────────────────────────────────────────────────────

class OrgCreate(BaseModel):
    name: str = Field(min_length=1, max_length=120)
    type: str = Field(default="team", pattern="^(personal|team)$")
    color: int = 0xFF6C47FF
    icon: str = "groups"


class AddMemberRequest(BaseModel):
    email: str  # invite an existing user by email
    role: str = Field(default="member", pattern="^(owner|admin|member)$")


# ── Workspaces ────────────────────────────────────────────────────────────────

class WorkspaceCreate(BaseModel):
    organizationId: str
    name: str = Field(min_length=1, max_length=120)
    description: str = ""
    color: int = 0xFF6C47FF
    icon: str = "rocket"


class WorkspaceUpdate(BaseModel):
    name: str | None = None
    description: str | None = None
    color: int | None = None
    icon: str | None = None


# ── Sprints ───────────────────────────────────────────────────────────────────

class SprintCreate(BaseModel):
    projectId: str  # workspace id
    name: str = Field(min_length=1, max_length=120)
    goal: str = ""
    startDate: datetime
    endDate: datetime


class SprintUpdate(BaseModel):
    name: str | None = None
    goal: str | None = None
    startDate: datetime | None = None
    endDate: datetime | None = None
    status: str | None = None


# ── Tasks ─────────────────────────────────────────────────────────────────────

class TaskCreate(BaseModel):
    projectId: str
    sprintId: str | None = None
    title: str = Field(min_length=1, max_length=300)
    description: str = ""
    status: str = "todo"
    priority: str = "normal"
    assigneeIds: list[str] = []
    dueDate: datetime | None = None


class TaskUpdate(BaseModel):
    title: str | None = None
    description: str | None = None
    status: str | None = None
    priority: str | None = None
    sprintId: str | None = None
    clearSprint: bool = False
    dueDate: datetime | None = None
    clearDueDate: bool = False
    assigneeIds: list[str] | None = None
    workspaceId: str | None = None  # move to another workspace


# ── SubTasks ──────────────────────────────────────────────────────────────────

class SubTaskCreate(BaseModel):
    title: str = Field(min_length=1, max_length=300)
    parentSubTaskId: str | None = None  # nest under another subtask


class SubTaskUpdate(BaseModel):
    title: str | None = None
    description: str | None = None
    status: str | None = None
    priority: str | None = None
    clearPriority: bool = False
    dueDate: datetime | None = None
    clearDueDate: bool = False
    assigneeIds: list[str] | None = None


# ── Comments ──────────────────────────────────────────────────────────────────

class CommentCreate(BaseModel):
    body: str = Field(min_length=1)
