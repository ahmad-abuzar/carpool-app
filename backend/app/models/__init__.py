"""
Models package initialization
"""
from app.models.match import (
    MusicPreference,
    TalkPreference,
    GenderPreference,
    RideFrequency,
    OfficeInfo,
    UserPreferences,
    BehavioralScores,
    UserProfile,
    MatchRequest,
    BatchMatchRequest,
    MatchResponse,
    BatchMatchResponse,
    CompatibilityLevel,
)

__all__ = [
    "MusicPreference",
    "TalkPreference",
    "GenderPreference",
    "RideFrequency",
    "OfficeInfo",
    "UserPreferences",
    "BehavioralScores",
    "UserProfile",
    "MatchRequest",
    "BatchMatchRequest",
    "MatchResponse",
    "BatchMatchResponse",
    "CompatibilityLevel",
]
