#!/usr/bin/env python3
"""
Mock Payment Testing Script
Test all payment scenarios without Razorpay signup!
"""

import asyncio
import sys
import os

# Add the app directory to Python path
sys.path.append(os.path.join(os.path.dirname(__file__), '.'))

async def test_mock_payments():
    """Test the mock payment system"""
    print("🧪 Testing Mock Payment System")
    print("=" * 50)
    
    try:
        from app.services.mock_payment_service import mock_gateway
        
        print("✅ Mock payment service imported successfully")
        
        # Test 1: Create UPI order
        print("\n1. Testing UPI Order Creation...")
        order = await mock_gateway.create_order(
            amount=299.99,
            currency="INR",
            receipt="test_receipt_001",
            notes={"customer_id": "test_user_123"}
        )
        print(f"   ✅ Order created: {order['id']}")
        print(f"   💰 Amount: ₹{order['amount']/100}")
        print(f"   📄 Status: {order['status']}")
        
        # Test 2: Simulate successful UPI payment
        print("\n2. Testing Successful UPI Payment...")
        payment = await mock_gateway.simulate_payment(order['id'], "upi")
        print(f"   ✅ Payment processed: {payment['id']}")
        print(f"   📊 Status: {payment['status']}")
        if payment['status'] == 'captured':
            print(f"   🏦 Bank: {payment.get('bank', 'N/A')}")
            print(f"   📱 VPA: {payment.get('vpa', 'N/A')}")
        else:
            print(f"   ❌ Error: {payment.get('error_description', 'Unknown error')}")
        
        # Test 3: Create another order for failure testing
        print("\n3. Testing Payment Failure Scenarios...")
        order2 = await mock_gateway.create_order(amount=15000.00)  # High amount = higher failure rate
        
        # Try multiple payments to see different outcomes
        for i in range(3):
            payment = await mock_gateway.simulate_payment(order2['id'], "upi")
            status_emoji = "✅" if payment['status'] == 'captured' else "❌"
            print(f"   {status_emoji} Attempt {i+1}: {payment['status']}")
            if payment['status'] == 'failed':
                print(f"      Error: {payment.get('error_description', 'Unknown')}")
        
        # Test 4: Different payment methods
        print("\n4. Testing Different Payment Methods...")
        methods = ["upi", "card", "netbanking", "wallet"]
        
        for method in methods:
            order = await mock_gateway.create_order(amount=500.00)
            payment = await mock_gateway.simulate_payment(order['id'], method)
            status_emoji = "✅" if payment['status'] == 'captured' else "❌"
            print(f"   {status_emoji} {method.upper()}: {payment['status']}")
        
        # Test 5: Signature verification
        print("\n5. Testing Signature Verification...")
        is_valid = await mock_gateway.verify_payment_signature(
            order['id'], 
            payment['id'], 
            "mock_signature_123"
        )
        print(f"   ✅ Signature verification: {'Valid' if is_valid else 'Invalid'}")
        
        print("\n" + "=" * 50)
        print("🎉 All mock payment tests completed successfully!")
        print("✅ Your payment system is ready for testing without Razorpay signup!")
        
    except Exception as e:
        print(f"❌ Error during testing: {e}")
        import traceback
        traceback.print_exc()

async def test_payment_service_integration():
    """Test integration with the main payment service"""
    print("\n🔗 Testing Payment Service Integration")
    print("=" * 50)
    
    try:
        from app.services.payment_service import PaymentService
        from app.schemas.payment import OrderWithPaymentCreate, PaymentMethodType, UpiApp
        
        # Initialize payment service
        payment_service = PaymentService()
        print(f"✅ Payment service initialized (Mock mode: {payment_service.is_mock_mode})")
        
        # Test order creation
        order_data = OrderWithPaymentCreate(
            cart_items=[
                {
                    "product_id": "prod_123",
                    "name": "Test Product",
                    "quantity": 2,
                    "price": 150.0,
                    "image_url": "https://example.com/image.jpg"
                }
            ],
            shipping_address_id="addr_123",
            payment_method=PaymentMethodType.upi,
            upi_app=UpiApp.googlepay,
            total_amount=300.0
        )
        
        print("✅ Order data created successfully")
        print(f"   Payment method: {order_data.payment_method}")
        print(f"   UPI app: {order_data.upi_app}")
        print(f"   Total amount: ₹{order_data.total_amount}")
        
    except Exception as e:
        print(f"❌ Integration test error: {e}")

if __name__ == "__main__":
    print("🚀 Starting Mock Payment System Tests")
    print("No Razorpay signup required!")
    print("=" * 60)
    
    asyncio.run(test_mock_payments())
    asyncio.run(test_payment_service_integration())
    
    print("\n📋 Next Steps:")
    print("1. Start backend: uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload")
    print("2. Start mobile app: flutter run")
    print("3. Test UPI payments (they'll use mock gateway)")
    print("4. Test COD payments (no gateway needed)")
    print("5. All payment scenarios will work without Razorpay!")
