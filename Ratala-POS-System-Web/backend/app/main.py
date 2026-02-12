"""
Main FastAPI application
"""
# Triggering uvicorn reload...
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import os

# Force reload for route registration
from app.core.config import settings
from app.db.database import init_db, get_db
from app.core.dependencies import get_password_hash
from app.models import User as DBUser
from app.api.v1 import api_router

# Create FastAPI app
app = FastAPI(
    title=settings.API_TITLE,
    version=settings.API_VERSION,
    description="Ratala Hospitality - Restaurant Management SaaS Platform API"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=settings.CORS_ALLOW_CREDENTIALS,
    allow_methods=settings.CORS_ALLOW_METHODS,
    allow_headers=settings.CORS_ALLOW_HEADERS,
)

# Include API routes with prefix
app.include_router(api_router, prefix=settings.API_PREFIX)

# Mount static files for uploads
UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")


# Initialize database on startup
@app.on_event("startup")
def startup_event():
    """Initialize database tables"""
    try:
        init_db()
        print("✓ Database initialized successfully")
    except Exception as e:
        print(f"✗ Database initialization failed: {e}")
        print("\nPlease check:")
        print("  • PostgreSQL is running")
        print("  • DATABASE_URL in .env is correct")
        print("  • Database credentials are valid")
        raise


@app.get("/")
async def root():
    """Root endpoint - API health check"""
    try:
        # Test database connection
        from app.db.database import get_engine
        from sqlalchemy import text
        engine = get_engine()
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        db_connected = True
    except Exception:
        db_connected = False
    
    return {
        "message": f"{settings.API_TITLE} is running",
        "version": settings.API_VERSION,
        "db_connected": db_connected
    }


@app.get("/welcome/admin")
async def welcome_admin():
    """Admin welcome endpoint"""
    return {"message": "Welcome to the Admin Command Center!"}


if __name__ == "__main__":
    """
    Run the FastAPI application directly
    Usage: python -m app.main
    Or from backend directory: python -m app.main
    """
    import uvicorn
    import sys
    from pathlib import Path
    
    # Ensure we're in the backend directory
    backend_dir = Path(__file__).parent.parent.absolute()
    if str(backend_dir) not in sys.path:
        sys.path.insert(0, str(backend_dir))
    
    try:
        uvicorn.run(
            "app.main:app",
            host="0.0.0.0",
            port=8000,
            reload=True,  # Enable auto-reload in development
            reload_dirs=[str(backend_dir / "app")]  # Watch app directory for changes
        )
    except KeyboardInterrupt:
        print("\n\nServer stopped by user")
    except Exception as e:
        print(f"\nError starting server: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
