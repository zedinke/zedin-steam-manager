@echo off
REM ############################################
REM Zedin Steam Manager - Development Start
REM Version: 0.0.1-alpha
REM ############################################

echo ==============================================
echo   Zedin Steam Manager - Development Mode
echo ==============================================
echo.

set SCRIPT_DIR=%~dp0

REM Start backend
if exist "%SCRIPT_DIR%backend" (
    echo Starting backend...
    cd /d "%SCRIPT_DIR%backend"
    
    REM Activate virtual environment if exists
    if exist "venv\Scripts\activate.bat" (
        call venv\Scripts\activate.bat
    )
    
    start "Backend" cmd /k "python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000"
    echo Backend started at http://localhost:8000
) else (
    echo Backend directory not found
    pause
    exit /b 1
)

REM Start frontend
if exist "%SCRIPT_DIR%frontend" (
    echo.
    echo Starting frontend...
    cd /d "%SCRIPT_DIR%frontend"
    
    start "Frontend" cmd /k "npm run dev"
    echo Frontend started at http://localhost:3000
) else (
    echo Frontend directory not found
    pause
    exit /b 1
)

echo.
echo ==============================================
echo   Development servers running
echo   Close the windows to stop
echo ==============================================
echo.

pause
