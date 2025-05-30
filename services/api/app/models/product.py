from sqlalchemy import Boolean, Column, String, Integer, Float, DateTime, ForeignKey, Text
from sqlalchemy.sql import func
from app.db.database import Base


class Product(Base):
    __tablename__ = "products"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    description = Column(Text, nullable=True)
    price = Column(Float)
    sale_price = Column(Float, nullable=True)
    stock = Column(Integer, default=0)
    category = Column(String, index=True)
    subcategory = Column(String, index=True, nullable=True)
    image_url = Column(String, nullable=True)
    is_featured = Column(Boolean, default=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships are defined in SQLAlchemy but managed by Supabase
    # These are for reference when using SQLAlchemy ORM
    # cart_items - backref from CartItem model
    # order_items - backref from OrderItem model 