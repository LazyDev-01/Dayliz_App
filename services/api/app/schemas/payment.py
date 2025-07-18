from pydantic import BaseModel, Field, field_validator
from typing import Optional, Dict, Any, List
from datetime import datetime
from enum import Enum


class PaymentMethodType(str, Enum):
    UPI = "upi"
    COD = "cod"
    CARD = "card"
    WALLET = "wallet"


class UpiApp(str, Enum):
    GOOGLEPAY = "googlepay"
    PAYTM = "paytm"
    PHONEPE = "phonepe"
    OTHER = "other"


class PaymentStatus(str, Enum):
    PENDING = "pending"
    PROCESSING = "payment_processing"
    COMPLETED = "completed"
    FAILED = "payment_failed"
    TIMEOUT = "payment_timeout"
    REFUNDED = "refunded"


# Enhanced order creation with payment method
class OrderWithPaymentCreate(BaseModel):
    cart_items: List[Dict[str, Any]]
    shipping_address_id: str
    payment_method: PaymentMethodType
    upi_app: Optional[UpiApp] = None
    total_amount: float = Field(..., gt=0, description="Total order amount in rupees")

    @field_validator('upi_app')
    @classmethod
    def validate_upi_app(cls, v, info):
        if info.data.get('payment_method') == PaymentMethodType.UPI and not v:
            raise ValueError('UPI app is required when payment method is UPI')
        return v


class RazorpayOrderCreate(BaseModel):
    internal_order_id: str
    amount: float = Field(..., gt=0, le=200000, description="Amount in rupees (max ₹2 Lakh)")
    upi_app: Optional[UpiApp] = None


class RazorpayOrderResponse(BaseModel):
    order_id: str
    currency: str
    amount: int  # Amount in paisa
    key: str  # Razorpay key_id
    internal_order_id: str
    upi_intent_url: Optional[str] = None
    timeout_at: datetime


class PaymentVerification(BaseModel):
    razorpay_order_id: str
    razorpay_payment_id: str
    razorpay_signature: str


class CODPayment(BaseModel):
    order_id: str  # Internal order ID (UUID)


class PaymentResponse(BaseModel):
    success: bool
    order_id: str  # Internal order ID (UUID)
    payment_id: Optional[str] = None
    status: PaymentStatus
    message: str
    razorpay_order_id: Optional[str] = None


class PaymentStatusResponse(BaseModel):
    order_id: str
    payment_status: PaymentStatus
    razorpay_order_id: Optional[str] = None
    payment_id: Optional[str] = None
    timeout_at: Optional[datetime] = None
    retry_count: int = 0
    can_retry: bool = False
    failure_reason: Optional[str] = None


class PaymentRetryRequest(BaseModel):
    order_id: str
    upi_app: Optional[UpiApp] = None


class WebhookEvent(BaseModel):
    event: str
    payload: Dict[str, Any]
    created_at: datetime