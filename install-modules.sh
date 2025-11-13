#!/bin/bash
# Zedin Steam Manager - Main Installer Module
# Source this file for common functions and variables

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Global variables
INSTALL_DIR="/opt/zedin-steam-manager"
SERVICE_USER="zsmanager"
STEAMCMD_DIR="/opt/steamcmd"
LOG_DIR="/var/log/zedin"
DATA_DIR="/var/lib/zedin"
GITHUB_REPO="https://github.com/zedinke/zedin-steam-manager.git"

# Logging functions
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
check_root() {
    if [ "$EUID" -eq 0 ]; then
        error "Please do not run this script as root. Use a regular user with sudo privileges."
    fi
}

# Check OS compatibility
check_os() {
    if ! grep -E "(Ubuntu|Debian)" /etc/os-release > /dev/null 2>&1; then
        error "This installer supports Ubuntu/Debian systems only."
    fi
}

# Show installation banner
show_banner() {
    echo "============================================================================"
    echo "          🚀 Zedin Steam Manager - Professional Installer"
    echo "============================================================================"
    echo ""
    echo "Installation Mode: $1"
    echo ""
}

# Confirm installation
confirm_installation() {
    echo "This installer will:"
    echo "  • Install system dependencies"
    echo "  • Set up user and directories"  
    echo "  • Download and configure application"
    echo "  • Configure services and web server"
    echo "  • Set up monitoring and updates"
    echo ""
    echo -n "Continue with installation? (y/N): "
    read -r REPLY
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Installation cancelled by user"
        exit 1
    fi
}

# Install system dependencies
install_system_deps() {
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
    
    # Install Node.js from NodeSource (LTS version)
    log "Installing Node.js 20.x LTS..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt install -y nodejs
    
    # Verify installations
    PYTHON_VERSION=$(python3 --version | grep -oE '[0-9]+\.[0-9]+' | head -1)
    NODE_VERSION=$(node --version | grep -oE '[0-9]+' | head -1)
    
    if [ "$(printf '%s\n' "3.9" "$PYTHON_VERSION" | sort -V | head -n1)" != "3.9" ]; then
        error "Python 3.9+ required. Current version: $PYTHON_VERSION"
    fi
    
    if [ "$NODE_VERSION" -lt 20 ]; then
        error "Node.js 20+ required. Current version: $(node --version)"
    fi
    
    log "✅ Python $PYTHON_VERSION and Node.js $(node --version) installed successfully"
    
    # Install Nginx
    log "Installing Nginx..."
    sudo apt install -y nginx
    
    # Check if nginx is already running
    if sudo systemctl is-active --quiet nginx; then
        log "Nginx is already running - stopping it temporarily for configuration"
        sudo systemctl stop nginx
    fi
    
    install_steamcmd
    log "✅ System dependencies installed"
}

# Create user and directories
setup_user_dirs() {
    log "Setting up user and directories..."
    
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
    sudo chown -R $SERVICE_USER:$SERVICE_USER $INSTALL_DIR
    
    log "✅ User and directories created"
}

# Download or copy application
download_app() {
    log "Setting up application files..."
    
    # Check if we're running from the target directory
    if [ "$(pwd)" = "$INSTALL_DIR" ]; then
        log "Running from target directory - files already in place"
        # Ensure proper ownership
        sudo chown -R $SERVICE_USER:$SERVICE_USER $INSTALL_DIR
    elif [ -d "$INSTALL_DIR/.git" ]; then
        # Update existing installation
        log "Updating existing installation..."
        cd $INSTALL_DIR
        sudo -u $SERVICE_USER git fetch origin
        sudo -u $SERVICE_USER git reset --hard origin/main
        sudo chown -R $SERVICE_USER:$SERVICE_USER $INSTALL_DIR
    else
        # Fresh installation - try to copy from current directory first
        if [ -f "$(pwd)/main.py" ] || [ -d "$(pwd)/backend" ]; then
            log "Copying application files from current directory..."
            sudo mkdir -p $INSTALL_DIR
            sudo cp -r * $INSTALL_DIR/
            sudo chown -R $SERVICE_USER:$SERVICE_USER $INSTALL_DIR
        else
            # Download from GitHub
            log "Downloading application from GitHub..."
            sudo rm -rf $INSTALL_DIR
            sudo -u $SERVICE_USER git clone $GITHUB_REPO $INSTALL_DIR
            sudo chown -R $SERVICE_USER:$SERVICE_USER $INSTALL_DIR
        fi
    fi
    
    log "✅ Application files ready"
}

# Install backend
install_backend() {
    log "Installing Python backend..."
    
    cd $INSTALL_DIR
    sudo -u $SERVICE_USER python3 -m venv venv
    sudo -u $SERVICE_USER bash -c "source venv/bin/activate && cd backend && pip install -r requirements.txt"
    
    log "✅ Backend installed"
}

# Deploy frontend
deploy_frontend() {
    log "Deploying frontend..."
    
    # Copy minimal frontend as main index
    if [ -f "$INSTALL_DIR/minimal-frontend.html" ]; then
        log "Using minimal frontend solution for maximum compatibility"
        sudo cp "$INSTALL_DIR/minimal-frontend.html" "$INSTALL_DIR/frontend/dist/index.html"
    elif [ ! -f "$INSTALL_DIR/frontend/dist/index.html" ]; then
        error "Frontend build not found. Repository sync issue."
    fi
    
    sudo chown -R $SERVICE_USER:$SERVICE_USER $INSTALL_DIR/frontend
    log "✅ Frontend deployed"
}

# Create configurations
create_config() {
    log "Creating configuration files..."
    
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
    log "✅ Configuration created"
}

# Setup services
setup_services() {
    log "Setting up systemd services..."
    
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

    log "✅ Services configured"
}

# Configure nginx
setup_nginx() {
    log "Configuring Nginx..."
    
    sudo tee /etc/nginx/sites-available/zsmanager > /dev/null << 'EOF'
server {
    listen 80 default_server;
    server_name _;
    root /opt/zedin-steam-manager/frontend/dist;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
        add_header Cache-Control "no-cache";
    }

    location /api/ {
        proxy_pass http://127.0.0.1:8000/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /health {
        proxy_pass http://127.0.0.1:8000/health;
    }

    location /docs {
        proxy_pass http://127.0.0.1:8000/docs;
    }
}
EOF

    sudo rm -f /etc/nginx/sites-enabled/default
    sudo ln -sf /etc/nginx/sites-available/zsmanager /etc/nginx/sites-enabled/
    
    if ! sudo nginx -t; then
        error "Nginx configuration test failed"
    fi
    
    log "✅ Nginx configured"
}

# Initialize database
init_database() {
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
    print('✅ Database initialized')
except Exception as e:
    print(f'❌ Database initialization failed: {e}')
    exit(1)
"
EOF
}

# Start services
start_services() {
    log "Starting services..."
    
    sudo systemctl daemon-reload
    sudo systemctl enable zsmanager-backend
    sudo systemctl start zsmanager-backend
    sudo systemctl restart nginx
    
    sleep 5
    log "✅ Services started"
}

# Check service status
check_status() {
    BACKEND_STATUS="❌ Failed"
    NGINX_STATUS="❌ Failed"
    API_STATUS="❌ Not responding"
    FRONTEND_STATUS="❌ Not accessible"
    
    if sudo systemctl is-active --quiet zsmanager-backend; then
        BACKEND_STATUS="✅ Running"
    fi
    
    if sudo systemctl is-active --quiet nginx; then
        NGINX_STATUS="✅ Running"
    fi
    
    if curl -s http://localhost:8000/api/health >/dev/null 2>&1; then
        API_STATUS="✅ API responding"
    fi
    
    if curl -s http://localhost/ >/dev/null 2>&1; then
        FRONTEND_STATUS="✅ Frontend accessible"
    fi
    
    export BACKEND_STATUS NGINX_STATUS API_STATUS FRONTEND_STATUS
}

# Show completion message
show_completion() {
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
}

# Export functions for other scripts
export -f log error warning info
export -f check_root check_os show_banner confirm_installation
export -f install_system_deps setup_user_dirs download_app
export -f install_backend deploy_frontend create_config
export -f setup_services setup_nginx init_database start_services
export -f check_status show_completion

# Install SteamCMD
install_steamcmd() {
    log "Installing SteamCMD..."
    
    sudo dpkg --add-architecture i386
    sudo apt update
    sudo apt install -y lib32gcc-s1 libc6:i386 libncurses5:i386 libstdc++6:i386
    
    sudo mkdir -p $STEAMCMD_DIR
    ORIGINAL_DIR=$(pwd)
    cd /tmp
    sudo rm -f steamcmd.tar.gz* 2>/dev/null || true
    
    if wget -q -O steamcmd.tar.gz https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz; then
        sudo tar -xzf steamcmd.tar.gz -C $STEAMCMD_DIR
        sudo chown -R root:root $STEAMCMD_DIR
        sudo chmod +x $STEAMCMD_DIR/steamcmd.sh
        log "✅ SteamCMD installed successfully"
    else
        warning "SteamCMD download failed - continuing without it"
    fi
    
    cd "$ORIGINAL_DIR"
}

# Setup services
setup_services() {
    log "Setting up systemd services..."
    
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
ReadWritePaths=/var/lib/zedin /var/log/zedin $INSTALL_DIR
ProtectHome=true

[Install]
WantedBy=multi-user.target
EOF

    log "✅ Services configured"
}

# Setup Nginx
setup_nginx() {
    log "Setting up Nginx..."
    
    # Remove default configurations
    sudo rm -f /etc/nginx/sites-enabled/default
    sudo rm -f /etc/nginx/sites-available/default
    sudo rm -f /etc/nginx/conf.d/default.conf
    
    sudo tee /etc/nginx/sites-available/zsmanager > /dev/null << 'EOF'
server {
    listen 80 default_server;
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
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # API docs
    location /docs {
        proxy_pass http://127.0.0.1:8000/docs;
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

    sudo ln -sf /etc/nginx/sites-available/zsmanager /etc/nginx/sites-enabled/
    
    if ! sudo nginx -t; then
        error "Nginx configuration test failed"
    fi
    
    log "✅ Nginx configured"
}

# Initialize database
init_database() {
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
    print('✅ Database initialized successfully')
except Exception as e:
    print(f'❌ Database initialization failed: {e}')
    exit(1)
"
EOF
    
    log "✅ Database ready"
}

# Start services
start_services() {
    log "Starting services..."
    
    sudo systemctl daemon-reload
    sudo systemctl enable zsmanager-backend nginx
    
    if sudo systemctl start zsmanager-backend; then
        log "✅ Backend service started"
    else
        error "Failed to start backend service"
    fi
    
    if sudo systemctl restart nginx; then
        log "✅ Nginx service started" 
    else
        error "Failed to start nginx"
    fi
    
    # Configure firewall
    sudo ufw --force enable
    sudo ufw allow ssh
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    sudo ufw allow 7777:7877/tcp
    sudo ufw allow 7777:7877/udp
    
    sleep 3
}
export -f log error warning info check_root check_os show_banner
export -f install_system_deps setup_user_dirs download_app install_backend
export -f deploy_frontend create_config setup_services setup_nginx
export -f init_database start_services check_status show_completion