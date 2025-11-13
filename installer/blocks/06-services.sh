#!/bin/bash

#############################################
# Block 06: Configure Systemd Services
#############################################

echo "Configuring systemd services..."

# Create backend service
cat > /etc/systemd/system/zedin-backend.service << 'EOFSERVICE'
[Unit]
Description=Zedin Steam Manager Backend
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/zedin-steam-manager/backend
Environment="PATH=/opt/zedin-steam-manager/backend/venv/bin"
ExecStart=/opt/zedin-steam-manager/backend/venv/bin/python3 -m uvicorn main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOFSERVICE

echo "✅ Backend service created"

# Create frontend service
cat > /etc/systemd/system/zedin-frontend.service << 'EOFSERVICE'
[Unit]
Description=Zedin Steam Manager Frontend
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/zedin-steam-manager/frontend
ExecStart=/usr/bin/npm run dev
Restart=always
RestartSec=10
Environment="PORT=3000"

[Install]
WantedBy=multi-user.target
EOFSERVICE

echo "✅ Frontend service created"

# Reload systemd
systemctl daemon-reload
echo "✅ Systemd reloaded"

# Enable services
systemctl enable zedin-backend.service
systemctl enable zedin-frontend.service
echo "✅ Services enabled"

# Start services
echo "Starting services..."
systemctl start zedin-backend.service
sleep 2

if systemctl is-active --quiet zedin-backend.service; then
    echo "✅ Backend service started"
else
    echo "❌ Backend service failed to start"
    journalctl -u zedin-backend.service -n 20 --no-pager
    exit 1
fi

systemctl start zedin-frontend.service
sleep 2

if systemctl is-active --quiet zedin-frontend.service; then
    echo "✅ Frontend service started"
else
    echo "⚠️  Frontend service failed to start (will try in dev mode)"
    journalctl -u zedin-frontend.service -n 20 --no-pager
fi

echo ""
echo "✅ Services configured and started"
echo ""
