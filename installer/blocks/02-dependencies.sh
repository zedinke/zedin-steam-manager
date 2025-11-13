#!/bin/bash

#############################################
# Block 02: Install Dependencies
#############################################

echo "Installing system dependencies..."

# Detect package manager
if command -v apt-get &> /dev/null; then
    PKG_MANAGER="apt-get"
    PKG_UPDATE="apt-get update -qq"
    PKG_INSTALL="apt-get install -y -qq"
elif command -v yum &> /dev/null; then
    PKG_MANAGER="yum"
    PKG_UPDATE="yum check-update || true"
    PKG_INSTALL="yum install -y"
elif command -v dnf &> /dev/null; then
    PKG_MANAGER="dnf"
    PKG_UPDATE="dnf check-update || true"
    PKG_INSTALL="dnf install -y"
else
    echo "❌ Error: No supported package manager found"
    exit 1
fi

echo "✅ Package manager: $PKG_MANAGER"

# Update package lists
echo "Updating package lists..."
$PKG_UPDATE

# Install dependencies based on package manager
if [ "$PKG_MANAGER" = "apt-get" ]; then
    PACKAGES=(
        "python3"
        "python3-pip"
        "python3-venv"
        "nodejs"
        "npm"
        "nginx"
        "git"
        "curl"
        "wget"
        "net-tools"
    )
elif [ "$PKG_MANAGER" = "yum" ] || [ "$PKG_MANAGER" = "dnf" ]; then
    PACKAGES=(
        "python3"
        "python3-pip"
        "python3-virtualenv"
        "nodejs"
        "npm"
        "nginx"
        "git"
        "curl"
        "wget"
        "net-tools"
    )
fi

# Install each package with verification
for package in "${PACKAGES[@]}"; do
    if ! command -v ${package//3/} &> /dev/null && ! dpkg -l | grep -q "^ii  $package"; then
        echo "Installing $package..."
        $PKG_INSTALL $package
        if [ $? -eq 0 ]; then
            echo "✅ $package installed"
        else
            echo "❌ Failed to install $package"
            exit 1
        fi
    else
        echo "✅ $package already installed"
    fi
done

# Verify Python version
PYTHON_VERSION=$(python3 --version | awk '{print $2}')
echo "✅ Python version: $PYTHON_VERSION"

# Verify Node.js version
NODE_VERSION=$(node --version)
echo "✅ Node.js version: $NODE_VERSION"

# Verify npm version
NPM_VERSION=$(npm --version)
echo "✅ npm version: $NPM_VERSION"

# Verify Nginx
if ! command -v nginx &> /dev/null; then
    echo "❌ Error: Nginx installation failed"
    exit 1
fi
NGINX_VERSION=$(nginx -v 2>&1 | awk -F/ '{print $2}')
echo "✅ Nginx version: $NGINX_VERSION"

# Verify Git
if ! command -v git &> /dev/null; then
    echo "❌ Error: Git installation failed"
    exit 1
fi
GIT_VERSION=$(git --version | awk '{print $3}')
echo "✅ Git version: $GIT_VERSION"

echo ""
echo "✅ All dependencies installed successfully"
echo ""
