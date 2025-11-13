"""Drop all tables and recreate them - USE WITH CAUTION!"""
import sys
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from backend.config.database import engine, Base
from backend.models import User, UserToken, Server, Host

def drop_all_tables():
    """Drop all tables."""
    print("⚠️  WARNING: This will DELETE ALL DATA!")
    print("\nTables to be dropped:")
    print("- users")
    print("- user_tokens")
    print("- servers")
    print("- hosts")
    print("\nThis action cannot be undone!")
    
    confirm = input("\nType 'yes' to continue: ")
    if confirm.lower() != 'yes':
        print("Operation cancelled.")
        return False
    
    print("\nDropping all tables...")
    Base.metadata.drop_all(bind=engine)
    print("✅ All tables dropped!")
    return True

def create_all_tables():
    """Create all tables."""
    print("\nCreating new tables...")
    Base.metadata.create_all(bind=engine)
    print("✅ Tables created successfully!")
    print("\nTables created:")
    print("- users")
    print("- user_tokens")
    print("- servers")
    print("- hosts")

if __name__ == "__main__":
    if drop_all_tables():
        create_all_tables()
        print("\n✅ Database reset complete!")
    else:
        print("\n❌ Database reset cancelled.")
