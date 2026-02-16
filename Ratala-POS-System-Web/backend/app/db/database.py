"""
Database configuration and session management
"""
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
from sqlalchemy.exc import OperationalError
import psycopg2
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT
from urllib.parse import urlparse
from app.core.config import settings

# Base class for models
Base = declarative_base()

# Global engine variable
engine = None
SessionLocal = None


def create_database_if_not_exists():
    """Create the database if it doesn't exist (PostgreSQL only)"""
    db_url = settings.DATABASE_URL
    
    if 'postgresql://' in db_url or 'postgres://' in db_url:
        try:
            # Parse the database URL
            parsed = urlparse(db_url)
            db_name = parsed.path[1:] if parsed.path.startswith('/') else parsed.path  # Remove leading /
            
            # Get connection parameters
            host = parsed.hostname or 'localhost'
            port = parsed.port or 5432
            user = parsed.username or 'postgres'
            password = parsed.password or ''
            
            # Connect to PostgreSQL server (to default 'postgres' database)
            conn = psycopg2.connect(
                host=host,
                port=port,
                user=user,
                password=password,
                database='postgres'  # Connect to default postgres database
            )
            conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
            cursor = conn.cursor()
            
            # Check if database exists
            cursor.execute(
                "SELECT 1 FROM pg_catalog.pg_database WHERE datname = %s",
                (db_name,)
            )
            exists = cursor.fetchone()
            
            if not exists:
                # Create database
                cursor.execute(f'CREATE DATABASE "{db_name}"')
                print(f"Database '{db_name}' created successfully")
            else:
                print(f"Database '{db_name}' already exists")
            
            cursor.close()
            conn.close()
            return True
        except psycopg2.OperationalError as e:
            print(f"Could not connect to PostgreSQL: {e}")
            print(f"   Please ensure PostgreSQL is running and credentials are correct")
            return False
        except Exception as e:
            print(f"Could not create database automatically: {e}")
            print(f"   Please create the database manually:")
            print(f"   psql -U {user}")
            print(f"   CREATE DATABASE {db_name};")
            return False
    return True


def init_db():
    """Initialize database - create database if needed, then create all tables"""
    global engine, SessionLocal
    
    # Import all models to ensure they're registered with Base
    from app.models import (
        User, Customer, Category, MenuGroup, MenuItem,
        UnitOfMeasurement, Product, InventoryTransaction,
        Supplier, PurchaseBill, PurchaseReturn, PurchaseBillItem,
        Table, Session, Order, OrderItem, KOT,
        DeliveryPartner, BillOfMaterials, BOMItem, BatchProduction,
        POSSession, Printer, QRCode, Organization, Branch, Floor, StorageArea, DiscountRule, PaymentMode
    )
    
    # Skip automatic DB creation in production (Neon/Render environment)
    is_prod = settings.ENVIRONMENT == "production"
    
    # Create database if it doesn't exist (PostgreSQL only) - skip in production
    if not is_prod and ('postgresql' in settings.DATABASE_URL or 'postgres' in settings.DATABASE_URL):
        if not create_database_if_not_exists():
            print("Warning: Database creation failed or skipped.")
    
    engine = get_engine()
    
    # Create session factory
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    
    # Create all tables
    try:
        Base.metadata.create_all(bind=engine)
        print("Database tables initialized")

        # Manually fix schema for production
        from sqlalchemy import text
        try:
            with engine.connect() as conn:
                conn = conn.execution_options(isolation_level="AUTOCOMMIT")
                print("Checking schema for missing columns...")
                
                updates = [
                    ("users", "profile_image_url", "VARCHAR"),
                    ("users", "profile_image_data", "BYTEA"),
                    ("categories", "image_data", "BYTEA"),
                    ("menu_groups", "image_data", "BYTEA"),
                    ("menu_items", "image_data", "BYTEA"),
                    ("company_settings", "logo_url", "VARCHAR"),
                    ("company_settings", "logo_data", "BYTEA"),
                    ("payment_modes", "branch_id", "INTEGER"),
                    ("storage_areas", "branch_id", "INTEGER"),
                    ("discount_rules", "branch_id", "INTEGER"),
                    ("tables", "merged_to_id", "INTEGER"),
                    ("tables", "merge_group_id", "VARCHAR"),
                    ("branches", "tax_rate", "FLOAT"),
                    ("branches", "service_charge_rate", "FLOAT"),
                    ("branches", "discount_rate", "FLOAT"),
                    ("branches", "slug", "VARCHAR"),
                    ("roles", "branch_id", "INTEGER")
                ]
                
                for table, col, dtype in updates:
                    try:
                        conn.execute(text(f"ALTER TABLE {table} ADD COLUMN IF NOT EXISTS {col} {dtype}"))
                        print(f"  ✓ {table}.{col} verified")
                    except Exception as e:
                        print(f"  ⚠ Error checking {table}.{col}: {e}")
                
                print("✓ Schema verified")
                
                # Migrations: Populate missing slugs for branches
                from app.services.branch_service import slugify
                from app.models.branch import Branch
                
                branches_to_update = conn.execute(text("SELECT id, name FROM branches WHERE slug IS NULL")).fetchall()
                for row in branches_to_update:
                    new_slug = slugify(row[1])
                    conn.execute(text("UPDATE branches SET slug = :slug WHERE id = :id"), {"slug": new_slug, "id": row[0]})
                    print(f"  → Populated slug '{new_slug}' for branch ID {row[0]}")
        except Exception as e:
            print(f"⚠ Schema check failed: {e}")

    except OperationalError as e:
        print(f"Error creating tables: {e}")
        raise


def get_engine():
    """Get the database engine"""
    global engine
    if engine is None:
        # Check if we need SSL (usually for Neon/Render in production)
        connect_args = {
            "connect_timeout": 10,
            "options": "-c statement_timeout=30000"
        }
        
        # Add SSL if not localhost
        if "localhost" not in settings.DATABASE_URL and "127.0.0.1" not in settings.DATABASE_URL:
            connect_args["sslmode"] = "require"

        engine = create_engine(
            settings.DATABASE_URL,
            pool_pre_ping=True,
            pool_size=5,
            max_overflow=10,
            pool_recycle=3600,
            pool_timeout=30,
            connect_args=connect_args
        )
    return engine


def get_db():
    """
    Database dependency for FastAPI routes
    Yields a database session and closes it after use
    """
    global SessionLocal
    if SessionLocal is None:
        SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=get_engine())
    
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
