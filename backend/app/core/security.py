"""
Password hashing (bcrypt) and JWT creation/verification.

We use the `bcrypt` library directly (no passlib) to avoid version-mismatch
warnings, and PyJWT for tokens. This is intentionally small so you can read
every line and understand exactly how auth works.
"""

from datetime import datetime, timedelta, timezone

import bcrypt
import jwt

from app.core.config import settings


# ── Passwords ─────────────────────────────────────────────────────────────────

def hash_password(plain: str) -> str:
    """Hash a plaintext password. The salt is stored inside the hash itself."""
    return bcrypt.hashpw(plain.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")


def verify_password(plain: str, hashed: str) -> bool:
    try:
        return bcrypt.checkpw(plain.encode("utf-8"), hashed.encode("utf-8"))
    except ValueError:
        # Malformed hash in the DB — treat as a failed check, never crash.
        return False


# ── JWT access tokens ─────────────────────────────────────────────────────────

def create_access_token(subject: str) -> str:
    """`subject` is the user id we encode into the token (the `sub` claim)."""
    now = datetime.now(timezone.utc)
    expire = now + timedelta(minutes=settings.access_token_expire_minutes)
    payload = {
        "sub": subject,
        "iat": int(now.timestamp()),
        "exp": int(expire.timestamp()),
    }
    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)


def decode_access_token(token: str) -> str | None:
    """Return the user id (`sub`) if the token is valid, else None."""
    try:
        payload = jwt.decode(
            token,
            settings.jwt_secret,
            algorithms=[settings.jwt_algorithm],
        )
        return payload.get("sub")
    except jwt.PyJWTError:
        return None
