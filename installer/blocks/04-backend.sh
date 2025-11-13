#!/bin/bash

#############################################
# Block 04: Backend Setup
#############################################

echo "Setting up FastAPI backend..."

# Create application directory
APP_DIR="/opt/zedin-steam-manager"
BACKEND_DIR="$APP_DIR/backend"

mkdir -p "$BACKEND_DIR"
cd "$BACKEND_DIR"

# Check if git repository exists
if [ ! -d ".git" ]; then
    echo "Cloning repository..."
    cd "$APP_DIR"
    if git clone https://github.com/zedinke/zedin-steam-manager.git temp_repo 2>/dev/null; then
        mv temp_repo/* . 2>/dev/null || true
        mv temp_repo/.* . 2>/dev/null || true
        rm -rf temp_repo
        echo "✅ Repository cloned"
    else
        echo "⚠️  Repository not found, creating structure..."
    fi
fi

# Create Python virtual environment
if [ ! -d "$BACKEND_DIR/venv" ]; then
    echo "Creating Python virtual environment..."
    python3 -m venv "$BACKEND_DIR/venv"
    echo "✅ Virtual environment created"
else
    echo "✅ Virtual environment already exists"
fi

# Activate virtual environment
source "$BACKEND_DIR/venv/bin/activate"

# Create requirements.txt
cat > "$BACKEND_DIR/requirements.txt" << 'EOF'
fastapi==0.104.1
uvicorn[standard]==0.24.0
supabase==2.3.0
python-jose[cryptography]==3.3.0
python-multipart==0.0.6
pydantic==2.5.0
pydantic-settings==2.1.0
python-dotenv==1.0.0
httpx==0.24.1
aiosmtplib==3.0.1
email-validator==2.1.0
jinja2==3.1.2
EOF

# Install Python dependencies
echo "Installing Python dependencies..."
pip install --upgrade pip -q
pip install -r requirements.txt -q

if [ $? -eq 0 ]; then
    echo "✅ Python dependencies installed"
else
    echo "❌ Error: Failed to install Python dependencies"
    exit 1
fi

# Create backend structure
mkdir -p "$BACKEND_DIR/config"
mkdir -p "$BACKEND_DIR/models"
mkdir -p "$BACKEND_DIR/routers"
mkdir -p "$BACKEND_DIR/services"
mkdir -p "$BACKEND_DIR/templates"

# Create main.py
cat > "$BACKEND_DIR/main.py" << 'EOFPYTHON'
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routers import auth, system, dashboard
import os

app = FastAPI(
    title="Zedin Steam Manager API",
    version="0.0.1",
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

@app.get("/api/health")
async def health_check():
    return {
        "status": "healthy",
        "version": "0.0.1",
        "service": "Zedin Steam Manager"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
EOFPYTHON

# Create auth router with email verification
cat > "$BACKEND_DIR/routers/auth.py" << 'EOFPYTHON'
from fastapi import APIRouter, HTTPException, Depends, BackgroundTasks
from pydantic import BaseModel, EmailStr
from datetime import datetime, timedelta
from jose import jwt
import os
from services.supabase_client import get_supabase
from services.email_service import send_verification_email
import secrets

router = APIRouter()

class RegisterRequest(BaseModel):
    email: EmailStr
    password: str
    username: str

class LoginRequest(BaseModel):
    email: EmailStr
    password: str

class VerifyEmailRequest(BaseModel):
    token: str

def create_access_token(data: dict):
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(days=30)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, os.getenv("JWT_SECRET"), algorithm="HS256")

@router.post("/register")
async def register(request: RegisterRequest, background_tasks: BackgroundTasks):
    """Register new user with email verification"""
    supabase = get_supabase()
    
    try:
        # Create user in Supabase Auth
        response = supabase.auth.sign_up({
            "email": request.email,
            "password": request.password,
            "options": {
                "data": {
                    "username": request.username,
                    "email_verified": False
                }
            }
        })
        
        if response.user:
            # Generate verification token
            verification_token = secrets.token_urlsafe(32)
            
            # Store token in database
            supabase.table("email_verifications").insert({
                "user_id": response.user.id,
                "token": verification_token,
                "expires_at": (datetime.utcnow() + timedelta(hours=24)).isoformat()
            }).execute()
            
            # Send verification email in background
            background_tasks.add_task(
                send_verification_email,
                request.email,
                request.username,
                verification_token
            )
            
            return {
                "message": "Registration successful. Please check your email to verify your account.",
                "email": request.email
            }
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/verify-email")
async def verify_email(request: VerifyEmailRequest):
    """Verify user email with token"""
    supabase = get_supabase()
    
    try:
        # Find verification token
        result = supabase.table("email_verifications")\
            .select("*")\
            .eq("token", request.token)\
            .gt("expires_at", datetime.utcnow().isoformat())\
            .execute()
        
        if not result.data:
            raise HTTPException(status_code=400, detail="Invalid or expired verification token")
        
        verification = result.data[0]
        
        # Update user as verified
        supabase.auth.admin.update_user_by_id(
            verification["user_id"],
            {"email_verified": True}
        )
        
        # Delete verification token
        supabase.table("email_verifications")\
            .delete()\
            .eq("token", request.token)\
            .execute()
        
        return {"message": "Email verified successfully. You can now login."}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/login")
async def login(request: LoginRequest):
    """Login with email verification check"""
    supabase = get_supabase()
    
    try:
        # Sign in user
        response = supabase.auth.sign_in_with_password({
            "email": request.email,
            "password": request.password
        })
        
        if response.user:
            # Check if email is verified
            if not response.user.user_metadata.get("email_verified", False):
                raise HTTPException(
                    status_code=403,
                    detail="Please verify your email before logging in"
                )
            
            # Create JWT token
            token = create_access_token({
                "sub": response.user.id,
                "email": response.user.email,
                "username": response.user.user_metadata.get("username")
            })
            
            return {
                "access_token": token,
                "token_type": "bearer",
                "user": {
                    "id": response.user.id,
                    "email": response.user.email,
                    "username": response.user.user_metadata.get("username")
                }
            }
    except Exception as e:
        raise HTTPException(status_code=401, detail="Invalid credentials")

@router.post("/logout")
async def logout():
    """Logout user"""
    return {"message": "Logged out successfully"}
EOFPYTHON

# Create system router
cat > "$BACKEND_DIR/routers/system.py" << 'EOFPYTHON'
from fastapi import APIRouter
import psutil
import platform

router = APIRouter()

@app.get("/info")
async def get_system_info():
    """Get real-time system information"""
    return {
        "cpu": {
            "percent": psutil.cpu_percent(interval=1),
            "cores": psutil.cpu_count()
        },
        "memory": {
            "total": psutil.virtual_memory().total,
            "used": psutil.virtual_memory().used,
            "percent": psutil.virtual_memory().percent
        },
        "disk": {
            "total": psutil.disk_usage('/').total,
            "used": psutil.disk_usage('/').used,
            "percent": psutil.disk_usage('/').percent
        },
        "platform": platform.system(),
        "version": platform.version()
    }
EOFPYTHON

# Create dashboard router with git update
cat > "$BACKEND_DIR/routers/dashboard.py" << 'EOFPYTHON'
from fastapi import APIRouter, HTTPException
import subprocess
import os

router = APIRouter()

@router.post("/git-update")
async def git_update():
    """Update application from git repository"""
    app_dir = "/opt/zedin-steam-manager"
    
    try:
        # Check if git repository exists
        if not os.path.exists(os.path.join(app_dir, ".git")):
            raise HTTPException(status_code=400, detail="Not a git repository")
        
        # Fetch latest changes
        subprocess.run(
            ["git", "fetch", "origin", "main"],
            cwd=app_dir,
            check=True,
            capture_output=True
        )
        
        # Check if updates available
        result = subprocess.run(
            ["git", "rev-list", "HEAD...origin/main", "--count"],
            cwd=app_dir,
            capture_output=True,
            text=True,
            check=True
        )
        
        commits_behind = int(result.stdout.strip())
        
        if commits_behind == 0:
            return {
                "message": "Already up to date",
                "updated": False,
                "commits_behind": 0
            }
        
        # Pull updates
        subprocess.run(
            ["git", "pull", "origin", "main"],
            cwd=app_dir,
            check=True,
            capture_output=True
        )
        
        # Restart services
        subprocess.run(["systemctl", "restart", "zedin-backend"], check=False)
        subprocess.run(["systemctl", "restart", "zedin-frontend"], check=False)
        
        return {
            "message": f"Updated successfully ({commits_behind} commits)",
            "updated": True,
            "commits_behind": commits_behind
        }
    except subprocess.CalledProcessError as e:
        raise HTTPException(status_code=500, detail=f"Git update failed: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/git-status")
async def git_status():
    """Check if updates are available"""
    app_dir = "/opt/zedin-steam-manager"
    
    try:
        # Fetch latest changes
        subprocess.run(
            ["git", "fetch", "origin", "main"],
            cwd=app_dir,
            check=True,
            capture_output=True
        )
        
        # Check commits behind
        result = subprocess.run(
            ["git", "rev-list", "HEAD...origin/main", "--count"],
            cwd=app_dir,
            capture_output=True,
            text=True,
            check=True
        )
        
        commits_behind = int(result.stdout.strip())
        
        return {
            "updates_available": commits_behind > 0,
            "commits_behind": commits_behind
        }
    except Exception as e:
        return {
            "updates_available": False,
            "commits_behind": 0,
            "error": str(e)
        }
EOFPYTHON

# Create Supabase client service
cat > "$BACKEND_DIR/services/supabase_client.py" << 'EOFPYTHON'
from supabase import create_client, Client
import os
from dotenv import load_dotenv

load_dotenv()

_supabase_client: Client = None

def get_supabase() -> Client:
    """Get Supabase client singleton"""
    global _supabase_client
    if _supabase_client is None:
        url = os.getenv("SUPABASE_URL")
        key = os.getenv("SUPABASE_KEY")
        _supabase_client = create_client(url, key)
    return _supabase_client
EOFPYTHON

# Create email service
cat > "$BACKEND_DIR/services/email_service.py" << 'EOFPYTHON'
import aiosmtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import os
from jinja2 import Template

async def send_verification_email(email: str, username: str, token: str):
    """Send email verification"""
    frontend_url = os.getenv("FRONTEND_URL", "http://localhost")
    verification_url = f"{frontend_url}/verify-email?token={token}"
    
    # Email template
    html_template = Template("""
    <!DOCTYPE html>
    <html>
    <head>
        <style>
            body { font-family: Arial, sans-serif; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .button { background-color: #4CAF50; color: white; padding: 12px 24px; 
                     text-decoration: none; border-radius: 4px; display: inline-block; }
        </style>
    </head>
    <body>
        <div class="container">
            <h2>Welcome to Zedin Steam Manager!</h2>
            <p>Hello {{ username }},</p>
            <p>Thank you for registering. Please verify your email address by clicking the button below:</p>
            <p><a href="{{ verification_url }}" class="button">Verify Email</a></p>
            <p>Or copy this link: {{ verification_url }}</p>
            <p>This link will expire in 24 hours.</p>
            <p>If you didn't register, please ignore this email.</p>
        </div>
    </body>
    </html>
    """)
    
    html_content = html_template.render(username=username, verification_url=verification_url)
    
    # Create message
    message = MIMEMultipart("alternative")
    message["Subject"] = "Verify your email - Zedin Steam Manager"
    message["From"] = os.getenv("SMTP_USER", "noreply@zedinmanager.com")
    message["To"] = email
    
    message.attach(MIMEText(html_content, "html"))
    
    # Send email
    try:
        await aiosmtplib.send(
            message,
            hostname=os.getenv("SMTP_HOST", "smtp.gmail.com"),
            port=int(os.getenv("SMTP_PORT", 587)),
            username=os.getenv("SMTP_USER"),
            password=os.getenv("SMTP_PASSWORD"),
            start_tls=True
        )
    except Exception as e:
        print(f"Failed to send email: {e}")
EOFPYTHON

# Create __init__.py files
touch "$BACKEND_DIR/routers/__init__.py"
touch "$BACKEND_DIR/services/__init__.py"
touch "$BACKEND_DIR/config/__init__.py"
touch "$BACKEND_DIR/models/__init__.py"

echo "✅ Backend structure created"

# Test backend
echo "Testing backend..."
cd "$BACKEND_DIR"
timeout 5 python3 main.py &
PID=$!
sleep 3
if ps -p $PID > /dev/null; then
    echo "✅ Backend started successfully"
    kill $PID 2>/dev/null
else
    echo "❌ Backend failed to start"
    exit 1
fi

echo ""
echo "✅ Backend setup completed"
echo ""
