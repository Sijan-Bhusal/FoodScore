from fastapi import APIRouter, Depends, HTTPException, status
from google.oauth2 import id_token
from google.auth.transport import requests as google_requests
from sqlalchemy.orm import Session

from app.config import GOOGLE_CLIENT_ID
from app.database import get_db
from app.models.user import User
from app.schemas.auth import (
    GoogleAuthRequest,
    TokenResponse,
    RefreshTokenRequest,
    UserOut,
    RegisterRequest,
    LoginRequest,
)
from app.services import auth_service
from app.api.deps import get_current_user

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/google", response_model=TokenResponse)
def auth_google(req: GoogleAuthRequest, db: Session = Depends(get_db)):
    try:
        info = id_token.verify_oauth2_token(
            req.id_token,
            google_requests.Request(),
            GOOGLE_CLIENT_ID,
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid Google ID token: {e}",
        )

    user = auth_service.authenticate_or_create_google_user(db, info)
    return _token_response(user)


@router.post("/register", response_model=TokenResponse)
def register(req: RegisterRequest, db: Session = Depends(get_db)):
    try:
        user = auth_service.register_user(db, req.username, req.email, req.password)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=str(e))
    return _token_response(user)


@router.post("/login", response_model=TokenResponse)
def login(req: LoginRequest, db: Session = Depends(get_db)):
    user = auth_service.authenticate_email_password(db, req.email, req.password)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        )
    return _token_response(user)


@router.post("/refresh", response_model=TokenResponse)
def refresh(req: RefreshTokenRequest, db: Session = Depends(get_db)):
    payload = auth_service.decode_token(req.refresh_token)
    if payload is None or payload.get("type") != "refresh":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired refresh token",
        )
    user = auth_service.get_user_by_id(db, payload["sub"])
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found",
        )
    return _token_response(user)


@router.get("/me", response_model=UserOut)
def get_me(current_user: User = Depends(get_current_user)):
    return current_user


def _token_response(user: User) -> TokenResponse:
    user_id_str = str(user.user_id)
    return TokenResponse(
        access_token=auth_service.create_access_token(user_id_str),
        refresh_token=auth_service.create_refresh_token(user_id_str),
    )
