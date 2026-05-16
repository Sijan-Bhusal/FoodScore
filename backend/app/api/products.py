from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from app.database import get_db
from app.schemas.product import ProductCreate
from app.services import product_service, score_service
from app.services.openfoodfacts import scan_barcode
from app.services.recommendations_service import get_recommendations, get_better_alternatives

router = APIRouter(prefix="/products", tags=["Products"])

@router.post("/")
def add_product(product: ProductCreate, db: Session = Depends(get_db)):
    product_id = product_service.create_product(product.model_dump(), db)
    result = score_service.compute_score(product_id, db)
    return {"product_id": product_id, **result}

@router.get("/")
def list_products(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db)
):
    rows = product_service.list_products(db, skip, limit)
    return [
        {"product_id": r[0], "name": r[1], "brand": r[2],
         "health_score": r[3], "is_harmful": r[4]}
        for r in rows
    ]

# IMPORTANT: Specific routes BEFORE the {product_id} wildcard
@router.get("/recommendations")
def get_recommendations_endpoint(limit: int = 5, db: Session = Depends(get_db)):
    return get_recommendations(None, limit, db)

@router.get("/scan/{barcode}")
async def scan_barcode_endpoint(barcode: str, db: Session = Depends(get_db)):
    result = await scan_barcode(barcode, db)
    if "error" in result:
        raise HTTPException(status_code=404, detail=result["error"])
    return result

# Wildcard route must be LAST
@router.get("/{product_id}")
def get_product(product_id: str, db: Session = Depends(get_db)):
    row = product_service.get_product(product_id, db)
    if not row:
        raise HTTPException(status_code=404, detail="Product not found")
    return {
        "product_id": row[0], "name": row[1], "brand": row[2],
        "category": row[3], "health_score": row[4], "is_harmful": row[5],
        "nova_group": row[6], "nutri_score": row[7], "nutriments": row[8],
        "additives": row[9], "suggestion": row[10],
        "flagged_ingredients": row[11],
        "traffic_light": score_service.get_traffic_light(row[4] or 0, row[5] or False)
    }

@router.get("/{product_id}/alternatives")
def get_alternatives(product_id: str, db: Session = Depends(get_db)):
    return {"alternatives": get_better_alternatives(product_id, db)}