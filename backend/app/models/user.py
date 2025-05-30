from sqlalchemy import Boolean, Column, String, Integer, DateTime, ForeignKey
from sqlalchemy.sql import func
from app.db.database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(String, primary_key=True, index=True)  # Matches Supabase Auth UUID
    email = Column(String, unique=True, index=True)
    name = Column(String)
    phone = Column(String, nullable=True)
    address = Column(String, nullable=True)
    role = Column(String, default="user")  # user, driver, admin
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships are defined in SQLAlchemy but managed by Supabase
    # These are for reference when using SQLAlchemy ORM
    # orders - backref from Order model
    # cart_items - backref from CartItem model
    # driver - backref from Driver model (if role=driver) 