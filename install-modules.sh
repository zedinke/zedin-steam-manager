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
        sudo -u $SERVICE_USER git clean -fdx
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
    log "PHASE 4: Installing Python backend..."
    
    cd $INSTALL_DIR
    
    # Create virtual environment
    log "Creating Python virtual environment..."
    sudo -u $SERVICE_USER python3 -m venv venv
    
    # Install backend dependencies
    log "Installing backend dependencies..."
    if [ ! -f "backend/requirements.txt" ]; then
        error "backend/requirements.txt not found"
    fi
    
    sudo -u $SERVICE_USER bash -c "source venv/bin/activate && cd backend && pip install --upgrade pip && pip install -r requirements.txt"
    
    # Verify critical packages
    log "Verifying installation..."
    sudo -u $SERVICE_USER bash -c "source venv/bin/activate && python -c 'import fastapi, uvicorn, sqlalchemy; print(\"✓ Core packages OK\")'" || error "Failed to import core packages"
    
    log "✅ Backend installed"
}

# Deploy frontend
deploy_frontend() {
    log "PHASE 5: Deploying frontend..."
    
    cd $INSTALL_DIR/frontend
    
    # Clean any potential old files or caches
    log "Cleaning frontend build cache and old files..."
    sudo -u $SERVICE_USER rm -rf .vite node_modules/.vite dist 2>/dev/null || true
    
    # Remove any untracked files from git that shouldn't be there
    if [ -d ".git" ]; then
        log "Removing untracked files from git repository..."
        cd $INSTALL_DIR
        sudo -u $SERVICE_USER git clean -fdx frontend/src/
        cd $INSTALL_DIR/frontend
    fi
    
    # Verify clean state
    log "Verifying frontend source structure..."
    if [ -f "src/App.tsx" ] && [ -f "src/main.tsx" ] && [ -f "src/index.css" ]; then
        SRC_FILE_COUNT=$(find src -type f | wc -l)
        if [ "$SRC_FILE_COUNT" -gt 3 ]; then
            warning "Found $SRC_FILE_COUNT files in src/, expected only 3 (App.tsx, main.tsx, index.css)"
            log "Listing unexpected files:"
            find src -type f | grep -v -E '(App\.tsx|main\.tsx|index\.css)$' || true
            
            # Force clean
            log "Force cleaning src directory..."
            cd $INSTALL_DIR
            sudo -u $SERVICE_USER git checkout HEAD -- frontend/src/
            sudo -u $SERVICE_USER git clean -fdx frontend/src/
            cd $INSTALL_DIR/frontend
        else
            log "✓ Source structure is clean ($SRC_FILE_COUNT files)"
        fi
    else
        error "Missing required frontend source files (App.tsx, main.tsx, or index.css)"
    fi
    
    # Check if we have source code or pre-built dist
    if [ -f "package.json" ] && [ -d "src" ]; then
        log "Building React frontend from source..."
        
        # Install dependencies
        log "Installing frontend dependencies..."
        sudo -u $SERVICE_USER npm install
        
        # Build production version
        log "Building production bundle..."
        sudo -u $SERVICE_USER npm run build
        
        if [ ! -d "dist" ] || [ ! -f "dist/index.html" ]; then
            error "Frontend build failed - dist directory not created"
        fi
        
        log "✅ Frontend built successfully"
    elif [ -d "dist" ] && [ -f "dist/index.html" ]; then
        log "Using pre-built frontend from dist/"
        log "✅ Frontend ready"
    else
        error "Frontend structure not found - neither source (package.json + src/) nor pre-built (dist/) exists"
    fi
    
    # Ensure proper ownership
    sudo chown -R $SERVICE_USER:$SERVICE_USER $INSTALL_DIR/frontend
    
    log "✅ Frontend deployed"
}

# Create configurations
create_config() {
    log "PHASE 6: Creating configuration files..."
    
    # Create main config directory
    sudo mkdir -p /etc/zedin
    
    # Environment file
    log "Creating environment configuration..."
    sudo tee /etc/zedin/zsmanager.env > /dev/null << EOF
# Zedin Steam Manager Configuration
APP_NAME=Zedin Steam Manager
VERSION=0.000001
DEBUG=False
HOST=0.0.0.0
PORT=8000

# Database
DATABASE_URL=sqlite:////var/lib/zedin/zedin_steam_manager.db

# Security
SECRET_KEY=$(openssl rand -hex 32)
ACCESS_TOKEN_EXPIRE_MINUTES=43200

# CORS
ALLOWED_ORIGINS=http://localhost:3000,http://127.0.0.1:3000

# Email (optional - disabled by default)
EMAIL_ENABLED=False
# SMTP_SERVER=smtp.gmail.com
# SMTP_PORT=587
# SMTP_USERNAME=your_email@gmail.com
# SMTP_PASSWORD=your_app_password
# EMAIL_FROM=noreply@zedinsteammanager.com

# Logging
LOG_LEVEL=INFO
EOF
    
    sudo chmod 640 /etc/zedin/zsmanager.env
    sudo chown root:$SERVICE_USER /etc/zedin/zsmanager.env
    
    # Create backend .env symlink
    sudo ln -sf /etc/zedin/zsmanager.env $INSTALL_DIR/backend/.env
    
    log "✅ Configuration created"
}

# Setup services
setup_services() {
    log "PHASE 7: Setting up systemd services..."
    
    # Backend service
    log "Creating backend service..."
    sudo tee /etc/systemd/system/zsmanager-backend.service > /dev/null << EOF
[Unit]
Description=Zedin Steam Manager Backend API
Documentation=https://github.com/zedinke/zedin-steam-manager
After=network.target

[Service]
Type=simple
User=$SERVICE_USER
Group=$SERVICE_USER
WorkingDirectory=$INSTALL_DIR/backend
Environment=PATH=$INSTALL_DIR/venv/bin:/usr/local/bin:/usr/bin:/bin
EnvironmentFile=/etc/zedin/zsmanager.env
ExecStart=$INSTALL_DIR/venv/bin/uvicorn main:app --host 0.0.0.0 --port 8000 --workers 4
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal
SyslogIdentifier=zsmanager-backend

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/lib/zedin /opt/zedin-steam-manager/backend/logs

# Resource limits
LimitNOFILE=65535
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
EOF

    log "✅ Services configured"
}

# Configure nginx
setup_nginx() {
    log "PHASE 8: Configuring Nginx..."
    
    sudo tee /etc/nginx/sites-available/zsmanager > /dev/null << 'EOF'
# Zedin Steam Manager - Nginx Configuration
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
    
    # Frontend static files
    root /opt/zedin-steam-manager/frontend/dist;
    index index.html;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    # Frontend - React Router support
    location / {
        try_files $uri $uri/ /index.html;
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
    }
    
    # Static assets caching
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Backend API
    location /api/ {
        proxy_pass http://127.0.0.1:8000/api/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }
    
    # Health check
    location /api/health {
        proxy_pass http://127.0.0.1:8000/api/health;
        access_log off;
    }
    
    # API documentation
    location /docs {
        proxy_pass http://127.0.0.1:8000/docs;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    
    location /openapi.json {
        proxy_pass http://127.0.0.1:8000/openapi.json;
        proxy_set_header Host $host;
    }
    
    # Deny access to sensitive files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
}
EOF

    # Remove default site if exists
    sudo rm -f /etc/nginx/sites-enabled/default
    
    # Enable our site
    sudo ln -sf /etc/nginx/sites-available/zsmanager /etc/nginx/sites-enabled/
    
    # Test nginx configuration
    log "Testing Nginx configuration..."
    if ! sudo nginx -t; then
        error "Nginx configuration test failed - check syntax"
    fi
    
    log "✅ Nginx configured"
}

# Initialize database
init_database() {
    log "PHASE 9: Initializing database..."
    
    # Ensure database directory exists
    sudo mkdir -p /var/lib/zedin
    sudo chown $SERVICE_USER:$SERVICE_USER /var/lib/zedin
    
    # Initialize database schema
    log "Creating database tables..."
    sudo -u $SERVICE_USER bash << 'EOF'
cd /opt/zedin-steam-manager
source venv/bin/activate
cd backend

python3 << PYEOF
import sys
try:
    from config.database import engine
    from models import base
    
    # Create all tables
    base.Base.metadata.create_all(bind=engine)
    
    print("✅ Database schema created successfully")
    sys.exit(0)
except Exception as e:
    print(f"❌ Database initialization failed: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
PYEOF
EOF
    
    if [ $? -ne 0 ]; then
        error "Database initialization failed"
    fi
    
    log "✅ Database initialized"
}

# Start services
start_services() {
    log "PHASE 10: Starting services..."
    
    # Reload systemd
    log "Reloading systemd daemon..."
    sudo systemctl daemon-reload
    
    # Enable and start backend
    log "Starting backend service..."
    sudo systemctl enable zsmanager-backend
    sudo systemctl start zsmanager-backend
    
    # Wait for backend to start
    sleep 5
    
    # Check backend status
    if sudo systemctl is-active --quiet zsmanager-backend; then
        log "✅ Backend service started"
    else
        warning "Backend service may have issues - checking logs..."
        sudo journalctl -u zsmanager-backend -n 20 --no-pager
        error "Backend failed to start - check logs above"
    fi
    
    # Restart nginx
    log "Restarting Nginx..."
    sudo systemctl restart nginx
    
    if sudo systemctl is-active --quiet nginx; then
        log "✅ Nginx started"
    else
        error "Nginx failed to start"
    fi
    
    log "✅ All services started"
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