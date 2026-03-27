from sqlalchemy.orm import sessionmaker
from app.db.base import engine

SessionLocal = sessionmaker(bind=engine)