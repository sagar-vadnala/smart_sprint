"""
Turn ORM rows into the exact JSON shapes the Flutter app parses.

Keys are camelCase to match the Dart model `fromJson` fields (projectId,
assigneeIds, dueDate, subtasks, ...). Dates are ISO 8601 strings. Enum values
are already stored as the Dart enum `.name`, so they pass through untouched.
"""

from datetime import datetime

from app.models.organization import Organization
from app.models.sprint import Sprint
from app.models.task import SubTask, Task
from app.models.user import User
from app.models.workspace import Workspace

# These serializers are PURE — they take everything they need as arguments and
# never touch the database. Callers fetch/batch the data; this keeps
# serialization free of N+1 queries and trivially testable.


def _iso(dt: datetime | None) -> str | None:
    return dt.isoformat() if dt is not None else None


def member_json(user: User) -> dict:
    return {
        "id": user.id,
        "name": user.name,
        "email": user.email,
        "role": user.role,
    }


def invite_json(inv, inviter_name: str = "") -> dict:
    return {
        "id": inv.id,
        "organizationId": inv.organization_id,
        "email": inv.email,
        "role": inv.role,
        "status": inv.status,
        "invitedBy": inv.invited_by,
        "inviterName": inviter_name,
        "createdAt": _iso(inv.created_at),
        "expiresAt": _iso(inv.expires_at),
    }


def org_json(org: Organization, member_ids: list[str]) -> dict:
    return {
        "id": org.id,
        "name": org.name,
        "type": org.type,
        "color": org.color,
        "icon": org.icon,
        "ownerId": org.owner_id,
        "memberIds": member_ids,
    }


def workspace_json(ws: Workspace, member_ids: list[str]) -> dict:
    # A workspace is accessible to all members of its org.
    return {
        "id": ws.id,
        "organizationId": ws.organization_id,
        "name": ws.name,
        "description": ws.description,
        "color": ws.color,
        "icon": ws.icon,
        "memberIds": member_ids,
    }


def sprint_json(s: Sprint) -> dict:
    return {
        "id": s.id,
        "projectId": s.workspace_id,  # "project" == workspace on the frontend
        "name": s.name,
        "goal": s.goal,
        "startDate": _iso(s.start_date),
        "endDate": _iso(s.end_date),
        "status": s.status,
    }


def subtask_json(st: SubTask, children: list[SubTask]) -> dict:
    kids = [c for c in children if c.parent_subtask_id == st.id]
    kids.sort(key=lambda x: x.position)
    return {
        "id": st.id,
        "title": st.title,
        "description": st.description,
        "status": st.status,
        "priority": st.priority,
        "dueDate": _iso(st.due_date),
        "assigneeIds": [u.id for u in st.assignees],
        "subtasks": [subtask_json(c, children) for c in kids],
    }


def task_json(t: Task) -> dict:
    all_subs = list(t.subtasks)
    roots = [s for s in all_subs if s.parent_subtask_id is None]
    roots.sort(key=lambda x: x.position)
    return {
        "id": t.id,
        "projectId": t.workspace_id,
        "sprintId": t.sprint_id,
        "title": t.title,
        "description": t.description,
        "status": t.status,
        "priority": t.priority,
        "dueDate": _iso(t.due_date),
        "assigneeIds": [u.id for u in t.assignees],
        "createdAt": _iso(t.created_at),
        "subtasks": [subtask_json(s, all_subs) for s in roots],
    }


def activity_json(a) -> dict:
    return {
        "id": a.id,
        "kind": a.kind,
        "actorId": a.actor_id,
        "text": a.text,
        "taskTitle": a.task_title,
        "projectId": a.workspace_id,
        "taskId": a.task_id,
        "body": a.body,
        "timestamp": _iso(a.created_at),
    }
