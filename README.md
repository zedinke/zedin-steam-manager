# Zedin Steam Manager

**Version:** 0.000001  
**Professional Steam Server Manager for ASE (Ark: Survival Evolved) and ASA (Ark: Survival Ascended)**

## 🚀 Quick Start

### Windows
```bash
# 1. Install dependencies
install.bat

# 2. Setup Supabase (see SETUP_SUPABASE.md)
copy backend\.env.example backend\.env
# Edit backend\.env with your Supabase credentials

# 3. Initialize database
cd backend
python init_db.py
cd ..

# 4. Start development
start-dev.bat
```

### Linux/Debian
```bash
# 1. Make scripts executable
chmod +x install.sh start-dev.sh

# 2. Install dependencies
./install.sh

# 3. Setup Supabase (see SETUP_SUPABASE.md)
cp backend/.env.example backend/.env
# Edit backend/.env with your Supabase credentials

# 4. Initialize database
cd backend
python3 init_db.py
cd ..

# 5. Start development
./start-dev.sh
```

## 📋 Requirements

### System Requirements
- **Python:** 3.9+
- **Node.js:** 18+
- **Database:** Supabase (PostgreSQL cloud)
- **OS:** Windows, Linux, macOS

### Linux Additional Requirements
```bash
sudo apt update
sudo apt install -y python3 python3-pip nodejs npm
```

## ✨ Features (Version 0.000001)

### Current Features
✅ User registration and authentication  
✅ JWT token-based sessions (30-day expiration)  
✅ Supabase cloud database integration  
✅ Material-UI dark theme interface  
✅ Cross-machine login persistence  

### Planned Features (Roadmap)
- [ ] Multi-server management (ASE/ASA)
- [ ] Real-time server status monitoring
- [ ] RCON integration (ListPlayers, DoExit, custom commands)
- [ ] Multi-host SSH management
- [ ] Safe server start/stop controls
- [ ] Live installation logging
- [ ] Web-based .ini file editor
- [ ] Shared files system for storage optimization
- [ ] System resource monitoring (CPU, RAM, Disk, Network)
- [ ] Automatic update checking (hourly GitHub releases)
- [ ] Multi-language support with browser detection
- [ ] Dashboard-based file management
- [ ] Player management interface
- [ ] Backup and restore functionality
- [ ] Scheduled tasks (auto-restart, backups)
- [ ] Server templates and presets
- [ ] Performance analytics and graphs
- [ ] Discord webhook notifications

## 🗂️ Project Structure

```
zedinsteammanager/
├── backend/
│   ├── config/
│   │   ├── database.py       # PostgreSQL connection
│   │   ├── settings.py       # App configuration
│   │   └── supabase_client.py # Supabase integration
│   ├── models/
│   │   ├── user.py           # User model
│   │   ├── token.py          # Token model
│   │   ├── server.py         # Server model
│   │   └── host.py           # Host model
│   ├── routers/
│   │   └── auth.py           # Authentication endpoints
│   ├── main.py               # FastAPI application
│   ├── init_db.py            # Database initialization
│   └── requirements.txt      # Python dependencies
├── frontend/
│   ├── src/
│   │   ├── pages/
│   │   │   ├── LoginPage.tsx
│   │   │   ├── RegisterPage.tsx
│   │   │   └── DashboardPage.tsx
│   │   ├── services/
│   │   │   └── api.ts        # API client
│   │   ├── App.tsx           # Main app component
│   │   └── main.tsx          # Entry point
│   ├── package.json          # Node dependencies
│   └── vite.config.ts        # Vite configuration
├── install.bat               # Windows installer
├── install.sh                # Linux installer
├── start-dev.bat             # Windows dev starter
├── start-dev.sh              # Linux dev starter
├── README.md                 # This file
└── SETUP_SUPABASE.md         # Supabase setup guide
```

## 🔐 Security Features

- **Password Hashing:** bcrypt with salt
- **JWT Tokens:** Stored in database for validation
- **Token Expiration:** 30-day automatic expiration
- **SSH Key Auth:** For remote host management
- **RCON Encryption:** Passwords encrypted in database
- **CORS Protection:** Configured for specific origins
- **Admin Controls:** Token generation restricted to admins

## 🌐 API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user
- `POST /api/auth/logout` - Logout user
- `GET /api/auth/me` - Get current user info

### System
- `GET /api/health` - Service health check
- `GET /api/version` - Get manager version

## 📝 Database Schema

### Tables
- **users** - User accounts (id, email, username, password, roles)
- **user_tokens** - JWT tokens (id, user_id, token, expires_at)
- **servers** - Server configs (id, name, type, status, ports, paths)
- **hosts** - SSH hosts (id, name, hostname, port, username, ssh_key)

## 🛠️ Development

### Backend Development
```bash
cd backend
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### Frontend Development
```bash
cd frontend
npm run dev
```

### Database Migrations
```bash
cd backend
python init_db.py
```

## 📦 Production Deployment

### Systemd Service (Linux)
```bash
# Backend service
sudo nano /etc/systemd/system/zedin-backend.service

# Frontend (build and serve with Nginx)
cd frontend
npm run build
sudo cp -r dist/* /var/www/zedin-steam-manager/
```

### Nginx Configuration
```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        root /var/www/zedin-steam-manager;
        try_files $uri $uri/ /index.html;
    }

    location /api {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## 🐛 Troubleshooting

### Backend won't start
```bash
# Check Python version
python --version  # Should be 3.9+

# Reinstall dependencies
cd backend
pip install -r requirements.txt --force-reinstall
```

### Frontend won't start
```bash
# Check Node version
node --version  # Should be 18+

# Clear cache and reinstall
cd frontend
rm -rf node_modules package-lock.json
npm install
```

### Database connection errors
- Check your `.env` file has correct Supabase credentials
- Verify your Supabase project is active
- Check firewall allows connections to Supabase

## 📄 License

Copyright © 2025 Zedin. All rights reserved.

---

**Built with ❤️ for the ARK community**
