#!/bin/bash

# Zedin Steam Manager Update Script
# Usage: sudo ./update.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
INSTALL_DIR="/opt/zedin-steam-manager"
SERVICE_USER="zsmanager"
FRONTEND_DIR="$INSTALL_DIR/frontend"
BACKEND_DIR="$INSTALL_DIR/backend"

# Logging function
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
echo "                    🔄 Zedin Steam Manager Update"  
echo "============================================================================"
echo ""

# Check if services are running
log "Checking current service status..."
BACKEND_RUNNING=false
if systemctl is-active --quiet zsmanager-backend; then
    BACKEND_RUNNING=true
    info "Backend service is running"
else
    warning "Backend service is not running"
fi

# Navigate to project directory
if [ -d "$INSTALL_DIR" ]; then
    cd "$INSTALL_DIR"
    log "Working directory: $INSTALL_DIR"
else
    error "Installation directory not found: $INSTALL_DIR"
fi

# Pull latest changes from git
log "Pulling latest changes from GitHub..."
if git fetch origin && git pull origin main; then
    log "✓ Git pull completed successfully"
else
    warning "Git pull failed - continuing with existing files"
fi

# Check for backend changes
log "Checking for backend updates..."
cd "$BACKEND_DIR"

# Update Python dependencies if requirements.txt changed
if git diff HEAD~1 HEAD --quiet requirements.txt 2>/dev/null; then
    info "No changes in requirements.txt"
else
    log "Requirements.txt changed - updating Python dependencies..."
    sudo -u $SERVICE_USER $INSTALL_DIR/venv/bin/pip install -r requirements.txt
    log "✓ Python dependencies updated"
fi

# Check for frontend changes
log "Checking for frontend updates..."
cd "$FRONTEND_DIR"

# Update Node.js dependencies if package.json changed
if git diff HEAD~1 HEAD --quiet package.json 2>/dev/null; then
    info "No changes in package.json"
else
    log "Package.json changed - updating Node.js dependencies..."
    sudo -u $SERVICE_USER npm install
    log "✓ Node.js dependencies updated"
fi

# Always rebuild frontend if source files changed
if git diff HEAD~1 HEAD --quiet src/ 2>/dev/null; then
    info "No frontend source changes detected"
else
    log "Frontend source changes detected - rebuilding..."
    sudo -u $SERVICE_USER npm run build
    log "✓ Frontend rebuilt successfully"
fi

# Check for database model changes
cd "$INSTALL_DIR"
if git diff HEAD~1 HEAD --quiet backend/models/ 2>/dev/null; then
    info "No database model changes detected"
else
    warning "Database model changes detected - may require manual migration"
    info "Check: sudo -u $SERVICE_USER $INSTALL_DIR/venv/bin/python -m alembic upgrade head"
fi

# Restart services if they were running
if [ "$BACKEND_RUNNING" = true ]; then
    log "Restarting backend service..."
    systemctl restart zsmanager-backend
    sleep 3
    
    if systemctl is-active --quiet zsmanager-backend; then
        log "✓ Backend service restarted successfully"
    else
        error "Backend service failed to restart - check logs: journalctl -u zsmanager-backend"
    fi
else
    info "Backend service was not running - not restarting"
fi

# Reload nginx
log "Reloading nginx configuration..."
if systemctl reload nginx; then
    log "✓ Nginx reloaded successfully"
else
    warning "Nginx reload failed - trying restart..."
    systemctl restart nginx
fi

# Final status check
log "Performing final status check..."

BACKEND_STATUS="✗ Not running"
NGINX_STATUS="✗ Not running"

if systemctl is-active --quiet zsmanager-backend; then
    BACKEND_STATUS="✓ Running"
fi

if systemctl is-active --quiet nginx; then
    NGINX_STATUS="✓ Running"  
fi

echo ""
echo "============================================================================"
echo "                    ✅ UPDATE COMPLETE!"
echo "============================================================================"
echo ""
echo "📊 Service Status:"
echo "   Backend: $BACKEND_STATUS"
echo "   Nginx: $NGINX_STATUS"
echo ""
echo "🌐 Access Points:"
echo "   Web Interface: http://$(hostname -I | awk '{print $1}')"
echo "   API Documentation: http://$(hostname -I | awk '{print $1}')/docs"
echo ""
echo "🔧 Useful Commands:"
echo "   Check logs: sudo journalctl -f -u zsmanager-backend"
echo "   Restart backend: sudo systemctl restart zsmanager-backend"
echo "   Check status: sudo systemctl status zsmanager-backend"
echo "   Update again: cd $INSTALL_DIR && sudo ./update.sh"
echo ""
echo "📖 Documentation:"
echo "   Update Guide: $INSTALL_DIR/MAINTENANCE.md"
echo "   Authentication: $INSTALL_DIR/AUTH_SYSTEM.md"
echo "   Main README: $INSTALL_DIR/README.md"
echo ""
echo "============================================================================"

log "Update completed successfully!"