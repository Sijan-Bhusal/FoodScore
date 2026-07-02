from sqlalchemy.orm import Session
from sqlalchemy import text
from typing import List, Dict, Any, Optional
from app.ml.recommender import find_similar_healthier

def get_recommendations(user_id: Optional[str] = None, limit: int = 5, db: Session = None) -> List[Dict[str, Any]]:
    """Get product recommendations"""
    if db is None:
        return []
    
    try:
        rows = db.execute(text("""
            SELECT product_id, name, brand, health_score, is_harmful
            FROM products
            WHERE health_score >= 70 AND is_harmful = FALSE
            ORDER BY health_score DESC
            LIMIT :limit
        """), {"limit": limit}).fetchall()
    except Exception as e:
        print(f"Error getting recommendations: {e}")
        return []
    
    return [
        {
            "product_id": r[0],
            "name": r[1],
            "brand": r[2],
            "health_score": r[3],
            "is_harmful": r[4],
            "reason": "High nutritional quality" if r[3] >= 80 else "Good nutritional value"
        }
        for r in rows
    ]

def get_better_alternatives(product_id: str, db: Session) -> List[Dict[str, Any]]:
    """Find nutritionally similar but healthier alternatives using KNN"""
    try:
        results = find_similar_healthier(product_id, db, top_n=3)
        for r in results:
            r["improvement"] = f"{r['health_score']} health score"
        return results
    except Exception as e:
        print(f"Error getting ML alternatives: {e}")
        return []