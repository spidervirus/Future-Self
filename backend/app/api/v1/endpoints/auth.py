from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database.connection import get_db
from app.services.auth_service import AuthService
from app.schemas.auth import (
    UserCreate,
    UserLogin,
    UserResponse,
    AuthResponse,
    TokenRefresh,
    TokenResponse,
    PasswordReset,
    PasswordResetConfirm,
    PasswordChange
)
from app.core.auth import get_current_user, get_current_active_user
from app.models.auth import User
from app.core.exceptions import AuthenticationError, ValidationError


router = APIRouter()
auth_service = AuthService()


@router.post("/register", response_model=AuthResponse, status_code=status.HTTP_201_CREATED)
async def register(
    user_create: UserCreate,
    db: Session = Depends(get_db)
):
    """Register a new user"""
    try:
        # Create user
        user = auth_service.create_user(db, user_create)
        
        # Create tokens
        user_login = UserLogin(email=user.email, password=user_create.password)
        auth_data = auth_service.login_user(db, user_login)
        
        return AuthResponse(
            user=UserResponse.model_validate(auth_data["user"]),
            token=auth_data["token"],
            message="User registered successfully"
        )
        
    except ValidationError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        # Log the actual error for debugging
        import traceback
        print(f"Registration error: {e}")
        print(f"Traceback: {traceback.format_exc()}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Registration failed: {str(e)}"
        )


@router.post("/login", response_model=AuthResponse)
async def login(
    user_login: UserLogin,
    db: Session = Depends(get_db)
):
    """Login user"""
    try:
        auth_data = auth_service.login_user(db, user_login)
        
        return AuthResponse(
            user=UserResponse.model_validate(auth_data["user"]),
            token=auth_data["token"],
            message="Login successful"
        )
        
    except AuthenticationError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e)
        )
    except Exception as e:
        # Log the actual error for debugging
        import traceback
        print(f"Login error: {e}")
        print(f"Traceback: {traceback.format_exc()}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Login failed: {str(e)}"
        )


@router.post("/logout")
async def logout(
    token_refresh: TokenRefresh,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Logout user by revoking refresh token"""
    try:
        auth_service.revoke_refresh_token(db, token_refresh.refresh_token)
        return {"message": "Logout successful"}
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Logout failed"
        )


@router.post("/refresh", response_model=TokenResponse)
async def refresh_token(
    token_refresh: TokenRefresh,
    db: Session = Depends(get_db)
):
    """Refresh JWT token"""
    try:
        token_data = auth_service.refresh_access_token(db, token_refresh.refresh_token)
        
        return TokenResponse(
            access_token=token_data["access_token"],
            token_type=token_data["token_type"],
            expires_in=token_data["expires_in"]
        )
        
    except AuthenticationError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Token refresh failed"
        )


@router.get("/me", response_model=UserResponse)
async def get_current_user_profile(
    current_user: User = Depends(get_current_active_user)
):
    """Get current user profile"""
    return UserResponse.model_validate(current_user)


@router.post("/password-reset")
async def request_password_reset(
    password_reset: PasswordReset,
    db: Session = Depends(get_db)
):
    """Request password reset"""
    try:
        token = auth_service.generate_password_reset_token(db, password_reset.email)
        
        if token:
            # In production, send email with reset link
            # For now, just return success message
            return {"message": "Password reset email sent"}
        else:
            # Don't reveal if email exists or not
            return {"message": "Password reset email sent"}
            
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Password reset request failed"
        )


# Add alias for frontend compatibility
@router.post("/forgot-password")
async def forgot_password_alias(
    password_reset: PasswordReset,
    db: Session = Depends(get_db)
):
    """Request password reset (alias for frontend compatibility)"""
    return await request_password_reset(password_reset, db)


@router.post("/password-reset-confirm")
async def confirm_password_reset(
    password_reset_confirm: PasswordResetConfirm,
    db: Session = Depends(get_db)
):
    """Confirm password reset"""
    try:
        user = auth_service.reset_password(
            db,
            password_reset_confirm.token,
            password_reset_confirm.new_password
        )
        
        if user:
            return {"message": "Password reset successful"}
        else:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid or expired reset token"
            )
            
    except AuthenticationError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Password reset failed"
        )


@router.post("/change-password")
async def change_password(
    password_change: PasswordChange,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Change user password"""
    try:
        success = auth_service.change_password(
            db,
            str(current_user.id),
            password_change.current_password,
            password_change.new_password
        )
        
        if success:
            return {"message": "Password changed successfully"}
        else:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Current password is incorrect"
            )
            
    except AuthenticationError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Password change failed"
        )


@router.post("/verify-email/{token}")
async def verify_email(
    token: str,
    db: Session = Depends(get_db)
):
    """Verify user email"""
    try:
        user = auth_service.verify_user_email(db, token)
        
        if user:
            return {"message": "Email verified successfully"}
        else:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid or expired verification token"
            )
            
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Email verification failed"
        ) 