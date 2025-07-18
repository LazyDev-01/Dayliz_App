#!/usr/bin/env python3
"""
Quick UPI Payment Endpoint Tests
Simple curl-like tests for payment endpoints
"""

import requests
import json

BASE_URL = "http://localhost:8000"

def test_health():
    """Test API health"""
    try:
        response = requests.get(f"{BASE_URL}/health")
        print(f"Health Check: {response.status_code}")
        if response.status_code == 200:
            print("✅ API is running!")
            return True
        else:
            print("❌ API health check failed")
            return False
    except Exception as e:
        print(f"❌ Cannot connect to API: {e}")
        return False

def test_payment_endpoints():
    """Test payment endpoints without auth"""
    
    print("\n🧪 Testing Payment Endpoints...")
    
    # Test 1: Create UPI Order (will fail without auth, but tests endpoint)
    print("\n1. Testing UPI Order Creation Endpoint...")
    upi_data = {
        "cart_items": [{"product_id": "test", "name": "Test", "quantity": 1, "price": 100}],
        "shipping_address_id": "test-address",
        "payment_method": "upi",
        "upi_app": "googlepay",
        "total_amount": 100.00
    }
    
    try:
        response = requests.post(
            f"{BASE_URL}/api/v1/payments/create-order-with-payment",
            json=upi_data,
            headers={"Content-Type": "application/json"}
        )
        print(f"   Status: {response.status_code}")
        if response.status_code == 401:
            print("   ✅ Endpoint exists (401 = needs auth)")
        elif response.status_code == 422:
            print("   ✅ Endpoint exists (422 = validation error)")
        else:
            print(f"   Response: {response.text[:200]}...")
    except Exception as e:
        print(f"   ❌ Error: {e}")
    
    # Test 2: Payment Status Endpoint
    print("\n2. Testing Payment Status Endpoint...")
    try:
        response = requests.get(f"{BASE_URL}/api/v1/payments/status/test-order-id")
        print(f"   Status: {response.status_code}")
        if response.status_code == 401:
            print("   ✅ Endpoint exists (401 = needs auth)")
        elif response.status_code == 404:
            print("   ✅ Endpoint exists (404 = order not found)")
        else:
            print(f"   Response: {response.text[:200]}...")
    except Exception as e:
        print(f"   ❌ Error: {e}")
    
    # Test 3: Payment Retry Endpoint
    print("\n3. Testing Payment Retry Endpoint...")
    retry_data = {"order_id": "test-order", "upi_app": "phonepe"}
    try:
        response = requests.post(
            f"{BASE_URL}/api/v1/payments/retry/test-order-id",
            json=retry_data,
            headers={"Content-Type": "application/json"}
        )
        print(f"   Status: {response.status_code}")
        if response.status_code == 401:
            print("   ✅ Endpoint exists (401 = needs auth)")
        elif response.status_code == 404:
            print("   ✅ Endpoint exists (404 = order not found)")
        else:
            print(f"   Response: {response.text[:200]}...")
    except Exception as e:
        print(f"   ❌ Error: {e}")

def test_database_connection():
    """Test if backend can connect to Supabase"""
    print("\n🗄️ Testing Database Connection...")
    
    # This would test an endpoint that requires database access
    # For now, we'll just check if the API responds to any endpoint
    try:
        response = requests.get(f"{BASE_URL}/api/v1/auth/me")
        print(f"   Auth endpoint status: {response.status_code}")
        if response.status_code in [401, 422]:
            print("   ✅ Backend is responding (database likely connected)")
        else:
            print(f"   Response: {response.text[:100]}...")
    except Exception as e:
        print(f"   ❌ Error: {e}")

if __name__ == "__main__":
    print("🚀 Quick UPI Payment Backend Test")
    print("=" * 40)
    
    # Test 1: Health Check
    if not test_health():
        print("\n❌ API is not running. Please start the FastAPI server first:")
        print("   cd services/api")
        print("   uvicorn app.main:app --reload")
        exit(1)
    
    # Test 2: Payment Endpoints
    test_payment_endpoints()
    
    # Test 3: Database Connection
    test_database_connection()
    
    print("\n" + "=" * 40)
    print("🎯 Quick Test Complete!")
    print("\nTo run full tests with authentication:")
    print("   python test_upi_payments.py")
    print("\nTo start the API server:")
    print("   cd services/api")
    print("   uvicorn app.main:app --reload --host 0.0.0.0 --port 8000")
