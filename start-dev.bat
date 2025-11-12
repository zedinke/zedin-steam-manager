@echo off
echo Starting Zedin Steam Manager Development Environment...

REM Refresh PATH environment variables
set PATH=%PATH%;C:\Program Files\nodejs\;%APPDATA%\npm

echo Starting Backend FastAPI Server...
start /min cmd /c "cd backend && python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000"

timeout /t 3

echo Starting Frontend Development Server...
start /min cmd /c "cd frontend && npm run dev"

timeout /t 5

echo Starting Electron Application...
cd .
npm start

echo Development environment started!