import os
import sys
import logging
from pathlib import Path

# Add the backend directory to Python path so imports like 'from app.database...' work
# when the app is run from the project root (e.g., Render deployment)
_backend_dir = Path(__file__).resolve().parent.parent
if str(_backend_dir) not in sys.path:
    sys.path.insert(0, str(_backend_dir))

from fastapi import FastAPI, Request, Depends
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware

logger = logging.getLogger(__name__)
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.database import engine, Base, get_db
from app.models import product, nutrition, score, user
from app.api import products, score as score_router, search, auth
from app.api import scan
app = FastAPI(title="FoodScore API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=os.getenv("ALLOWED_ORIGINS", "http://localhost:3000").split(","),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

SCHEMA_FILE = Path(__file__).resolve().parents[2] / "database" / "schema.sql"


@app.middleware("http")
async def catch_exceptions(request: Request, call_next):
    try:
        return await call_next(request)
    except Exception as e:
        logger.exception("Unhandled exception")
        return JSONResponse(
            status_code=500,
            content={"error": "Internal server error"}
        )


@app.on_event("startup")
def startup():
    Base.metadata.create_all(bind=engine)
    if SCHEMA_FILE.exists():
        schema_sql = SCHEMA_FILE.read_text(encoding="utf-8")
        # Use raw connection to execute multi-statement SQL (handles $$ functions)
        conn = engine.raw_connection()
        try:
            cursor = conn.cursor()
            cursor.execute(schema_sql)
            conn.commit()
        finally:
            conn.close()


app.include_router(auth.router)
app.include_router(scan.router)
app.include_router(products.router)
app.include_router(score_router.router)
app.include_router(search.router)


@app.get("/")
def home():
    return {"message": "FoodScore API is running"}


@app.get("/health")
def health_check(db: Session = Depends(get_db)):
    """Health check endpoint for monitoring and container orchestration"""
    try:
        # Verify database connection
        db.execute(text("SELECT 1"))
        return {
            "status": "healthy",
            "service": "FoodScore API",
            "version": "1.0.0"
        }
    except Exception as e:
        return JSONResponse(
            status_code=503,
            content={
                "status": "unhealthy",
                "service": "FoodScore API",
                "error": str(e)
            }
        )
