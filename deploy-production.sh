#!/bin/bash

# Zedin Steam Manager - Production Deployment Script
# This script will set up everything needed for production

set -e  # Exit on error

echo "=============================================="
echo "  Zedin Steam Manager - Production Setup"
echo "=============================================="
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    echo "❌ Please do not run as root. Run as normal user with sudo privileges."
    exit 1
fi

# Variables
INSTALL_DIR="/opt/zedin-steam-manager"
SERVICE_USER="zedin"
CURRENT_USER=$(whoami)

echo "📋 Installation Summary:"
echo "  - Install directory: $INSTALL_DIR"
echo "  - Service user: $SERVICE_USER"
echo "  - Current user: $CURRENT_USER"
echo ""

read -p "Continue with installation? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Installation cancelled."
    exit 0
fi

echo ""
echo "======================================"
echo "STEP 1: Installing system dependencies"
echo "======================================"

sudo apt update
sudo apt install -y python3 python3-pip python3-venv python3-full nodejs npm nginx

echo "✅ System dependencies installed"

echo ""
echo "======================================"
echo "STEP 2: Creating service user and directories"
echo "======================================"

# Create service user if not exists
if ! id "$SERVICE_USER" &>/dev/null; then
    sudo useradd -r -s /bin/bash -d $INSTALL_DIR $SERVICE_USER
    echo "✅ Service user created: $SERVICE_USER"
else
    echo "✅ Service user already exists: $SERVICE_USER"
fi

# Create installation directory
sudo mkdir -p $INSTALL_DIR
sudo chown -R $SERVICE_USER:$SERVICE_USER $INSTALL_DIR

echo ""
echo "======================================"
echo "STEP 3: Copying application files"
echo "======================================"

# Copy all files to installation directory
sudo cp -r . $INSTALL_DIR/
sudo chown -R $SERVICE_USER:$SERVICE_USER $INSTALL_DIR

echo "✅ Files copied to $INSTALL_DIR"

echo ""
echo "======================================"
echo "STEP 4: Installing Python dependencies"
echo "======================================"

cd $INSTALL_DIR/backend
sudo -u $SERVICE_USER python3 -m venv venv
sudo -u $SERVICE_USER bash -c "source venv/bin/activate && pip install --upgrade pip && pip install -r requirements.txt"

echo "✅ Python dependencies installed"

echo ""
echo "======================================"
echo "STEP 5: Installing Node.js dependencies"
echo "======================================"

cd $INSTALL_DIR/frontend
sudo -u $SERVICE_USER npm install

echo "✅ Node.js dependencies installed"

echo ""
echo "======================================"
echo "STEP 6: Setting up environment configuration"
echo "======================================"

# Create .env file
sudo -u $SERVICE_USER bash -c "cat > $INSTALL_DIR/backend/.env << 'EOF'
# Zedin Steam Manager - Environment Configuration

# Supabase Configuration
SUPABASE_URL=https://mgosieaxhosiwzpvcyle.supabase.co
SUPABASE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1nb3NpZWF4aG9zaXd6cHZjeWxlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5ODc5ODcsImV4cCI6MjA3ODU2Mzk4N30.8k7qGQCitCOp-ZDu-Km5XunFUs5pBcp2khkwDxxijdY
SUPABASE_JWT_SECRET=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1nb3NpZWF4aG9zaXd6cHZjeWxlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2Mjk4Nzk4NywiZXhwIjoyMDc4NTYzOTg3fQ.1Fis5CoT2xZVbiv-jUvVcrjPZZhzeZMn1hrrZIbauJw

# Database Configuration (PostgreSQL via Supabase)
DATABASE_URL=postgresql://postgres:Gele007ta...@db.mgosieaxhosiwzpvcyle.supabase.co:5432/postgres

# JWT Configuration (for local token generation)
SECRET_KEY=zedin-steam-manager-secret-key-production-2025
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_DAYS=30

# Application
DEBUG=False
EOF"

echo "✅ Environment configured"

echo ""
echo "======================================"
echo "STEP 7: Initializing database"
echo "======================================"

cd $INSTALL_DIR/backend
sudo -u $SERVICE_USER bash -c "source venv/bin/activate && python reset_db.py" << 'DBCONFIRM'
yes
DBCONFIRM

echo "✅ Database initialized"

echo ""
echo "======================================"
echo "STEP 8: Building frontend"
echo "======================================"

cd $INSTALL_DIR/frontend
sudo -u $SERVICE_USER npm run build

echo "✅ Frontend built"

echo ""
echo "======================================"
echo "STEP 9: Setting up systemd services"
echo "======================================"

# Backend service
sudo tee /etc/systemd/system/zedin-backend.service > /dev/null << EOF
[Unit]
Description=Zedin Steam Manager Backend
After=network.target

[Service]
Type=simple
User=$SERVICE_USER
WorkingDirectory=$INSTALL_DIR/backend
Environment="PATH=$INSTALL_DIR/backend/venv/bin"
ExecStart=$INSTALL_DIR/backend/venv/bin/uvicorn main:app --host 127.0.0.1 --port 8000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and start services
sudo systemctl daemon-reload
sudo systemctl enable zedin-backend
sudo systemctl start zedin-backend

echo "✅ Backend service created and started"

echo ""
echo "======================================"
echo "STEP 10: Configuring Nginx"
echo "======================================"

# Get server IP
SERVER_IP=$(hostname -I | awk '{print $1}')

# Nginx configuration
sudo tee /etc/nginx/sites-available/zedin-steam-manager > /dev/null << EOF
server {
    listen 80;
    server_name $SERVER_IP;

    # Frontend (serve static files)
    location / {
        root $INSTALL_DIR/frontend/dist;
        try_files \$uri \$uri/ /index.html;
    }

    # Backend API proxy
    location /api {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Health check
    location /health {
        proxy_pass http://127.0.0.1:8000/api/health;
    }
}
EOF

# Enable site
sudo ln -sf /etc/nginx/sites-available/zedin-steam-manager /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test nginx configuration
sudo nginx -t

# Restart nginx
sudo systemctl restart nginx
sudo systemctl enable nginx

echo "✅ Nginx configured and started"

echo ""
echo "======================================"
echo "STEP 11: Opening firewall ports"
echo "======================================"

if command -v ufw &> /dev/null; then
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    echo "✅ UFW firewall configured"
elif command -v iptables &> /dev/null; then
    sudo iptables -I INPUT -p tcp --dport 80 -j ACCEPT
    sudo iptables -I INPUT -p tcp --dport 443 -j ACCEPT
    echo "✅ iptables configured"
fi

echo ""
echo "=============================================="
echo "✅ Installation Complete!"
echo "=============================================="
echo ""
echo "🌐 Access your application at:"
echo "   http://$SERVER_IP"
echo ""
echo "📊 Service Management:"
echo "   sudo systemctl status zedin-backend"
echo "   sudo systemctl restart zedin-backend"
echo "   sudo systemctl stop zedin-backend"
echo ""
echo "📋 Logs:"
echo "   sudo journalctl -u zedin-backend -f"
echo ""
echo "🗂️ Installation directory: $INSTALL_DIR"
echo ""
echo "To uninstall, run: sudo bash $INSTALL_DIR/uninstall.sh"
echo ""
