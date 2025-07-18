#!/usr/bin/env python3
"""
Simple endpoint test using only built-in Python libraries
No external dependencies required
"""

import urllib.request
import urllib.parse
import json
import sys

BASE_URL = "http://localhost:8000"

def test_endpoint(url, method="GET", data=None):
    """Test an endpoint using built-in urllib"""
    try:
        if data:
            data = json.dumps(data).encode('utf-8')
        
        req = urllib.request.Request(
            url, 
            data=data,
            headers={'Content-Type': 'application/json'} if data else {}
        )
        req.get_method = lambda: method
        
        with urllib.request.urlopen(req, timeout=5) as response:
            status = response.getcode()
            body = response.read().decode('utf-8')
            return status, body
            
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode('utf-8')
    except urllib.error.URLError as e:
        return 0, str(e)
    except Exception as e:
        return 0, str(e)

def main():
    print("🧪 Simple Backend Endpoint Test")
    print("=" * 40)
    print(f"Testing: {BASE_URL}")
    print()
    
    # Test 1: Health Check
    print("1. Testing Health Endpoint...")
    status, body = test_endpoint(f"{BASE_URL}/health")
    if status == 200:
        print("   ✅ Health endpoint works!")
    elif status == 0:
        print("   ❌ Cannot connect to server")
        print("   💡 Make sure FastAPI server is running:")
        print("      cd services/api")
        print("      uvicorn app.main:app --reload")
        return False
    else:
        print(f"   ⚠️ Unexpected status: {status}")
    
    # Test 2: API Documentation
    print("\n2. Testing API Documentation...")
    status, body = test_endpoint(f"{BASE_URL}/docs")
    if status == 200:
        print("   ✅ API docs available at http://localhost:8000/docs")
    else:
        print(f"   ⚠️ Docs status: {status}")
    
    # Test 3: Payment Endpoints (expect 401/422 without auth)
    print("\n3. Testing Payment Endpoints...")
    
    endpoints = [
        ("POST", "/api/v1/payments/create-order-with-payment", {
            "cart_items": [{"product_id": "test", "name": "Test", "quantity": 1, "price": 100}],
            "shipping_address_id": "test",
            "payment_method": "upi",
            "upi_app": "googlepay", 
            "total_amount": 100.0
        }),
        ("GET", "/api/v1/payments/status/test-order", None),
        ("POST", "/api/v1/payments/retry/test-order", {"order_id": "test", "upi_app": "googlepay"})
    ]
    
    for method, endpoint, data in endpoints:
        print(f"\n   Testing {method} {endpoint}...")
        status, body = test_endpoint(f"{BASE_URL}{endpoint}", method, data)
        
        if status in [401, 422]:
            print(f"   ✅ Endpoint exists (status {status} = needs auth/validation)")
        elif status == 404:
            print(f"   ❌ Endpoint not found (404)")
        elif status == 500:
            print(f"   ⚠️ Server error (500) - check server logs")
        elif status == 0:
            print(f"   ❌ Connection failed")
        else:
            print(f"   ℹ️ Status {status}")
            if len(body) < 200:
                print(f"   Response: {body}")
    
    print("\n" + "=" * 40)
    print("🎯 Test Complete!")
    print("\nNext steps:")
    print("1. If server isn't running, start it with:")
    print("   uvicorn app.main:app --reload")
    print("2. Visit http://localhost:8000/docs to see API documentation")
    print("3. Check server logs for any errors")
    
    return True

if __name__ == "__main__":
    main()
