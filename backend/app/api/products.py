from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from app.database import get_db
from app.schemas.product import ProductCreate
from app.services import product_service, score_service
from app.services.openfoodfacts import scan_barcode
from app.services.recommendations_service import get_recommendations
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

# Wildcard route must be LAST
@router.get("/{product_id}")
def get_product(product_id: str, db: Session = Depends(get_db)):
    row = product_service.get_product(product_id, db)
    if not row:
        raise HTTPException(status_code=404, detail="Product not found")
    return {
        "product_id": row[0], "name": row[1], "brand": row[2],
        "category": row[3], "image_url": row[4],
        "health_score": row[5], "is_harmful": row[6],
        "nova_group": row[7], "nutri_score": row[8], "nutriments": row[9],
        "additives": row[10], "suggestion": row[11],
        "flagged_ingredients": row[12],
        "traffic_light": score_service.get_traffic_light(row[5] or 0, row[6] or False)
    }

@router.get("/scan/{barcode}")
async def scan_barcode_endpoint(barcode: str, db: Session = Depends(get_db)):
    """Scan a product by barcode - checks local DB first, then OpenFoodFacts"""
    from app.services.openfoodfacts import scan_barcode
    
    try:
        result = await scan_barcode(barcode, db)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error scanning barcode: {str(e)}")
    
    if "error" in result:
        raise HTTPException(status_code=404, detail=result["error"])
    
    product_id = result.get("product_id")
    if not product_id:
        return result

    row = product_service.get_product(product_id, db)
    if not row:
        return result

    return {
        "source": result.get("source"),
        "product_id": row[0], "name": row[1], "brand": row[2],
        "category": row[3], "image_url": row[4],
        "health_score": row[5], "is_harmful": row[6],
        "nova_group": row[7], "nutri_score": row[8], "nutriments": row[9],
        "additives": row[10], "suggestion": row[11],
        "flagged_ingredients": row[12],
        "traffic_light": score_service.get_traffic_light(row[5] or 0, row[6] or False)
    }
