#!/bin/bash

# ============================================================================
# Zedin Steam Manager - Simplified Production Installation Script
# Ubuntu/Debian systems - Uses pre-built frontend
# ============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Variables
INSTALL_DIR="/opt/zedin-steam-manager"
SERVICE_USER="zsmanager"
GITHUB_REPO="https://github.com/zedinke/zedin-steam-manager.git"

echo "============================================================================"
echo "          🚀 Zedin Steam Manager - Simplified Installer"
echo "============================================================================"
echo ""
echo "This installer will:"
echo "  1. Install system dependencies (Python, Nginx)"
echo "  2. Download latest code from GitHub"  
echo "  3. Install backend and deploy pre-built frontend"
echo "  4. Set up systemd service"
echo "  5. Configure web server"
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

# Install dependencies
log "Installing dependencies..."
sudo apt install -y python3 python3-pip python3-venv git nginx curl

log "✅ Dependencies installed successfully"

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
sudo mkdir -p $INSTALL_DIR
sudo mkdir -p /var/lib/zedin/{servers,shared_files,backups}
sudo mkdir -p /etc/zedin

# ============================================================================
# PHASE 3: Download Application
# ============================================================================

log "PHASE 3: Downloading application from GitHub..."

# Clone or update repository
if [ -d "$INSTALL_DIR/.git" ]; then
    log "Updating existing repository..."
    cd $INSTALL_DIR
    sudo -u $SERVICE_USER git fetch origin
    sudo -u $SERVICE_USER git reset --hard origin/main
else
    log "Cloning fresh repository..."
    sudo rm -rf $INSTALL_DIR
    sudo -u $SERVICE_USER git clone $GITHUB_REPO $INSTALL_DIR
fi

cd $INSTALL_DIR
sudo chown -R $SERVICE_USER:$SERVICE_USER $INSTALL_DIR

log "✅ Application downloaded successfully"

# ============================================================================
# PHASE 4: Install Backend
# ============================================================================

log "PHASE 4: Installing backend..."

# Install Python dependencies  
log "Installing Python dependencies..."
cd $INSTALL_DIR
sudo -u $SERVICE_USER python3 -m venv venv
sudo -u $SERVICE_USER bash -c "source venv/bin/activate && cd backend && pip install -r requirements.txt"

log "✅ Backend installed successfully"

# ============================================================================
# PHASE 5: Deploy Frontend
# ============================================================================

log "PHASE 5: Deploying simplified frontend..."

# Ensure frontend dist directory exists
sudo mkdir -p $INSTALL_DIR/frontend/dist

# The simplified HTML should already be in the repository
if [ -f "$INSTALL_DIR/frontend/dist/index.html" ]; then
    log "✅ Pre-built frontend found and ready"
else
    error "Frontend build not found in repository. Check repository sync."
fi

# Set proper permissions
sudo chown -R $SERVICE_USER:$SERVICE_USER $INSTALL_DIR/frontend

# ============================================================================
# PHASE 6: Configuration
# ============================================================================

log "PHASE 6: Creating configuration..."

# Environment file
sudo tee /etc/zedin/zsmanager.env > /dev/null << EOF
APP_NAME=Zedin Steam Manager
VERSION=0.000001
DEBUG=False
HOST=0.0.0.0
PORT=8000
DATABASE_URL=sqlite:///var/lib/zedin/zedin_steam_manager.db
SECRET_KEY=$(openssl rand -hex 32)
EOF

sudo chmod 640 /etc/zedin/zsmanager.env

# ============================================================================
# PHASE 7: Services
# ============================================================================

log "PHASE 7: Setting up services..."

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
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

# Nginx configuration
sudo tee /etc/nginx/sites-available/zsmanager > /dev/null << 'EOF'
server {
    listen 80 default_server;
    server_name _;
    root /opt/zedin-steam-manager/frontend/dist;
    index index.html;

    # Frontend
    location / {
        try_files $uri $uri/ /index.html;
        add_header Cache-Control "no-cache";
    }

    # API proxy
    location /api/ {
        proxy_pass http://127.0.0.1:8000/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Health check
    location /health {
        proxy_pass http://127.0.0.1:8000/health;
    }

    # API docs
    location /docs {
        proxy_pass http://127.0.0.1:8000/docs;
    }
}
EOF

# Enable site
sudo rm -f /etc/nginx/sites-enabled/default
sudo ln -sf /etc/nginx/sites-available/zsmanager /etc/nginx/sites-enabled/

# Test nginx configuration
if ! sudo nginx -t; then
    error "Nginx configuration test failed"
fi

# ============================================================================
# PHASE 8: Initialize Database
# ============================================================================

log "PHASE 8: Initializing database..."

sudo -u $SERVICE_USER bash << 'EOF'
cd /opt/zedin-steam-manager
source venv/bin/activate
cd backend
python3 -c "
try:
    from config.database import engine
    from models import base
    base.Base.metadata.create_all(bind=engine)
    print('✅ Database initialized')
except Exception as e:
    print(f'❌ Database initialization failed: {e}')
    exit(1)
"
EOF

# ============================================================================
# PHASE 9: Start Services
# ============================================================================

log "PHASE 9: Starting services..."

# Reload systemd and start services
sudo systemctl daemon-reload
sudo systemctl enable zsmanager-backend
sudo systemctl start zsmanager-backend

# Start nginx
sudo systemctl restart nginx

# Wait for services
sleep 5

# Check status
BACKEND_STATUS="❌ Failed"
NGINX_STATUS="❌ Failed"

if sudo systemctl is-active --quiet zsmanager-backend; then
    BACKEND_STATUS="✅ Running"
fi

if sudo systemctl is-active --quiet nginx; then
    NGINX_STATUS="✅ Running"
fi

# Test API
API_STATUS="❌ Not responding"
if curl -s http://localhost:8000/api/health >/dev/null 2>&1; then
    API_STATUS="✅ API responding"
fi

# Test frontend
FRONTEND_STATUS="❌ Not accessible"
if curl -s http://localhost/ >/dev/null 2>&1; then
    FRONTEND_STATUS="✅ Frontend accessible"
fi

# ============================================================================
# Installation Complete
# ============================================================================

clear
echo "============================================================================"
echo "                    🎉 INSTALLATION COMPLETE! 🎉"
echo "============================================================================"
echo ""
echo "📊 Status:"
echo "   Backend: $BACKEND_STATUS"
echo "   Nginx: $NGINX_STATUS"
echo "   API: $API_STATUS"  
echo "   Frontend: $FRONTEND_STATUS"
echo ""
echo "🌐 Access:"
echo "   Web Interface: http://$(hostname -I | awk '{print $1}')"
echo "   API Docs: http://$(hostname -I | awk '{print $1}')/docs"
echo ""
echo "🔧 Management:"
echo "   Status: sudo systemctl status zsmanager-backend"
echo "   Logs: sudo journalctl -f -u zsmanager-backend"
echo "   Restart: sudo systemctl restart zsmanager-backend"
echo ""
echo "🔄 Updates:"
echo "   Update: cd $INSTALL_DIR && sudo ./update.sh"
echo "   Debug: sudo ./debug-service.sh"
echo ""
if [ "$BACKEND_STATUS" = "✅ Running" ] && [ "$NGINX_STATUS" = "✅ Running" ]; then
    echo "🎯 Ready to use! Open your browser to:"
    echo "   http://$(hostname -I | awk '{print $1}')"
else
    echo "⚠️  Some services need attention:"
    echo "   Check logs: sudo journalctl -f -u zsmanager-backend"
fi
echo ""
echo "============================================================================"

log "Simplified installation completed!"