#!/usr/bin/env python3
"""
Simple test server to verify mobile app connectivity
"""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
import json
from datetime import datetime

app = FastAPI(title="Dayliz Test Server", version="1.0.0")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    return {"message": "Dayliz Test Server is running!", "timestamp": datetime.now().isoformat()}

@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "service": "dayliz-test-server",
        "timestamp": datetime.now().isoformat(),
        "version": "1.0.0"
    }

@app.post("/api/v1/payments/create-order-with-payment")
async def create_test_order():
    """Mock endpoint for testing mobile app connectivity"""
    return {
        "success": True,
        "order_id": f"test_order_{datetime.now().strftime('%Y%m%d%H%M%S')}",
        "payment_required": True,
        "razorpay_order": {
            "order_id": f"rzp_test_{datetime.now().strftime('%Y%m%d%H%M%S')}",
            "currency": "INR",
            "amount": 29999,  # ₹299.99 in paisa
            "key": "rzp_test_mock_payment_gateway",
            "internal_order_id": f"internal_{datetime.now().strftime('%Y%m%d%H%M%S')}",
            "upi_intent_url": None,
            "timeout_at": datetime.now().isoformat()
        },
        "message": "Test order created successfully"
    }

@app.post("/api/v1/payments/razorpay/verify")
async def verify_test_payment():
    """Mock endpoint for payment verification"""
    return {
        "success": True,
        "order_id": f"verified_order_{datetime.now().strftime('%Y%m%d%H%M%S')}",
        "payment_id": f"pay_test_{datetime.now().strftime('%Y%m%d%H%M%S')}",
        "status": "completed",
        "message": "Payment verified successfully"
    }

@app.post("/api/v1/payments/cod/process")
async def process_test_cod():
    """Mock endpoint for COD processing"""
    return {
        "success": True,
        "order_id": f"cod_order_{datetime.now().strftime('%Y%m%d%H%M%S')}",
        "payment_id": None,
        "status": "confirmed",
        "message": "COD order processed successfully"
    }

@app.get("/api/v1/payments/status/{order_id}")
async def get_test_payment_status(order_id: str):
    """Mock endpoint for payment status"""
    return {
        "order_id": order_id,
        "status": "completed",
        "payment_method": "upi",
        "amount": 299.99,
        "timestamp": datetime.now().isoformat()
    }

if __name__ == "__main__":
    print("🚀 Starting Dayliz Test Server...")
    print("📱 This server will help test mobile app connectivity")
    print("🔗 Server will run on: http://127.0.0.1:8000")
    print("📋 Available endpoints:")
    print("   GET  /health")
    print("   POST /api/v1/payments/create-order-with-payment")
    print("   POST /api/v1/payments/razorpay/verify")
    print("   POST /api/v1/payments/cod/process")
    print("   GET  /api/v1/payments/status/{order_id}")
    print("=" * 60)
    
    uvicorn.run(
        app, 
        host="127.0.0.1", 
        port=8000, 
        log_level="info",
        access_log=True
    )
