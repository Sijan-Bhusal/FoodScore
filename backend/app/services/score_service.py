from sqlalchemy.orm import Session
from sqlalchemy import text
import json

TIER_PENALTIES = {
    "harmful": 100,
    "high": 15,
    "medium": 7,
    "low": 2,
}

NUTRIMENT_RULES = [
    ("sugars_100g", 20, 10, 5),
    ("saturated_fat_100g", 5, 2, 5),
    ("salt_100g", 1.5, 0.6, 5),
    ("fiber_100g", 3, 6, -5),
    ("proteins_100g", 5, 10, -3),
]

def get_traffic_light(score: int, is_harmful: bool) -> dict:
    if is_harmful or score == 0:
        return {"color": "red", "label": "Harmful — avoid"}
    elif score <= 40:
        return {"color": "orange", "label": "Poor"}
    elif score <= 70:
        return {"color": "yellow", "label": "Moderate"}
    else:
        return {"color": "green", "label": "Good"}

def compute_score(product_id: str, db: Session) -> dict:
    row = db.execute(text("""
        SELECT additives, nutriments, nova_group, nutri_score
        FROM products WHERE product_id = :pid
    """), {"pid": product_id}).fetchone()
    
    if not row:
        return {"error": "Product not found"}
    
    additives, nutriments, nova_group, nutri_score = row
    score = 100
    is_harmful = False
    flagged = []
    
    # Check additives against reference table
    if additives and len(additives) > 0:
        additive_rows = db.execute(text("""
            SELECT e_number, common_name, risk_tier, is_banned
            FROM additive_reference
            WHERE e_number = ANY(:additives)
        """), {"additives": additives}).fetchall()
        
        for e_num, name, tier, banned in additive_rows:
            if banned or tier == "harmful":
                is_harmful = True
                score = 0
                flagged.append({"e_number": e_num, "name": name, "risk": tier, "penalty": 100})
                break
            else:
                penalty = TIER_PENALTIES.get(tier, 0)
                score -= penalty
                flagged.append({"e_number": e_num, "name": name, "risk": tier, "penalty": penalty})
    
    # Check nutriments if not already harmful
    if not is_harmful and nutriments:
        nut_data = nutriments or {}
        for field, high, medium, penalty in NUTRIMENT_RULES:
            value = nut_data.get(field, 0) or 0
            if penalty > 0:
                if value >= high:
                    score -= penalty
                elif value >= medium:
                    score -= penalty // 2
            else:
                if value >= medium:
                    score += abs(penalty)
    
    # NOVA modifier
    nova_mod = {1: 5, 2: 0, 3: -5, 4: -10}
    score += nova_mod.get(nova_group, 0)
    
    # Nutri-Score modifier
    nutri_mod = {"A": 5, "B": 3, "C": 0, "D": -5, "E": -10}
    score += nutri_mod.get(nutri_score, 0)
    
    # Clamp
    score = max(0, min(100, score))
    
    # Save score to DB
    db.execute(text("""
        UPDATE products
        SET health_score = :score, is_harmful = :harmful, updated_at = NOW()
        WHERE product_id = :pid
    """), {"score": score, "harmful": is_harmful, "pid": product_id})
    
    # Save flagged ingredients
    db.execute(text("DELETE FROM flagged_ingredients WHERE product_id = :pid"), {"pid": product_id})
    
    for f in flagged:
        db.execute(text("""
            INSERT INTO flagged_ingredients (product_id, ingredient_name, e_number, risk_tier, penalty)
            VALUES (:pid, :name, :enum, :risk, :penalty)
        """), {"pid": product_id, "name": f["name"], "enum": f["e_number"], "risk": f["risk"], "penalty": f["penalty"]})
    
    db.commit()
    
    return {
        "product_id": product_id,
        "health_score": score,
        "is_harmful": is_harmful,
        "flagged_ingredients": flagged,
        "traffic_light": get_traffic_light(score, is_harmful)
    }