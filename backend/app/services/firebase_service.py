"""
Firebase service for database operations
"""
import firebase_admin
from firebase_admin import credentials, firestore
from typing import Optional, Dict, Any
from app.core.config import settings
import os


class FirebaseService:
    """Service for Firebase Firestore operations"""
    
    _instance = None
    _db = None
    
    def __new__(cls):
        """Singleton pattern for Firebase connection"""
        if cls._instance is None:
            cls._instance = super(FirebaseService, cls).__new__(cls)
            cls._instance._initialize_firebase()
        return cls._instance
    
    def _initialize_firebase(self):
        """Initialize Firebase Admin SDK"""
        try:
            # Check if already initialized
            firebase_admin.get_app()
        except ValueError:
            # Initialize for the first time
            cred_path = settings.FIREBASE_CREDENTIALS_PATH
            
            if not os.path.exists(cred_path):
                raise FileNotFoundError(
                    f"Firebase credentials not found at {cred_path}. "
                    "Please add your firebase-credentials.json file."
                )
            
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
        
        self._db = firestore.client()
    
    @property
    def db(self):
        """Get Firestore database instance"""
        return self._db
    
    async def get_user_preferences(self, user_id: str) -> Optional[Dict[str, Any]]:
        """
        Get user preferences from Firestore
        
        Args:
            user_id: User ID
            
        Returns:
            User preferences dict or None if not found
        """
        doc_ref = self._db.collection('user_preferences').document(user_id)
        doc = doc_ref.get()
        
        if doc.exists:
            return doc.to_dict()
        return None
    
    async def save_user_preferences(
        self, 
        user_id: str, 
        preferences: Dict[str, Any]
    ) -> bool:
        """
        Save user preferences to Firestore
        
        Args:
            user_id: User ID
            preferences: Preferences data
            
        Returns:
            True if successful
        """
        doc_ref = self._db.collection('user_preferences').document(user_id)
        doc_ref.set(preferences, merge=True)
        return True
    
    async def get_user_profile(self, user_id: str) -> Optional[Dict[str, Any]]:
        """
        Get complete user profile including preferences and behavioral scores
        
        Args:
            user_id: User ID
            
        Returns:
            User profile dict or None
        """
        # Get from users collection
        user_doc = self._db.collection('users').document(user_id).get()
        
        if not user_doc.exists:
            return None
        
        user_data = user_doc.to_dict()
        
        # Get preferences
        prefs = await self.get_user_preferences(user_id)
        if prefs:
            user_data['preferences'] = prefs.get('preferences', {})
            user_data['behavioral_scores'] = prefs.get('behavioralScores', {
                'punctualityScore': 100.0,
                'completionRate': 100.0,
                'averageRating': 5.0
            })
        
        return user_data
    
    async def get_ride_history(
        self, 
        user_id: str, 
        limit: int = 100
    ) -> list:
        """
        Get user's ride history
        
        Args:
            user_id: User ID
            limit: Maximum number of rides to fetch
            
        Returns:
            List of ride documents
        """
        rides_ref = self._db.collection('ride_history')
        query = rides_ref.where('userId', '==', user_id).limit(limit)
        
        docs = query.stream()
        return [doc.to_dict() for doc in docs]
    
    async def save_match_result(
        self,
        user_id: str,
        candidate_id: str,
        compatibility_score: float,
        reasons: list
    ) -> bool:
        """
        Save match result for analytics
        
        Args:
            user_id: User ID
            candidate_id: Candidate ID
            compatibility_score: Calculated score
            reasons: List of reasons
            
        Returns:
            True if successful
        """
        from datetime import datetime
        
        match_data = {
            'userId': user_id,
            'candidateId': candidate_id,
            'compatibilityScore': compatibility_score,
            'reasons': reasons,
            'timestamp': datetime.utcnow(),
        }
        
        self._db.collection('match_history').add(match_data)
        return True


# Global instance
firebase_service = FirebaseService()
