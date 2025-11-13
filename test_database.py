#!/usr/bin/env python3

import sys
import psycopg2
from urllib.parse import urlparse

def test_supabase_connection(connection_string):
    """Test Supabase PostgreSQL connection"""
    
    print("🔌 Testing Supabase database connection...")
    print(f"Connection string: {connection_string[:50]}...{connection_string[-20:]}")
    print()
    
    try:
        # Parse connection string
        parsed = urlparse(connection_string)
        
        print("📋 Connection details:")
        print(f"  Host: {parsed.hostname}")
        print(f"  Port: {parsed.port}")
        print(f"  Database: {parsed.path[1:]}")
        print(f"  User: {parsed.username}")
        print(f"  Password: {'*' * len(parsed.password) if parsed.password else 'None'}")
        print()
        
        # Test connection
        print("🔗 Connecting to database...")
        conn = psycopg2.connect(connection_string)
        
        print("✅ Connection successful!")
        
        # Test basic operations
        cursor = conn.cursor()
        
        print("📊 Testing basic database operations...")
        
        # Get PostgreSQL version
        cursor.execute("SELECT version();")
        version = cursor.fetchone()[0]
        print(f"  PostgreSQL version: {version.split(',')[0]}")
        
        # Test creating a simple table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS test_connection (
                id SERIAL PRIMARY KEY,
                test_message TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """)
        
        # Insert test data
        cursor.execute("""
            INSERT INTO test_connection (test_message) 
            VALUES ('ZedinSteamManager connection test successful!');
        """)
        
        # Read test data
        cursor.execute("SELECT * FROM test_connection ORDER BY created_at DESC LIMIT 1;")
        result = cursor.fetchone()
        
        print(f"  Test insert/select: ✅ ID={result[0]}, Message='{result[1]}'")
        
        # Clean up test table
        cursor.execute("DROP TABLE test_connection;")
        
        # Commit changes
        conn.commit()
        
        print("  Cleanup: ✅ Test table removed")
        
        # Close connection
        cursor.close()
        conn.close()
        
        print()
        print("🎉 All tests passed! Supabase database is ready for ZedinSteamManager!")
        return True
        
    except psycopg2.OperationalError as e:
        print(f"❌ Connection failed: {e}")
        print()
        print("💡 Common issues:")
        print("  - Wrong password")
        print("  - Network/firewall blocking connection")
        print("  - Incorrect connection string format")
        return False
        
    except psycopg2.Error as e:
        print(f"❌ Database error: {e}")
        return False
        
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        return False

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 test_database.py 'postgresql://connection_string'")
        print()
        print("Example:")
        print("python3 test_database.py 'postgresql://postgres:password@db.project.supabase.co:5432/postgres'")
        sys.exit(1)
    
    connection_string = sys.argv[1]
    success = test_supabase_connection(connection_string)
    sys.exit(0 if success else 1)