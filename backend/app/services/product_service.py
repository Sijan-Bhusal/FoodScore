import uuid
import json
from sqlalchemy.orm import Session
from sqlalchemy import text

def create_product(data: dict, db: Session) -> str:
    product_id = str(uuid.uuid4())
    
    # Convert additives list to JSONB format
    additives_json = json.dumps(data.get("additives", []))
    
    # Ensure nutriments is properly formatted as JSONB
    nutriments = data.get("nutriments", {})
    if isinstance(nutriments, str):
        nutriments_json = nutriments
    else:
        nutriments_json = json.dumps(nutriments)
    
    db.execute(text("""
        INSERT INTO products
        (product_id, name, brand, category, ingredients_raw,
         additives, nutriments, nova_group, nutri_score, barcode)
        VALUES (:pid, :name, :brand, :cat, :ingr,
                CAST(:additives AS jsonb), CAST(:nutriments AS jsonb), :nova, :nutri, :barcode)
    """), {
        "pid": product_id,
        "name": data.get("name"),
        "brand": data.get("brand"),
        "cat": data.get("category"),
        "ingr": data.get("ingredients_raw"),
        "additives": additives_json,
        "nutriments": nutriments_json,
        "nova": data.get("nova_group"),
        "nutri": data.get("nutri_score"),
        "barcode": data.get("barcode"),
    })
    db.commit()
    return product_id

def get_product(product_id: str, db: Session):
    return db.execute(text("""
        SELECT p.product_id, p.name, p.brand, p.category,
               p.health_score, p.is_harmful, p.nova_group,
               p.nutri_score, p.nutriments, p.additives,
               s.suggestion_text,
               COALESCE(
                   json_agg(
                       json_build_object(
                           'ingredient', f.ingredient_name,
                           'e_number', f.e_number,
                           'risk', f.risk_tier,
                           'penalty', f.penalty
                       )
                   ) FILTER (WHERE f.id IS NOT NULL), '[]'
               ) AS flagged
        FROM products p
        LEFT JOIN suggestions s ON s.product_id = p.product_id
        LEFT JOIN flagged_ingredients f ON f.product_id = p.product_id
        WHERE p.product_id = :pid
        GROUP BY p.product_id, s.suggestion_text
    """), {"pid": product_id}).fetchone()

def list_products(db: Session, skip: int = 0, limit: int = 20):
    return db.execute(text("""
        SELECT product_id, name, brand, health_score, is_harmful
        FROM products ORDER BY created_at DESC LIMIT :limit OFFSET :skip
    """), {"limit": limit, "skip": skip}).fetchall()