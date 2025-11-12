@echo off
echo ============================================================================
echo                    Zedin Steam Manager - Windows Test
echo ============================================================================
echo.

echo Current directory: %CD%
echo.

echo === Checking for project files ===
if exist "backend" (
    echo [OK] backend directory found
    dir backend | findstr /C:"main.py" >nul && echo   - main.py found || echo   - main.py missing
    dir backend | findstr /C:"requirements.txt" >nul && echo   - requirements.txt found || echo   - requirements.txt missing
) else (
    echo [ERROR] backend directory not found
)

if exist "frontend" (
    echo [OK] frontend directory found
    dir frontend | findstr /C:"package.json" >nul && echo   - package.json found || echo   - package.json missing
    dir frontend | findstr /C:"src" >nul && echo   - src directory found || echo   - src directory missing
) else (
    echo [ERROR] frontend directory not found
)

if exist "electron" (
    echo [OK] electron directory found
) else (
    echo [WARN] electron directory not found
)

echo.
echo === Checking dependencies ===
python --version 2>nul && echo [OK] Python found || echo [ERROR] Python not found
node --version 2>nul && echo [OK] Node.js found || echo [ERROR] Node.js not found
npm --version 2>nul && echo [OK] npm found || echo [ERROR] npm not found

echo.
echo === Simulating installation steps ===

if exist "backend\requirements.txt" (
    echo [STEP 1] Would install Python dependencies from backend\requirements.txt
    echo   pip install -r backend\requirements.txt
) else (
    echo [ERROR] requirements.txt not found
)

if exist "frontend\package.json" (
    echo [STEP 2] Would install Node.js dependencies from frontend\package.json
    echo   cd frontend ^&^& npm install ^&^& npm run build
) else (
    echo [ERROR] frontend package.json not found
)

if exist "package.json" (
    echo [STEP 3] Would install root dependencies
    echo   npm install
) else (
    echo [WARN] Root package.json not found
)

echo.
echo === Test backend startup ===
if exist "backend\main.py" (
    echo [TEST] Attempting to start backend...
    cd backend
    python -c "import sys; print('Python path:', sys.executable)"
    python -c "
try:
    from fastapi import FastAPI
    print('[OK] FastAPI importable')
except ImportError:
    print('[ERROR] FastAPI not installed')

try:
    import uvicorn
    print('[OK] Uvicorn importable')
except ImportError:
    print('[ERROR] Uvicorn not installed')

try:
    import sqlalchemy
    print('[OK] SQLAlchemy importable')
except ImportError:
    print('[ERROR] SQLAlchemy not installed')
    
print('[INFO] Would start with: uvicorn main:app --host 0.0.0.0 --port 8000')
"
    cd ..
) else (
    echo [ERROR] backend\main.py not found
)

echo.
echo === Summary ===
echo Installation would create:
echo   - Backend service on port 8000
echo   - Frontend build in frontend\dist
echo   - Database at data\zedin_steam_manager.db
echo   - Logs in logs\ directory

echo.
echo To actually install on Linux, run: sudo ./install-simple.sh
echo ============================================================================
pause