@echo off
echo Starting Zedin Steam Manager Development Environment...
echo.

start "Backend API" cmd /k "cd backend && uvicorn main:app --reload --host 0.0.0.0 --port 8000"
timeout /t 3 /nobreak > nul

start "Frontend Dev Server" cmd /k "cd frontend && npm run dev"

echo.
echo Services starting...
echo Backend API: http://localhost:8000
echo Frontend: http://localhost:3000
echo.
echo Press any key to close this window (services will continue running)
pause > nul
