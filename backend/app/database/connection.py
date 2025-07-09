from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, Session
from supabase import create_client, Client
import logging

from app.core.config import settings
from app.models.base import Base

logger = logging.getLogger(__name__)

# Database engine
engine = None
SessionLocal = None

# Supabase client
supabase: Client = None


def get_database_url() -> str:
    """Construct database URL from Supabase settings"""
    if settings.DATABASE_URL:
        return settings.DATABASE_URL
    
    # Extract database info from Supabase URL if needed
    # Format: postgresql://user:password@host:port/dbname
    supabase_url = settings.SUPABASE_URL
    if supabase_url:
        # This is a simplified approach - you might need to adjust based on your Supabase setup
        host = supabase_url.replace("https://", "").replace("http://", "")
        return f"postgresql://postgres:password@db.{host}:5432/postgres"
    
    raise ValueError("No database URL configured")


def init_database():
    """Initialize database connection and create tables"""
    global engine, SessionLocal, supabase
    
    try:
        # Initialize Supabase client (will fail with placeholder but continue)
        try:
            supabase = create_client(settings.SUPABASE_URL, settings.SUPABASE_ANON_KEY)
            logger.info("✅ Supabase client initialized")
        except Exception as e:
            logger.warning(f"⚠️ Supabase initialization failed: {e} (using fallback)")
            supabase = None
        
        # Create database engine - use SQLite in-memory for testing if real DB fails
        try:
            # Check if we have real database credentials
            if (settings.SUPABASE_URL.startswith("https://placeholder") or 
                "placeholder" in settings.SUPABASE_URL):
                raise ValueError("Using placeholder credentials, falling back to SQLite")
            
            database_url = get_database_url()
            engine = create_engine(
                database_url,
                pool_size=20,
                max_overflow=0,
                pool_recycle=3600,
                pool_pre_ping=False,
                echo=settings.DEBUG,  # Log SQL queries in debug mode
            )
            
            # Test connection
            with engine.connect() as conn:
                from sqlalchemy import text
                conn.execute(text("SELECT 1"))
            
            logger.info("✅ Connected to real database")
            
        except Exception as e:
            logger.warning(f"⚠️ Real database connection failed: {e} (using SQLite fallback)")
            # Use SQLite in-memory database for testing
            engine = create_engine(
                "sqlite:///:memory:",
                echo=settings.DEBUG,
                connect_args={"check_same_thread": False},
            )
        
        # Create session factory
        SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
        
        # Create tables
        Base.metadata.create_all(bind=engine)
        logger.info("✅ Database tables created/verified")
        
        logger.info("✅ Database initialized successfully")
        
    except Exception as e:
        logger.error(f"❌ Failed to initialize database: {e}")
        raise


def get_db() -> Session:
    """Get database session dependency for FastAPI"""
    if SessionLocal is None:
        raise RuntimeError("Database not initialized. Call init_database() first.")
    
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def get_supabase() -> Client:
    """Get Supabase client"""
    if supabase is None:
        logger.warning("⚠️ Supabase client not available, using fallback mode")
        return None
    return supabase


def close_database():
    """Close database connections"""
    global engine
    if engine:
        engine.dispose()
        logger.info("🔌 Database connections closed")


# Health check function
async def check_database_health() -> dict:
    """Check database connectivity"""
    try:
        if SessionLocal is None:
            return {"status": "error", "message": "Database not initialized"}
        
        db = SessionLocal()
        try:
            # Simple query to test connection
            from sqlalchemy import text
            result = db.execute(text("SELECT 1"))
            result.fetchone()
            return {"status": "healthy", "message": "Database connection OK"}
        finally:
            db.close()
            
    except Exception as e:
        return {"status": "error", "message": f"Database connection failed: {str(e)}"}


async def check_supabase_health() -> dict:
    """Check Supabase connectivity"""
    try:
        if supabase is None:
            return {"status": "warning", "message": "Using SQLite fallback (Supabase not available)"}
        
        # Test Supabase connection with a simple query
        response = supabase.table("users").select("count", count="exact").limit(0).execute()
        return {"status": "healthy", "message": "Supabase connection OK"}
        
    except Exception as e:
        return {"status": "error", "message": f"Supabase connection failed: {str(e)}"} 