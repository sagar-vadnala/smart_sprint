"""
Organization invitations — the real "invite a teammate" flow.

Flow:
  1. An owner/admin POSTs an email to /organizations/{id}/invites.
  2. We create an Invitation row + email the invitee a tokenised accept link.
     (If SMTP isn't configured, the link is returned in the response so the
     admin can share it manually — the flow still works end-to-end.)
  3. The invitee opens the link, signs up / logs in, and POSTs to
     /invites/{token}/accept — which creates their Membership and drops them
     into the organization.

Unlike the legacy /members endpoint, the invitee does NOT need an account first.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.invitation import Invitation
from app.models.organization import Membership, Organization
from app.models.user import User
from app.schemas.workspace import InviteCreate
from app.services.authz import require_org, require_role
from app.services.email import invite_email_html, send_email
from app.services.orgs import org_member_ids
from app.services.serializers import invite_json, org_json

router = APIRouter(tags=["invitations"])


def _accept_url(token: str) -> str:
    # Flutter web uses fragment (hash) routing, so the path lives after '#'.
    base = settings.app_base_url.rstrip("/")
    return f"{base}/#/invite/{token}"


def _is_member_email(db: Session, org_id: str, email: str) -> bool:
    return (
        db.query(Membership)
        .join(User, User.id == Membership.user_id)
        .filter(Membership.organization_id == org_id, User.email == email)
        .first()
        is not None
    )


# ── Admin: manage invites for an org ──────────────────────────────────────────


@router.post("/organizations/{org_id}/invites", status_code=status.HTTP_201_CREATED)
def create_invite(
    org_id: str,
    payload: InviteCreate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    # Only owners/admins of a TEAM org may invite.
    org = require_role(db, user.id, org_id, {"owner", "admin"})
    if org.type == "personal":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Personal organizations can't have other members.",
        )

    email = payload.email.lower().strip()

    if _is_member_email(db, org_id, email):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="That person is already a member of this organization.",
        )

    # Reuse an existing pending invite for this email (refresh it) instead of
    # piling up duplicates.
    invite = (
        db.query(Invitation)
        .filter(
            Invitation.organization_id == org_id,
            Invitation.email == email,
            Invitation.status == "pending",
        )
        .first()
    )
    if invite is None:
        invite = Invitation(
            organization_id=org_id,
            email=email,
            role=payload.role,
            invited_by=user.id,
        )
        db.add(invite)
    else:
        invite.role = payload.role  # allow changing the offered role
    db.commit()
    db.refresh(invite)

    accept_url = _accept_url(invite.token)
    email_sent = send_email(
        to=email,
        subject=f"You're invited to join {org.name} on SmartSprint",
        html_body=invite_email_html(
            org_name=org.name,
            inviter_name=user.name or "A teammate",
            accept_url=accept_url,
        ),
    )

    return {
        "invite": invite_json(invite, inviter_name=user.name),
        "acceptUrl": accept_url,
        "emailSent": email_sent,
    }


@router.get("/organizations/{org_id}/invites")
def list_invites(
    org_id: str,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    require_role(db, user.id, org_id, {"owner", "admin"})
    invites = (
        db.query(Invitation)
        .filter(Invitation.organization_id == org_id, Invitation.status == "pending")
        .order_by(Invitation.created_at.desc())
        .all()
    )
    return [invite_json(i) for i in invites]


@router.delete(
    "/organizations/{org_id}/invites/{invite_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
def revoke_invite(
    org_id: str,
    invite_id: str,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    require_role(db, user.id, org_id, {"owner", "admin"})
    invite = db.get(Invitation, invite_id)
    if invite is None or invite.organization_id != org_id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Invitation not found."
        )
    if invite.status == "pending":
        invite.status = "revoked"
        db.commit()
    return None


# ── Invitee: preview + accept (token-based) ───────────────────────────────────


@router.get("/invites/{token}")
def preview_invite(token: str, db: Session = Depends(get_db)):
    """Public preview so the accept screen can show who invited you, before you
    even log in. Returns just enough to render the invitation."""
    invite = db.query(Invitation).filter(Invitation.token == token).first()
    if invite is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="This invitation link is invalid.",
        )

    org = db.get(Organization, invite.organization_id)
    inviter = db.get(User, invite.invited_by)

    state = invite.status
    if state == "pending" and invite.is_expired():
        state = "expired"

    return {
        "email": invite.email,
        "role": invite.role,
        "status": state,
        "organizationId": invite.organization_id,
        "organizationName": org.name if org else "an organization",
        "inviterName": inviter.name if inviter else "A teammate",
    }


@router.post("/invites/{token}/accept")
def accept_invite(
    token: str,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    invite = db.query(Invitation).filter(Invitation.token == token).first()
    if invite is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="This invitation link is invalid.",
        )

    if invite.status == "revoked":
        raise HTTPException(
            status_code=status.HTTP_410_GONE,
            detail="This invitation has been revoked.",
        )
    if invite.status == "accepted":
        # Idempotent-ish: if THIS user already accepted, just return the org.
        if invite.accepted_user_id == user.id:
            return org_json(invite.organization, org_member_ids(db, invite.organization_id))
        raise HTTPException(
            status_code=status.HTTP_410_GONE,
            detail="This invitation has already been used.",
        )
    if invite.is_expired():
        invite.status = "expired"
        db.commit()
        raise HTTPException(
            status_code=status.HTTP_410_GONE,
            detail="This invitation has expired. Ask for a new one.",
        )

    # The invite is addressed to a specific email — make sure the right person
    # is accepting it.
    if user.email.lower().strip() != invite.email.lower().strip():
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=(
                f"This invitation was sent to {invite.email}. "
                "Sign in with that email to accept it."
            ),
        )

    # Create the membership if they aren't already in (defensive).
    existing = (
        db.query(Membership)
        .filter(
            Membership.organization_id == invite.organization_id,
            Membership.user_id == user.id,
        )
        .first()
    )
    if existing is None:
        db.add(
            Membership(
                organization_id=invite.organization_id,
                user_id=user.id,
                role=invite.role,
            )
        )

    from app.models.common import utcnow

    invite.status = "accepted"
    invite.accepted_at = utcnow()
    invite.accepted_user_id = user.id
    db.commit()

    org = db.get(Organization, invite.organization_id)
    return org_json(org, org_member_ids(db, invite.organization_id))
