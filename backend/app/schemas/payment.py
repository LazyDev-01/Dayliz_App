from pydantic import BaseModel
from typing import Optional, Dict, Any
from datetime import datetime


class RazorpayOrderCreate(BaseModel):
    amount: float  # Amount in rupees


class RazorpayOrderResponse(BaseModel):
    order_id: str
    currency: str
    amount: int  # Amount in paisa
    key: str  # Razorpay key_id


class PaymentVerification(BaseModel):
    razorpay_order_id: str
    razorpay_payment_id: str
    razorpay_signature: str


class CODPayment(BaseModel):
    order_id: int  # Internal order ID


class PaymentResponse(BaseModel):
    success: bool
    order_id: int  # Internal order ID
    payment_id: Optional[str] = None
    status: str  # "pending", "paid", "failed"
    message: str 