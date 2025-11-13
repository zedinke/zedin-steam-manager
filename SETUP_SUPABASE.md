# Zedin Steam Manager - Supabase Setup Guide

## 1. Create Supabase Project

1. Go to https://supabase.com and sign up/login
2. Create a new project
3. Wait for the project to be initialized (takes 1-2 minutes)

## 2. Get Connection Details

### Get API Keys
1. Go to Project Settings → API
2. Copy these values:
   - **Project URL** (looks like: `https://xxxxx.supabase.co`)
   - **anon public key** (long string starting with `eyJ...`)
   - **JWT Secret** (under "JWT Settings")

### Get Database URL
1. Go to Project Settings → Database
2. Copy the **Connection string** under "Connection string"
3. Select "URI" format
4. It looks like: `postgresql://postgres:[YOUR-PASSWORD]@db.xxxxx.supabase.co:5432/postgres`
5. Replace `[YOUR-PASSWORD]` with your database password (you set this when creating the project)

## 3. Configure Backend

1. Copy `.env.example` to `.env`:
   ```bash
   cp backend/.env.example backend/.env
   ```

2. Edit `backend/.env` and fill in your Supabase details:
   ```env
   SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
   SUPABASE_KEY=your_supabase_anon_key_here
   SUPABASE_JWT_SECRET=your_supabase_jwt_secret_here
   DATABASE_URL=postgresql://postgres:YOUR_PASSWORD@db.YOUR_PROJECT_REF.supabase.co:5432/postgres
   SECRET_KEY=generate_random_secret_key_here
   ```

## 4. Install Dependencies

### Windows:
```bash
install.bat
```

### Linux/macOS:
```bash
chmod +x install.sh
./install.sh
```

## 5. Initialize Database

### Windows:
```bash
cd backend
python init_db.py
cd ..
```

### Linux:
```bash
cd backend
source venv/bin/activate
python init_db.py
deactivate
cd ..
```

## 6. Start Development Environment

### Windows:
```bash
start-dev.bat
```

### Linux/macOS:
```bash
chmod +x start-dev.sh
./start-dev.sh
```

Backend will be available at: http://localhost:8000  
Frontend will be available at: http://localhost:3000

Frontend will be available at: http://localhost:3000

## Test the Application

1. Open http://localhost:3000
2. Click "Register" to create a new account
3. Fill in email, username, and password
4. After registration, you'll be automatically logged in
5. Your token and user data are stored in **Supabase PostgreSQL database**
6. Even if you reinstall your machine, you can login again with your credentials

## Database Tables Created

- **users** - User accounts with email, username, hashed password
- **user_tokens** - JWT tokens for authentication (persistent sessions)
- **servers** - ASE/ASA server configurations (for future features)
- **hosts** - SSH host configurations (for future features)

## Security Notes

✅ Passwords are hashed with bcrypt  
✅ JWT tokens stored in database for validation  
✅ Tokens expire after 30 days  
✅ All data stored in Supabase cloud (survives reinstalls)  
✅ CORS configured for localhost development

## Next Steps

After login system works, we'll implement:
- Server management (start/stop/install)
- RCON integration (ListPlayers, DoExit)
- Multi-host SSH management
- File editor for .ini configs
- Real-time system monitoring
- Auto-update checker
