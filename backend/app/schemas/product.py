from pydantic import BaseModel, Field, field_validator
from typing import Optional

class ProductCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=200)
    brand: Optional[str] = Field(None, max_length=100)
    category: Optional[str] = Field(None, max_length=50)
    ingredients_raw: Optional[str] = None
    additives: Optional[list[str]] = []
    nutriments: Optional[dict] = {}
    nova_group: Optional[int] = Field(None, ge=1, le=4)
    nutri_score: Optional[str] = Field(None, pattern="^[A-E]$")
    
    @field_validator('name')
    def name_not_empty(cls, v):
        if not v or not v.strip():
            raise ValueError('Product name cannot be empty')
        return v.strip()

class ProductOut(BaseModel):
    product_id: str
    name: str
    brand: Optional[str] = None
    category: Optional[str] = None
    health_score: Optional[int] = None
    is_harmful: bool = False
    
    class Config:
        from_attributes = True