from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.user import User
from app.models.workspace import Workspace
from app.schemas.workspace import CommentCreate
from app.services import activity
from app.services.authz import require_task
from app.services.serializers import activity_json

router = APIRouter(prefix="/tasks/{task_id}/comments", tags=["comments"])


@router.post("", status_code=status.HTTP_201_CREATED)
def add_comment(
    task_id: str,
    payload: CommentCreate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    # Comments surface in the activity timeline (kind=comment), matching the app.
    task = require_task(db, user.id, task_id)
    ws = db.get(Workspace, task.workspace_id)
    act = activity.log(
        db,
        organization_id=ws.organization_id,
        actor_id=user.id,
        kind="comment",
        text="commented",
        workspace_id=task.workspace_id,
        task_id=task.id,
        task_title=task.title,
        body=payload.body.strip(),
    )
    db.commit()
    db.refresh(act)
    return activity_json(act)
