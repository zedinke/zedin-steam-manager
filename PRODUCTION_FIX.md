# Production Deployment Fix Guide

## 🚨 Current Issues Identified

Based on the update log from 2025-11-13 02:54:47, the following issues need to be resolved:

### 1. Git Repository Issue
```
fatal: not a git repository (or any of the parent directories): .git
```

### 2. Frontend Build Issue  
```
✓ 11814 modules transformed.
dist/assets/index-618556ec.js   640.92 kB │ gzip: 196.15 kB
```
- Still building old Material-UI version (640KB)
- Should be simplified HTML version

### 3. Backend Service Restart Failure
```
ERROR: Backend service failed to restart - check logs: journalctl -u zsmanager-backend
```

## 🔧 Quick Fix Commands

Run these commands on the production server as root:

### Step 1: Stop Services
```bash
sudo systemctl stop zsmanager-backend
```

### Step 2: Fix Git Repository  
```bash
cd /opt/zedin-steam-manager
sudo ./deploy-production.sh
```

### Step 3: Debug Service Issues
```bash
sudo ./debug-service.sh
```

### Step 4: Manual Service Check
```bash
# Check service status
sudo systemctl status zsmanager-backend

# Check recent logs
sudo journalctl -u zsmanager-backend --since "10 minutes ago"

# Restart service
sudo systemctl restart zsmanager-backend
```

## 📋 Script Files

- **`deploy-production.sh`** - Complete production deployment fix
- **`debug-service.sh`** - Service debugging and diagnostics  
- **`update.sh`** - Updated to handle new simplified structure

## 🎯 Expected Results After Fix

### Frontend
- Build size: ~1KB (simplified HTML)
- No Material-UI dependencies
- Direct CDN React usage

### Backend  
- Service starts successfully
- Database connections work
- API endpoints respond

### Git Repository
- Properly initialized and tracking origin
- Clean pull/push operations

## 🔍 Verification Steps

1. **Check service status:**
   ```bash
   sudo systemctl status zsmanager-backend
   ```

2. **Test frontend:**
   ```bash
   curl -I http://localhost/
   ```

3. **Test backend API:**
   ```bash
   curl http://localhost/api/health
   ```

4. **Check Git status:**
   ```bash
   cd /opt/zedin-steam-manager && git status
   ```

## 🆘 Emergency Recovery

If all else fails:

```bash
# Complete reinstall
sudo systemctl stop zsmanager-backend
sudo rm -rf /opt/zedin-steam-manager
# Run fresh install script
curl -sSL https://raw.githubusercontent.com/zedinke/zedin-steam-manager/main/install.sh | sudo bash
```

## 📞 Support

- Check logs: `sudo journalctl -f -u zsmanager-backend`
- GitHub Issues: https://github.com/zedinke/zedin-steam-manager/issues
- Documentation: `/opt/zedin-steam-manager/MAINTENANCE.md`