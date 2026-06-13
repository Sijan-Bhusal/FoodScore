import uuid

from pydantic import BaseModel, EmailStr, field_validator
from typing import Optional
from datetime import datetime


class GoogleAuthRequest(BaseModel):
    id_token: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int = 3600
    user: UserOut


class RefreshTokenRequest(BaseModel):
    refresh_token: str


class UserOut(BaseModel):
    user_id: str
    username: str
    email: str
    display_name: Optional[str] = None
    avatar_url: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True

    @field_validator("user_id", mode="before")
    @classmethod
    def validate_user_id(cls, v):
        if isinstance(v, uuid.UUID):
            return str(v)
        return v


class UserUpdate(BaseModel):
    display_name: Optional[str] = None
    avatar_url: Optional[str] = None


class RegisterRequest(BaseModel):
    username: str
    email: EmailStr
    password: str


class LoginRequest(BaseModel):
    email: EmailStr
    password: str
