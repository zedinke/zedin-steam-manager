#!/bin/bash

# Zedin Steam Manager Service Debug Script

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

INSTALL_DIR="/opt/zedin-steam-manager"
SERVICE_USER="zsmanager"

log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

echo "============================================================================"
echo "                🔍 Zedin Steam Manager Debug Info"
echo "============================================================================"

log "Checking systemd service status..."
systemctl status zsmanager-backend --no-pager || true

echo ""
log "Checking recent service logs..."
journalctl -u zsmanager-backend --since "5 minutes ago" --no-pager

echo ""
log "Checking backend directory and permissions..."
ls -la "$INSTALL_DIR/backend/"
ls -la "$INSTALL_DIR/backend/main.py"

echo ""
log "Checking virtual environment..."
ls -la "$INSTALL_DIR/venv/bin/python"
sudo -u $SERVICE_USER "$INSTALL_DIR/venv/bin/python" --version

echo ""
log "Testing backend import..."
cd "$INSTALL_DIR/backend"
sudo -u $SERVICE_USER "$INSTALL_DIR/venv/bin/python" -c "
import sys
sys.path.insert(0, '.')
try:
    from main import app
    print('✅ Backend imports successfully')
except Exception as e:
    print(f'❌ Backend import failed: {e}')
"

echo ""
log "Checking database..."
if [ -f "$INSTALL_DIR/backend/zedin_steam_manager.db" ]; then
    ls -la "$INSTALL_DIR/backend/zedin_steam_manager.db"
    info "Database file exists"
else
    warning "Database file missing"
fi

echo ""
log "Checking environment variables..."
if [ -f "/etc/systemd/system/zsmanager-backend.service" ]; then
    info "Service file exists"
    cat "/etc/systemd/system/zsmanager-backend.service"
else
    error "Service file missing"
fi

echo ""
log "Manual backend start test..."
info "Trying to start backend manually..."
cd "$INSTALL_DIR/backend"
timeout 10s sudo -u $SERVICE_USER "$INSTALL_DIR/venv/bin/python" -m uvicorn main:app --host 0.0.0.0 --port 8000 || warning "Manual start test completed"

echo "============================================================================"
echo "                    🔧 Debug Complete"
echo "============================================================================"