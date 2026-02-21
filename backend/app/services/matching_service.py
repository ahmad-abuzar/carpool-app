"""
AI Smart Matching Service - Rule-based compatibility scoring
"""
from datetime import datetime
from typing import Dict, List, Tuple
from app.models.match import (
    UserProfile,
    MusicPreference,
    TalkPreference,
    GenderPreference,
    CompatibilityLevel,
)
from app.core.config import settings


class MatchingService:
    """Service for calculating ride compatibility scores"""
    
    # Preference value mappings
    MUSIC_MAP = {
        MusicPreference.NONE: 0,
        MusicPreference.SOFT: 1,
        MusicPreference.LOUD: 2,
    }
    
    TALK_MAP = {
        TalkPreference.QUIET: 0,
        TalkPreference.NORMAL: 1,
        TalkPreference.TALKATIVE: 2,
    }
    
    def __init__(self):
        """Initialize matching service with weights from config"""
        self.weights = {
            'office_match': settings.WEIGHT_OFFICE_MATCH,
            'music_preference': settings.WEIGHT_MUSIC_PREFERENCE,
            'talk_preference': settings.WEIGHT_TALK_PREFERENCE,
            'punctuality': settings.WEIGHT_PUNCTUALITY,
            'gender_preference': settings.WEIGHT_GENDER_PREFERENCE,
            'time_match': settings.WEIGHT_TIME_MATCH,
        }
    
    def calculate_compatibility(
        self,
        user: UserProfile,
        candidate: UserProfile
    ) -> Dict:
        """
        Calculate compatibility score between user and candidate
        
        Args:
            user: User seeking a ride
            candidate: Potential match (driver or co-passenger)
            
        Returns:
            Dict with score, reasons, and breakdown
        """
        scores = {}
        reasons = []
        
        # 1. Office/Company Match
        office_score, office_reason = self._calculate_office_match(user, candidate)
        scores['office_match'] = office_score
        if office_reason:
            reasons.append(office_reason)
        
        # 2. Music Preference Match
        music_score, music_reason = self._calculate_music_match(user, candidate)
        scores['music_preference'] = music_score
        if music_reason:
            reasons.append(music_reason)
        
        # 3. Talk Preference Match
        talk_score, talk_reason = self._calculate_talk_match(user, candidate)
        scores['talk_preference'] = talk_score
        if talk_reason:
            reasons.append(talk_reason)
        
        # 4. Punctuality Score
        punctuality_score, punctuality_reason = self._calculate_punctuality_match(
            user, candidate
        )
        scores['punctuality'] = punctuality_score
        if punctuality_reason:
            reasons.append(punctuality_reason)
        
        # 5. Gender Preference Match
        gender_score, gender_reason = self._calculate_gender_match(user, candidate)
        scores['gender_preference'] = gender_score
        if gender_reason:
            reasons.append(gender_reason)
        
        # 6. Time Match
        time_score, time_reason = self._calculate_time_match(user, candidate)
        scores['time_match'] = time_score
        if time_reason:
            reasons.append(time_reason)
        
        # Calculate weighted final score
        final_score = sum(
            scores[key] * self.weights[key] 
            for key in self.weights.keys()
        )
        
        # Determine compatibility level
        compatibility_level = self._get_compatibility_level(final_score)
        
        # Generate recommendation
        recommendation = self._generate_recommendation(
            final_score, 
            compatibility_level,
            reasons
        )
        
        return {
            'compatibility_score': round(final_score, 1),
            'compatibility_level': compatibility_level,
            'reasons': reasons,
            'breakdown': scores,
            'recommendation': recommendation,
        }
    
    def _calculate_office_match(
        self,
        user: UserProfile,
        candidate: UserProfile
    ) -> Tuple[float, str]:
        """Calculate office/company match score"""
        user_office = user.preferences.office.name.lower()
        candidate_office = candidate.preferences.office.name.lower()
        
        # Exact office match
        if user_office == candidate_office:
            return 100.0, "🏢 Same office/company"
        
        # Company email domain match
        user_email = user.preferences.company_email
        candidate_email = candidate.preferences.company_email
        
        if user_email and candidate_email:
            user_domain = user_email.split('@')[-1]
            candidate_domain = candidate_email.split('@')[-1]
            
            if user_domain == candidate_domain:
                return 80.0, "🏢 Same company domain"
        
        return 0.0, ""
    
    def _calculate_music_match(
        self,
        user: UserProfile,
        candidate: UserProfile
    ) -> Tuple[float, str]:
        """Calculate music preference match score"""
        user_pref = user.preferences.music_preference
        candidate_pref = candidate.preferences.music_preference
        
        diff = abs(self.MUSIC_MAP[user_pref] - self.MUSIC_MAP[candidate_pref])
        score = 100.0 - (diff * 50.0)
        
        reason = ""
        if diff == 0:
            reason = "🎵 Same music preference"
        elif diff == 1:
            reason = "🎵 Similar music taste"
        
        return score, reason
    
    def _calculate_talk_match(
        self,
        user: UserProfile,
        candidate: UserProfile
    ) -> Tuple[float, str]:
        """Calculate conversation preference match score"""
        user_pref = user.preferences.talk_preference
        candidate_pref = candidate.preferences.talk_preference
        
        diff = abs(self.TALK_MAP[user_pref] - self.TALK_MAP[candidate_pref])
        score = 100.0 - (diff * 50.0)
        
        reason = ""
        if diff == 0:
            reason = "💬 Similar conversation style"
        elif diff == 1:
            reason = "💬 Compatible conversation level"
        
        return score, reason
    
    def _calculate_punctuality_match(
        self,
        user: UserProfile,
        candidate: UserProfile
    ) -> Tuple[float, str]:
        """Calculate punctuality compatibility score"""
        user_score = user.behavioral_scores.punctuality_score
        candidate_score = candidate.behavioral_scores.punctuality_score
        
        avg_score = (user_score + candidate_score) / 2
        
        reason = ""
        if avg_score >= 90:
            reason = "⏰ Both highly punctual (90%+)"
        elif avg_score >= 80:
            reason = "⏰ Good punctuality record"
        
        return avg_score, reason
    
    def _calculate_gender_match(
        self,
        user: UserProfile,
        candidate: UserProfile
    ) -> Tuple[float, str]:
        """Calculate gender preference match score"""
        user_pref = user.preferences.gender_preference
        user_gender = user.gender.lower()
        candidate_gender = candidate.gender.lower()
        
        # User has no preference
        if user_pref == GenderPreference.ANY:
            return 100.0, ""
        
        # User wants same gender
        if user_pref == GenderPreference.SAME:
            if user_gender == candidate_gender:
                return 100.0, "👥 Gender preference matched"
            return 0.0, ""
        
        # User wants specific gender
        if user_pref.value == candidate_gender:
            return 100.0, "👥 Gender preference matched"
        
        return 0.0, ""
    
    def _calculate_time_match(
        self,
        user: UserProfile,
        candidate: UserProfile
    ) -> Tuple[float, str]:
        """Calculate office start time match score"""
        user_time_str = user.preferences.office.start_time
        candidate_time_str = candidate.preferences.office.start_time
        
        # Parse times
        user_time = datetime.strptime(user_time_str, "%H:%M")
        candidate_time = datetime.strptime(candidate_time_str, "%H:%M")
        
        # Calculate difference in minutes
        diff_minutes = abs((user_time - candidate_time).total_seconds() / 60)
        
        # Score based on time difference
        if diff_minutes <= 15:
            return 100.0, "🕐 Perfect time match (±15 min)"
        elif diff_minutes <= 30:
            return 75.0, "🕐 Good time match (±30 min)"
        elif diff_minutes <= 60:
            return 50.0, ""
        else:
            return 25.0, ""
    
    def _get_compatibility_level(self, score: float) -> CompatibilityLevel:
        """Determine compatibility level from score"""
        if score >= settings.HIGH_COMPATIBILITY_THRESHOLD:
            return CompatibilityLevel.HIGH
        elif score >= settings.MEDIUM_COMPATIBILITY_THRESHOLD:
            return CompatibilityLevel.MEDIUM
        else:
            return CompatibilityLevel.LOW
    
    def _generate_recommendation(
        self,
        score: float,
        level: CompatibilityLevel,
        reasons: List[str]
    ) -> str:
        """Generate human-readable recommendation"""
        if level == CompatibilityLevel.HIGH:
            return (
                f"Highly compatible match! "
                f"You share {len(reasons)} key preferences. "
                f"This ride is likely to be comfortable and enjoyable."
            )
        elif level == CompatibilityLevel.MEDIUM:
            return (
                f"Moderately compatible. "
                f"You have some common preferences. "
                f"This could be a good ride option."
            )
        else:
            return (
                f"Lower compatibility. "
                f"Consider if you're comfortable with different preferences."
            )


# Global instance
matching_service = MatchingService()
