# Zedin Steam Manager

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python](https://img.shields.io/badge/python-3.9+-blue.svg)](https://www.python.org/downloads/)
[![Node.js](https://img.shields.io/badge/node.js-18+-green.svg)](https://nodejs.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.104+-00a393.svg)](https://fastapi.tiangolo.com/)
[![React](https://img.shields.io/badge/React-18+-61dafb.svg)](https://reactjs.org/)

Professional Steam Server Manager for ASE (Ark: Survival Evolved) and ASA (Ark: Survival Ascended) servers.

## Features

### Core Manager Functionality
- **Version Control**: Automatic version tracking (V 0.000001)
- **Update System**: Hourly GitHub version checking with notification system
- **Real-time Monitoring**: 5-second system resource updates (RAM/HDD/CPU/Network)
- **Multi-language Support**: i18n with browser language detection

### Server Management
- **Server Status Monitoring**: Real-time server status (RUNNING, STOPPED, INSTALLING, NOT_INSTALLED)
- **Start/Stop Control**: Safe server shutdown using RCON DoExit command
- **Live Installation Logging**: Real-time log viewing during installation with 1-second updates
- **RCON Integration**: Player listing (ListPlayers) and command execution
- **Configuration Management**: Web-based .ini file editing (GameUserSettings.ini, Game.ini, Engine.ini)

### File Management
- **Shared Files System**: Centralized storage for ASE/ASA files to save disk space
- **File Operations**: Dashboard-based shared file deletion for both ASE and ASA
- **SteamCMD Integration**: Automated game file installation and updates

### Infrastructure
- **Multi-Host Support**: Remote server management via SSH
- **Database Management**: SQLAlchemy with comprehensive data storage
- **RESTful API**: FastAPI with dedicated endpoints for all operations
- **Desktop Application**: Electron-based UI with React frontend

## Architecture

```
Zedin Steam Manager/
├── backend/                 # FastAPI Python backend
│   ├── main.py             # Application entry point
│   ├── config/             # Database and settings configuration
│   ├── models/             # SQLAlchemy database models
│   ├── routers/            # API route handlers
│   ├── services/           # Business logic services
│   └── requirements.txt    # Python dependencies
├── frontend/               # React TypeScript frontend
│   ├── src/
│   │   ├── components/     # Reusable UI components
│   │   ├── pages/          # Application pages
│   │   ├── services/       # API service layer
│   │   └── stores/         # State management
│   ├── package.json
│   └── vite.config.ts
├── electron/               # Electron desktop wrapper
│   ├── main.ts             # Electron main process
│   └── tsconfig.json
└── package.json            # Root package configuration
```

## Technology Stack

- **Backend**: FastAPI, SQLAlchemy, Uvicorn, APScheduler
- **Frontend**: React, TypeScript, Material-UI, React Query, Zustand
- **Desktop**: Electron with auto-updater
- **Database**: SQLite (production-ready with PostgreSQL support)
- **Authentication**: JWT tokens with secure user management
- **Infrastructure**: Docker-ready, SSH remote management

## Installation

### Prerequisites
- Node.js 18+ 
- Python 3.9+
- Git
- Ubuntu/Debian Linux (for production)
- Non-root user with sudo privileges

### User and Group Setup (Linux/Production)

Before installing, create the proper user and group for the Steam Manager:

```bash
# 1. Create zsmanager group
sudo groupadd zsmanager

# 2. Create zsmanager user (system user for service)
sudo useradd -r -m -g zsmanager -s /bin/bash zsmanager

# 3. Set password for zsmanager user (required for security)
sudo passwd zsmanager
# Enter a secure password when prompted

# 4. Add zsmanager user to sudo group (for system operations)
sudo usermod -aG sudo zsmanager

# 5. Create your personal user (if not exists) and add to zsmanager group
sudo useradd -m -g users -G zsmanager -s /bin/bash yourusername
# OR add existing user to zsmanager group:
sudo usermod -aG zsmanager yourusername

# 6. Set password for your personal user (if newly created)
sudo passwd yourusername
# Enter a secure password when prompted

# 5. Set up directory permissions
sudo mkdir -p /opt/zedin-steam-manager
sudo mkdir -p /var/lib/zedin/{servers,shared_files,backups}
sudo mkdir -p /var/log/zedin
sudo mkdir -p /etc/zedin

# 6. Set proper ownership
sudo chown -R zsmanager:zsmanager /opt/zedin-steam-manager
sudo chown -R zsmanager:zsmanager /var/lib/zedin
sudo chown -R zsmanager:zsmanager /var/log/zedin

# 7. Set directory permissions
sudo chmod 755 /opt/zedin-steam-manager
sudo chmod 755 /var/lib/zedin
sudo chmod 755 /var/log/zedin
sudo chmod 750 /etc/zedin

# 8. Switch to regular user (NOT root) for installation
su - yourusername  # Replace with your username
```

### 🔐 Security Notes for User Setup

- **Strong Passwords**: Always use strong, unique passwords for both `zsmanager` and personal users
- **SSH Keys**: Consider setting up SSH key authentication instead of password-only access
- **Limited Privileges**: The `zsmanager` user has sudo access only for system operations
- **Service Account**: `zsmanager` is designed as a service account - avoid using it for daily operations
- **Regular Updates**: Keep user passwords updated regularly for security

### Important: Installation User Requirements

⚠️ **NEVER run the installer as root!**

The installer must be run as a regular user with sudo privileges because:
- Root user is blocked for security reasons
- Services run under dedicated `zsmanager` user
- Proper file permissions are automatically set
- Security policies prevent root service execution

### 🚀 Quick Installation

#### Option 1: Simplified Installer (Recommended)
```bash
curl -sSL https://raw.githubusercontent.com/zedinke/zedin-steam-manager/main/install-simple.sh | bash
```

#### Option 2: Manual Installation  
```bash
git clone https://github.com/zedinke/zedin-steam-manager.git
cd zedin-steam-manager
chmod +x install-simple.sh
sudo ./install-simple.sh
```

#### Option 3: Advanced Installation (Full Features)
```bash
curl -sSL https://raw.githubusercontent.com/zedinke/zedin-steam-manager/main/install.sh | bash
```

### 🛠️ Production Deployment Issues?

If you experience white screen or installation problems:

```bash
# Complete production fix
sudo ./deploy-production.sh

# Debug service issues  
sudo ./debug-service.sh

# Check installation guide
cat PRODUCTION_FIX.md
```

### Quick Start
```bash
# Clone repository (as regular user, NOT root)
git clone https://github.com/zedinke/zedin-steam-manager.git
cd zedin-steam-manager

# For development:
npm run install:all
npm run dev

# For production (Linux):
chmod +x install.sh
sudo ./install.sh  # This will handle everything automatically
```

### Production Installation (Automated)

The `install.sh` script automatically handles:

1. **System Dependencies**: Python, Node.js, SteamCMD
2. **User Management**: Creates `zsmanager` service user
3. **Directory Setup**: Creates all required directories with proper permissions
4. **Application Installation**: Installs backend and frontend
5. **Service Configuration**: Sets up systemd services
6. **Web Server**: Configures Nginx reverse proxy
7. **Firewall**: Configures UFW for game server ports
8. **Security**: Implements non-root service execution

After installation, the application will be available at:
- **Web Interface**: `http://your-server-ip/`
- **API Documentation**: `http://your-server-ip/docs`

### Manual Installation (Development)
```bash
# Install all dependencies
npm run install:all

# Start development environment
npm run dev
```

This will start:
- Backend API server on http://localhost:8000
- Frontend development server on http://localhost:3000  
- Electron desktop application

### Production Build
```bash
# Build all components
npm run build

# Start production server
npm start
```

## Service Management (Production)

### Service Status
```bash
# Check all services
sudo systemctl status zsmanager-backend
sudo systemctl status nginx

# View logs
sudo journalctl -f -u zsmanager-backend
sudo journalctl -f -u nginx
```

### Starting/Stopping Services
```bash
# Start services
sudo systemctl start zsmanager-backend
sudo systemctl start nginx

# Stop services  
sudo systemctl stop zsmanager-backend
sudo systemctl stop nginx

# Restart services
sudo systemctl restart zsmanager-backend
sudo systemctl restart nginx

# Enable auto-start on boot
sudo systemctl enable zsmanager-backend
sudo systemctl enable nginx
```

### Troubleshooting

#### Permission Issues
```bash
# Fix ownership if needed
sudo chown -R zsmanager:zsmanager /opt/zedin-steam-manager
sudo chown -R zsmanager:zsmanager /var/lib/zedin
sudo chown -R zsmanager:zsmanager /var/log/zedin

# Check user groups
groups zsmanager
id zsmanager
```

#### Service Issues
```bash
# Check service logs for errors
sudo journalctl -u zsmanager-backend --since "1 hour ago"

# Check port availability
sudo netstat -tlnp | grep :8000
sudo netstat -tlnp | grep :80

# Test backend directly
curl http://localhost:8000/api/health
```

#### Database Issues
```bash
# Check database file permissions
ls -la /var/lib/zedin/zedin_steam_manager.db

# Reset database (if needed)
sudo -u zsmanager rm -f /var/lib/zedin/zedin_steam_manager.db
sudo systemctl restart zsmanager-backend
```

## Configuration

### Environment Variables
Create `.env` file in backend directory:
```env
DATABASE_URL=sqlite:///./zedin_steam_manager.db
SECRET_KEY=your-secret-key-here
STEAMCMD_PATH=./steamcmd
SHARED_FILES_PATH=./shared_files
SERVERS_PATH=./servers
```

### Game Server Configuration
- **ASE App ID**: 376030
- **ASA App ID**: 2430930
- **RCON**: Automatic configuration for player management
- **Shared Files**: Automatic setup for space-efficient storage

## Security Features

- **Token Management**: Secure JWT authentication (admin-only token generation)
- **User Management**: Online user data storage (not local)
- **Admin Controls**: Protected operations require admin privileges
- **SSH Security**: Secure remote host management

## Usage

### Creating Servers
1. Navigate to Server Management
2. Select ASE or ASA
3. Configure server settings (ports, RCON, max players)
4. Click "Install Files" to begin installation
5. Monitor real-time installation logs

### Managing Servers
- **Start**: Click play button (immediate status change to RUNNING)
- **Stop**: Safe shutdown using RCON DoExit command  
- **View Logs**: Real-time log monitoring with 1-second refresh
- **Configure**: Edit .ini files directly from web interface
- **RCON**: Execute commands and view player lists

### System Monitoring
- Real-time resource monitoring (5-second updates)
- Server process tracking
- Network usage statistics
- Disk space management

### Remote Management
1. Add remote hosts via SSH configuration
2. Deploy servers across multiple machines
3. Centralized management from single interface

## API Documentation

When running, visit http://localhost:8000/docs for interactive API documentation.

### Key Endpoints
- `GET /api/servers` - List all servers
- `POST /api/servers/{id}/start` - Start server
- `POST /api/servers/{id}/stop` - Stop server safely
- `GET /api/servers/{id}/logs` - Get server logs
- `GET /api/dashboard/info` - System information
- `GET /api/check-updates` - Check for updates

## Development

### File Structure
- **Backend Services**: Server management, RCON communication, file operations
- **Frontend Components**: Dashboard, server cards, log viewers, configuration editors
- **Electron Integration**: Desktop notifications, auto-updater, system integration

### Adding Game Support
1. Add game configuration to `config/settings.py`
2. Implement game-specific service in `services/`
3. Update frontend with game-specific UI components

## License

MIT License - Professional use permitted

## Support

For issues and feature requests, please use the GitHub issue tracker.

---

**Zedin Steam Manager v0.000001** - Professional Steam Server Management Solution