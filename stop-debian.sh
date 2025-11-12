#!/bin/bash

# Zedin Steam Manager - Debian Stop Script
echo "Stopping Zedin Steam Manager..."

# Function to stop process by PID file
stop_by_pid() {
    local pidfile=$1
    local name=$2
    
    if [ -f "$pidfile" ]; then
        local pid=$(cat "$pidfile")
        if ps -p $pid > /dev/null 2>&1; then
            echo "Stopping $name (PID: $pid)..."
            kill $pid
            sleep 2
            
            # Force kill if still running
            if ps -p $pid > /dev/null 2>&1; then
                echo "Force killing $name..."
                kill -9 $pid
            fi
        else
            echo "$name process not found"
        fi
        rm -f "$pidfile"
    else
        echo "No PID file for $name"
    fi
}

# Stop by PID files
stop_by_pid "logs/backend.pid" "Backend"
stop_by_pid "logs/frontend.pid" "Frontend"

# Fallback: kill by process name
echo "Checking for remaining processes..."
pkill -f "uvicorn.*main:app" 2>/dev/null && echo "Killed remaining backend processes"
pkill -f "npm.*dev" 2>/dev/null && echo "Killed remaining frontend processes"

# Check if ports are free
check_port_free() {
    if ! lsof -Pi :$1 -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo "Port $1 is now free"
    else
        echo "Warning: Port $1 is still in use"
    fi
}

check_port_free 8000
check_port_free 3000

echo "Zedin Steam Manager stopped."