#!/bin/bash

# Zedin Steam Manager Production Deployment Script
# This script fixes the production server issues

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
INSTALL_DIR="/opt/zedin-steam-manager"
SERVICE_USER="zsmanager"
REPO_URL="https://github.com/zedinke/zedin-steam-manager.git"

log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

info() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root (use sudo)"
fi

echo "============================================================================"
echo "                🚀 Zedin Steam Manager Production Fix"
echo "============================================================================"

log "Step 1: Stop services"
systemctl stop zsmanager-backend || true

log "Step 2: Fix Git repository"
cd "$INSTALL_DIR"

# Remove broken git repo if exists
if [ -d ".git" ]; then
    warning "Removing broken Git repository"
    rm -rf .git
fi

# Clone fresh repository
log "Cloning latest version from GitHub..."
git init
git remote add origin "$REPO_URL"
git fetch origin
git reset --hard origin/main

# Set proper ownership
chown -R $SERVICE_USER:$SERVICE_USER "$INSTALL_DIR"

log "Step 3: Update backend dependencies"
cd "$INSTALL_DIR/backend"
sudo -u $SERVICE_USER $INSTALL_DIR/venv/bin/pip install -r requirements.txt

log "Step 4: Deploy simplified frontend"
cd "$INSTALL_DIR/frontend"

# Remove old node_modules and dependencies
rm -rf node_modules package-lock.json

# Install only required dependencies
sudo -u $SERVICE_USER npm install

# Copy the simplified HTML build
log "Deploying simplified frontend (no Material-UI)..."
cp -f dist/index.html "$INSTALL_DIR/frontend/dist/"

# Ensure correct permissions
chown -R $SERVICE_USER:$SERVICE_USER "$INSTALL_DIR/frontend"

log "Step 5: Database migration"
cd "$INSTALL_DIR/backend"
sudo -u $SERVICE_USER $INSTALL_DIR/venv/bin/python -m alembic upgrade head || warning "Database migration failed - may need manual intervention"

log "Step 6: Restart services"
systemctl start zsmanager-backend
systemctl reload nginx

# Status check
sleep 3
if systemctl is-active --quiet zsmanager-backend; then
    log "✅ Backend service is running"
else
    error "❌ Backend service failed to start - check: journalctl -u zsmanager-backend"
fi

if systemctl is-active --quiet nginx; then
    log "✅ Nginx is running"
else
    warning "⚠️ Nginx may have issues"
fi

echo "============================================================================"
echo "                    ✅ PRODUCTION FIX COMPLETE!"
echo "============================================================================"
echo ""
echo "🎯 Fixed Issues:"
echo "   • Git repository reinitialized"
echo "   • Simplified frontend deployed (no Material-UI)"  
echo "   • Backend dependencies updated"
echo "   • Services restarted"
echo ""
echo "🌐 Test Access:"
echo "   Web: http://$(hostname -I | awk '{print $1}')"
echo "   API: http://$(hostname -I | awk '{print $1}')/api/health"
echo ""
echo "🔍 Check Logs:"
echo "   sudo journalctl -f -u zsmanager-backend"
echo ""
echo "============================================================================"

log "Production deployment completed successfully!"