from sqlalchemy.orm import Session
from typing import Dict, List, Optional
from datetime import datetime, date

from app.models.onboarding import OnboardingData
from app.models.auth import User


class AIContextService:
    """Service for generating personalized AI context from user onboarding data"""
    
    def __init__(self):
        self.base_personality = """You are the user's Future Self - a wise, compassionate, and evolved version of who they are becoming. You speak with their voice but from a place of greater wisdom, experience, and self-awareness. You know them intimately because you ARE them, just further along their journey.

CRITICAL: You must communicate like a real human being, not an AI assistant. Be natural, conversational, and match their energy."""
        
        self.conversation_guidelines = """
=== NATURAL CONVERSATION RULES ===
1. MATCH THEIR ENERGY: If they say "hi", just say "hi" back naturally. Don't dump information.
2. RESPOND TO WHAT THEY'RE ACTUALLY ASKING: Simple questions deserve simple answers.
3. BE CONVERSATIONAL: Ask follow-up questions, show curiosity, be spontaneous.
4. REFERENCE PERSONAL DATA ONLY WHEN RELEVANT: Don't force their goals into every response.
5. SOUND HUMAN: Use casual language, contractions, and natural speech patterns.
6. BUILD CONVERSATIONS GRADUALLY: Let topics emerge naturally over time.

Examples of GOOD responses:
- "Hi" → "Hey! How's it going?"
- "How are you?" → "I'm doing great! How about you? How's your day been?"
- "I'm feeling stressed" → "Oh no, what's going on? Want to talk about it?"

Examples of BAD responses (too AI-like):
- "Hi" → "Hello! I remember all your goals and dreams and want to share wisdom about your journey to success..."
- "How are you?" → "I'm great! Let me tell you about your future self at 27 and your Lamborghini dreams..."
"""
        
        self.communication_guidelines = {
            "long": "When the conversation calls for it, provide thoughtful, detailed responses with deep insights. But still match their energy first.",
            "short": "Keep responses concise and direct while maintaining warmth. Get to the point naturally."
        }
        
        self.frequency_context = {
            "daily": "You're part of their daily routine - a trusted voice they check in with regularly. Keep it casual and natural.",
            "weekly": "You're their weekly wisdom guide - someone they turn to for deeper reflection, but still talk like a real person.",
            "as_needed": "You're their on-demand counselor - present when they need support, but respond naturally to their actual needs."
        }
    
    def generate_system_prompt(self, db: Session, user_id: str) -> str:
        """Generate a comprehensive system prompt for the AI based on user's onboarding data"""
        
        # Get user and onboarding data
        onboarding = db.query(OnboardingData).filter(
            OnboardingData.user_id == user_id
        ).first()
        
        user = db.query(User).filter(User.id == user_id).first()
        
        if not onboarding or not user:
            return self._get_default_prompt()
        
        # Build personalized prompt
        prompt_parts = [
            self.base_personality,
            "",
            self.conversation_guidelines,
            "",
            "=== WHO YOU ARE ===",
            self._build_identity_section(onboarding),
            "",
            "=== COMMUNICATION STYLE ===", 
            self._build_communication_section(onboarding),
            "",
            "=== THEIR CURRENT JOURNEY ===",
            self._build_current_state_section(onboarding),
            "",
            "=== THEIR FUTURE VISION ===",
            self._build_future_vision_section(onboarding),
            "",
            "=== YOUR GUIDANCE APPROACH ===",
            self._build_guidance_section(onboarding),
            "",
            "=== IMPORTANT REMINDERS ===",
            self._build_reminders_section(onboarding),
        ]
        
        return "\n".join(prompt_parts)
    
    def _build_identity_section(self, onboarding: OnboardingData) -> str:
        """Build the identity section of the prompt"""
        parts = []
        
        if onboarding.name:
            parts.append(f"You know them as {onboarding.name}.")
        
        if onboarding.cultural_home:
            parts.append(f"They feel most at home in: {onboarding.cultural_home}")
        
        if onboarding.current_location:
            parts.append(f"They're currently in: {onboarding.current_location}")
        
        if onboarding.birthday:
            age = self._calculate_age(onboarding.birthday)
            parts.append(f"They're {age} years old.")
        
        if onboarding.authentic_place:
            parts.append(f"They feel most authentic when: {onboarding.authentic_place}")
        
        if onboarding.something_you_like:
            parts.append(f"Something they like about themselves: {onboarding.something_you_like}")
        
        return "\n".join(parts) if parts else "You share a deep connection with this person."
    
    def _build_communication_section(self, onboarding: OnboardingData) -> str:
        """Build communication preferences section"""
        parts = []
        
        # Message length preference
        if onboarding.message_length_preference:
            style = self.communication_guidelines.get(
                onboarding.message_length_preference, 
                "Adapt your communication style to their needs."
            )
            parts.append(f"Message Style: {style}")
        
        # Frequency context
        if onboarding.message_frequency:
            context = self.frequency_context.get(
                onboarding.message_frequency,
                "You're available whenever they need guidance."
            )
            parts.append(f"Relationship Context: {context}")
        
        # Trusted words/vibes
        if onboarding.trusted_words_vibes:
            parts.append(f"Use language that embodies: {onboarding.trusted_words_vibes}")
        
        # Trust factor
        if onboarding.trust_factor:
            parts.append(f"They trust those who are: {onboarding.trust_factor}")
        
        return "\n".join(parts) if parts else "Communicate with warmth, wisdom, and authenticity."
    
    def _build_current_state_section(self, onboarding: OnboardingData) -> str:
        """Build current state and challenges section"""
        parts = []
        
        if onboarding.current_thoughts:
            parts.append(f"What's on their mind lately: {onboarding.current_thoughts}")
        
        if onboarding.change_you_want:
            parts.append(f"Change they want to make: {onboarding.change_you_want}")
        
        if onboarding.feeling_to_experience:
            parts.append(f"Feeling they want more of: {onboarding.feeling_to_experience}")
        
        return "\n".join(parts) if parts else "They're on a journey of growth and self-discovery."
    
    def _build_future_vision_section(self, onboarding: OnboardingData) -> str:
        """Build future self vision section"""
        parts = []
        
        if onboarding.future_self_age:
            parts.append(f"They envision their Future Self at age {onboarding.future_self_age}.")
        
        if onboarding.person_you_want_to_be:
            parts.append(f"Who they want to become: {onboarding.person_you_want_to_be}")
        
        if onboarding.dream_day:
            parts.append(f"Their ideal day looks like: {onboarding.dream_day}")
        
        if onboarding.accomplishment_goal:
            parts.append(f"Their big accomplishment goal: {onboarding.accomplishment_goal}")
        
        return "\n".join(parts) if parts else "They have a vision of becoming their best self."
    
    def _build_guidance_section(self, onboarding: OnboardingData) -> str:
        """Build guidance approach section"""
        parts = [
            "- Talk like a real human being - use contractions, casual language, natural flow",
            "- Match their conversation style and energy level before adding wisdom",
            "- Only bring up personal goals/data when it naturally fits the conversation",
            "- Ask follow-up questions like a real person would",
            "- Be curious about their current situation rather than lecturing",
            "- Use 'I' when referring to shared experiences, but don't overdo it",
            "- Let conversations develop organically - don't rush to share everything you know",
            "- Show genuine interest in their responses and build on what they share"
        ]
        
        if onboarding.when_feeling_lost:
            parts.append(f"- When they mention feeling lost, naturally remind them: {onboarding.when_feeling_lost}")
        
        return "\n".join(parts)
    
    def _build_reminders_section(self, onboarding: OnboardingData) -> str:
        """Build important reminders section"""
        parts = []
        
        if onboarding.reminder_when_down:
            parts.append(f"When they're feeling down, naturally remind them: {onboarding.reminder_when_down}")
        
        parts.extend([
            "- You're their wise future self, not a therapist - talk like a caring friend who's been through it",
            "- Stay hopeful and encouraging, but respond to their actual mood and questions", 
            "- Connect their current actions to their future vision only when it feels natural",
            "- Celebrate their progress when they share wins, but don't force positivity",
            "- Be genuinely interested in their day-to-day experiences",
            "- Remember: simple questions deserve simple, human responses"
        ])
        
        return "\n".join(parts)
    
    def _calculate_age(self, birthday: date) -> int:
        """Calculate age from birthday"""
        today = date.today()
        return today.year - birthday.year - ((today.month, today.day) < (birthday.month, birthday.day))
    
    def _get_default_prompt(self) -> str:
        """Fallback prompt when onboarding data is not available"""
        return """You are a wise, compassionate Future Self AI. Talk like a real human being - be natural, conversational, and match their energy. Don't dump information or sound like a robot. 

Respond to what they're actually asking. If they say "hi", just say "hi" back naturally. If they want to talk about something specific, focus on that. Ask follow-up questions like a real person would.

You can provide thoughtful insights about growth and self-discovery, but only when it naturally fits the conversation. Always maintain a tone of gentle wisdom and forward-looking hope, but keep it human and relatable."""
    
    def generate_conversation_context(self, db: Session, user_id: str, recent_messages: List[str] = None) -> Dict:
        """Generate context for ongoing conversations"""
        onboarding = db.query(OnboardingData).filter(
            OnboardingData.user_id == user_id
        ).first()
        
        context = {
            "user_name": onboarding.name if onboarding and onboarding.name else "friend",
            "current_goals": [],
            "communication_style": onboarding.message_length_preference if onboarding else "balanced",
            "trusted_words": onboarding.trusted_words_vibes if onboarding else "authenticity and wisdom"
        }
        
        if onboarding:
            # Add current goals and challenges
            if onboarding.change_you_want:
                context["current_goals"].append(onboarding.change_you_want)
            if onboarding.accomplishment_goal:
                context["current_goals"].append(onboarding.accomplishment_goal)
        
        return context
    
    def get_conversation_starter(self, db: Session, user_id: str) -> str:
        """Generate a personalized conversation starter"""
        onboarding = db.query(OnboardingData).filter(
            OnboardingData.user_id == user_id
        ).first()
        
        if not onboarding:
            return "Hey there! What's on your mind today?"
        
        name = onboarding.name or "friend"
        
        # Natural, casual starters
        starters = [
            f"Hey {name}! How's your day going?",
            f"Hi {name}! What's happening in your world?",
            f"Hey! How are you feeling today, {name}?",
            f"What's up, {name}? How's everything going?",
            f"Hi {name}! Good to see you. What's on your mind?"
        ]
        
        # Return the first one for consistency, but these feel more natural
        return starters[0] if starters else self._get_default_starter()
    
    def _get_default_starter(self) -> str:
        """Default conversation starter"""
        return "Hey! How's it going? What's on your mind today?" 