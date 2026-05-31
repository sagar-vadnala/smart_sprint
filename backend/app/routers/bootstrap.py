"""
GET /bootstrap — one round-trip that returns everything the app needs on launch:
the user, all their organizations (+ member ids), the distinct members across
those orgs, and every workspace / sprint / task (+ nested subtasks) / activity
the user can see. The Flutter app holds this whole dataset and scopes it to the
current organization client-side, so switching orgs needs no extra request.
"""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.engagement import Activity
from app.models.organization import Membership, Organization
from app.models.sprint import Sprint
from app.models.task import Task
from app.models.user import User
from app.models.workspace import Workspace
from app.services.orgs import ensure_personal_org, member_ids_by_org
from app.services.serializers import (
    activity_json,
    member_json,
    org_json,
    sprint_json,
    task_json,
    workspace_json,
)

router = APIRouter(tags=["bootstrap"])


@router.get("/bootstrap")
def bootstrap(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    # Backfill a Personal org for accounts that predate the org tables.
    ensure_personal_org(db, user)

    org_ids = [
        r[0]
        for r in db.query(Membership.organization_id)
        .filter(Membership.user_id == user.id)
        .all()
    ]
    if not org_ids:
        return _empty(user)

    orgs = db.query(Organization).filter(Organization.id.in_(org_ids)).all()

    # ONE query for all member ids across my orgs; reused for orgs + workspaces.
    members_by_org = member_ids_by_org(db, org_ids)
    member_ids = {uid for ids in members_by_org.values() for uid in ids}
    members = (
        db.query(User).filter(User.id.in_(member_ids)).all() if member_ids else []
    )

    workspaces = db.query(Workspace).filter(
        Workspace.organization_id.in_(org_ids)
    ).all()
    ws_ids = [w.id for w in workspaces]

    sprints = (
        db.query(Sprint).filter(Sprint.workspace_id.in_(ws_ids)).all()
        if ws_ids
        else []
    )
    # selectin on Task.assignees/subtasks batches those loads automatically.
    tasks = (
        db.query(Task).filter(Task.workspace_id.in_(ws_ids)).all() if ws_ids else []
    )
    activities = (
        db.query(Activity)
        .filter(Activity.organization_id.in_(org_ids))
        .order_by(Activity.created_at.desc())
        .limit(200)
        .all()
    )

    return {
        "user": member_json(user),
        "organizations": [
            org_json(o, members_by_org.get(o.id, [])) for o in orgs
        ],
        "members": [member_json(m) for m in members],
        "workspaces": [
            workspace_json(w, members_by_org.get(w.organization_id, []))
            for w in workspaces
        ],
        "sprints": [sprint_json(s) for s in sprints],
        "tasks": [task_json(t) for t in tasks],
        "activities": [activity_json(a) for a in activities],
    }


def _empty(user: User) -> dict:
    return {
        "user": member_json(user),
        "organizations": [],
        "members": [member_json(user)],
        "workspaces": [],
        "sprints": [],
        "tasks": [],
        "activities": [],
    }
