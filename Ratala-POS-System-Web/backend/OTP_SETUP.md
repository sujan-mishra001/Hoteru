# OTP Service Setup Guide

## Overview

The OTP (One-Time Password) service is now integrated with the FastAPI backend, replacing the previous Node.js implementation. This service handles email verification for signup and password reset functionality.

## Features

- ✅ Email-based OTP generation and verification
- ✅ Separate flows for signup and password reset
- ✅ 5-minute OTP expiration
- ✅ Beautiful HTML email templates
- ✅ Integrated with FastAPI backend
- ✅ No external dependencies (Node.js server removed)

## Configuration

### 1. Email Setup

The OTP service uses Gmail SMTP to send emails. You need to configure your email credentials in the `.env` file:

```env
# Email Configuration for OTP
EMAIL_USER=your_email@gmail.com
EMAIL_PASS=your_app_password_here
```

#### Getting Gmail App Password:

1. Go to your Google Account settings
2. Navigate to Security → 2-Step Verification (enable if not already)
3. Scroll down to "App passwords"
4. Generate a new app password for "Mail"
5. Copy the 16-character password to `EMAIL_PASS` in `.env`

### 2. Backend Setup

The OTP endpoints are automatically available when you run the FastAPI backend:

```bash
cd backend
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## API Endpoints

All OTP endpoints are under `/api/v1/otp`:

### 1. Send OTP

**POST** `/api/v1/otp/send-otp`

Request body:
```json
{
  "email": "user@example.com",
  "type": "signup"  // or "reset"
}
```

Response:
```json
{
  "success": true,
  "message": "OTP sent successfully"
}
```

### 2. Verify OTP

**POST** `/api/v1/otp/verify-otp`

Request body:
```json
{
  "email": "user@example.com",
  "code": "123456"
}
```

Response:
```json
{
  "success": true,
  "message": "OTP verified successfully"
}
```

### 3. Complete Password Reset

**POST** `/api/v1/otp/complete-password-reset`

Request body:
```json
{
  "email": "user@example.com",
  "code": "123456",
  "new_password": "newSecurePassword123"
}
```

Response:
```json
{
  "success": true,
  "message": "Password updated successfully"
}
```

### 4. Health Check

**GET** `/api/v1/otp/health`

Response:
```json
{
  "status": "healthy",
  "service": "OTP Service"
}
```

## Flutter/Mobile App Integration

The Flutter app includes an `OtpService` class to interact with these endpoints:

```dart
import 'package:dautari_adda/features/auth/data/otp_service.dart';

final otpService = OtpService();

// Send OTP
final result = await otpService.sendOtp(
  email: 'user@example.com',
  type: 'signup', // or 'reset'
);

// Verify OTP
final verifyResult = await otpService.verifyOtp(
  email: 'user@example.com',
  code: '123456',
);

// Complete password reset
final resetResult = await otpService.completePasswordReset(
  email: 'user@example.com',
  code: '123456',
  newPassword: 'newPassword123',
);
```

## Email Template

The OTP emails use a professional HTML template with:
- Company branding (Ratala POS)
- Clear OTP display
- Expiration notice (5 minutes)
- Responsive design

## Security Features

- **OTP Expiration**: All OTPs expire after 5 minutes
- **One-time Use**: OTPs are consumed after successful verification
- **User Validation**: Password reset verifies user exists before sending OTP
- **In-memory Storage**: For development (use Redis in production)

## Production Considerations

### 1. Redis for OTP Storage

For production, replace the in-memory OTP storage with Redis:

```python
# In app/services/otp_service.py
import redis

redis_client = redis.Redis(host='localhost', port=6379, db=0)

def store_otp(self, email: str, otp: str):
    redis_client.setex(f"otp:{email}", 300, otp)  # 5 minutes
```

### 2. Rate Limiting

Add rate limiting to prevent abuse:

```python
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)

@router.post("/send-otp")
@limiter.limit("5/minute")
async def send_otp(...):
    ...
```

### 3. Environment Variables

Ensure all sensitive data is in environment variables:
- `EMAIL_USER`: Gmail address
- `EMAIL_PASS`: Gmail app password
- `SECRET_KEY`: For JWT tokens
- `DATABASE_URL`: Database connection string

## Troubleshooting

### Email not sending

1. Check `EMAIL_USER` and `EMAIL_PASS` in `.env`
2. Ensure Gmail app password is correct (not regular password)
3. Check Gmail security settings
4. Verify SMTP is not blocked by firewall

### OTP not received

1. Check spam/junk folder
2. Verify email address is correct
3. Check backend logs for errors
4. Test with `/otp/health` endpoint

### OTP expired

- OTPs expire after 5 minutes
- Request a new OTP if expired

## Migration from Node.js

The old Node.js OTP server (`otp_server/` folder) has been removed. All functionality is now handled by the Python backend:

| Old (Node.js) | New (Python) |
|---------------|--------------|
| `POST http://localhost:3000/send-otp` | `POST /api/v1/otp/send-otp` |
| `POST http://localhost:3000/verify-otp` | `POST /api/v1/otp/verify-otp` |
| `POST http://localhost:3000/complete-password-reset` | `POST /api/v1/otp/complete-password-reset` |

No separate server needed - everything runs with FastAPI!

## Testing

Test the OTP service using the API documentation:

1. Start the backend: `uvicorn app.main:app --reload`
2. Open browser: `http://localhost:8000/docs`
3. Navigate to the "OTP" section
4. Test each endpoint with sample data

---

**Note**: This service is production-ready but should be enhanced with Redis for OTP storage and rate limiting for security in a live environment.
