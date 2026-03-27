from fastapi import FastAPI
from app.database import engine, Base, SessionLocal

# import models so SQLAlchemy sees them
from app.models import product, nutrition, score

app = FastAPI()


@app.on_event("startup")
def startup_db_check():
    try:
        Base.metadata.create_all(bind=engine)
        app.state.db_startup_error = None
    except Exception as e:
        app.state.db_startup_error = str(e)

@app.get("/")
def home():
    return {"message": "FoodScore backend running 🚀"}

@app.get("/test-db")
def test_db():
    if getattr(app.state, "db_startup_error", None):
        return {
            "status": "DB not ready ❌",
            "error": app.state.db_startup_error,
        }

    db = None
    try:
        db = SessionLocal()
        return {"status": "DB connected ✅"}
    except Exception as e:
        return {"error": str(e)}
    finally:
        if db:
            db.close()