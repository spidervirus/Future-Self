from sqlalchemy import Column, String, Text, DateTime, ForeignKey, Boolean, Enum as SQLEnum
from sqlalchemy.orm import relationship
from .base import BaseModel, UUID
import enum


class MessageRole(enum.Enum):
    USER = "user"
    ASSISTANT = "assistant"
    SYSTEM = "system"


class Conversation(BaseModel):
    """Conversation model for organizing chat sessions"""
    
    __tablename__ = "conversations"
    
    user_id = Column(UUID(), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    title = Column(String(255), nullable=False)
    summary = Column(Text)
    is_archived = Column(Boolean, default=False)
    
    # Relationships
    user = relationship("User", back_populates="conversations")
    messages = relationship("ChatMessage", back_populates="conversation", cascade="all, delete-orphan")


class ChatMessage(BaseModel):
    """Chat message model for storing conversation history"""
    
    __tablename__ = "chat_messages"
    
    conversation_id = Column(UUID(), ForeignKey("conversations.id", ondelete="CASCADE"), nullable=False)
    role = Column(SQLEnum(MessageRole), nullable=False)
    content = Column(Text, nullable=False)
    message_metadata = Column(Text)  # JSON string for additional data
    token_count = Column(Text)  # Store as text for flexibility
    
    # Relationships
    conversation = relationship("Conversation", back_populates="messages") 