from sqlalchemy.orm import Session
from typing import Optional, Dict, Any, List
from datetime import datetime, date

from app.models.onboarding import OnboardingData
from app.models.auth import User
from app.schemas.onboarding import (
    OnboardingStepUpdate,
    OnboardingProgress,
    OnboardingDataResponse,
    OnboardingStepValidation,
    MessageLengthPreference,
    MessageFrequency
)
from app.core.exceptions import ValidationError, NotFoundError


class OnboardingService:
    """Service class for managing user onboarding flow"""
    
    def __init__(self):
        self.step_fields = {
            1: ['name', 'birthday', 'cultural_home', 'current_location'],
            2: ['current_thoughts', 'authentic_place', 'something_you_like', 'reminder_when_down'],
            3: ['change_you_want', 'feeling_to_experience', 'person_you_want_to_be'],
            4: ['future_self_age', 'dream_day', 'accomplishment_goal'],
            5: ['trusted_words_vibes', 'message_length_preference', 'message_frequency', 'trust_factor'],
            6: ['when_feeling_lost']  # Optional step
        }
        
        self.step_names = {
            1: "Let Me Meet You",
            2: "Tell Me More About You", 
            3: "Moving from A to B",
            4: "Tell Me About Your Future Self",
            5: "Communication Style Preferences",
            6: "Additional Context"
        }
    
    def get_or_create_onboarding(self, db: Session, user_id: str) -> OnboardingData:
        """Get existing onboarding data or create new record"""
        onboarding = db.query(OnboardingData).filter(
            OnboardingData.user_id == user_id
        ).first()
        
        if not onboarding:
            # Create new onboarding record
            onboarding = OnboardingData(
                user_id=user_id,
                completed_steps=0,
                is_complete=False
            )
            db.add(onboarding)
            db.commit()
            db.refresh(onboarding)
        
        return onboarding
    
    def start_onboarding(self, db: Session, user_id: str) -> OnboardingData:
        """Initialize onboarding process for user"""
        # Verify user exists
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise NotFoundError("User not found")
        
        # Get or create onboarding record
        onboarding = self.get_or_create_onboarding(db, user_id)
        
        return onboarding
    
    def update_step(
        self, 
        db: Session, 
        user_id: str, 
        step_number: int, 
        step_data: Dict[str, Any]
    ) -> OnboardingData:
        """Update a specific onboarding step with validation"""
        if step_number not in range(1, 7):
            raise ValidationError("Step number must be between 1 and 6")
        
        onboarding = self.get_or_create_onboarding(db, user_id)
        
        # Validate and update step data
        self._validate_step_data(step_number, step_data)
        updated_fields = self._update_step_fields(onboarding, step_number, step_data)
        
        if not updated_fields:
            raise ValidationError("No valid fields provided for this step")
        
        # Update metadata
        onboarding.update_completed_steps()
        
        # Check if onboarding is complete
        if onboarding.completed_steps >= 5 and not onboarding.is_complete:
            onboarding.is_complete = True
            onboarding.completed_at = datetime.utcnow()
        
        db.commit()
        db.refresh(onboarding)
        
        return onboarding
    
    def get_progress(self, db: Session, user_id: str) -> OnboardingProgress:
        """Get current onboarding progress"""
        onboarding = self.get_or_create_onboarding(db, user_id)
        
        current_step = min(onboarding.completed_steps + 1, 6)
        completion_percentage = onboarding.get_completion_percentage()
        
        return OnboardingProgress(
            user_id=str(onboarding.user_id),
            completed_steps=onboarding.completed_steps,
            is_complete=onboarding.is_complete,
            completion_percentage=completion_percentage,
            current_step=current_step
        )
    
    def get_onboarding_data(self, db: Session, user_id: str) -> OnboardingDataResponse:
        """Get complete onboarding data"""
        onboarding = self.get_or_create_onboarding(db, user_id)
        return OnboardingDataResponse.model_validate(onboarding)
    
    def validate_step(self, db: Session, user_id: str, step_number: int) -> OnboardingStepValidation:
        """Validate if a specific step is complete and identify missing fields"""
        if step_number not in range(1, 7):
            raise ValidationError("Step number must be between 1 and 6")
        
        onboarding = self.get_or_create_onboarding(db, user_id)
        
        # Check step completion
        is_complete = onboarding.is_step_complete(step_number)
        
        # Find missing fields
        missing_fields = []
        if not is_complete and step_number != 6:  # Step 6 is optional
            step_fields = self.step_fields[step_number]
            for field in step_fields:
                if getattr(onboarding, field) is None:
                    missing_fields.append(field)
        
        completion_percentage = onboarding.get_completion_percentage()
        
        return OnboardingStepValidation(
            step_number=step_number,
            is_complete=is_complete,
            missing_fields=missing_fields,
            completion_percentage=completion_percentage
        )
    
    def complete_onboarding(self, db: Session, user_id: str) -> OnboardingData:
        """Mark onboarding as complete if requirements are met"""
        onboarding = self.get_or_create_onboarding(db, user_id)
        
        # Check if minimum requirements are met (steps 1-5)
        if onboarding.completed_steps < 5:
            missing_steps = []
            for step in range(1, 6):
                if not onboarding.is_step_complete(step):
                    missing_steps.append(f"Step {step}: {self.step_names[step]}")
            
            raise ValidationError(
                f"Cannot complete onboarding. Missing required steps: {', '.join(missing_steps)}"
            )
        
        # Mark as complete
        onboarding.is_complete = True
        onboarding.completed_at = datetime.utcnow()
        
        db.commit()
        db.refresh(onboarding)
        
        return onboarding
    
    def _validate_step_data(self, step_number: int, step_data: Dict[str, Any]) -> None:
        """Validate step data according to step requirements"""
        valid_fields = self.step_fields[step_number]
        
        # Check for invalid fields
        invalid_fields = set(step_data.keys()) - set(valid_fields)
        if invalid_fields:
            raise ValidationError(
                f"Invalid fields for step {step_number}: {', '.join(invalid_fields)}. "
                f"Valid fields: {', '.join(valid_fields)}"
            )
        
        # Validate specific field types and constraints
        if step_number == 1:
            self._validate_step1_data(step_data)
        elif step_number == 4:
            self._validate_step4_data(step_data)
        elif step_number == 5:
            self._validate_step5_data(step_data)
    
    def _validate_step1_data(self, step_data: Dict[str, Any]) -> None:
        """Validate Step 1 specific data"""
        if 'birthday' in step_data and step_data['birthday']:
            # Ensure birthday is not in the future
            if isinstance(step_data['birthday'], str):
                try:
                    birthday = datetime.strptime(step_data['birthday'], '%Y-%m-%d').date()
                except ValueError:
                    raise ValidationError("Birthday must be in YYYY-MM-DD format")
            else:
                birthday = step_data['birthday']
            
            if birthday > date.today():
                raise ValidationError("Birthday cannot be in the future")
            
            # Check reasonable age range (13-120 years old)
            age = (date.today() - birthday).days / 365.25
            if age < 13 or age > 120:
                raise ValidationError("Please enter a valid birthday (age must be between 13 and 120)")
    
    def _validate_step4_data(self, step_data: Dict[str, Any]) -> None:
        """Validate Step 4 specific data"""
        if 'future_self_age' in step_data and step_data['future_self_age']:
            age = step_data['future_self_age']
            if not isinstance(age, int) or age < 18 or age > 150:
                raise ValidationError("Future self age must be between 18 and 150")
    
    def _validate_step5_data(self, step_data: Dict[str, Any]) -> None:
        """Validate Step 5 specific data"""
        if 'message_length_preference' in step_data and step_data['message_length_preference']:
            if step_data['message_length_preference'] not in [e.value for e in MessageLengthPreference]:
                raise ValidationError(f"Invalid message length preference. Must be one of: {', '.join([e.value for e in MessageLengthPreference])}")
        
        if 'message_frequency' in step_data and step_data['message_frequency']:
            if step_data['message_frequency'] not in [e.value for e in MessageFrequency]:
                raise ValidationError(f"Invalid message frequency. Must be one of: {', '.join([e.value for e in MessageFrequency])}")
    
    def _update_step_fields(
        self, 
        onboarding: OnboardingData, 
        step_number: int, 
        step_data: Dict[str, Any]
    ) -> List[str]:
        """Update onboarding model fields for specific step"""
        updated_fields = []
        valid_fields = self.step_fields[step_number]
        
        for field, value in step_data.items():
            if field in valid_fields and value is not None:
                # Special handling for date fields
                if field == 'birthday' and isinstance(value, str):
                    try:
                        value = datetime.strptime(value, '%Y-%m-%d').date()
                    except ValueError:
                        continue
                
                setattr(onboarding, field, value)
                updated_fields.append(field)
        
        return updated_fields
    
    def get_next_step(self, db: Session, user_id: str) -> int:
        """Get the next incomplete step number"""
        onboarding = self.get_or_create_onboarding(db, user_id)
        
        # Check each step to find the first incomplete one
        for step in range(1, 7):
            if not onboarding.is_step_complete(step):
                return step
        
        # All steps complete
        return 6
    
    def get_step_summary(self, db: Session, user_id: str) -> Dict[int, Dict[str, Any]]:
        """Get summary of all steps with completion status"""
        onboarding = self.get_or_create_onboarding(db, user_id)
        
        summary = {}
        for step in range(1, 7):
            is_complete = onboarding.is_step_complete(step)
            missing_fields = []
            
            if not is_complete and step != 6:  # Step 6 is optional
                step_fields = self.step_fields[step]
                for field in step_fields:
                    if getattr(onboarding, field) is None:
                        missing_fields.append(field)
            
            summary[step] = {
                'name': self.step_names[step],
                'is_complete': is_complete,
                'missing_fields': missing_fields,
                'is_optional': step == 6
            }
        
        return summary 