#!/bin/bash

# Zedin Steam Manager Update Script
# Version: 0.000001
# Usage: sudo ./update.sh [--force] [--skip-backup] [--skip-deps]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
INSTALL_DIR="/opt/zedin-steam-manager"
SERVICE_USER="zsmanager"
FRONTEND_DIR="$INSTALL_DIR/frontend"
BACKEND_DIR="$INSTALL_DIR/backend"
VENV_DIR="$INSTALL_DIR/venv"
BACKUP_DIR="$INSTALL_DIR/backups"

# Parse command line arguments
FORCE_UPDATE=false
SKIP_BACKUP=false
SKIP_DEPS=false

for arg in "$@"; do
    case $arg in
        --force)
            FORCE_UPDATE=true
            shift
            ;;
        --skip-backup)
            SKIP_BACKUP=true
            shift
            ;;
        --skip-deps)
            SKIP_DEPS=true
            shift
            ;;
        --help|-h)
            echo "Usage: sudo ./update.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --force        Force update even if no changes detected"
            echo "  --skip-backup  Skip creating backup before update"
            echo "  --skip-deps    Skip dependency updates"
            echo "  --help, -h     Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $arg"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Logging function
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

info() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root (use sudo)"
fi

echo "============================================================================"
echo -e "               ${CYAN}🔄 Zedin Steam Manager Update v0.000001${NC}"
echo "============================================================================"
echo ""

# Check if installation exists
if [ ! -d "$INSTALL_DIR" ]; then
    error "Installation directory not found: $INSTALL_DIR"
fi

# Create backup directory if it doesn't exist
if [ "$SKIP_BACKUP" = false ]; then
    mkdir -p "$BACKUP_DIR"
    chown $SERVICE_USER:$SERVICE_USER "$BACKUP_DIR"
fi

# Check if services are running
log "Checking current service status..."
BACKEND_RUNNING=false
NGINX_RUNNING=false

if systemctl is-active --quiet zsmanager-backend 2>/dev/null; then
    BACKEND_RUNNING=true
    info "Backend service is running"
else
    warning "Backend service is not running"
fi

if systemctl is-active --quiet nginx 2>/dev/null; then
    NGINX_RUNNING=true
    info "Nginx service is running"
else
    warning "Nginx service is not running"
fi

# Navigate to project directory
cd "$INSTALL_DIR" || error "Cannot navigate to $INSTALL_DIR"
log "Working directory: $INSTALL_DIR"

# Check git repository
if [ ! -d ".git" ]; then
    warning "Git repository not initialized"
    if [ "$FORCE_UPDATE" = false ]; then
        error "Cannot update without git repository. Use --force to skip git checks."
    fi
fi

# Create backup before update
if [ "$SKIP_BACKUP" = false ]; then
    BACKUP_NAME="backup_$(date +%Y%m%d_%H%M%S)"
    BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"
    
    log "Creating backup: $BACKUP_NAME"
    mkdir -p "$BACKUP_PATH"
    
    # Backup database
    if [ -f "$BACKEND_DIR/zedin_steam_manager.db" ]; then
        cp "$BACKEND_DIR/zedin_steam_manager.db" "$BACKUP_PATH/database.db"
        log "✓ Database backed up"
    fi
    
    # Backup .env file
    if [ -f "$BACKEND_DIR/.env" ]; then
        cp "$BACKEND_DIR/.env" "$BACKUP_PATH/.env"
        log "✓ Environment config backed up"
    fi
    
    # Keep only last 5 backups
    cd "$BACKUP_DIR"
    ls -t | tail -n +6 | xargs -r rm -rf
    cd "$INSTALL_DIR"
    
    log "✓ Backup created successfully"
fi

# Pull latest changes from git
if [ -d ".git" ]; then
    log "Fetching latest changes from GitHub..."
    
    # Store current commit
    CURRENT_COMMIT=$(git rev-parse HEAD)
    
    # Stash any local changes
    if ! git diff-index --quiet HEAD --; then
        warning "Local changes detected, stashing..."
        git stash
    fi
    
    # Fetch and pull
    if git fetch origin; then
        log "✓ Fetched from origin"
        
        # Check if there are updates
        REMOTE_COMMIT=$(git rev-parse origin/main)
        
        if [ "$CURRENT_COMMIT" = "$REMOTE_COMMIT" ] && [ "$FORCE_UPDATE" = false ]; then
            info "Already up to date (commit: ${CURRENT_COMMIT:0:7})"
            echo ""
            echo "No updates available. Use --force to reinstall anyway."
            exit 0
        fi
        
        # Pull changes
        if git pull origin main; then
            NEW_COMMIT=$(git rev-parse HEAD)
            log "✓ Updated from ${CURRENT_COMMIT:0:7} to ${NEW_COMMIT:0:7}"
            
            # Show what changed
            echo ""
            info "Changes in this update:"
            git log --oneline --no-decorate "${CURRENT_COMMIT}..${NEW_COMMIT}" | head -n 5
            echo ""
        else
            error "Git pull failed"
        fi
    else
        warning "Git fetch failed - continuing with existing files"
    fi
else
    warning "Not a git repository - skipping git operations"
fi

# Check for backend changes
log "Checking for backend updates..."
cd "$BACKEND_DIR" || error "Cannot navigate to backend directory"

BACKEND_UPDATED=false

# Update Python dependencies if requirements.txt exists
if [ -f "requirements.txt" ] && [ "$SKIP_DEPS" = false ]; then
    if [ -d ".git" ]; then
        if git diff HEAD~1 HEAD --quiet requirements.txt 2>/dev/null; then
            info "No changes in requirements.txt"
        else
            log "Requirements.txt changed - updating Python dependencies..."
            BACKEND_UPDATED=true
        fi
    else
        log "Updating Python dependencies..."
        BACKEND_UPDATED=true
    fi
    
    if [ "$BACKEND_UPDATED" = true ] || [ "$FORCE_UPDATE" = true ]; then
        if [ -f "$VENV_DIR/bin/pip" ]; then
            sudo -u $SERVICE_USER $VENV_DIR/bin/pip install --upgrade pip
            sudo -u $SERVICE_USER $VENV_DIR/bin/pip install -r requirements.txt
            log "✓ Python dependencies updated"
        else
            error "Virtual environment not found at $VENV_DIR"
        fi
    fi
fi

# Check if main.py or other backend files changed
if [ -d ".git" ]; then
    if ! git diff HEAD~1 HEAD --quiet *.py routers/ models/ services/ 2>/dev/null; then
        info "Backend code changes detected"
        BACKEND_UPDATED=true
    fi
fi

# Check for frontend changes
log "Checking for frontend updates..."
cd "$FRONTEND_DIR" || error "Cannot navigate to frontend directory"

FRONTEND_UPDATED=false

# Check if package.json exists (source structure)
if [ -f "package.json" ] && [ "$SKIP_DEPS" = false ]; then
    if [ -d ".git" ]; then
        if git diff HEAD~1 HEAD --quiet package.json 2>/dev/null; then
            info "No changes in package.json"
        else
            log "Package.json changed - updating Node.js dependencies..."
            FRONTEND_UPDATED=true
        fi
    else
        FRONTEND_UPDATED=true
    fi
    
    if [ "$FRONTEND_UPDATED" = true ] || [ "$FORCE_UPDATE" = true ]; then
        sudo -u $SERVICE_USER npm install
        log "✓ Node.js dependencies updated"
    fi
    
    # Check for source changes
    if [ -d "src" ]; then
        if [ -d ".git" ]; then
            if ! git diff HEAD~1 HEAD --quiet src/ 2>/dev/null; then
                log "Frontend source changes detected - rebuilding..."
                FRONTEND_UPDATED=true
            fi
        fi
        
        if [ "$FRONTEND_UPDATED" = true ] || [ "$FORCE_UPDATE" = true ]; then
            sudo -u $SERVICE_USER npm run build
            log "✓ Frontend rebuilt successfully"
        fi
    fi
elif [ -d "dist" ]; then
    # Pre-built frontend structure
    if [ -d ".git" ]; then
        if ! git diff HEAD~1 HEAD --quiet dist/ 2>/dev/null; then
            log "Pre-built frontend changes detected"
            FRONTEND_UPDATED=true
        fi
    fi
    
    # Ensure proper ownership
    chown -R $SERVICE_USER:$SERVICE_USER "$FRONTEND_DIR"
    log "✓ Frontend files updated"
else
    warning "No frontend structure found (neither src/ nor dist/)"
fi

# Check for database model changes
log "Checking for database changes..."
cd "$INSTALL_DIR"

if [ -d "$BACKEND_DIR/models" ]; then
    if [ -d ".git" ]; then
        if ! git diff HEAD~1 HEAD --quiet backend/models/ 2>/dev/null; then
            warning "Database model changes detected"
            info "Database schema may need migration"
            
            # Check if Alembic is configured
            if [ -f "$BACKEND_DIR/alembic.ini" ]; then
                echo ""
                read -p "Run database migration now? (y/N): " -n 1 -r
                echo ""
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    log "Running database migration..."
                    cd "$BACKEND_DIR"
                    sudo -u $SERVICE_USER $VENV_DIR/bin/python -m alembic upgrade head
                    log "✓ Database migrated successfully"
                fi
            else
                info "Manual database check recommended"
                info "Models changed in: backend/models/"
            fi
        fi
    fi
fi

# Ensure correct permissions
log "Fixing permissions..."
chown -R $SERVICE_USER:$SERVICE_USER "$INSTALL_DIR"
chmod -R 755 "$INSTALL_DIR"
chmod -R 775 "$BACKEND_DIR/logs" 2>/dev/null || true
chmod 600 "$BACKEND_DIR/.env" 2>/dev/null || true
log "✓ Permissions updated"

# Restart services if they were running
if [ "$BACKEND_RUNNING" = true ] || [ "$BACKEND_UPDATED" = true ]; then
    log "Restarting backend service..."
    
    if systemctl restart zsmanager-backend; then
        sleep 3
        
        if systemctl is-active --quiet zsmanager-backend; then
            log "✓ Backend service restarted successfully"
        else
            error "Backend service failed to restart - check logs: journalctl -u zsmanager-backend -n 50"
        fi
    else
        error "Failed to restart backend service"
    fi
elif [ "$BACKEND_RUNNING" = false ]; then
    info "Backend service was not running - not restarting"
    info "Start with: sudo systemctl start zsmanager-backend"
fi

# Reload nginx if it's running
if [ "$NGINX_RUNNING" = true ] || [ "$FRONTEND_UPDATED" = true ]; then
    log "Reloading nginx configuration..."
    
    # Test nginx config first
    if nginx -t 2>/dev/null; then
        if systemctl reload nginx; then
            log "✓ Nginx reloaded successfully"
        else
            warning "Nginx reload failed - trying restart..."
            systemctl restart nginx
        fi
    else
        warning "Nginx configuration test failed - not reloading"
    fi
elif [ "$NGINX_RUNNING" = false ]; then
    info "Nginx was not running - not reloading"
fi

# Final status check
log "Performing final status check..."

BACKEND_STATUS="${RED}✗ Not running${NC}"
NGINX_STATUS="${RED}✗ Not running${NC}"
API_STATUS="${RED}✗ Not accessible${NC}"

if systemctl is-active --quiet zsmanager-backend 2>/dev/null; then
    BACKEND_STATUS="${GREEN}✓ Running${NC}"
fi

if systemctl is-active --quiet nginx 2>/dev/null; then
    NGINX_STATUS="${GREEN}✓ Running${NC}"
fi

# Test API endpoint
SERVER_IP=$(hostname -I | awk '{print $1}')
if curl -f -s "http://localhost:8000/api/health" > /dev/null 2>&1; then
    API_STATUS="${GREEN}✓ Accessible${NC}"
fi

# Get current version
CURRENT_VERSION="0.000001"
if [ -f "$BACKEND_DIR/main.py" ]; then
    VERSION_FROM_CODE=$(grep -oP 'version.*?"\K[0-9.]+' "$BACKEND_DIR/main.py" | head -n1)
    if [ ! -z "$VERSION_FROM_CODE" ]; then
        CURRENT_VERSION="$VERSION_FROM_CODE"
    fi
fi

echo ""
echo "============================================================================"
echo -e "                    ${GREEN}✅ UPDATE COMPLETE!${NC}"
echo "============================================================================"
echo ""
echo -e "📊 ${CYAN}Service Status:${NC}"
echo -e "   Backend: $BACKEND_STATUS"
echo -e "   Nginx: $NGINX_STATUS"
echo -e "   API: $API_STATUS"
echo ""
echo -e "🏷️  ${CYAN}Version:${NC} $CURRENT_VERSION"
echo ""
echo -e "🌐 ${CYAN}Access Points:${NC}"
echo "   Web Interface: http://$SERVER_IP"
echo "   API Endpoint: http://$SERVER_IP/api"
echo "   API Docs: http://$SERVER_IP/docs"
echo ""
echo -e "🔧 ${CYAN}Useful Commands:${NC}"
echo "   View logs: sudo journalctl -f -u zsmanager-backend"
echo "   Restart backend: sudo systemctl restart zsmanager-backend"
echo "   Check status: sudo systemctl status zsmanager-backend"
echo "   Update again: cd $INSTALL_DIR && sudo ./update.sh"
echo "   Force update: cd $INSTALL_DIR && sudo ./update.sh --force"
echo ""
if [ "$SKIP_BACKUP" = false ]; then
    echo -e "💾 ${CYAN}Backup Location:${NC} $BACKUP_PATH"
    echo ""
fi
echo -e "📖 ${CYAN}Documentation:${NC}"
echo "   Maintenance: $INSTALL_DIR/MAINTENANCE.md"
echo "   Auth System: $INSTALL_DIR/AUTH_SYSTEM.md"
echo "   Main README: $INSTALL_DIR/README.md"
echo ""
echo "============================================================================"

log "Update completed successfully!"
exit 0