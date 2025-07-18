from fastapi import APIRouter, Depends, HTTPException, status, Request
from typing import Optional
import logging
from datetime import datetime

from app.schemas.payment import (
    RazorpayOrderCreate,
    RazorpayOrderResponse,
    PaymentVerification,
    CODPayment,
    PaymentResponse,
    OrderWithPaymentCreate,
    PaymentStatusResponse,
    PaymentRetryRequest,
    PaymentStatus,
    UpiApp
)
from app.api.v1.auth import get_current_user
from app.schemas.user import User
from app.services.supabase import supabase_client
from app.utils.payment_security import PaymentSecurityManager
from app.services.payment_service import payment_service
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


# ============================================================================
# ENHANCED UPI PAYMENT ENDPOINTS
# ============================================================================

@router.post("/create-order-with-payment")
async def create_order_with_payment(
    order_data: OrderWithPaymentCreate,
    request: Request,
    current_user: User = Depends(get_current_user)
):
    """
    Enhanced order creation with integrated payment processing

    Flow:
    1. Create order with status 'pending_payment' (for UPI) or 'processing' (for COD)
    2. For UPI: Create Razorpay order and return payment details
    3. For COD: Mark order as confirmed

    Security Features:
    - Amount validation against RBI limits
    - User authentication required
    - Comprehensive audit logging
    - Fraud detection integration
    """
    try:
        payment_logger.info(
            f"Enhanced order creation initiated - User: {current_user.id}, "
            f"Amount: ₹{order_data.total_amount}, Payment: {order_data.payment_method}, "
            f"IP: {request.client.host}"
        )

        # Create order with payment processing
        result = await payment_service.create_order_with_payment(
            order_data=order_data,
            user_id=current_user.id,
            ip_address=request.client.host,
            user_agent=request.headers.get("user-agent", "")
        )

        payment_logger.info(
            f"Order created successfully - Order ID: {result['order_id']}, "
            f"Payment Required: {result['payment_required']}"
        )

        return result

    except HTTPException:
        raise
    except Exception as e:
        payment_logger.error(
            f"Enhanced order creation failed - User: {current_user.id}, "
            f"Error: {str(e)}, IP: {request.client.host}"
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Order creation failed. Please try again."
        )


@router.get("/status/{order_id}", response_model=PaymentStatusResponse)
async def get_payment_status(
    order_id: str,
    current_user: User = Depends(get_current_user)
):
    """
    Get current payment status for an order

    Used for:
    - Real-time payment status updates
    - Timeout detection
    - Retry eligibility checking
    - Progress tracking
    """
    try:
        # Get order details
        order = await supabase_client.get_order(order_id, current_user.id)

        if not order:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Order not found or unauthorized access."
            )

        # Get payment order details if exists
        payment_order = None
        if order.get("razorpay_order_id"):
            payment_order = await supabase_client.get_payment_order(
                order["razorpay_order_id"]
            )

        # Determine if retry is possible
        can_retry = (
            order.get("payment_status") in ["payment_failed", "payment_timeout"] and
            order.get("payment_retry_count", 0) < 3
        )

        return PaymentStatusResponse(
            order_id=order_id,
            payment_status=order.get("payment_status", "pending"),
            razorpay_order_id=order.get("razorpay_order_id"),
            payment_id=order.get("payment_id"),
            timeout_at=order.get("payment_timeout_at"),
            retry_count=order.get("payment_retry_count", 0),
            can_retry=can_retry,
            failure_reason=payment_order.get("failure_reason") if payment_order else None
        )

    except HTTPException:
        raise
    except Exception as e:
        payment_logger.error(f"Payment status check failed: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get payment status"
        )


@router.post("/retry/{order_id}")
async def retry_payment(
    order_id: str,
    retry_data: PaymentRetryRequest,
    request: Request,
    current_user: User = Depends(get_current_user)
):
    """
    Retry failed payment for an order

    Features:
    - Maximum 3 retry attempts
    - New Razorpay order creation
    - Updated timeout handling
    - Comprehensive logging
    """
    try:
        payment_logger.info(
            f"Payment retry initiated - User: {current_user.id}, "
            f"Order: {order_id}, IP: {request.client.host}"
        )

        # Get order details
        order = await supabase_client.get_order(order_id, current_user.id)

        if not order:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Order not found or unauthorized access."
            )

        # Check retry eligibility
        if order.get("payment_status") not in ["payment_failed", "payment_timeout"]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Payment retry not allowed for current order status."
            )

        retry_count = order.get("payment_retry_count", 0)
        if retry_count >= 3:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Maximum retry attempts exceeded."
            )

        # Create new Razorpay order for retry
        razorpay_response = await payment_service._create_razorpay_order(
            order_id=order_id,
            amount=float(order["total_amount"]),
            user_id=current_user.id,
            upi_app=retry_data.upi_app,
            ip_address=request.client.host,
            user_agent=request.headers.get("user-agent", "")
        )

        # Update retry count
        await supabase_client.update_order(order_id, {
            "payment_retry_count": retry_count + 1,
            "payment_status": "payment_processing",
            "updated_at": datetime.now().isoformat()
        })

        payment_logger.info(
            f"Payment retry successful - Order: {order_id}, "
            f"Retry Count: {retry_count + 1}"
        )

        return {
            "success": True,
            "message": "Payment retry initiated",
            "razorpay_order": razorpay_response,
            "retry_count": retry_count + 1
        }

    except HTTPException:
        raise
    except Exception as e:
        payment_logger.error(f"Payment retry failed: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Payment retry failed. Please try again."
        )
