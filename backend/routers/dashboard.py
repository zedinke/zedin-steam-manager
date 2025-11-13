from fastapi import APIRouter, HTTPException
import subprocess
import os

router = APIRouter()

# Git executable path
GIT_CMD = "/usr/bin/git"

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
            [GIT_CMD, "fetch", "origin", "main"],
            cwd=app_dir,
            check=True,
            capture_output=True
        )
        
        # Check if updates available
        result = subprocess.run(
            [GIT_CMD, "rev-list", "HEAD...origin/main", "--count"],
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
            [GIT_CMD, "pull", "origin", "main"],
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
            [GIT_CMD, "fetch", "origin", "main"],
            cwd=app_dir,
            check=True,
            capture_output=True
        )
        
        # Check commits behind
        result = subprocess.run(
            [GIT_CMD, "rev-list", "HEAD...origin/main", "--count"],
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
