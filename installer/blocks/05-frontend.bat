@echo off
REM ############################################
REM Block 05: Frontend Setup
REM ############################################

echo Setting up frontend...
echo.

set INSTALL_DIR=%USERPROFILE%\zedin-steam-manager
set FRONTEND_DIR=%INSTALL_DIR%\frontend

REM Copy frontend files
if exist "frontend" (
    echo Copying frontend files...
    xcopy /E /I /Y frontend "%FRONTEND_DIR%" >nul
    echo [OK] Frontend files copied
) else (
    echo Creating frontend structure...
    mkdir "%FRONTEND_DIR%\src\pages"
    mkdir "%FRONTEND_DIR%\src\services"
    mkdir "%FRONTEND_DIR%\src\components"
    mkdir "%FRONTEND_DIR%\public"
)

cd /d "%FRONTEND_DIR%"

REM Install dependencies
if exist "package.json" (
    echo Installing npm dependencies...
    echo This may take a few minutes...
    call npm install --silent
    if %errorlevel% neq 0 (
        echo [ERROR] Failed to install dependencies
        exit /b 1
    )
    echo [OK] Dependencies installed
) else (
    echo [WARNING] package.json not found
)

echo.
echo [OK] Frontend setup completed
echo Frontend location: %FRONTEND_DIR%
echo.
echo To start frontend manually:
echo   cd "%FRONTEND_DIR%"
echo   npm run dev
echo.
