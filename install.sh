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

#!/bin/bash

# ============================================================================
# Zedin Steam Manager - Production Installation Script
# Ubuntu/Debian systems - Complete setup with all features
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
echo "  5. Configure firewall and web server"
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
    ca-certificates git unzip tar htop nano vim screen tmux ufw fail2ban logrotate \
    build-essential

# Install Python 3.9+
log "Installing Python..."
sudo apt install -y python3 python3-pip python3-venv python3-dev

# Fix Node.js conflicts and install clean version
log "Installing Node.js (fixing conflicts)..."
sudo apt remove --purge nodejs npm -y 2>/dev/null || true
sudo apt autoremove -y
sudo apt autoclean

# Install Node.js from NodeSource
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Verify installations
PYTHON_VERSION=$(python3 --version | grep -oE '[0-9]+\.[0-9]+' | head -1)
NODE_VERSION=$(node --version | grep -oE '[0-9]+' | head -1)

if [ "$(printf '%s\n' "3.9" "$PYTHON_VERSION" | sort -V | head -n1)" != "3.9" ]; then
    error "Python 3.9+ required. Current version: $PYTHON_VERSION"
fi

if [ "$NODE_VERSION" -lt 18 ]; then
    error "Node.js 18+ required. Current version: $(node --version)"
fi

log "✓ Python $PYTHON_VERSION and Node.js $(node --version) installed successfully"

# Install SteamCMD dependencies
log "Installing SteamCMD dependencies..."
sudo dpkg --add-architecture i386
sudo apt update
sudo apt install -y lib32gcc-s1 libc6:i386 libncurses5:i386 libstdc++6:i386

# Install SteamCMD with better error handling
log "Installing SteamCMD..."
sudo mkdir -p $STEAMCMD_DIR

# Save current directory before changing to /tmp
ORIGINAL_DIR=$(pwd)
cd /tmp
sudo rm -f steamcmd.tar.gz* 2>/dev/null || true

if wget -q -O steamcmd.tar.gz https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz; then
    sudo tar -xzf steamcmd.tar.gz -C $STEAMCMD_DIR
    sudo chown -R root:root $STEAMCMD_DIR
    sudo chmod +x $STEAMCMD_DIR/steamcmd.sh
    log "✓ SteamCMD installed successfully"
else
    warning "SteamCMD download failed - continuing without it (can be installed manually later)"
fi

# Return to original directory
cd "$ORIGINAL_DIR"

# Install Nginx
log "Installing Nginx..."
sudo apt install -y nginx

# ============================================================================
# PHASE 2: User and Directory Setup
# ============================================================================

log "PHASE 2: Setting up user and directories..."

# Create service user
if ! id "$SERVICE_USER" &>/dev/null; then
    log "Creating service user: $SERVICE_USER"
    sudo useradd -r -s /bin/bash -d $INSTALL_DIR -m $SERVICE_USER
    sudo usermod -aG sudo $SERVICE_USER
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

# Verify we're in the right directory and copy files
CURRENT_DIR=$(pwd)
log "Current directory: $CURRENT_DIR"

if [ -d "backend" ] && [ -d "frontend" ]; then
    log "Found application files - copying to $INSTALL_DIR"
    sudo cp -r * $INSTALL_DIR/
    sudo chown -R $SERVICE_USER:$SERVICE_USER $INSTALL_DIR
    log "✓ Application files copied successfully"
else
    error "Application files not found. Please run this script from the project directory containing backend/ and frontend/ folders."
fi

# Install Python dependencies
log "Installing Python dependencies..."
sudo -u $SERVICE_USER bash << 'EOF'
cd /opt/zedin-steam-manager
python3 -m venv venv
source venv/bin/activate
cd backend
pip install --upgrade pip
pip install -r requirements.txt
cd ..
echo "✓ Python dependencies installed"
EOF

# Install Node.js dependencies and build frontend
log "Installing Node.js dependencies and building frontend..."
sudo -u $SERVICE_USER bash << 'EOF'
cd /opt/zedin-steam-manager

# Root dependencies
npm install

# Frontend dependencies and build
cd frontend
npm install
npm run build
cd ..

echo "✓ Frontend built successfully"
EOF

# ============================================================================
# PHASE 4: Configuration
# ============================================================================

log "PHASE 4: Creating configuration files..."

# Environment file
sudo tee /etc/zedin/zsmanager.env > /dev/null << EOF
# Zedin Steam Manager Configuration
APP_NAME=Zedin Steam Manager
VERSION=0.000001
DEBUG=False

# Server
HOST=0.0.0.0
PORT=8000

# Database
DATABASE_URL=sqlite:///$DATA_DIR/zedin_steam_manager.db

# Security
SECRET_KEY=$(openssl rand -hex 32)
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=1440

# Paths
STEAMCMD_PATH=$STEAMCMD_DIR
SHARED_FILES_PATH=$DATA_DIR/shared_files
SERVERS_PATH=$DATA_DIR/servers
LOG_FILE=$LOG_DIR/steam_manager.log

# Steam Apps
ASE_APP_ID=376030
ASA_APP_ID=2430930

# GitHub
GITHUB_REPO=zedinke/zedin-steam-manager
UPDATE_CHECK_INTERVAL=3600

# Monitoring
SYSTEM_MONITOR_INTERVAL=5

# Remote hosts
MAX_REMOTE_HOSTS=50
SSH_TIMEOUT=30
RCON_TIMEOUT=10
EOF

sudo chown root:$SERVICE_USER /etc/zedin/zsmanager.env
sudo chmod 640 /etc/zedin/zsmanager.env

# ============================================================================
# PHASE 5: Frontend Build & Web Server
# ============================================================================

log "PHASE 5: Building frontend and configuring web server..."

# Install nginx
log "Installing nginx..."
sudo apt install -y nginx

# Build frontend
log "Building frontend application..."
cd "$INSTALL_DIR/frontend"
sudo -u $SERVICE_USER npm install
sudo -u $SERVICE_USER npm run build

# Create nginx configuration
log "Creating nginx configuration..."
sudo tee /etc/nginx/sites-available/zsmanager > /dev/null << 'EOF'
server {
    listen 80;
    server_name _;
    root /opt/zedin-steam-manager/frontend/dist;
    index index.html;

    # Frontend static files
    location / {
        try_files $uri $uri/ /index.html;
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
    }

    # API proxy
    location /api/ {
        proxy_pass http://127.0.0.1:8000/api/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }

    # Health check
    location /health {
        proxy_pass http://127.0.0.1:8000/health;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # API docs
    location /docs {
        proxy_pass http://127.0.0.1:8000/docs;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied expired no-cache no-store private no_last_modified no_etag auth;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/javascript;
}
EOF

# Remove default nginx site
sudo rm -f /etc/nginx/sites-enabled/default

# Enable zsmanager site
sudo ln -sf /etc/nginx/sites-available/zsmanager /etc/nginx/sites-enabled/

# Test nginx configuration
sudo nginx -t

# ============================================================================
# PHASE 6: Services
# ============================================================================

log "PHASE 6: Setting up systemd services..."

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

# Security
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ReadWritePaths=$DATA_DIR $LOG_DIR $INSTALL_DIR
ProtectHome=true

[Install]
WantedBy=multi-user.target
EOF

# ============================================================================
# PHASE 6: Web Server
# ============================================================================

log "PHASE 6: Configuring Nginx..."

sudo tee /etc/nginx/sites-available/zedin-steam-manager > /dev/null << 'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name _;

    # Frontend static files
    location / {
        root /opt/zedin-steam-manager/frontend/dist;
        index index.html;
        try_files $uri $uri/ /index.html;
        
        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }

    # API proxy
    location /api/ {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    # API docs
    location /docs {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Health check
    location /health {
        proxy_pass http://localhost:8000/api/health;
    }
}
EOF

# Enable site
sudo ln -sf /etc/nginx/sites-available/zedin-steam-manager /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test nginx config
if ! sudo nginx -t; then
    error "Nginx configuration test failed"
fi

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
# PHASE 8: Initialize and Start Services
# ============================================================================

log "PHASE 8: Starting services..."

# Initialize database
log "Initializing database..."
sudo -u $SERVICE_USER bash << 'EOF'
cd /opt/zedin-steam-manager
source venv/bin/activate
cd backend
python3 -c "
try:
    from config.database import engine
    from models import base
    base.Base.metadata.create_all(bind=engine)
    print('✓ Database initialized successfully')
except Exception as e:
    print(f'✗ Database initialization failed: {e}')
    exit(1)
"
EOF

sudo systemctl daemon-reload
sudo systemctl enable zsmanager-backend
sudo systemctl start zsmanager-backend
sudo systemctl restart nginx

# Wait for services to start
sleep 5

# Check service status
BACKEND_STATUS="✗ Failed"
NGINX_STATUS="✗ Failed"

if sudo systemctl is-active --quiet zsmanager-backend; then
    BACKEND_STATUS="✓ Running"
else
    log "Backend service issue - checking logs..."
    sudo journalctl -u zsmanager-backend --no-pager -n 10
fi

if sudo systemctl is-active --quiet nginx; then
    NGINX_STATUS="✓ Running"
else
    log "Nginx service issue - checking logs..."
    sudo journalctl -u nginx --no-pager -n 10
fi

# Test connectivity
API_STATUS="✗ Not responding"
if curl -s http://localhost:8000/api/health >/dev/null 2>&1; then
    API_STATUS="✓ API responding"
fi

FRONTEND_STATUS="✗ Not accessible"
if curl -s http://localhost/ >/dev/null 2>&1; then
    FRONTEND_STATUS="✓ Frontend accessible"
fi

# ============================================================================
# Installation Complete
# ============================================================================

clear
echo "============================================================================"
echo "                    🎉 INSTALLATION COMPLETE! 🎉"
echo "============================================================================"
echo ""
echo "Zedin Steam Manager has been successfully installed!"
echo ""
echo "📊 Service Status:"
echo "   Backend: $BACKEND_STATUS"
echo "   Nginx: $NGINX_STATUS"
echo "   API: $API_STATUS"
echo "   Frontend: $FRONTEND_STATUS"
echo ""
echo "📍 Access Points:"
echo "   Web Interface: http://$(hostname -I | awk '{print $1}')"
echo "   API Documentation: http://$(hostname -I | awk '{print $1}')/docs"
echo "   Health Check: http://$(hostname -I | awk '{print $1}')/health"
echo ""
echo "🔧 Service Management:"
echo "   Status: sudo systemctl status zsmanager-backend"
echo "   Logs: sudo journalctl -f -u zsmanager-backend"
echo "   Stop: sudo systemctl stop zsmanager-backend"
echo "   Start: sudo systemctl start zsmanager-backend"
echo "   Restart: sudo systemctl restart zsmanager-backend"
echo ""
echo "📂 Important Directories:"
echo "   Application: $INSTALL_DIR"
echo "   Data: $DATA_DIR"
echo "   Logs: $LOG_DIR"
echo "   Config: /etc/zedin"
echo ""
echo "🔐 Security Features:"
echo "   Firewall: Enabled (UFW)"
echo "   Service User: $SERVICE_USER (non-root)"
echo "   Game Server Ports: 7777-7877 (TCP/UDP)"
echo ""
if [ "$BACKEND_STATUS" = "✓ Running" ] && [ "$NGINX_STATUS" = "✓ Running" ]; then
    echo "🎯 Ready to use! Open your web browser and go to:"
    echo "   http://$(hostname -I | awk '{print $1}')"
    echo ""
    echo "   Default login will be created on first access."
else
    echo "⚠️  Some services need attention. Check the logs above."
    echo "   Troubleshooting: sudo journalctl -f -u zsmanager-backend"
fi
echo ""
echo "============================================================================"

# ============================================================================
# PHASE 7: Firewall & SteamCMD
# ============================================================================

log "PHASE 7: Configuring firewall and installing SteamCMD..."

# Install SteamCMD
log "Installing SteamCMD..."
ORIGINAL_DIR=$(pwd)
sudo mkdir -p $STEAMCMD_DIR
cd /tmp
sudo rm -f steamcmd.tar.gz*  # Remove any existing files
wget -q -O steamcmd.tar.gz https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz || \
    wget -q -O steamcmd.tar.gz http://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
if [ -f steamcmd.tar.gz ]; then
    sudo tar -xzf steamcmd.tar.gz -C $STEAMCMD_DIR
    sudo chown -R root:root $STEAMCMD_DIR
    sudo chmod +x $STEAMCMD_DIR/steamcmd.sh
    log "SteamCMD installed successfully"
else
    error "Failed to download SteamCMD"
fi
cd "$ORIGINAL_DIR"

# Configure UFW firewall
log "Configuring firewall..."
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 7777:7877/tcp
sudo ufw allow 7777:7877/udp
sudo ufw --force enable

# ============================================================================
# PHASE 8: Service Startup & Testing
# ============================================================================

log "PHASE 8: Starting services..."

# Start services
sudo systemctl daemon-reload
sudo systemctl enable zsmanager-backend nginx
sudo systemctl start zsmanager-backend
sudo systemctl restart nginx

# Wait for services to start
sleep 5
else
    warning "SteamCMD download failed, but continuing installation..."
fi

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

sudo chown root:$SERVICE_USER /etc/zedin/zsmanager.env
sudo chmod 640 /etc/zedin/zsmanager.env

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