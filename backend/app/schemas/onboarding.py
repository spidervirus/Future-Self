from pydantic import BaseModel, Field, validator, field_validator
from typing import Optional, List, Dict, Any
from datetime import datetime, date
from enum import Enum


class MessageLengthPreference(str, Enum):
    """Message length preference options"""
    LONG = "long"
    SHORT = "short"


class MessageFrequency(str, Enum):
    """Message frequency options"""
    DAILY = "daily"
    WEEKLY = "weekly"
    AS_NEEDED = "as_needed"


class OnboardingStepBase(BaseModel):
    """Base schema for onboarding step data"""
    step_number: int = Field(..., ge=1, le=6, description="Step number (1-6)")


class OnboardingStep1(OnboardingStepBase):
    """Step 1: Let Me Meet You"""
    step_number: int = Field(default=1, ge=1, le=1)
    name: Optional[str] = Field(None, min_length=1, max_length=255, description="User's preferred name")
    birthday: Optional[date] = Field(None, description="User's birthday")
    cultural_home: Optional[str] = Field(None, description="Where they feel culturally at home")
    current_location: Optional[str] = Field(None, max_length=255, description="Current location")


class OnboardingStep2(OnboardingStepBase):
    """Step 2: Tell Me More About You"""
    step_number: int = Field(default=2, ge=2, le=2)
    current_thoughts: Optional[str] = Field(None, description="What's on their mind lately")
    authentic_place: Optional[str] = Field(None, description="Place where they feel most authentic")
    something_you_like: Optional[str] = Field(None, description="Something they really like")
    reminder_when_down: Optional[str] = Field(None, description="What to remember when feeling down")


class OnboardingStep3(OnboardingStepBase):
    """Step 3: Moving from A to B"""
    step_number: int = Field(default=3, ge=3, le=3)
    change_you_want: Optional[str] = Field(None, description="Change they want to make")
    feeling_to_experience: Optional[str] = Field(None, description="Feeling they want to experience more")
    person_you_want_to_be: Optional[str] = Field(None, description="Who they want to become")


class OnboardingStep4(OnboardingStepBase):
    """Step 4: Tell Me About Your Future Self"""
    step_number: int = Field(default=4, ge=4, le=4)
    future_self_age: Optional[int] = Field(None, ge=18, le=150, description="Age of their future self")
    dream_day: Optional[str] = Field(None, description="Description of their perfect day")
    accomplishment_goal: Optional[str] = Field(None, description="Goal they want to accomplish")
    future_self_photo_url: Optional[str] = Field(None, description="URL to uploaded future self photo")


class OnboardingStep5(OnboardingStepBase):
    """Step 5: Communication Style Preferences"""
    step_number: int = Field(default=5, ge=5, le=5)
    trusted_words_vibes: Optional[str] = Field(None, description="Words/vibes that build trust")
    message_length_preference: Optional[MessageLengthPreference] = Field(None, description="Preferred message length")
    message_frequency: Optional[MessageFrequency] = Field(None, description="Preferred message frequency")
    trust_factor: Optional[str] = Field(None, description="What builds trust for them")


class OnboardingStep6(OnboardingStepBase):
    """Step 6: Additional Context (Optional)"""
    step_number: int = Field(default=6, ge=6, le=6)
    when_feeling_lost: Optional[str] = Field(None, description="What to do when feeling lost")


class OnboardingStepUpdate(BaseModel):
    """Schema for updating a specific onboarding step"""
    step_data: Dict[str, Any] = Field(..., description="Step-specific data to update")
    
    @field_validator('step_data')
    @classmethod
    def validate_step_data(cls, v):
        """Validate step data is not empty"""
        if not v:
            raise ValueError("Step data cannot be empty")
        return v


class OnboardingProgress(BaseModel):
    """Schema for onboarding progress tracking"""
    user_id: str
    completed_steps: int = Field(..., ge=0, le=6)
    is_complete: bool
    completion_percentage: float = Field(..., ge=0.0, le=100.0)
    current_step: int = Field(..., ge=1, le=6)
    
    model_config = {"from_attributes": True}
    
    @field_validator('user_id', mode='before')
    @classmethod
    def convert_uuid_to_string(cls, v):
        """Convert UUID object to string"""
        from uuid import UUID
        if isinstance(v, UUID):
            return str(v)
        return v


class OnboardingDataResponse(BaseModel):
    """Complete onboarding data response"""
    user_id: str
    
    # Step 1 fields
    name: Optional[str]
    birthday: Optional[date]
    cultural_home: Optional[str]
    current_location: Optional[str]
    
    # Step 2 fields
    current_thoughts: Optional[str]
    authentic_place: Optional[str]
    something_you_like: Optional[str]
    reminder_when_down: Optional[str]
    
    # Step 3 fields
    change_you_want: Optional[str]
    feeling_to_experience: Optional[str]
    person_you_want_to_be: Optional[str]
    
    # Step 4 fields
    future_self_age: Optional[int]
    dream_day: Optional[str]
    accomplishment_goal: Optional[str]
    future_self_photo_url: Optional[str]
    
    # Step 5 fields
    trusted_words_vibes: Optional[str]
    message_length_preference: Optional[MessageLengthPreference]
    message_frequency: Optional[MessageFrequency]
    trust_factor: Optional[str]
    
    # Step 6 fields
    when_feeling_lost: Optional[str]
    
    # Metadata
    completed_steps: int
    is_complete: bool
    completed_at: Optional[datetime]
    created_at: datetime
    updated_at: datetime
    
    model_config = {"from_attributes": True}
    
    @field_validator('user_id', mode='before')
    @classmethod
    def convert_uuid_to_string(cls, v):
        """Convert UUID object to string"""
        from uuid import UUID
        if isinstance(v, UUID):
            return str(v)
        return v


class OnboardingStart(BaseModel):
    """Schema for starting onboarding process"""
    message: str = Field(default="Onboarding started successfully")


class OnboardingStepResponse(BaseModel):
    """Response after updating an onboarding step"""
    message: str
    step_number: int
    completed_steps: int
    is_step_complete: bool
    completion_percentage: float


class OnboardingComplete(BaseModel):
    """Schema for completing onboarding"""
    user_id: str
    completion_percentage: float
    completed_at: datetime
    message: str = Field(default="Onboarding completed successfully!")
    
    @field_validator('user_id', mode='before')
    @classmethod
    def convert_uuid_to_string(cls, v):
        """Convert UUID object to string"""
        from uuid import UUID
        if isinstance(v, UUID):
            return str(v)
        return v


class OnboardingStepValidation(BaseModel):
    """Schema for validating step completion"""
    step_number: int = Field(..., ge=1, le=6)
    is_complete: bool
    missing_fields: List[str] = Field(default=[])
    completion_percentage: float = Field(..., ge=0.0, le=100.0) 