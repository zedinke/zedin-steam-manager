#!/usr/bin/env python3
"""
Create admin user for Zedin Steam Manager
Run this on the server after installation
"""

import sys
import os

# Add backend to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'backend'))

from sqlalchemy.orm import Session
from config.database import engine, SessionLocal
from models.user import User, UserRole
from models.base import Base

def create_admin():
    """Create admin user"""
    
    # Create tables if they don't exist
    Base.metadata.create_all(bind=engine)
    
    db: Session = SessionLocal()
    
    try:
        # Check if admin exists
        admin = db.query(User).filter(User.email == "geleako@gmail.com").first()
        
        if admin:
            print(f"✅ Admin user already exists: {admin.email}")
            print(f"   Role: {admin.role.value}")
            print(f"   Active: {admin.is_active}")
            return
        
        # Create admin user
        admin = User(
            email="geleako@gmail.com",
            first_name="Admin",
            last_name="User",
            role=UserRole.ADMIN,
            is_active=True
        )
        admin.set_password("Admin123!")  # Change this!
        
        db.add(admin)
        db.commit()
        db.refresh(admin)
        
        print("✅ Admin user created successfully!")
        print(f"   Email: {admin.email}")
        print(f"   Password: Admin123!")
        print(f"   Role: {admin.role.value}")
        print("")
        print("⚠️  IMPORTANT: Change the password after first login!")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    create_admin()
