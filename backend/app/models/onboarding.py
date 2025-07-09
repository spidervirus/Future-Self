from sqlalchemy import Column, String, Text, Integer, Boolean, Date, DateTime, ForeignKey, CheckConstraint
from sqlalchemy.orm import relationship
from .base import BaseModel, UUID


class OnboardingData(BaseModel):
    """Onboarding data model storing all user personalization responses"""
    
    __tablename__ = "onboarding_data"
    
    user_id = Column(UUID(), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, unique=True)
    
    # Step 1: Let Me Meet You
    name = Column(String(255))
    birthday = Column(Date)
    cultural_home = Column(Text)
    current_location = Column(String(255))
    
    # Step 2: Tell Me More About You
    current_thoughts = Column(Text)
    authentic_place = Column(Text)
    something_you_like = Column(Text)
    reminder_when_down = Column(Text)
    
    # Step 3: Moving from A to B
    change_you_want = Column(Text)
    feeling_to_experience = Column(Text)
    person_you_want_to_be = Column(Text)
    
    # Step 4: Tell Me About Your Future Self
    future_self_age = Column(Integer)
    dream_day = Column(Text)
    accomplishment_goal = Column(Text)
    future_self_photo_url = Column(Text)
    
    # Step 5: Communication Style Preferences
    trusted_words_vibes = Column(Text)
    message_length_preference = Column(String(20))
    message_frequency = Column(String(20))
    trust_factor = Column(Text)
    
    # Step 6: Additional Context
    when_feeling_lost = Column(Text)
    
    # Metadata
    completed_steps = Column(Integer, default=0)
    is_complete = Column(Boolean, default=False)
    completed_at = Column(DateTime)
    
    # Add constraints
    __table_args__ = (
        CheckConstraint(
            message_length_preference.in_(['long', 'short']),
            name='check_message_length_preference'
        ),
        CheckConstraint(
            message_frequency.in_(['daily', 'weekly', 'as_needed']),
            name='check_message_frequency'
        ),
        CheckConstraint(
            'completed_steps >= 0 AND completed_steps <= 6',
            name='check_completed_steps_range'
        ),
    )
    
    # Relationships
    user = relationship("User", back_populates="onboarding_data")
    
    def get_completion_percentage(self):
        """Calculate onboarding completion percentage"""
        return (self.completed_steps / 6) * 100
    
    def is_step_complete(self, step_number: int) -> bool:
        """Check if a specific step is complete"""
        step_fields = {
            1: [self.name, self.birthday, self.cultural_home, self.current_location],
            2: [self.current_thoughts, self.authentic_place, self.something_you_like, self.reminder_when_down],
            3: [self.change_you_want, self.feeling_to_experience, self.person_you_want_to_be],
            4: [self.future_self_age, self.dream_day, self.accomplishment_goal],
            5: [self.trusted_words_vibes, self.message_length_preference, self.message_frequency, self.trust_factor],
            6: [True]  # Step 6 is optional
        }
        
        if step_number not in step_fields:
            return False
        
        if step_number == 6:
            return True  # Step 6 is always considered complete (optional)
        
        return all(field is not None for field in step_fields[step_number])
    
    def update_completed_steps(self):
        """Update the completed_steps count based on filled fields"""
        completed = 0
        for step in range(1, 7):
            if self.is_step_complete(step):
                completed += 1
            else:
                break  # Steps must be completed in order
        
        self.completed_steps = completed
        self.is_complete = completed >= 5  # At least 5 steps (step 6 is optional) 