#!/bin/bash

# ============================================================================
# Zedin Steam Manager - Linux Installation Script
# For Ubuntu/Debian systems
# ============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Functions
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    error "Please do not run this script as root. Use a regular user with sudo privileges."
fi

# Check OS
if ! grep -E "(Ubuntu|Debian)" /etc/os-release > /dev/null 2>&1; then
    error "This installer supports Ubuntu/Debian systems only."
fi

# Variables
INSTALL_DIR="/opt/zedin-steam-manager"
SERVICE_USER="zsmanager"
LOG_DIR="/var/log/zedin"
DATA_DIR="/var/lib/zedin"
STEAMCMD_DIR="/opt/steamcmd"

echo "============================================================================"
echo "                    Zedin Steam Manager Installer"
echo "============================================================================"
echo ""
echo "This installer will:"
echo "  1. Install system dependencies (Node.js, Python, SteamCMD)"
echo "  2. Create dedicated user and directories"
echo "  3. Install and configure the application"
echo "  4. Set up systemd services"
echo "  5. Configure firewall"
echo "  6. Create backup system"
echo ""
echo -n "Continue with installation? (y/N): "
read -r REPLY
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# ============================================================================
# PHASE 1: System Dependencies
# ============================================================================

log "PHASE 1: Installing system dependencies..."

# Update system
log "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install basic dependencies
log "Installing basic dependencies..."
sudo apt install -y curl wget gnupg2 software-properties-common apt-transport-https \
    ca-certificates git unzip tar htop nano vim screen tmux ufw fail2ban logrotate

# Install Python 3.9+
log "Installing Python..."
sudo apt install -y python3 python3-pip python3-venv python3-dev build-essential

# Install Node.js 18+
log "Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install SteamCMD dependencies
log "Installing SteamCMD dependencies..."
sudo dpkg --add-architecture i386
sudo apt update
sudo apt install -y lib32gcc-s1 libc6:i386 libncurses5:i386 libstdc++6:i386

# Install SteamCMD
log "Installing SteamCMD..."
sudo mkdir -p $STEAMCMD_DIR
cd /tmp
wget -O steamcmd.tar.gz https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
sudo tar -xzf steamcmd.tar.gz -C $STEAMCMD_DIR
sudo chown -R root:root $STEAMCMD_DIR
sudo chmod +x $STEAMCMD_DIR/steamcmd.sh

# ============================================================================
# PHASE 2: User and Directory Setup
# ============================================================================

log "PHASE 2: Setting up user and directories..."

# Create service user
if ! id "$SERVICE_USER" &>/dev/null; then
    log "Creating service user: $SERVICE_USER"
    sudo useradd -r -s /bin/bash -d $INSTALL_DIR -m $SERVICE_USER
else
    log "User $SERVICE_USER already exists"
fi

# Create directories
log "Creating directories..."
sudo mkdir -p $INSTALL_DIR
sudo mkdir -p $LOG_DIR
sudo mkdir -p $DATA_DIR/{servers,shared_files,backups}
sudo mkdir -p /etc/zedin

# Set permissions
sudo chown -R $SERVICE_USER:$SERVICE_USER $INSTALL_DIR
sudo chown -R $SERVICE_USER:$SERVICE_USER $DATA_DIR
sudo chown -R $SERVICE_USER:$SERVICE_USER $LOG_DIR

# ============================================================================
# PHASE 3: Application Installation
# ============================================================================

log "PHASE 3: Installing application..."

# Copy application files
if [ -d "backend" ] && [ -d "frontend" ] && [ -d "electron" ]; then
    log "Copying application files..."
    sudo cp -r * $INSTALL_DIR/
else
    error "Application files not found. Please run from the project directory."
fi

# Set ownership
sudo chown -R $SERVICE_USER:$SERVICE_USER $INSTALL_DIR

# Install dependencies
sudo -u $SERVICE_USER bash << 'EOF'
cd /opt/zedin-steam-manager

# Create Python virtual environment
log() { echo -e "\033[0;32m[$(date '+%Y-%m-%d %H:%M:%S')] $1\033[0m"; }
log "Creating Python virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Install Python dependencies
log "Installing Python dependencies..."
cd backend
pip install --upgrade pip
pip install -r requirements.txt
cd ..

# Install Node.js dependencies
log "Installing Node.js dependencies..."
npm install
cd frontend && npm install && npm run build && cd ..
EOF

# ============================================================================
# PHASE 4: Configuration
# ============================================================================

log "PHASE 4: Creating configuration..."

# Environment file
sudo tee /etc/zedin/zsmanager.env > /dev/null << EOF
APP_NAME=Zedin Steam Manager
VERSION=0.000001
DEBUG=False
HOST=0.0.0.0
PORT=8000
DATABASE_URL=sqlite:///$DATA_DIR/zedin_steam_manager.db
SECRET_KEY=$(openssl rand -hex 32)
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=1440
STEAMCMD_PATH=$STEAMCMD_DIR
SHARED_FILES_PATH=$DATA_DIR/shared_files
SERVERS_PATH=$DATA_DIR/servers
LOG_FILE=$LOG_DIR/steam_manager.log
ASE_APP_ID=376030
ASA_APP_ID=2430930
GITHUB_REPO=zedinke/zedin-steam-manager
UPDATE_CHECK_INTERVAL=3600
SYSTEM_MONITOR_INTERVAL=5
MAX_REMOTE_HOSTS=50
SSH_TIMEOUT=30
RCON_TIMEOUT=10
EOF

sudo chown root:$SERVICE_USER /etc/zedin/zedin.env
sudo chmod 640 /etc/zedin/zedin.env

# ============================================================================
# PHASE 5: Services
# ============================================================================

log "PHASE 5: Setting up services..."

# Backend service
sudo tee /etc/systemd/system/zsmanager-backend.service > /dev/null << EOF
[Unit]
Description=Zedin Steam Manager Backend
After=network.target

[Service]
Type=simple
User=$SERVICE_USER
Group=$SERVICE_USER
WorkingDirectory=$INSTALL_DIR/backend
Environment=PATH=$INSTALL_DIR/venv/bin
EnvironmentFile=/etc/zedin/zsmanager.env
ExecStart=$INSTALL_DIR/venv/bin/uvicorn main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# ============================================================================
# PHASE 6: Web Server
# ============================================================================

log "PHASE 6: Setting up Nginx..."

sudo apt install -y nginx

sudo tee /etc/nginx/sites-available/zedin-steam-manager > /dev/null << 'EOF'
server {
    listen 80;
    server_name _;

    location / {
        root /opt/zedin-steam-manager/frontend/dist;
        index index.html;
        try_files $uri $uri/ /index.html;
    }

    location /api/ {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    location /docs {
        proxy_pass http://localhost:8000;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/zedin-steam-manager /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t

# ============================================================================
# PHASE 7: Firewall
# ============================================================================

log "PHASE 7: Configuring firewall..."

sudo ufw --force enable
sudo ufw allow ssh
sudo ufw allow 'Nginx Full'
sudo ufw allow 7777:7877/tcp
sudo ufw allow 7777:7877/udp

# ============================================================================
# PHASE 8: Start Services
# ============================================================================

log "PHASE 8: Starting services..."

# Initialize database
sudo -u $SERVICE_USER bash << 'EOF'
cd /opt/zedin-steam-manager
source venv/bin/activate
cd backend
python3 -c "
from config.database import engine
from models import base
base.Base.metadata.create_all(bind=engine)
print('Database initialized')
"
EOF

sudo systemctl daemon-reload
sudo systemctl enable zsmanager-backend
sudo systemctl start zsmanager-backend
sudo systemctl restart nginx

# Wait and check
sleep 5

if sudo systemctl is-active --quiet zsmanager-backend; then
    log "✓ Backend service started"
else
    error "✗ Backend service failed to start"
fi

if sudo systemctl is-active --quiet nginx; then
    log "✓ Nginx started"
else
    error "✗ Nginx failed"
fi

# ============================================================================
# Complete
# ============================================================================

clear
echo "============================================================================"
echo "                    🎉 INSTALLATION COMPLETE! 🎉"
echo "============================================================================"
echo ""
echo "Zedin Steam Manager successfully installed!"
echo ""
echo "📍 Access:"
echo "   Web: http://$(hostname -I | awk '{print $1}')"
echo "   API: http://$(hostname -I | awk '{print $1}')/docs"
echo ""
echo "🔧 Management:"
echo "   Status: sudo systemctl status zsmanager-backend"
echo "   Logs: sudo journalctl -f -u zsmanager-backend"
echo "   Stop: sudo systemctl stop zsmanager-backend"
echo "   Start: sudo systemctl start zsmanager-backend"
echo ""
echo "📂 Paths:"
echo "   App: $INSTALL_DIR"
echo "   Data: $DATA_DIR"
echo "   Logs: $LOG_DIR"
echo ""
echo "============================================================================"