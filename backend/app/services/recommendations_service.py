from sqlalchemy.orm import Session
from sqlalchemy import text
from typing import List, Dict, Any, Optional

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
    """Find better alternatives for a product"""
    if db is None:
        return []
    
    try:
        # Get current product score
        current = db.execute(text("""
            SELECT health_score FROM products WHERE product_id = :pid
        """), {"pid": product_id}).fetchone()
        
        if not current:
            return []
        
        current_score = current[0] if current[0] else 0
        
        rows = db.execute(text("""
            SELECT product_id, name, brand, health_score
            FROM products
            WHERE health_score > :score AND health_score IS NOT NULL
            ORDER BY health_score DESC
            LIMIT 3
        """), {"score": current_score, "pid": product_id}).fetchall()
        
    except Exception as e:
        print(f"Error getting alternatives: {e}")
        return []
    
    return [
        {
            "product_id": r[0],
            "name": r[1],
            "brand": r[2],
            "health_score": r[3],
            "improvement": f"{r[3] - current_score} points higher"
        }
        for r in rows
    ]