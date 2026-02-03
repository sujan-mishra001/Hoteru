"""
OTP service for generating and verifying OTPs
"""
import random
from datetime import datetime, timedelta
from typing import Dict, Optional


class OTPService:
    """Service for managing OTP generation and verification"""
    
    def __init__(self):
        # In-memory store for OTPs (For production, use Redis or a Database)
        self.otp_store: Dict[str, Dict] = {}
    
    def generate_otp(self) -> str:
        """Generate a 6-digit OTP"""
        return str(random.randint(100000, 999999))
    
    def store_otp(self, email: str, otp: str, expires_minutes: int = 5) -> None:
        """
        Store OTP with expiry time
        
        Args:
            email: User email address
            otp: OTP code to store
            expires_minutes: Minutes until OTP expires (default: 5)
        """
        expiry_time = datetime.now() + timedelta(minutes=expires_minutes)
        self.otp_store[email] = {
            'code': otp,
            'expires': expiry_time
        }
    
    def verify_otp(self, email: str, code: str) -> tuple[bool, str]:
        """
        Verify OTP code
        
        Args:
            email: User email address
            code: OTP code to verify
            
        Returns:
            tuple: (success: bool, message: str)
        """
        if email not in self.otp_store:
            return False, 'No OTP found for this email'
        
        record = self.otp_store[email]
        
        # Check if expired
        if datetime.now() > record['expires']:
            del self.otp_store[email]
            return False, 'OTP expired'
        
        # Verify code
        if record['code'] == code:
            del self.otp_store[email]  # Consume OTP
            return True, 'OTP verified successfully'
        else:
            return False, 'Invalid OTP'
    
    def clear_otp(self, email: str) -> None:
        """Clear OTP for an email address"""
        if email in self.otp_store:
            del self.otp_store[email]
    
    def has_valid_otp(self, email: str) -> bool:
        """Check if email has a valid (non-expired) OTP"""
        if email not in self.otp_store:
            return False
        
        record = self.otp_store[email]
        return datetime.now() <= record['expires']


# Global OTP service instance
otp_service = OTPService()
