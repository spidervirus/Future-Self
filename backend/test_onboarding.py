#!/usr/bin/env python3
"""
Comprehensive onboarding system test
Tests the complete onboarding flow: start -> step updates -> progress -> completion
"""

import requests
import json
import time
import threading
from datetime import datetime, date
from app.database.connection import init_database
from app.main import app
import uvicorn

# Test configuration
BASE_URL = "http://localhost:8002"

class OnboardingTestRunner:
    def __init__(self):
        self.server = None
        self.server_thread = None
        self.access_token = None
        self.refresh_token = None
        self.user_id = None
        
        # Test user data for registration
        self.test_user = {
            "email": "onboarding@futureself.com",
            "password": "TestPass123",
            "full_name": "Onboarding Test User"
        }
        
        # Test onboarding data for each step
        self.step_data = {
            1: {
                "name": "Alex Future",
                "birthday": "1990-05-15",
                "cultural_home": "I feel most at home in multicultural environments where diverse perspectives are celebrated.",
                "current_location": "San Francisco, CA"
            },
            2: {
                "current_thoughts": "I've been thinking a lot about finding more balance between work and personal growth.",
                "authentic_place": "In quiet coffee shops early in the morning, before the world gets busy.",
                "something_you_like": "I really like my curiosity and willingness to try new things.",
                "reminder_when_down": "Remember that growth happens outside your comfort zone, and every challenge is teaching you something valuable."
            },
            3: {
                "change_you_want": "I keep saying I'll be more consistent with my morning routine, but I always find excuses.",
                "feeling_to_experience": "A deeper sense of inner peace and confidence in my decisions.",
                "person_you_want_to_be": "Someone who inspires others to believe in themselves and pursue their dreams authentically."
            },
            4: {
                "future_self_age": 35,
                "dream_day": "I wake up energized, spend the morning writing or creating, have meaningful conversations with people I care about, and end the day feeling like I contributed something positive to the world.",
                "accomplishment_goal": "Writing a book that genuinely helps people discover their purpose and live more fulfilling lives."
            },
            5: {
                "trusted_words_vibes": "Authenticity, curiosity, growth, compassion, and gentle honesty.",
                "message_length_preference": "long",
                "message_frequency": "weekly",
                "trust_factor": "People trust those who are a little vulnerable and willing to admit they don't have all the answers."
            },
            6: {
                "when_feeling_lost": "I take a walk in nature, journal about what I'm feeling, and remind myself that feeling lost sometimes means I'm ready for the next chapter."
            }
        }
    
    def start_server(self):
        """Start the FastAPI server in a separate thread"""
        print("🚀 Starting FastAPI server...")
        
        def run_server():
            uvicorn.run(app, host="0.0.0.0", port=8002, log_level="warning")
        
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
    
    def setup_user(self):
        """Register and authenticate a test user"""
        print("\n👤 Setting up test user...")
        
        # Register user
        response = requests.post(
            f"{BASE_URL}/api/v1/auth/register",
            json=self.test_user
        )
        
        if response.status_code == 201:
            data = response.json()
            self.access_token = data['token']['access_token']
            self.refresh_token = data['token']['refresh_token']
            self.user_id = data['user']['id']
            print(f"✅ User registered and authenticated")
            print(f"   User ID: {self.user_id}")
            return True
        else:
            print(f"❌ User setup failed: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
    
    def get_auth_headers(self):
        """Get authorization headers for authenticated requests"""
        return {"Authorization": f"Bearer {self.access_token}"}
    
    def test_start_onboarding(self):
        """Test starting the onboarding process"""
        print("\n🚀 Testing onboarding start...")
        try:
            response = requests.post(
                f"{BASE_URL}/api/v1/onboarding/start",
                headers=self.get_auth_headers()
            )
            
            if response.status_code == 201:
                data = response.json()
                print(f"✅ Onboarding started: {data['message']}")
                return True
            else:
                print(f"❌ Start onboarding failed: {response.status_code}")
                print(f"   Response: {response.text}")
                return False
                
        except Exception as e:
            print(f"❌ Start onboarding error: {e}")
            return False
    
    def test_get_questions(self):
        """Test getting onboarding questions structure"""
        print("\n❓ Testing get onboarding questions...")
        try:
            response = requests.get(f"{BASE_URL}/api/v1/onboarding/questions")
            
            if response.status_code == 200:
                data = response.json()
                print(f"✅ Questions retrieved successfully")
                print(f"   Available steps: {list(data.keys())}")
                return True
            else:
                print(f"❌ Get questions failed: {response.status_code}")
                return False
                
        except Exception as e:
            print(f"❌ Get questions error: {e}")
            return False
    
    def test_step_updates(self):
        """Test updating each onboarding step"""
        print("\n📝 Testing step-by-step updates...")
        results = {}
        
        for step_number in range(1, 7):
            try:
                step_update = {
                    "step_data": self.step_data[step_number]
                }
                
                response = requests.put(
                    f"{BASE_URL}/api/v1/onboarding/step/{step_number}",
                    json=step_update,
                    headers=self.get_auth_headers()
                )
                
                if response.status_code == 200:
                    data = response.json()
                    print(f"✅ Step {step_number} updated successfully")
                    print(f"   Completed steps: {data['completed_steps']}")
                    print(f"   Completion: {data['completion_percentage']:.1f}%")
                    print(f"   Step complete: {data['is_step_complete']}")
                    results[step_number] = True
                else:
                    print(f"❌ Step {step_number} update failed: {response.status_code}")
                    print(f"   Response: {response.text}")
                    results[step_number] = False
                    
            except Exception as e:
                print(f"❌ Step {step_number} error: {e}")
                results[step_number] = False
        
        success_count = sum(results.values())
        print(f"\n📊 Step updates: {success_count}/6 successful")
        return success_count == 6
    
    def test_progress_tracking(self):
        """Test onboarding progress tracking"""
        print("\n📈 Testing progress tracking...")
        try:
            response = requests.get(
                f"{BASE_URL}/api/v1/onboarding/progress",
                headers=self.get_auth_headers()
            )
            
            if response.status_code == 200:
                data = response.json()
                print(f"✅ Progress retrieved successfully")
                print(f"   Completed steps: {data['completed_steps']}")
                print(f"   Is complete: {data['is_complete']}")
                print(f"   Completion percentage: {data['completion_percentage']:.1f}%")
                print(f"   Current step: {data['current_step']}")
                return True
            else:
                print(f"❌ Progress tracking failed: {response.status_code}")
                print(f"   Response: {response.text}")
                return False
                
        except Exception as e:
            print(f"❌ Progress tracking error: {e}")
            return False
    
    def test_step_validation(self):
        """Test individual step validation"""
        print("\n✅ Testing step validation...")
        results = {}
        
        for step_number in range(1, 7):
            try:
                response = requests.get(
                    f"{BASE_URL}/api/v1/onboarding/step/{step_number}/validate",
                    headers=self.get_auth_headers()
                )
                
                if response.status_code == 200:
                    data = response.json()
                    print(f"✅ Step {step_number} validation: {data['is_complete']}")
                    if data['missing_fields']:
                        print(f"   Missing fields: {data['missing_fields']}")
                    results[step_number] = True
                else:
                    print(f"❌ Step {step_number} validation failed: {response.status_code}")
                    results[step_number] = False
                    
            except Exception as e:
                print(f"❌ Step {step_number} validation error: {e}")
                results[step_number] = False
        
        success_count = sum(results.values())
        print(f"\n📊 Validations: {success_count}/6 successful")
        return success_count == 6
    
    def test_get_data(self):
        """Test getting complete onboarding data"""
        print("\n📋 Testing get onboarding data...")
        try:
            response = requests.get(
                f"{BASE_URL}/api/v1/onboarding/data",
                headers=self.get_auth_headers()
            )
            
            if response.status_code == 200:
                data = response.json()
                print(f"✅ Onboarding data retrieved successfully")
                print(f"   User ID: {data['user_id']}")
                print(f"   Name: {data['name']}")
                print(f"   Completed steps: {data['completed_steps']}")
                print(f"   Is complete: {data['is_complete']}")
                return True
            else:
                print(f"❌ Get data failed: {response.status_code}")
                print(f"   Response: {response.text}")
                return False
                
        except Exception as e:
            print(f"❌ Get data error: {e}")
            return False
    
    def test_completion(self):
        """Test marking onboarding as complete"""
        print("\n🎉 Testing onboarding completion...")
        try:
            response = requests.post(
                f"{BASE_URL}/api/v1/onboarding/complete",
                headers=self.get_auth_headers()
            )
            
            if response.status_code == 200:
                data = response.json()
                print(f"✅ Onboarding completed successfully!")
                print(f"   User ID: {data['user_id']}")
                print(f"   Completion: {data['completion_percentage']:.1f}%")
                print(f"   Completed at: {data['completed_at']}")
                print(f"   Message: {data['message']}")
                return True
            else:
                print(f"❌ Completion failed: {response.status_code}")
                print(f"   Response: {response.text}")
                return False
                
        except Exception as e:
            print(f"❌ Completion error: {e}")
            return False
    
    def test_next_step(self):
        """Test getting next step"""
        print("\n➡️ Testing next step retrieval...")
        try:
            response = requests.get(
                f"{BASE_URL}/api/v1/onboarding/next-step",
                headers=self.get_auth_headers()
            )
            
            if response.status_code == 200:
                data = response.json()
                print(f"✅ Next step retrieved: {data['next_step']}")
                return True
            else:
                print(f"❌ Next step failed: {response.status_code}")
                return False
                
        except Exception as e:
            print(f"❌ Next step error: {e}")
            return False
    
    def test_step_summary(self):
        """Test getting step summary"""
        print("\n📊 Testing step summary...")
        try:
            response = requests.get(
                f"{BASE_URL}/api/v1/onboarding/summary",
                headers=self.get_auth_headers()
            )
            
            if response.status_code == 200:
                data = response.json()
                print(f"✅ Step summary retrieved successfully")
                for step_num, step_info in data['steps'].items():
                    status = "✅" if step_info['is_complete'] else "❌"
                    optional = " (Optional)" if step_info['is_optional'] else ""
                    print(f"   Step {step_num}: {step_info['name']}{optional} {status}")
                return True
            else:
                print(f"❌ Step summary failed: {response.status_code}")
                return False
                
        except Exception as e:
            print(f"❌ Step summary error: {e}")
            return False
    
    def run_complete_test(self):
        """Run the complete onboarding test suite"""
        print("🧪 COMPREHENSIVE ONBOARDING SYSTEM TEST")
        print("=" * 70)
        
        # Initialize database
        print("🗄️ Initializing database...")
        init_database()
        print("✅ Database initialized")
        
        # Start server
        if not self.start_server():
            print("❌ Failed to start server. Exiting.")
            return False
        
        # Setup user
        if not self.setup_user():
            print("❌ Failed to setup user. Exiting.")
            return False
        
        # Run tests in sequence
        tests = [
            ("Get Questions", self.test_get_questions),
            ("Start Onboarding", self.test_start_onboarding),
            ("Step Updates", self.test_step_updates),
            ("Progress Tracking", self.test_progress_tracking),
            ("Step Validation", self.test_step_validation),
            ("Get Data", self.test_get_data),
            ("Next Step", self.test_next_step),
            ("Step Summary", self.test_step_summary),
            ("Complete Onboarding", self.test_completion)
        ]
        
        results = {}
        for test_name, test_func in tests:
            results[test_name] = test_func()
        
        # Summary
        print("\n" + "=" * 70)
        print("📊 ONBOARDING TEST RESULTS SUMMARY")
        print("=" * 70)
        
        passed = sum(results.values())
        total = len(results)
        
        for test_name, result in results.items():
            status = "✅ PASS" if result else "❌ FAIL"
            print(f"{test_name:<25} {status}")
        
        print(f"\nOverall: {passed}/{total} tests passed")
        
        if passed == total:
            print("🎉 ALL ONBOARDING TESTS PASSED!")
            print("✅ Onboarding system is fully functional!")
        else:
            print("⚠️ Some tests failed. Please check the implementation.")
        
        return passed == total


def main():
    """Main test runner"""
    test_runner = OnboardingTestRunner()
    success = test_runner.run_complete_test()
    return success


if __name__ == "__main__":
    success = main()
    exit(0 if success else 1) 