#!/bin/bash

# Debug script to check what's going on
echo "=== Debug Information ==="
echo "Current directory: $(pwd)"
echo "Current user: $(whoami)"
echo "User ID: $(id)"
echo ""

echo "=== Directory contents ==="
ls -la
echo ""

echo "=== Looking for project files ==="
echo "Checking for backend directory:"
if [ -d "backend" ]; then
    echo "✓ backend/ found"
    ls -la backend/ | head -5
else
    echo "✗ backend/ not found"
fi

echo "Checking for frontend directory:"
if [ -d "frontend" ]; then
    echo "✓ frontend/ found"
    ls -la frontend/ | head -5
else
    echo "✗ frontend/ not found"
fi

echo "Checking for install scripts:"
if [ -f "install.sh" ]; then
    echo "✓ install.sh found"
fi
if [ -f "install-simple.sh" ]; then
    echo "✓ install-simple.sh found"
fi

echo ""
echo "=== Searching for project in common locations ==="
for dir in /home/*/zedin-steam-manager /tmp/zedin-steam-manager /opt/zedin-steam-manager /zedin-steam-manager ~/zedin-steam-manager; do
    if [ -d "$dir" ]; then
        echo "Found directory: $dir"
        if [ -d "$dir/backend" ]; then
            echo "  ✓ Has backend/"
        fi
        if [ -d "$dir/frontend" ]; then
            echo "  ✓ Has frontend/"
        fi
    fi
done

echo ""
echo "=== Process information ==="
echo "Current processes with 'zedin':"
ps aux | grep zedin || echo "No zedin processes"

echo ""
echo "=== Git information ==="
if [ -d ".git" ]; then
    echo "Git repository found"
    echo "Remote URLs:"
    git remote -v 2>/dev/null || echo "No git remotes"
else
    echo "Not a git repository"
fi

echo "=== End Debug ==="