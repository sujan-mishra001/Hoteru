@echo off
chcp 65001 >nul
echo ==========================================
echo 🚀 Starting Hoteru Backend Server
echo ==========================================
echo.
echo This will start the backend 8000
 on portecho Make sure to keep this window open!
echo.
echo Make sure Python is installed first.
echo.

cd /d "%~dp0backend"

echo [1/4] Checking Python installation...
python --version
if errorlevel 1 (
    echo ❌ Python not found! Please install Python 3.8+
    echo Download from: https://python.org/downloads
    pause
    exit /b 1
)
echo ✅ Python found

echo.
echo [2/4] Installing dependencies (if needed)...
pip install -r requirements.txt -q
if errorlevel 1 (
    echo ⚠️  Warning: Some dependencies might not have installed correctly
)

echo.
echo [3/4] Starting backend server...
echo.
echo 🌐 Server will be available at:
echo    http://localhost:8000
echo    http://127.0.0.1:8000
echo.
echo 📚 API Documentation at:
echo    http://localhost:8000/docs
echo.
echo ⚠️  IMPORTANT: Keep this window open!
echo    Press Ctrl+C to stop the server
echo.
echo ==========================================
echo.

uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

echo.
echo ==========================================
echo 🛑 Server stopped
echo ==========================================
pause
