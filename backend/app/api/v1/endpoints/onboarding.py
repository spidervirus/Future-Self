from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import Dict, Any

from app.database.connection import get_db
from app.services.onboarding_service import OnboardingService
from app.schemas.onboarding import (
    OnboardingStepUpdate,
    OnboardingProgress,
    OnboardingDataResponse,
    OnboardingStart,
    OnboardingStepResponse,
    OnboardingComplete,
    OnboardingStepValidation
)
from app.core.auth import get_current_user
from app.models.auth import User
from app.core.exceptions import ValidationError, NotFoundError


router = APIRouter()
onboarding_service = OnboardingService()


@router.post("/start", response_model=OnboardingStart, status_code=status.HTTP_201_CREATED)
async def start_onboarding(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Initialize onboarding process for the current user"""
    try:
        onboarding = onboarding_service.start_onboarding(db, str(current_user.id))
        return OnboardingStart(message="Onboarding started successfully")
        
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to start onboarding"
        )


@router.put("/step/{step_number}", response_model=OnboardingStepResponse)
async def update_onboarding_step(
    step_number: int,
    step_update: OnboardingStepUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update a specific onboarding step"""
    try:
        onboarding = onboarding_service.update_step(
            db, 
            str(current_user.id), 
            step_number, 
            step_update.step_data
        )
        
        # Check if the step is now complete
        validation = onboarding_service.validate_step(db, str(current_user.id), step_number)
        completion_percentage = onboarding.get_completion_percentage()
        
        return OnboardingStepResponse(
            message=f"Step {step_number} updated successfully",
            step_number=step_number,
            completed_steps=onboarding.completed_steps,
            is_step_complete=validation.is_complete,
            completion_percentage=completion_percentage
        )
        
    except ValidationError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to update onboarding step"
        )


@router.get("/progress", response_model=OnboardingProgress)
async def get_onboarding_progress(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get current user's onboarding progress"""
    try:
        progress = onboarding_service.get_progress(db, str(current_user.id))
        return progress
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get onboarding progress"
        )


@router.get("/data", response_model=OnboardingDataResponse)
async def get_onboarding_data(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get current user's complete onboarding data"""
    try:
        data = onboarding_service.get_onboarding_data(db, str(current_user.id))
        return data
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get onboarding data"
        )


@router.get("/step/{step_number}/validate", response_model=OnboardingStepValidation)
async def validate_onboarding_step(
    step_number: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Validate if a specific step is complete and get missing fields"""
    try:
        validation = onboarding_service.validate_step(db, str(current_user.id), step_number)
        return validation
        
    except ValidationError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to validate onboarding step"
        )


@router.post("/complete", response_model=OnboardingComplete)
async def complete_onboarding(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Mark onboarding as complete if requirements are met"""
    try:
        onboarding = onboarding_service.complete_onboarding(db, str(current_user.id))
        
        return OnboardingComplete(
            user_id=str(onboarding.user_id),
            completion_percentage=onboarding.get_completion_percentage(),
            completed_at=onboarding.completed_at,
            message="Onboarding completed successfully!"
        )
        
    except ValidationError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to complete onboarding"
        )


@router.get("/next-step")
async def get_next_step(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get the next incomplete step number"""
    try:
        next_step = onboarding_service.get_next_step(db, str(current_user.id))
        return {"next_step": next_step}
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get next step"
        )


@router.get("/summary")
async def get_step_summary(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get summary of all steps with completion status"""
    try:
        summary = onboarding_service.get_step_summary(db, str(current_user.id))
        return {"steps": summary}
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get step summary"
        )


@router.get("/questions")
async def get_onboarding_questions():
    """Get structured onboarding questions for frontend reference"""
    questions = {
        "step1": {
            "title": "Let Me Meet You",
            "description": "Tell us a bit about yourself to get started",
            "fields": [
                {"name": "name", "label": "What's your name?", "type": "text", "required": True},
                {"name": "birthday", "label": "When is your birthday?", "type": "date", "required": True},
                {"name": "cultural_home", "label": "What country or culture feels most like 'home' to you?", "type": "textarea", "required": True},
                {"name": "current_location", "label": "Where in the world are you right now?", "type": "text", "required": True}
            ]
        },
        "step2": {
            "title": "Tell Me More About You",
            "description": "Help us understand your current mindset and preferences",
            "fields": [
                {"name": "current_thoughts", "label": "What's been on your mind lately?", "type": "textarea", "required": True},
                {"name": "authentic_place", "label": "Where do you feel most like yourself?", "type": "textarea", "required": True},
                {"name": "something_you_like", "label": "What's something you like about yourself?", "type": "textarea", "required": True},
                {"name": "reminder_when_down", "label": "What's one thing you wish someone would remind you when you're feeling down?", "type": "textarea", "required": True}
            ]
        },
        "step3": {
            "title": "Moving from A to B",
            "description": "Let's explore your goals and aspirations",
            "fields": [
                {"name": "change_you_want", "label": "What's one thing you keep saying you'll change... but haven't yet?", "type": "textarea", "required": True},
                {"name": "feeling_to_experience", "label": "What feeling do you want to experience more this year?", "type": "textarea", "required": True},
                {"name": "person_you_want_to_be", "label": "What kind of person do you want to be one day?", "type": "textarea", "required": True}
            ]
        },
        "step4": {
            "title": "Tell Me About Your Future Self",
            "description": "Visualize your future self and dream life",
            "fields": [
                {"name": "future_self_age", "label": "How old is your Future Self in your mind?", "type": "number", "required": True, "min": 18, "max": 150},
                {"name": "dream_day", "label": "What would your dream day look like?", "type": "textarea", "required": True},
                {"name": "accomplishment_goal", "label": "One day, you want to wake up and think: 'I actually did it.' What is 'it'?", "type": "textarea", "required": True},
                {"name": "future_self_photo_url", "label": "Upload a photo if you'd like to imagine your Future Self", "type": "file", "required": False}
            ]
        },
        "step5": {
            "title": "Communication Style Preferences",
            "description": "Help us understand how you like to communicate",
            "fields": [
                {"name": "trusted_words_vibes", "label": "What are some words or vibes you always trust?", "type": "textarea", "required": True},
                {"name": "message_length_preference", "label": "Do you prefer long messages, or short and straight to the point?", "type": "select", "required": True, "options": [{"value": "long", "label": "Long, detailed messages"}, {"value": "short", "label": "Short, concise messages"}]},
                {"name": "message_frequency", "label": "How often do you like to be messaged?", "type": "select", "required": True, "options": [{"value": "daily", "label": "Daily"}, {"value": "weekly", "label": "Weekly"}, {"value": "as_needed", "label": "As needed"}]},
                {"name": "trust_factor", "label": "People trust those who are a little...", "type": "textarea", "required": True}
            ]
        },
        "step6": {
            "title": "Additional Context",
            "description": "Optional final details to help personalize your experience",
            "fields": [
                {"name": "when_feeling_lost", "label": "What do you do when you're feeling lost?", "type": "textarea", "required": False}
            ]
        }
    }
    return questions 