from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime


class ProductBase(BaseModel):
    name: str
    description: Optional[str] = None
    price: float
    category: str
    subcategory: Optional[str] = None
    image_url: Optional[str] = None


class ProductCreate(ProductBase):
    stock: int
    is_featured: Optional[bool] = False
    sale_price: Optional[float] = None


class ProductUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    price: Optional[float] = None
    sale_price: Optional[float] = None
    stock: Optional[int] = None
    category: Optional[str] = None
    subcategory: Optional[str] = None
    image_url: Optional[str] = None
    is_featured: Optional[bool] = None
    is_active: Optional[bool] = None


class ProductInDBBase(ProductBase):
    id: int
    stock: int
    sale_price: Optional[float] = None
    is_featured: bool
    is_active: bool
    created_at: datetime
    
    class Config:
        orm_mode = True


class Product(ProductInDBBase):
    pass


class ProductInDB(ProductInDBBase):
    pass


class ProductListResponse(BaseModel):
    total: int
    products: List[Product]
    page: int
    page_size: int 