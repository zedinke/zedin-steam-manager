#!/bin/bash

echo "🌐 Setting up Supabase External Database for ZedinSteamManager"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📋 Instructions for Supabase setup:${NC}"
echo ""
echo -e "${YELLOW}1. Go to https://supabase.com and create a free account${NC}"
echo -e "${YELLOW}2. Create a new project${NC}"
echo -e "${YELLOW}3. Set a strong database password${NC}"
echo -e "${YELLOW}4. Go to Settings > Database${NC}"
echo -e "${YELLOW}5. Copy the Connection string (URI)${NC}"
echo ""
echo -e "${BLUE}It should look like:${NC}"
echo "postgresql://postgres:[YOUR-PASSWORD]@db.[YOUR-PROJECT].supabase.co:5432/postgres"
echo ""

read -p "Enter your Supabase connection string: " SUPABASE_URL

if [ -z "$SUPABASE_URL" ]; then
    echo -e "${RED}❌ No connection string provided. Exiting.${NC}"
    exit 1
fi

# Validate connection string format
if [[ ! $SUPABASE_URL == postgresql://* ]]; then
    echo -e "${RED}❌ Invalid connection string format. Should start with postgresql://${NC}"
    exit 1
fi

echo -e "${BLUE}📧 Email configuration (optional - for email verification):${NC}"
read -p "Enter your email address (for sending verification emails): " EMAIL_SENDER
read -s -p "Enter your email app password (Gmail app password): " EMAIL_PASSWORD
echo ""

# Create .env file
echo -e "${YELLOW}📝 Creating environment configuration...${NC}"

cd /opt/zedin-steam-manager

sudo -u zsmanager tee .env << EOF
# External Database Configuration
EXTERNAL_DATABASE_URL=$SUPABASE_URL
USE_EXTERNAL_DB=true

# Email Configuration
EMAIL_SENDER=$EMAIL_SENDER
EMAIL_PASSWORD=$EMAIL_PASSWORD
EMAIL_ENABLED=true

# Security
SECRET_KEY=$(openssl rand -hex 32)

# Application
DEBUG=false
LOG_LEVEL=INFO
EOF

echo -e "${GREEN}✅ Environment configuration created${NC}"

# Install PostgreSQL adapter
echo -e "${YELLOW}📦 Installing PostgreSQL dependencies...${NC}"
sudo -u zsmanager /opt/zedin-steam-manager/venv/bin/pip install psycopg2-binary

# Test database connection
echo -e "${YELLOW}🔌 Testing database connection...${NC}"
sudo -u zsmanager PYTHONPATH=/opt/zedin-steam-manager/backend /opt/zedin-steam-manager/venv/bin/python << 'EOF'
import sys
sys.path.append('/opt/zedin-steam-manager/backend')
try:
    from config.database import test_connection
    test_connection()
except Exception as e:
    print(f"❌ Connection test failed: {e}")
    exit(1)
EOF

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Database connection successful${NC}"
else
    echo -e "${RED}❌ Database connection failed${NC}"
    exit 1
fi

# Run database migrations
echo -e "${YELLOW}🏗️ Creating database tables...${NC}"
sudo -u zsmanager PYTHONPATH=/opt/zedin-steam-manager/backend /opt/zedin-steam-manager/venv/bin/python -m alembic -c backend/alembic.ini upgrade head

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Database tables created successfully${NC}"
else
    echo -e "${RED}❌ Database migration failed${NC}"
    exit 1
fi

# Restart services
echo -e "${YELLOW}🔄 Restarting services...${NC}"
sudo systemctl restart zsmanager-backend
sudo systemctl restart nginx

# Check service status
sleep 3
if systemctl is-active --quiet zsmanager-backend; then
    echo -e "${GREEN}✅ Backend service is running${NC}"
else
    echo -e "${RED}❌ Backend service failed to start${NC}"
    echo "Check logs: sudo journalctl -u zsmanager-backend --no-pager -n 20"
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 Supabase setup completed successfully!${NC}"
echo ""
echo -e "${BLUE}📊 You can monitor your database at:${NC}"
echo "https://app.supabase.com/project/[your-project]/editor"
echo ""
echo -e "${BLUE}📝 What happens now:${NC}"
echo "• User registrations will be stored in Supabase"
echo "• Tokens and licenses will persist across reinstallations"
echo "• Users can access their accounts from any installation"
echo "• Trial tokens are automatically created for new users"
echo ""
echo -e "${YELLOW}💡 Next steps:${NC}"
echo "1. Test registration on your frontend"
echo "2. Check user data in Supabase dashboard"
echo "3. Configure email settings in Supabase if needed"