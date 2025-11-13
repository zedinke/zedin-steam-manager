"""Database initialization script - creates all tables."""
import sys
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from backend.config.database import engine, Base
from backend.models import User, UserToken, Server, Host

def init_database():
    """Create all database tables."""
    print("Creating database tables...")
    Base.metadata.create_all(bind=engine)
    print("✅ Database tables created successfully!")
    print("\nTables created:")
    print("- users")
    print("- user_tokens")
    print("- servers")
    print("- hosts")

if __name__ == "__main__":
    init_database()
