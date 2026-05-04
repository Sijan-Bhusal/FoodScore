from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.services.score_service import compute_score

router = APIRouter(prefix="/score", tags=["Score"])

@router.post("/{product_id}")
def rescore_product(product_id: str, db: Session = Depends(get_db)):
    result = compute_score(product_id, db)
    if "error" in result:
        raise HTTPException(status_code=404, detail=result["error"])
    return result