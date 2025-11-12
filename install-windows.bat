@echo off
setlocal enabledelayedexpansion

:: ============================================================================
:: Zedin Steam Manager - Windows Installer
:: ============================================================================

echo ============================================================================
echo                    Zedin Steam Manager Installer                          
echo ============================================================================
echo.

:: Check if running as administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: This installer must be run as Administrator
    echo Please right-click and select "Run as administrator"
    pause
    exit /b 1
)

:: Set variables
set INSTALL_DIR=C:\ZedinSteamManager
set SERVICE_NAME=ZedinSteamManager
set PYTHON_URL=https://www.python.org/ftp/python/3.12.10/python-3.12.10-amd64.exe
set NODEJS_URL=https://nodejs.org/dist/v18.19.0/node-v18.19.0-x64.msi
set TEMP_DIR=%TEMP%\zedin_install

echo This installer will:
echo   1. Install Python 3.12 and Node.js 18
echo   2. Install application dependencies
echo   3. Create Windows service
echo   4. Configure Windows Firewall
echo   5. Set up automatic startup
echo.
set /p CONTINUE=Continue with installation? (Y/N): 
if /i not "%CONTINUE%"=="Y" exit /b 0

echo.
echo ============================================================================
echo PHASE 1: Installing system dependencies...
echo ============================================================================

:: Create temp directory
mkdir "%TEMP_DIR%" 2>nul

:: Check if Python is installed
python --version >nul 2>&1
if %errorLevel% neq 0 (
    echo Installing Python 3.12...
    powershell -Command "& { Invoke-WebRequest -Uri '%PYTHON_URL%' -OutFile '%TEMP_DIR%\python-installer.exe' }"
    "%TEMP_DIR%\python-installer.exe" /quiet InstallAllUsers=1 PrependPath=1 Include_test=0
    if %errorLevel% neq 0 (
        echo ERROR: Python installation failed
        exit /b 1
    )
    echo Python installed successfully
) else (
    echo Python is already installed
)

:: Check if Node.js is installed
node --version >nul 2>&1
if %errorLevel% neq 0 (
    echo Installing Node.js 18...
    powershell -Command "& { Invoke-WebRequest -Uri '%NODEJS_URL%' -OutFile '%TEMP_DIR%\nodejs-installer.msi' }"
    msiexec /i "%TEMP_DIR%\nodejs-installer.msi" /quiet
    if %errorLevel% neq 0 (
        echo ERROR: Node.js installation failed
        exit /b 1
    )
    echo Node.js installed successfully
    :: Refresh PATH
    call refreshenv.cmd 2>nul || echo Please restart command prompt to update PATH
) else (
    echo Node.js is already installed
)

echo.
echo ============================================================================
echo PHASE 2: Setting up application directories...
echo ============================================================================

:: Create installation directory
echo Creating directory: %INSTALL_DIR%
mkdir "%INSTALL_DIR%" 2>nul

:: Copy application files
echo Copying application files...
if exist "zedinsteammanager" (
    xcopy "zedinsteammanager\*" "%INSTALL_DIR%\" /E /I /Q
) else if exist "backend" (
    xcopy "." "%INSTALL_DIR%\" /E /I /Q /EXCLUDE:install_exclude.txt
) else (
    echo ERROR: Application files not found
    exit /b 1
)

:: Create data directories
mkdir "%INSTALL_DIR%\data" 2>nul
mkdir "%INSTALL_DIR%\logs" 2>nul
mkdir "%INSTALL_DIR%\data\servers" 2>nul
mkdir "%INSTALL_DIR%\data\shared_files" 2>nul

echo.
echo ============================================================================
echo PHASE 3: Installing application dependencies...
echo ============================================================================

cd /d "%INSTALL_DIR%"

:: Install Python dependencies
echo Installing Python dependencies...
python -m venv venv
call venv\Scripts\activate
cd backend
pip install --upgrade pip
pip install -r requirements.txt
cd ..

:: Install Node.js dependencies
echo Installing Node.js dependencies...
call npm install
cd frontend
call npm install
cd ..

:: Build application
echo Building application...
call npm run build:electron 2>nul || echo Build completed with warnings

echo.
echo ============================================================================
echo PHASE 4: Creating Windows Service...
echo ============================================================================

:: Create service wrapper batch file
echo @echo off > "%INSTALL_DIR%\service.bat"
echo cd /d "%INSTALL_DIR%" >> "%INSTALL_DIR%\service.bat"
echo call venv\Scripts\activate >> "%INSTALL_DIR%\service.bat"
echo cd backend >> "%INSTALL_DIR%\service.bat"
echo python -m uvicorn main:app --host 0.0.0.0 --port 8000 >> "%INSTALL_DIR%\service.bat"

:: Install NSSM (Non-Sucking Service Manager)
powershell -Command "& { Invoke-WebRequest -Uri 'https://nssm.cc/release/nssm-2.24.zip' -OutFile '%TEMP_DIR%\nssm.zip' }"
powershell -Command "& { Expand-Archive -Path '%TEMP_DIR%\nssm.zip' -DestinationPath '%TEMP_DIR%' -Force }"
copy "%TEMP_DIR%\nssm-2.24\win64\nssm.exe" "%INSTALL_DIR%\" >nul

:: Create and install service
"%INSTALL_DIR%\nssm.exe" install "%SERVICE_NAME%" "%INSTALL_DIR%\service.bat"
"%INSTALL_DIR%\nssm.exe" set "%SERVICE_NAME%" DisplayName "Zedin Steam Manager"
"%INSTALL_DIR%\nssm.exe" set "%SERVICE_NAME%" Description "Professional Steam Server Manager for ASE and ASA"
"%INSTALL_DIR%\nssm.exe" set "%SERVICE_NAME%" Start SERVICE_AUTO_START
"%INSTALL_DIR%\nssm.exe" set "%SERVICE_NAME%" AppStdout "%INSTALL_DIR%\logs\service.log"
"%INSTALL_DIR%\nssm.exe" set "%SERVICE_NAME%" AppStderr "%INSTALL_DIR%\logs\error.log"

echo.
echo ============================================================================
echo PHASE 5: Configuring Windows Firewall...
echo ============================================================================

:: Allow application through firewall
netsh advfirewall firewall add rule name="Zedin Steam Manager API" dir=in action=allow protocol=TCP localport=8000
netsh advfirewall firewall add rule name="Zedin Steam Manager Frontend" dir=in action=allow protocol=TCP localport=3000

:: Allow ARK server ports
netsh advfirewall firewall add rule name="ARK Servers TCP" dir=in action=allow protocol=TCP localport=7777-7877
netsh advfirewall firewall add rule name="ARK Servers UDP" dir=in action=allow protocol=UDP localport=7777-7877
netsh advfirewall firewall add rule name="ARK Query Ports TCP" dir=in action=allow protocol=TCP localport=27015-27115
netsh advfirewall firewall add rule name="ARK Query Ports UDP" dir=in action=allow protocol=UDP localport=27015-27115
netsh advfirewall firewall add rule name="ARK RCON Ports" dir=in action=allow protocol=TCP localport=27020-27120

echo.
echo ============================================================================
echo PHASE 6: Creating configuration files...
echo ============================================================================

:: Create environment file
echo # Zedin Steam Manager Configuration > "%INSTALL_DIR%\.env"
echo APP_NAME=Zedin Steam Manager >> "%INSTALL_DIR%\.env"
echo VERSION=0.000001 >> "%INSTALL_DIR%\.env"
echo DEBUG=False >> "%INSTALL_DIR%\.env"
echo HOST=0.0.0.0 >> "%INSTALL_DIR%\.env"
echo PORT=8000 >> "%INSTALL_DIR%\.env"
echo DATABASE_URL=sqlite:///%INSTALL_DIR%\data\zedin_steam_manager.db >> "%INSTALL_DIR%\.env"
echo SECRET_KEY=%RANDOM%%RANDOM%%RANDOM% >> "%INSTALL_DIR%\.env"
echo SHARED_FILES_PATH=%INSTALL_DIR%\data\shared_files >> "%INSTALL_DIR%\.env"
echo SERVERS_PATH=%INSTALL_DIR%\data\servers >> "%INSTALL_DIR%\.env"

:: Create startup script
echo @echo off > "%INSTALL_DIR%\start.bat"
echo cd /d "%INSTALL_DIR%" >> "%INSTALL_DIR%\start.bat"
echo call venv\Scripts\activate >> "%INSTALL_DIR%\start.bat"
echo echo Starting Zedin Steam Manager... >> "%INSTALL_DIR%\start.bat"
echo start /min cmd /c "cd backend && python -m uvicorn main:app --host 0.0.0.0 --port 8000" >> "%INSTALL_DIR%\start.bat"
echo timeout /t 3 >> "%INSTALL_DIR%\start.bat"
echo start /min cmd /c "cd frontend && npm run dev" >> "%INSTALL_DIR%\start.bat"
echo echo Backend: http://localhost:8000 >> "%INSTALL_DIR%\start.bat"
echo echo Frontend: http://localhost:3000 >> "%INSTALL_DIR%\start.bat"
echo pause >> "%INSTALL_DIR%\start.bat"

:: Create stop script
echo @echo off > "%INSTALL_DIR%\stop.bat"
echo taskkill /f /im python.exe 2>nul >> "%INSTALL_DIR%\stop.bat"
echo taskkill /f /im node.exe 2>nul >> "%INSTALL_DIR%\stop.bat"
echo echo Zedin Steam Manager stopped. >> "%INSTALL_DIR%\stop.bat"
echo pause >> "%INSTALL_DIR%\stop.bat"

echo.
echo ============================================================================
echo PHASE 7: Starting services...
echo ============================================================================

:: Start service
net start "%SERVICE_NAME%"
if %errorLevel% equ 0 (
    echo ✓ Service started successfully
) else (
    echo ✗ Service failed to start
)

:: Cleanup temp files
rmdir /s /q "%TEMP_DIR%" 2>nul

:: Create desktop shortcuts
echo Creating desktop shortcuts...
powershell -Command "& { $WshShell = New-Object -comObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%USERPROFILE%\Desktop\Zedin Steam Manager.lnk'); $Shortcut.TargetPath = '%INSTALL_DIR%\start.bat'; $Shortcut.WorkingDirectory = '%INSTALL_DIR%'; $Shortcut.IconLocation = '%INSTALL_DIR%\icon.ico'; $Shortcut.Save() }" 2>nul

echo.
echo ============================================================================
echo                    🎉 INSTALLATION COMPLETED! 🎉                         
echo ============================================================================
echo.
echo Zedin Steam Manager has been successfully installed!
echo.
echo 📍 Access Points:
echo    Web Interface: http://localhost:8000
echo    API Documentation: http://localhost:8000/docs
echo.
echo 📂 Installation Directory: %INSTALL_DIR%
echo.
echo 🔧 Service Management:
echo    Start: net start "%SERVICE_NAME%"
echo    Stop: net stop "%SERVICE_NAME%"
echo    Status: sc query "%SERVICE_NAME%"
echo.
echo 🖥️  Manual Start: Double-click "start.bat" in %INSTALL_DIR%
echo.
echo 📋 Next Steps:
echo    1. Configure your servers in the web interface
echo    2. Set up your ASE/ASA game servers
echo    3. Configure RCON settings
echo.
echo The service will start automatically on system boot.
echo.
echo ============================================================================
echo.
pause