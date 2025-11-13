#!/bin/bash
echo "======================================"
echo "  Zedin Steam Manager - Update"
echo "======================================"
echo ""

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo "❌ Error: Not a git repository!"
    echo "Please run this script from the project root directory."
    exit 1
fi

echo "[1/5] Stopping services..."
if pgrep -f "uvicorn main:app" > /dev/null; then
    pkill -f "uvicorn main:app"
    echo "✓ Backend stopped"
fi
if pgrep -f "vite" > /dev/null; then
    pkill -f "vite"
    echo "✓ Frontend stopped"
fi

echo ""
echo "[2/5] Pulling latest changes from GitHub..."
git pull origin main
if [ $? -ne 0 ]; then
    echo "❌ Git pull failed!"
    exit 1
fi
echo "✓ Code updated"

echo ""
echo "[3/5] Updating backend dependencies..."
cd backend
if [ -d "venv" ]; then
    source venv/bin/activate
    pip install --upgrade pip -q
    pip install -r requirements.txt -q
    deactivate
    echo "✓ Backend dependencies updated"
else
    echo "⚠ Virtual environment not found, skipping backend update"
fi
cd ..

echo ""
echo "[4/5] Updating frontend dependencies..."
cd frontend
if [ -f "package.json" ]; then
    npm install
    if [ $? -ne 0 ]; then
        echo "❌ Frontend update failed!"
        exit 1
    fi
    echo "✓ Frontend dependencies updated"
fi
cd ..

echo ""
echo "[5/5] Checking database migrations..."
cd backend
if [ -f "init_db.py" ]; then
    source venv/bin/activate
    python init_db.py
    deactivate
    echo "✓ Database checked"
fi
cd ..

echo ""
echo "======================================"
echo "✅ Update completed successfully!"
echo "======================================"
echo ""
echo "To start the application, run:"
echo "  ./start-dev.sh"
echo ""
