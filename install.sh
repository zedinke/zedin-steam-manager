#!/bin/bash

# ============================================================================
# Zedin Steam Manager - Universal Installation Script
# Ubuntu/Debian systems - Choose your installation type
# ============================================================================

# Load installation modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/install-modules.sh"

# Pre-installation checks
check_root
check_os

# Installation type selection
echo "============================================================================"
echo "          🚀 Zedin Steam Manager - Universal Installer"
echo "============================================================================"
echo ""
echo "Choose your installation type:"
echo ""
echo "1) 🚀 Simple Installation (Recommended)"
echo "   • Fast deployment (3-5 minutes)" 
echo "   • Pre-built frontend"
echo "   • Essential features only"
echo ""
echo "2) 🔧 Full Installation (Advanced)"
echo "   • Complete setup (10-15 minutes)"
echo "   • All features and tools"
echo "   • Development environment"
echo ""
echo -n "Select installation type (1/2): "
read -r INSTALL_TYPE
echo

case $INSTALL_TYPE in
    1)
        show_banner "SIMPLE INSTALLATION (Fast Deployment)"
        log "⚡ Starting simple installation..."
        ;;
    2)
        show_banner "FULL INSTALLATION (All Features)"
        log "🚀 Starting full installation..."
        ;;
    *)
        error "Invalid selection. Please run the installer again and choose 1 or 2."
        ;;
esac

# Check if running from target directory
if [ "$(pwd)" = "/opt/zedin-steam-manager" ]; then
    log "⚠️  Running from target directory - will skip file copying"
fi

confirm_installation

# Common installation phases
install_system_deps
setup_user_dirs  
download_app
install_backend
deploy_frontend
create_config
setup_services
setup_nginx
init_database
start_services

# Check final status
check_status
show_completion

log "Installation completed successfully!"