from sqlalchemy import Column, String, Text, Boolean, DateTime, ForeignKey, Enum as SQLEnum
from sqlalchemy.orm import relationship
from .base import BaseModel, UUID
import uuid
import enum


class UserProfile(BaseModel):
    """Extended user profile model"""
    
    __tablename__ = "user_profiles"
    
    user_id = Column(UUID(), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, unique=True)
    bio = Column(Text)
    timezone = Column(String(50))
    preferred_name = Column(String(100))
    avatar_url = Column(Text)
    
    # AI Interaction Preferences
    ai_personality_preference = Column(String(50))  # warm, professional, casual, etc.
    communication_style = Column(String(50))  # brief, detailed, conversational
    
    # Relationships
    user = relationship("User", back_populates="profile") 