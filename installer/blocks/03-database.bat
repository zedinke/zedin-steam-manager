@echo off
REM ############################################
REM Block 03: Database Configuration
REM ############################################

echo Configuring Supabase database...
echo.

set SUPABASE_URL=https://mgosieaxhosiwzpvcyle.supabase.co
set SUPABASE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1nb3NpZWF4aG9zaXd6cHZjeWxlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5ODc5ODcsImV4cCI6MjA3ODU2Mzk4N30.8k7qGQCitCOp-ZDu-Km5XunFUs5pBcp2khkwDxxijdY
set JWT_SECRET=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1nb3NpZWF4aG9zaXd6cHZjeWxlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2Mjk4Nzk4NywiZXhwIjoyMDc4NTYzOTg3fQ.lREOEbqmRtpPG_4c7fzbQMwIgdMNjZw9VBFEzujrvg4

REM Test Supabase connection
echo Testing Supabase connection...
curl -s -o nul -w "%%{http_code}" -H "apikey: %SUPABASE_KEY%" -H "Authorization: Bearer %SUPABASE_KEY%" "%SUPABASE_URL%/rest/v1/" > temp_response.txt
set /p HTTP_CODE=<temp_response.txt
del temp_response.txt

if "%HTTP_CODE%"=="200" (
    echo [OK] Supabase connection successful
) else (
    echo [ERROR] Unable to connect to Supabase (HTTP %HTTP_CODE%^)
    exit /b 1
)

REM Create installation directory
set INSTALL_DIR=%USERPROFILE%\zedin-steam-manager
if not exist "%INSTALL_DIR%\backend" mkdir "%INSTALL_DIR%\backend"

REM Create .env file
echo Creating environment configuration...
(
echo # Supabase Configuration
echo SUPABASE_URL=%SUPABASE_URL%
echo SUPABASE_KEY=%SUPABASE_KEY%
echo JWT_SECRET=%JWT_SECRET%
echo.
echo # Email Configuration
echo SMTP_HOST=smtp.gmail.com
echo SMTP_PORT=587
echo SMTP_USER=noreply@zedinmanager.com
echo SMTP_PASSWORD=change_me_in_production
echo.
echo # Application Configuration
echo APP_NAME=Zedin Steam Manager
echo APP_VERSION=0.0.1
echo FRONTEND_URL=http://localhost:3000
echo BACKEND_URL=http://localhost:8000
echo.
echo # Security
echo ALGORITHM=HS256
echo ACCESS_TOKEN_EXPIRE_DAYS=30
) > "%INSTALL_DIR%\backend\.env"

echo [OK] Environment file created: %INSTALL_DIR%\backend\.env
echo.
echo [WARNING] Email verification is enabled
echo Configure SMTP settings in .env before production use
echo.
echo [OK] Database configuration completed
echo.
