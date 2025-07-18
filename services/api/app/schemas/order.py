from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from app.schemas.product import Product


class OrderItemBase(BaseModel):
    product_id: int
    quantity: int


class OrderItemCreate(OrderItemBase):
    price: float


class OrderItemInDBBase(OrderItemBase):
    id: int
    order_id: int
    price: float
    
    class Config:
        from_attributes = True


class OrderItem(OrderItemInDBBase):
    pass


class OrderItemWithProduct(OrderItem):
    product: Product


class OrderBase(BaseModel):
    address: str
    address_lat: Optional[float] = None
    address_lng: Optional[float] = None
    payment_method: str


class OrderCreate(OrderBase):
    total_price: float
    items: List[OrderItemCreate]


class OrderUpdate(BaseModel):
    status: Optional[str] = None
    payment_status: Optional[str] = None
    driver_id: Optional[str] = None


class OrderInDBBase(OrderBase):
    id: int
    user_id: str
    status: str
    total_price: float
    payment_status: str
    payment_id: Optional[str] = None
    driver_id: Optional[str] = None
    created_at: datetime
    updated_at: Optional[datetime] = None
    delivered_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True


class Order(OrderInDBBase):
    pass


class OrderInDB(OrderInDBBase):
    pass


class OrderWithItems(Order):
    items: List[OrderItemWithProduct]


class OrderList(BaseModel):
    orders: List[Order]
    total: int
    page: int
    page_size: int 