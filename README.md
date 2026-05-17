# FoodScore

A comprehensive food nutrition assessment platform that combines barcode scanning with AI-powered nutritional scoring. Users can scan product barcodes, view detailed nutritional information, and receive personalized health recommendations.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Flutter Mobile App                     │
│  (Barcode Scanning, Product Search, Scan History)          │
└────────────────────────┬────────────────────────────────────┘
                         │ HTTP/REST
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    FastAPI Backend                          │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Product Service (Local DB → OpenFoodFacts Fallback)│  │
│  │  Score Service (Nutri-Score & AI Predictions)      │  │
│  │  Search Service (Full-text & Barcode Lookup)       │  │
│  └──────────────────────────────────────────────────────┘  │
└────────────┬────────────────────────────────┬───────────────┘
             │                                │
             ▼                                ▼
    ┌──────────────────┐           ┌──────────────────────┐
    │   PostgreSQL     │           │ OpenFoodFacts API    │
    │   (Local DB)     │           │ (Remote Fallback)    │
    └──────────────────┘           └──────────────────────┘
```

**Data Flow:**
1. User scans barcode in Flutter app
2. Backend checks local PostgreSQL database first
3. If product not found locally, queries OpenFoodFacts API
4. Calculates Nutri-Score and health metrics
5. Returns product with score and source information
6. Flutter app stores scan history in local SharedPreferences

## Tech Stack

### Backend
- **Framework:** FastAPI 0.115.0
- **Server:** uvicorn[standard] 0.30.0
- **Database ORM:** SQLAlchemy 2.0.35
- **HTTP Client:** httpx 0.28.1 (async)
- **Database:** PostgreSQL 15
- **Environment:** python-dotenv, pydantic

### Frontend
- **Framework:** Flutter (Dart)
- **State Management:** flutter_riverpod 3.3.1
- **Barcode Scanner:** mobile_scanner 7.2.0
- **Permissions:** permission_handler 12.0.1
- **Local Storage:** shared_preferences 2.3.2
- **HTTP Client:** http package

### Infrastructure
- **Containerization:** Docker & docker-compose
- **Database:** PostgreSQL 15-alpine
- **Development:** Python 3.12, Flutter SDK

## Local Setup

### Prerequisites
- Python 3.12+
- Flutter SDK
- Docker & Docker Compose
- PostgreSQL client tools (optional)

### Backend Setup

1. **Clone and navigate to backend:**
   ```bash
   cd backend
   ```

2. **Create virtual environment:**
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

4. **Set up environment variables:**
   ```bash
   cp ../.env.example .env
   # Edit .env with your local database credentials:
   # DATABASE_URL=postgresql://user:password@localhost:5432/foodscore
   # OPENFOODFACTS_API_URL=https://world.openfoodfacts.org
   ```

5. **Initialize database (optional - if running PostgreSQL locally):**
   ```bash
   psql -U postgres -c "CREATE DATABASE foodscore;"
   psql -U postgres -d foodscore -f ../database/schema.sql
   ```

### Flutter Setup

1. **Navigate to flutter app:**
   ```bash
   cd flutter_app
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure API endpoint:**
   - Edit `lib/services/config.dart` or similar config file
   - Set API base URL to `http://localhost:8000` for local development

4. **Build for your platform:**
   ```bash
   # Android
   flutter build apk --debug
   
   # iOS (macOS only)
   flutter build ios --debug
   
   # Linux
   flutter build linux
   ```

## Running the Application

### Option 1: Using Docker Compose (Recommended for Production-like Environment)

1. **From project root, start all services:**
   ```bash
   docker-compose up --build
   ```

   This will:
   - Start PostgreSQL database on `localhost:5432`
   - Start FastAPI backend on `http://localhost:8000`
   - Initialize database schema automatically

2. **Access the API:**
   ```bash
   curl http://localhost:8000/products/scan/3017620425035
   ```

3. **Stop services:**
   ```bash
   docker-compose down
   ```

### Option 2: Local Development (Backend Only)

1. **Start PostgreSQL** (if not using Docker):
   ```bash
   # Using Docker for just DB
   docker run --name foodscore-db -e POSTGRES_PASSWORD=password -p 5432:5432 postgres:15-alpine
   ```

2. **Run FastAPI server:**
   ```bash
   cd backend
   source venv/bin/activate
   uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
   ```

   Server will be available at `http://localhost:8000`
   API docs at `http://localhost:8000/docs`

### Option 3: Run Flutter App

1. **Ensure backend is running** (localhost:8000)

2. **Run on connected device/emulator:**
   ```bash
   cd flutter_app
   flutter run
   ```

3. **Or run on specific target:**
   ```bash
   flutter run -d android  # Android emulator
   flutter run -d chrome   # Web browser
   flutter run -d linux    # Linux desktop
   ```

## API Endpoints

### Product Scanning
- **GET** `/products/scan/{barcode}` - Scan product by barcode
  ```bash
  curl http://localhost:8000/products/scan/3017620425035
  ```
  Response:
  ```json
  {
    "product_id": "3017620425035",
    "name": "Product Name",
    "health_score": 7,
    "source": "local",
    "image_url": "https://...",
    "ingredients": ["..."],
    "nutrition_info": {...}
  }
  ```

## Project Structure

```
FoodScore/
├── backend/               # FastAPI application
│   ├── app/
│   │   ├── main.py       # Application entry point
│   │   ├── config.py     # Configuration
│   │   ├── database.py   # Database setup
│   │   ├── api/          # API routes
│   │   ├── services/     # Business logic
│   │   ├── models/       # Database models
│   │   └── schemas/      # Request/response schemas
│   ├── requirements.txt  # All dependencies
│   └── Dockerfile        # Container image
├── flutter_app/          # Flutter mobile application
│   ├── lib/
│   │   ├── main.dart     # App entry point
│   │   ├── screens/      # UI screens
│   │   ├── services/     # Business logic
│   │   ├── models/       # Data models
│   │   └── providers/    # State management
│   └── pubspec.yaml      # Dependencies
├── database/
│   └── schema.sql        # Database schema
└── docker-compose.yml    # Service orchestration
```

## Development Workflow

### Backend Development
```bash
cd backend
source venv/bin/activate

# Run with auto-reload
uvicorn app.main:app --reload

# Run tests (if available)
pytest
```

### Flutter Development
```bash
cd flutter_app

# Hot reload during development
flutter run

# Build release version
flutter build apk --release
```

## Troubleshooting

**Backend won't start:**
- Check PostgreSQL is running: `psql -U postgres -l`
- Verify `.env` file exists and DATABASE_URL is correct
- Clear Python cache: `rm -rf backend/__pycache__ backend/.pytest_cache`

**Flutter app can't connect to API:**
- Ensure backend is running on `http://localhost:8000`
- Check device/emulator can reach your machine's IP (not `localhost`)
- Update API endpoint in Flutter config if needed

**Database migration issues:**
- Re-initialize: `psql -d foodscore -f database/schema.sql`
- Check Docker volume permissions if using docker-compose

## Next Steps

- [ ] Add comprehensive API tests
- [ ] Implement user authentication
- [ ] Add push notifications for health alerts
- [ ] Integrate more data sources
- [ ] Mobile platform-specific optimizations

## License

[Add your license here]

## Contributing

[Add contributing guidelines here]
