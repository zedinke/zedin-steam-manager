#!/bin/bash

#############################################
# Zedin Steam Manager - Update Script
# Version: 0.0.1-alpha
#############################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Directories
APP_DIR="/opt/zedin-steam-manager"
LOG_DIR="$APP_DIR/installer/logs"
UPDATE_LOG="$LOG_DIR/update-$(date +%Y%m%d-%H%M%S).log"

# Create log directory
mkdir -p "$LOG_DIR"

# Logging function
log() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$UPDATE_LOG"
}

print_msg() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
    log "INFO" "$message"
}

print_header() {
    clear
    print_msg "$BLUE" "=============================================="
    print_msg "$BLUE" "  Zedin Steam Manager - Update v0.0.1"
    print_msg "$BLUE" "=============================================="
    echo ""
}

print_header

# Check if installed
if [ ! -d "$APP_DIR" ]; then
    print_msg "$RED" "❌ Error: Zedin Steam Manager is not installed"
    print_msg "$YELLOW" "   Run main-installer.sh first"
    exit 1
fi

cd "$APP_DIR"

# Check if git repository
if [ ! -d ".git" ]; then
    print_msg "$RED" "❌ Error: Not a git repository"
    exit 1
fi

print_msg "$BLUE" "Checking for updates..."
log "INFO" "Update started"

# Fetch latest changes
git fetch origin main
COMMITS_BEHIND=$(git rev-list HEAD...origin/main --count)

if [ "$COMMITS_BEHIND" -eq 0 ]; then
    print_msg "$GREEN" "✅ Already up to date"
    log "INFO" "No updates available"
    exit 0
fi

print_msg "$YELLOW" "📦 $COMMITS_BEHIND updates available"
log "INFO" "Updates found: $COMMITS_BEHIND commits"

# Pull updates
print_msg "$BLUE" "Pulling updates..."
git pull origin main

if [ $? -ne 0 ]; then
    print_msg "$RED" "❌ Git pull failed"
    log "ERROR" "Git pull failed"
    exit 1
fi

print_msg "$GREEN" "✅ Code updated"

# Update backend dependencies
if [ -f "$APP_DIR/backend/requirements.txt" ]; then
    print_msg "$BLUE" "Updating backend dependencies..."
    source "$APP_DIR/backend/venv/bin/activate"
    pip install -r "$APP_DIR/backend/requirements.txt" -q
    print_msg "$GREEN" "✅ Backend dependencies updated"
fi

# Update frontend dependencies
if [ -f "$APP_DIR/frontend/package.json" ]; then
    print_msg "$BLUE" "Updating frontend dependencies..."
    cd "$APP_DIR/frontend"
    npm install --silent
    npm run build
    print_msg "$GREEN" "✅ Frontend dependencies updated"
fi

# Restart services
print_msg "$BLUE" "Restarting services..."
systemctl restart zedin-backend.service
systemctl restart zedin-frontend.service
systemctl restart nginx

# Check services
sleep 3

if systemctl is-active --quiet zedin-backend.service; then
    print_msg "$GREEN" "✅ Backend service running"
else
    print_msg "$RED" "❌ Backend service failed"
    systemctl status zedin-backend.service --no-pager
fi

if systemctl is-active --quiet zedin-frontend.service; then
    print_msg "$GREEN" "✅ Frontend service running"
else
    print_msg "$YELLOW" "⚠️  Frontend service warning"
fi

if systemctl is-active --quiet nginx; then
    print_msg "$GREEN" "✅ Nginx running"
else
    print_msg "$RED" "❌ Nginx failed"
fi

# Update complete
print_header
print_msg "$GREEN" "✅ Update Complete!"
echo ""
print_msg "$BLUE" "Updated from $COMMITS_BEHIND commits behind"
echo ""
print_msg "$BLUE" "🌐 Access your manager at:"
SERVER_IP=$(hostname -I | awk '{print $1}')
print_msg "$GREEN" "   http://$SERVER_IP"
echo ""
print_msg "$BLUE" "📋 Update log:"
print_msg "$GREEN" "   $UPDATE_LOG"
echo ""

log "INFO" "Update completed successfully"
