"""
Database Initialization Script for PostgreSQL.
Creates the database and enables pgvector extension.

Usage:
    python scripts/init_db.py
"""
import asyncio
import asyncpg
from sqlalchemy.ext.asyncio import create_async_engine

# Database connection settings
DB_HOST = "localhost"
DB_PORT = 5432
DB_USER = "postgres"
DB_PASSWORD = "postgres"
DB_NAME = "medical_study_db"


async def create_database():
    """Create the database if it doesn't exist."""
    # Connect to default postgres database
    try:
        conn = await asyncpg.connect(
            host=DB_HOST,
            port=DB_PORT,
            user=DB_USER,
            password=DB_PASSWORD,
            database="postgres"
        )
        
        # Check if database exists
        result = await conn.fetchrow(
            "SELECT 1 FROM pg_database WHERE datname = $1", DB_NAME
        )
        
        if not result:
            # Create database
            await conn.execute(f'CREATE DATABASE {DB_NAME}')
            print(f"[OK] Database '{DB_NAME}' created successfully!")
        else:
            print(f"[INFO] Database '{DB_NAME}' already exists.")
        
        await conn.close()
        
    except Exception as e:
        print(f"[ERROR] Error creating database: {e}")
        raise


async def enable_pgvector():
    """Enable pgvector extension (optional - will warn if not available)."""
    try:
        conn = await asyncpg.connect(
            host=DB_HOST,
            port=DB_PORT,
            user=DB_USER,
            password=DB_PASSWORD,
            database=DB_NAME
        )
        
        # Enable pgvector extension
        await conn.execute('CREATE EXTENSION IF NOT EXISTS vector')
        print("[OK] pgvector extension enabled!")
        
        await conn.close()
        
    except Exception as e:
        print(f"[WARNING] pgvector not available (optional): {e}")
        print("[INFO] Continuing without vector search - using JSON for embeddings...")
        # Don't raise - pgvector is optional


async def create_tables():
    """Create all database tables."""
    try:
        # Import after database is created
        import sys
        sys.path.insert(0, 'c:/123TIP/backend')
        
        from app.database import engine, Base
        from app import models  # noqa - registers models
        
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
        
        print("[OK] All tables created successfully!")
        print("\nCreated tables:")
        for table_name in Base.metadata.tables.keys():
            print(f"   • {table_name}")
            
    except Exception as e:
        print(f"[ERROR] Error creating tables: {e}")
        raise


async def main():
    """Main initialization function."""
    print("=" * 50)
    print("Medical Study App - Database Initialization")
    print("=" * 50)
    print()
    
    print("Step 1: Creating database...")
    await create_database()
    
    print("\nStep 2: Enabling pgvector extension...")
    await enable_pgvector()
    
    print("\nStep 3: Creating tables...")
    await create_tables()
    
    print("\n" + "=" * 50)
    print("[OK] Database initialization complete!")
    print("=" * 50)


if __name__ == "__main__":
    asyncio.run(main())
