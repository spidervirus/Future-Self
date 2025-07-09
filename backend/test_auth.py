#!/usr/bin/env python3
"""
Simple test script to debug authentication registration
"""

import asyncio
from app.database.connection import init_database
from app.services.auth_service import AuthService
from app.schemas.auth import UserCreate
import traceback

async def test_auth_registration():
    """Test authentication registration step by step"""
    
    print("🧪 Testing Authentication Registration")
    print("=" * 50)
    
    try:
        # Step 1: Initialize database
        print("1️⃣ Initializing database...")
        init_database()
        print("✅ Database initialized successfully")
        
        # Step 2: Create auth service
        print("\n2️⃣ Creating auth service...")
        auth_service = AuthService()
        print("✅ Auth service created successfully")
        
        # Step 3: Create user data
        print("\n3️⃣ Creating user data...")
        user_data = UserCreate(
            email="test@example.com",
            password="TestPassword123",
            full_name="Test User"
        )
        print("✅ User data created successfully")
        
        # Step 4: Test password hashing
        print("\n4️⃣ Testing password hashing...")
        hashed = auth_service.get_password_hash("TestPassword123")
        verify_result = auth_service.verify_password("TestPassword123", hashed)
        print(f"✅ Password hashing works: {verify_result}")
        
        # Step 5: Test JWT token creation
        print("\n5️⃣ Testing JWT token creation...")
        token = auth_service.create_access_token({"sub": "test-user-id"})
        print(f"✅ JWT token created: {token[:50]}...")
        
        # Step 6: Test database session
        print("\n6️⃣ Testing database session...")
        from app.database.connection import SessionLocal
        db = SessionLocal()
        try:
            from sqlalchemy import text
            result = db.execute(text("SELECT 1"))
            print(f"✅ Database query successful: {result.fetchone()}")
        finally:
            db.close()
        
        # Step 7: Test user creation (this is where it might fail)
        print("\n7️⃣ Testing user creation...")
        db = SessionLocal()
        try:
            user = auth_service.create_user(db, user_data)
            print(f"✅ User created successfully: {user.email}")
            print(f"   User ID: {user.id}")
            print(f"   Full name: {user.full_name}")
            print(f"   Is active: {user.is_active}")
        except Exception as e:
            print(f"❌ User creation failed: {e}")
            traceback.print_exc()
        finally:
            db.close()
        
        print("\n🎉 All tests completed!")
        
    except Exception as e:
        print(f"❌ Test failed: {e}")
        traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(test_auth_registration()) 