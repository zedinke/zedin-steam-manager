from fastapi import HTTPException

class DummyUser:
    def __init__(self):
        self.id = 1
        self.username = "admin"
        self.email = "admin@zedin.com"
        self.is_admin = True

def get_current_user():
    """Simplified auth service for demo"""
    return DummyUser()