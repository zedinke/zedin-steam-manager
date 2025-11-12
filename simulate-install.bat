@echo off
chcp 65001 >nul
cls

echo ============================================================================
echo   ███████╗███████╗██████╗ ██╗███╗   ██╗    ███████╗███╗   ███╗
echo   ╚══███╔╝██╔════╝██╔══██╗██║████╗  ██║    ██╔════╝████╗ ████║
echo     ███╔╝ █████╗  ██║  ██║██║██╔██╗ ██║    ███████╗██╔████╔██║
echo    ███╔╝  ██╔══╝  ██║  ██║██║██║╚██╗██║    ╚════██║██║╚██╔╝██║
echo   ███████╗███████╗██████╔╝██║██║ ╚████║    ███████║██║ ╚═╝ ██║
echo   ╚══════╝╚══════╝╚═════╝ ╚═╝╚═╝  ╚═══╝    ╚══════╝╚═╝     ╚═╝
echo.
echo                     🎮 STEAM SERVER MANAGER 🎮
echo                        Windows Telepítő Szimulátor
echo ============================================================================
echo.
echo 💡 Ez egy Windows-os szimuláció a Linux telepítőhöz!
echo.

set /p "continue=Folytatod a szimulációt? (y/N): "
if /i not "%continue%"=="y" (
    echo Szimuláció megszakítva.
    pause
    exit /b
)

echo.
echo [%date% %time%] 🚀 Zedin Steam Manager Windows szimuláció indítása...

REM Könyvtárak létrehozása
set "INSTALL_DIR=%~dp0simulated_linux"
set "LOG_DIR=%INSTALL_DIR%\logs"
set "DATA_DIR=%INSTALL_DIR%\data"

echo [%date% %time%] 📁 Könyvtárak létrehozása...
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
if not exist "%DATA_DIR%" mkdir "%DATA_DIR%"
if not exist "%INSTALL_DIR%\backend" mkdir "%INSTALL_DIR%\backend"
if not exist "%INSTALL_DIR%\frontend" mkdir "%INSTALL_DIR%\frontend"
if not exist "%INSTALL_DIR%\config" mkdir "%INSTALL_DIR%\config"
if not exist "%INSTALL_DIR%\steamcmd" mkdir "%INSTALL_DIR%\steamcmd"

REM Fájlok másolása
echo [%date% %time%] 📋 Alkalmazás fájlok másolása...
if exist "backend" (
    echo Copying backend files...
    xcopy /E /I /Y "backend\*" "%INSTALL_DIR%\backend\" >nul
)
if exist "frontend" (
    echo Copying frontend files...  
    xcopy /E /I /Y "frontend\*" "%INSTALL_DIR%\frontend\" >nul
)

REM Függőségek ellenőrzése  
echo [%date% %time%] 🔍 Függőségek ellenőrzése...
node --version >nul 2>&1
if %errorlevel%==0 (
    for /f "tokens=*" %%i in ('node --version 2^>nul') do echo ✓ Node.js telepítve: %%i
) else (
    echo ⚠ Node.js nincs telepítve
)

python --version >nul 2>&1
if %errorlevel%==0 (
    for /f "tokens=*" %%i in ('python --version 2^>nul') do echo ✓ Python telepítve: %%i
) else (
    echo ⚠ Python nincs telepítve
)

git --version >nul 2>&1
if %errorlevel%==0 (
    for /f "tokens=*" %%i in ('git --version 2^>nul') do echo ✓ Git telepítve: %%i
) else (
    echo ⚠ Git nincs telepítve
)

REM Backend konfiguráció
echo [%date% %time%] ⚙ Backend konfiguráció létrehozása...
(
echo # Zedin Steam Manager Konfiguráció ^(Windows Szimuláció^)
echo HOST=0.0.0.0
echo PORT=8000
echo DATABASE_URL=sqlite:///%DATA_DIR:\=/%/zedin_steam_manager.db
echo SECRET_KEY=simulated_secret_key_123456
echo ALGORITHM=HS256
echo ACCESS_TOKEN_EXPIRE_MINUTES=1440
echo STEAMCMD_PATH=%INSTALL_DIR:\=/%/steamcmd
echo SHARED_FILES_PATH=%DATA_DIR:\=/%/shared_files
echo SERVERS_PATH=%DATA_DIR:\=/%/servers
echo LOG_FILE=%LOG_DIR:\=/%/steam_manager.log
echo ASE_APP_ID=376030
echo ASA_APP_ID=2430930
echo GITHUB_REPO=zedinke/zedin-steam-manager
echo UPDATE_CHECK_INTERVAL=3600
echo SYSTEM_MONITOR_INTERVAL=5
) > "%INSTALL_DIR%\config\zsmanager.env"

REM Frontend build szimuláció
echo [%date% %time%] 🌐 Frontend build szimulálása...
if not exist "%INSTALL_DIR%\frontend\dist" mkdir "%INSTALL_DIR%\frontend\dist"

REM Demo HTML létrehozása
(
echo ^<!DOCTYPE html^>
echo ^<html lang="hu"^>
echo ^<head^>
echo ^<meta charset="UTF-8"^>
echo ^<meta name="viewport" content="width=device-width, initial-scale=1.0"^>
echo ^<title^>Zedin Steam Manager - Windows Szimuláció^</title^>
echo ^<style^>
echo body { font-family: 'Segoe UI', sans-serif; background: linear-gradient^(135deg, #1a1a1a 0%%, #2d2d30 100%%^); color: white; margin: 0; padding: 20px; min-height: 100vh; }
echo .container { max-width: 1200px; margin: 0 auto; }
echo .header { text-align: center; margin-bottom: 40px; padding: 20px; background: rgba^(255,255,255,0.1^); border-radius: 12px; }
echo .card { background: rgba^(45, 45, 45, 0.8^); padding: 25px; border-radius: 12px; margin: 20px 0; border: 1px solid rgba^(255,255,255,0.1^); }
echo .success { color: #4CAF50; }
echo .warning { color: #FF9800; }
echo .info { color: #2196F3; }
echo code { background: rgba^(0,0,0,0.5^); padding: 2px 6px; border-radius: 4px; font-family: 'Courier New', monospace; }
echo pre { background: rgba^(0,0,0,0.7^); padding: 15px; border-radius: 8px; overflow-x: auto; }
echo ^</style^>
echo ^</head^>
echo ^<body^>
echo ^<div class="container"^>
echo ^<div class="header"^>
echo ^<h1^>🎮 Zedin Steam Manager^</h1^>
echo ^<h2^>Windows Telepítő Szimuláció^</h2^>
echo ^<p class="info"^>Verzió: 0.000001 ^| Build: %date% %time%^</p^>
echo ^</div^>
echo ^<div class="card"^>
echo ^<h3 class="success"^>✅ Szimuláció Sikeresen Befejezve!^</h3^>
echo ^<p^>A Zedin Steam Manager telepítési folyamata Windows környezetben szimulálva lett.^</p^>
echo ^</div^>
echo ^<div class="card"^>
echo ^<h3^>🚀 Implementált Funkciók^</h3^>
echo ^<ul^>
echo ^<li^>✅ Backend API ^(FastAPI, SQLAlchemy, Uvicorn^)^</li^>
echo ^<li^>✅ React Frontend ^(TypeScript, Material-UI^)^</li^>
echo ^<li^>✅ Steam Integration ^(SteamCMD, ASE/ASA^)^</li^>
echo ^<li^>✅ RCON Protocol ^(Server communication^)^</li^>
echo ^<li^>✅ System Monitoring ^(Real-time tracking^)^</li^>
echo ^<li^>✅ Security ^(JWT Auth, UFW Firewall^)^</li^>
echo ^</ul^>
echo ^</div^>
echo ^<div class="card"^>
echo ^<h3^>📍 Szimulált Elérési Pontok^</h3^>
echo ^<ul^>
echo ^<li^>^<strong^>Frontend:^</strong^> ^<code^>file:///%INSTALL_DIR:\=/%/frontend/dist/index.html^</code^>^</li^>
echo ^<li^>^<strong^>Backend API:^</strong^> ^<code^>http://localhost:8000/api^</code^> ^(szimulálva^)^</li^>
echo ^<li^>^<strong^>API Docs:^</strong^> ^<code^>http://localhost:8000/docs^</code^> ^(szimulálva^)^</li^>
echo ^<li^>^<strong^>Konfiguráció:^</strong^> ^<code^>%INSTALL_DIR%\config\^</code^>^</li^>
echo ^<li^>^<strong^>Logok:^</strong^> ^<code^>%LOG_DIR%\^</code^>^</li^>
echo ^</ul^>
echo ^</div^>
echo ^<div class="card"^>
echo ^<h3^>🔧 Linux Telepítés^</h3^>
echo ^<p^>^<strong^>Valódi Linux szerveren:^</strong^>^</p^>
echo ^<pre^>^<code^># SSH kapcsolódás
echo ssh user@your-server.com
echo.
echo # Repository klónozása  
echo git clone https://github.com/zedinke/zedin-steam-manager.git
echo.
echo # Telepítő futtatása
echo cd zedin-steam-manager
echo sudo ./install.sh^</code^>^</pre^>
echo ^</div^>
echo ^</div^>
echo ^<script^>
echo console.log^('🎮 Zedin Steam Manager - Windows Szimuláció'^);
echo console.log^('📁 Telepítési könyvtár:', '%INSTALL_DIR%'^);
echo console.log^('✅ Szimuláció befejezve:', new Date^(^).toISOString^(^)^);
echo ^</script^>
echo ^</body^>
echo ^</html^>
) > "%INSTALL_DIR%\frontend\dist\index.html"

echo [%date% %time%] ✓ Frontend build létrehozva

REM Service fájlok  
echo [%date% %time%] 🔧 Service fájlok létrehozása...
(
echo [Unit]
echo Description=Zedin Steam Manager Backend ^(Simulation^)
echo After=network.target
echo.
echo [Service] 
echo Type=simple
echo User=zsmanager
echo WorkingDirectory=%INSTALL_DIR%/backend
echo EnvironmentFile=%INSTALL_DIR%/config/zsmanager.env
echo ExecStart=python3 main.py
echo Restart=always
echo RestartSec=3
echo.
echo [Install]
echo WantedBy=multi-user.target
) > "%INSTALL_DIR%\config\zsmanager-backend.service"

echo [%date% %time%] ✓ Service fájlok létrehozva

REM Összefoglaló
echo.
echo ============================================================================
echo                     🎉 WINDOWS SZIMULÁCIÓ BEFEJEZVE! 🎉
echo ============================================================================
echo.
echo 📊 Telepítés összefoglaló:
echo    Backend: ✓ Telepítve (%INSTALL_DIR%\backend)
echo    Frontend: ✓ Felépítve (%INSTALL_DIR%\frontend\dist)
echo    Konfiguráció: ✓ Létrehozva (%INSTALL_DIR%\config)
echo.
echo 🌐 Elérési pontok:
echo    Web Interface: file:///%INSTALL_DIR:\=/%/frontend/dist/index.html
echo    Backend API: http://localhost:8000 (szimulálva)
echo    Telepítési könyvtár: %INSTALL_DIR%
echo.
echo 🔧 Hasznos parancsok:
echo    Fájlok megtekintése: explorer "%INSTALL_DIR%"
echo    Web interface: start "%INSTALL_DIR%\frontend\dist\index.html"
echo.
echo ✨ Éles telepítéshez Linux szerveren:
echo    ssh user@server
echo    git clone https://github.com/zedinke/zedin-steam-manager.git
echo    cd zedin-steam-manager ^&^& sudo ./install.sh
echo.
echo ============================================================================

REM Web interface automatikus megnyitása
echo [%date% %time%] 🌐 Web interface megnyitása...
start "" "%INSTALL_DIR%\frontend\dist\index.html"

echo.
echo Nyomj ENTER-t a telepítési könyvtár megnyitásához...
pause >nul
explorer "%INSTALL_DIR%"

echo.
echo Nyomj ENTER-t a kilépéshez...
pause >nul