@echo off
REM ############################################
REM Block 01: System Requirements Check
REM ############################################

echo Checking system requirements...
echo.

REM Check Windows version
ver | findstr /i "10\." >nul
if %errorlevel% equ 0 (
    echo [OK] Windows 10 or later detected
) else (
    ver | findstr /i "11\." >nul
    if %errorlevel% equ 0 (
        echo [OK] Windows 11 detected
    ) else (
        echo [ERROR] Windows 10 or later required
        exit /b 1
    )
)

REM Check disk space (need at least 10GB = 10485760 KB)
for /f "tokens=3" %%a in ('dir /-c %SystemDrive%\ ^| findstr /i "bytes free"') do set FREE_SPACE=%%a
set FREE_SPACE=%FREE_SPACE:,=%
if %FREE_SPACE% LSS 10737418240 (
    echo [WARNING] Low disk space
) else (
    echo [OK] Sufficient disk space available
)

REM Check if ports are available
netstat -ano | findstr ":80 " >nul
if %errorlevel% equ 0 (
    echo [WARNING] Port 80 is already in use
) else (
    echo [OK] Port 80 is available
)

netstat -ano | findstr ":3000 " >nul
if %errorlevel% equ 0 (
    echo [WARNING] Port 3000 is already in use
) else (
    echo [OK] Port 3000 is available
)

netstat -ano | findstr ":8000 " >nul
if %errorlevel% equ 0 (
    echo [WARNING] Port 8000 is already in use
) else (
    echo [OK] Port 8000 is available
)

REM Check internet connectivity
ping -n 1 google.com >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Internet connection available
) else (
    echo [ERROR] No internet connection
    exit /b 1
)

REM Check if already installed
if exist "%USERPROFILE%\zedin-steam-manager" (
    echo [WARNING] Previous installation detected
    set /p CONTINUE="Continue with installation? (Y/N): "
    if /i not "%CONTINUE%"=="Y" (
        echo Installation cancelled
        exit /b 1
    )
)

echo.
echo [OK] System requirements check passed
echo.
