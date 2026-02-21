"""
Ratings API endpoints
Handles rating submission, retrieval, and aggregation
"""
from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from app.services.firebase_service import firebase_service

router = APIRouter()


class RatingRequest(BaseModel):
    """Request to submit a rating"""
    rated_user_id: str = Field(..., description="User being rated")
    rater_user_id: str = Field(..., description="User submitting the rating")
    stars: int = Field(..., ge=1, le=5, description="Star rating 1-5")
    tags: List[str] = Field(default_factory=list, description="Rating tags")
    comment: Optional[str] = Field(default=None, description="Optional comment")
    ride_id: str = Field(..., description="Related ride ID")


class RatingResponse(BaseModel):
    """Rating details"""
    id: str
    rated_user_id: str
    rater_user_id: str
    stars: int
    tags: List[str]
    comment: Optional[str]
    ride_id: str
    timestamp: str


@router.post("/ratings", status_code=status.HTTP_201_CREATED)
async def submit_rating(request: RatingRequest):
    """
    Submit a rating for a user after a ride

    Also updates the rated user's average rating atomically.

    **Request Body:**
    ```json
    {
        "rated_user_id": "driver456",
        "rater_user_id": "user123",
        "stars": 5,
        "tags": ["Safe driving", "On time", "Friendly"],
        "comment": "Great ride, very professional!",
        "ride_id": "ride789"
    }
    ```
    """
    try:
        db = firebase_service.db

        # Check for duplicate ratings
        existing = db.collection('ratings').where(
            'raterUserId', '==', request.rater_user_id
        ).where(
            'ratedUserId', '==', request.rated_user_id
        ).where(
            'rideId', '==', request.ride_id
        ).limit(1).stream()

        if any(True for _ in existing):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="You have already rated this user for this ride"
            )

        # Create rating document
        rating_data = {
            'ratedUserId': request.rated_user_id,
            'raterUserId': request.rater_user_id,
            'stars': request.stars,
            'tags': request.tags,
            'comment': request.comment,
            'rideId': request.ride_id,
            'timestamp': datetime.utcnow(),
        }

        # Add rating
        _, doc_ref = db.collection('ratings').add(rating_data)
        rating_id = doc_ref.id

        # Update the rated user's average rating
        user_ref = db.collection('users').document(request.rated_user_id)
        user_doc = user_ref.get()

        if user_doc.exists:
            user_data = user_doc.to_dict()
            current_rating = float(user_data.get('rating', 0.0))
            total_ratings = int(user_data.get('totalRatings', 0))

            new_total = total_ratings + 1
            new_average = ((current_rating * total_ratings) + request.stars) / new_total

            user_ref.update({
                'rating': round(new_average, 2),
                'totalRatings': new_total,
            })

        return {
            "success": True,
            "rating_id": rating_id,
            "message": "Rating submitted successfully",
            "new_average": round(new_average, 2) if user_doc.exists else None,
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error submitting rating: {str(e)}"
        )


@router.get("/ratings/user/{user_id}")
async def get_user_ratings(user_id: str, limit: int = 50):
    """
    Get all ratings received by a user

    Returns ratings sorted by most recent first.
    """
    try:
        db = firebase_service.db
        query = db.collection('ratings').where(
            'ratedUserId', '==', user_id
        ).order_by('timestamp', direction='DESCENDING').limit(limit)

        docs = query.stream()
        ratings = []

        for doc in docs:
            data = doc.to_dict()
            ts = data.get('timestamp')
            timestamp_str = ''
            if ts:
                if hasattr(ts, 'isoformat'):
                    timestamp_str = ts.isoformat()
                elif hasattr(ts, 'timestamp'):
                    timestamp_str = datetime.fromtimestamp(ts.timestamp()).isoformat()

            ratings.append({
                'id': doc.id,
                'rated_user_id': data.get('ratedUserId', ''),
                'rater_user_id': data.get('raterUserId', ''),
                'stars': data.get('stars', 0),
                'tags': data.get('tags', []),
                'comment': data.get('comment'),
                'ride_id': data.get('rideId', ''),
                'timestamp': timestamp_str,
            })

        # Calculate statistics
        if ratings:
            total_stars = sum(r['stars'] for r in ratings)
            average = total_stars / len(ratings)
            distribution = {str(i): sum(1 for r in ratings if r['stars'] == i) for i in range(1, 6)}
        else:
            average = 0.0
            distribution = {str(i): 0 for i in range(1, 6)}

        return {
            "user_id": user_id,
            "total_ratings": len(ratings),
            "average_rating": round(average, 2),
            "distribution": distribution,
            "ratings": ratings,
        }

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error fetching user ratings: {str(e)}"
        )


@router.get("/ratings/ride/{ride_id}")
async def get_ride_ratings(ride_id: str):
    """
    Get all ratings for a specific ride
    """
    try:
        db = firebase_service.db
        query = db.collection('ratings').where(
            'rideId', '==', ride_id
        ).order_by('timestamp', direction='DESCENDING')

        docs = query.stream()
        ratings = []

        for doc in docs:
            data = doc.to_dict()
            ts = data.get('timestamp')
            timestamp_str = ''
            if ts:
                if hasattr(ts, 'isoformat'):
                    timestamp_str = ts.isoformat()
                elif hasattr(ts, 'timestamp'):
                    timestamp_str = datetime.fromtimestamp(ts.timestamp()).isoformat()

            ratings.append({
                'id': doc.id,
                'rated_user_id': data.get('ratedUserId', ''),
                'rater_user_id': data.get('raterUserId', ''),
                'stars': data.get('stars', 0),
                'tags': data.get('tags', []),
                'comment': data.get('comment'),
                'ride_id': data.get('rideId', ''),
                'timestamp': timestamp_str,
            })

        return {
            "ride_id": ride_id,
            "total_ratings": len(ratings),
            "ratings": ratings,
        }

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error fetching ride ratings: {str(e)}"
        )
