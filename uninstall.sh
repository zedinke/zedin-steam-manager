#!/bin/bash

# ============================================================================
# Zedin Steam Manager - Eltávolító Script
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

# Variables
SERVICE_USER="zedin"
INSTALL_DIR="/opt/zedin-steam-manager"
DATA_DIR="/var/lib/zedin"
LOG_DIR="/var/log/zedin"

echo "============================================================================"
echo "                    Zedin Steam Manager Uninstaller                       "
echo "============================================================================"
echo ""
warning "Ez a script TELJESEN eltávolítja a Zedin Steam Manager-t!"
echo ""
echo "El fog távolítani:"
echo "  ❌ Alkalmazást és összes fájlját ($INSTALL_DIR)"
echo "  ❌ Adatbázist és szerver fájlokat ($DATA_DIR)"
echo "  ❌ Naplófájlokat ($LOG_DIR)"
echo "  ❌ Systemd szolgáltatásokat"
echo "  ❌ Nginx konfigurációt"
echo "  ❌ Felhasználói fiókot ($SERVICE_USER)"
echo "  ❌ Cron job-okat"
echo ""
read -p "Biztos vagy benne? Írd be 'IGEN' a folytatáshoz: " -r
if [[ ! $REPLY == "IGEN" ]]; then
    echo "Eltávolítás megszakítva."
    exit 1
fi

echo ""
read -p "Utolsó lehetőség! Biztosan törölni akarod az ÖSSZES adatot? (igen/nem): " -r
if [[ ! $REPLY =~ ^(igen|IGEN)$ ]]; then
    echo "Eltávolítás megszakítva."
    exit 1
fi

log "Zedin Steam Manager eltávolítása megkezdődött..."

# Stop and disable services
log "Szolgáltatások leállítása..."
sudo systemctl stop zedin-backend zedin-frontend 2>/dev/null || true
sudo systemctl disable zedin-backend zedin-frontend 2>/dev/null || true

# Remove systemd service files
log "Systemd szolgáltatások eltávolítása..."
sudo rm -f /etc/systemd/system/zedin-backend.service
sudo rm -f /etc/systemd/system/zedin-frontend.service
sudo systemctl daemon-reload

# Remove nginx configuration
log "Nginx konfiguráció eltávolítása..."
sudo rm -f /etc/nginx/sites-enabled/zedin-steam-manager
sudo rm -f /etc/nginx/sites-available/zedin-steam-manager
sudo systemctl reload nginx 2>/dev/null || true

# Remove cron jobs
log "Cron job-ok eltávolítása..."
sudo rm -f /etc/cron.d/zedin-backup

# Remove logrotate configuration
log "Logrotate konfiguráció eltávolítása..."
sudo rm -f /etc/logrotate.d/zedin-steam-manager

# Remove UFW rules
log "Tűzfal szabályok eltávolítása..."
sudo ufw delete allow 7777:7877/tcp 2>/dev/null || true
sudo ufw delete allow 7777:7877/udp 2>/dev/null || true
sudo ufw delete allow 27015:27115/tcp 2>/dev/null || true
sudo ufw delete allow 27015:27115/udp 2>/dev/null || true
sudo ufw delete allow 27020:27120/tcp 2>/dev/null || true

# Stop any remaining processes
log "Fennmaradt folyamatok leállítása..."
sudo pkill -u $SERVICE_USER 2>/dev/null || true
sudo pkill -f "uvicorn.*main:app" 2>/dev/null || true

# Remove user account
log "Felhasználói fiók eltávolítása..."
if id "$SERVICE_USER" &>/dev/null; then
    sudo userdel -r $SERVICE_USER 2>/dev/null || {
        warning "Nem sikerült teljesen eltávolítani a felhasználót. Kézi törlés szükséges lehet."
        sudo userdel $SERVICE_USER 2>/dev/null || true
    }
fi

# Remove directories
log "Könyvtárak eltávolítása..."
sudo rm -rf $INSTALL_DIR
sudo rm -rf $DATA_DIR
sudo rm -rf $LOG_DIR
sudo rm -rf /etc/zedin

# Remove SteamCMD (optional - ask user)
read -p "Eltávolítsam a SteamCMD-t is? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log "SteamCMD eltávolítása..."
    sudo rm -rf /opt/steamcmd
fi

# Clean package cache
log "Package cache tisztítása..."
sudo apt autoremove -y 2>/dev/null || true

echo ""
echo "============================================================================"
echo "                    ✅ ELTÁVOLÍTÁS BEFEJEZVE!                              "
echo "============================================================================"
echo ""
log "Zedin Steam Manager teljesen eltávolítva a rendszerből."
echo ""
echo "Az alábbiak maradtak meg (ha telepítve voltak):"
echo "  ✓ Python, Node.js, Nginx (más alkalmazások is használhatják)"
echo "  ✓ UFW tűzfal (csak a Zedin specifikus szabályok lettek eltávolítva)"
echo ""
echo "Ha teljesen tiszta rendszert szeretnél, manuálisan eltávolíthatod:"
echo "  sudo apt remove nodejs npm nginx python3"
echo ""
echo "Köszönjük, hogy használtad a Zedin Steam Manager-t!"
echo "============================================================================"
echo ""