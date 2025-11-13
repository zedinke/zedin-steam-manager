# Zedin Steam Manager

**Version:** 0.0.1-alpha  
**Modular Steam Server Management System**

## 🎯 Module 1: Installation & Base System (CURRENT)

### Features
✅ Modular installer with block-based architecture  
✅ Web-based manager accessible via browser  
✅ External database authentication (Supabase)  
✅ Email verification on registration  
✅ Modern, professional UI (Material-UI)  
✅ Git auto-update system in dashboard  
✅ Installation verification (skip if installed)  
✅ Installation & update logging  
✅ Cross-platform support (Linux & Windows)  

## 📦 Installation

### Quick Start (Linux)
```bash
wget https://raw.githubusercontent.com/zedinke/zedin-steam-manager/main/install.sh
chmod +x install.sh
./install.sh
```

### Quick Start (Windows)
```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/zedinke/zedin-steam-manager/main/install.bat" -OutFile "install.bat"
.\install.bat
```

## 🗂️ Project Structure

```
zedin-steam-manager/
├── installer/
│   ├── main-installer.sh          # Main orchestrator (Linux)
│   ├── main-installer.bat         # Main orchestrator (Windows)
│   ├── blocks/
│   │   ├── 01-system-check.sh     # System requirements
│   │   ├── 02-dependencies.sh     # Install dependencies
│   │   ├── 03-database.sh         # Database setup
│   │   ├── 04-backend.sh          # Backend installation
│   │   ├── 05-frontend.sh         # Frontend installation
│   │   ├── 06-services.sh         # Systemd/Services
│   │   └── 07-nginx.sh            # Web server config
│   └── logs/                      # Installation logs
├── backend/
│   ├── app/
│   │   ├── main.py                # FastAPI app
│   │   ├── config/                # Configuration
│   │   ├── models/                # Database models
│   │   ├── routers/               # API routes
│   │   │   └── auth.py           # Auth with email verification
│   │   └── services/              # Business logic
│   │       └── updater.py        # Git auto-update
│   └── requirements.txt
├── frontend/
│   ├── src/
│   │   ├── pages/
│   │   │   ├── Login.tsx          # Login with email
│   │   │   ├── Register.tsx       # Register with verification
│   │   │   └── Dashboard.tsx      # Dashboard with update button
│   │   ├── components/            # Reusable components
│   │   └── theme/                 # Modern Material-UI theme
│   └── package.json
└── docs/
    ├── INSTALLATION.md
    └── MODULE_1.md
```

## 🚀 Roadmap

- [x] **Module 1:** Installation & Base System (CURRENT)
- [ ] **Module 2:** Server Management
- [ ] **Module 3:** RCON Integration
- [ ] **Module 4:** File Management
- [ ] **Module 5:** Monitoring & Analytics

## 📄 License

Proprietary - © 2025 Zedin
