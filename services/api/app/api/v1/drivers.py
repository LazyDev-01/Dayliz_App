from fastapi import APIRouter, Depends, HTTPException, status, Request
from typing import List, Optional
import logging
from datetime import datetime

from app.schemas.driver import Driver, DriverCreate, DriverUpdate, DriverLocation, DriverList
from app.api.v1.auth import get_current_user
from app.schemas.user import User
from app.services.supabase import supabase_client

router = APIRouter()

# Configure logging for driver operations
driver_logger = logging.getLogger("driver_operations")
driver_logger.setLevel(logging.INFO)

@router.get("/", response_model=DriverList)
async def get_drivers(
    skip: int = 0,
    limit: int = 20,
    status_filter: Optional[str] = None,
    zone_id: Optional[str] = None,
    current_user: User = Depends(get_current_user)
):
    """
    Get list of drivers (admin/manager access required)
    """
    try:
        # TODO: Add role-based access control
        # For now, allow all authenticated users
        
        # Validate pagination parameters
        if skip < 0 or limit <= 0 or limit > 100:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid pagination parameters"
            )
        
        # Get drivers from database
        drivers = await supabase_client.get_drivers(
            skip=skip,
            limit=limit,
            status_filter=status_filter,
            zone_id=zone_id
        )
        
        # Get total count for pagination
        total_count = await supabase_client.get_drivers_count(
            status_filter=status_filter,
            zone_id=zone_id
        )
        
        return DriverList(
            drivers=[Driver(**driver) for driver in drivers],
            total=total_count,
            skip=skip,
            limit=limit
        )
        
    except HTTPException:
        raise
    except Exception as e:
        driver_logger.error(
            f"Failed to get drivers - User: {current_user.id}, Error: {str(e)}"
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve drivers"
        )

@router.get("/{driver_id}", response_model=Driver)
async def get_driver(
    driver_id: str,
    current_user: User = Depends(get_current_user)
):
    """
    Get specific driver details
    """
    try:
        driver = await supabase_client.get_driver(driver_id)
        
        if not driver:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Driver not found"
            )
        
        return Driver(**driver)
        
    except HTTPException:
        raise
    except Exception as e:
        driver_logger.error(
            f"Failed to get driver - Driver ID: {driver_id}, "
            f"User: {current_user.id}, Error: {str(e)}"
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve driver"
        )

@router.post("/", response_model=Driver)
async def create_driver(
    driver_data: DriverCreate,
    request: Request,
    current_user: User = Depends(get_current_user)
):
    """
    Create new driver (admin access required)
    """
    try:
        # TODO: Add admin role check
        
        driver_logger.info(
            f"Driver creation initiated - User: {current_user.id}, "
            f"Driver Name: {driver_data.name}, IP: {request.client.host}"
        )
        
        # Validate driver data
        if not driver_data.name or not driver_data.phone:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Driver name and phone are required"
            )
        
        # Validate Indian phone number format
        import re
        if not re.match(r'^[6-9]\d{9}$', driver_data.phone):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid Indian phone number format"
            )
        
        # Create driver in database
        driver_dict = driver_data.dict()
        driver_dict.update({
            "status": "inactive",  # Default status
            "created_at": datetime.now().isoformat(),
            "created_by": current_user.id
        })
        
        created_driver = await supabase_client.create_driver(driver_dict)
        
        if not created_driver:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create driver"
            )
        
        driver_logger.info(
            f"Driver created successfully - Driver ID: {created_driver['id']}, "
            f"User: {current_user.id}"
        )
        
        return Driver(**created_driver)
        
    except HTTPException:
        raise
    except Exception as e:
        driver_logger.error(
            f"Driver creation failed - User: {current_user.id}, "
            f"Error: {str(e)}, IP: {request.client.host}"
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Driver creation failed"
        )

@router.patch("/{driver_id}", response_model=Driver)
async def update_driver(
    driver_id: str,
    driver_update: DriverUpdate,
    request: Request,
    current_user: User = Depends(get_current_user)
):
    """
    Update driver information
    """
    try:
        # Get existing driver
        existing_driver = await supabase_client.get_driver(driver_id)
        
        if not existing_driver:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Driver not found"
            )
        
        driver_logger.info(
            f"Driver update initiated - Driver ID: {driver_id}, "
            f"User: {current_user.id}, IP: {request.client.host}"
        )
        
        # Update driver
        update_data = driver_update.dict(exclude_unset=True)
        update_data["updated_at"] = datetime.now().isoformat()
        update_data["updated_by"] = current_user.id
        
        updated_driver = await supabase_client.update_driver(driver_id, update_data)
        
        if not updated_driver:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to update driver"
            )
        
        driver_logger.info(f"Driver updated successfully - Driver ID: {driver_id}")
        
        return Driver(**updated_driver)
        
    except HTTPException:
        raise
    except Exception as e:
        driver_logger.error(
            f"Driver update failed - Driver ID: {driver_id}, "
            f"User: {current_user.id}, Error: {str(e)}"
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Driver update failed"
        )

@router.post("/{driver_id}/location")
async def update_driver_location(
    driver_id: str,
    location_data: DriverLocation,
    request: Request,
    current_user: User = Depends(get_current_user)
):
    """
    Update driver's current location
    """
    try:
        # Validate location data
        if not (-90 <= location_data.latitude <= 90):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid latitude"
            )
        
        if not (-180 <= location_data.longitude <= 180):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid longitude"
            )
        
        # Update driver location
        location_dict = location_data.dict()
        location_dict.update({
            "driver_id": driver_id,
            "updated_at": datetime.now().isoformat(),
            "ip_address": request.client.host
        })
        
        await supabase_client.update_driver_location(driver_id, location_dict)
        
        return {
            "success": True,
            "message": "Driver location updated successfully",
            "driver_id": driver_id,
            "timestamp": datetime.now().isoformat()
        }
        
    except HTTPException:
        raise
    except Exception as e:
        driver_logger.error(
            f"Driver location update failed - Driver ID: {driver_id}, "
            f"User: {current_user.id}, Error: {str(e)}"
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to update driver location"
        )

@router.get("/nearby/{latitude}/{longitude}")
async def get_nearby_drivers(
    latitude: float,
    longitude: float,
    radius_km: float = 5.0,
    current_user: User = Depends(get_current_user)
):
    """
    Get drivers near a specific location
    """
    try:
        # Validate coordinates
        if not (-90 <= latitude <= 90):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid latitude"
            )
        
        if not (-180 <= longitude <= 180):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid longitude"
            )
        
        # Validate radius
        if radius_km <= 0 or radius_km > 50:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Radius must be between 0 and 50 km"
            )
        
        # Get nearby drivers
        nearby_drivers = await supabase_client.get_nearby_drivers(
            latitude=latitude,
            longitude=longitude,
            radius_km=radius_km
        )
        
        return {
            "success": True,
            "drivers": nearby_drivers,
            "search_location": {
                "latitude": latitude,
                "longitude": longitude
            },
            "radius_km": radius_km,
            "count": len(nearby_drivers)
        }
        
    except HTTPException:
        raise
    except Exception as e:
        driver_logger.error(
            f"Nearby drivers search failed - Lat: {latitude}, Lng: {longitude}, "
            f"User: {current_user.id}, Error: {str(e)}"
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to search nearby drivers"
        )

@router.get("/{driver_id}/orders")
async def get_driver_orders(
    driver_id: str,
    skip: int = 0,
    limit: int = 20,
    status_filter: Optional[str] = None,
    current_user: User = Depends(get_current_user)
):
    """
    Get orders assigned to a specific driver
    """
    try:
        # Validate pagination parameters
        if skip < 0 or limit <= 0 or limit > 100:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid pagination parameters"
            )
        
        # Get driver orders
        orders = await supabase_client.get_driver_orders(
            driver_id=driver_id,
            skip=skip,
            limit=limit,
            status_filter=status_filter
        )
        
        # Get total count
        total_count = await supabase_client.get_driver_orders_count(
            driver_id=driver_id,
            status_filter=status_filter
        )
        
        return {
            "success": True,
            "orders": orders,
            "total": total_count,
            "skip": skip,
            "limit": limit,
            "driver_id": driver_id
        }
        
    except HTTPException:
        raise
    except Exception as e:
        driver_logger.error(
            f"Failed to get driver orders - Driver ID: {driver_id}, "
            f"User: {current_user.id}, Error: {str(e)}"
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve driver orders"
        )
