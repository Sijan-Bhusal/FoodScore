from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text
from pydantic import BaseModel, EmailStr
from typing import Optional
from app.database import get_db
from app.services import auth_service

router = APIRouter(prefix="/auth", tags=["Authentication"])

class UserRegister(BaseModel):
    email: EmailStr
    username: str
    password: str
    full_name: Optional[str] = None

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class TokenResponse(BaseModel):
    access_token: str
    token_type: str
    user: dict

@router.post("/register", response_model=TokenResponse)
def register(user: UserRegister, db: Session = Depends(get_db)):
    try:
        # Check if user exists
        existing = db.execute(text(
            "SELECT user_id FROM users WHERE email = :email OR username = :username"
        ), {"email": user.email, "username": user.username}).fetchone()
        
        if existing:
            raise HTTPException(status_code=400, detail="Email or username already exists")
        
        # Create user
        new_user = auth_service.create_user(
            user.email, user.username, user.password, db, user.full_name
        )
        
        # Create token
        token = auth_service.create_access_token({
            "sub": new_user["email"], 
            "user_id": new_user["user_id"]
        })
        
        return {"user": new_user, "access_token": token, "token_type": "bearer"}
    
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

@router.post("/login", response_model=TokenResponse)
def login(user: UserLogin, db: Session = Depends(get_db)):
    try:
        authenticated = auth_service.authenticate_user(user.email, user.password, db)
        
        if not authenticated:
            raise HTTPException(status_code=401, detail="Invalid credentials")
        
        token = auth_service.create_access_token({
            "sub": authenticated["email"], 
            "user_id": authenticated["user_id"]
        })
        
        return {"user": authenticated, "access_token": token, "token_type": "bearer"}
    
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")