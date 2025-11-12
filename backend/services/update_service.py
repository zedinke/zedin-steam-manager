import asyncio
import requests
from config.settings import Settings

class UpdateService:
    def __init__(self):
        self.settings = Settings()
    
    async def check_for_updates(self):
        """Check GitHub for new releases"""
        try:
            url = f"https://api.github.com/repos/{self.settings.GITHUB_REPO}/releases/latest"
            response = requests.get(url)
            
            if response.status_code == 200:
                data = response.json()
                latest_version = data.get('tag_name', '').replace('v', '')
                
                return {
                    "hasUpdate": latest_version != self.settings.VERSION,
                    "currentVersion": self.settings.VERSION,
                    "latestVersion": latest_version,
                    "downloadUrl": data.get('html_url', '')
                }
            else:
                return {
                    "hasUpdate": False,
                    "currentVersion": self.settings.VERSION,
                    "latestVersion": self.settings.VERSION,
                    "error": "Could not check for updates"
                }
        except Exception as e:
            return {
                "hasUpdate": False,
                "currentVersion": self.settings.VERSION,
                "latestVersion": self.settings.VERSION,
                "error": str(e)
            }
    
    async def update_manager(self):
        """Update the manager (placeholder)"""
        return {"message": "Update functionality not implemented yet"}