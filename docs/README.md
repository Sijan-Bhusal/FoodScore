# FoodScore

A food nutrition assessment platform that combines barcode scanning with rule-based nutritional scoring. Users scan product barcodes, view nutritional information and flagged additives, and get a health score with traffic-light style ratings and healthier alternatives.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Flutter Mobile App                       │
│  (Barcode Scanning, Product Search, Scan History, Auth)       │
└────────────────────────┬──────────────────────────────────────┘
                          │ HTTP/REST (JSON)
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                    FastAPI Backend                            │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ Auth Service     (JWT, Google Sign-In, email/password)│   │
│  │ Product Service  (Local DB → OpenFoodFacts Fallback)  │   │
│  │ Score Service    (Additive/Nutriment rule-based score)│   │
│  │ Search Service   (Full-text name/brand search)        │   │
│  │ Scan History     (Per-user scan log)                  │   │
│  │ Recommendations  (Healthier alternatives)              │   │
│  └──────────────────────────────────────────────────────┘   │
└────────────┬────────────────────────────────┬─────────────────┘
             │                                │
             ▼                                ▼
    ┌──────────────────┐           ┌──────────────────────┐
    │   PostgreSQL     │           │  OpenFoodFacts API    │
    │   (Local DB)     │           │  (Remote Fallback)    │
    └──────────────────┘           └──────────────────────┘
```

**Scan data flow:**
1. User scans a barcode in the Flutter app (`GET /products/scan/{barcode}`).
2. The backend checks the local PostgreSQL `products` table first.
3. If not found, it queries the OpenFoodFacts API, persists the product locally, and computes a health score.
4. The score service evaluates additives, nutriments, NOVA group, and Nutri-Score, then returns a 0–100 health score, a list of flagged ingredients, and a traffic-light rating (red/orange/yellow/green).
5. The Flutter app records the scan in its history (locally and via `POST /scan/history` when signed in).

## Tech Stack

### Backend (`backend/`)
- **Framework:** FastAPI 0.115
- **Server:** Uvicorn (standard, with `--reload` for dev)
- **ORM:** SQLAlchemy 2.0 (raw SQL via `text()` for most queries)
- **Database:** PostgreSQL 15
- **HTTP client:** httpx (async, used for OpenFoodFacts calls)
- **Auth:** JWT access/refresh tokens (`PyJWT`/`python-jose`), `passlib`/bcrypt for password hashing, Google ID token verification (`google-auth`)
- **Config:** `python-dotenv` + `app/config.py`
- **Error monitoring:** Sentry SDK
- **OCR (planned):** `pytesseract` (label scanning)

### Frontend (`flutter_app/`)
- **Framework:** Flutter (Dart, SDK ^3.10)
- **State management:** flutter_riverpod 3.3
- **Barcode scanning:** mobile_scanner 7.2
- **Auth:** google_sign_in, flutter_secure_storage
- **Local storage:** shared_preferences
- **Permissions:** permission_handler
- **HTTP client:** `http` package via `lib/services/api_client.dart`

### Infrastructure
- **Containerization:** Docker & docker-compose
- **Database image:** `postgres:15-alpine`
- **Schema bootstrap:** `database/schema.sql` is mounted into the Postgres container and is also re-applied by the backend on startup (`backend/app/main.py`)

## Local Setup

### Prerequisites
- Python 3.12+
- Flutter SDK
- Docker & Docker Compose
- PostgreSQL client tools (optional, for manual DB access)

### Environment variables

Copy `.env.example` to `.env` in the project root and set values:

```bash
cp .env.example .env
```

| Variable | Required | Description |
|---|---|---|
| `DATABASE_URL` | Yes | SQLAlchemy connection string, e.g. `postgresql://foodscore:password@postgres:5432/foodscore` |
| `DB_USER` / `DB_PASSWORD` / `DB_NAME` | Yes (docker-compose) | Postgres container credentials |
| `SECRET_KEY` | Yes | JWT signing secret. Backend raises a `RuntimeError` on startup if unset |
| `GOOGLE_CLIENT_ID` | No | Required only for `POST /auth/google` (Google Sign-In) |
| `ALLOWED_ORIGINS` | No | Comma-separated CORS origins (default `http://localhost:3000`) |
| `PYTHONUNBUFFERED` | No | Set to `1` for unbuffered container logs |

### Backend setup (without Docker)

```bash
cd backend
python -m venv venv
source venv/bin/activate          # Windows: venv\Scripts\activate
pip install -r requirements.txt
```

Then either run against a local Postgres instance (initialize with `database/schema.sql`) or point `DATABASE_URL` at a running container (see "Running the Application" below).

### Flutter setup

```bash
cd flutter_app
flutter pub get
```

The API base URL is set in `lib/app/app_config.dart`:

```dart
class AppConfig {
  static const String apiBaseUrl = 'http://localhost:8000';
}
```

Update this if the backend is reachable at a different host (e.g. an emulator's host-loopback address or a deployed URL).

## Running the Application

### Option 1: Docker Compose (recommended)

```bash
docker-compose up --build
```

This starts:
- PostgreSQL on `localhost:5433` (mapped from container port 5432)
- FastAPI backend on `http://localhost:8000`, with the schema in `database/schema.sql` applied automatically on startup

Verify it's up:

```bash
curl http://localhost:8000/health
```

Stop services:

```bash
docker-compose down
```

### Option 2: Backend only (local Python)

```bash
# Start Postgres separately if needed
docker run --name foodscore-db -e POSTGRES_PASSWORD=password -p 5432:5432 postgres:15-alpine

cd backend
source venv/bin/activate
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

- API: `http://localhost:8000`
- Interactive docs (Swagger UI): `http://localhost:8000/docs`

### Option 3: Flutter app

Ensure the backend is running and reachable at the address configured in `app_config.dart`, then:

```bash
cd flutter_app
flutter run                # pick a connected device/emulator
flutter run -d android
flutter run -d chrome
flutter run -d linux
```

## API Overview

See [API.md](API.md) for the full endpoint reference (auth, products, scanning, scoring, search, scan history, recommendations).

Quick example:

```bash
curl http://localhost:8000/products/scan/3017620425035
```

## Project Structure

```
FoodScore/
├── backend/
│   ├── app/
│   │   ├── main.py         # App entry point, CORS, schema bootstrap, health check
│   │   ├── config.py        # Env-based configuration (DATABASE_URL, SECRET_KEY, ...)
│   │   ├── database.py      # SQLAlchemy engine/session setup
│   │   ├── api/              # Route modules: auth, products, scan, score, search
│   │   ├── services/         # Business logic (auth, scoring, OpenFoodFacts, recommendations)
│   │   ├── models/            # SQLAlchemy models
│   │   ├── schemas/           # Pydantic request/response models
│   │   └── ml/                 # Placeholder modules for future ML-based scoring
│   ├── tests/                  # pytest test suite
│   ├── requirements.txt        # Python dependencies
│   └── Dockerfile
├── flutter_app/
│   └── lib/
│       ├── main.dart
│       ├── app/                # App shell, routing, theme, config
│       ├── screens/             # UI screens (onboarding, scanner, product, history, ...)
│       ├── services/            # API client, auth, barcode, search services
│       ├── providers/ & state/  # Riverpod providers/controllers
│       └── models/              # Dart data models
├── database/
│   └── schema.sql              # Postgres schema, indexes, seed data for additive reference
├── add_products.py             # Bulk product importer script (uses POST /products/)
└── docker-compose.yml
```

## Database Schema

Key tables in `database/schema.sql`:

- **`products`** — barcode, name, brand, category, ingredients, additives (JSONB), nutriments (JSONB), NOVA group, Nutri-Score, computed `health_score`, `is_harmful` flag.
- **`additive_reference`** — seeded reference data mapping E-numbers to risk tiers (`harmful`, `high`, `medium`, `low`) and ban status, used by the scoring engine.
- **`flagged_ingredients`** — additives flagged on a product with their risk tier and score penalty.
- **`suggestions`** — generated suggestions/alternatives per product (reserved for future use).
- **`users`** — supports email/password and Google Sign-In (`password_hash`, `google_id`, `apple_id`, `display_name`, `avatar_url`, `preferences`).
- **`scan_history`** — per-user scan log, referencing either a known `product_id` or a raw `barcode`.
- **`user_settings`** — per-user key/value settings.

## Scoring Algorithm

Implemented in `backend/app/services/score_service.py`. Every product starts at a base score of **100**:

1. **Additives** — each additive is looked up in `additive_reference`. A `harmful`/banned additive sets the score to **0** and marks the product `is_harmful`. Otherwise penalties apply: `high` -15, `medium` -7, `low` -2.
2. **Nutriments** (per 100g, skipped if already harmful):
   - Sugars ≥20g: -5, ≥10g: -2.5
   - Saturated fat ≥5g: -5, ≥2g: -2.5
   - Salt ≥1.5g: -5, ≥0.6g: -2.5
   - Fiber ≥6g: +5 (if ≥3g threshold met)
   - Protein ≥10g: +3 (if ≥5g threshold met)
3. **NOVA group modifier:** group 1 +5, group 2 +0, group 3 -5, group 4 -10.
4. **Nutri-Score modifier:** A +5, B +3, C +0, D -5, E -10.
5. Score is clamped to **0–100** and persisted, along with the flagged-ingredients list.

The result also includes a **traffic-light** rating: red (harmful or score 0), orange (≤40), yellow (≤70), green (>70).

## Development Workflow

### Backend
```bash
cd backend
source venv/bin/activate
uvicorn app.main:app --reload
pytest
```

### Flutter
```bash
cd flutter_app
flutter run               # hot reload
flutter build apk --release
```

## Troubleshooting

**Backend won't start:**
- `SECRET_KEY` must be set in `.env` — the app raises `RuntimeError("SECRET_KEY must be set in environment")` otherwise.
- Check Postgres is reachable: `psql -U foodscore -h localhost -p 5433 -l` (Docker Compose maps Postgres to `5433`).
- Clear Python cache: `rm -rf backend/__pycache__ backend/.pytest_cache`

**Flutter app can't reach the API:**
- Confirm `apiBaseUrl` in `lib/app/app_config.dart` points at a host reachable from the device/emulator (not `localhost` when using an Android emulator).
- Confirm the backend's `ALLOWED_ORIGINS` includes the app's origin if running on web.

**Database / schema issues:**
- `backend/app/main.py` re-applies `database/schema.sql` on every startup (statements are idempotent via `IF NOT EXISTS`/`ON CONFLICT`).
- To reset Docker Compose data: `docker-compose down -v` (deletes the Postgres volume).

## Related Docs

- [API.md](API.md) — full API reference
- [QUICKSTART.md](QUICKSTART.md) — minimal commands to get running with Docker
