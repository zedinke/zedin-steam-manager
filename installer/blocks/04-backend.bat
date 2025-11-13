@echo off
REM ############################################
REM Block 04: Backend Setup
REM ############################################

echo Setting up backend...
echo.

set INSTALL_DIR=%USERPROFILE%\zedin-steam-manager
set BACKEND_DIR=%INSTALL_DIR%\backend

REM Copy backend files from current directory
if exist "backend" (
    echo Copying backend files...
    xcopy /E /I /Y backend "%BACKEND_DIR%" >nul
    echo [OK] Backend files copied
) else (
    echo Creating backend structure...
    mkdir "%BACKEND_DIR%\routers"
    mkdir "%BACKEND_DIR%\services"
    mkdir "%BACKEND_DIR%\config"
    mkdir "%BACKEND_DIR%\models"
    mkdir "%BACKEND_DIR%\templates"
)

cd /d "%BACKEND_DIR%"

REM Create virtual environment
if not exist "venv" (
    echo Creating Python virtual environment...
    python -m venv venv
    if %errorlevel% neq 0 (
        echo [ERROR] Failed to create virtual environment
        exit /b 1
    )
    echo [OK] Virtual environment created
) else (
    echo [OK] Virtual environment already exists
)

REM Activate virtual environment
call venv\Scripts\activate.bat

REM Install dependencies
if exist "requirements.txt" (
    echo Installing Python dependencies...
    pip install --upgrade pip -q
    pip install -r requirements.txt -q
    if %errorlevel% neq 0 (
        echo [ERROR] Failed to install dependencies
        exit /b 1
    )
    echo [OK] Dependencies installed
) else (
    echo [WARNING] requirements.txt not found
    echo Installing basic dependencies...
    pip install fastapi uvicorn[standard] supabase python-jose[cryptography] -q
)

echo.
echo [OK] Backend setup completed
echo Backend location: %BACKEND_DIR%
echo.
echo To start backend manually:
echo   cd "%BACKEND_DIR%"
echo   venv\Scripts\activate
echo   python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
echo.
