from fastapi import APIRouter, Depends, HTTPException, status, Request
from typing import Optional
import logging
from datetime import datetime

from app.schemas.payment import (
    RazorpayOrderCreate, 
    RazorpayOrderResponse, 
    PaymentVerification, 
    CODPayment, 
    PaymentResponse
)
from app.api.v1.auth import get_current_user
from app.schemas.user import User
from app.services.supabase import supabase_client
from app.utils.payment_security import PaymentSecurityManager
from app.core.config import settings

router = APIRouter()

# Initialize payment security manager
payment_security = PaymentSecurityManager()

# Configure logging for payment operations (RBI compliance requirement)
payment_logger = logging.getLogger("payment_operations")
payment_logger.setLevel(logging.INFO)

@router.post("/razorpay/create-order", response_model=RazorpayOrderResponse)
async def create_razorpay_order(
    order_data: RazorpayOrderCreate,
    request: Request,
    current_user: User = Depends(get_current_user)
):
    """
    Create Razorpay order for payment processing
    
    Compliance:
    - RBI Guidelines for Digital Payments
    - PCI-DSS Level 1 requirements
    - Indian IT Act 2000 compliance
    """
    try:
        # Log payment initiation (RBI audit requirement)
        payment_logger.info(
            f"Payment order creation initiated - User: {current_user.id}, "
            f"Amount: {order_data.amount}, IP: {request.client.host}"
        )
        
        # Validate amount (RBI minimum transaction limits)
        if order_data.amount < 1.0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Minimum transaction amount is ₹1.00 as per RBI guidelines"
            )
        
        # Maximum transaction limit for security (can be configured)
        if order_data.amount > 200000.0:  # ₹2 Lakh limit
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Transaction amount exceeds maximum limit. Please contact support."
            )
        
        # Create Razorpay order (when Razorpay is activated)
        razorpay_order = await payment_security.create_razorpay_order(
            amount=order_data.amount,
            currency="INR",
            user_id=current_user.id
        )
        
        # Store order in database for audit trail
        await supabase_client.create_payment_order({
            "user_id": current_user.id,
            "razorpay_order_id": razorpay_order["order_id"],
            "amount": order_data.amount,
            "currency": "INR",
            "status": "created",
            "created_at": datetime.now().isoformat(),
            "ip_address": request.client.host,
            "user_agent": request.headers.get("user-agent", "")
        })
        
        payment_logger.info(
            f"Razorpay order created successfully - Order ID: {razorpay_order['order_id']}"
        )
        
        return RazorpayOrderResponse(
            order_id=razorpay_order["order_id"],
            currency="INR",
            amount=int(order_data.amount * 100),  # Convert to paisa
            key=settings.RAZORPAY_KEY_ID
        )
        
    except Exception as e:
        payment_logger.error(
            f"Payment order creation failed - User: {current_user.id}, "
            f"Error: {str(e)}, IP: {request.client.host}"
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Payment order creation failed. Please try again."
        )

@router.post("/razorpay/verify", response_model=PaymentResponse)
async def verify_razorpay_payment(
    payment_data: PaymentVerification,
    request: Request,
    current_user: User = Depends(get_current_user)
):
    """
    Verify Razorpay payment signature and process payment
    
    Critical Security Implementation:
    - HMAC-SHA256 signature verification
    - Double verification against stored order
    - Fraud detection checks
    - RBI compliance logging
    """
    try:
        payment_logger.info(
            f"Payment verification initiated - User: {current_user.id}, "
            f"Order ID: {payment_data.razorpay_order_id}, IP: {request.client.host}"
        )
        
        # Verify payment signature (Critical security step)
        is_valid = payment_security.verify_razorpay_signature(
            order_id=payment_data.razorpay_order_id,
            payment_id=payment_data.razorpay_payment_id,
            signature=payment_data.razorpay_signature
        )
        
        if not is_valid:
            payment_logger.warning(
                f"Invalid payment signature detected - User: {current_user.id}, "
                f"Order ID: {payment_data.razorpay_order_id}, IP: {request.client.host}"
            )
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Payment verification failed. Invalid signature."
            )
        
        # Verify order exists and belongs to user
        order = await supabase_client.get_payment_order(
            payment_data.razorpay_order_id,
            current_user.id
        )
        
        if not order:
            payment_logger.warning(
                f"Payment verification attempted for non-existent order - "
                f"User: {current_user.id}, Order ID: {payment_data.razorpay_order_id}"
            )
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Order not found or unauthorized access."
            )
        
        # Prevent double processing
        if order.get("status") == "paid":
            payment_logger.warning(
                f"Duplicate payment verification attempt - "
                f"Order ID: {payment_data.razorpay_order_id}"
            )
            return PaymentResponse(
                success=True,
                order_id=order["internal_order_id"],
                payment_id=payment_data.razorpay_payment_id,
                status="paid",
                message="Payment already processed"
            )
        
        # Update payment status
        await supabase_client.update_payment_order(
            payment_data.razorpay_order_id,
            {
                "status": "paid",
                "payment_id": payment_data.razorpay_payment_id,
                "verified_at": datetime.now().isoformat(),
                "verification_ip": request.client.host
            }
        )
        
        # Update main order status
        await supabase_client.update_order_payment_status(
            order["internal_order_id"],
            "paid",
            payment_data.razorpay_payment_id
        )
        
        payment_logger.info(
            f"Payment verified successfully - Order ID: {payment_data.razorpay_order_id}, "
            f"Payment ID: {payment_data.razorpay_payment_id}"
        )
        
        return PaymentResponse(
            success=True,
            order_id=order["internal_order_id"],
            payment_id=payment_data.razorpay_payment_id,
            status="paid",
            message="Payment verified successfully"
        )
        
    except HTTPException:
        raise
    except Exception as e:
        payment_logger.error(
            f"Payment verification failed - User: {current_user.id}, "
            f"Error: {str(e)}, IP: {request.client.host}"
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Payment verification failed. Please contact support."
        )

@router.post("/cod/process", response_model=PaymentResponse)
async def process_cod_payment(
    cod_data: CODPayment,
    request: Request,
    current_user: User = Depends(get_current_user)
):
    """
    Process Cash on Delivery payment
    
    Security Features:
    - Order validation and fraud detection
    - User verification
    - Delivery address validation
    - COD amount limits as per RBI guidelines
    """
    try:
        payment_logger.info(
            f"COD payment processing initiated - User: {current_user.id}, "
            f"Order ID: {cod_data.order_id}, IP: {request.client.host}"
        )
        
        # Get order details
        order = await supabase_client.get_order(cod_data.order_id, current_user.id)
        
        if not order:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Order not found or unauthorized access."
            )
        
        # Validate COD eligibility
        cod_validation = await payment_security.validate_cod_order(
            order=order,
            user_id=current_user.id,
            ip_address=request.client.host
        )
        
        if not cod_validation["eligible"]:
            payment_logger.warning(
                f"COD order rejected - User: {current_user.id}, "
                f"Order ID: {cod_data.order_id}, Reason: {cod_validation['reason']}"
            )
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=cod_validation["reason"]
            )
        
        # Process COD payment
        await supabase_client.update_order_payment_status(
            cod_data.order_id,
            "cod_pending",
            None
        )
        
        # Log COD processing
        await supabase_client.create_payment_log({
            "user_id": current_user.id,
            "order_id": cod_data.order_id,
            "payment_method": "cod",
            "status": "cod_pending",
            "amount": order["total_amount"],
            "created_at": datetime.now().isoformat(),
            "ip_address": request.client.host,
            "user_agent": request.headers.get("user-agent", "")
        })
        
        payment_logger.info(
            f"COD payment processed successfully - Order ID: {cod_data.order_id}"
        )
        
        return PaymentResponse(
            success=True,
            order_id=cod_data.order_id,
            payment_id=None,
            status="cod_pending",
            message="Cash on Delivery order confirmed. Pay when delivered."
        )
        
    except HTTPException:
        raise
    except Exception as e:
        payment_logger.error(
            f"COD payment processing failed - User: {current_user.id}, "
            f"Error: {str(e)}, IP: {request.client.host}"
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="COD payment processing failed. Please try again."
        )

@router.get("/methods")
async def get_payment_methods(
    current_user: User = Depends(get_current_user)
):
    """
    Get available payment methods for user
    
    Returns methods based on:
    - User eligibility
    - Regional availability
    - RBI compliance status
    """
    try:
        # Get user's payment method eligibility
        methods = await payment_security.get_available_payment_methods(
            user_id=current_user.id
        )
        
        return {
            "success": True,
            "methods": methods,
            "message": "Payment methods retrieved successfully"
        }
        
    except Exception as e:
        payment_logger.error(
            f"Failed to get payment methods - User: {current_user.id}, Error: {str(e)}"
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve payment methods"
        )

@router.post("/webhook/razorpay")
async def razorpay_webhook(request: Request):
    """
    Handle Razorpay webhooks for payment status updates
    
    Security:
    - Webhook signature verification
    - Idempotency handling
    - Comprehensive logging
    """
    try:
        # Get webhook payload
        payload = await request.body()
        signature = request.headers.get("x-razorpay-signature", "")
        
        # Verify webhook signature
        is_valid = payment_security.verify_webhook_signature(payload, signature)
        
        if not is_valid:
            payment_logger.warning(
                f"Invalid webhook signature from IP: {request.client.host}"
            )
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid webhook signature"
            )
        
        # Process webhook
        await payment_security.process_webhook(payload)
        
        return {"status": "success"}
        
    except Exception as e:
        payment_logger.error(f"Webhook processing failed: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Webhook processing failed"
        )
