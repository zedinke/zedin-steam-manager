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
        exit 1
    fi
}

# Install system dependencies
install_system_deps() {
    log "Installing system dependencies..."
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y curl wget git python3 python3-pip python3-venv nginx
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

# Download application
download_app() {
    log "Downloading application from GitHub..."
    
    if [ -d "$INSTALL_DIR/.git" ]; then
        cd $INSTALL_DIR
        sudo -u $SERVICE_USER git fetch origin
        sudo -u $SERVICE_USER git reset --hard origin/main
    else
        sudo rm -rf $INSTALL_DIR
        sudo -u $SERVICE_USER git clone $GITHUB_REPO $INSTALL_DIR
    fi
    
    cd $INSTALL_DIR
    sudo chown -R $SERVICE_USER:$SERVICE_USER $INSTALL_DIR
    log "✅ Application downloaded"
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
    
    if [ ! -f "$INSTALL_DIR/frontend/dist/index.html" ]; then
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
export -f log error warning info check_root check_os show_banner
export -f install_system_deps setup_user_dirs download_app install_backend
export -f deploy_frontend create_config setup_services setup_nginx
export -f init_database start_services check_status show_completion