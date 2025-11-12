#!/bin/bash

# ============================================================================
# Zedin Steam Manager - Simple Installation Script
# Skip problematic components for quick setup
# ============================================================================

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

# Check user
if [ "$EUID" -eq 0 ]; then
    error "Please do not run as root. Use a regular user with sudo privileges."
fi

# Variables
INSTALL_DIR="/opt/zedin-steam-manager"
SERVICE_USER="zsmanager"
LOG_DIR="/var/log/zedin"
DATA_DIR="/var/lib/zedin"

echo "============================================================================"
echo "                    Zedin Steam Manager - Simple Install"
echo "============================================================================"

log "PHASE 1: Installing basic dependencies..."
sudo apt update
sudo apt install -y python3 python3-pip python3-venv nodejs npm git nginx curl

log "PHASE 2: Creating user and directories..."
# Create user if not exists
if ! id "$SERVICE_USER" &>/dev/null; then
    sudo useradd -r -m -g users -s /bin/bash $SERVICE_USER
    log "Created user: $SERVICE_USER"
fi

# Create directories
sudo mkdir -p $INSTALL_DIR $LOG_DIR $DATA_DIR/{servers,shared_files,backups} /etc/zedin
sudo chown -R $SERVICE_USER:users $INSTALL_DIR $DATA_DIR $LOG_DIR

log "PHASE 3: Installing application..."
# Copy files - check current directory first
CURRENT_DIR=$(pwd)
log "Current directory: $CURRENT_DIR"
log "Directory contents:"
ls -la

# Check if we're in the right directory
if [ -d "backend" ] && [ -d "frontend" ]; then
    log "Found application files in current directory"
    sudo cp -r * $INSTALL_DIR/
    sudo chown -R $SERVICE_USER:users $INSTALL_DIR
elif [ -d "../backend" ] && [ -d "../frontend" ]; then
    log "Found application files in parent directory"
    sudo cp -r ../* $INSTALL_DIR/
    sudo chown -R $SERVICE_USER:users $INSTALL_DIR
else
    log "Searching for application files..."
    # Try to find the project directory
    PROJECT_DIR=""
    for dir in /home/*/zedin-steam-manager /tmp/zedin-steam-manager /opt/zedin-steam-manager /zedin-steam-manager; do
        if [ -d "$dir/backend" ] && [ -d "$dir/frontend" ]; then
            PROJECT_DIR="$dir"
            break
        fi
    done
    
    if [ -n "$PROJECT_DIR" ]; then
        log "Found project directory at: $PROJECT_DIR"
        sudo cp -r $PROJECT_DIR/* $INSTALL_DIR/
        sudo chown -R $SERVICE_USER:users $INSTALL_DIR
    else
        error "Application files not found. Please run from the project directory or ensure backend/ and frontend/ exist"
    fi
fi

log "PHASE 4: Installing Python dependencies..."
sudo -u $SERVICE_USER bash << 'EOF'
cd /opt/zedin-steam-manager
python3 -m venv venv
source venv/bin/activate
cd backend
pip install --upgrade pip
pip install -r requirements.txt
EOF

log "PHASE 5: Installing Node.js dependencies..."
sudo -u $SERVICE_USER bash << 'EOF'
cd /opt/zedin-steam-manager/frontend
npm install
npm run build
EOF

log "PHASE 6: Creating configuration..."
sudo tee /etc/zedin/zsmanager.env > /dev/null << EOF
APP_NAME=Zedin Steam Manager
VERSION=0.000001
HOST=0.0.0.0
PORT=8000
DATABASE_URL=sqlite:///$DATA_DIR/zedin_steam_manager.db
SECRET_KEY=$(openssl rand -hex 32)
SERVERS_PATH=$DATA_DIR/servers
LOG_FILE=$LOG_DIR/steam_manager.log
EOF
sudo chown $SERVICE_USER:users /etc/zedin/zsmanager.env

log "PHASE 7: Creating systemd service..."
sudo tee /etc/systemd/system/zsmanager-backend.service > /dev/null << EOF
[Unit]
Description=Zedin Steam Manager Backend
After=network.target

[Service]
Type=simple
User=$SERVICE_USER
WorkingDirectory=$INSTALL_DIR/backend
Environment=PATH=$INSTALL_DIR/venv/bin
EnvironmentFile=/etc/zedin/zsmanager.env
ExecStart=$INSTALL_DIR/venv/bin/uvicorn main:app --host 0.0.0.0 --port 8000
Restart=always

[Install]
WantedBy=multi-user.target
EOF

log "PHASE 8: Configuring Nginx..."
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
    }

    location /docs {
        proxy_pass http://localhost:8000;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/zedin-steam-manager /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t

log "PHASE 9: Starting services..."
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

sleep 3

# Check services
if sudo systemctl is-active --quiet zsmanager-backend; then
    log "✓ Backend service started"
else
    log "✗ Backend service issue - check logs: sudo journalctl -u zsmanager-backend"
fi

if sudo systemctl is-active --quiet nginx; then
    log "✓ Nginx started"
else
    log "✗ Nginx issue - check logs: sudo journalctl -u nginx"
fi

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
echo ""
echo "Note: SteamCMD skipped for quick setup - install manually if needed"
echo "============================================================================"