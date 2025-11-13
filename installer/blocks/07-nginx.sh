#!/bin/bash

#############################################
# Block 07: Configure Nginx
#############################################

echo "Configuring Nginx..."

# Backup existing nginx config if exists
if [ -f /etc/nginx/sites-available/zedin-manager ]; then
    cp /etc/nginx/sites-available/zedin-manager /etc/nginx/sites-available/zedin-manager.backup.$(date +%Y%m%d-%H%M%S)
    echo "✅ Existing config backed up"
fi

# Create Nginx configuration
cat > /etc/nginx/sites-available/zedin-manager << 'EOFNGINX'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    server_name _;
    
    # Frontend (React)
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Backend API
    location /api {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Increase timeouts for long-running operations
        proxy_connect_timeout 600;
        proxy_send_timeout 600;
        proxy_read_timeout 600;
        send_timeout 600;
    }
    
    # WebSocket support
    location /ws {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host $host;
    }
}
EOFNGINX

echo "✅ Nginx config created"

# Enable site
if [ -f /etc/nginx/sites-enabled/default ]; then
    rm /etc/nginx/sites-enabled/default
    echo "✅ Default site removed"
fi

ln -sf /etc/nginx/sites-available/zedin-manager /etc/nginx/sites-enabled/zedin-manager
echo "✅ Site enabled"

# Test Nginx configuration
echo "Testing Nginx configuration..."
nginx -t

if [ $? -eq 0 ]; then
    echo "✅ Nginx configuration valid"
else
    echo "❌ Nginx configuration invalid"
    exit 1
fi

# Restart Nginx
echo "Restarting Nginx..."
systemctl restart nginx

if systemctl is-active --quiet nginx; then
    echo "✅ Nginx restarted successfully"
else
    echo "❌ Nginx failed to restart"
    systemctl status nginx --no-pager
    exit 1
fi

# Enable Nginx on boot
systemctl enable nginx
echo "✅ Nginx enabled on boot"

# Check if firewall is active and configure
if command -v ufw &> /dev/null; then
    if ufw status | grep -q "Status: active"; then
        echo "Configuring UFW firewall..."
        ufw allow 80/tcp
        ufw allow 443/tcp
        echo "✅ Firewall rules added"
    fi
fi

# Get server IP
SERVER_IP=$(hostname -I | awk '{print $1}')

echo ""
echo "✅ Nginx configured successfully"
echo ""
echo "🌐 Access your manager at:"
echo "   http://$SERVER_IP"
echo ""
