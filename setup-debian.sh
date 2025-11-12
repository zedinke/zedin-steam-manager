#!/bin/bash

echo "=== Zedin Steam Manager - Debian Setup ==="

# Check if running on Debian/Ubuntu
if ! command -v apt &> /dev/null; then
    echo "This script is for Debian/Ubuntu systems"
    exit 1
fi

# Create Python virtual environment
echo "Creating Python virtual environment..."
cd /path/to/zedinsteammanager
python3 -m venv venv
source venv/bin/activate

# Install Python dependencies
echo "Installing Python dependencies..."
cd backend
pip install --upgrade pip
pip install -r requirements.txt
cd ..

# Install Node.js dependencies
echo "Installing Node.js dependencies..."
npm install
cd frontend && npm install && cd ..

# Create systemd service files
echo "Creating systemd services..."

# Backend service
sudo tee /etc/systemd/system/zedin-backend.service > /dev/null <<EOF
[Unit]
Description=Zedin Steam Manager Backend
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=/path/to/zedinsteammanager/backend
Environment=PATH=/path/to/zedinsteammanager/venv/bin
ExecStart=/path/to/zedinsteammanager/venv/bin/uvicorn main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# Frontend service (for development)
sudo tee /etc/systemd/system/zedin-frontend.service > /dev/null <<EOF
[Unit]
Description=Zedin Steam Manager Frontend
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=/path/to/zedinsteammanager/frontend
ExecStart=/usr/bin/npm run dev
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and enable services
sudo systemctl daemon-reload
sudo systemctl enable zedin-backend
sudo systemctl enable zedin-frontend

echo "Setup complete! Use the following commands to manage the services:"
echo "sudo systemctl start zedin-backend"
echo "sudo systemctl start zedin-frontend"
echo "sudo systemctl status zedin-backend"
echo "sudo systemctl status zedin-frontend"