"""
Medical Study App - FastAPI Main Application
"""
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.database import init_db
from app.routers import auth, documents, questions, exams, courses, groups, slides


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan events."""
    # Startup
    await init_db()
    yield
    # Shutdown
    pass


app = FastAPI(
    title="Medical Study App API",
    description="""
    Backend API for the Medical Study mobile application.
    
    Features:
    - User authentication with term/group selection
    - Document upload and AI-powered question generation
    - Smart semantic hints
    - 7-Day Logic exam preparation algorithm
    """,
    version="1.0.0",
    lifespan=lifespan
)

# CORS middleware for mobile app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth.router, prefix="/api/v1")
app.include_router(courses.router, prefix="/api/v1")
app.include_router(documents.router, prefix="/api/v1")
app.include_router(questions.router, prefix="/api/v1")
app.include_router(exams.router, prefix="/api/v1")
app.include_router(groups.router, prefix="/api/v1")
app.include_router(slides.router, prefix="/api/v1")


@app.get("/")
async def root():
    """Root endpoint."""
    return {
        "message": "Medical Study App API",
        "docs": "/docs",
        "version": "1.0.0"
    }


@app.api_route("/health", methods=["GET", "HEAD"])
async def health_check():
    """Health check endpoint for Render."""
    return {"status": "healthy"}
