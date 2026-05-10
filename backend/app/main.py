from fastapi import FastAPI, Request, Depends
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
import traceback
from pathlib import Path
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.database import engine, Base, get_db
from app.models import product, nutrition, score
from app.api import products, score as score_router, search

app = FastAPI(title="FoodScore API", version="1.0.0")

# CORS — allows Flutter app to call this API
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
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
        return JSONResponse(
            status_code=500,
            content={"error": str(e), "detail": traceback.format_exc()}
        )

@app.on_event("startup")
def startup():
    Base.metadata.create_all(bind=engine)
    if SCHEMA_FILE.exists():
        schema_sql = SCHEMA_FILE.read_text(encoding="utf-8")
        statements = [s.strip() for s in schema_sql.split(";") if s.strip()]
        with engine.begin() as connection:
            for statement in statements:
                connection.exec_driver_sql(statement)

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