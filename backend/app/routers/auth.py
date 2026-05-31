"""
Auth endpoints:
  POST /auth/signup  — create an account, return a token + user
  POST /auth/login   — verify credentials, return a token + user
  GET  /auth/me      — return the currently authenticated user
"""

from fastapi import APIRouter, Depends, HTTPException, status
import requests as http_requests
from google.auth.transport import requests as google_requests
from google.oauth2 import id_token as google_id_token
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.database import get_db
from app.core.deps import get_current_user
from app.core.security import (
    create_access_token,
    hash_password,
    verify_password,
)
from app.models.user import User
from app.schemas.auth import (
    AuthResponse,
    GoogleLoginRequest,
    LoginRequest,
    SignupRequest,
    UserOut,
)
from app.services.orgs import create_personal_org

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/signup", response_model=AuthResponse, status_code=status.HTTP_201_CREATED)
def signup(payload: SignupRequest, db: Session = Depends(get_db)) -> AuthResponse:
    email = payload.email.lower().strip()

    existing = db.query(User).filter(User.email == email).first()
    if existing is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="An account with this email already exists.",
        )

    user = User(
        email=email,
        name=payload.name.strip(),
        password_hash=hash_password(payload.password),
        role="Product Manager",
    )
    db.add(user)
    db.flush()  # assign user.id before creating their org

    # Every new account starts with a private Personal organization.
    create_personal_org(db, user)

    db.commit()
    db.refresh(user)

    token = create_access_token(subject=user.id)
    return AuthResponse(access_token=token, user=UserOut.model_validate(user))


@router.post("/login", response_model=AuthResponse)
def login(payload: LoginRequest, db: Session = Depends(get_db)) -> AuthResponse:
    email = payload.email.lower().strip()
    user = db.query(User).filter(User.email == email).first()

    # Same error for "no such user" and "wrong password" — don't leak which
    # emails are registered.
    if user is None or not verify_password(payload.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password.",
        )

    token = create_access_token(subject=user.id)
    return AuthResponse(access_token=token, user=UserOut.model_validate(user))


@router.post("/google", response_model=AuthResponse)
def google_login(payload: GoogleLoginRequest, db: Session = Depends(get_db)) -> AuthResponse:
    """Sign in with a Google credential.

    Mobile sends an `id_token` (verified cryptographically).
    Web (google_sign_in popup flow) sends an `access_token` — we call
    Google's userinfo API to get the user details.
    """
    if not settings.google_client_id:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Google sign-in is not configured on the server.",
        )

    if not payload.id_token and not payload.access_token:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Provide either id_token or access_token.",
        )

    # ── Path 1: id_token (mobile) ─────────────────────────────────────────────
    if payload.id_token:
        try:
            info = google_id_token.verify_oauth2_token(
                payload.id_token,
                google_requests.Request(),
                settings.google_client_id,
            )
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Could not verify your Google sign-in. Please try again.",
            )
        email = (info.get("email") or "").lower().strip()
        name = info.get("name") or ""

    # ── Path 2: access_token (web fallback) ───────────────────────────────────
    else:
        resp = http_requests.get(
            "https://www.googleapis.com/oauth2/v3/userinfo",
            headers={"Authorization": f"Bearer {payload.access_token}"},
            timeout=10,
        )
        if resp.status_code != 200:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Could not verify your Google sign-in. Please try again.",
            )
        info = resp.json()
        email = (info.get("email") or "").lower().strip()
        name = info.get("name") or ""

    if not email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Your Google account has no email.",
        )

    user = db.query(User).filter(User.email == email).first()
    if user is None:
        user = User(
            email=email,
            name=name or email.split("@")[0],
            password_hash="",
            role="Product Manager",
        )
        db.add(user)
        db.flush()
        create_personal_org(db, user)
        db.commit()
        db.refresh(user)

    token = create_access_token(subject=user.id)
    return AuthResponse(access_token=token, user=UserOut.model_validate(user))


@router.get("/me", response_model=UserOut)
def me(current_user: User = Depends(get_current_user)) -> UserOut:
    return UserOut.model_validate(current_user)
