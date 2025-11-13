#!/bin/bash

#############################################
# Block 03: Database Configuration
#############################################

echo "Configuring Supabase database connection..."

# Supabase credentials
SUPABASE_URL="https://mgosieaxhosiwzpvcyle.supabase.co"
SUPABASE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1nb3NpZWF4aG9zaXd6cHZjeWxlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5ODc5ODcsImV4cCI6MjA3ODU2Mzk4N30.8k7qGQCitCOp-ZDu-Km5XunFUs5pBcp2khkwDxxijdY"
JWT_SECRET="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1nb3NpZWF4aG9zaXd6cHZjeWxlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2Mjk4Nzk4NywiZXhwIjoyMDc4NTYzOTg3fQ.lREOEbqmRtpPG_4c7fzbQMwIgdMNjZw9VBFEzujrvg4"

# Test connection
echo "Testing Supabase connection..."
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "apikey: $SUPABASE_KEY" \
    -H "Authorization: Bearer $SUPABASE_KEY" \
    "$SUPABASE_URL/rest/v1/")

if [ "$RESPONSE" = "200" ]; then
    echo "✅ Supabase connection successful"
else
    echo "❌ Error: Unable to connect to Supabase (HTTP $RESPONSE)"
    exit 1
fi

# Create environment file
ENV_FILE="/opt/zedin-steam-manager/backend/.env"
mkdir -p "$(dirname $ENV_FILE)"

cat > "$ENV_FILE" << EOF
# Supabase Configuration
SUPABASE_URL=$SUPABASE_URL
SUPABASE_KEY=$SUPABASE_KEY
JWT_SECRET=$JWT_SECRET

# Email Configuration (for verification)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=noreply@zedinmanager.com
SMTP_PASSWORD=change_me_in_production

# Application Configuration
APP_NAME=Zedin Steam Manager
APP_VERSION=0.0.1
FRONTEND_URL=http://localhost
BACKEND_URL=http://localhost:8000

# Security
SECRET_KEY=$(openssl rand -hex 32)
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_DAYS=30
EOF

chmod 600 "$ENV_FILE"
echo "✅ Environment file created: $ENV_FILE"

# Verify email verification requirements
echo "⚠️  Note: Email verification is enabled"
echo "   Configure SMTP settings in $ENV_FILE before production use"

echo ""
echo "✅ Database configuration completed"
echo ""
