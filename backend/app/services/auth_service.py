import uuid
from datetime import datetime, timedelta, timezone
from typing import Optional

from jose import JWTError, jwt
from passlib.context import CryptContext
from sqlalchemy.orm import Session

from app.config import SECRET_KEY, GOOGLE_CLIENT_ID
from app.models.user import User

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60
REFRESH_TOKEN_EXPIRE_DAYS = 30


def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)


def create_access_token(user_id: str) -> str:
    expire = datetime.now(timezone.utc) + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    payload = {"sub": user_id, "exp": expire, "type": "access"}
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)


def create_refresh_token(user_id: str) -> str:
    expire = datetime.now(timezone.utc) + timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS)
    payload = {"sub": user_id, "exp": expire, "type": "refresh"}
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)


def decode_token(token: str) -> Optional[dict]:
    try:
        return jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
    except JWTError:
        return None


def get_user_by_email(db: Session, email: str) -> Optional[User]:
    return db.query(User).filter(User.email == email).first()


def get_user_by_google_id(db: Session, google_id: str) -> Optional[User]:
    return db.query(User).filter(User.google_id == google_id).first()


def get_user_by_id(db: Session, user_id: str) -> Optional[User]:
    try:
        uid = uuid.UUID(user_id)
    except ValueError:
        return None
    return db.query(User).filter(User.user_id == uid).first()


def create_user(
    db: Session,
    username: str,
    email: str,
    google_id: Optional[str] = None,
    display_name: Optional[str] = None,
    avatar_url: Optional[str] = None,
    password_hash: Optional[str] = None,
) -> User:
    user = User(
        username=username,
        email=email,
        google_id=google_id,
        display_name=display_name or username,
        avatar_url=avatar_url,
        password_hash=password_hash,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def authenticate_or_create_google_user(db: Session, id_token: dict) -> User:
    google_id = id_token["sub"]
    email = id_token.get("email", "")
    name = id_token.get("name", email.split("@")[0])
    picture = id_token.get("picture")

    user = get_user_by_google_id(db, google_id)
    if user:
        return user

    user = get_user_by_email(db, email)
    if user:
        user.google_id = google_id
        user.display_name = user.display_name or name
        user.avatar_url = user.avatar_url or picture
        db.commit()
        db.refresh(user)
        return user

    base_username = email.split("@")[0]
    username = base_username
    suffix = 1
    while db.query(User).filter(User.username == username).first():
        username = f"{base_username}{suffix}"
        suffix += 1

    return create_user(
        db=db,
        username=username,
        email=email,
        google_id=google_id,
        display_name=name,
        avatar_url=picture,
    )


def register_user(db: Session, username: str, email: str, password: str) -> User:
    if get_user_by_email(db, email):
        raise ValueError("Email already registered")

    if db.query(User).filter(User.username == username).first():
        raise ValueError("Username already taken")

    return create_user(
        db=db,
        username=username,
        email=email,
        password_hash=hash_password(password),
    )


def authenticate_email_password(db: Session, email: str, password: str) -> Optional[User]:
    user = get_user_by_email(db, email)
    if not user or not user.password_hash:
        return None
    if not verify_password(password, user.password_hash):
        return None
    return user
