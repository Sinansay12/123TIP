"""
Application Configuration using Pydantic Settings.
Loads environment variables from .env file.
"""
from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    # Database - Using SQLite for easy local development (no PostgreSQL required)
    database_url: str = "sqlite+aiosqlite:///./medical_app.db"
    # PostgreSQL option: database_url: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/medical_study_db"
    
    # Google Gemini AI (Free Tier)
    gemini_api_key: str = ""
    
    # JWT Auth
    jwt_secret_key: str = "your-super-secret-jwt-key"
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    
    # File Upload
    upload_dir: str = "./uploads"
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


@lru_cache()
def get_settings() -> Settings:
    """Cached settings instance."""
    return Settings()
