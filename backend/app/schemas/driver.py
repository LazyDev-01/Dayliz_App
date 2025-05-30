from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime


class DriverBase(BaseModel):
    user_id: str
    vehicle_type: Optional[str] = None
    vehicle_number: Optional[str] = None


class DriverCreate(DriverBase):
    pass


class DriverUpdate(BaseModel):
    vehicle_type: Optional[str] = None
    vehicle_number: Optional[str] = None
    lat: Optional[float] = None
    lng: Optional[float] = None
    is_available: Optional[bool] = None
    

class DriverLocation(BaseModel):
    lat: float
    lng: float


class DriverInDBBase(DriverBase):
    id: str
    lat: Optional[float] = None
    lng: Optional[float] = None
    is_available: bool
    last_location_update: Optional[datetime] = None
    created_at: datetime
    
    class Config:
        orm_mode = True


class Driver(DriverInDBBase):
    pass


class DriverInDB(DriverInDBBase):
    pass


class DriverList(BaseModel):
    drivers: List[Driver]
    total: int 