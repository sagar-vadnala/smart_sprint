from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.organization import Membership, Organization
from app.models.user import User
from app.schemas.workspace import AddMemberRequest, OrgCreate
from app.services.authz import require_org
from app.services.orgs import org_members
from app.services.serializers import member_json, org_json

router = APIRouter(prefix="/organizations", tags=["organizations"])


@router.get("")
def list_my_orgs(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    orgs = (
        db.query(Organization)
        .join(Membership, Membership.organization_id == Organization.id)
        .filter(Membership.user_id == user.id)
        .all()
    )
    return [org_json(db, o) for o in orgs]


@router.post("", status_code=status.HTTP_201_CREATED)
def create_org(
    payload: OrgCreate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    org = Organization(
        name=payload.name.strip(),
        type=payload.type,
        color=payload.color,
        icon=payload.icon,
        owner_id=user.id,
    )
    db.add(org)
    db.flush()
    db.add(Membership(organization_id=org.id, user_id=user.id, role="owner"))
    db.commit()
    return org_json(db, org)


@router.get("/{org_id}")
def get_org(
    org_id: str,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    org = require_org(db, user.id, org_id)
    return org_json(db, org)


@router.get("/{org_id}/members")
def list_members(
    org_id: str,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    require_org(db, user.id, org_id)
    return [member_json(m) for m in org_members(db, org_id)]


@router.post("/{org_id}/members", status_code=status.HTTP_201_CREATED)
def add_member(
    org_id: str,
    payload: AddMemberRequest,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    org = require_org(db, user.id, org_id)
    if org.type == "personal":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Personal organizations can't have other members.",
        )

    invitee = db.query(User).filter(User.email == payload.email.lower().strip()).first()
    if invitee is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No user with that email. They need to sign up first.",
        )

    existing = (
        db.query(Membership)
        .filter(Membership.organization_id == org_id, Membership.user_id == invitee.id)
        .first()
    )
    if existing is None:
        db.add(Membership(organization_id=org_id, user_id=invitee.id, role=payload.role))
        db.commit()

    return [member_json(m) for m in org_members(db, org_id)]
