from sqlalchemy import Column, Integer, Float, ForeignKey
from app.database import Base

class NutritionFacts(Base):
    __tablename__ = "nutrition_facts"

    id = Column(Integer, primary_key=True)
    product_id = Column(Integer, ForeignKey("products.id"))
    energy = Column(Float)
    fat = Column(Float)
    sugar = Column(Float)
    salt = Column(Float)
    protein = Column(Float)