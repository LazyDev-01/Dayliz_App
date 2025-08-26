#!/usr/bin/env python3
"""
Create a test agent using Supabase's auth signup API
This ensures the user is created through the proper Supabase flow
"""

import requests
import json

# Supabase configuration - Use environment variables in production
SUPABASE_URL = "https://your-project.supabase.co"  # Replace with your Supabase URL
SUPABASE_ANON_KEY = "your_supabase_anon_key_here"  # Replace with your Supabase anon key

def create_test_agent():
    """Create a test agent using Supabase's auth signup API"""
    
    # Test credentials - Use environment variables in production
    agent_id = "DLZ-AG-GHY-00001"
    email = f"{agent_id}@dayliz.internal"
    password = "your_test_password_here"  # Replace with secure password
    
    print(f"🔄 Creating test agent with email: {email}")
    
    # Step 1: Sign up using Supabase auth API
    signup_url = f"{SUPABASE_URL}/auth/v1/signup"
    headers = {
        "apikey": SUPABASE_ANON_KEY,
        "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
        "Content-Type": "application/json"
    }
    
    signup_data = {
        "email": email,
        "password": password,
        "data": {
            "agent_id": agent_id,
            "full_name": "Test Agent"
        }
    }
    
    try:
        print("Step 1: Creating auth user via Supabase signup API...")
        response = requests.post(signup_url, headers=headers, json=signup_data)
        
        if response.status_code == 200:
            user_data = response.json()
            user_id = user_data.get("user", {}).get("id")
            print(f"✅ Auth user created: {user_id}")
            print(f"   Email: {user_data.get('user', {}).get('email')}")
            
            # Step 2: Create agent record
            print("Step 2: Creating agent record...")
            
            agent_url = f"{SUPABASE_URL}/rest/v1/agents"
            agent_data = {
                "user_id": user_id,
                "agent_id": agent_id,
                "full_name": "Test Agent",
                "phone": "+919876543210",
                "email": "testagent@dayliz.com",
                "assigned_zone": "Guwahati Zone 1",
                "status": "active",
                "is_verified": True
            }
            
            agent_response = requests.post(agent_url, headers=headers, json=agent_data)
            
            if agent_response.status_code in [200, 201]:
                print("✅ Agent record created successfully!")
                print("")
                print("🎉 Test agent created successfully!")
                print(f"   Agent ID: {agent_id}")
                print(f"   Password: {password}")
                print("   Ready for testing!")
                return True
            else:
                print(f"❌ Failed to create agent record: {agent_response.status_code}")
                print(f"   Response: {agent_response.text}")
                return False
                
        else:
            print(f"❌ Failed to create auth user: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def test_authentication():
    """Test the authentication with the created user"""
    
    agent_id = "DLZ-AG-GHY-00001"
    email = f"{agent_id}@dayliz.internal"
    password = "your_test_password_here"  # Replace with secure password
    
    print(f"\n🔄 Testing authentication with email: {email}")
    
    signin_url = f"{SUPABASE_URL}/auth/v1/token?grant_type=password"
    headers = {
        "apikey": SUPABASE_ANON_KEY,
        "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
        "Content-Type": "application/json"
    }
    
    signin_data = {
        "email": email,
        "password": password
    }
    
    try:
        response = requests.post(signin_url, headers=headers, json=signin_data)
        
        if response.status_code == 200:
            auth_data = response.json()
            print("✅ Authentication successful!")
            print(f"   Access token: {auth_data.get('access_token', '')[:20]}...")
            return True
        else:
            print(f"❌ Authentication failed: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Error testing authentication: {e}")
        return False

if __name__ == "__main__":
    print("🚀 Creating test agent for Dayliz Agent App")
    print("=" * 50)
    
    if create_test_agent():
        test_authentication()
    else:
        print("❌ Failed to create test agent")
