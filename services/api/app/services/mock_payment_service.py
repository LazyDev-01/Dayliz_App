"""
Mock Payment Service - Complete Payment Testing Without Razorpay Signup
Simulates all payment scenarios for comprehensive testing
"""

import asyncio
import random
import uuid
from datetime import datetime, timedelta
from typing import Dict, Any, Optional
import logging

logger = logging.getLogger(__name__)

class MockPaymentGateway:
    """
    Complete mock payment gateway that simulates:
    - UPI payments (Google Pay, PhonePe, Paytm)
    - Card payments
    - Wallet payments
    - Payment failures
    - Network timeouts
    - Success scenarios
    """
    
    def __init__(self):
        self.orders = {}  # Store mock orders
        self.payments = {}  # Store mock payments
        
    async def create_order(self, amount: float, currency: str = "INR", **kwargs) -> Dict[str, Any]:
        """Create a mock Razorpay order"""
        order_id = f"order_mock_{uuid.uuid4().hex[:12]}"
        
        mock_order = {
            "id": order_id,
            "entity": "order",
            "amount": int(amount * 100),  # Convert to paisa
            "amount_paid": 0,
            "amount_due": int(amount * 100),
            "currency": currency,
            "receipt": kwargs.get("receipt", f"receipt_{order_id}"),
            "status": "created",
            "attempts": 0,
            "created_at": int(datetime.now().timestamp()),
            "notes": kwargs.get("notes", {}),
        }
        
        self.orders[order_id] = mock_order
        logger.info(f"Mock order created: {order_id} for ₹{amount}")
        
        return mock_order
    
    async def simulate_payment(self, order_id: str, payment_method: str = "upi") -> Dict[str, Any]:
        """
        Simulate payment processing with realistic scenarios
        """
        if order_id not in self.orders:
            raise ValueError(f"Order {order_id} not found")
        
        order = self.orders[order_id]
        payment_id = f"pay_mock_{uuid.uuid4().hex[:12]}"
        
        # Simulate processing delay
        await asyncio.sleep(random.uniform(1, 3))
        
        # Simulate different payment outcomes based on amount
        amount = order["amount"] / 100
        success_rate = self._get_success_rate(amount, payment_method)
        
        if random.random() < success_rate:
            # Successful payment
            payment = {
                "id": payment_id,
                "entity": "payment",
                "amount": order["amount"],
                "currency": order["currency"],
                "status": "captured",
                "order_id": order_id,
                "method": payment_method,
                "amount_refunded": 0,
                "refund_status": None,
                "captured": True,
                "description": f"Mock payment via {payment_method}",
                "card_id": None,
                "bank": self._get_mock_bank(payment_method),
                "wallet": None,
                "vpa": self._get_mock_vpa(payment_method) if payment_method == "upi" else None,
                "email": "test@example.com",
                "contact": "+919876543210",
                "created_at": int(datetime.now().timestamp()),
                "fee": int(amount * 0.02 * 100),  # 2% fee simulation
                "tax": int(amount * 0.0036 * 100),  # 18% GST on fee
                "error_code": None,
                "error_description": None,
            }
            
            # Update order status
            order["status"] = "paid"
            order["amount_paid"] = order["amount"]
            order["amount_due"] = 0
            
        else:
            # Failed payment
            error_scenarios = self._get_error_scenarios(payment_method)
            error = random.choice(error_scenarios)
            
            payment = {
                "id": payment_id,
                "entity": "payment",
                "amount": order["amount"],
                "currency": order["currency"],
                "status": "failed",
                "order_id": order_id,
                "method": payment_method,
                "captured": False,
                "description": f"Failed mock payment via {payment_method}",
                "created_at": int(datetime.now().timestamp()),
                "error_code": error["code"],
                "error_description": error["description"],
                "error_source": error["source"],
                "error_step": error["step"],
                "error_reason": error["reason"],
            }
        
        self.payments[payment_id] = payment
        logger.info(f"Mock payment processed: {payment_id} - Status: {payment['status']}")
        
        return payment
    
    def _get_success_rate(self, amount: float, payment_method: str) -> float:
        """Calculate success rate based on amount and payment method"""
        base_rates = {
            "upi": 0.95,
            "card": 0.90,
            "netbanking": 0.85,
            "wallet": 0.92,
        }
        
        base_rate = base_rates.get(payment_method, 0.90)
        
        # Lower success rate for very high amounts
        if amount > 10000:
            base_rate *= 0.8
        elif amount > 5000:
            base_rate *= 0.9
        
        return base_rate
    
    def _get_mock_bank(self, payment_method: str) -> Optional[str]:
        """Get mock bank based on payment method"""
        banks = {
            "upi": ["HDFC", "ICICI", "SBI", "AXIS", "KOTAK"],
            "card": ["HDFC", "ICICI", "SBI", "AXIS", "KOTAK", "CITI"],
            "netbanking": ["HDFC", "ICICI", "SBI", "AXIS", "KOTAK"],
        }
        
        if payment_method in banks:
            return random.choice(banks[payment_method])
        return None
    
    def _get_mock_vpa(self, payment_method: str) -> Optional[str]:
        """Get mock VPA for UPI payments"""
        if payment_method == "upi":
            vpas = [
                "user@googlepay",
                "user@phonepe",
                "user@paytm",
                "user@amazonpay",
                "user@bhim",
            ]
            return random.choice(vpas)
        return None
    
    def _get_error_scenarios(self, payment_method: str) -> list:
        """Get realistic error scenarios for different payment methods"""
        common_errors = [
            {
                "code": "BAD_REQUEST_ERROR",
                "description": "Payment failed due to insufficient funds",
                "source": "customer",
                "step": "payment_authentication",
                "reason": "insufficient_funds"
            },
            {
                "code": "GATEWAY_ERROR",
                "description": "Payment failed due to a temporary issue",
                "source": "bank",
                "step": "authorization",
                "reason": "bank_failure"
            },
            {
                "code": "BAD_REQUEST_ERROR",
                "description": "Payment cancelled by user",
                "source": "customer",
                "step": "payment_capture",
                "reason": "payment_cancelled"
            },
        ]
        
        upi_errors = [
            {
                "code": "BAD_REQUEST_ERROR",
                "description": "UPI PIN incorrect",
                "source": "customer",
                "step": "payment_authentication",
                "reason": "invalid_upi_pin"
            },
            {
                "code": "GATEWAY_ERROR",
                "description": "UPI app not responding",
                "source": "bank",
                "step": "payment_authentication",
                "reason": "upi_app_timeout"
            },
        ]
        
        if payment_method == "upi":
            return common_errors + upi_errors
        
        return common_errors
    
    async def verify_payment_signature(self, order_id: str, payment_id: str, signature: str) -> bool:
        """Mock signature verification - always returns True for testing"""
        logger.info(f"Mock signature verification: order={order_id}, payment={payment_id}")
        
        # Simulate verification delay
        await asyncio.sleep(0.1)
        
        # In mock mode, we always verify successfully
        return True
    
    def get_payment_status(self, payment_id: str) -> Optional[Dict[str, Any]]:
        """Get payment status"""
        return self.payments.get(payment_id)
    
    def get_order_status(self, order_id: str) -> Optional[Dict[str, Any]]:
        """Get order status"""
        return self.orders.get(order_id)

# Global mock payment gateway instance
mock_gateway = MockPaymentGateway()

async def create_mock_order(amount: float, currency: str = "INR", **kwargs) -> Dict[str, Any]:
    """Create a mock order"""
    return await mock_gateway.create_order(amount, currency, **kwargs)

async def process_mock_payment(order_id: str, payment_method: str = "upi") -> Dict[str, Any]:
    """Process a mock payment"""
    return await mock_gateway.simulate_payment(order_id, payment_method)

async def verify_mock_signature(order_id: str, payment_id: str, signature: str) -> bool:
    """Verify mock payment signature"""
    return await mock_gateway.verify_payment_signature(order_id, payment_id, signature)
