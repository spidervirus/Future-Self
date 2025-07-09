from fastapi import APIRouter
from app.core.config import settings
from app.database.connection import check_database_health, check_supabase_health

router = APIRouter()


@router.get("/")
async def health_check():
    """Detailed health check endpoint"""
    # Check database health
    db_health = await check_database_health()
    supabase_health = await check_supabase_health()
    
    # Overall health status
    overall_status = "healthy"
    if db_health["status"] != "healthy" or supabase_health["status"] != "healthy":
        overall_status = "degraded"
    
    return {
        "status": overall_status,
        "service": "Future Self API",
        "version": settings.VERSION,
        "environment": settings.ENVIRONMENT,
        "debug": settings.DEBUG,
        "checks": {
            "database": db_health,
            "supabase": supabase_health
        }
    }


@router.get("/ping")
async def ping():
    """Simple ping endpoint"""
    return {"message": "pong"}


@router.get("/database")
async def database_health():
    """Database-specific health check"""
    return await check_database_health()


@router.get("/supabase")
async def supabase_health():
    """Supabase-specific health check"""
    return await check_supabase_health() 