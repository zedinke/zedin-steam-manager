"""
Log management router for viewing and managing log files
"""
from fastapi import APIRouter, HTTPException, Query
from fastapi.responses import FileResponse, PlainTextResponse
import os
from pathlib import Path
from typing import List, Optional
import json
from datetime import datetime

from config.logging_config import system_logger, log_system_info

router = APIRouter()

LOGS_DIR = Path(__file__).parent.parent.parent / "logs"

@router.get("/logs/list")
async def list_log_files():
    """List all available log files"""
    try:
        log_system_info("📋 Listing log files requested")
        
        if not LOGS_DIR.exists():
            return {"logs": [], "message": "No logs directory found"}
        
        log_files = []
        for log_file in LOGS_DIR.glob("*.log"):
            stat = log_file.stat()
            log_files.append({
                "name": log_file.name,
                "size": stat.st_size,
                "size_mb": round(stat.st_size / (1024 * 1024), 2),
                "modified": datetime.fromtimestamp(stat.st_mtime).isoformat(),
                "path": str(log_file)
            })
        
        log_files.sort(key=lambda x: x["modified"], reverse=True)
        
        return {
            "logs": log_files,
            "total_files": len(log_files),
            "logs_directory": str(LOGS_DIR)
        }
        
    except Exception as e:
        system_logger.error(f"❌ Error listing log files: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error listing logs: {str(e)}")

@router.get("/logs/view/{log_name}")
async def view_log_file(
    log_name: str,
    lines: Optional[int] = Query(100, description="Number of lines to return from end of file"),
    download: Optional[bool] = Query(False, description="Download file instead of viewing")
):
    """View or download a specific log file"""
    try:
        log_system_info(f"📖 Log file requested: {log_name}")
        
        log_file = LOGS_DIR / log_name
        
        if not log_file.exists():
            raise HTTPException(status_code=404, detail=f"Log file {log_name} not found")
        
        if not log_file.name.endswith('.log'):
            raise HTTPException(status_code=400, detail="Invalid log file extension")
        
        if download:
            return FileResponse(
                path=log_file,
                filename=log_name,
                media_type='text/plain'
            )
        
        # Read last N lines
        try:
            with open(log_file, 'r', encoding='utf-8') as f:
                all_lines = f.readlines()
                
            # Get last N lines
            if lines and lines > 0:
                selected_lines = all_lines[-lines:]
            else:
                selected_lines = all_lines
                
            content = ''.join(selected_lines)
            
            return PlainTextResponse(
                content=content,
                headers={
                    "Content-Type": "text/plain; charset=utf-8",
                    "X-Total-Lines": str(len(all_lines)),
                    "X-Returned-Lines": str(len(selected_lines))
                }
            )
            
        except UnicodeDecodeError:
            # Fallback for binary content
            with open(log_file, 'rb') as f:
                content = f.read()
            return PlainTextResponse(
                content=content.decode('utf-8', errors='replace'),
                headers={"Content-Type": "text/plain; charset=utf-8"}
            )
            
    except HTTPException:
        raise
    except Exception as e:
        system_logger.error(f"❌ Error reading log file {log_name}: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error reading log: {str(e)}")

@router.get("/logs/tail/{log_name}")
async def tail_log_file(
    log_name: str,
    lines: Optional[int] = Query(50, description="Number of recent lines to return")
):
    """Get the tail (last N lines) of a log file - useful for live monitoring"""
    try:
        log_file = LOGS_DIR / log_name
        
        if not log_file.exists():
            raise HTTPException(status_code=404, detail=f"Log file {log_name} not found")
        
        with open(log_file, 'r', encoding='utf-8') as f:
            all_lines = f.readlines()
        
        recent_lines = all_lines[-lines:] if lines else all_lines
        
        return {
            "log_name": log_name,
            "total_lines": len(all_lines),
            "returned_lines": len(recent_lines),
            "content": recent_lines,
            "timestamp": datetime.now().isoformat()
        }
        
    except Exception as e:
        system_logger.error(f"❌ Error tailing log file {log_name}: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error tailing log: {str(e)}")

@router.delete("/logs/clear/{log_name}")
async def clear_log_file(log_name: str):
    """Clear (truncate) a specific log file"""
    try:
        log_system_info(f"🗑️ Clear log file requested: {log_name}")
        
        log_file = LOGS_DIR / log_name
        
        if not log_file.exists():
            raise HTTPException(status_code=404, detail=f"Log file {log_name} not found")
        
        # Truncate the file
        with open(log_file, 'w', encoding='utf-8') as f:
            f.write("")
        
        system_logger.info(f"✅ Log file cleared: {log_name}")
        
        return {
            "success": True,
            "message": f"Log file {log_name} cleared successfully",
            "timestamp": datetime.now().isoformat()
        }
        
    except Exception as e:
        system_logger.error(f"❌ Error clearing log file {log_name}: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error clearing log: {str(e)}")

@router.get("/logs/stats")
async def get_logs_stats():
    """Get statistics about all log files"""
    try:
        if not LOGS_DIR.exists():
            return {
                "total_files": 0,
                "total_size_mb": 0,
                "files": []
            }
        
        total_size = 0
        files_stats = []
        
        for log_file in LOGS_DIR.glob("*.log"):
            stat = log_file.stat()
            size = stat.st_size
            total_size += size
            
            # Count lines
            try:
                with open(log_file, 'r', encoding='utf-8') as f:
                    line_count = sum(1 for _ in f)
            except:
                line_count = 0
            
            files_stats.append({
                "name": log_file.name,
                "size_bytes": size,
                "size_mb": round(size / (1024 * 1024), 2),
                "lines": line_count,
                "modified": datetime.fromtimestamp(stat.st_mtime).isoformat()
            })
        
        return {
            "total_files": len(files_stats),
            "total_size_mb": round(total_size / (1024 * 1024), 2),
            "logs_directory": str(LOGS_DIR),
            "files": files_stats,
            "timestamp": datetime.now().isoformat()
        }
        
    except Exception as e:
        system_logger.error(f"❌ Error getting log stats: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error getting log stats: {str(e)}")