#!/bin/bash

#############################################
# Zedin Steam Manager - Main Installer
# Version: 0.0.1-alpha
# Platform: Linux
#############################################

set -e  # Exit on error

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BLOCKS_DIR="$SCRIPT_DIR/blocks"
LOG_DIR="$SCRIPT_DIR/logs"
INSTALL_LOG="$LOG_DIR/install-$(date +%Y%m%d-%H%M%S).log"

# Create log directory
mkdir -p "$LOG_DIR"

# Logging function
log() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$INSTALL_LOG"
}

# Print colored message
print_msg() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
    log "INFO" "$message"
}

# Print header
print_header() {
    clear
    print_msg "$BLUE" "=============================================="
    print_msg "$BLUE" "  Zedin Steam Manager - Installer v0.0.1"
    print_msg "$BLUE" "=============================================="
    echo ""
}

# Check if block exists
check_block() {
    local block=$1
    if [ ! -f "$BLOCKS_DIR/$block" ]; then
        print_msg "$RED" "❌ Error: Block $block not found!"
        log "ERROR" "Block $block not found at $BLOCKS_DIR/$block"
        exit 1
    fi
}

# Execute installation block
execute_block() {
    local block=$1
    local description=$2
    
    check_block "$block"
    
    print_msg "$YELLOW" "▶ $description"
    log "INFO" "Starting block: $block - $description"
    
    if bash "$BLOCKS_DIR/$block" 2>&1 | tee -a "$INSTALL_LOG"; then
        print_msg "$GREEN" "✅ $description - Completed"
        log "SUCCESS" "Block completed: $block"
        return 0
    else
        print_msg "$RED" "❌ $description - Failed"
        log "ERROR" "Block failed: $block"
        return 1
    fi
}

# Main installation process
main() {
    print_header
    
    log "INFO" "Installation started"
    log "INFO" "Script directory: $SCRIPT_DIR"
    log "INFO" "Blocks directory: $BLOCKS_DIR"
    log "INFO" "Log file: $INSTALL_LOG"
    
    # Installation blocks in order
    BLOCKS=(
        "01-system-check.sh:System Requirements Check"
        "02-dependencies.sh:Installing Dependencies"
        "03-database.sh:Database Configuration"
        "04-backend.sh:Backend Setup"
        "05-frontend.sh:Frontend Setup"
        "06-services.sh:Service Configuration"
        "07-nginx.sh:Web Server Setup"
    )
    
    local total=${#BLOCKS[@]}
    local current=0
    
    for block_info in "${BLOCKS[@]}"; do
        current=$((current + 1))
        IFS=':' read -r block_file description <<< "$block_info"
        
        echo ""
        print_msg "$BLUE" "[$current/$total] $description"
        echo ""
        
        if ! execute_block "$block_file" "$description"; then
            print_msg "$RED" "Installation failed at: $description"
            print_msg "$YELLOW" "Check log file: $INSTALL_LOG"
            log "ERROR" "Installation aborted"
            exit 1
        fi
        
        sleep 1
    done
    
    # Installation complete
    echo ""
    print_header
    print_msg "$GREEN" "✅ Installation Complete!"
    echo ""
    print_msg "$BLUE" "🌐 Access your manager at:"
    print_msg "$GREEN" "   http://$(hostname -I | awk '{print $1}')"
    echo ""
    print_msg "$BLUE" "📋 Installation log:"
    print_msg "$GREEN" "   $INSTALL_LOG"
    echo ""
    print_msg "$BLUE" "📚 Documentation:"
    print_msg "$GREEN" "   https://github.com/zedinke/zedin-steam-manager"
    echo ""
    
    log "INFO" "Installation completed successfully"
}

# Run main installation
main "$@"
