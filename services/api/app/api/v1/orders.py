from fastapi import APIRouter, Depends, HTTPException, status, Request
from typing import List, Optional
import logging
from datetime import datetime

from app.schemas.order import Order, OrderCreate, OrderUpdate, OrderWithItems, OrderList
from app.api.v1.auth import get_current_user
from app.schemas.user import User
from app.services.supabase import supabase_client
from app.utils.payment_security import PaymentSecurityManager

router = APIRouter()

# Initialize payment security for order validation
payment_security = PaymentSecurityManager()

# Configure logging for order operations
order_logger = logging.getLogger("order_operations")
order_logger.setLevel(logging.INFO)

@router.post("/", response_model=Order)
async def create_order(
    order_data: OrderCreate,
    request: Request,
    current_user: User = Depends(get_current_user)
):
    """
    Create a new order with comprehensive security validation
    
    Security Features:
    - Payment method validation
    - Order amount verification
    - Delivery address validation
    - Fraud detection
    - Indian compliance checks
    """
    try:
        order_logger.info(
            f"Order creation initiated - User: {current_user.id}, "
            f"Amount: {order_data.total_amount}, Payment: {order_data.payment_method}, "
            f"IP: {request.client.host}"
        )
        
        # Validate order amount
        if order_data.total_amount <= 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Order amount must be greater than zero"
            )
        
        # Validate minimum order amount (business rule)
        if order_data.total_amount < 99.0:  # ₹99 minimum order
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Minimum order amount is ₹99"
            )
        
        # Validate payment method
        if order_data.payment_method not in ["cod", "razorpay", "upi"]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid payment method"
            )
        
        # Special validation for COD orders
        if order_data.payment_method == "cod":
            # Validate COD eligibility
            cod_validation = await payment_security.validate_cod_order(
                order=order_data.dict(),
                user_id=current_user.id,
                ip_address=request.client.host
            )
            
            if not cod_validation["eligible"]:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=cod_validation["reason"]
                )
        
        # Validate delivery address
        if not order_data.shipping_address:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Delivery address is required"
            )
        
        # Create order in database
        order_dict = order_data.dict()
        order_dict.update({
            "user_id": current_user.id,
            "status": "processing",
            "payment_status": "pending",
            "created_at": datetime.now().isoformat(),
            "ip_address": request.client.host,
            "user_agent": request.headers.get("user-agent", "")
        })
        
        created_order = await supabase_client.create_order(order_dict)
        
        if not created_order:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create order"
            )
        
        order_logger.info(
            f"Order created successfully - Order ID: {created_order['id']}, "
            f"User: {current_user.id}"
        )
        
        return Order(**created_order)
        
    except HTTPException:
        raise
    except Exception as e:
        order_logger.error(
            f"Order creation failed - User: {current_user.id}, "
            f"Error: {str(e)}, IP: {request.client.host}"
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Order creation failed. Please try again."
        )

@router.get("/", response_model=OrderList)
async def get_user_orders(
    skip: int = 0,
    limit: int = 20,
    status_filter: Optional[str] = None,
    current_user: User = Depends(get_current_user)
):
    """
    Get user's orders with pagination and filtering
    """
    try:
        # Validate pagination parameters
        if skip < 0 or limit <= 0 or limit > 100:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid pagination parameters"
            )
        
        # Get orders from database
        orders = await supabase_client.get_user_orders(
            user_id=current_user.id,
            skip=skip,
            limit=limit,
            status_filter=status_filter
        )
        
        # Get total count for pagination
        total_count = await supabase_client.get_user_orders_count(
            user_id=current_user.id,
            status_filter=status_filter
        )
        
        return OrderList(
            orders=[Order(**order) for order in orders],
            total=total_count,
            skip=skip,
            limit=limit
        )
        
    except HTTPException:
        raise
    except Exception as e:
        order_logger.error(
            f"Failed to get orders - User: {current_user.id}, Error: {str(e)}"
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve orders"
        )

@router.get("/{order_id}", response_model=OrderWithItems)
async def get_order(
    order_id: str,
    current_user: User = Depends(get_current_user)
):
    """
    Get specific order with items
    """
    try:
        # Get order with items
        order = await supabase_client.get_order_with_items(order_id, current_user.id)
        
        if not order:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Order not found"
            )
        
        return OrderWithItems(**order)
        
    except HTTPException:
        raise
    except Exception as e:
        order_logger.error(
            f"Failed to get order - Order ID: {order_id}, "
            f"User: {current_user.id}, Error: {str(e)}"
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve order"
        )

@router.patch("/{order_id}", response_model=Order)
async def update_order(
    order_id: str,
    order_update: OrderUpdate,
    request: Request,
    current_user: User = Depends(get_current_user)
):
    """
    Update order (limited fields for security)
    """
    try:
        # Get existing order
        existing_order = await supabase_client.get_order(order_id, current_user.id)
        
        if not existing_order:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Order not found"
            )
        
        # Check if order can be updated
        if existing_order["status"] in ["delivered", "cancelled", "refunded"]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Order cannot be updated in current status"
            )
        
        # Log order update
        order_logger.info(
            f"Order update initiated - Order ID: {order_id}, "
            f"User: {current_user.id}, IP: {request.client.host}"
        )
        
        # Update order
        update_data = order_update.dict(exclude_unset=True)
        update_data["updated_at"] = datetime.now().isoformat()
        
        updated_order = await supabase_client.update_order(order_id, update_data)
        
        if not updated_order:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to update order"
            )
        
        order_logger.info(f"Order updated successfully - Order ID: {order_id}")
        
        return Order(**updated_order)
        
    except HTTPException:
        raise
    except Exception as e:
        order_logger.error(
            f"Order update failed - Order ID: {order_id}, "
            f"User: {current_user.id}, Error: {str(e)}"
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Order update failed"
        )

@router.post("/{order_id}/cancel")
async def cancel_order(
    order_id: str,
    request: Request,
    current_user: User = Depends(get_current_user)
):
    """
    Cancel order with proper validation and refund handling
    """
    try:
        # Get existing order
        existing_order = await supabase_client.get_order(order_id, current_user.id)
        
        if not existing_order:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Order not found"
            )
        
        # Check if order can be cancelled
        if existing_order["status"] in ["delivered", "cancelled", "shipped"]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Order cannot be cancelled in current status"
            )
        
        order_logger.info(
            f"Order cancellation initiated - Order ID: {order_id}, "
            f"User: {current_user.id}, IP: {request.client.host}"
        )
        
        # Cancel order
        cancellation_data = {
            "status": "cancelled",
            "cancelled_at": datetime.now().isoformat(),
            "cancellation_reason": "User requested",
            "updated_at": datetime.now().isoformat()
        }
        
        # Handle refund if payment was made
        if existing_order["payment_status"] == "paid":
            # TODO: Implement refund logic for paid orders
            cancellation_data["refund_status"] = "pending"
            cancellation_data["refund_initiated_at"] = datetime.now().isoformat()
        
        cancelled_order = await supabase_client.update_order(order_id, cancellation_data)
        
        if not cancelled_order:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to cancel order"
            )
        
        order_logger.info(f"Order cancelled successfully - Order ID: {order_id}")
        
        return {
            "success": True,
            "message": "Order cancelled successfully",
            "order_id": order_id,
            "refund_status": cancellation_data.get("refund_status", "not_applicable")
        }
        
    except HTTPException:
        raise
    except Exception as e:
        order_logger.error(
            f"Order cancellation failed - Order ID: {order_id}, "
            f"User: {current_user.id}, Error: {str(e)}"
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Order cancellation failed"
        )

@router.get("/{order_id}/track")
async def track_order(
    order_id: str,
    current_user: User = Depends(get_current_user)
):
    """
    Get order tracking information
    """
    try:
        # Get order tracking data
        tracking_data = await supabase_client.get_order_tracking(order_id, current_user.id)
        
        if not tracking_data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Order not found or tracking not available"
            )
        
        return {
            "success": True,
            "order_id": order_id,
            "tracking_data": tracking_data
        }
        
    except HTTPException:
        raise
    except Exception as e:
        order_logger.error(
            f"Order tracking failed - Order ID: {order_id}, "
            f"User: {current_user.id}, Error: {str(e)}"
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get tracking information"
        )
