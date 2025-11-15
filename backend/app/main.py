"""Main FastAPI application"""
import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.core.config import settings
from app.core.database import connect_db, disconnect_db
from app.api.endpoints import auth, projects, versions, notes, sessions, ai, references

# Configure logging
logging.basicConfig(
    level=getattr(logging, settings.log_level),
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan events"""
    # Startup
    logger.info("Starting Production Tracker API...")
    await connect_db()
    logger.info("Database connected")
    yield
    # Shutdown
    logger.info("Shutting down...")
    await disconnect_db()
    logger.info("Database disconnected")


# Create FastAPI application
app = FastAPI(
    title="Production Tracker API",
    description="AI-powered production assistant for Ableton Live",
    version="1.0.0",
    lifespan=lifespan
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth.router, prefix="/api/auth", tags=["Authentication"])
app.include_router(projects.router, prefix="/api/projects", tags=["Projects"])
app.include_router(versions.router, prefix="/api/versions", tags=["Versions"])
app.include_router(notes.router, prefix="/api/notes", tags=["Notes"])
app.include_router(sessions.router, prefix="/api/sessions", tags=["Sessions"])
app.include_router(ai.router, prefix="/api/ai", tags=["AI"])
app.include_router(references.router, prefix="/api/references", tags=["References"])


@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "Production Tracker API",
        "version": "1.0.0",
        "docs": "/docs"
    }


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy"}


# Global exception handler
@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    """Handle all uncaught exceptions"""
    logger.error(f"Unhandled exception: {exc}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal server error"}
    )
