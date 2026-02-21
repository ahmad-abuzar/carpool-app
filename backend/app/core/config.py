"""
Core configuration for the AI Smart Matching API
"""
from pydantic_settings import BaseSettings
from typing import Optional


class Settings(BaseSettings):
    # API Configuration
    PROJECT_NAME: str = "AI Smart Ride Matching API"
    API_V1_PREFIX: str = "/api/v1"
    DEBUG: bool = True
    
    # Firebase Configuration
    FIREBASE_CREDENTIALS_PATH: str = "firebase-credentials.json"
    
    # ML Configuration
    ML_MODEL_PATH: str = "ml/models/compatibility_model.pkl"
    ENABLE_ML_MATCHING: bool = False
    
    # Matching Weights (must sum to 1.0)
    WEIGHT_OFFICE_MATCH: float = 0.25
    WEIGHT_MUSIC_PREFERENCE: float = 0.15
    WEIGHT_TALK_PREFERENCE: float = 0.15
    WEIGHT_PUNCTUALITY: float = 0.20
    WEIGHT_GENDER_PREFERENCE: float = 0.10
    WEIGHT_TIME_MATCH: float = 0.15
    
    # Scoring Thresholds
    HIGH_COMPATIBILITY_THRESHOLD: float = 80.0
    MEDIUM_COMPATIBILITY_THRESHOLD: float = 60.0
    
    class Config:
        env_file = ".env"
        case_sensitive = True


# Global settings instance
settings = Settings()


# Validate weights sum to 1.0
def validate_weights():
    total = (
        settings.WEIGHT_OFFICE_MATCH +
        settings.WEIGHT_MUSIC_PREFERENCE +
        settings.WEIGHT_TALK_PREFERENCE +
        settings.WEIGHT_PUNCTUALITY +
        settings.WEIGHT_GENDER_PREFERENCE +
        settings.WEIGHT_TIME_MATCH
    )
    
    if abs(total - 1.0) > 0.01:
        raise ValueError(f"Weights must sum to 1.0, got {total}")


validate_weights()
