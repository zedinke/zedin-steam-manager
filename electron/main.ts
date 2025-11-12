import { app, BrowserWindow, Menu, ipcMain, dialog } from 'electron';
import { autoUpdater } from 'electron-updater';
import * as path from 'path';
import fetch from 'node-fetch';

class ZedinSteamManager {
  private mainWindow: BrowserWindow | null = null;
  private readonly currentVersion = '0.000001';
  private backendPort = 8000;

  constructor() {
    this.initializeApp();
  }

  private async initializeApp(): Promise<void> {
    await app.whenReady();
    this.createWindow();
    this.setupMenu();
    this.setupAutoUpdater();
    this.setupUpdateChecker();
    this.setupIpcHandlers();
  }

  private createWindow(): void {
    this.mainWindow = new BrowserWindow({
      width: 1400,
      height: 900,
      minWidth: 1200,
      minHeight: 800,
      webPreferences: {
        nodeIntegration: true,
        contextIsolation: false
      },
      icon: path.join(__dirname, '../assets/icon.png'),
      title: 'Zedin Steam Manager',
      show: false
    });

    // Load the frontend
    const isDev = process.env.NODE_ENV === 'development';
    const frontendUrl = isDev 
      ? 'http://localhost:3000'
      : `file://${path.join(__dirname, '../frontend/dist/index.html')}`;

    this.mainWindow.loadURL(frontendUrl);

    this.mainWindow.once('ready-to-show', () => {
      this.mainWindow?.show();
      if (isDev) {
        this.mainWindow?.webContents.openDevTools();
      }
    });

    this.mainWindow.on('closed', () => {
      this.mainWindow = null;
    });
  }

  private setupMenu(): void {
    const template = [
      {
        label: 'Manager',
        submenu: [
          {
            label: `Version: ${this.currentVersion}`,
            enabled: false
          },
          { type: 'separator' },
          {
            label: 'Check for Updates',
            click: () => this.checkForUpdates()
          },
          { type: 'separator' },
          {
            label: 'Quit',
            accelerator: 'CmdOrCtrl+Q',
            click: () => app.quit()
          }
        ]
      },
      {
        label: 'View',
        submenu: [
          { role: 'reload' },
          { role: 'forceReload' },
          { role: 'toggleDevTools' },
          { type: 'separator' },
          { role: 'resetZoom' },
          { role: 'zoomIn' },
          { role: 'zoomOut' },
          { type: 'separator' },
          { role: 'togglefullscreen' }
        ]
      },
      {
        label: 'Help',
        submenu: [
          {
            label: 'About Zedin Steam Manager',
            click: () => this.showAbout()
          }
        ]
      }
    ];

    const menu = Menu.buildFromTemplate(template as any);
    Menu.setApplicationMenu(menu);
  }

  private setupAutoUpdater(): void {
    autoUpdater.checkForUpdatesAndNotify();

    autoUpdater.on('update-available', () => {
      dialog.showMessageBox(this.mainWindow!, {
        type: 'info',
        title: 'Update Available',
        message: 'A new version is available. It will be downloaded in the background.',
        buttons: ['OK']
      });
    });

    autoUpdater.on('update-downloaded', () => {
      dialog.showMessageBox(this.mainWindow!, {
        type: 'info',
        title: 'Update Ready',
        message: 'Update downloaded. The application will restart to apply the update.',
        buttons: ['Restart Now', 'Later']
      }).then((result) => {
        if (result.response === 0) {
          autoUpdater.quitAndInstall();
        }
      });
    });
  }

  private setupUpdateChecker(): void {
    // Check for updates every hour
    setInterval(() => {
      this.checkForUpdates();
    }, 60 * 60 * 1000);
  }

  private async checkForUpdates(): Promise<void> {
    try {
      const response = await fetch('https://api.github.com/repos/zedin/steam-manager/releases/latest');
      const data: any = await response.json();
      const latestVersion = data.tag_name?.replace('v', '');
      
      if (latestVersion && latestVersion !== this.currentVersion) {
        const result = await dialog.showMessageBox(this.mainWindow!, {
          type: 'question',
          title: 'Update Available',
          message: `A new version (${latestVersion}) is available. Current version: ${this.currentVersion}`,
          buttons: ['Update Now', 'Later'],
          defaultId: 0
        });

        if (result.response === 0) {
          autoUpdater.checkForUpdatesAndNotify();
        }
      }
    } catch (error) {
      console.log('Update check failed:', error);
    }
  }

  private setupIpcHandlers(): void {
    ipcMain.handle('get-version', () => {
      return this.currentVersion;
    });

    ipcMain.handle('get-backend-url', () => {
      return `http://localhost:${this.backendPort}`;
    });
  }

  private showAbout(): void {
    dialog.showMessageBox(this.mainWindow!, {
      type: 'info',
      title: 'About Zedin Steam Manager',
      message: 'Zedin Steam Manager',
      detail: `Version: ${this.currentVersion}\n\nProfessional Steam Server Manager for ASE and ASA\n\nDeveloped by Zedin`
    });
  }
}

// Initialize the application
new ZedinSteamManager();

// Handle application events
app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

app.on('activate', () => {
  if (BrowserWindow.getAllWindows().length === 0) {
    new ZedinSteamManager();
  }
});