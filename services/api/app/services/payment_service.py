"""
Enhanced Payment Service for UPI Integration with Razorpay
Handles order creation, payment processing, and status management
"""

import logging
import hmac
import hashlib
import json
from datetime import datetime, timedelta
from typing import Dict, Any, Optional, List
from uuid import UUID

import razorpay
from fastapi import HTTPException, status

from app.core.config import settings
from app.services.supabase import supabase_client
from app.services.mock_payment_service import mock_gateway
from app.schemas.payment import (
    PaymentMethodType, UpiApp, PaymentStatus,
    OrderWithPaymentCreate, RazorpayOrderResponse,
    PaymentStatusResponse
)

logger = logging.getLogger("payment_service")


class PaymentService:
    """Enhanced Payment Service with UPI support"""
    
    def __init__(self):
        self.logger = logger
        self.is_mock_mode = self._is_mock_mode()

        if self.is_mock_mode:
            self.logger.info("🧪 Payment Service initialized in MOCK MODE - No Razorpay signup needed!")
            self.razorpay_client = None
        elif settings.RAZORPAY_KEY_ID and settings.RAZORPAY_KEY_SECRET:
            self.razorpay_client = razorpay.Client(
                auth=(settings.RAZORPAY_KEY_ID, settings.RAZORPAY_KEY_SECRET)
            )
            self.logger.info("Razorpay client initialized successfully")
        else:
            self.razorpay_client = None
            self.logger.warning("Razorpay credentials not configured - using mock mode")

    def _is_mock_mode(self) -> bool:
        """Check if we should use mock payment gateway"""
        return (
            getattr(settings, 'PAYMENT_MODE', '') == 'mock' or
            settings.RAZORPAY_KEY_ID.startswith('rzp_test_mock') or
            settings.RAZORPAY_KEY_SECRET.startswith('mock_')
        )
    
    async def create_order_with_payment(
        self, 
        order_data: OrderWithPaymentCreate, 
        user_id: str,
        ip_address: str,
        user_agent: str
    ) -> Dict[str, Any]:
        """
        Create order and initiate payment process
        
        Flow:
        1. Create order with status 'pending_payment'
        2. If UPI: Create Razorpay order and return payment details
        3. If COD: Mark order as confirmed
        """
        try:
            # Create internal order first
            order_id = await self._create_internal_order(order_data, user_id)
            
            # Log order creation
            await self._log_payment_event(
                user_id=user_id,
                order_id=order_id,
                event_type="order_created",
                event_data={
                    "payment_method": order_data.payment_method,
                    "amount": order_data.total_amount,
                    "upi_app": order_data.upi_app
                },
                ip_address=ip_address
            )
            
            if order_data.payment_method == PaymentMethodType.UPI:
                # Create Razorpay order for UPI payment
                razorpay_response = await self._create_razorpay_order(
                    order_id=order_id,
                    amount=order_data.total_amount,
                    user_id=user_id,
                    upi_app=order_data.upi_app,
                    ip_address=ip_address,
                    user_agent=user_agent
                )
                
                return {
                    "order_id": order_id,
                    "payment_required": True,
                    "payment_method": "upi",
                    "razorpay_order": razorpay_response
                }
                
            elif order_data.payment_method == PaymentMethodType.COD:
                # For COD, mark order as confirmed
                await self._update_order_status(
                    order_id=order_id,
                    status="processing",
                    payment_status=PaymentStatus.PENDING
                )
                
                return {
                    "order_id": order_id,
                    "payment_required": False,
                    "payment_method": "cod",
                    "message": "Order confirmed. Payment on delivery."
                }
            
            else:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Payment method {order_data.payment_method} not supported"
                )
                
        except Exception as e:
            self.logger.error(f"Order creation failed: {str(e)}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Order creation failed. Please try again."
            )
    
    async def _create_internal_order(
        self, 
        order_data: OrderWithPaymentCreate, 
        user_id: str
    ) -> str:
        """Create internal order in database"""
        
        # Calculate timeout (15 minutes for UPI payments)
        timeout_at = None
        if order_data.payment_method == PaymentMethodType.UPI:
            timeout_at = datetime.now() + timedelta(minutes=15)
        
        order_payload = {
            "user_id": user_id,
            "total_amount": order_data.total_amount,
            "status": "pending_payment" if order_data.payment_method == PaymentMethodType.UPI else "processing",
            "payment_method": order_data.payment_method,
            "payment_status": "payment_processing" if order_data.payment_method == PaymentMethodType.UPI else "pending",
            "shipping_address_id": order_data.shipping_address_id,
            "payment_timeout_at": timeout_at.isoformat() if timeout_at else None,
            "payment_method_details": {
                "type": order_data.payment_method,
                "upi_app": order_data.upi_app
            },
            "payment_initiated_at": datetime.now().isoformat()
        }
        
        # Create order in database
        order = await supabase_client.create_order(order_payload)
        
        # Create order items
        for item in order_data.cart_items:
            await supabase_client.create_order_item({
                "order_id": order["id"],
                "product_id": item["product_id"],
                "quantity": item["quantity"],
                "price": item["price"],
                "name": item["name"],
                "image_url": item.get("image_url")
            })
        
        return order["id"]
    
    async def _create_razorpay_order(
        self,
        order_id: str,
        amount: float,
        user_id: str,
        upi_app: Optional[UpiApp],
        ip_address: str,
        user_agent: str
    ) -> RazorpayOrderResponse:
        """Create Razorpay order for UPI payment"""
        
        try:
            # Validate amount
            if amount <= 0 or amount > 200000:
                raise ValueError("Invalid payment amount")
            
            # Create Razorpay order
            if self.razorpay_client:
                # Real Razorpay integration
                razorpay_order = self.razorpay_client.order.create({
                    "amount": int(amount * 100),  # Convert to paisa
                    "currency": "INR",
                    "receipt": f"order_{order_id}",
                    "payment_capture": 1,
                    "notes": {
                        "internal_order_id": order_id,
                        "user_id": user_id,
                        "upi_app": upi_app
                    }
                })
                razorpay_order_id = razorpay_order["id"]
            else:
                # Mock mode for development
                razorpay_order_id = f"order_mock_{datetime.now().strftime('%Y%m%d%H%M%S')}"
            
            # Store payment order in database
            timeout_at = datetime.now() + timedelta(minutes=15)
            
            await supabase_client.create_payment_order({
                "user_id": user_id,
                "internal_order_id": order_id,
                "razorpay_order_id": razorpay_order_id,
                "amount": amount,
                "currency": "INR",
                "status": "created",
                "upi_app": upi_app,
                "timeout_at": timeout_at.isoformat(),
                "ip_address": ip_address,
                "user_agent": user_agent
            })
            
            # Update order with Razorpay order ID
            await supabase_client.update_order(order_id, {
                "razorpay_order_id": razorpay_order_id,
                "payment_timeout_at": timeout_at.isoformat()
            })
            
            # Generate UPI intent URL
            upi_intent_url = self._generate_upi_intent_url(
                razorpay_order_id, amount, upi_app
            )
            
            # Log payment initiation
            await self._log_payment_event(
                user_id=user_id,
                order_id=order_id,
                razorpay_order_id=razorpay_order_id,
                event_type="payment_initiated",
                event_data={
                    "amount": amount,
                    "upi_app": upi_app,
                    "timeout_at": timeout_at.isoformat()
                },
                ip_address=ip_address
            )
            
            return RazorpayOrderResponse(
                order_id=razorpay_order_id,
                currency="INR",
                amount=int(amount * 100),
                key=settings.RAZORPAY_KEY_ID or "mock_key",
                internal_order_id=order_id,
                upi_intent_url=upi_intent_url,
                timeout_at=timeout_at
            )
            
        except Exception as e:
            self.logger.error(f"Razorpay order creation failed: {str(e)}")
            raise
    
    def _generate_upi_intent_url(
        self, 
        razorpay_order_id: str, 
        amount: float, 
        upi_app: Optional[UpiApp]
    ) -> Optional[str]:
        """Generate UPI intent URL for specific apps"""
        
        if not upi_app:
            return None
        
        # UPI parameters
        merchant_vpa = "merchant@razorpay"  # This would be your actual VPA
        merchant_name = "Dayliz"
        transaction_note = f"Payment for order {razorpay_order_id}"
        
        base_upi_url = f"upi://pay?pa={merchant_vpa}&pn={merchant_name}&am={amount}&cu=INR&tn={transaction_note}"
        
        # App-specific URLs
        if upi_app == UpiApp.GOOGLEPAY:
            return f"tez://upi/pay?pa={merchant_vpa}&pn={merchant_name}&am={amount}&cu=INR&tn={transaction_note}"
        elif upi_app == UpiApp.PHONEPE:
            return f"phonepe://pay?pa={merchant_vpa}&pn={merchant_name}&am={amount}&cu=INR&tn={transaction_note}"
        elif upi_app == UpiApp.PAYTM:
            return f"paytmmp://pay?pa={merchant_vpa}&pn={merchant_name}&am={amount}&cu=INR&tn={transaction_note}"
        else:
            return base_upi_url
    
    async def _update_order_status(
        self, 
        order_id: str, 
        status: str, 
        payment_status: PaymentStatus
    ):
        """Update order status in database"""
        await supabase_client.update_order(order_id, {
            "status": status,
            "payment_status": payment_status,
            "updated_at": datetime.now().isoformat()
        })
    
    async def _log_payment_event(
        self,
        user_id: str,
        order_id: str,
        event_type: str,
        event_data: Dict[str, Any],
        ip_address: str,
        razorpay_order_id: Optional[str] = None,
        payment_id: Optional[str] = None,
        severity: str = "info"
    ):
        """Log payment event for audit trail"""
        await supabase_client.create_payment_log({
            "user_id": user_id,
            "order_id": order_id,
            "razorpay_order_id": razorpay_order_id,
            "payment_id": payment_id,
            "event_type": event_type,
            "event_data": event_data,
            "ip_address": ip_address,
            "severity": severity
        })


# Global payment service instance
payment_service = PaymentService()
