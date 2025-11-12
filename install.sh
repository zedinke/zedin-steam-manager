#!/bin/bash

# ============================================================================
# Zedin Steam Manager - Automatikus Telepítő Script
# Debian/Ubuntu rendszerekhez
# ============================================================================

set -e  # Exit on any error

# Színes output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
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
    error "Please do not run this script as root. Run as regular user with sudo privileges."
fi

# Check OS
if ! grep -E "(Ubuntu|Debian)" /etc/os-release > /dev/null 2>&1; then
    error "This installer is designed for Ubuntu/Debian systems only."
fi

# Variables
INSTALL_DIR="/opt/zedin-steam-manager"
SERVICE_USER="zedin"
LOG_DIR="/var/log/zedin"
DATA_DIR="/var/lib/zedin"
STEAMCMD_DIR="/opt/steamcmd"

echo "============================================================================"
echo "                    Zedin Steam Manager Installer                          "
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
read -p "Continue with installation? (y/N): " -n 1 -r
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
sudo apt install -y \
    curl \
    wget \
    gnupg2 \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    git \
    unzip \
    tar \
    htop \
    nano \
    vim \
    screen \
    tmux \
    ufw \
    fail2ban \
    logrotate

# Install Python 3.11+
log "Installing Python..."
sudo apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    build-essential

# Verify Python version
PYTHON_VERSION=$(python3 --version | grep -oE '[0-9]+\.[0-9]+' | head -1)
if [ "$(printf '%s\n' "3.9" "$PYTHON_VERSION" | sort -V | head -n1)" != "3.9" ]; then
    error "Python 3.9+ required. Current version: $PYTHON_VERSION"
fi

# Install Node.js 18+
log "Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verify Node.js version
NODE_VERSION=$(node --version | grep -oE '[0-9]+' | head -1)
if [ "$NODE_VERSION" -lt 18 ]; then
    error "Node.js 18+ required. Current version: $(node --version)"
fi

# Install SteamCMD dependencies
log "Installing SteamCMD dependencies..."
sudo dpkg --add-architecture i386
sudo apt update
sudo apt install -y \
    lib32gcc-s1 \
    libc6:i386 \
    libncurses5:i386 \
    libstdc++6:i386

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
if [ -d "$(pwd)/zedinsteammanager" ]; then
    log "Copying application files..."
    sudo cp -r $(pwd)/zedinsteammanager/* $INSTALL_DIR/
elif [ -d "$(pwd)/backend" ]; then
    log "Copying application files from current directory..."
    sudo cp -r $(pwd)/* $INSTALL_DIR/
else
    error "Application files not found. Please run this script from the project directory."
fi

# Set ownership
sudo chown -R $SERVICE_USER:$SERVICE_USER $INSTALL_DIR

# Switch to service user for application setup
sudo -u $SERVICE_USER bash << 'EOF'
cd /opt/zedin-steam-manager

# Create Python virtual environment
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
cd frontend && npm install && cd ..

# Build frontend for production
log "Building frontend..."
cd frontend && npm run build && cd ..

# Build Electron
log "Building Electron..."
npm run build:electron
EOF

# ============================================================================
# PHASE 4: Configuration Files
# ============================================================================

log "PHASE 4: Creating configuration files..."

# Environment configuration
sudo tee /etc/zedin/zedin.env > /dev/null << EOF
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
GITHUB_REPO=zedin/steam-manager
UPDATE_CHECK_INTERVAL=3600

# Monitoring
SYSTEM_MONITOR_INTERVAL=5

# Remote hosts
MAX_REMOTE_HOSTS=50
SSH_TIMEOUT=30
RCON_TIMEOUT=10
EOF

# Set permissions
sudo chown root:$SERVICE_USER /etc/zedin/zedin.env
sudo chmod 640 /etc/zedin/zedin.env

# ============================================================================
# PHASE 5: Systemd Services
# ============================================================================

log "PHASE 5: Setting up systemd services..."

# Backend service
sudo tee /etc/systemd/system/zedin-backend.service > /dev/null << EOF
[Unit]
Description=Zedin Steam Manager Backend
After=network.target
Wants=network.target

[Service]
Type=simple
User=$SERVICE_USER
Group=$SERVICE_USER
WorkingDirectory=$INSTALL_DIR/backend
Environment=PATH=$INSTALL_DIR/venv/bin
EnvironmentFile=/etc/zedin/zedin.env
ExecStart=$INSTALL_DIR/venv/bin/uvicorn main:app --host 0.0.0.0 --port 8000 --workers 2
ExecReload=/bin/kill -HUP \$MAINPID
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal
SyslogIdentifier=zedin-backend

# Security
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ReadWritePaths=$DATA_DIR $LOG_DIR $INSTALL_DIR
ProtectHome=true

[Install]
WantedBy=multi-user.target
EOF

# Frontend service (nginx will serve static files in production)
sudo tee /etc/systemd/system/zedin-frontend.service > /dev/null << EOF
[Unit]
Description=Zedin Steam Manager Frontend (Development)
After=network.target zedin-backend.service
Wants=zedin-backend.service

[Service]
Type=simple
User=$SERVICE_USER
Group=$SERVICE_USER
WorkingDirectory=$INSTALL_DIR/frontend
ExecStart=/usr/bin/npm run dev -- --host 0.0.0.0
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal
SyslogIdentifier=zedin-frontend

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
sudo systemctl daemon-reload

# Enable services
sudo systemctl enable zedin-backend

# ============================================================================
# PHASE 6: Web Server Setup (Nginx)
# ============================================================================

log "PHASE 6: Setting up Nginx..."

# Install Nginx
sudo apt install -y nginx

# Configure Nginx
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
        proxy_pass http://localhost:8000;
    }
}
EOF

# Enable site
sudo ln -sf /etc/nginx/sites-available/zedin-steam-manager /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test nginx config
sudo nginx -t

# ============================================================================
# PHASE 7: Firewall Setup
# ============================================================================

log "PHASE 7: Configuring firewall..."

# Enable UFW
sudo ufw --force enable

# Allow SSH
sudo ufw allow ssh

# Allow HTTP/HTTPS
sudo ufw allow 'Nginx Full'

# Allow custom ports for game servers (ARK default range)
sudo ufw allow 7777:7877/tcp
sudo ufw allow 7777:7877/udp
sudo ufw allow 27015:27115/tcp
sudo ufw allow 27015:27115/udp

# Allow RCON ports
sudo ufw allow 27020:27120/tcp

# ============================================================================
# PHASE 8: Logging Setup
# ============================================================================

log "PHASE 8: Setting up logging..."

# Logrotate configuration
sudo tee /etc/logrotate.d/zedin-steam-manager > /dev/null << EOF
$LOG_DIR/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 $SERVICE_USER $SERVICE_USER
    postrotate
        systemctl reload zedin-backend
    endscript
}
EOF

# ============================================================================
# PHASE 9: Backup System
# ============================================================================

log "PHASE 9: Setting up backup system..."

# Backup script
sudo tee $INSTALL_DIR/backup.sh > /dev/null << 'EOF'
#!/bin/bash

BACKUP_DIR="/var/lib/zedin/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/zedin_backup_$DATE.tar.gz"

# Create backup
tar -czf "$BACKUP_FILE" \
    --exclude="venv" \
    --exclude="node_modules" \
    --exclude="*.log" \
    -C /opt zedin-steam-manager \
    -C /var/lib zedin \
    -C /etc zedin

# Keep only last 7 backups
find "$BACKUP_DIR" -name "zedin_backup_*.tar.gz" -type f -mtime +7 -delete

echo "Backup created: $BACKUP_FILE"
EOF

sudo chmod +x $INSTALL_DIR/backup.sh
sudo chown $SERVICE_USER:$SERVICE_USER $INSTALL_DIR/backup.sh

# Daily backup cron job
sudo tee /etc/cron.d/zedin-backup > /dev/null << EOF
0 2 * * * $SERVICE_USER $INSTALL_DIR/backup.sh
EOF

# ============================================================================
# PHASE 10: Final Setup and Start
# ============================================================================

log "PHASE 10: Final setup and starting services..."

# Initialize database
sudo -u $SERVICE_USER bash << 'EOF'
cd /opt/zedin-steam-manager
source venv/bin/activate
cd backend
python -c "
from config.database import engine
from models import base
base.Base.metadata.create_all(bind=engine)
print('Database initialized successfully')
"
EOF

# Start services
log "Starting services..."
sudo systemctl start zedin-backend
sudo systemctl restart nginx

# Wait for services to start
sleep 5

# Check service status
if sudo systemctl is-active --quiet zedin-backend; then
    log "✓ Backend service started successfully"
else
    error "✗ Backend service failed to start"
fi

if sudo systemctl is-active --quiet nginx; then
    log "✓ Nginx started successfully"
else
    error "✗ Nginx failed to start"
fi

# ============================================================================
# Installation Complete
# ============================================================================

clear
echo "============================================================================"
echo "                    🎉 INSTALLATION COMPLETED! 🎉                         "
echo "============================================================================"
echo ""
echo "Zedin Steam Manager has been successfully installed!"
echo ""
echo "📍 Access Points:"
echo "   Web Interface: http://$(hostname -I | awk '{print $1}')"
echo "   API Documentation: http://$(hostname -I | awk '{print $1}')/docs"
echo "   Health Check: http://$(hostname -I | awk '{print $1}')/health"
echo ""
echo "📂 Important Directories:"
echo "   Application: $INSTALL_DIR"
echo "   Data: $DATA_DIR"
echo "   Logs: $LOG_DIR"
echo "   Config: /etc/zedin"
echo ""
echo "🔧 Service Management:"
echo "   Start: sudo systemctl start zedin-backend"
echo "   Stop: sudo systemctl stop zedin-backend"
echo "   Status: sudo systemctl status zedin-backend"
echo "   Logs: sudo journalctl -f -u zedin-backend"
echo ""
echo "💾 Backup:"
echo "   Manual: sudo -u $SERVICE_USER $INSTALL_DIR/backup.sh"
echo "   Auto: Daily at 2:00 AM"
echo ""
echo "🔐 Security:"
echo "   Firewall: Enabled (UFW)"
echo "   Service User: $SERVICE_USER (non-root)"
echo "   SSL: Configure with Let's Encrypt (optional)"
echo ""
echo "📋 Next Steps:"
echo "   1. Configure your domain name in Nginx"
echo "   2. Set up SSL certificate with Let's Encrypt"
echo "   3. Customize /etc/zedin/zedin.env as needed"
echo "   4. Add your first ASE/ASA servers"
echo ""
echo "Need help? Check the logs: sudo journalctl -f -u zedin-backend"
echo ""
echo "============================================================================"