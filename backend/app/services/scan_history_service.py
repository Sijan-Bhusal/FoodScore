import uuid
from sqlalchemy.orm import Session
from sqlalchemy import text
from typing import List, Dict, Any, Optional
from datetime import datetime

def save_scan(user_id: str, db: Session, product_id: Optional[str] = None, barcode: Optional[str] = None, score: Optional[int] = None) -> Optional[str]:
    """Save a scan to history"""
    if db is None:
        return None
    
    # Validate: must have either product_id or barcode
    if not product_id and not barcode:
        print("Error: Neither product_id nor barcode provided")
        return None
    
    scan_id = str(uuid.uuid4())
    
    try:
        db.execute(text("""
            INSERT INTO scan_history (scan_id, user_id, product_id, barcode, score_at_scan)
            VALUES (:sid, :uid, :pid, :bc, :score)
        """), {"sid": scan_id, "uid": user_id, "pid": product_id, "bc": barcode, "score": score})
        db.commit()
    except Exception as e:
        db.rollback()
        print(f"Error saving scan: {e}")
        return None
    
    return scan_id

def get_user_scans(user_id: str, db: Session, limit: int = 20) -> List[Dict[str, Any]]:
    """Get user's scan history"""
    if db is None:
        return []
    
    try:
        rows = db.execute(text("""
            SELECT s.scan_id, s.barcode, s.scanned_at, s.score_at_scan,
                   p.product_id, p.name, p.brand, p.health_score, p.is_harmful
            FROM scan_history s
            LEFT JOIN products p ON s.product_id = p.product_id
            WHERE s.user_id = :uid
            ORDER BY s.scanned_at DESC
            LIMIT :limit
        """), {"uid": user_id, "limit": limit}).fetchall()
    except Exception as e:
        print(f"Error getting user scans: {e}")
        return []
    
    return [
        {
            "scan_id": r[0],
            "barcode": r[1],
            "scanned_at": r[2].isoformat() if r[2] else None,
            "score_at_scan": r[3],
            "product": {
                "product_id": r[4],
                "name": r[5],
                "brand": r[6],
                "health_score": r[7],
                "is_harmful": r[8]
            } if r[4] else None
        }
        for r in rows
    ]

def get_recent_scans(db: Session, limit: int = 10) -> List[Dict[str, Any]]:
    """Get recent scans from all users"""
    if db is None:
        return []
    
    try:
        rows = db.execute(text("""
            SELECT s.scan_id, s.barcode, s.scanned_at, s.score_at_scan,
                   p.product_id, p.name, p.brand, p.health_score, p.is_harmful
            FROM scan_history s
            LEFT JOIN products p ON s.product_id = p.product_id
            ORDER BY s.scanned_at DESC
            LIMIT :limit
        """), {"limit": limit}).fetchall()
    except Exception as e:
        print(f"Error getting recent scans: {e}")
        return []
    
    return [
        {
            "scan_id": r[0],
            "barcode": r[1],
            "scanned_at": r[2].isoformat() if r[2] else None,
            "score_at_scan": r[3],
            "product": {
                "product_id": r[4],
                "name": r[5],
                "brand": r[6],
                "health_score": r[7],
                "is_harmful": r[8]
            } if r[4] else None
        }
        for r in rows
    ]