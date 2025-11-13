#!/bin/bash

#############################################
# Zedin Steam Manager - Development Start
# Version: 0.0.1-alpha
#############################################

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=============================================="
echo -e "  Zedin Steam Manager - Development Mode"
echo -e "===============================================${NC}"
echo ""

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$SCRIPT_DIR/backend"
FRONTEND_DIR="$SCRIPT_DIR/frontend"

# Start backend
if [ -d "$BACKEND_DIR" ]; then
    echo -e "${GREEN}Starting backend...${NC}"
    cd "$BACKEND_DIR"
    
    # Activate virtual environment
    if [ -f "venv/bin/activate" ]; then
        source venv/bin/activate
    fi
    
    # Start backend in background
    python3 -m uvicorn main:app --reload --host 0.0.0.0 --port 8000 &
    BACKEND_PID=$!
    
    echo -e "${GREEN}✅ Backend started (PID: $BACKEND_PID)${NC}"
    echo "   http://localhost:8000"
else
    echo "Backend directory not found"
    exit 1
fi

# Start frontend
if [ -d "$FRONTEND_DIR" ]; then
    echo ""
    echo -e "${GREEN}Starting frontend...${NC}"
    cd "$FRONTEND_DIR"
    
    # Start frontend
    npm run dev &
    FRONTEND_PID=$!
    
    echo -e "${GREEN}✅ Frontend started (PID: $FRONTEND_PID)${NC}"
    echo "   http://localhost:3000"
else
    echo "Frontend directory not found"
    kill $BACKEND_PID 2>/dev/null
    exit 1
fi

echo ""
echo -e "${BLUE}=============================================="
echo -e "  Development servers running"
echo -e "  Press Ctrl+C to stop"
echo -e "===============================================${NC}"

# Wait for Ctrl+C
trap "kill $BACKEND_PID $FRONTEND_PID 2>/dev/null; exit" SIGINT SIGTERM

wait
