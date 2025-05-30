from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from app.schemas.product import Product


class CartItemBase(BaseModel):
    product_id: int
    quantity: int


class CartItemCreate(CartItemBase):
    pass


class CartItemUpdate(BaseModel):
    quantity: int


class CartItemInDBBase(CartItemBase):
    id: int
    user_id: str
    created_at: datetime
    
    class Config:
        orm_mode = True


class CartItem(CartItemInDBBase):
    pass


class CartItemInDB(CartItemInDBBase):
    pass


class CartItemWithProduct(CartItem):
    product: Product


class Cart(BaseModel):
    items: List[CartItemWithProduct]
    total: float 