"""
Authorization helpers — every data endpoint funnels through these so the rule
"you may only touch rows inside an org you're a member of" is enforced in one
place rather than copy-pasted.
"""

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.organization import Membership, Organization
from app.models.sprint import Sprint
from app.models.task import Task
from app.models.workspace import Workspace


def user_org_ids(db: Session, user_id: str) -> list[str]:
    rows = db.query(Membership.organization_id).filter(Membership.user_id == user_id).all()
    return [r[0] for r in rows]


def is_member(db: Session, user_id: str, org_id: str) -> bool:
    return (
        db.query(Membership)
        .filter(Membership.organization_id == org_id, Membership.user_id == user_id)
        .first()
        is not None
    )


def _forbid() -> HTTPException:
    return HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not allowed.")


def _missing(what: str) -> HTTPException:
    return HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"{what} not found.")


def require_org(db: Session, user_id: str, org_id: str) -> Organization:
    org = db.get(Organization, org_id)
    if org is None:
        raise _missing("Organization")
    if not is_member(db, user_id, org_id):
        raise _forbid()
    return org


def require_workspace(db: Session, user_id: str, workspace_id: str) -> Workspace:
    ws = db.get(Workspace, workspace_id)
    if ws is None:
        raise _missing("Workspace")
    if not is_member(db, user_id, ws.organization_id):
        raise _forbid()
    return ws


def require_sprint(db: Session, user_id: str, sprint_id: str) -> Sprint:
    sprint = db.get(Sprint, sprint_id)
    if sprint is None:
        raise _missing("Sprint")
    require_workspace(db, user_id, sprint.workspace_id)
    return sprint


def require_task(db: Session, user_id: str, task_id: str) -> Task:
    task = db.get(Task, task_id)
    if task is None:
        raise _missing("Task")
    require_workspace(db, user_id, task.workspace_id)
    return task
