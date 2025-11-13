@echo off
REM ############################################
REM Zedin Steam Manager - Main Installer
REM Version: 0.0.1-alpha
REM Platform: Windows
REM ############################################

setlocal enabledelayedexpansion

REM Directories
set SCRIPT_DIR=%~dp0
set BLOCKS_DIR=%SCRIPT_DIR%blocks
set LOG_DIR=%SCRIPT_DIR%logs
set INSTALL_LOG=%LOG_DIR%\install-%date:~0,4%%date:~5,2%%date:~8,2%-%time:~0,2%%time:~3,2%%time:~6,2%.log
set INSTALL_LOG=%INSTALL_LOG: =0%

REM Create log directory
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

REM Header
cls
echo ==============================================
echo   Zedin Steam Manager - Installer v0.0.1
echo ==============================================
echo.
echo [%date% %time%] Installation started >> "%INSTALL_LOG%"

REM Installation blocks
set blocks[0]=01-system-check.bat:System Requirements Check
set blocks[1]=02-dependencies.bat:Installing Dependencies
set blocks[2]=03-database.bat:Database Configuration
set blocks[3]=04-backend.bat:Backend Setup
set blocks[4]=05-frontend.bat:Frontend Setup
set blocks[5]=06-services.bat:Service Configuration
set blocks[6]=07-nginx.bat:Web Server Setup

set total=7
set current=0

for /L %%i in (0,1,6) do (
    set /a current=%%i+1
    
    REM Parse block info
    for /f "tokens=1,2 delims=:" %%a in ("!blocks[%%i]!") do (
        set block_file=%%a
        set description=%%b
        
        echo.
        echo [!current!/%total%] !description!
        echo.
        echo [%date% %time%] Starting: !block_file! >> "%INSTALL_LOG%"
        
        if exist "%BLOCKS_DIR%\!block_file!" (
            call "%BLOCKS_DIR%\!block_file!" >> "%INSTALL_LOG%" 2>&1
            if errorlevel 1 (
                echo ERROR: !description! failed
                echo [%date% %time%] ERROR: !block_file! failed >> "%INSTALL_LOG%"
                echo Installation aborted. Check log: %INSTALL_LOG%
                pause
                exit /b 1
            )
            echo SUCCESS: !description! completed
            echo [%date% %time%] SUCCESS: !block_file! >> "%INSTALL_LOG%"
        ) else (
            echo ERROR: Block !block_file! not found
            echo [%date% %time%] ERROR: Block !block_file! not found >> "%INSTALL_LOG%"
            pause
            exit /b 1
        )
        
        timeout /t 1 /nobreak >nul
    )
)

REM Installation complete
cls
echo ==============================================
echo   Zedin Steam Manager - Installer v0.0.1
echo ==============================================
echo.
echo Installation Complete!
echo.
echo Access your manager at:
echo   http://localhost
echo.
echo Installation log:
echo   %INSTALL_LOG%
echo.
echo [%date% %time%] Installation completed successfully >> "%INSTALL_LOG%"

pause
