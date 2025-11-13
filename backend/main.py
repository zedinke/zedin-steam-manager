from fastapi import FastAPI

app = FastAPI(
    title="Zedin Steam Manager API",
    version="0.0.2-test",
    description="Professional Steam Server Manager"
)

@app.get("/api/health")
async def health_check():
    return {
        "status": "healthy",
        "version": "0.0.2-test",
        "service": "Zedin Steam Manager"
    }

@app.post("/api/auth/login")
async def login():
    return {
        "access_token": "test_token",
        "token_type": "bearer",
        "user": {
            "id": "test_user_id",
            "email": "test@example.com",
            "username": "testuser"
        }
    }
