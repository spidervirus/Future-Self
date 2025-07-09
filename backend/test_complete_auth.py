#!/usr/bin/env python3
"""
Comprehensive authentication system test
Tests the complete auth flow: register -> login -> refresh -> logout
"""

import asyncio
import requests
import time
import json
from app.database.connection import init_database
from app.main import app
import uvicorn
import threading
from contextlib import contextmanager

# Test configuration
BASE_URL = "http://localhost:8001"
TEST_USER = {
    "email": "testuser@futureself.com",
    "password": "TestPass123",  # Simpler password that meets requirements  
    "full_name": "Test User"
}

class AuthTestRunner:
    def __init__(self):
        self.server = None
        self.server_thread = None
        self.access_token = None
        self.refresh_token = None
        
    def start_server(self):
        """Start the FastAPI server in a separate thread"""
        print("🚀 Starting FastAPI server...")
        
        def run_server():
            uvicorn.run(app, host="0.0.0.0", port=8001, log_level="warning")
        
        self.server_thread = threading.Thread(target=run_server, daemon=True)
        self.server_thread.start()
        
        # Wait for server to start
        time.sleep(3)
        
        # Test if server is running
        try:
            response = requests.get(f"{BASE_URL}/health")
            if response.status_code == 200:
                print("✅ Server started successfully")
                return True
        except requests.exceptions.ConnectionError:
            pass
        
        print("❌ Failed to start server")
        return False
    
    def test_health_check(self):
        """Test health check endpoint"""
        print("\n🏥 Testing health check...")
        try:
            response = requests.get(f"{BASE_URL}/health")
            if response.status_code == 200:
                data = response.json()
                print(f"✅ Health check passed: {data['status']}")
                return True
            else:
                print(f"❌ Health check failed: {response.status_code}")
                return False
        except Exception as e:
            print(f"❌ Health check error: {e}")
            return False
    
    def test_registration(self):
        """Test user registration"""
        print("\n📝 Testing user registration...")
        try:
            response = requests.post(
                f"{BASE_URL}/api/v1/auth/register",
                json=TEST_USER
            )
            
            if response.status_code == 201:
                data = response.json()
                print(f"✅ Registration successful")
                print(f"   User ID: {data['user']['id']}")
                print(f"   Email: {data['user']['email']}")
                
                # Store tokens for later tests
                self.access_token = data['token']['access_token']
                self.refresh_token = data['token']['refresh_token']
                return True
            else:
                print(f"❌ Registration failed: {response.status_code}")
                print(f"   Response: {response.text}")
                return False
                
        except Exception as e:
            print(f"❌ Registration error: {e}")
            return False
    
    def test_login(self):
        """Test user login"""
        print("\n🔑 Testing user login...")
        try:
            response = requests.post(
                f"{BASE_URL}/api/v1/auth/login",
                json={
                    "email": TEST_USER["email"],
                    "password": TEST_USER["password"]
                }
            )
            
            if response.status_code == 200:
                data = response.json()
                print(f"✅ Login successful")
                print(f"   Token type: {data['token']['token_type']}")
                print(f"   Expires in: {data['token']['expires_in']} seconds")
                
                # Update tokens
                self.access_token = data['token']['access_token']
                self.refresh_token = data['token']['refresh_token']
                return True
            else:
                print(f"❌ Login failed: {response.status_code}")
                print(f"   Response: {response.text}")
                return False
                
        except Exception as e:
            print(f"❌ Login error: {e}")
            return False
    
    def test_protected_endpoint(self):
        """Test accessing a protected endpoint"""
        print("\n🔒 Testing protected endpoint access...")
        try:
            headers = {
                "Authorization": f"Bearer {self.access_token}"
            }
            
            response = requests.get(
                f"{BASE_URL}/api/v1/auth/me",  # Fixed endpoint URL
                headers=headers
            )
            
            if response.status_code == 200:
                data = response.json()
                print(f"✅ Protected endpoint access successful")
                print(f"   User: {data['email']} ({data['full_name']})")
                return True
            else:
                print(f"❌ Protected endpoint failed: {response.status_code}")
                print(f"   Response: {response.text}")
                return False
                
        except Exception as e:
            print(f"❌ Protected endpoint error: {e}")
            return False
    
    def test_token_refresh(self):
        """Test token refresh"""
        print("\n🔄 Testing token refresh...")
        try:
            response = requests.post(
                f"{BASE_URL}/api/v1/auth/refresh",
                json={"refresh_token": self.refresh_token}
            )
            
            if response.status_code == 200:
                data = response.json()
                print(f"✅ Token refresh successful")
                print(f"   New token expires in: {data['expires_in']} seconds")
                
                # Update access token
                self.access_token = data['access_token']
                return True
            else:
                print(f"❌ Token refresh failed: {response.status_code}")
                print(f"   Response: {response.text}")
                return False
                
        except Exception as e:
            print(f"❌ Token refresh error: {e}")
            return False
    
    def test_logout(self):
        """Test user logout"""
        print("\n👋 Testing user logout...")
        try:
            headers = {
                "Authorization": f"Bearer {self.access_token}"
            }
            
            response = requests.post(
                f"{BASE_URL}/api/v1/auth/logout",
                headers=headers,
                json={"refresh_token": self.refresh_token}
            )
            
            if response.status_code == 200:
                data = response.json()
                print(f"✅ Logout successful: {data['message']}")
                return True
            else:
                print(f"❌ Logout failed: {response.status_code}")
                print(f"   Response: {response.text}")
                return False
                
        except Exception as e:
            print(f"❌ Logout error: {e}")
            return False
    
    def run_complete_test(self):
        """Run the complete authentication test suite"""
        print("🧪 COMPREHENSIVE AUTHENTICATION TEST")
        print("=" * 60)
        
        # Initialize database
        print("🗄️ Initializing database...")
        init_database()
        print("✅ Database initialized")
        
        # Start server
        if not self.start_server():
            print("❌ Failed to start server. Exiting.")
            return False
        
        # Run tests in sequence
        tests = [
            ("Health Check", self.test_health_check),
            ("User Registration", self.test_registration),
            ("User Login", self.test_login),
            ("Protected Endpoint", self.test_protected_endpoint),
            ("Token Refresh", self.test_token_refresh),
            ("User Logout", self.test_logout)
        ]
        
        results = {}
        for test_name, test_func in tests:
            results[test_name] = test_func()
        
        # Summary
        print("\n" + "=" * 60)
        print("📊 TEST RESULTS SUMMARY")
        print("=" * 60)
        
        passed = sum(results.values())
        total = len(results)
        
        for test_name, result in results.items():
            status = "✅ PASS" if result else "❌ FAIL"
            print(f"{test_name:<20} {status}")
        
        print(f"\nOverall: {passed}/{total} tests passed")
        
        if passed == total:
            print("🎉 ALL AUTHENTICATION TESTS PASSED!")
            print("✅ Authentication system is fully functional!")
        else:
            print("⚠️ Some tests failed. Please check the implementation.")
        
        return passed == total

def main():
    """Main test runner"""
    test_runner = AuthTestRunner()
    success = test_runner.run_complete_test()
    return success

if __name__ == "__main__":
    success = main()
    exit(0 if success else 1) 