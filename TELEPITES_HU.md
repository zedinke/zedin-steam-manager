# Module 1 - Telepítési Útmutató

## Mi változott?

Az előző monolitikus megközelítés helyett most **moduláris blokk-alapú telepítő** rendszert hoztunk létre.

## Új Funkciók (Module 1)

### ✅ Moduláris Telepítő
- 7 független telepítési blokk
- Minden blokk külön fájl az `installer/blocks/` mappában
- Könnyű hibajavítás és karbantartás
- Részletes telepítési naplók

### ✅ Email Verifikáció
- Regisztrációkor email megerősítés szükséges
- Verifikációs link email-ben
- Csak megerősített email-lel lehet bejelentkezni
- SMTP konfiguráció támogatás

### ✅ Git Auto-Update
- Dashboard-ban "Update Now" gomb
- Egy kattintással frissítés GitHub-ról
- Automatikus service újraindítás
- Update státusz jelzés (hány commit van hátra)

### ✅ Professzionális Design
- Material-UI dark téma
- Modern, nem minimál design
- Responsive layout
- Színes komponensek

### ✅ Telepítési Logging
- Minden telepítés logolva van
- Timestamp-ekkel ellátott bejegyzések
- Mentés: `installer/logs/install-YYYYMMDD-HHMMSS.log`
- Update logok külön fájlban

### ✅ Cross-Platform
- Linux: `.sh` szkriptek
- Windows: `.bat` szkriptek
- Fejlesztői mód mindkét platformon

## Telepítés

### Linux Szerveren (Debian):

```bash
# Klónozás
git clone https://github.com/zedinke/zedin-steam-manager.git
cd zedin-steam-manager

# Telepítés futtatása
sudo chmod +x installer/main-installer.sh
sudo ./installer/main-installer.sh
```

### Windows Fejlesztéshez:

```cmd
# Klónozás
git clone https://github.com/zedinke/zedin-steam-manager.git
cd zedin-steam-manager

# Fejlesztői mód indítása
start-dev.bat
```

## Telepítési Folyamat

A telepítő 7 blokkot fut végig:

1. **System Check** - Rendszer követelmények ellenőrzése
2. **Dependencies** - Python, Node.js, Nginx, Git telepítése
3. **Database** - Supabase kapcsolat konfigurálása
4. **Backend** - FastAPI, email verification setup
5. **Frontend** - React, Material-UI, Git update gomb
6. **Services** - Systemd szolgáltatások
7. **Nginx** - Reverse proxy (80-as port)

## Használat

### 1. Regisztráció
- Nyisd meg: `http://YOUR_SERVER_IP/register`
- Add meg: email, username, jelszó
- Ellenőrizd az email-t és kattints a verifikációs linkre

### 2. Email Verifikáció
- Kattints az email-ben kapott linkre
- Vagy manuálisan: `http://YOUR_SERVER_IP/verify-email?token=TOKEN`

### 3. Bejelentkezés
- `http://YOUR_SERVER_IP/login`
- Add meg a verifikált email-t és jelszót

### 4. Dashboard
- Git Update gomb: frissítés a GitHub-ról
- System Info: verzió és email információk
- További funkciók a következő modulokban

## Frissítés

### Manuális frissítés:
```bash
cd /opt/zedin-steam-manager
sudo ./installer/update.sh
```

### Dashboard-ról:
- Kattints az "Update Now" gombra
- Automatikus frissítés és újraindítás

## Email Konfiguráció

A telepítés után konfiguráld az SMTP beállításokat:

```bash
sudo nano /opt/zedin-steam-manager/backend/.env
```

Változtasd meg:
```env
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password
```

Gmail App Password generálás:
1. Google Account → Security
2. 2FA bekapcsolása
3. App Passwords → Generate
4. Másold be a jelszót

## Logok Ellenőrzése

### Telepítési logok:
```bash
ls -la /opt/zedin-steam-manager/installer/logs/
tail -f /opt/zedin-steam-manager/installer/logs/install-*.log
```

### Service logok:
```bash
# Backend
journalctl -u zedin-backend.service -f

# Frontend
journalctl -u zedin-frontend.service -f

# Nginx
tail -f /var/log/nginx/access.log
```

## Eltávolítás

```bash
cd zedin-steam-manager
sudo ./installer/uninstall.sh
```

## Következő Lépések

Module 1 kész! Következő modulok:
- Module 2: Szerver menedzsment
- Module 3: RCON integráció
- Module 4: Fájl kezelés
- stb.

## Hibaelhárítás

### Services nem indulnak:
```bash
systemctl status zedin-backend.service
systemctl status zedin-frontend.service
journalctl -u zedin-backend.service -n 50
```

### Email nem érkezik:
- Ellenőrizd az SMTP beállításokat
- Gmail esetén App Password használata kötelező
- Ellenőrizd a spam mappát

### Port 80 foglalt:
```bash
sudo netstat -tuln | grep :80
sudo systemctl stop apache2  # ha Apache fut
```

## Támogatás

- GitHub: https://github.com/zedinke/zedin-steam-manager
- Issues: https://github.com/zedinke/zedin-steam-manager/issues

---

**Verzió:** 0.0.1-alpha  
**Modul:** 1 - Telepítés & Alap Rendszer  
**Státusz:** ✅ Kész
