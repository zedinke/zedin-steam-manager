@echo off
REM ############################################
REM Block 07: Web Server Configuration
REM ############################################

echo Configuring web server...
echo.

echo [INFO] Web Server Setup for Windows
echo.
echo For development, no web server configuration is needed.
echo Access the application at:
echo   - Frontend: http://localhost:3000
echo   - Backend:  http://localhost:8000
echo.
echo For production deployment on Windows:
echo.
echo Option 1: Nginx for Windows
echo   - Download from: http://nginx.org/en/download.html
echo   - Configure as reverse proxy
echo   - Use nginx.conf for port 80 routing
echo.
echo Option 2: IIS (Internet Information Services)
echo   - Enable IIS in Windows Features
echo   - Install URL Rewrite module
echo   - Install Application Request Routing (ARR)
echo   - Configure reverse proxy rules
echo.
echo Option 3: Deploy to Linux Server
echo   - Use the main-installer.sh script
echo   - Full production setup with systemd + nginx
echo   - Recommended for production use
echo.
echo [INFO] For this installation, use start-all.bat to run in development mode
echo.
echo [OK] Configuration information displayed
echo.
