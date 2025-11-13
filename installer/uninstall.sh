#!/bin/bash

#############################################
# Zedin Steam Manager - Uninstall Script
# Version: 0.0.1-alpha
#############################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_msg() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_header() {
    clear
    print_msg "$BLUE" "=============================================="
    print_msg "$BLUE" "  Zedin Steam Manager - Uninstall"
    print_msg "$BLUE" "=============================================="
    echo ""
}

print_header

# Confirmation
print_msg "$RED" "⚠️  WARNING: This will completely remove Zedin Steam Manager"
echo ""
read -p "Are you sure you want to continue? (type 'yes' to confirm): " confirmation

if [ "$confirmation" != "yes" ]; then
    print_msg "$YELLOW" "Uninstall cancelled"
    exit 0
fi

echo ""
print_msg "$BLUE" "Uninstalling..."

# Stop services
print_msg "$YELLOW" "Stopping services..."
systemctl stop zedin-backend.service 2>/dev/null || true
systemctl stop zedin-frontend.service 2>/dev/null || true
print_msg "$GREEN" "✅ Services stopped"

# Disable services
print_msg "$YELLOW" "Disabling services..."
systemctl disable zedin-backend.service 2>/dev/null || true
systemctl disable zedin-frontend.service 2>/dev/null || true
print_msg "$GREEN" "✅ Services disabled"

# Remove service files
print_msg "$YELLOW" "Removing service files..."
rm -f /etc/systemd/system/zedin-backend.service
rm -f /etc/systemd/system/zedin-frontend.service
systemctl daemon-reload
print_msg "$GREEN" "✅ Service files removed"

# Remove Nginx configuration
print_msg "$YELLOW" "Removing Nginx configuration..."
rm -f /etc/nginx/sites-enabled/zedin-manager
rm -f /etc/nginx/sites-available/zedin-manager
systemctl restart nginx 2>/dev/null || true
print_msg "$GREEN" "✅ Nginx configuration removed"

# Remove application directory
print_msg "$YELLOW" "Removing application files..."
rm -rf /opt/zedin-steam-manager
print_msg "$GREEN" "✅ Application files removed"

# Done
print_header
print_msg "$GREEN" "✅ Uninstall Complete!"
echo ""
print_msg "$BLUE" "Zedin Steam Manager has been removed from your system"
echo ""
print_msg "$YELLOW" "Note: Database data on Supabase was not removed"
echo ""
