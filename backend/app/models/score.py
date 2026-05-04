from sqlalchemy import Column, Integer, Float, String, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from app.database import Base

class HealthScore(Base):
    __tablename__ = "health_scores"
    
    id = Column(Integer, primary_key=True)
    product_id = Column(UUID(as_uuid=True), ForeignKey("products.product_id"))
    score = Column(Float)
    grade = Column(String(1))