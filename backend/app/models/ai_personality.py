from sqlalchemy import Column, String, Text, Boolean, Integer, ForeignKey
from sqlalchemy.orm import relationship
from .base import BaseModel, UUID


class AIPersonalityProfile(BaseModel):
    """AI personality configuration for each user"""
    
    __tablename__ = "ai_personality_profiles"
    
    user_id = Column(UUID(), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, unique=True)
    
    # Personality traits
    name = Column(String(100), default="Your Future Self")
    tone = Column(String(50), default="warm")  # warm, professional, casual, inspiring
    communication_style = Column(String(50), default="conversational")  # brief, detailed, conversational
    empathy_level = Column(Integer, default=8)  # 1-10 scale
    motivation_style = Column(String(50), default="encouraging")  # tough_love, encouraging, gentle
    
    # Context and background
    background_story = Column(Text)
    core_values = Column(Text)  # JSON string of values
    speaking_patterns = Column(Text)  # JSON string of patterns
    
    # Behavioral settings
    proactivity_level = Column(Integer, default=5)  # How often AI initiates conversations
    reminder_frequency = Column(String(20), default="daily")  # daily, weekly, as_needed
    
    # Relationships
    user = relationship("User", back_populates="ai_personality")
    
    def activate(self):
        """Activate this personality profile"""
        self.is_active = True
    
    def deactivate(self):
        """Deactivate this personality profile"""
        self.is_active = False
    
    def update_traits(self, traits_dict: dict):
        """Update personality traits"""
        if self.traits is None:
            self.traits = {}
        self.traits.update(traits_dict)
    
    def update_communication_style(self, style_dict: dict):
        """Update communication style preferences"""
        if self.communication_style is None:
            self.communication_style = {}
        self.communication_style.update(style_dict)


class UserActivity(BaseModel):
    """User activities and engagement tracking"""
    
    __tablename__ = "user_activities"
    
    user_id = Column(UUID(), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    activity_type = Column(String(100), nullable=False)  # 'chat', 'journal', 'goal_update', 'daily_message_read'
    activity_data = Column(Text)  # JSON string for activity data
    
    # Relationships
    user = relationship("User", back_populates="activities")
    
    def add_activity_data(self, key: str, value):
        """Add data to the activity"""
        if self.activity_data is None:
            self.activity_data = {}
        self.activity_data[key] = value


class FileUpload(BaseModel):
    """File uploads model for user content"""
    
    __tablename__ = "file_uploads"
    
    user_id = Column(UUID(), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    filename = Column(String(255), nullable=False)
    original_filename = Column(String(255), nullable=False)
    file_type = Column(String(100), nullable=False)
    file_size = Column(Integer, nullable=False)
    file_path = Column(Text, nullable=False)
    upload_purpose = Column(String(100))  # 'profile_photo', 'future_self_photo', 'voice_message', 'journal_attachment'
    file_metadata = Column(Text)  # JSON string for metadata
    
    # Relationships
    user = relationship("User", back_populates="file_uploads")
    
    def is_image(self) -> bool:
        """Check if the file is an image"""
        image_types = ['image/jpeg', 'image/png', 'image/gif', 'image/webp']
        return self.file_type in image_types
    
    def is_audio(self) -> bool:
        """Check if the file is an audio file"""
        audio_types = ['audio/mpeg', 'audio/wav', 'audio/ogg', 'audio/mp4']
        return self.file_type in audio_types
    
    def get_file_size_mb(self) -> float:
        """Get file size in MB"""
        return self.file_size / (1024 * 1024)
    
    def add_metadata(self, key: str, value):
        """Add metadata to the file"""
        if self.file_metadata is None:
            self.file_metadata = {}
        self.file_metadata[key] = value 