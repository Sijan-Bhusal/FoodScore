import httpx
from sqlalchemy.orm import Session
from app.services.product_service import create_product
from app.services.score_service import compute_score

async def fetch_from_openfoodfacts(barcode: str) -> dict | None:
    """Fetch product data from OpenFoodFacts API"""
    url = f"https://world.openfoodfacts.org/api/v2/product/{barcode}.json"
    
    async with httpx.AsyncClient() as client:
        response = await client.get(url)
        
        if response.status_code != 200:
            return None
        
        data = response.json()
        
        if data.get("status") != 1:
            return None
        
        product = data["product"]
        
        # Extract relevant data
        return {
            "barcode": barcode,
            "name": product.get("product_name", "Unknown"),
            "brand": product.get("brands", "").split(",")[0] if product.get("brands") else None,
            "category": product.get("categories", "").split(",")[0] if product.get("categories") else None,
            "ingredients_raw": product.get("ingredients_text", ""),
            "additives": [a.replace("en:", "") for a in product.get("additives_tags", []) if a],
            "nutriments": {
                "sugars_100g": product.get("nutriments", {}).get("sugars_100g", 0),
                "saturated_fat_100g": product.get("nutriments", {}).get("saturated-fat_100g", 0),
                "salt_100g": product.get("nutriments", {}).get("salt_100g", 0),
                "fiber_100g": product.get("nutriments", {}).get("fiber_100g", 0),
                "proteins_100g": product.get("nutriments", {}).get("proteins_100g", 0),
            },
            "nova_group": product.get("nova_group", 0),
            "nutri_score": product.get("nutriscore_grade", "").upper() if product.get("nutriscore_grade") else None,
        }

def get_product_by_barcode(barcode: str, db: Session):
    """Check if product exists in local database by barcode"""
    from sqlalchemy import text
    row = db.execute(text("""
        SELECT product_id, name, brand, health_score, is_harmful
        FROM products 
        WHERE barcode = :barcode
    """), {"barcode": barcode}).fetchone()
    
    if row:
        return {
            "product_id": row[0],
            "name": row[1],
            "brand": row[2],
            "health_score": row[3],
            "is_harmful": row[4],
            "source": "local"
        }
    return None

async def scan_barcode(barcode: str, db: Session) -> dict:
    """Main function: check local DB first, then fetch from OpenFoodFacts"""
    
    # Step 1: Check local database
    local_product = get_product_by_barcode(barcode, db)
    if local_product:
        return local_product
    
    # Step 2: Fetch from OpenFoodFacts
    off_data = await fetch_from_openfoodfacts(barcode)
    
    if not off_data:
        return {"error": "Product not found in OpenFoodFacts", "source": "error"}
    
    # Step 3: Create product in local database
    product_id = create_product(off_data, db)
    
    # Step 4: Compute health score
    score_result = compute_score(product_id, db)
    
    # Step 5: Return result
    return {
        "source": "openfoodfacts",
        "product_id": product_id,
        "name": off_data["name"],
        "brand": off_data["brand"],
        "health_score": score_result["health_score"],
        "is_harmful": score_result["is_harmful"],
        "traffic_light": score_result["traffic_light"],
        "flagged_ingredients": score_result["flagged_ingredients"]
    }