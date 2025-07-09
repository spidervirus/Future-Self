from pydantic import BaseModel, Field, field_validator
from typing import Optional, List, Dict, Any
from datetime import datetime
from enum import Enum
from uuid import UUID


class MessageRole(str, Enum):
    """Message role types"""
    USER = "user"
    ASSISTANT = "assistant"
    SYSTEM = "system"


class MessageType(str, Enum):
    """Message content types"""
    TEXT = "text"
    VOICE = "voice"
    IMAGE = "image"
    SYSTEM_MESSAGE = "system_message"


class SendMessageRequest(BaseModel):
    """Request schema for sending a message"""
    content: str = Field(..., min_length=1, max_length=4000, description="Message content")
    conversation_id: Optional[str] = Field(None, description="Existing conversation ID, if none provided, creates new conversation")
    message_type: MessageType = Field(default=MessageType.TEXT, description="Type of message content")
    metadata: Optional[Dict[str, Any]] = Field(default=None, description="Additional message metadata")


class MessageResponse(BaseModel):
    """Response schema for individual messages"""
    id: str
    conversation_id: str
    role: MessageRole
    content: str
    message_type: MessageType
    metadata: Optional[Dict[str, Any]]
    token_count: Optional[str]
    created_at: datetime
    
    model_config = {"from_attributes": True}
    
    @field_validator('id', 'conversation_id', mode='before')
    @classmethod
    def convert_uuid_to_string(cls, v):
        """Convert UUID object to string"""
        if isinstance(v, UUID):
            return str(v)
        return v


class ChatResponse(BaseModel):
    """Response schema for chat interactions"""
    user_message: MessageResponse
    ai_message: MessageResponse
    conversation_id: str
    is_new_conversation: bool = Field(description="Whether this created a new conversation")


class ConversationSummary(BaseModel):
    """Summary of a conversation"""
    id: str
    title: str
    summary: Optional[str]
    message_count: int
    last_message_at: datetime
    is_archived: bool
    created_at: datetime
    
    model_config = {"from_attributes": True}
    
    @field_validator('id', mode='before')
    @classmethod
    def convert_uuid_to_string(cls, v):
        """Convert UUID object to string"""
        if isinstance(v, UUID):
            return str(v)
        return v


class ConversationDetail(BaseModel):
    """Detailed conversation with messages"""
    id: str
    title: str
    summary: Optional[str]
    is_archived: bool
    created_at: datetime
    updated_at: datetime
    messages: List[MessageResponse]
    
    model_config = {"from_attributes": True}
    
    @field_validator('id', mode='before')
    @classmethod
    def convert_uuid_to_string(cls, v):
        """Convert UUID object to string"""
        if isinstance(v, UUID):
            return str(v)
        return v


class ConversationListResponse(BaseModel):
    """Response for listing conversations"""
    conversations: List[ConversationSummary]
    total_count: int
    has_more: bool


class ChatHistoryRequest(BaseModel):
    """Request schema for chat history"""
    conversation_id: Optional[str] = Field(None, description="Specific conversation ID")
    limit: int = Field(default=50, ge=1, le=100, description="Number of messages to retrieve")
    offset: int = Field(default=0, ge=0, description="Number of messages to skip")
    include_system_messages: bool = Field(default=False, description="Include system messages in history")


class ChatHistoryResponse(BaseModel):
    """Response schema for chat history"""
    messages: List[MessageResponse]
    conversation_id: Optional[str]
    total_count: int
    has_more: bool


class ConversationCreate(BaseModel):
    """Schema for creating a new conversation"""
    title: Optional[str] = Field(None, max_length=255, description="Conversation title")
    initial_message: Optional[str] = Field(None, description="First message to start the conversation")


class ConversationUpdate(BaseModel):
    """Schema for updating conversation details"""
    title: Optional[str] = Field(None, max_length=255, description="New conversation title")
    is_archived: Optional[bool] = Field(None, description="Archive status")


class AIGenerationRequest(BaseModel):
    """Internal schema for AI response generation"""
    user_message: str
    conversation_history: List[Dict[str, str]] = Field(default=[], description="Recent conversation context")
    user_context: Dict[str, Any] = Field(default={}, description="User personalization context")
    system_prompt: str = Field(description="Personalized system prompt")


class AIGenerationResponse(BaseModel):
    """Internal schema for AI response"""
    content: str
    token_count: Optional[int]
    model_used: str
    generation_time_ms: Optional[int]
    metadata: Optional[Dict[str, Any]]


class WebSocketMessage(BaseModel):
    """Schema for WebSocket messages"""
    type: str = Field(..., description="Message type: 'message', 'typing', 'error', 'connected'")
    content: Optional[str] = Field(None, description="Message content")
    conversation_id: Optional[str] = Field(None, description="Conversation ID")
    metadata: Optional[Dict[str, Any]] = Field(default=None, description="Additional data")


class WebSocketResponse(BaseModel):
    """Schema for WebSocket responses"""
    type: str
    content: Optional[str] = None
    message_id: Optional[str] = None
    conversation_id: Optional[str] = None
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    metadata: Optional[Dict[str, Any]] = None


class ConversationStarter(BaseModel):
    """Schema for conversation starter"""
    message: str = Field(description="Personalized conversation starter message")
    suggested_topics: List[str] = Field(default=[], description="Suggested conversation topics")
    context: Optional[Dict[str, Any]] = Field(default=None, description="Context used for personalization")


class ChatStats(BaseModel):
    """Schema for chat statistics"""
    total_conversations: int
    total_messages: int
    favorite_topics: List[str] = Field(default=[], description="Most discussed topics")
    chat_frequency: str = Field(description="How often user chats")
    last_chat_date: Optional[datetime]
    avg_message_length: float


class DailyMessage(BaseModel):
    """Schema for daily AI messages"""
    id: str
    content: str
    message_type: str = Field(default="daily_wisdom")
    is_read: bool = Field(default=False)
    created_at: datetime
    personalization_context: Optional[Dict[str, Any]] = Field(default=None)
    
    @field_validator('id', mode='before')
    @classmethod
    def convert_uuid_to_string(cls, v):
        """Convert UUID object to string"""
        if isinstance(v, UUID):
            return str(v)
        return v


class VoiceMessageRequest(BaseModel):
    """Schema for voice message upload"""
    audio_data: str = Field(description="Base64 encoded audio data")
    conversation_id: Optional[str] = Field(None, description="Conversation ID")
    duration_seconds: Optional[float] = Field(None, ge=0, le=300, description="Audio duration in seconds")
    audio_format: str = Field(default="mp3", description="Audio format")


class VoiceMessageResponse(BaseModel):
    """Schema for voice message response"""
    transcription: str = Field(description="Transcribed text from audio")
    ai_response: MessageResponse = Field(description="AI text response")
    audio_response_url: Optional[str] = Field(None, description="URL to AI audio response if available")


class ErrorResponse(BaseModel):
    """Schema for error responses"""
    error: str = Field(description="Error type")
    message: str = Field(description="Human-readable error message")
    details: Optional[Dict[str, Any]] = Field(default=None, description="Additional error details")
    timestamp: datetime = Field(default_factory=datetime.utcnow) 