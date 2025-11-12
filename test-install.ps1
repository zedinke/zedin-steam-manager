# Zedin Steam Manager - Windows Installation Test
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "                    Zedin Steam Manager - Windows Test" -ForegroundColor Cyan  
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Current directory: $PWD" -ForegroundColor Yellow
Write-Host ""

# Check project structure
Write-Host "=== Checking Project Structure ===" -ForegroundColor Green
$projectValid = $true

if (Test-Path "backend") {
    Write-Host "[✓] backend directory found" -ForegroundColor Green
    if (Test-Path "backend\main.py") {
        Write-Host "  ✓ main.py found" -ForegroundColor Green
    } else {
        Write-Host "  ✗ main.py missing" -ForegroundColor Red
        $projectValid = $false
    }
    if (Test-Path "backend\requirements.txt") {
        Write-Host "  ✓ requirements.txt found" -ForegroundColor Green
    } else {
        Write-Host "  ✗ requirements.txt missing" -ForegroundColor Red
        $projectValid = $false
    }
} else {
    Write-Host "[✗] backend directory not found" -ForegroundColor Red
    $projectValid = $false
}

if (Test-Path "frontend") {
    Write-Host "[✓] frontend directory found" -ForegroundColor Green
    if (Test-Path "frontend\package.json") {
        Write-Host "  ✓ package.json found" -ForegroundColor Green
    } else {
        Write-Host "  ✗ package.json missing" -ForegroundColor Red
        $projectValid = $false
    }
    if (Test-Path "frontend\src") {
        Write-Host "  ✓ src directory found" -ForegroundColor Green
    } else {
        Write-Host "  ✗ src directory missing" -ForegroundColor Red
        $projectValid = $false
    }
} else {
    Write-Host "[✗] frontend directory not found" -ForegroundColor Red
    $projectValid = $false
}

Write-Host ""

# Check dependencies
Write-Host "=== Checking Dependencies ===" -ForegroundColor Green
try {
    $pythonVersion = python --version 2>$null
    Write-Host "[✓] Python found: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "[✗] Python not found" -ForegroundColor Red
}

try {
    $nodeVersion = node --version 2>$null
    Write-Host "[✓] Node.js found: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "[✗] Node.js not found" -ForegroundColor Red
}

try {
    $npmVersion = npm --version 2>$null
    Write-Host "[✓] npm found: $npmVersion" -ForegroundColor Green
} catch {
    Write-Host "[✗] npm not found" -ForegroundColor Red
}

Write-Host ""

# Test Python imports
if ($projectValid -and (Test-Path "backend\requirements.txt")) {
    Write-Host "=== Testing Python Dependencies ===" -ForegroundColor Green
    
    Push-Location backend
    
    Write-Host "Testing Python imports..." -ForegroundColor Yellow
    $pythonTest = @"
try:
    import fastapi
    print('[✓] FastAPI available')
except ImportError:
    print('[✗] FastAPI not installed - run: pip install fastapi')

try:
    import uvicorn
    print('[✓] Uvicorn available')
except ImportError:
    print('[✗] Uvicorn not installed - run: pip install uvicorn')

try:
    import sqlalchemy
    print('[✓] SQLAlchemy available')
except ImportError:
    print('[✗] SQLAlchemy not installed - run: pip install sqlalchemy')
"@
    python -c $pythonTest
    
    Pop-Location
}

Write-Host ""

# Simulate installation steps
Write-Host "=== Installation Simulation ===" -ForegroundColor Green

if ($projectValid) {
    Write-Host "Installation would perform these steps:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Create directories:" -ForegroundColor Cyan
    Write-Host "   - /opt/zedin-steam-manager/" -ForegroundColor Gray
    Write-Host "   - /var/lib/zedin/" -ForegroundColor Gray
    Write-Host "   - /var/log/zedin/" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Install Python dependencies:" -ForegroundColor Cyan
    Write-Host "   pip install -r backend/requirements.txt" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. Install and build frontend:" -ForegroundColor Cyan
    Write-Host "   cd frontend; npm install; npm run build" -ForegroundColor Gray
    Write-Host ""
    Write-Host "4. Create systemd service:" -ForegroundColor Cyan
    Write-Host "   zsmanager-backend.service" -ForegroundColor Gray
    Write-Host ""
    Write-Host "5. Configure Nginx:" -ForegroundColor Cyan
    Write-Host "   Proxy /api/ to backend:8000" -ForegroundColor Gray
    Write-Host "   Serve frontend from /dist/" -ForegroundColor Gray
    Write-Host ""
    Write-Host "6. Start services:" -ForegroundColor Cyan
    Write-Host "   systemctl start zsmanager-backend nginx" -ForegroundColor Gray
} else {
    Write-Host "❌ Project structure invalid - cannot proceed with installation" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Quick Development Test ===" -ForegroundColor Green

if (Test-Path "backend\main.py") {
    Write-Host "To test backend locally:" -ForegroundColor Yellow
    Write-Host "  cd backend" -ForegroundColor Gray
    Write-Host "  python -m venv venv" -ForegroundColor Gray
    Write-Host "  venv\Scripts\activate" -ForegroundColor Gray
    Write-Host "  pip install -r requirements.txt" -ForegroundColor Gray
    Write-Host "  uvicorn main:app --reload --host 0.0.0.0 --port 8000" -ForegroundColor Gray
}

if (Test-Path "frontend\package.json") {
    Write-Host ""
    Write-Host "To test frontend locally:" -ForegroundColor Yellow
    Write-Host "  cd frontend" -ForegroundColor Gray
    Write-Host "  npm install" -ForegroundColor Gray
    Write-Host "  npm run dev" -ForegroundColor Gray
}

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "For Linux installation, run: sudo ./install-simple.sh" -ForegroundColor Green
Write-Host "============================================================================" -ForegroundColor Cyan

Read-Host "Press Enter to continue"