"""
Application configuration settings
"""
import os
from dotenv import load_dotenv

load_dotenv()


class Settings:
    """Application settings loaded from environment variables"""
    
    # API Settings
    API_TITLE: str = os.getenv("API_TITLE", "Ratala Hospitality API")
    API_VERSION: str = "1.0.0"
    API_PREFIX: str = "/api/v1"
    
    # Security Settings
    SECRET_KEY: str = os.getenv("SECRET_KEY", "supersecretkey-change-in-production")
    ALGORITHM: str = os.getenv("ALGORITHM", "HS256")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "1440")) # Default to 24 hours
    
    # Database Settings
    _db_url = os.getenv("DATABASE_URL", "postgresql://postgres:password@localhost:5432/ratala_hospitality")
    if _db_url.startswith("postgres://"):
        _db_url = _db_url.replace("postgres://", "postgresql://", 1)
    DATABASE_URL: str = _db_url
    
    # Deployment Environment
    ENVIRONMENT: str = os.getenv("ENVIRONMENT", "development")
    FRONTEND_URL: str = os.getenv("FRONTEND_URL", "http://localhost:5173")

    # CORS Settings
    _cors_origins = os.getenv("CORS_ORIGINS", "")
    _origins_list = [origin.strip() for origin in _cors_origins.split(",") if origin.strip()]
    
    # If credentials are allowed, we CANNOT use ["*"]
    # We must provide an explicit list of origins
    if not _origins_list or "*" in _origins_list:
        # Default fallback origins if none provided or if "*" was used (which is incompatible with credentials)
        _origins_list = [
            "http://localhost:5173",
            "http://localhost:3000",
            FRONTEND_URL
        ]
        # Remove duplicates
        _origins_list = list(set(_origins_list))
    
    CORS_ORIGINS: list = _origins_list
    
    CORS_ALLOW_CREDENTIALS: bool = True
    CORS_ALLOW_METHODS: list = ["*"]
    CORS_ALLOW_HEADERS: list = ["*"]
    
    # Defaults
    DEFAULT_COMPANY_NAME: str = "Ratala Hospitality"


settings = Settings()
