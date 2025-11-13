#!/bin/bash

# Zedin Steam Manager - Uninstall Script

echo "=============================================="
echo "  Zedin Steam Manager - Uninstall"
echo "=============================================="
echo ""

INSTALL_DIR="/opt/zedin-steam-manager"
SERVICE_USER="zedin"

echo "⚠️  WARNING: This will completely remove Zedin Steam Manager!"
echo ""
echo "The following will be removed:"
echo "  - Installation directory: $INSTALL_DIR"
echo "  - Systemd services: zedin-backend"
echo "  - Nginx configuration"
echo "  - Service user: $SERVICE_USER"
echo ""
read -p "Are you sure you want to uninstall? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Uninstall cancelled."
    exit 0
fi

echo ""
echo "Stopping and removing services..."

# Stop and disable services
sudo systemctl stop zedin-backend 2>/dev/null || true
sudo systemctl disable zedin-backend 2>/dev/null || true

# Remove systemd service files
sudo rm -f /etc/systemd/system/zedin-backend.service
sudo systemctl daemon-reload

echo "✅ Services removed"

echo ""
echo "Removing Nginx configuration..."

# Remove nginx configuration
sudo rm -f /etc/nginx/sites-enabled/zedin-steam-manager
sudo rm -f /etc/nginx/sites-available/zedin-steam-manager
sudo systemctl restart nginx 2>/dev/null || true

echo "✅ Nginx configuration removed"

echo ""
echo "Removing installation directory..."

# Remove installation directory
sudo rm -rf $INSTALL_DIR

echo "✅ Installation directory removed"

echo ""
echo "Removing service user..."

# Remove service user
sudo userdel -r $SERVICE_USER 2>/dev/null || true

echo "✅ Service user removed"

echo ""
echo "=============================================="
echo "✅ Uninstall Complete!"
echo "=============================================="
echo ""
echo "Zedin Steam Manager has been completely removed from your system."
echo ""
