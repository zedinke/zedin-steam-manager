from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
import uvicorn
from contextlib import asynccontextmanager

from config.database import engine
from config.settings import Settings
from models import base
from routers import auth, servers, dashboard, system, files
from services.update_service import UpdateService
from services.scheduler import start_scheduler
from middleware.language import LanguageMiddleware

# Database initialization
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    base.Base.metadata.create_all(bind=engine)
    start_scheduler()
    yield
    # Shutdown - cleanup if needed

# Initialize FastAPI with lifespan
app = FastAPI(
    title="Zedin Steam Manager API",
    description="Professional Steam Server Manager for ASE and ASA",
    version="0.000001",
    lifespan=lifespan
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://127.0.0.1:3000", "*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Language middleware
app.add_middleware(LanguageMiddleware)

# Security
security = HTTPBearer()

# API Routes
app.include_router(auth.router, tags=["Authentication"])
app.include_router(servers.router, prefix="/api/servers", tags=["Server Management"])
app.include_router(dashboard.router, prefix="/api/dashboard", tags=["Dashboard"])
app.include_router(system.router, prefix="/api/system", tags=["System"])
app.include_router(files.router, prefix="/api/files", tags=["File Management"])

# Health check endpoint
@app.get("/api/health")
async def health_check():
    return {
        "status": "healthy",
        "version": "0.000001",
        "message": "Zedin Steam Manager API is running"
    }

# Version endpoint
@app.get("/api/version")
async def get_version():
    return {
        "version": "0.000001",
        "name": "Zedin Steam Manager",
        "description": "Professional Steam Server Manager for ASE and ASA"
    }

# Update check endpoint
@app.get("/api/check-updates")
async def check_updates():
    update_service = UpdateService()
    return await update_service.check_for_updates()

# Root endpoint
@app.get("/")
async def root():
    return {"message": "Zedin Steam Manager API", "version": "0.000001"}

if __name__ == "__main__":
    settings = Settings()
    uvicorn.run(
        "main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG,
        log_level="info"
    )