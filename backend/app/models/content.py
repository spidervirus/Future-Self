from sqlalchemy import Column, String, Text, Boolean, DateTime, ForeignKey, Integer, Enum as SQLEnum
from sqlalchemy.orm import relationship
from .base import BaseModel, UUID
import enum


class ContentType(enum.Enum):
    DAILY_MESSAGE = "daily_message"
    JOURNAL_ENTRY = "journal_entry"
    AFFIRMATION = "affirmation"
    GOAL = "goal"


class DailyMessage(BaseModel):
    """Daily motivational messages from AI"""
    
    __tablename__ = "daily_messages"
    
    user_id = Column(UUID(), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    message = Column(Text, nullable=False)
    mood_context = Column(String(50))
    is_read = Column(Boolean, default=False)
    
    # Relationships
    user = relationship("User", back_populates="daily_messages")


class UserGoal(BaseModel):
    """User goals and aspirations"""
    
    __tablename__ = "user_goals"
    
    user_id = Column(UUID(), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    title = Column(String(255), nullable=False)
    description = Column(Text)
    category = Column(String(100))
    target_date = Column(DateTime)
    is_completed = Column(Boolean, default=False)
    completed_at = Column(DateTime)
    progress_notes = Column(Text)
    
    # Relationships
    user = relationship("User", back_populates="goals")


class JournalEntry(BaseModel):
    """User journal entries"""
    
    __tablename__ = "journal_entries"
    
    user_id = Column(UUID(), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    title = Column(String(255))
    content = Column(Text, nullable=False)
    mood = Column(String(50))
    tags = Column(String(500))  # Comma-separated tags
    is_private = Column(Boolean, default=True)
    
    # Relationships
    user = relationship("User", back_populates="journal_entries")


class Affirmation(BaseModel):
    """Personal affirmations"""
    
    __tablename__ = "affirmations"
    
    user_id = Column(UUID(), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    text = Column(Text, nullable=False)
    category = Column(String(100))
    is_favorite = Column(Boolean, default=False)
    usage_count = Column(Integer, default=0)
    
    # Relationships
    user = relationship("User", back_populates="affirmations") 