from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from config.settings import settings
import os

# Determine which database to use
if settings.USE_EXTERNAL_DB and settings.EXTERNAL_DATABASE_URL:
    DATABASE_URL = settings.EXTERNAL_DATABASE_URL
    print(f"🌐 Using external database: {DATABASE_URL.split('@')[1] if '@' in DATABASE_URL else 'configured'}")
else:
    DATABASE_URL = settings.DATABASE_URL
    print(f"💾 Using local database: {DATABASE_URL}")

# Create database engine with appropriate settings
if "sqlite" in DATABASE_URL:
    # SQLite specific settings
    engine = create_engine(
        DATABASE_URL,
        connect_args={"check_same_thread": False}
    )
elif "postgresql" in DATABASE_URL:
    # PostgreSQL specific settings (Supabase/Neon)
    engine = create_engine(
        DATABASE_URL,
        pool_size=10,
        max_overflow=20,
        pool_pre_ping=True,
        connect_args={
            "sslmode": "require"
        }
    )
elif "mysql" in DATABASE_URL:
    # MySQL specific settings (PlanetScale)
    engine = create_engine(
        DATABASE_URL,
        pool_size=10,
        max_overflow=20,
        pool_pre_ping=True,
        connect_args={
            "ssl_disabled": False
        }
    )
else:
    # Default settings
    engine = create_engine(DATABASE_URL)

# Create SessionLocal class
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Create Base class for models
Base = declarative_base()

# Dependency to get database session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Test database connection
def test_connection():
    try:
        with engine.connect() as connection:
            print("✅ Database connection successful")
            return True
    except Exception as e:
        print(f"❌ Database connection failed: {e}")
        return False