from sqlalchemy import Boolean, Column, String, Integer, Float, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.database import Base


class Driver(Base):
    __tablename__ = "drivers"

    id = Column(String, primary_key=True)  # Using user_id as ID
    user_id = Column(String, ForeignKey("users.id"), unique=True, index=True)
    vehicle_type = Column(String, nullable=True)
    vehicle_number = Column(String, nullable=True)
    lat = Column(Float, nullable=True)
    lng = Column(Float, nullable=True)
    is_available = Column(Boolean, default=True)
    last_location_update = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Define relationships
    # orders - backref from Order model 