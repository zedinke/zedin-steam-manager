# Zedin Steam Manager - Copilot Instructions

## Project Overview
- **Name**: Zedin Steam Manager
- **Version**: 0.000001  
- **Type**: Professional Steam Server Manager for ASE (Ark: Survival Evolved) and ASA (Ark: Survival Ascended)
- **Architecture**: Multi-tier application with FastAPI backend, React frontend, and Electron desktop wrapper

## Core Requirements Implemented

### Manager Functionality
✅ Version control system (V 0.000001) with automatic incrementing  
✅ Hourly GitHub version checking with update notifications  
✅ 5-second system resource monitoring (RAM/HDD/CPU/Network)  
✅ Multi-language support with browser language detection  

### Server Management  
✅ Real-time server status monitoring (RUNNING, STOPPED, INSTALLING, NOT_INSTALLED)  
✅ Safe server start/stop controls with RCON DoExit implementation  
✅ Live installation logging with 1-second refresh intervals  
✅ RCON integration for player listing (ListPlayers) and command execution  
✅ Web-based configuration file editing (.ini files)  

### Infrastructure
✅ Multi-host support via SSH for remote server management  
✅ SQLAlchemy database with comprehensive data models  
✅ RESTful API with FastAPI and dedicated endpoints  
✅ Shared files system for ASE/ASA storage optimization  
✅ Dashboard-based file management operations  

## Development Guidelines

### Code Structure
- **Backend**: `/backend` - FastAPI Python application
- **Frontend**: `/frontend` - React TypeScript SPA  
- **Desktop**: `/electron` - Electron main process
- **Database**: SQLAlchemy models in `/backend/models`
- **API**: Route handlers in `/backend/routers`
- **Services**: Business logic in `/backend/services`

### Key Components
- **System Monitoring**: Real-time metrics every 5 seconds
- **Update System**: Hourly GitHub release checking
- **Server Control**: RCON-based safe operations
- **File Management**: Centralized shared storage
- **Authentication**: JWT-based with admin controls

### Development Workflow
1. Backend: `uvicorn main:app --reload --host 0.0.0.0 --port 8000`
2. Frontend: `npm run dev` (Vite development server on port 3000)
3. Desktop: `npm start` (Electron with hot reload)
4. Full stack: `./start-dev.bat` (all components)

### Security Notes
- Token generation restricted to admin users only
- User data and tokens stored on remote servers, not locally
- SSH key-based authentication for remote hosts
- RCON passwords encrypted in database

## API Endpoints
- **Health**: `GET /api/health` - Service status
- **Version**: `GET /api/version` - Manager version info  
- **Updates**: `GET /api/check-updates` - Check for newer versions
- **Servers**: `/api/servers` - Full CRUD server management
- **System**: `/api/system` - Real-time system information
- **Dashboard**: `/api/dashboard` - Aggregated dashboard data

## Installation & Setup
```bash
# Dependencies
npm run install:all

# Development
./start-dev.bat

# Production Build  
npm run build
npm start
```

## Environment Requirements
- Node.js 18+
- Python 3.9+  
- Windows/Linux/macOS support
- SteamCMD for game file management

Work through each checklist item systematically.
Keep communication concise and focused.
Follow development best practices.