import numpy as np
from sklearn.neighbors import NearestNeighbors
from sqlalchemy.orm import Session
from sqlalchemy import text

FEATURE_FIELDS = ["sugars_100g", "saturated_fat_100g", "salt_100g", "fiber_100g", "proteins_100g"]


def fetch_feature_matrix(db: Session, category: str = None):
    """Pull products with nutriments and build a feature matrix"""
    query = """
        SELECT product_id, name, brand, health_score, nutriments, category
        FROM products
        WHERE nutriments IS NOT NULL AND health_score IS NOT NULL
    """
    params = {}
    if category:
        query += " AND category = :cat"
        params["cat"] = category

    rows = db.execute(text(query), params).fetchall()

    product_ids, names, brands, scores, vectors = [], [], [], [], []
    for r in rows:
        nut = r.nutriments or {}
        vec = [nut.get(f, 0) or 0 for f in FEATURE_FIELDS]
        product_ids.append(r.product_id)
        names.append(r.name)
        brands.append(r.brand)
        scores.append(r.health_score)
        vectors.append(vec)

    return product_ids, names, brands, scores, np.array(vectors)


def find_similar_healthier(product_id: str, db: Session, top_n: int = 5):
    """Find nutritionally similar products with a higher health_score"""
    row = db.execute(text("""
        SELECT nutriments, category, health_score FROM products WHERE product_id = :pid
    """), {"pid": product_id}).fetchone()

    if not row or not row.nutriments:
        return []

    target_vec = np.array([[row.nutriments.get(f, 0) or 0 for f in FEATURE_FIELDS]])
    current_score = row.health_score or 0

    ids, names, brands, scores, matrix = fetch_feature_matrix(db, category=row.category)

    if len(matrix) < 2:
        return []

    n_neighbors = min(top_n + 5, len(matrix))
    model = NearestNeighbors(n_neighbors=n_neighbors, metric="euclidean")
    model.fit(matrix)

    distances, indices = model.kneighbors(target_vec)

    results = []
    for dist, idx in zip(distances[0], indices[0]):
        if str(ids[idx]) == str(product_id):
            continue
        if scores[idx] is None or scores[idx] <= current_score:
            continue
        results.append({
            "product_id": ids[idx],
            "name": names[idx],
            "brand": brands[idx],
            "health_score": scores[idx],
            "similarity_distance": round(float(dist), 2)
        })
        if len(results) >= top_n:
            break

    return results