"""
Pydantic request/response schemas for auth.

These define the JSON shapes the API accepts and returns. FastAPI validates
incoming requests against them automatically and documents them at /docs.
"""

from datetime import datetime

from pydantic import BaseModel, EmailStr, Field


class SignupRequest(BaseModel):
    name: str = Field(min_length=1, max_length=120)
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)


class LoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=1, max_length=128)


class UserOut(BaseModel):
    id: str
    name: str
    email: EmailStr
    role: str
    created_at: datetime

    # Allow building this straight from the SQLAlchemy ORM object.
    model_config = {"from_attributes": True}


class AuthResponse(BaseModel):
    """Returned by signup and login: the user plus their access token."""

    access_token: str
    token_type: str = "bearer"
    user: UserOut
