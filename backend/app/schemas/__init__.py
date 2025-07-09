"""
Pydantic schemas for request/response validation
"""

from .auth import (
    UserCreate,
    UserLogin,
    UserResponse,
    UserUpdate,
    PasswordReset,
    PasswordResetConfirm,
    PasswordChange,
    Token,
    TokenRefresh,
    TokenResponse,
    AuthResponse
)

from .onboarding import (
    MessageLengthPreference,
    MessageFrequency,
    OnboardingStep1,
    OnboardingStep2,
    OnboardingStep3,
    OnboardingStep4,
    OnboardingStep5,
    OnboardingStep6,
    OnboardingStepUpdate,
    OnboardingProgress,
    OnboardingDataResponse,
    OnboardingStart,
    OnboardingStepResponse,
    OnboardingComplete,
    OnboardingStepValidation
)

from .chat import (
    MessageRole,
    MessageType,
    SendMessageRequest,
    MessageResponse,
    ChatResponse,
    ConversationSummary,
    ConversationDetail,
    ConversationListResponse,
    ChatHistoryRequest,
    ChatHistoryResponse,
    ConversationCreate,
    ConversationUpdate,
    AIGenerationRequest,
    AIGenerationResponse,
    WebSocketMessage,
    WebSocketResponse,
    ConversationStarter,
    ChatStats,
    DailyMessage,
    VoiceMessageRequest,
    VoiceMessageResponse,
    ErrorResponse
)

__all__ = [
    # Auth schemas
    "UserCreate",
    "UserLogin", 
    "UserResponse",
    "UserUpdate",
    "PasswordReset",
    "PasswordResetConfirm",
    "PasswordChange",
    "Token",
    "TokenRefresh",
    "TokenResponse",
    "AuthResponse",
    
    # Onboarding schemas
    "MessageLengthPreference",
    "MessageFrequency",
    "OnboardingStep1",
    "OnboardingStep2",
    "OnboardingStep3",
    "OnboardingStep4",
    "OnboardingStep5",
    "OnboardingStep6",
    "OnboardingStepUpdate",
    "OnboardingProgress",
    "OnboardingDataResponse",
    "OnboardingStart",
    "OnboardingStepResponse",
    "OnboardingComplete",
    "OnboardingStepValidation",
    
    # Chat schemas
    "MessageRole",
    "MessageType",
    "SendMessageRequest",
    "MessageResponse",
    "ChatResponse",
    "ConversationSummary",
    "ConversationDetail",
    "ConversationListResponse",
    "ChatHistoryRequest",
    "ChatHistoryResponse",
    "ConversationCreate",
    "ConversationUpdate",
    "AIGenerationRequest",
    "AIGenerationResponse",
    "WebSocketMessage",
    "WebSocketResponse",
    "ConversationStarter",
    "ChatStats",
    "DailyMessage",
    "VoiceMessageRequest",
    "VoiceMessageResponse",
    "ErrorResponse"
] 