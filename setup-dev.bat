@echo off
REM ############################################
REM Zedin Steam Manager - Development Setup
REM Quick setup for development environment
REM ############################################

echo ==============================================
echo   Zedin Steam Manager - Development Setup
echo ==============================================
echo.

echo This will set up the development environment.
echo.
echo IMPORTANT:
echo - For Windows: This sets up LOCAL development
echo - For Production: Deploy to Linux server using:
echo   ./installer/main-installer.sh
echo.
pause

REM Check Python
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Python not found
    echo Please install Python 3.9+ from https://www.python.org/downloads/
    pause
    exit /b 1
)
echo [OK] Python found

REM Check Node.js
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Node.js not found
    echo Please install Node.js 18+ from https://nodejs.org/
    pause
    exit /b 1
)
echo [OK] Node.js found

REM Check Git
git --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Git not found
    echo Please install Git from https://git-scm.com/download/win
    pause
    exit /b 1
)
echo [OK] Git found

echo.
echo ==============================================
echo   Ready for development
echo ==============================================
echo.
echo Next steps:
echo.
echo 1. Backend files will be created by installer blocks
echo 2. Frontend files will be created by installer blocks
echo 3. Use start-dev.bat to run development servers
echo.
echo OR run the full installer:
echo   installer\main-installer.bat
echo.
pause
