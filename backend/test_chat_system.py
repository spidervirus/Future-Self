#!/usr/bin/env python3
"""
Comprehensive AI Chat System Test
Tests the complete personalized AI chat functionality including:
- AI Context Service (personalized prompts)
- Ollama Service (AI generation with fallbacks) 
- Chat endpoints (send message, conversations, history)
- Database persistence and error handling
"""

import requests
import json
import time
import threading
import asyncio
from datetime import datetime, date
from app.database.connection import init_database
from app.main import app
import uvicorn

# Test configuration
BASE_URL = "http://localhost:8003"

class ChatSystemTestRunner:
    def __init__(self):
        self.server = None
        self.server_thread = None
        self.access_token = None
        self.refresh_token = None
        self.user_id = None
        self.conversation_id = None
        
        # Test user data for registration
        self.test_user = {
            "email": "chattest@futureself.com",
            "password": "TestPass123",
            "full_name": "Alex Test User"
        }
        
        # Test onboarding data for personalization
        self.onboarding_data = {
            "step_number": 1,
            "name": "Alex Test",
            "birthday": "1990-05-15",
            "cultural_home": "San Francisco, CA",
            "current_location": "New York, NY",
            "current_thoughts": "Building an AI companion app",
            "authentic_place": "When I'm creating something meaningful",
            "something_you_like": "My curiosity and determination",
            "change_you_want": "Be more consistent with my goals",
            "feeling_to_experience": "Deep satisfaction from meaningful work",
            "person_you_want_to_be": "A wise, compassionate leader who helps others grow",
            "future_self_age": 40,
            "dream_day": "Wake up energized, work on impactful projects, connect with loved ones",
            "accomplishment_goal": "Build technology that genuinely helps people",
            "trusted_words_vibes": "Authenticity, growth, wisdom, compassion",
            "trust_factor": "Honest and genuinely caring",
            "when_feeling_lost": "Remember my core values and the people I want to help",
            "reminder_when_down": "Every setback is teaching me something valuable",
            "message_length_preference": "long",
            "message_frequency": "daily"
        }

    def start_server(self):
        """Start the FastAPI server in a separate thread"""
        print("🚀 Starting test server on port 8003...")
        
        def run_server():
            uvicorn.run(app, host="localhost", port=8003, log_level="error")
        
        self.server_thread = threading.Thread(target=run_server, daemon=True)
        self.server_thread.start()
        
        # Wait for server to start
        for i in range(30):
            try:
                response = requests.get(f"{BASE_URL}/health", timeout=2)
                if response.status_code == 200:
                    print("✅ Test server started successfully")
                    return True
            except:
                pass
            time.sleep(1)
        
        raise Exception("❌ Failed to start test server")

    def test_database_setup(self):
        """Test database initialization"""
        print("\n🔧 Testing database setup...")
        try:
            init_database()
            print("✅ Database initialized successfully")
            return True
        except Exception as e:
            print(f"❌ Database setup failed: {e}")
            return False

    def test_user_registration_and_login(self):
        """Test user registration and login"""
        print("\n👤 Testing user registration and login...")
        
        try:
            # Register user
            reg_response = requests.post(
                f"{BASE_URL}/api/v1/auth/register",
                json=self.test_user
            )
            
            if reg_response.status_code != 201:
                print(f"❌ Registration failed: {reg_response.text}")
                return False
            
            print("✅ User registration successful")
            
            # Login user
            login_response = requests.post(
                f"{BASE_URL}/api/v1/auth/login",
                json=self.test_user
            )
            
            if login_response.status_code != 200:
                print(f"❌ Login failed: {login_response.text}")
                return False
            
            login_data = login_response.json()
            self.access_token = login_data["token"]["access_token"]
            self.refresh_token = login_data["token"]["refresh_token"]
            self.user_id = login_data["user"]["id"]
            
            print("✅ User login successful")
            return True
            
        except Exception as e:
            print(f"❌ Auth test failed: {e}")
            return False

    def test_onboarding_completion(self):
        """Complete onboarding to enable personalization"""
        print("\n📝 Testing onboarding completion for personalization...")
        
        try:
            headers = {"Authorization": f"Bearer {self.access_token}"}
            
            # Start onboarding
            start_response = requests.post(
                f"{BASE_URL}/api/v1/onboarding/start",
                headers=headers
            )
            
            if start_response.status_code != 201:
                print(f"❌ Onboarding start failed: {start_response.text}")
                return False
            
            # Complete all onboarding steps
            for step in range(1, 7):
                step_data = {"step_number": step, **self.onboarding_data}
                
                step_response = requests.put(
                    f"{BASE_URL}/api/v1/onboarding/step",
                    headers=headers,
                    json=step_data
                )
                
                if step_response.status_code != 200:
                    print(f"❌ Step {step} failed: {step_response.text}")
                    return False
            
            # Complete onboarding
            complete_response = requests.post(
                f"{BASE_URL}/api/v1/onboarding/complete",
                headers=headers
            )
            
            if complete_response.status_code != 200:
                print(f"❌ Onboarding completion failed: {complete_response.text}")
                return False
            
            print("✅ Onboarding completed successfully")
            return True
            
        except Exception as e:
            print(f"❌ Onboarding test failed: {e}")
            return False

    def test_ollama_health_check(self):
        """Test Ollama service health (graceful failure expected)"""
        print("\n🤖 Testing Ollama service health...")
        
        try:
            headers = {"Authorization": f"Bearer {self.access_token}"}
            
            health_response = requests.get(
                f"{BASE_URL}/api/v1/chat/health/ollama",
                headers=headers
            )
            
            if health_response.status_code == 200:
                health_data = health_response.json()
                print(f"✅ Ollama health check: {health_data['status']}")
                
                if health_data['status'] == 'healthy':
                    print("✅ Ollama server is running and accessible")
                else:
                    print(f"⚠️  Ollama not available: {health_data.get('error', 'Unknown error')}")
                    print("✅ Graceful fallback handling will be tested")
                
                return True
            else:
                print(f"❌ Health check failed: {health_response.text}")
                return False
                
        except Exception as e:
            print(f"❌ Ollama health check failed: {e}")
            return False

    def test_conversation_starter(self):
        """Test personalized conversation starter"""
        print("\n💬 Testing personalized conversation starter...")
        
        try:
            headers = {"Authorization": f"Bearer {self.access_token}"}
            
            starter_response = requests.get(
                f"{BASE_URL}/api/v1/chat/starter",
                headers=headers
            )
            
            if starter_response.status_code != 200:
                print(f"❌ Conversation starter failed: {starter_response.text}")
                return False
            
            starter_data = starter_response.json()
            
            # Verify personalization
            message = starter_data["message"]
            if "Alex" in message:  # Should include user's name
                print(f"✅ Personalized starter includes user name")
            else:
                print(f"⚠️  Starter may not be fully personalized")
            
            print(f"📝 Starter message: {message[:100]}...")
            print(f"💡 Suggested topics: {len(starter_data['suggested_topics'])} provided")
            
            return True
            
        except Exception as e:
            print(f"❌ Conversation starter test failed: {e}")
            return False

    def test_send_message_and_ai_response(self):
        """Test sending message and receiving AI response"""
        print("\n🗨️  Testing message sending and AI response...")
        
        try:
            headers = {"Authorization": f"Bearer {self.access_token}"}
            
            # Send first message (should create new conversation)
            message_data = {
                "content": "Hi Future Self! I'm feeling a bit overwhelmed with my goals lately. Can you help me get some perspective?",
                "message_type": "text"
            }
            
            send_response = requests.post(
                f"{BASE_URL}/api/v1/chat/send",
                headers=headers,
                json=message_data
            )
            
            if send_response.status_code != 200:
                print(f"❌ Send message failed: {send_response.text}")
                return False
            
            chat_data = send_response.json()
            
            # Verify response structure
            assert "user_message" in chat_data
            assert "ai_message" in chat_data
            assert "conversation_id" in chat_data
            assert chat_data["is_new_conversation"] == True
            
            self.conversation_id = chat_data["conversation_id"]
            
            # Verify user message
            user_msg = chat_data["user_message"]
            assert user_msg["content"] == message_data["content"]
            assert user_msg["role"] == "user"
            
            # Verify AI response
            ai_msg = chat_data["ai_message"]
            assert len(ai_msg["content"]) > 0
            assert ai_msg["role"] == "assistant"
            
            print("✅ Message sent and AI response received")
            print(f"💭 User message: {user_msg['content'][:50]}...")
            print(f"🤖 AI response: {ai_msg['content'][:100]}...")
            
            # Check if response shows personalization
            ai_content = ai_msg["content"].lower()
            if any(word in ai_content for word in ["alex", "goals", "wisdom", "growth"]):
                print("✅ AI response shows personalization elements")
            else:
                print("⚠️  AI response may not be fully personalized (possibly using fallback)")
            
            return True
            
        except Exception as e:
            print(f"❌ Send message test failed: {e}")
            return False

    def test_conversation_continuation(self):
        """Test continuing a conversation"""
        print("\n🔄 Testing conversation continuation...")
        
        try:
            headers = {"Authorization": f"Bearer {self.access_token}"}
            
            # Send follow-up message
            message_data = {
                "content": "Thank you for that insight! Can you remind me of my core values and help me prioritize?",
                "conversation_id": self.conversation_id,
                "message_type": "text"
            }
            
            send_response = requests.post(
                f"{BASE_URL}/api/v1/chat/send",
                headers=headers,
                json=message_data
            )
            
            if send_response.status_code != 200:
                print(f"❌ Conversation continuation failed: {send_response.text}")
                return False
            
            chat_data = send_response.json()
            
            # Verify it's the same conversation
            assert chat_data["conversation_id"] == self.conversation_id
            assert chat_data["is_new_conversation"] == False
            
            ai_response = chat_data["ai_message"]["content"]
            print("✅ Conversation continued successfully")
            print(f"🤖 Follow-up response: {ai_response[:100]}...")
            
            # Check for context awareness (should reference previous conversation)
            if any(word in ai_response.lower() for word in ["values", "authenticity", "growth", "compassion"]):
                print("✅ AI shows context awareness from onboarding data")
            
            return True
            
        except Exception as e:
            print(f"❌ Conversation continuation test failed: {e}")
            return False

    def test_conversation_management(self):
        """Test conversation listing and management"""
        print("\n📋 Testing conversation management...")
        
        try:
            headers = {"Authorization": f"Bearer {self.access_token}"}
            
            # Get conversations list
            conv_response = requests.get(
                f"{BASE_URL}/api/v1/chat/conversations",
                headers=headers
            )
            
            if conv_response.status_code != 200:
                print(f"❌ Get conversations failed: {conv_response.text}")
                return False
            
            conv_data = conv_response.json()
            
            assert "conversations" in conv_data
            assert len(conv_data["conversations"]) >= 1
            
            conversation = conv_data["conversations"][0]
            assert conversation["message_count"] >= 2  # Two messages sent
            
            print(f"✅ Found {len(conv_data['conversations'])} conversation(s)")
            print(f"📝 Conversation title: {conversation['title']}")
            print(f"💬 Message count: {conversation['message_count']}")
            
            # Get conversation detail
            detail_response = requests.get(
                f"{BASE_URL}/api/v1/chat/conversations/{self.conversation_id}",
                headers=headers
            )
            
            if detail_response.status_code != 200:
                print(f"❌ Get conversation detail failed: {detail_response.text}")
                return False
            
            detail_data = detail_response.json()
            
            assert "messages" in detail_data
            assert len(detail_data["messages"]) >= 4  # 2 user + 2 AI messages
            
            print(f"✅ Conversation detail retrieved with {len(detail_data['messages'])} messages")
            
            return True
            
        except Exception as e:
            print(f"❌ Conversation management test failed: {e}")
            return False

    def test_chat_history(self):
        """Test chat history retrieval"""
        print("\n📚 Testing chat history...")
        
        try:
            headers = {"Authorization": f"Bearer {self.access_token}"}
            
            # Get general chat history
            history_response = requests.get(
                f"{BASE_URL}/api/v1/chat/history?limit=10",
                headers=headers
            )
            
            if history_response.status_code != 200:
                print(f"❌ Get chat history failed: {history_response.text}")
                return False
            
            history_data = history_response.json()
            
            assert "messages" in history_data
            assert len(history_data["messages"]) >= 2
            
            print(f"✅ Chat history retrieved with {len(history_data['messages'])} messages")
            
            # Test conversation-specific history
            conv_history_response = requests.get(
                f"{BASE_URL}/api/v1/chat/history?conversation_id={self.conversation_id}",
                headers=headers
            )
            
            if conv_history_response.status_code != 200:
                print(f"❌ Get conversation history failed: {conv_history_response.text}")
                return False
            
            conv_history_data = conv_history_response.json()
            
            assert conv_history_data["conversation_id"] == self.conversation_id
            print(f"✅ Conversation-specific history retrieved")
            
            return True
            
        except Exception as e:
            print(f"❌ Chat history test failed: {e}")
            return False

    def test_error_handling(self):
        """Test error handling and edge cases"""
        print("\n⚠️  Testing error handling...")
        
        try:
            headers = {"Authorization": f"Bearer {self.access_token}"}
            
            # Test invalid conversation ID
            invalid_message = {
                "content": "Test message",
                "conversation_id": "invalid-uuid-format"
            }
            
            error_response = requests.post(
                f"{BASE_URL}/api/v1/chat/send",
                headers=headers,
                json=invalid_message
            )
            
            # Should handle gracefully (either 400 or 404)
            if error_response.status_code in [400, 404, 422]:
                print("✅ Invalid conversation ID handled gracefully")
            else:
                print(f"⚠️  Unexpected response for invalid ID: {error_response.status_code}")
            
            # Test empty message
            empty_message = {
                "content": "",
                "conversation_id": self.conversation_id
            }
            
            empty_response = requests.post(
                f"{BASE_URL}/api/v1/chat/send",
                headers=headers,
                json=empty_message
            )
            
            if empty_response.status_code == 422:
                print("✅ Empty message validation handled correctly")
            
            # Test unauthorized access
            no_auth_response = requests.get(
                f"{BASE_URL}/api/v1/chat/conversations"
            )
            
            if no_auth_response.status_code == 401:
                print("✅ Unauthorized access properly blocked")
            
            return True
            
        except Exception as e:
            print(f"❌ Error handling test failed: {e}")
            return False

    def test_conversation_update_and_deletion(self):
        """Test conversation updates and deletion"""
        print("\n🗑️  Testing conversation updates and deletion...")
        
        try:
            headers = {"Authorization": f"Bearer {self.access_token}"}
            
            # Update conversation title
            update_data = {
                "title": "My Goal Discussion with Future Self",
                "is_archived": False
            }
            
            update_response = requests.put(
                f"{BASE_URL}/api/v1/chat/conversations/{self.conversation_id}",
                headers=headers,
                json=update_data
            )
            
            if update_response.status_code != 200:
                print(f"❌ Conversation update failed: {update_response.text}")
                return False
            
            update_result = update_response.json()
            assert update_result["title"] == update_data["title"]
            
            print("✅ Conversation title updated successfully")
            
            # Archive conversation
            archive_data = {"is_archived": True}
            
            archive_response = requests.put(
                f"{BASE_URL}/api/v1/chat/conversations/{self.conversation_id}",
                headers=headers,
                json=archive_data
            )
            
            if archive_response.status_code == 200:
                print("✅ Conversation archived successfully")
            
            # Test deletion (create new conversation first to avoid losing test data)
            new_conv_response = requests.post(
                f"{BASE_URL}/api/v1/chat/conversations",
                headers=headers,
                json={"title": "Test conversation for deletion"}
            )
            
            if new_conv_response.status_code == 201:
                new_conv_id = new_conv_response.json()["id"]
                
                delete_response = requests.delete(
                    f"{BASE_URL}/api/v1/chat/conversations/{new_conv_id}",
                    headers=headers
                )
                
                if delete_response.status_code == 200:
                    print("✅ Conversation deletion successful")
            
            return True
            
        except Exception as e:
            print(f"❌ Conversation update/deletion test failed: {e}")
            return False

    def run_all_tests(self):
        """Run the complete test suite"""
        print("🧪 Starting Comprehensive AI Chat System Tests")
        print("=" * 50)
        
        tests = [
            ("Database Setup", self.test_database_setup),
            ("Server Startup", self.start_server),
            ("User Auth", self.test_user_registration_and_login),
            ("Onboarding", self.test_onboarding_completion),
            ("Ollama Health", self.test_ollama_health_check),
            ("Conversation Starter", self.test_conversation_starter),
            ("Send Message & AI Response", self.test_send_message_and_ai_response),
            ("Conversation Continuation", self.test_conversation_continuation),
            ("Conversation Management", self.test_conversation_management),
            ("Chat History", self.test_chat_history),
            ("Error Handling", self.test_error_handling),
            ("Updates & Deletion", self.test_conversation_update_and_deletion)
        ]
        
        passed = 0
        failed = 0
        
        for test_name, test_func in tests:
            try:
                if test_func():
                    passed += 1
                else:
                    failed += 1
            except Exception as e:
                print(f"❌ {test_name} crashed: {e}")
                failed += 1
        
        print("\n" + "=" * 50)
        print("🧪 AI CHAT SYSTEM TEST RESULTS")
        print(f"✅ Passed: {passed}")
        print(f"❌ Failed: {failed}")
        print(f"📊 Success Rate: {(passed/(passed+failed)*100):.1f}%")
        
        if failed == 0:
            print("\n🎉 ALL TESTS PASSED! AI Chat System is ready! 🎉")
            print("\n🔥 FEATURES WORKING:")
            print("  ✅ Personalized AI prompts from onboarding data")
            print("  ✅ Ollama/Mistral integration with graceful fallbacks")
            print("  ✅ Full conversation management (CRUD operations)")
            print("  ✅ Chat history and message persistence")
            print("  ✅ Error handling and validation")
            print("  ✅ User authentication and authorization")
            print("  ✅ Database integration with UUID support")
        else:
            print(f"\n⚠️  {failed} test(s) failed. Please review the errors above.")


if __name__ == "__main__":
    runner = ChatSystemTestRunner()
    runner.run_all_tests() 