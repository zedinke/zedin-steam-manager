@echo off
echo ======================================
echo   Zedin Steam Manager - Update
echo ======================================
echo.

REM Check if we're in a git repository
if not exist ".git" (
    echo ERROR: Not a git repository!
    echo Please run this script from the project root directory.
    pause
    exit /b 1
)

echo [1/5] Stopping services...
taskkill /F /IM python.exe /FI "WINDOWTITLE eq Backend API*" >nul 2>&1
taskkill /F /IM node.exe /FI "WINDOWTITLE eq Frontend Dev Server*" >nul 2>&1
echo Services stopped

echo.
echo [2/5] Pulling latest changes from GitHub...
git pull origin main
if %errorlevel% neq 0 (
    echo ERROR: Git pull failed!
    pause
    exit /b 1
)
echo Code updated

echo.
echo [3/5] Updating backend dependencies...
cd backend
if exist "venv\" (
    call venv\Scripts\activate.bat
    pip install --upgrade pip -q
    pip install -r requirements.txt -q
    call venv\Scripts\deactivate.bat
    echo Backend dependencies updated
) else (
    echo Virtual environment not found, skipping backend update
)
cd ..

echo.
echo [4/5] Updating frontend dependencies...
cd frontend
if exist "package.json" (
    call npm install
    if %errorlevel% neq 0 (
        echo ERROR: Frontend update failed!
        pause
        exit /b 1
    )
    echo Frontend dependencies updated
)
cd ..

echo.
echo [5/5] Checking database migrations...
cd backend
if exist "init_db.py" (
    call venv\Scripts\activate.bat
    python init_db.py
    call venv\Scripts\deactivate.bat
    echo Database checked
)
cd ..

echo.
echo ======================================
echo Update completed successfully!
echo ======================================
echo.
echo To start the application, run:
echo   start-dev.bat
echo.
pause
