#!/bin/bash
echo "Installing Zedin Steam Manager..."
echo ""

echo "[1/3] Creating Python virtual environment..."
cd backend

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    python3 -m venv venv
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to create virtual environment!"
        echo "Please install: sudo apt install python3-venv python3-full"
        exit 1
    fi
    echo "✓ Virtual environment created"
else
    echo "✓ Virtual environment already exists"
fi

# Activate virtual environment and install dependencies
echo ""
echo "[2/3] Installing backend dependencies..."
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
if [ $? -ne 0 ]; then
    echo "ERROR: Backend installation failed!"
    exit 1
fi
deactivate
cd ..

echo ""
echo "[3/3] Installing frontend dependencies..."
cd frontend
npm install
if [ $? -ne 0 ]; then
    echo "ERROR: Frontend installation failed!"
    exit 1
fi
cd ..

echo ""
echo "[4/4] Setup complete!"
echo ""
echo "Next steps:"
echo "1. Follow SETUP_SUPABASE.md to configure your Supabase database"
echo "2. Copy backend/.env.example to backend/.env and fill in your credentials"
echo "3. Run: python backend/init_db.py (to create database tables)"
echo "4. Run: ./start-dev.sh (to start both backend and frontend)"
echo ""
