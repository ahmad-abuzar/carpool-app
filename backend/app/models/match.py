"""
Pydantic models for API requests and responses
"""
from pydantic import BaseModel, Field, validator
from typing import Optional, List, Dict
from enum import Enum
from datetime import time


class MusicPreference(str, Enum):
    """Music preference during ride"""
    NONE = "none"
    SOFT = "soft"
    LOUD = "loud"


class TalkPreference(str, Enum):
    """Conversation preference during ride"""
    QUIET = "quiet"
    NORMAL = "normal"
    TALKATIVE = "talkative"


class GenderPreference(str, Enum):
    """Gender preference for ride companions"""
    ANY = "any"
    MALE = "male"
    FEMALE = "female"
    SAME = "same"


class RideFrequency(str, Enum):
    """How often user takes rides"""
    DAILY = "daily"
    WEEKLY = "weekly"
    OCCASIONAL = "occasional"


class LocationModel(BaseModel):
    """Geographic location"""
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    address: Optional[str] = None


class OfficeInfo(BaseModel):
    """Office/workplace information"""
    name: str = Field(..., min_length=1, max_length=200)
    location: LocationModel
    start_time: str = Field(..., pattern=r"^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$")
    end_time: str = Field(..., pattern=r"^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$")
    
    @validator('end_time')
    def validate_end_time(cls, v, values):
        """Ensure end time is after start time"""
        if 'start_time' in values and v <= values['start_time']:
            raise ValueError('end_time must be after start_time')
        return v


class UserPreferences(BaseModel):
    """User behavioral preferences for matching"""
    office: OfficeInfo
    music_preference: MusicPreference
    talk_preference: TalkPreference
    gender_preference: GenderPreference
    ride_frequency: RideFrequency
    company_email: Optional[str] = None
    email_verified: bool = False


class BehavioralScores(BaseModel):
    """Auto-calculated behavioral scores"""
    punctuality_score: float = Field(default=100.0, ge=0, le=100)
    completion_rate: float = Field(default=100.0, ge=0, le=100)
    average_rating: float = Field(default=5.0, ge=0, le=5)


class UserProfile(BaseModel):
    """Complete user profile for matching"""
    user_id: str
    name: str
    gender: str
    preferences: UserPreferences
    behavioral_scores: BehavioralScores
    smart_matching_enabled: bool = True


class MatchRequest(BaseModel):
    """Request to calculate compatibility between two users"""
    user_id: str = Field(..., description="ID of the user seeking a ride")
    candidate_id: str = Field(..., description="ID of the potential match")
    use_ml: bool = Field(default=False, description="Use ML model for prediction")


class BatchMatchRequest(BaseModel):
    """Request to calculate compatibility for multiple candidates"""
    user_id: str
    candidate_ids: List[str] = Field(..., min_items=1, max_items=50)
    use_ml: bool = False


class CompatibilityLevel(str, Enum):
    """Compatibility level categories"""
    HIGH = "high"
    MEDIUM = "medium"
    LOW = "low"


class MatchResponse(BaseModel):
    """Response with compatibility score and details"""
    user_id: str
    candidate_id: str
    compatibility_score: float = Field(..., ge=0, le=100)
    compatibility_level: CompatibilityLevel
    reasons: List[str] = Field(default_factory=list)
    breakdown: Dict[str, float] = Field(default_factory=dict)
    recommendation: str


class BatchMatchResponse(BaseModel):
    """Response with multiple match results"""
    user_id: str
    matches: List[MatchResponse]
    total_candidates: int


class PreferencesUpdateRequest(BaseModel):
    """Request to update user preferences"""
    user_id: str
    preferences: UserPreferences
