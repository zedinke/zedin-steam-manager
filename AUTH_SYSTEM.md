# 🔐 Authentication System

## Overview

A teljes authentication rendszer hierarchikus jogosultsági szintekkel, email verifikációval és modern biztonsági funkciókkal.

## 👥 User Roles (Hierarchikus)

### 🔴 Manager Admin
- **Ki**: Csak te
- **Jogosultságok**: Minden funkció, user role módosítása, rendszer adminisztráció
- **Védett**: Nem törölhető, role nem módosítható mások által

### 🟠 Server Admin  
- **Ki**: Szerver adminisztrátorok
- **Jogosultságok**: Szerverek teljes kezelése, user management (admin szint alatt)
- **Funkciók**: Server install/update/delete, RCON vezérlés, konfigurációs fájlok

### 🟡 Admin
- **Ki**: Általános adminisztrátorok  
- **Jogosultságok**: User management (admin szint alatt), dashboard megtekintés
- **Funkciók**: User lista, szerepkör módosítás (admin alatt), monitoring

### 🟢 User
- **Ki**: Alapértelmezett regisztráció
- **Jogosultságok**: Dashboard megtekintés, saját profil kezelés
- **Funkciók**: Read-only dashboard, jelszó változtatás, profil szerkesztés

## 📝 Regisztráció folyamata

### Kötelező adatok:
- ✅ **Keresztnév** (min. 2 karakter)
- ✅ **Vezetéknév** (min. 2 karakter)  
- ✅ **Email cím** (egyedi, valid formátum)
- ✅ **Jelszó** (min. 8 karakter, nagybetű + kisbetű + szám)
- ✅ **Jelszó megerősítés**
- ✅ **Születési dátum** (min. 13 év, max. 120 év)

### Validációk:
- Email cím egyediség ellenőrzés
- Jelszó komplexitás követelmény
- Születési dátum korlátok
- Név hossz validációk

## 📧 Email Verification System

### Gyönyörű HTML Email Template
- 🎨 Gradient header design
- 🎮 Gaming-themed branding  
- 📱 Responsive design
- 🔒 6-digit verification code
- 🔗 One-click verification link
- ⏰ 24 órás lejárati idő

### Dual Verification:
1. **6-digit kód**: Email-ben küldött számsor
2. **Közvetlen link**: Egy-kattintásos megerősítés

### Email tartalom:
- Üdvözlő üzenet személyre szabva
- Biztonsági információk
- Márka design elemek
- Lejárati figyelmeztetés

## 🛡️ Security Features

### Password Security:
- bcrypt hashing (industry standard)
- Minimum complexity követelmények
- Biztonságos tárolás

### JWT Tokens:
- Configurable expiry time
- Role-based payload
- Secure secret key

### Session Management:
- Automatic token refresh
- Secure logout
- Local storage with persistence

## 🔄 Frontend Integration

### Modern Login/Register UI:
- 🎨 Material-UI design
- 📱 Responsive tabs (Login/Register)
- 👁️ Password visibility toggle
- 📅 Date picker for birth date
- ✅ Real-time validation feedback
- 🔔 Success/error alerts

### State Management:
- Zustand store with persistence
- Role-based permission checking
- User data synchronization
- Loading state management

## 🗄️ Database Options

### Development:
- SQLite (helyi fejlesztés)
- Automatikus tábla generálás

### Production külső opciók:
- **PlanetScale** (MySQL compatible, ingyenes tier)
- **Supabase** (PostgreSQL, real-time features)  
- **Neon** (PostgreSQL, serverless)
- **Railway** (PostgreSQL/MySQL)

### Konfiguráció:
```python
# settings.py
EXTERNAL_DATABASE_URL = "postgresql://user:pass@host/db"
USE_EXTERNAL_DB = True
EMAIL_ENABLED = True
EMAIL_SENDER = "noreply@yourdomain.com" 
EMAIL_PASSWORD = "your_gmail_app_password"
```

## 🚀 API Endpoints

### Public:
- `POST /api/auth/register` - Új user regisztráció
- `POST /api/auth/login` - Bejelentkezés
- `POST /api/auth/verify-email` - Email megerősítés

### Authenticated:
- `GET /api/auth/me` - Saját profil
- `POST /api/auth/change-password` - Jelszó változtatás
- `POST /api/auth/logout` - Kijelentkezés

### Admin only:
- `GET /api/auth/users` - User lista
- `PATCH /api/auth/users/{id}/role` - Role módosítás (Manager Admin)
- `DELETE /api/auth/users/{id}` - User törlés

## 🔧 Deployment

### Email beállítás (Gmail):
1. Google Account Security settings
2. 2-factor authentication engedélyezése  
3. App Password generálás
4. EMAIL_PASSWORD beállítás

### Külső adatbázis setup:
1. Szolgáltató regisztráció (PlanetScale/Supabase/Neon)
2. Database létrehozás
3. CONNECTION_STRING másolás
4. Environment variables beállítás

### Frissítés meglévő rendszerre:
```bash
cd /home/zsmanager/zedin-steam-manager
git pull
sudo ./update.sh
```

## ✨ Features Summary

- ✅ **4-szintű hierarchikus jogosultság**
- ✅ **Gyönyörű email verification**  
- ✅ **Modern responsive UI**
- ✅ **Biztonságos password handling**
- ✅ **JWT token authentication**
- ✅ **Role-based access control**
- ✅ **Külső database támogatás**
- ✅ **Automated update system**
- ✅ **Production-ready security**

🎉 **Ready for professional Steam server management!**