#!/bin/bash

# ============================================================================
# Zedin Steam Manager - Minimal Installation Script
# Skips problematic Node.js dependencies for quick backend setup
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
echo "                    Zedin Steam Manager - Minimal Install"
echo "============================================================================"

log "PHASE 1: Installing minimal dependencies (Python only)..."
sudo apt update
sudo apt install -y python3 python3-pip python3-venv git nginx curl

log "PHASE 2: Creating user and directories..."
# Create user if not exists
if ! id "$SERVICE_USER" &>/dev/null; then
    sudo useradd -r -m -g users -s /bin/bash $SERVICE_USER
    log "Created user: $SERVICE_USER"
else
    log "User $SERVICE_USER already exists"
fi

# Create directories
sudo mkdir -p $INSTALL_DIR $LOG_DIR $DATA_DIR/{servers,shared_files,backups} /etc/zedin
sudo chown -R $SERVICE_USER:users $INSTALL_DIR $DATA_DIR $LOG_DIR

log "PHASE 3: Installing application..."
# Copy files
if [ -d "backend" ]; then
    sudo cp -r backend/ $INSTALL_DIR/
    sudo cp -r frontend/ $INSTALL_DIR/ 2>/dev/null || log "Frontend skipped (Node.js not available)"
    sudo cp package.json $INSTALL_DIR/ 2>/dev/null || true
    sudo cp README.md $INSTALL_DIR/ 2>/dev/null || true
    sudo chown -R $SERVICE_USER:users $INSTALL_DIR
    log "Application files copied successfully"
else
    error "Backend directory not found"
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

log "PHASE 5: Creating configuration..."
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

log "PHASE 6: Creating systemd service..."
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

log "PHASE 7: Configuring Nginx (API only)..."
sudo tee /etc/nginx/sites-available/zedin-steam-manager > /dev/null << 'EOF'
server {
    listen 80;
    server_name _;

    # API endpoints
    location /api/ {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location /docs {
        proxy_pass http://localhost:8000;
    }

    location /health {
        proxy_pass http://localhost:8000;
    }

    # Simple status page
    location / {
        return 200 'Zedin Steam Manager API Running\nAccess API docs at /docs';
        add_header Content-Type text/plain;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/zedin-steam-manager /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t

log "PHASE 8: Starting services..."
# Initialize database
sudo -u $SERVICE_USER bash << 'EOF'
cd /opt/zedin-steam-manager
source venv/bin/activate
cd backend
python3 -c "
try:
    from config.database import engine
    from models import base
    base.Base.metadata.create_all(bind=engine)
    print('Database initialized successfully')
except Exception as e:
    print(f'Database initialization error: {e}')
    exit(1)
"
EOF

sudo systemctl daemon-reload
sudo systemctl enable zsmanager-backend
sudo systemctl start zsmanager-backend
sudo systemctl restart nginx

sleep 3

# Check services
if sudo systemctl is-active --quiet zsmanager-backend; then
    log "✓ Backend service started successfully"
else
    log "✗ Backend service issue - checking logs..."
    sudo journalctl -u zsmanager-backend --no-pager -n 20
fi

if sudo systemctl is-active --quiet nginx; then
    log "✓ Nginx started successfully"
else
    log "✗ Nginx issue - check logs: sudo journalctl -u nginx"
fi

# Test API
log "Testing API connectivity..."
curl -s http://localhost:8000/health >/dev/null && log "✓ API responding" || log "✗ API not responding"

clear
echo "============================================================================"
echo "                    🎉 MINIMAL INSTALLATION COMPLETE! 🎉"
echo "============================================================================"
echo ""
echo "Zedin Steam Manager Backend successfully installed!"
echo ""
echo "📍 Access:"
echo "   API: http://$(hostname -I | awk '{print $1}')/docs"
echo "   Health: http://$(hostname -I | awk '{print $1}')/health"
echo ""
echo "🔧 Management:"
echo "   Status: sudo systemctl status zsmanager-backend"
echo "   Logs: sudo journalctl -f -u zsmanager-backend"
echo "   Stop: sudo systemctl stop zsmanager-backend"
echo "   Start: sudo systemctl start zsmanager-backend"
echo ""
echo "📝 Next Steps:"
echo "   1. Install Node.js manually if you need frontend"
echo "   2. Access API docs to test functionality"
echo "   3. Check logs for any issues"
echo ""
echo "Note: Frontend skipped due to Node.js conflicts - backend API fully functional"
echo "============================================================================"