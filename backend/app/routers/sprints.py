from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.sprint import Sprint
from app.models.user import User
from app.schemas.workspace import SprintCreate, SprintUpdate
from app.services import activity
from app.services.authz import require_sprint, require_workspace
from app.services.serializers import sprint_json

router = APIRouter(prefix="/sprints", tags=["sprints"])


@router.post("", status_code=status.HTTP_201_CREATED)
def create_sprint(
    payload: SprintCreate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    ws = require_workspace(db, user.id, payload.projectId)
    sprint = Sprint(
        workspace_id=ws.id,
        name=payload.name.strip(),
        goal=payload.goal,
        start_date=payload.startDate,
        end_date=payload.endDate,
        status="planned",
    )
    db.add(sprint)
    activity.log(
        db,
        organization_id=ws.organization_id,
        actor_id=user.id,
        kind="sprintCreated",
        text="created sprint",
        workspace_id=ws.id,
        task_title=sprint.name,
    )
    db.commit()
    return sprint_json(sprint)


@router.patch("/{sprint_id}")
def update_sprint(
    sprint_id: str,
    payload: SprintUpdate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    sprint = require_sprint(db, user.id, sprint_id)
    if payload.name is not None:
        sprint.name = payload.name.strip()
    if payload.goal is not None:
        sprint.goal = payload.goal
    if payload.startDate is not None:
        sprint.start_date = payload.startDate
    if payload.endDate is not None:
        sprint.end_date = payload.endDate
    if payload.status is not None:
        sprint.status = payload.status
    db.commit()
    return sprint_json(sprint)


@router.delete("/{sprint_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_sprint(
    sprint_id: str,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    sprint = require_sprint(db, user.id, sprint_id)
    db.delete(sprint)
    db.commit()
