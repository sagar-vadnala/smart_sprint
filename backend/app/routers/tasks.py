from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.task import Task
from app.models.user import User
from app.models.workspace import Workspace
from app.schemas.workspace import TaskCreate, TaskUpdate
from app.services import activity
from app.services.authz import require_task, require_workspace
from app.services.orgs import org_member_ids
from app.services.serializers import task_json

router = APIRouter(prefix="/tasks", tags=["tasks"])


def _resolve_assignees(db: Session, org_id: str, user_ids: list[str]) -> list[User]:
    """Only allow assigning users who are members of the workspace's org."""
    if not user_ids:
        return []
    allowed = set(org_member_ids(db, org_id))
    valid = [uid for uid in user_ids if uid in allowed]
    if not valid:
        return []
    return db.query(User).filter(User.id.in_(valid)).all()


@router.get("/{task_id}")
def get_task(
    task_id: str,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    task = require_task(db, user.id, task_id)
    return task_json(task)


@router.post("", status_code=status.HTTP_201_CREATED)
def create_task(
    payload: TaskCreate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    ws = require_workspace(db, user.id, payload.projectId)
    task = Task(
        workspace_id=ws.id,
        sprint_id=payload.sprintId,
        title=payload.title.strip(),
        description=payload.description,
        status=payload.status,
        priority=payload.priority,
        due_date=payload.dueDate,
        created_by=user.id,
    )
    task.assignees = _resolve_assignees(db, ws.organization_id, payload.assigneeIds)
    db.add(task)
    activity.log(
        db,
        organization_id=ws.organization_id,
        actor_id=user.id,
        kind="taskCreated",
        text="created",
        workspace_id=ws.id,
        task_id=task.id,
        task_title=task.title,
    )
    db.commit()
    return task_json(task)


@router.patch("/{task_id}")
def update_task(
    task_id: str,
    payload: TaskUpdate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    task = require_task(db, user.id, task_id)
    ws = db.get(Workspace, task.workspace_id)
    org_id = ws.organization_id

    # Move to another workspace (must be in the same org; clears sprint).
    if payload.workspaceId is not None and payload.workspaceId != task.workspace_id:
        dest = require_workspace(db, user.id, payload.workspaceId)
        task.workspace_id = dest.id
        task.sprint_id = None
        org_id = dest.organization_id
        activity.log(
            db, organization_id=org_id, actor_id=user.id, kind="edited",
            text="moved this task", workspace_id=dest.id, task_id=task.id,
            task_title=task.title,
        )

    if payload.title is not None:
        task.title = payload.title.strip()
        activity.log(
            db, organization_id=org_id, actor_id=user.id, kind="edited",
            text="renamed this task", workspace_id=task.workspace_id,
            task_id=task.id, task_title=task.title,
        )
    if payload.description is not None:
        task.description = payload.description
    if payload.status is not None and payload.status != task.status:
        task.status = payload.status
        is_done = payload.status == "done"
        activity.log(
            db, organization_id=org_id, actor_id=user.id,
            kind="taskCompleted" if is_done else "statusChanged",
            text="completed" if is_done else "changed status",
            workspace_id=task.workspace_id, task_id=task.id, task_title=task.title,
        )
    if payload.priority is not None:
        task.priority = payload.priority

    if payload.clearSprint:
        task.sprint_id = None
    elif payload.sprintId is not None:
        task.sprint_id = payload.sprintId

    if payload.clearDueDate:
        task.due_date = None
    elif payload.dueDate is not None:
        task.due_date = payload.dueDate

    if payload.assigneeIds is not None:
        task.assignees = _resolve_assignees(db, org_id, payload.assigneeIds)
        activity.log(
            db, organization_id=org_id, actor_id=user.id, kind="taskAssigned",
            text="updated assignees on", workspace_id=task.workspace_id,
            task_id=task.id, task_title=task.title,
        )

    db.commit()
    return task_json(task)


@router.post("/{task_id}/duplicate", status_code=status.HTTP_201_CREATED)
def duplicate_task(
    task_id: str,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    src = require_task(db, user.id, task_id)
    ws = db.get(Workspace, src.workspace_id)
    copy = Task(
        workspace_id=src.workspace_id,
        sprint_id=src.sprint_id,
        title=f"{src.title} (copy)",
        description=src.description,
        status="todo",
        priority=src.priority,
        due_date=src.due_date,
        created_by=user.id,
    )
    copy.assignees = list(src.assignees)
    db.add(copy)
    activity.log(
        db, organization_id=ws.organization_id, actor_id=user.id,
        kind="taskCreated", text="duplicated", workspace_id=src.workspace_id,
        task_id=copy.id, task_title=copy.title,
    )
    db.commit()
    return task_json(copy)


@router.delete("/{task_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_task(
    task_id: str,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    task = require_task(db, user.id, task_id)
    db.delete(task)
    db.commit()
