from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.user import User
from app.models.workspace import Workspace
from app.schemas.workspace import WorkspaceCreate, WorkspaceUpdate
from app.services import activity
from app.services.authz import require_org, require_workspace
from app.services.orgs import org_member_ids
from app.services.serializers import workspace_json

router = APIRouter(prefix="/workspaces", tags=["workspaces"])


@router.post("", status_code=status.HTTP_201_CREATED)
def create_workspace(
    payload: WorkspaceCreate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    require_org(db, user.id, payload.organizationId)
    ws = Workspace(
        organization_id=payload.organizationId,
        name=payload.name.strip(),
        description=payload.description,
        color=payload.color,
        icon=payload.icon,
    )
    db.add(ws)
    activity.log(
        db,
        organization_id=ws.organization_id,
        actor_id=user.id,
        kind="projectCreated",
        text="created workspace",
        workspace_id=ws.id,
        task_title=ws.name,
    )
    db.commit()
    return workspace_json(ws, org_member_ids(db, ws.organization_id))


@router.patch("/{workspace_id}")
def update_workspace(
    workspace_id: str,
    payload: WorkspaceUpdate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    ws = require_workspace(db, user.id, workspace_id)
    if payload.name is not None:
        ws.name = payload.name.strip()
    if payload.description is not None:
        ws.description = payload.description
    if payload.color is not None:
        ws.color = payload.color
    if payload.icon is not None:
        ws.icon = payload.icon
    db.commit()
    return workspace_json(ws, org_member_ids(db, ws.organization_id))


@router.delete("/{workspace_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_workspace(
    workspace_id: str,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    ws = require_workspace(db, user.id, workspace_id)
    db.delete(ws)
    db.commit()
