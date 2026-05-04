from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.database import get_db

router = APIRouter(prefix="/search", tags=["Search"])

@router.get("/")
def search_products(
    q: str = Query(..., min_length=1, description="Search by product name or brand"),
    db: Session = Depends(get_db)
):
    rows = db.execute(text("""
        SELECT product_id, name, brand, health_score, is_harmful
        FROM products
        WHERE name ILIKE :query OR brand ILIKE :query
        ORDER BY health_score DESC
        LIMIT 20
    """), {"query": f"%{q}%"}).fetchall()
    
    return [
        {"product_id": r[0], "name": r[1], "brand": r[2],
         "health_score": r[3], "is_harmful": r[4]}
        for r in rows
    ]