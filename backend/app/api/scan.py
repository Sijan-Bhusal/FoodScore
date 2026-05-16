from fastapi import APIRouter, Depends, HTTPException, Header
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional
from app.database import get_db
from app.services import scan_history_service, auth_service

class ScanHistoryCreate(BaseModel):
    product_id: Optional[str] = None
    barcode: Optional[str] = None
    score: Optional[int] = None

router = APIRouter(prefix="/scan", tags=["Scan History"])

@router.post("/history")
def save_scan(
    scan_data: ScanHistoryCreate,
    authorization: str = Header(None),
    db: Session = Depends(get_db)
):
    if not authorization:
        raise HTTPException(status_code=401, detail="Token required")
    
    token = authorization.replace("Bearer ", "")
    payload = auth_service.verify_token(token)
    if not payload:
        raise HTTPException(status_code=401, detail="Invalid token")
    
    user_id = payload.get("user_id")
    
    product_id = scan_data.product_id
    barcode = scan_data.barcode
    score = scan_data.score
    
    # Validate: must have either product_id OR barcode, not both, not neither
    if not product_id and not barcode:
        raise HTTPException(status_code=400, detail="Either product_id or barcode is required")
    
    if product_id and barcode:
        raise HTTPException(status_code=400, detail="Cannot provide both product_id and barcode")
    
    scan_id = scan_history_service.save_scan(user_id, db, product_id, barcode, score)
    
    if scan_id is None:
        raise HTTPException(status_code=500, detail="Failed to save scan")
    
    return {"scan_id": scan_id, "message": "Scan saved successfully"}

@router.get("/history")
def get_history(limit: int = 20, authorization: str = Header(None), db: Session = Depends(get_db)):
    if not authorization:
        raise HTTPException(status_code=401, detail="Token required")
    
    token = authorization.replace("Bearer ", "")
    payload = auth_service.verify_token(token)
    if not payload:
        raise HTTPException(status_code=401, detail="Invalid token")
    
    # Fixed: user_id, db, limit (not user_id, limit, db)
    scans = scan_history_service.get_user_scans(payload["user_id"], db, limit)
    return {"scans": scans}

@router.get("/recent")
def get_recent_scans(limit: int = 10, db: Session = Depends(get_db)):
    scans = scan_history_service.get_recent_scans(limit, db)
    return {"scans": scans}