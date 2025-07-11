from sqlalchemy import Boolean, Column, String, Integer, Numeric, DateTime, ForeignKey, Text, JSON
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from sqlalchemy.dialects.postgresql import UUID
from app.db.database import Base
import uuid


class Order(Base):
    __tablename__ = "orders"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), index=True)
    status = Column(String, default="processing")  # processing, out_for_delivery, delivered, cancelled
    total_amount = Column(Numeric(10, 2))  # Using Numeric for money values
    payment_method = Column(String)  # creditCard, wallet, cashOnDelivery, upi
    payment_status = Column(String, default="pending")  # pending, completed, failed, refunded
    payment_id = Column(String, nullable=True)  # Payment gateway ID if applicable
    shipping_address = Column(JSON, nullable=True)  # Store full address as JSON
    billing_address = Column(JSON, nullable=True)  # Store full address as JSON
    address_lat = Column(Numeric(10, 6), nullable=True)  # More precise for coordinates
    address_lng = Column(Numeric(10, 6), nullable=True)  # More precise for coordinates
    driver_id = Column(UUID(as_uuid=True), ForeignKey("drivers.id"), nullable=True)
    tracking_number = Column(String, nullable=True)
    cancellation_reason = Column(String, nullable=True)
    refund_amount = Column(Numeric(10, 2), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    delivered_at = Column(DateTime(timezone=True), nullable=True)

    # Define relationships
    items = relationship("OrderItem", back_populates="order", cascade="all, delete-orphan")


class OrderItem(Base):
    __tablename__ = "order_items"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    order_id = Column(UUID(as_uuid=True), ForeignKey("orders.id"), index=True)
    product_id = Column(UUID(as_uuid=True), ForeignKey("products.id"), index=True)
    name = Column(String, nullable=False)  # Store product name at time of purchase
    image_url = Column(String, nullable=True)  # Store product image at time of purchase
    quantity = Column(Integer, nullable=False)
    price = Column(Numeric(10, 2), nullable=False)  # Price at time of purchase
    discount_amount = Column(Numeric(10, 2), nullable=True)  # Discount at time of purchase
    attributes = Column(JSON, nullable=True)  # Store product attributes (size, color, etc.)

    # Define relationships
    order = relationship("Order", back_populates="items")
    product = relationship("Product")