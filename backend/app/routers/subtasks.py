from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.task import SubTask, Task
from app.models.user import User
from app.models.workspace import Workspace
from app.schemas.workspace import SubTaskCreate, SubTaskUpdate
from app.services.authz import require_task
from app.services.orgs import org_member_ids
from app.services.serializers import task_json

router = APIRouter(prefix="/tasks/{task_id}/subtasks", tags=["subtasks"])


def _require_subtask(db: Session, user: User, task_id: str, subtask_id: str):
    task = require_task(db, user.id, task_id)  # authz on the parent task
    sub = db.get(SubTask, subtask_id)
    if sub is None or sub.task_id != task_id:
        raise HTTPException(status_code=404, detail="Subtask not found.")
    return task, sub


def _resolve_assignees(db: Session, org_id: str, ids: list[str]) -> list[User]:
    allowed = set(org_member_ids(db, org_id))
    valid = [i for i in ids if i in allowed]
    return db.query(User).filter(User.id.in_(valid)).all() if valid else []


@router.post("", status_code=status.HTTP_201_CREATED)
def add_subtask(
    task_id: str,
    payload: SubTaskCreate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    task = require_task(db, user.id, task_id)

    if payload.parentSubTaskId is not None:
        parent = db.get(SubTask, payload.parentSubTaskId)
        if parent is None or parent.task_id != task_id:
            raise HTTPException(status_code=404, detail="Parent subtask not found.")

    next_pos = (
        db.query(func.coalesce(func.max(SubTask.position), -1))
        .filter(SubTask.task_id == task_id)
        .scalar()
        + 1
    )
    sub = SubTask(
        task_id=task_id,
        parent_subtask_id=payload.parentSubTaskId,
        title=payload.title.strip(),
        position=next_pos,
    )
    db.add(sub)
    db.commit()
    db.refresh(task)
    return task_json(task)


@router.patch("/{subtask_id}")
def update_subtask(
    task_id: str,
    subtask_id: str,
    payload: SubTaskUpdate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    task, sub = _require_subtask(db, user, task_id, subtask_id)
    ws = db.get(Workspace, task.workspace_id)

    if payload.title is not None:
        sub.title = payload.title.strip()
    if payload.description is not None:
        sub.description = payload.description
    if payload.status is not None:
        sub.status = payload.status
    if payload.clearPriority:
        sub.priority = None
    elif payload.priority is not None:
        sub.priority = payload.priority
    if payload.clearDueDate:
        sub.due_date = None
    elif payload.dueDate is not None:
        sub.due_date = payload.dueDate
    if payload.assigneeIds is not None:
        sub.assignees = _resolve_assignees(db, ws.organization_id, payload.assigneeIds)

    db.commit()
    db.refresh(task)
    return task_json(task)


@router.delete("/{subtask_id}")
def delete_subtask(
    task_id: str,
    subtask_id: str,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    task, sub = _require_subtask(db, user, task_id, subtask_id)
    db.delete(sub)  # cascade removes nested children
    db.commit()
    db.refresh(task)
    return task_json(task)
