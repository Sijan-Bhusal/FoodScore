import uuid
from sqlalchemy import Column, Integer, String, DateTime, Boolean
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.sql import func
from app.database import Base

class Product(Base):
    __tablename__ = "products"
    
    product_id = Column(UUID(as_uuid=True), primary_key=True, index=True, default=uuid.uuid4)
    barcode = Column(String(50), unique=True, nullable=True, index=True)
    name = Column(String, nullable=False)
    brand = Column(String)
    category = Column(String)
    image_url = Column(String)
    ingredients_raw = Column(String)
    additives = Column(JSONB, default=[])
    nutriments = Column(JSONB, default={})
    nova_group = Column(Integer)
    nutri_score = Column(String(1))
    health_score = Column(Integer)
    is_harmful = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
