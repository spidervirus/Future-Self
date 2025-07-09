from datetime import datetime, timedelta
from typing import Optional, Dict, Any
import secrets
import hashlib
from jose import JWTError, jwt
from passlib.context import CryptContext
from sqlalchemy.orm import Session
from sqlalchemy import and_

from app.core.config import settings
from app.models.auth import User, RefreshToken
from app.schemas.auth import UserCreate, UserLogin, Token
from app.core.exceptions import AuthenticationError, ValidationError


class AuthService:
    """Authentication service for handling user auth operations"""
    
    def __init__(self):
        self.pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
        self.algorithm = settings.ALGORITHM
        self.secret_key = settings.SECRET_KEY
        self.access_token_expire_minutes = settings.ACCESS_TOKEN_EXPIRE_MINUTES
        self.refresh_token_expire_days = 30  # 30 days for refresh tokens
    
    def verify_password(self, plain_password: str, hashed_password: str) -> bool:
        """Verify a plain password against a hashed password"""
        return self.pwd_context.verify(plain_password, hashed_password)
    
    def get_password_hash(self, password: str) -> str:
        """Hash a password"""
        return self.pwd_context.hash(password)
    
    def create_access_token(self, data: Dict[str, Any], expires_delta: Optional[timedelta] = None) -> str:
        """Create JWT access token"""
        to_encode = data.copy()
        if expires_delta:
            expire = datetime.utcnow() + expires_delta
        else:
            expire = datetime.utcnow() + timedelta(minutes=self.access_token_expire_minutes)
        
        to_encode.update({"exp": expire})
        encoded_jwt = jwt.encode(to_encode, self.secret_key, algorithm=self.algorithm)
        return encoded_jwt
    
    def create_refresh_token(self, db: Session, user_id: str) -> str:
        """Create and store refresh token"""
        # Generate secure random token
        token_data = secrets.token_urlsafe(32)
        
        # Create refresh token record
        refresh_token = RefreshToken(
            user_id=user_id,
            token=token_data,
            expires_at=datetime.utcnow() + timedelta(days=self.refresh_token_expire_days)
        )
        
        db.add(refresh_token)
        db.commit()
        
        return token_data
    
    def verify_token(self, token: str) -> Optional[Dict[str, Any]]:
        """Verify JWT token and return payload"""
        try:
            payload = jwt.decode(token, self.secret_key, algorithms=[self.algorithm])
            return payload
        except JWTError:
            return None
    
    def get_user_by_email(self, db: Session, email: str) -> Optional[User]:
        """Get user by email"""
        return db.query(User).filter(User.email == email).first()
    
    def get_user_by_id(self, db: Session, user_id: str) -> Optional[User]:
        """Get user by ID"""
        return db.query(User).filter(User.id == user_id).first()
    
    def create_user(self, db: Session, user_create: UserCreate) -> User:
        """Create a new user"""
        # Check if user already exists
        existing_user = self.get_user_by_email(db, user_create.email)
        if existing_user:
            raise ValidationError("User with this email already exists")
        
        # Hash password
        hashed_password = self.get_password_hash(user_create.password)
        
        # Create user
        user = User(
            email=user_create.email,
            full_name=user_create.full_name,
            hashed_password=hashed_password,
            verification_token=secrets.token_urlsafe(32)
        )
        
        db.add(user)
        db.commit()
        db.refresh(user)
        
        return user
    
    def authenticate_user(self, db: Session, email: str, password: str) -> Optional[User]:
        """Authenticate user with email and password"""
        user = self.get_user_by_email(db, email)
        if not user:
            return None
        
        if not self.verify_password(password, user.hashed_password):
            return None
        
        if not user.is_active:
            return None
        
        # Update last login
        user.update_last_login()
        db.commit()
        
        return user
    
    def login_user(self, db: Session, user_login: UserLogin) -> Dict[str, Any]:
        """Login user and return tokens"""
        user = self.authenticate_user(db, user_login.email, user_login.password)
        if not user:
            raise AuthenticationError("Invalid email or password")
        
        # Create tokens
        access_token = self.create_access_token(data={"sub": str(user.id)})
        refresh_token = self.create_refresh_token(db, str(user.id))
        
        return {
            "user": user,
            "token": Token(
                access_token=access_token,
                refresh_token=refresh_token,
                token_type="bearer",
                expires_in=self.access_token_expire_minutes * 60
            )
        }
    
    def refresh_access_token(self, db: Session, refresh_token: str) -> Dict[str, Any]:
        """Refresh access token using refresh token"""
        # Find refresh token
        token_record = db.query(RefreshToken).filter(
            and_(
                RefreshToken.token == refresh_token,
                RefreshToken.is_revoked == False
            )
        ).first()
        
        if not token_record or not token_record.is_valid():
            raise AuthenticationError("Invalid or expired refresh token")
        
        # Get user
        user = self.get_user_by_id(db, str(token_record.user_id))
        if not user or not user.is_active:
            raise AuthenticationError("User not found or inactive")
        
        # Create new access token
        access_token = self.create_access_token(data={"sub": str(user.id)})
        
        return {
            "access_token": access_token,
            "token_type": "bearer",
            "expires_in": self.access_token_expire_minutes * 60
        }
    
    def revoke_refresh_token(self, db: Session, refresh_token: str) -> bool:
        """Revoke refresh token"""
        token_record = db.query(RefreshToken).filter(
            RefreshToken.token == refresh_token
        ).first()
        
        if token_record:
            token_record.revoke()
            db.commit()
            return True
        
        return False
    
    def revoke_all_user_tokens(self, db: Session, user_id: str) -> int:
        """Revoke all refresh tokens for a user"""
        count = db.query(RefreshToken).filter(
            and_(
                RefreshToken.user_id == user_id,
                RefreshToken.is_revoked == False
            )
        ).update({"is_revoked": True})
        
        db.commit()
        return count
    
    def verify_user_email(self, db: Session, token: str) -> Optional[User]:
        """Verify user email using verification token"""
        user = db.query(User).filter(User.verification_token == token).first()
        if user:
            user.is_verified = True
            user.verification_token = None
            db.commit()
            return user
        return None
    
    def generate_password_reset_token(self, db: Session, email: str) -> Optional[str]:
        """Generate password reset token"""
        user = self.get_user_by_email(db, email)
        if not user:
            return None
        
        token = secrets.token_urlsafe(32)
        user.set_password_reset_token(token)
        db.commit()
        
        return token
    
    def reset_password(self, db: Session, token: str, new_password: str) -> Optional[User]:
        """Reset password using reset token"""
        user = db.query(User).filter(User.password_reset_token == token).first()
        if not user or not user.is_password_reset_valid():
            return None
        
        # Update password
        user.hashed_password = self.get_password_hash(new_password)
        user.clear_password_reset_token()
        
        # Revoke all refresh tokens
        self.revoke_all_user_tokens(db, str(user.id))
        
        db.commit()
        return user
    
    def change_password(self, db: Session, user_id: str, current_password: str, new_password: str) -> bool:
        """Change user password"""
        user = self.get_user_by_id(db, user_id)
        if not user:
            return False
        
        # Verify current password
        if not self.verify_password(current_password, user.hashed_password):
            return False
        
        # Update password
        user.hashed_password = self.get_password_hash(new_password)
        
        # Revoke all refresh tokens
        self.revoke_all_user_tokens(db, user_id)
        
        db.commit()
        return True 