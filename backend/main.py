from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import sys
import os

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from routers import auth, system, dashboard, tokens

app = FastAPI(
    title="Zedin Steam Manager API",
    version="0.0.2-test",
    description="Professional Steam Server Manager"
)

# CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth.router, prefix="/api/auth", tags=["Authentication"])
app.include_router(system.router, prefix="/api/system", tags=["System"])
app.include_router(dashboard.router, prefix="/api/dashboard", tags=["Dashboard"])
app.include_router(tokens.router, prefix="/api", tags=["Tokens & Notifications"])

@app.get("/api/health")
async def health_check():
    return {
        "status": "healthy",
        "version": "0.0.2-test",
        "service": "Zedin Steam Manager"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
