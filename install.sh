#!/bin/bash

# ============================================================================
# Zedin Steam Manager - Production Installation Script
# Ubuntu/Debian systems - Full installation with all features
# ============================================================================

# Load installation modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/install-modules.sh"

# Pre-installation checks
check_root
check_os

# Show banner
show_banner "ZEDIN STEAM MANAGER - PRODUCTION INSTALLATION"
log "🚀 Starting production installation with all features..."
log "⏱️  Estimated time: 10-15 minutes"
echo ""

# Check if running from target directory
if [ "$(pwd)" = "/opt/zedin-steam-manager" ]; then
    log "⚠️  Running from target directory - will skip file copying"
fi

confirm_installation

# Installation phases
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