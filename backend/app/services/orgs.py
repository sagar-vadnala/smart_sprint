"""Organization-related operations shared across routers."""

from sqlalchemy.orm import Session

from app.models.organization import Membership, Organization
from app.models.user import User


def create_personal_org(db: Session, user: User) -> Organization:
    """Every new user gets a private 'Personal' org with themselves as owner."""
    org = Organization(
        name="Personal",
        type="personal",
        color=0xFF6C47FF,
        icon="person",
        owner_id=user.id,
    )
    db.add(org)
    db.flush()  # assign org.id
    db.add(Membership(organization_id=org.id, user_id=user.id, role="owner"))
    return org


def ensure_personal_org(db: Session, user: User) -> None:
    """Idempotent backfill: give the user a Personal org if they belong to none.

    Covers accounts created before the org tables existed.
    """
    has_any = (
        db.query(Membership).filter(Membership.user_id == user.id).first() is not None
    )
    if not has_any:
        create_personal_org(db, user)
        db.commit()


def org_member_ids(db: Session, org_id: str) -> list[str]:
    rows = db.query(Membership.user_id).filter(Membership.organization_id == org_id).all()
    return [r[0] for r in rows]


def org_members(db: Session, org_id: str) -> list[User]:
    return (
        db.query(User)
        .join(Membership, Membership.user_id == User.id)
        .filter(Membership.organization_id == org_id)
        .all()
    )
