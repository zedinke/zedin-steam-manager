#!/bin/bash
echo "======================================"
echo "  Zedin Steam Manager - First Setup"
echo "======================================"
echo ""

# Check if .env already exists
if [ -f "backend/.env" ]; then
    echo "⚠️  .env file already exists!"
    echo ""
    read -p "Do you want to overwrite it? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "Setup cancelled."
        exit 0
    fi
fi

echo "Creating backend/.env configuration..."
echo ""

# Create .env file with Supabase credentials
cat > backend/.env << 'EOF'
# Zedin Steam Manager - Environment Configuration

# Supabase Configuration
SUPABASE_URL=https://mgosieaxhosiwzpvcyle.supabase.co
SUPABASE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1nb3NpZWF4aG9zaXd6cHZjeWxlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI5ODc5ODcsImV4cCI6MjA3ODU2Mzk4N30.8k7qGQCitCOp-ZDu-Km5XunFUs5pBcp2khkwDxxijdY
SUPABASE_JWT_SECRET=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1nb3NpZWF4aG9zaXd6cHZjeWxlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2Mjk4Nzk4NywiZXhwIjoyMDc4NTYzOTg3fQ.1Fis5CoT2xZVbiv-jUvVcrjPZZhzeZMn1hrrZIbauJw

# Database Configuration (PostgreSQL via Supabase)
DATABASE_URL=postgresql://postgres:Gele007ta...@db.mgosieaxhosiwzpvcyle.supabase.co:5432/postgres

# JWT Configuration (for local token generation)
SECRET_KEY=zedin-steam-manager-secret-key-change-in-production-2025
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_DAYS=30

# Application
DEBUG=True
EOF

echo "✅ Configuration created: backend/.env"
echo ""
echo "Initializing database..."
cd backend
source venv/bin/activate
python init_db.py
deactivate
cd ..

echo ""
echo "======================================"
echo "✅ Setup completed successfully!"
echo "======================================"
echo ""
echo "To start the application, run:"
echo "  ./start-dev.sh"
echo ""
