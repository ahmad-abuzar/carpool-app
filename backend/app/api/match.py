"""
Match API endpoints
"""
from fastapi import APIRouter, HTTPException, status
from typing import List
from app.models.match import (
    MatchRequest,
    BatchMatchRequest,
    MatchResponse,
    BatchMatchResponse,
    UserProfile,
)
from app.services.firebase_service import firebase_service
from app.services.matching_service import matching_service

router = APIRouter()


@router.post("/match", response_model=MatchResponse, status_code=status.HTTP_200_OK)
async def calculate_match(request: MatchRequest):
    """
    Calculate compatibility score between user and candidate
    
    **Request Body:**
    ```json
    {
        "user_id": "user123",
        "candidate_id": "driver456",
        "use_ml": false
    }
    ```
    
    **Response:**
    ```json
    {
        "user_id": "user123",
        "candidate_id": "driver456",
        "compatibility_score": 85.5,
        "compatibility_level": "high",
        "reasons": [
            "🏢 Same office/company",
            "🎵 Same music preference",
            "⏰ Both highly punctual (90%+)"
        ],
        "breakdown": {
            "office_match": 100.0,
            "music_preference": 100.0,
            "talk_preference": 50.0,
            "punctuality": 95.0,
            "gender_preference": 100.0,
            "time_match": 100.0
        },
        "recommendation": "Highly compatible match! You share 3 key preferences..."
    }
    ```
    """
    try:
        # Fetch user profiles
        user_data = await firebase_service.get_user_profile(request.user_id)
        candidate_data = await firebase_service.get_user_profile(request.candidate_id)
        
        if not user_data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"User {request.user_id} not found"
            )
        
        if not candidate_data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Candidate {request.candidate_id} not found"
            )
        
        # Check if smart matching is enabled for user
        if not user_data.get('preferences', {}).get('smart_matching_enabled', True):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Smart matching is disabled for this user"
            )
        
        # Convert to UserProfile models
        user = UserProfile(**user_data)
        candidate = UserProfile(**candidate_data)
        
        # Calculate compatibility
        result = matching_service.calculate_compatibility(user, candidate)
        
        # Save match result for analytics
        await firebase_service.save_match_result(
            user_id=request.user_id,
            candidate_id=request.candidate_id,
            compatibility_score=result['compatibility_score'],
            reasons=result['reasons']
        )
        
        return MatchResponse(
            user_id=request.user_id,
            candidate_id=request.candidate_id,
            **result
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error calculating match: {str(e)}"
        )


@router.post("/match/batch", response_model=BatchMatchResponse)
async def batch_match(request: BatchMatchRequest):
    """
    Calculate compatibility for multiple candidates
    
    Returns sorted list by compatibility score (highest first)
    
    **Request Body:**
    ```json
    {
        "user_id": "user123",
        "candidate_ids": ["driver1", "driver2", "driver3"],
        "use_ml": false
    }
    ```
    
    **Response:**
    ```json
    {
        "user_id": "user123",
        "total_candidates": 3,
        "matches": [
            {
                "candidate_id": "driver2",
                "compatibility_score": 92.5,
                "compatibility_level": "high",
                "reasons": [...],
                ...
            },
            {
                "candidate_id": "driver1",
                "compatibility_score": 78.0,
                "compatibility_level": "medium",
                ...
            },
            ...
        ]
    }
    ```
    """
    try:
        # Fetch user profile
        user_data = await firebase_service.get_user_profile(request.user_id)
        
        if not user_data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"User {request.user_id} not found"
            )
        
        user = UserProfile(**user_data)
        matches = []
        
        # Calculate compatibility for each candidate
        for candidate_id in request.candidate_ids:
            try:
                candidate_data = await firebase_service.get_user_profile(candidate_id)
                
                if not candidate_data:
                    continue  # Skip if candidate not found
                
                candidate = UserProfile(**candidate_data)
                result = matching_service.calculate_compatibility(user, candidate)
                
                matches.append(
                    MatchResponse(
                        user_id=request.user_id,
                        candidate_id=candidate_id,
                        **result
                    )
                )
                
            except Exception as e:
                # Log error but continue with other candidates
                print(f"Error matching with {candidate_id}: {str(e)}")
                continue
        
        # Sort by compatibility score (descending)
        matches.sort(key=lambda x: x.compatibility_score, reverse=True)
        
        return BatchMatchResponse(
            user_id=request.user_id,
            matches=matches,
            total_candidates=len(matches)
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error in batch matching: {str(e)}"
        )


@router.get("/match/history/{user_id}")
async def get_match_history(user_id: str, limit: int = 20):
    """
    Get user's match history
    
    **Parameters:**
    - user_id: User ID
    - limit: Maximum number of records (default: 20, max: 100)
    
    **Response:**
    ```json
    {
        "user_id": "user123",
        "total_matches": 15,
        "matches": [
            {
                "candidate_id": "driver1",
                "compatibility_score": 85.5,
                "timestamp": "2024-01-15T10:30:00Z",
                "reasons": [...]
            },
            ...
        ]
    }
    ```
    """
    try:
        if limit > 100:
            limit = 100
        
        # Fetch match history from Firebase
        db = firebase_service.db
        query = db.collection('match_history').where(
            'userId', '==', user_id
        ).order_by('timestamp', direction='DESCENDING').limit(limit)
        
        docs = query.stream()
        matches = []
        
        for doc in docs:
            data = doc.to_dict()
            ts = data.get('timestamp')
            timestamp_str = ''
            if ts:
                if hasattr(ts, 'isoformat'):
                    timestamp_str = ts.isoformat()
                elif hasattr(ts, 'timestamp'):
                    from datetime import datetime
                    timestamp_str = datetime.fromtimestamp(ts.timestamp()).isoformat()
            
            matches.append({
                'candidate_id': data.get('candidateId', ''),
                'compatibility_score': data.get('compatibilityScore', 0.0),
                'reasons': data.get('reasons', []),
                'timestamp': timestamp_str,
            })
        
        return {
            "user_id": user_id,
            "total_matches": len(matches),
            "matches": matches
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error fetching match history: {str(e)}"
        )
