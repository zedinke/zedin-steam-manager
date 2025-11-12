# Zedin Steam Manager - Telepítési Útmutató

## 🚀 Automatikus Telepítés

### Linux (Debian/Ubuntu)

```bash
# 1. Töltsd le a projekt fájlokat
git clone <repository-url> zedinsteammanager
cd zedinsteammanager

# 2. Futtasd a telepítőt (sudo jogokkal rendelkező felhasználóként)
chmod +x install.sh
./install.sh

# 3. Kész! Az alkalmazás elérhető:
#    http://your-server-ip/
```

### Windows

```batch
REM 1. Töltsd le és csomagold ki a projekt fájlokat
REM 2. Jobb klikk az install-windows.bat fájlon
REM 3. "Futtatás rendszergazdaként"
REM 4. Kövesd a telepítő utasításait

REM Az alkalmazás elérhető lesz:
REM http://localhost:8000/
```

## 📋 Mit telepít az automatikus telepítő?

### Linux verzió:
- ✅ **System Dependencies**: Python 3.9+, Node.js 18+, SteamCMD
- ✅ **Dedicated User**: `zedin` szolgáltatási felhasználó
- ✅ **Systemd Services**: Automatikus indítás boot-kor
- ✅ **Nginx Reverse Proxy**: Professional web szerver
- ✅ **Firewall**: UFW konfigurálva ARK portokkal
- ✅ **Backup System**: Napi automatikus mentések
- ✅ **Logging**: Logrotate konfiguráció
- ✅ **Security**: Non-root user, protected directories

### Windows verzió:
- ✅ **Dependencies**: Python 3.12, Node.js 18
- ✅ **Windows Service**: NSSM service manager
- ✅ **Firewall Rules**: Windows Defender konfigurálva
- ✅ **Desktop Shortcuts**: Egyszerű indítás
- ✅ **Auto Startup**: Automatikus indítás boot-kor

## 🔧 Manuális telepítés (haladó felhasználóknak)

### Előfeltételek
- Python 3.9+ és pip
- Node.js 18+ és npm
- Git

### Lépések
```bash
# 1. Dependencies telepítése
npm run install:all

# 2. Konfigurációs fájl létrehozása
cp .env.production backend/.env

# 3. Adatbázis inicializálás
cd backend
source ../venv/bin/activate  # Linux
# vagy
venv\Scripts\activate  # Windows

python -c "
from config.database import engine
from models import base
base.Base.metadata.create_all(bind=engine)
"

# 4. Alkalmazás indítása
# Linux
./start-debian.sh

# Windows
start-dev.bat
```

## 🗂️ Telepítés után

### Alapértelmezett hozzáférési pontok:
- **Web Interface**: `http://your-ip/`
- **API Documentation**: `http://your-ip/docs`
- **Health Check**: `http://your-ip/health`

### Első beállítások:
1. **Admin fiók létrehozása** a web felületen
2. **ASE/ASA szerverek hozzáadása**
3. **RCON beállítások** konfigurálása
4. **SSH kulcsok** beállítása (remote hosts esetén)

## 🔒 Biztonsági jegyzet

Az automatikus telepítő:
- ✅ Non-root felhasználóval futtatja a szolgáltatást
- ✅ Firewall szabályokat állít be
- ✅ Véletlenszerű SECRET_KEY-t generál
- ✅ Korlátozott fájlrendszer hozzáférést biztosít

**Éles környezetben javasolt:**
- SSL tanúsítvány beállítása (Let's Encrypt)
- Adatbázis jelszó módosítása
- Admin fiók erős jelszóval

## 🔄 Frissítés

```bash
# Automatikus frissítés (hamarosan)
sudo systemctl stop zedin-backend
git pull origin main
sudo systemctl start zedin-backend

# Vagy manuális frissítés az admin felületen
```

## 🗑️ Eltávolítás

### Linux
```bash
chmod +x uninstall.sh
./uninstall.sh
```

### Windows
```batch
REM Vezérlőpult > Programok > Zedin Steam Manager > Eltávolítás
REM Vagy manuálisan:
net stop ZedinSteamManager
sc delete ZedinSteamManager
```

## ❓ Hibaelhárítás

### Szolgáltatás nem indul
```bash
# Linux
sudo journalctl -f -u zedin-backend
sudo systemctl status zedin-backend

# Windows
eventviewer.msc (Windows Logs > Application)
```

### Port foglalt hiba
```bash
# Linux
sudo lsof -i :8000
sudo netstat -tulpn | grep :8000

# Windows
netstat -ano | findstr :8000
```

### Permission denied hibák
```bash
# Linux
sudo chown -R zedin:zedin /opt/zedin-steam-manager
sudo chmod +x /opt/zedin-steam-manager/start-debian.sh
```

## 📞 Támogatás

- **GitHub Issues**: Hibajelentések és feature kérések
- **Dokumentáció**: `/docs` endpoint az API-ról
- **Logok**: Mindig nézd meg a logokat hiba esetén

---

**⚠️ Fontos:** Az első telepítés után mindig változtasd meg az alapértelmezett jelszavakat és konfiguráld a biztonsági beállításokat!