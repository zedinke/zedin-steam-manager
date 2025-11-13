@echo off
REM ############################################
REM Block 06: Configure Services
REM ############################################

echo Configuring services...
echo.

echo [INFO] Windows Service configuration
echo.
echo On Windows, you can run the application in several ways:
echo.
echo 1. Development Mode (Recommended):
echo    - Use start-dev.bat to run both backend and frontend
echo    - Automatically starts in separate windows
echo.
echo 2. Windows Services (Advanced):
echo    - Use NSSM (Non-Sucking Service Manager)
echo    - Download from: https://nssm.cc/download
echo    - Create services for backend and frontend
echo.
echo 3. IIS Integration (Production):
echo    - Install IIS with URL Rewrite module
echo    - Configure as reverse proxy
echo    - Use IISNode for Node.js apps
echo.

REM Create startup scripts
set INSTALL_DIR=%USERPROFILE%\zedin-steam-manager

echo Creating startup scripts...

REM Backend startup script
(
echo @echo off
echo cd /d "%INSTALL_DIR%\backend"
echo call venv\Scripts\activate.bat
echo python -m uvicorn main:app --host 0.0.0.0 --port 8000
) > "%INSTALL_DIR%\start-backend.bat"

REM Frontend startup script
(
echo @echo off
echo cd /d "%INSTALL_DIR%\frontend"
echo npm run dev
) > "%INSTALL_DIR%\start-frontend.bat"

REM Combined startup script
(
echo @echo off
echo echo Starting Zedin Steam Manager...
echo echo.
echo start "Backend" cmd /k "%INSTALL_DIR%\start-backend.bat"
echo timeout /t 3 /nobreak ^>nul
echo start "Frontend" cmd /k "%INSTALL_DIR%\start-frontend.bat"
echo echo.
echo echo Services started!
echo echo Backend: http://localhost:8000
echo echo Frontend: http://localhost:3000
echo pause
) > "%INSTALL_DIR%\start-all.bat"

echo [OK] Startup scripts created
echo.
echo Startup scripts location:
echo   %INSTALL_DIR%\start-backend.bat
echo   %INSTALL_DIR%\start-frontend.bat
echo   %INSTALL_DIR%\start-all.bat
echo.
echo [OK] Service configuration completed
echo.
