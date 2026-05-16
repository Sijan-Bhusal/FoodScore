import uuid
import jwt
import os
import bcrypt
from datetime import datetime, timedelta, timezone
from sqlalchemy.orm import Session
from sqlalchemy import text
from typing import Optional, Dict, Any

SECRET_KEY = os.getenv("SECRET_KEY", "your-secret-key-change-in-production")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24 * 7  # 7 days

def hash_password(password: str) -> str:
    if not password:
        raise ValueError("Password cannot be empty")
    password_bytes = password.encode("utf-8")[:72]
    salt = bcrypt.gensalt(rounds=12)
    return bcrypt.hashpw(password_bytes, salt).decode("utf-8")

def verify_password(plain: str, hashed: str) -> bool:
    if not plain or not hashed:
        return False
    plain_bytes = plain.encode("utf-8")[:72]
    return bcrypt.checkpw(plain_bytes, hashed.encode("utf-8"))

def create_user(email: str, username: str, password: str, db: Session, full_name: Optional[str] = None) -> Dict[str, Any]:
    user_id = str(uuid.uuid4())
    hashed = hash_password(password)
    try:
        db.execute(text("""
            INSERT INTO users (user_id, email, username, password_hash, full_name)
            VALUES (:uid, :email, :username, :pwd, :name)
        """), {"uid": user_id, "email": email, "username": username, "pwd": hashed, "name": full_name})
        db.commit()
    except Exception as e:
        db.rollback()
        raise ValueError(f"Failed to create user: {str(e)}")
    return {"user_id": user_id, "email": email, "username": username}

def authenticate_user(email: str, password: str, db: Session) -> Optional[Dict[str, Any]]:
    try:
        row = db.execute(text("""
            SELECT user_id, email, username, password_hash, full_name
            FROM users WHERE email = :email
        """), {"email": email}).fetchone()
    except Exception as e:
        raise ValueError(f"Database error: {str(e)}")
    if not row:
        return None
    if not verify_password(password, row[3]):
        return None
    return {
        "user_id": row[0],
        "email": row[1],
        "username": row[2],
        "full_name": row[4]
    }

def create_access_token(data: dict) -> str:
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

def verify_token(token: str) -> Optional[Dict[str, Any]]:
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except jwt.ExpiredSignatureError:
        return None
    except jwt.InvalidTokenError:
        return None
    except Exception:
        return None