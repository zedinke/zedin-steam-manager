import psutil
import os
from datetime import datetime

class SystemService:
    def __init__(self, db):
        self.db = db
    
    def get_system_info(self):
        """Get real-time system information"""
        try:
            # CPU usage
            cpu_percent = psutil.cpu_percent(interval=1)
            
            # Memory usage
            memory = psutil.virtual_memory()
            memory_total = round(memory.total / 1024 / 1024)  # MB
            memory_used = round(memory.used / 1024 / 1024)    # MB
            
            # Disk usage
            disk = psutil.disk_usage('/')
            disk_total = round(disk.total / 1024 / 1024 / 1024)  # GB
            disk_used = round(disk.used / 1024 / 1024 / 1024)    # GB
            
            # Network usage
            network = psutil.net_io_counters()
            network_sent = round(network.bytes_sent / 1024 / 1024)  # MB
            network_recv = round(network.bytes_recv / 1024 / 1024) # MB
            
            return {
                "cpu_percent": cpu_percent,
                "memory_total": memory_total,
                "memory_used": memory_used,
                "disk_total": disk_total,
                "disk_used": disk_used,
                "network_sent": network_sent,
                "network_recv": network_recv,
                "timestamp": datetime.utcnow().isoformat()
            }
        except Exception as e:
            return {
                "error": str(e),
                "timestamp": datetime.utcnow().isoformat()
            }
    
    def get_servers_summary(self, user_id: int):
        """Get summary of all servers"""
        return {
            "total_servers": 0,
            "running_servers": 0,
            "installing_servers": 0,
            "stopped_servers": 0
        }
    
    def get_remote_hosts(self):
        """Get registered remote hosts"""
        return []
    
    def register_remote_host(self, host_data):
        """Register new remote host"""
        return {"message": "Remote host registration not implemented yet"}
    
    def remove_remote_host(self, host_id):
        """Remove remote host"""
        return {"message": "Remote host removal not implemented yet"}