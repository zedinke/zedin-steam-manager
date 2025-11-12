#!/bin/bash

# ============================================================================
# Zedin Steam Manager - Windows Telepítő Szimulátor 
# ============================================================================
# Ez a script szimulálja a Linux telepítő működését Windows környezetben
# Git Bash vagy WSL2 használatával

set -e
trap 'echo "❌ Script interrupted"; exit 1' INT

# Színes kimenetek
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging funkciók
log() {
    echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] ${GREEN}$1${NC}"
}

warn() {
    echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] ${YELLOW}WARNING:${NC} $1"
}

error() {
    echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] ${RED}ERROR:${NC} $1" >&2
    exit 1
}

# ASCII Art Banner
show_banner() {
    echo -e "${BLUE}"
    echo "============================================================================"
    echo "  ███████╗███████╗██████╗ ██╗███╗   ██╗    ███████╗███╗   ███╗"
    echo "  ╚══███╔╝██╔════╝██╔══██╗██║████╗  ██║    ██╔════╝████╗ ████║"
    echo "    ███╔╝ █████╗  ██║  ██║██║██╔██╗ ██║    ███████╗██╔████╔██║"
    echo "   ███╔╝  ██╔══╝  ██║  ██║██║██║╚██╗██║    ╚════██║██║╚██╔╝██║"
    echo "  ███████╗███████╗██████╔╝██║██║ ╚████║    ███████║██║ ╚═╝ ██║"
    echo "  ╚══════╝╚══════╝╚═════╝ ╚═╝╚═╝  ╚═══╝    ╚══════╝╚═╝     ╚═╝"
    echo ""
    echo "                    🎮 STEAM SERVER MANAGER 🎮"
    echo "                       Windows Szimulátor v0.1"
    echo "============================================================================"
    echo -e "${NC}"
}

# Konfiguráció
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$SCRIPT_DIR/simulated_linux"
LOG_DIR="$INSTALL_DIR/logs"
DATA_DIR="$INSTALL_DIR/data"
SERVICE_USER="zsmanager"

# Fő funkciók
initialize_simulation() {
    log "Szimuláció inicializálása..."
    
    # Könyvtárak létrehozása
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$LOG_DIR"
    mkdir -p "$DATA_DIR"
    mkdir -p "$INSTALL_DIR/backend"
    mkdir -p "$INSTALL_DIR/frontend"
    mkdir -p "$INSTALL_DIR/config"
    mkdir -p "$INSTALL_DIR/steamcmd"
    
    # Fájlok másolása
    if [ -d "$SCRIPT_DIR/backend" ]; then
        log "Backend fájlok másolása..."
        cp -r "$SCRIPT_DIR/backend"/* "$INSTALL_DIR/backend/"
    fi
    
    if [ -d "$SCRIPT_DIR/frontend" ]; then
        log "Frontend fájlok másolása..."
        cp -r "$SCRIPT_DIR/frontend"/* "$INSTALL_DIR/frontend/"
    fi
    
    log "✓ Fájlok sikeresen másolva"
}

simulate_dependencies() {
    log "Függőségek szimulálása..."
    
    # Node.js ellenőrzés
    if command -v node &> /dev/null; then
        log "✓ Node.js már telepítve: $(node --version)"
    else
        warn "Node.js nincs telepítve"
    fi
    
    # Python ellenőrzés  
    if command -v python &> /dev/null; then
        log "✓ Python már telepítve: $(python --version)"
    elif command -v python3 &> /dev/null; then
        log "✓ Python3 már telepítve: $(python3 --version)"
    else
        warn "Python nincs telepítve"
    fi
    
    # Git ellenőrzés
    if command -v git &> /dev/null; then
        log "✓ Git már telepítve: $(git --version)"
    else
        warn "Git nincs telepítve"
    fi
}

simulate_backend_install() {
    log "Backend telepítés szimulálása..."
    
    cd "$INSTALL_DIR/backend"
    
    # Virtual environment szimuláció
    if [ -f "requirements.txt" ]; then
        log "Python függőségek szimulálása..."
        echo "✓ FastAPI==0.104.1 (szimulálva)" > "$LOG_DIR/pip_install.log"
        echo "✓ Uvicorn==0.24.0 (szimulálva)" >> "$LOG_DIR/pip_install.log"
        echo "✓ SQLAlchemy==2.0.23 (szimulálva)" >> "$LOG_DIR/pip_install.log"
        log "✓ Python függőségek telepítve (szimulálva)"
    fi
    
    # Konfigurációs fájl létrehozása
    cat > "$INSTALL_DIR/config/zsmanager.env" << EOF
# Zedin Steam Manager Konfiguráció (Szimuláció)
HOST=0.0.0.0
PORT=8000
DATABASE_URL=sqlite:///$DATA_DIR/zedin_steam_manager.db
SECRET_KEY=simulated_secret_key_123456
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=1440
STEAMCMD_PATH=$INSTALL_DIR/steamcmd
SHARED_FILES_PATH=$DATA_DIR/shared_files
SERVERS_PATH=$DATA_DIR/servers
LOG_FILE=$LOG_DIR/steam_manager.log
ASE_APP_ID=376030
ASA_APP_ID=2430930
GITHUB_REPO=zedinke/zedin-steam-manager
UPDATE_CHECK_INTERVAL=3600
SYSTEM_MONITOR_INTERVAL=5
EOF
    
    log "✓ Backend konfiguráció létrehozva"
}

simulate_frontend_build() {
    log "Frontend build szimulálása..."
    
    cd "$INSTALL_DIR/frontend"
    
    if [ -f "package.json" ]; then
        log "Node.js függőségek szimulálása..."
        
        # TypeScript check szimuláció
        log "TypeScript ellenőrzés..."
        if [ -f "tsconfig.json" ]; then
            log "✓ tsconfig.json megtalálva"
        else
            warn "tsconfig.json hiányzik"
        fi
        
        # Build szimuláció
        mkdir -p "dist"
        cat > "dist/index.html" << EOF
<!DOCTYPE html>
<html lang="hu">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Zedin Steam Manager - Szimuláció</title>
    <style>
        body { font-family: Arial, sans-serif; background: #1a1a1a; color: white; margin: 0; padding: 20px; }
        .container { max-width: 1200px; margin: 0 auto; }
        .header { text-align: center; margin-bottom: 30px; }
        .card { background: #2d2d2d; padding: 20px; border-radius: 8px; margin: 10px 0; }
        .success { color: #4CAF50; }
        .warning { color: #FF9800; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🎮 Zedin Steam Manager</h1>
            <h3>Telepítő Szimuláció</h3>
        </div>
        
        <div class="card">
            <h3 class="success">✅ Telepítés Sikeres!</h3>
            <p>A Zedin Steam Manager sikeresen telepítve lett szimuláció módban.</p>
        </div>
        
        <div class="card">
            <h3>🚀 Funkciók</h3>
            <ul>
                <li class="success">✅ Backend API (szimulálva)</li>
                <li class="success">✅ React Frontend</li>
                <li class="success">✅ Steam Server Management</li>
                <li class="success">✅ RCON Integration</li>
                <li class="success">✅ System Monitoring</li>
            </ul>
        </div>
        
        <div class="card">
            <h3>📍 Elérési pontok</h3>
            <ul>
                <li>Web Interface: <code>file://$INSTALL_DIR/frontend/dist/index.html</code></li>
                <li>API Documentation: <code>http://localhost:8000/docs</code> (szimulálva)</li>
                <li>Backend Logs: <code>$LOG_DIR/steam_manager.log</code></li>
            </ul>
        </div>
        
        <div class="card">
            <h3>🔧 Következő lépések</h3>
            <p>Éles telepítéshez futtasd a script-et Linux szerveren:</p>
            <pre><code>ssh user@server "bash ./install.sh"</code></pre>
        </div>
    </div>
    
    <script>
        console.log('🎮 Zedin Steam Manager - Telepítő Szimuláció');
        console.log('✅ Frontend build szimulálva');
    </script>
</body>
</html>
EOF
        
        log "✓ Frontend build létrehozva (szimulálva)"
    fi
}

simulate_services() {
    log "Szolgáltatások szimulálása..."
    
    # Service fájlok létrehozása
    cat > "$INSTALL_DIR/config/zsmanager-backend.service" << EOF
[Unit]
Description=Zedin Steam Manager Backend (Simulation)
After=network.target

[Service]
Type=simple
User=$SERVICE_USER
WorkingDirectory=$INSTALL_DIR/backend
EnvironmentFile=$INSTALL_DIR/config/zsmanager.env
ExecStart=python3 main.py
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

    # Nginx konfiguráció
    cat > "$INSTALL_DIR/config/nginx.conf" << EOF
server {
    listen 8080;
    server_name localhost;
    root $INSTALL_DIR/frontend/dist;
    index index.html;

    location / {
        try_files \$uri \$uri/ /index.html;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:8000/api/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF
    
    log "✓ Szolgáltatás fájlok létrehozva"
}

generate_summary() {
    echo ""
    echo -e "${GREEN}============================================================================${NC}"
    echo -e "${GREEN}                    🎉 SZIMULÁCIÓ BEFEJEZVE! 🎉${NC}"
    echo -e "${GREEN}============================================================================${NC}"
    echo ""
    echo -e "${CYAN}📊 Telepítés összefoglaló:${NC}"
    echo -e "   Backend: ${GREEN}✓ Telepítve${NC} ($INSTALL_DIR/backend)"
    echo -e "   Frontend: ${GREEN}✓ Felépítve${NC} ($INSTALL_DIR/frontend/dist)"
    echo -e "   Konfiguráció: ${GREEN}✓ Létrehozva${NC} ($INSTALL_DIR/config)"
    echo ""
    echo -e "${CYAN}🌐 Elérési pontok:${NC}"
    echo -e "   Web Interface: ${BLUE}file://$INSTALL_DIR/frontend/dist/index.html${NC}"
    echo -e "   Backend API: ${BLUE}http://localhost:8000${NC} (szimulálva)"
    echo -e "   Logok: ${BLUE}$LOG_DIR/${NC}"
    echo ""
    echo -e "${CYAN}🔧 Hasznos parancsok:${NC}"
    echo -e "   Fájlok megtekintése: ${YELLOW}explorer $INSTALL_DIR${NC}"
    echo -e "   Web interface megnyitása: ${YELLOW}start $INSTALL_DIR/frontend/dist/index.html${NC}"
    echo -e "   Logok olvasása: ${YELLOW}cat $LOG_DIR/*.log${NC}"
    echo ""
    echo -e "${PURPLE}✨ Éles telepítéshez használd a következő parancsot Linux szerveren:${NC}"
    echo -e "   ${YELLOW}sudo ./install.sh${NC}"
    echo ""
    echo -e "${GREEN}============================================================================${NC}"
}

# Fő szkript végrehajtás
main() {
    show_banner
    
    echo -e "${YELLOW}Ez egy szimuláció - nem végez valódi telepítést!${NC}"
    echo ""
    echo -n "Folytatod a szimulációt? (y/N): "
    read -r REPLY
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Szimuláció megszakítva."
        exit 1
    fi
    
    log "Zedin Steam Manager telepítő szimuláció indítása..."
    
    initialize_simulation
    simulate_dependencies  
    simulate_backend_install
    simulate_frontend_build
    simulate_services
    
    generate_summary
    
    # Web interface automatikus megnyitása
    if command -v explorer.exe &> /dev/null; then
        log "Web interface megnyitása..."
        explorer.exe "$INSTALL_DIR/frontend/dist/index.html"
    fi
}

# Script futtatása
main "$@"