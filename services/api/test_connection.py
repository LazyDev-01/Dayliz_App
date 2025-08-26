#!/usr/bin/env python3
"""
Test backend connection and payment endpoints
"""

import requests
import json
import sys

def test_backend_connection():
    """Test if backend is running and accessible"""
    print("🔍 Testing Backend Connection...")
    print("=" * 50)
    
    base_url = "http://localhost:8000"
    
    # Test 1: Health check
    try:
        print("1. Testing health endpoint...")
        response = requests.get(f"{base_url}/health", timeout=5)
        if response.status_code == 200:
            print("   ✅ Health check passed")
            print(f"   📊 Response: {response.json()}")
        else:
            print(f"   ❌ Health check failed: {response.status_code}")
            return False
    except requests.exceptions.ConnectionError:
        print("   ❌ Connection failed - Backend not running")
        return False
    except Exception as e:
        print(f"   ❌ Health check error: {e}")
        return False
    
    # Test 2: API docs
    try:
        print("\n2. Testing API documentation...")
        response = requests.get(f"{base_url}/docs", timeout=5)
        if response.status_code == 200:
            print("   ✅ API docs accessible")
        else:
            print(f"   ⚠️ API docs status: {response.status_code}")
    except Exception as e:
        print(f"   ⚠️ API docs error: {e}")
    
    # Test 3: Payment endpoints (without auth)
    try:
        print("\n3. Testing payment endpoint structure...")
        response = requests.post(
            f"{base_url}/api/v1/payments/create-order-with-payment",
            json={"test": "data"},
            timeout=5
        )
        # We expect 401 (unauthorized) or 422 (validation error), not 404
        if response.status_code in [401, 422]:
            print("   ✅ Payment endpoint exists (auth required)")
        elif response.status_code == 404:
            print("   ❌ Payment endpoint not found")
        else:
            print(f"   ℹ️ Payment endpoint status: {response.status_code}")
    except Exception as e:
        print(f"   ⚠️ Payment endpoint test error: {e}")
    
    print("\n" + "=" * 50)
    print("✅ Backend connection test completed!")
    return True

def test_mock_payment_flow():
    """Test the mock payment flow"""
    print("\n🧪 Testing Mock Payment Flow...")
    print("=" * 50)
    
    try:
        # Import and test mock payment service
        import sys
        import os
        sys.path.append(os.path.join(os.path.dirname(__file__), '.'))
        
        from app.services.mock_payment_service import mock_gateway
        import asyncio
        
        async def run_mock_test():
            # Test order creation
            order = await mock_gateway.create_order(
                amount=299.99,
                currency="INR",
                receipt="test_connection_001"
            )
            print(f"✅ Mock order created: {order['id']}")
            
            # Test payment simulation
            payment = await mock_gateway.simulate_payment(order['id'], "upi")
            print(f"✅ Mock payment processed: {payment['status']}")
            
            return True
        
        result = asyncio.run(run_mock_test())
        if result:
            print("✅ Mock payment system working correctly!")
        
    except Exception as e:
        print(f"❌ Mock payment test failed: {e}")
        return False
    
    return True

if __name__ == "__main__":
    print("🚀 Backend Connection & Payment Test")
    print("=" * 60)
    
    # Test backend connection
    backend_ok = test_backend_connection()
    
    # Test mock payment system
    mock_ok = test_mock_payment_flow()
    
    print("\n📋 Test Summary:")
    print(f"Backend Connection: {'✅ PASS' if backend_ok else '❌ FAIL'}")
    print(f"Mock Payment System: {'✅ PASS' if mock_ok else '❌ FAIL'}")
    
    if backend_ok and mock_ok:
        print("\n🎉 All systems ready for testing!")
        print("Next steps:")
        print("1. Start mobile app: flutter run")
        print("2. Test UPI payments (will use mock gateway)")
        print("3. Test COD payments")
    else:
        print("\n⚠️ Some issues found. Check the logs above.")
        sys.exit(1)
