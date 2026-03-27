from sqlalchemy import Column, Integer, Float, String, ForeignKey
from app.database import Base

class HealthScore(Base):
    __tablename__ = "health_scores"

    id = Column(Integer, primary_key=True)
    product_id = Column(Integer, ForeignKey("products.id"))
    score = Column(Float)
    grade = Column(String)