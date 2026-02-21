"""
FastAPI Main Application
AI Smart Ride Matching API
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from app.core.config import settings
from app.api import match, preferences, analytics, agora, notifications, ratings

# Create FastAPI app
app = FastAPI(
    title=settings.PROJECT_NAME,
    description="AI-powered ride compatibility matching API for carpooling",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify exact origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/", tags=["Root"])
async def root():
    """
    Root endpoint - API health check
    """
    return {
        "message": "AI Smart Ride Matching API",
        "version": "1.0.0",
        "status": "running",
        "docs": "/docs",
    }


@app.get("/health", tags=["Health"])
async def health_check():
    """
    Health check endpoint for monitoring
    """
    return {
        "status": "healthy",
        "ml_enabled": settings.ENABLE_ML_MATCHING,
    }


# Include API routers
app.include_router(
    match.router,
    prefix=f"{settings.API_V1_PREFIX}",
    tags=["Matching"]
)

app.include_router(
    preferences.router,
    prefix=f"{settings.API_V1_PREFIX}",
    tags=["Preferences"]
)

app.include_router(
    analytics.router,
    prefix=f"{settings.API_V1_PREFIX}",
    tags=["Analytics"]
)

app.include_router(
    agora.router,
    prefix=f"{settings.API_V1_PREFIX}",
    tags=["Agora"]
)

app.include_router(
    notifications.router,
    prefix=f"{settings.API_V1_PREFIX}",
    tags=["Notifications"]
)

app.include_router(
    ratings.router,
    prefix=f"{settings.API_V1_PREFIX}",
    tags=["Ratings"]
)


# Global exception handler
@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    """
    Global exception handler for unhandled errors
    """
    return JSONResponse(
        status_code=500,
        content={
            "error": "Internal server error",
            "detail": str(exc) if settings.DEBUG else "An error occurred"
        }
    )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.DEBUG
    )
