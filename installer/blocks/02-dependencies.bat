@echo off
REM ############################################
REM Block 02: Install Dependencies
REM ############################################

echo Installing dependencies...
echo.

REM Check Python
python --version >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Python is installed
    python --version
) else (
    echo [ERROR] Python not found
    echo Please install Python 3.9+ from https://www.python.org/downloads/
    echo Make sure to check "Add Python to PATH" during installation
    exit /b 1
)

REM Check Node.js
node --version >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Node.js is installed
    node --version
) else (
    echo [ERROR] Node.js not found
    echo Please install Node.js 18+ from https://nodejs.org/
    exit /b 1
)

REM Check npm
npm --version >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] npm is installed
    npm --version
) else (
    echo [ERROR] npm not found
    exit /b 1
)

REM Check Git
git --version >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Git is installed
    git --version
) else (
    echo [ERROR] Git not found
    echo Please install Git from https://git-scm.com/download/win
    exit /b 1
)

echo.
echo [OK] All required dependencies are installed
echo.
echo NOTE: For production deployment on Windows, consider using:
echo - IIS or Nginx for Windows as reverse proxy
echo - Windows Service wrapper for backend/frontend
echo - Or deploy to Linux server using main-installer.sh
echo.
