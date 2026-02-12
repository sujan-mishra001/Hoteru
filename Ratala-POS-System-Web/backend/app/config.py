"""
Application configuration settings
"""
import os
from dotenv import load_dotenv

load_dotenv()


class Settings:
    """Application settings loaded from environment variables"""
    
    # API Settings
    API_TITLE: str = "Ratala Hospitality API"
    API_VERSION: str = "1.0.0"
    API_PREFIX: str = "/api/v1"
    
    # Security Settings
    SECRET_KEY: str = os.getenv("SECRET_KEY", "supersecretkey-change-in-production")
    ALGORITHM: str = os.getenv("ALGORITHM", "HS256")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "1440"))
    
    # Database Settings
    DATABASE_URL: str = os.getenv(
        "DATABASE_URL", 
        "postgresql://postgres:password@localhost:5432/ratala_hospitality"
    )
    
    # CORS Settings
    CORS_ORIGINS: list = ["*"]  # In production, specify exact origins
    CORS_ALLOW_CREDENTIALS: bool = True
    CORS_ALLOW_METHODS: list = ["*"]
    CORS_ALLOW_HEADERS: list = ["*"]
    
    # No default admin - users must signup
    DEFAULT_COMPANY_NAME: str = "Ratala Hospitality"


settings = Settings()
