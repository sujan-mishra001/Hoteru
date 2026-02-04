"""
Email service for sending OTP and other notifications
"""
import smtplib
import os
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime
from typing import Optional


class EmailService:
    """Service for sending emails"""
    
    def __init__(self):
        self.email_user = os.getenv('EMAIL_USER', '')
        self.email_pass = os.getenv('EMAIL_PASS', '')
        self.smtp_server = 'smtp.gmail.com'
        self.smtp_port = 587
        
    def send_otp_email(self, to_email: str, otp: str, email_type: str = 'signup') -> bool:
        """
        Send OTP email
        
        Args:
            to_email: Recipient email address
            otp: 6-digit OTP code
            email_type: Type of email - 'signup' or 'reset'
            
        Returns:
            bool: True if email sent successfully, False otherwise
        """
        try:
            # Configure subject and content based on type
            if email_type == 'reset':
                subject = 'Reset Your Password'
                title = 'Password Reset Request'
                message = 'We received a request to reset your password for your Dautari Adda account. Enter the code below to set a new password.'
                action_text = 'Reset Code'
            else:
                subject = 'Your Verification Code'
                title = 'Verify your email address'
                message = 'Thanks for starting the new account creation process. We want to make sure it\'s really you. Please enter the following verification code when prompted.'
                action_text = 'Verification Code'
            
            # Create HTML email
            html_content = self._create_email_template(title, message, otp, action_text)
            
            # Create message
            msg = MIMEMultipart('alternative')
            msg['From'] = f"Dautari Adda <{self.email_user}>"
            msg['To'] = to_email
            msg['Subject'] = subject
            
            # Attach HTML part
            html_part = MIMEText(html_content, 'html')
            msg.attach(html_part)
            
            # Send email
            with smtplib.SMTP(self.smtp_server, self.smtp_port) as server:
                server.starttls()
                server.login(self.email_user, self.email_pass)
                server.send_message(msg)
            
            print(f"OTP ({email_type}) sent to {to_email}")
            return True
            
        except Exception as e:
            print(f"Error sending email: {e}")
            return False
    
    def _create_email_template(self, title: str, message: str, otp: str, action_text: str) -> str:
        """Create HTML email template"""
        year = datetime.now().year
        
        return f"""
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>{title}</title>
        </head>
        <body style="margin: 0; padding: 0; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6;">
            <table border="0" cellpadding="0" cellspacing="0" width="100%" style="max-width: 600px; margin: 0 auto; background-color: #ffffff; margin-top: 40px; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.05);">
                <!-- Header -->
                <tr>
                    <td style="background-color: #2D3436; padding: 30px; text-align: center;">
                        <h1 style="color: #FF8C00; margin: 0; font-size: 28px; font-weight: 700; letter-spacing: 1px;">Dautari Adda</h1>
                    </td>
                </tr>
                
                <!-- Body -->
                <tr>
                    <td style="padding: 40px 30px;">
                        <h2 style="color: #2D3436; font-size: 22px; margin-top: 0; margin-bottom: 20px;">{title}</h2>
                        <p style="color: #636e72; font-size: 16px; line-height: 1.6; margin-bottom: 30px;">
                            {message}
                        </p>
                        
                        <!-- OTP Box -->
                        <div style="background-color: #f9f9f9; border-radius: 12px; padding: 20px; text-align: center; margin-bottom: 30px; border: 1px dashed #FF8C00;">
                            <span style="display: block; color: #b2bec3; font-size: 14px; margin-bottom: 10px; text-transform: uppercase; letter-spacing: 1px;">{action_text}</span>
                            <span style="font-size: 36px; font-weight: 800; color: #2D3436; letter-spacing: 8px;">{otp}</span>
                        </div>
                        
                        <p style="color: #636e72; font-size: 15px; line-height: 1.6; margin-bottom: 0;">
                            This code will expire in <strong style="color: #d63031;">5 minutes</strong>. If you didn't request this, you can safely ignore this email.
                        </p>
                    </td>
                </tr>
                
                <!-- Footer -->
                <tr>
                    <td style="background-color: #f1f2f6; padding: 20px; text-align: center;">
                        <p style="color: #b2bec3; font-size: 12px; margin: 0;">
                            &copy; {year} Dautari Adda. All rights reserved.
                        </p>
                    </td>
                </tr>
            </table>
        </body>
        </html>
        """
