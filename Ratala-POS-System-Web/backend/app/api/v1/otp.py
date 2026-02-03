"""
OTP routes for email verification and password reset
"""
from fastapi import APIRouter, HTTPException, status, Depends
from pydantic import BaseModel, EmailStr
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import User
from app.services.otp_service import otp_service
from app.services.email_service import EmailService
from app.dependencies import get_password_hash

router = APIRouter()
email_service = EmailService()


class SendOTPRequest(BaseModel):
    email: EmailStr
    type: str = 'signup'  # 'signup' or 'reset'


class VerifyOTPRequest(BaseModel):
    email: EmailStr
    code: str


class CompletePasswordResetRequest(BaseModel):
    email: EmailStr
    code: str
    new_password: str


@router.post("/send-otp")
async def send_otp(request: SendOTPRequest, db: Session = Depends(get_db)):
    """
    Send OTP to email
    
    For signup: Just send OTP
    For reset: Verify user exists first
    """
    # If password reset, verify user exists
    if request.type == 'reset':
        user = db.query(User).filter(User.email == request.email).first()
        if not user:
            return {
                "success": False,
                "message": "User does not exist"
            }
    
    # Generate OTP
    otp = otp_service.generate_otp()
    
    # Store OTP
    otp_service.store_otp(request.email, otp)
    
    # Send email
    email_sent = email_service.send_otp_email(
        to_email=request.email,
        otp=otp,
        email_type=request.type
    )
    
    if email_sent:
        return {
            "success": True,
            "message": "OTP sent successfully"
        }
    else:
        # Clear OTP if email failed
        otp_service.clear_otp(request.email)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to send OTP email"
        )


@router.post("/verify-otp")
async def verify_otp(request: VerifyOTPRequest):
    """Verify OTP code"""
    success, message = otp_service.verify_otp(request.email, request.code)
    
    return {
        "success": success,
        "message": message
    }


@router.post("/complete-password-reset")
async def complete_password_reset(
    request: CompletePasswordResetRequest,
    db: Session = Depends(get_db)
):
    """Complete password reset with OTP verification"""
    
    # Verify OTP
    success, message = otp_service.verify_otp(request.email, request.code)
    if not success:
        return {
            "success": False,
            "message": message
        }
    
    # Find user
    user = db.query(User).filter(User.email == request.email).first()
    if not user:
        return {
            "success": False,
            "message": "User not found"
        }
    
    # Update password
    try:
        user.hashed_password = get_password_hash(request.new_password)
        db.commit()
        
        return {
            "success": True,
            "message": "Password updated successfully"
        }
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update password: {str(e)}"
        )


@router.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "OTP Service"
    }
