# FoodScore API Reference

Base URL (local): `http://localhost:8000`

Interactive Swagger UI is available at `/docs` and OpenAPI schema at `/openapi.json` when the backend is running.

## Authentication

Most endpoints are public. Endpoints under `/auth/me` and `/scan/history` require a Bearer access token.

```
Authorization: Bearer <access_token>
```

Access tokens are JWTs signed with `SECRET_KEY` (HS256), valid for **60 minutes**. Refresh tokens are valid for **30 days**. Token payloads include `sub` (user ID), `exp`, and `type` (`access` or `refresh`).

---

## Auth — `/auth`

### Register with email/password

```http
POST /auth/register
Content-Type: application/json
```

```json
{
  "username": "jane_doe",
  "email": "jane@example.com",
  "password": "hunter2"
}
```

**Response 200** — [`TokenResponse`](#tokenresponse)

**Errors**
| Status | Description |
|---|---|
| 409 | Email already registered or username already taken |

### Login with email/password

```http
POST /auth/login
Content-Type: application/json
```

```json
{
  "email": "jane@example.com",
  "password": "hunter2"
}
```

**Response 200** — [`TokenResponse`](#tokenresponse)

**Errors**
| Status | Description |
|---|---|
| 401 | Invalid email or password |

### Sign in with Google

```http
POST /auth/google
Content-Type: application/json
```

```json
{
  "id_token": "<google-id-token>"
}
```

Verifies the ID token against `GOOGLE_CLIENT_ID`. If a user with the same email exists, it is linked to the Google account; otherwise a new user is created (username derived from the email local-part, de-duplicated with a numeric suffix if needed).

**Response 200** — [`TokenResponse`](#tokenresponse)

**Errors**
| Status | Description |
|---|---|
| 401 | Invalid Google ID token |

### Refresh access token

```http
POST /auth/refresh
Content-Type: application/json
```

```json
{
  "refresh_token": "<refresh_token>"
}
```

**Response 200** — [`TokenResponse`](#tokenresponse) (issues a new access + refresh token pair)

**Errors**
| Status | Description |
|---|---|
| 401 | Invalid or expired refresh token, or user not found |

### Get current user

```http
GET /auth/me
Authorization: Bearer <access_token>
```

**Response 200** — [`UserOut`](#userout)

### Update current user

```http
PATCH /auth/me
Authorization: Bearer <access_token>
Content-Type: application/json
```

```json
{
  "display_name": "Jane",
  "avatar_url": "https://example.com/avatar.png"
}
```

Both fields are optional; only provided fields are updated.

**Response 200** — [`UserOut`](#userout)

---

## Products — `/products`

### Create a product

```http
POST /products/
Content-Type: application/json
```

Body matches `ProductCreate` (barcode, name, brand, category, ingredients, additives, nutriments, nova_group, nutri_score, image_url — see `backend/app/schemas/product.py`). The score service runs immediately after creation.

```json
{
  "barcode": "5449000000996",
  "name": "Coca-Cola Original",
  "brand": "Coca-Cola",
  "category": "Beverages",
  "additives": ["e150d", "e338"],
  "nutriments": {
    "sugars_100g": 10.6,
    "saturated_fat_100g": 0,
    "salt_100g": 0.02,
    "fiber_100g": 0,
    "proteins_100g": 0
  }
}
```

**Response 200**
```json
{
  "product_id": "uuid",
  "health_score": 78,
  "is_harmful": false,
  "flagged_ingredients": [],
  "traffic_light": { "color": "green", "label": "Good" }
}
```

### List products

```http
GET /products/?skip=0&limit=20
```

| Query param | Type | Default | Description |
|---|---|---|---|
| `skip` | int | 0 | Offset (`>= 0`) |
| `limit` | int | 20 | Page size (`1`–`100`) |

**Response 200**
```json
[
  { "product_id": "uuid", "name": "Coca-Cola Original", "brand": "Coca-Cola", "health_score": 78, "is_harmful": false }
]
```

### Get recommendations

```http
GET /products/recommendations?limit=5
```

> Note: this route is registered before `/products/{product_id}` so the literal path `recommendations` is matched correctly.

Returns up to `limit` products with `health_score >= 70` and `is_harmful = false`, ordered by score descending.

**Response 200**
```json
[
  {
    "product_id": "uuid",
    "name": "Plain Greek Yogurt",
    "brand": "Brand",
    "health_score": 85,
    "is_harmful": false,
    "reason": "High nutritional quality"
  }
]
```

### Get a product by ID

```http
GET /products/{product_id}
```

**Response 200**
```json
{
  "product_id": "uuid",
  "name": "Coca-Cola Original",
  "brand": "Coca-Cola",
  "category": "Beverages",
  "image_url": "https://...",
  "health_score": 78,
  "is_harmful": false,
  "nova_group": 4,
  "nutri_score": "E",
  "nutriments": { "sugars_100g": 10.6, "...": "..." },
  "additives": ["e150d", "e338"],
  "suggestion": null,
  "flagged_ingredients": [],
  "traffic_light": { "color": "green", "label": "Good" }
}
```

**Errors**
| Status | Description |
|---|---|
| 404 | Product not found |

### Scan a product by barcode

```http
GET /products/scan/{barcode}
```

Checks the local database first; if not found, fetches from the OpenFoodFacts API, persists the product locally, and computes its health score.

**Response 200** — same shape as [Get a product by ID](#get-a-product-by-id), plus a top-level `"source"` field (`"local"` or `"openfoodfacts"`).

```bash
curl http://localhost:8000/products/scan/3017620425035
```

**Errors**
| Status | Description |
|---|---|
| 404 | Product not found locally or in OpenFoodFacts |
| 500 | Error scanning barcode (network/parse error) |

---

## Score — `/score`

### Recompute a product's score

```http
POST /score/{product_id}
```

Re-runs the scoring algorithm (see [README — Scoring Algorithm](README.md#scoring-algorithm)) and persists the result.

**Response 200**
```json
{
  "product_id": "uuid",
  "health_score": 78,
  "is_harmful": false,
  "flagged_ingredients": [],
  "traffic_light": { "color": "green", "label": "Good" }
}
```

**Errors**
| Status | Description |
|---|---|
| 404 | Product not found |

---

## Search — `/search`

### Search products by name or brand

```http
GET /search/?q=cola
```

| Query param | Type | Required | Description |
|---|---|---|---|
| `q` | string | Yes (min length 1) | Matches `name` or `brand` (case-insensitive substring) |

Results are ordered by `health_score` descending, limited to 20.

**Response 200**
```json
[
  { "product_id": "uuid", "name": "Coca-Cola Original", "brand": "Coca-Cola", "health_score": 78, "is_harmful": false }
]
```

---

## Scan History — `/scan`

### Save a scan

```http
POST /scan/history
Authorization: Bearer <access_token>
Content-Type: application/json
```

```json
{
  "product_id": "uuid",
  "score": 78
}
```

Exactly one of `product_id` or `barcode` must be provided.

| Field | Type | Required | Description |
|---|---|---|---|
| `product_id` | string (UUID) | One of `product_id`/`barcode` | Known product |
| `barcode` | string | One of `product_id`/`barcode` | Raw barcode (e.g. if the product wasn't found) |
| `score` | int | No | Health score at time of scan |

**Response 200**
```json
{ "scan_id": "uuid", "message": "Scan saved successfully" }
```

**Errors**
| Status | Description |
|---|---|
| 400 | Neither or both of `product_id`/`barcode` provided |
| 401 | Missing/invalid `Authorization` header or token |
| 500 | Failed to save scan |

### Get current user's scan history

```http
GET /scan/history?limit=20
Authorization: Bearer <access_token>
```

**Response 200**
```json
{ "scans": [ /* scan records, most recent first */ ] }
```

**Errors**
| Status | Description |
|---|---|
| 401 | Missing/invalid `Authorization` header or token |

### Get recent scans (global, public)

```http
GET /scan/recent?limit=10
```

Returns the most recent scans across all users (no auth required).

**Response 200**
```json
{ "scans": [ /* recent scan records */ ] }
```

---

## Health Check

```http
GET /health
```

Verifies database connectivity. Used by Docker Compose's healthcheck.

**Response 200**
```json
{ "status": "healthy", "service": "FoodScore API", "version": "1.0.0" }
```

**Response 503**
```json
{ "status": "unhealthy", "service": "FoodScore API", "error": "..." }
```

---

## Shared Schemas

### `TokenResponse`

```json
{
  "access_token": "eyJhbG...",
  "refresh_token": "eyJhbG...",
  "token_type": "bearer",
  "expires_in": 3600,
  "user": { "...": "see UserOut" }
}
```

### `UserOut`

```json
{
  "user_id": "uuid",
  "username": "jane_doe",
  "email": "jane@example.com",
  "display_name": "Jane",
  "avatar_url": "https://example.com/avatar.png",
  "created_at": "2026-01-01T00:00:00Z"
}
```

### Traffic light

| `color` | Condition |
|---|---|
| `red` | `is_harmful` is true, or `health_score == 0` |
| `orange` | `health_score <= 40` |
| `yellow` | `health_score <= 70` |
| `green` | `health_score > 70` |

### Error format

All unhandled exceptions are caught by the global middleware in `app/main.py` and return:

```json
{ "error": "Internal server error" }
```

with status `500`. Validation errors from FastAPI/Pydantic follow the standard format:

```json
{ "detail": [ { "loc": ["body", "field"], "msg": "...", "type": "..." } ] }
```
