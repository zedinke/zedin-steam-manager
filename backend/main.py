"""FastAPI main application."""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from backend.config.settings import settings
from backend.routers import auth

app = FastAPI(
    title="Zedin Steam Manager API",
    version=settings.VERSION,
    description="Professional Steam Server Manager for ASE and ASA"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth.router, prefix="/api")

@app.get("/")
async def root():
    return {
        "message": "Zedin Steam Manager API",
        "version": settings.VERSION,
        "status": "online"
    }

@app.get("/api/health")
async def health():
    return {
        "status": "healthy",
        "version": settings.VERSION,
        "app_name": settings.APP_NAME
    }

@app.get("/api/version")
async def version():
    return {
        "version": settings.VERSION,
        "app_name": settings.APP_NAME
    }
