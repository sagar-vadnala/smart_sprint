"""Helper to append an activity-feed entry."""

from sqlalchemy.orm import Session

from app.models.engagement import Activity


def log(
    db: Session,
    *,
    organization_id: str,
    actor_id: str,
    kind: str,
    text: str,
    workspace_id: str | None = None,
    task_id: str | None = None,
    task_title: str | None = None,
    body: str | None = None,
) -> Activity:
    act = Activity(
        organization_id=organization_id,
        workspace_id=workspace_id,
        task_id=task_id,
        actor_id=actor_id,
        kind=kind,
        text=text,
        task_title=task_title,
        body=body,
    )
    db.add(act)
    return act
