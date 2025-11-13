#!/bin/bash

#############################################
# Block 01: System Requirements Check
#############################################

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    echo "⚠️  Warning: Running as root is not recommended"
fi

# Check OS
if [ ! -f /etc/os-release ]; then
    echo "❌ Error: Unable to detect operating system"
    exit 1
fi

source /etc/os-release
echo "✅ OS: $PRETTY_NAME"

# Check architecture
ARCH=$(uname -m)
if [ "$ARCH" != "x86_64" ] && [ "$ARCH" != "aarch64" ]; then
    echo "❌ Error: Unsupported architecture: $ARCH"
    echo "   Supported: x86_64, aarch64"
    exit 1
fi
echo "✅ Architecture: $ARCH"

# Check disk space (minimum 10GB free)
AVAILABLE_SPACE=$(df / | tail -1 | awk '{print $4}')
REQUIRED_SPACE=10485760  # 10GB in KB

if [ "$AVAILABLE_SPACE" -lt "$REQUIRED_SPACE" ]; then
    echo "❌ Error: Insufficient disk space"
    echo "   Required: 10GB, Available: $((AVAILABLE_SPACE / 1024 / 1024))GB"
    exit 1
fi
echo "✅ Disk space: $((AVAILABLE_SPACE / 1024 / 1024))GB available"

# Check RAM (minimum 2GB)
TOTAL_RAM=$(free -m | awk '/^Mem:/{print $2}')
REQUIRED_RAM=2048

if [ "$TOTAL_RAM" -lt "$REQUIRED_RAM" ]; then
    echo "❌ Error: Insufficient RAM"
    echo "   Required: 2GB, Available: ${TOTAL_RAM}MB"
    exit 1
fi
echo "✅ RAM: ${TOTAL_RAM}MB available"

# Check internet connectivity
if ! ping -c 1 google.com &> /dev/null; then
    echo "❌ Error: No internet connection"
    exit 1
fi
echo "✅ Internet connection available"

# Check if ports are available
REQUIRED_PORTS=(80 3000 8000)
for port in "${REQUIRED_PORTS[@]}"; do
    if netstat -tuln 2>/dev/null | grep -q ":$port "; then
        echo "⚠️  Warning: Port $port is already in use"
    else
        echo "✅ Port $port is available"
    fi
done

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo "⚠️  Git not found, will be installed"
else
    echo "✅ Git: $(git --version)"
fi

# Check if already installed
if [ -d "/opt/zedin-steam-manager" ]; then
    echo "⚠️  Warning: Previous installation detected at /opt/zedin-steam-manager"
    read -p "Do you want to continue? This will upgrade the existing installation. (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled"
        exit 1
    fi
fi

echo ""
echo "✅ System requirements check passed"
echo ""
