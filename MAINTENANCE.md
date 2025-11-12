# Update és Karbantartási Útmutató

## 🔄 Egyszerű Frissítés

A Zedin Steam Manager frissítése egyetlen paranccsal:

```bash
cd /opt/zedin-steam-manager
sudo ./update.sh
```

## 📋 Mit csinál az update.sh?

### ✅ Automatikus folyamatok:
1. **Git Pull** - Legfrissebb kód letöltése
2. **Dependency Check** - Python/Node.js csomagok frissítése
3. **Frontend Build** - React alkalmazás újraépítése
4. **Service Restart** - Backend szolgáltatás újraindítása
5. **Nginx Reload** - Web szerver konfigurációjának frissítése
6. **Status Check** - Minden szolgáltatás állapotának ellenőrzése

### 📊 Intelligens detektálás:
- **Requirements.txt változás** → Python dependencies frissítése
- **Package.json változás** → Node.js dependencies frissítése  
- **Frontend source változás** → Automatikus rebuild
- **Database model változás** → Migration warning

## 🚀 Frissítési Forgatókönyvek

### 1. Új funkció hozzáadása
```bash
# Windows fejlesztői gépen
git add .
git commit -m "Új funkció"
git push

# Linux szerveren  
cd /opt/zedin-steam-manager
sudo ./update.sh
```

### 2. Hotfix alkalmazása
```bash
# Szerveren
sudo ./update.sh
# Automatikusan újraindul minden szolgáltatás
```

### 3. Dependency frissítés
```bash
# Ha új csomag kell, add hozzá requirements.txt vagy package.json-hez
# Majd:
sudo ./update.sh
# Automatikusan felismeri és telepíti
```

## 🛠️ Manuális Parancsok

### Backend műveletek:
```bash
# Szolgáltatás újraindítása
sudo systemctl restart zsmanager-backend

# Logok megtekintése
sudo journalctl -f -u zsmanager-backend

# Python dependencies frissítése
sudo -u zsmanager /opt/zedin-steam-manager/venv/bin/pip install -r requirements.txt
```

### Frontend műveletek:
```bash
# Frontend újraépítése
cd /opt/zedin-steam-manager/frontend
sudo -u zsmanager npm run build

# Node.js dependencies frissítése
sudo -u zsmanager npm install
```

### Nginx műveletek:
```bash
# Konfigurációs teszt
sudo nginx -t

# Újratöltés
sudo systemctl reload nginx

# Újraindítás
sudo systemctl restart nginx
```

## 🔍 Hibaelhárítás

### Update.sh nem fut:
```bash
# Futtatható jogosultság ellenőrzése
ls -la /opt/zedin-steam-manager/update.sh

# Jogosultság megadása
sudo chmod +x /opt/zedin-steam-manager/update.sh
```

### Git problémák:
```bash
# Git státusz ellenőrzése
cd /opt/zedin-steam-manager
git status

# Local változtatások elvetése
git reset --hard HEAD
git clean -fd
```

### Szolgáltatás hibák:
```bash
# Backend logok
sudo journalctl -u zsmanager-backend --no-pager -n 50

# Nginx logok
sudo journalctl -u nginx --no-pager -n 50

# Rendszer státusz
sudo systemctl status zsmanager-backend nginx
```

## ⚡ Gyors Parancsok

| Művelet | Parancs |
|---------|---------|
| Teljes frissítés | `sudo ./update.sh` |
| Backend restart | `sudo systemctl restart zsmanager-backend` |
| Frontend rebuild | `cd frontend && sudo -u zsmanager npm run build` |
| Logok | `sudo journalctl -f -u zsmanager-backend` |
| Státusz | `sudo systemctl status zsmanager-backend` |
| Git pull | `git pull origin main` |

## 🎯 Best Practices

### ✅ Ajánlott:
- Mindig az `update.sh` scriptet használd frissítéshez
- Ellenőrizd a logokat frissítés után
- Tesztelj fejlesztői környezetben először
- Készíts backup-ot fontos változtatások előtt

### ❌ Kerüld:
- Manuális fájl másolgatás
- Szolgáltatások kézi leállítása frissítés közben
- Root user használata Python/Node.js műveletekhez
- Nginx konfigurációjának direkts szerkesztése

## 📱 Monitoring

### Státusz ellenőrzése:
```bash
# Szolgáltatások
sudo systemctl is-active zsmanager-backend nginx

# API hozzáférhetőség
curl -s http://localhost:8000/api/health

# Frontend hozzáférhetőség  
curl -s http://localhost/ | head -5
```

## 🆘 Vészhelyzeti Visszaállítás

```bash
# Teljes újratelepítés (végső megoldás)
cd /home/zsmanager/zedin-steam-manager
sudo ./install.sh
```