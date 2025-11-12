#!/bin/bash

# Zedin Steam Manager - Debian Startup Script
echo "Starting Zedin Steam Manager on Debian..."

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "Creating Python virtual environment..."
    python3 -m venv venv
    source venv/bin/activate
    cd backend
    pip install --upgrade pip
    pip install -r requirements.txt
    cd ..
else
    echo "Activating Python virtual environment..."
    source venv/bin/activate
fi

# Function to check if port is in use
check_port() {
    if lsof -Pi :$1 -sTCP:LISTEN -t >/dev/null ; then
        echo "Port $1 is already in use"
        return 1
    else
        echo "Port $1 is available"
        return 0
    fi
}

# Check ports
check_port 8000
if [ $? -eq 1 ]; then
    echo "Backend port 8000 is busy. Kill existing process? (y/n)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        pkill -f "uvicorn.*main:app"
        sleep 2
    else
        exit 1
    fi
fi

check_port 3000
if [ $? -eq 1 ]; then
    echo "Frontend port 3000 is busy. Kill existing process? (y/n)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        pkill -f "npm.*dev"
        sleep 2
    else
        exit 1
    fi
fi

# Create logs directory
mkdir -p logs

# Start backend
echo "Starting FastAPI Backend..."
cd backend
nohup uvicorn main:app --host 0.0.0.0 --port 8000 --reload > ../logs/backend.log 2>&1 &
BACKEND_PID=$!
echo "Backend started with PID: $BACKEND_PID"
cd ..

# Wait a moment for backend to start
sleep 3

# Start frontend (if in development)
if [ "$1" = "dev" ]; then
    echo "Starting Frontend Development Server..."
    cd frontend
    nohup npm run dev > ../logs/frontend.log 2>&1 &
    FRONTEND_PID=$!
    echo "Frontend started with PID: $FRONTEND_PID"
    cd ..
fi

# Save PIDs
echo $BACKEND_PID > logs/backend.pid
if [ ! -z "$FRONTEND_PID" ]; then
    echo $FRONTEND_PID > logs/frontend.pid
fi

echo ""
echo "=== Zedin Steam Manager Started ==="
echo "Backend API: http://localhost:8000"
echo "API Documentation: http://localhost:8000/docs"
if [ "$1" = "dev" ]; then
    echo "Frontend: http://localhost:3000"
fi
echo ""
echo "Logs:"
echo "  Backend: tail -f logs/backend.log"
if [ "$1" = "dev" ]; then
    echo "  Frontend: tail -f logs/frontend.log"
fi
echo ""
echo "To stop:"
echo "  ./stop-debian.sh"