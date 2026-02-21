"""
Unit tests for matching service
"""
import pytest
from app.services.matching_service import MatchingService
from app.models.match import (
    UserProfile,
    UserPreferences,
    BehavioralScores,
    OfficeInfo,
    LocationModel,
    MusicPreference,
    TalkPreference,
    GenderPreference,
    RideFrequency,
)


@pytest.fixture
def matching_service():
    """Create matching service instance"""
    return MatchingService()


@pytest.fixture
def sample_user():
    """Create sample user profile"""
    return UserProfile(
        user_id="user1",
        name="John Doe",
        gender="male",
        preferences=UserPreferences(
            office=OfficeInfo(
                name="Google India",
                location=LocationModel(latitude=28.5355, longitude=77.3910),
                start_time="09:00",
                end_time="18:00"
            ),
            music_preference=MusicPreference.SOFT,
            talk_preference=TalkPreference.NORMAL,
            gender_preference=GenderPreference.ANY,
            ride_frequency=RideFrequency.DAILY,
            company_email="john@google.com",
            email_verified=True
        ),
        behavioral_scores=BehavioralScores(
            punctuality_score=95.0,
            completion_rate=98.0,
            average_rating=4.8
        ),
        smart_matching_enabled=True
    )


@pytest.fixture
def sample_candidate():
    """Create sample candidate profile"""
    return UserProfile(
        user_id="candidate1",
        name="Jane Smith",
        gender="female",
        preferences=UserPreferences(
            office=OfficeInfo(
                name="Google India",
                location=LocationModel(latitude=28.5355, longitude=77.3910),
                start_time="09:15",
                end_time="18:15"
            ),
            music_preference=MusicPreference.SOFT,
            talk_preference=TalkPreference.NORMAL,
            gender_preference=GenderPreference.ANY,
            ride_frequency=RideFrequency.DAILY,
            company_email="jane@google.com",
            email_verified=True
        ),
        behavioral_scores=BehavioralScores(
            punctuality_score=92.0,
            completion_rate=96.0,
            average_rating=4.7
        ),
        smart_matching_enabled=True
    )


def test_same_office_match(matching_service, sample_user, sample_candidate):
    """Test that same office gives high score"""
    result = matching_service.calculate_compatibility(sample_user, sample_candidate)
    
    assert result['compatibility_score'] >= 80.0
    assert "🏢 Same office/company" in result['reasons']
    assert result['breakdown']['office_match'] == 100.0


def test_music_preference_match(matching_service, sample_user, sample_candidate):
    """Test music preference matching"""
    result = matching_service.calculate_compatibility(sample_user, sample_candidate)
    
    assert "🎵 Same music preference" in result['reasons']
    assert result['breakdown']['music_preference'] == 100.0


def test_talk_preference_match(matching_service, sample_user, sample_candidate):
    """Test talk preference matching"""
    result = matching_service.calculate_compatibility(sample_user, sample_candidate)
    
    assert "💬 Similar conversation style" in result['reasons']
    assert result['breakdown']['talk_preference'] == 100.0


def test_punctuality_score(matching_service, sample_user, sample_candidate):
    """Test punctuality score calculation"""
    result = matching_service.calculate_compatibility(sample_user, sample_candidate)
    
    expected_score = (95.0 + 92.0) / 2
    assert result['breakdown']['punctuality'] == expected_score
    assert "⏰ Both highly punctual" in result['reasons']


def test_time_match(matching_service, sample_user, sample_candidate):
    """Test time matching (15 min difference)"""
    result = matching_service.calculate_compatibility(sample_user, sample_candidate)
    
    assert result['breakdown']['time_match'] == 100.0
    assert "🕐 Perfect time match" in result['reasons']


def test_different_music_preference(matching_service, sample_user, sample_candidate):
    """Test different music preferences"""
    sample_candidate.preferences.music_preference = MusicPreference.LOUD
    
    result = matching_service.calculate_compatibility(sample_user, sample_candidate)
    
    # Difference of 1 level = 50 point penalty
    assert result['breakdown']['music_preference'] == 50.0


def test_gender_preference_any(matching_service, sample_user, sample_candidate):
    """Test gender preference set to ANY"""
    result = matching_service.calculate_compatibility(sample_user, sample_candidate)
    
    assert result['breakdown']['gender_preference'] == 100.0


def test_compatibility_level_high(matching_service, sample_user, sample_candidate):
    """Test high compatibility level"""
    result = matching_service.calculate_compatibility(sample_user, sample_candidate)
    
    assert result['compatibility_level'] == "high"
    assert result['compatibility_score'] >= 80.0


def test_compatibility_level_low(matching_service, sample_user, sample_candidate):
    """Test low compatibility level"""
    # Make candidates very different
    sample_candidate.preferences.office.name = "Different Company"
    sample_candidate.preferences.music_preference = MusicPreference.LOUD
    sample_candidate.preferences.talk_preference = TalkPreference.QUIET
    sample_candidate.preferences.office.start_time = "14:00"
    sample_candidate.behavioral_scores.punctuality_score = 40.0
    
    result = matching_service.calculate_compatibility(sample_user, sample_candidate)
    
    assert result['compatibility_level'] == "low"
    assert result['compatibility_score'] < 60.0


def test_recommendation_generation(matching_service, sample_user, sample_candidate):
    """Test recommendation text generation"""
    result = matching_service.calculate_compatibility(sample_user, sample_candidate)
    
    assert 'recommendation' in result
    assert len(result['recommendation']) > 0
    assert isinstance(result['recommendation'], str)
