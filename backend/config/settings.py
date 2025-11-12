import os
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    # Application
    APP_NAME: str = "Zedin Steam Manager"
    VERSION: str = "0.000001"
    DEBUG: bool = True
    
    # Server
    HOST: str = "0.0.0.0"
    PORT: int = 8000
    
    # Database
    DATABASE_URL: str = "sqlite:///./zedin_steam_manager.db"
    
    # Security
    SECRET_KEY: str = "zedin-steam-manager-secret-key-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    # Steam
    STEAMCMD_PATH: str = "./steamcmd"
    SHARED_FILES_PATH: str = "./shared_files"
    SERVERS_PATH: str = "./servers"
    
    # ASE/ASA Configuration
    ASE_APP_ID: str = "376030"
    ASA_APP_ID: str = "2430930"
    
    # Update checking
    GITHUB_REPO: str = "zedin/steam-manager"
    UPDATE_CHECK_INTERVAL: int = 3600  # 1 hour in seconds
    
    # System monitoring
    SYSTEM_MONITOR_INTERVAL: int = 5  # 5 seconds
    
    # Logging
    LOG_LEVEL: str = "INFO"
    LOG_FILE: str = "./logs/steam_manager.log"
    
    # Remote hosts
    MAX_REMOTE_HOSTS: int = 10
    SSH_TIMEOUT: int = 30
    
    # RCON
    RCON_TIMEOUT: int = 10
    
    # Frontend URL
    FRONTEND_URL: str = "http://142.132.194.186"
    
    # Email Configuration (Gmail SMTP)
    EMAIL_SENDER: str = "noreply@zedinsteammanager.com"
    EMAIL_PASSWORD: str = "your_app_password_here"  # Gmail App Password
    EMAIL_ENABLED: bool = False  # Set to True when email is configured
    
    # External Database (PlanetScale/Supabase/Neon)
    EXTERNAL_DATABASE_URL: str = ""  # Set this for external database
    USE_EXTERNAL_DB: bool = False
    
    class Config:
        env_file = ".env"

# Create settings instance
settings = Settings()