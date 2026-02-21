"""
Preferences API endpoints
"""
from fastapi import APIRouter, HTTPException, status
from app.models.match import PreferencesUpdateRequest, UserPreferences
from app.services.firebase_service import firebase_service

router = APIRouter()


@router.post("/preferences", status_code=status.HTTP_201_CREATED)
async def save_preferences(request: PreferencesUpdateRequest):
    """
    Save or update user preferences
    
    **Request Body:**
    ```json
    {
        "user_id": "user123",
        "preferences": {
            "office": {
                "name": "Google India",
                "location": {
                    "latitude": 28.5355,
                    "longitude": 77.3910
                },
                "start_time": "09:00",
                "end_time": "18:00"
            },
            "music_preference": "soft",
            "talk_preference": "normal",
            "gender_preference": "any",
            "ride_frequency": "daily",
            "company_email": "user@google.com",
            "email_verified": true
        }
    }
    ```
    
    **Response:**
    ```json
    {
        "success": true,
        "message": "Preferences saved successfully",
        "user_id": "user123"
    }
    ```
    """
    try:
        # Prepare preferences data
        prefs_data = {
            'preferences': request.preferences.dict(),
            'smart_matching_enabled': True,
        }
        
        # Save to Firebase
        success = await firebase_service.save_user_preferences(
            user_id=request.user_id,
            preferences=prefs_data
        )
        
        if success:
            return {
                "success": True,
                "message": "Preferences saved successfully",
                "user_id": request.user_id
            }
        else:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to save preferences"
            )
            
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error saving preferences: {str(e)}"
        )


@router.get("/preferences/{user_id}", response_model=UserPreferences)
async def get_preferences(user_id: str):
    """
    Get user preferences
    
    **Parameters:**
    - user_id: User ID
    
    **Response:**
    ```json
    {
        "office": {
            "name": "Google India",
            "location": {...},
            "start_time": "09:00",
            "end_time": "18:00"
        },
        "music_preference": "soft",
        "talk_preference": "normal",
        "gender_preference": "any",
        "ride_frequency": "daily",
        "company_email": "user@google.com",
        "email_verified": true
    }
    ```
    """
    try:
        prefs_data = await firebase_service.get_user_preferences(user_id)
        
        if not prefs_data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Preferences not found for user {user_id}"
            )
        
        return UserPreferences(**prefs_data.get('preferences', {}))
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error fetching preferences: {str(e)}"
        )


@router.put("/preferences/{user_id}", status_code=status.HTTP_200_OK)
async def update_preferences(user_id: str, preferences: UserPreferences):
    """
    Update user preferences
    
    **Parameters:**
    - user_id: User ID
    
    **Request Body:** Same as UserPreferences model
    
    **Response:**
    ```json
    {
        "success": true,
        "message": "Preferences updated successfully",
        "user_id": "user123"
    }
    ```
    """
    try:
        # Check if preferences exist
        existing = await firebase_service.get_user_preferences(user_id)
        
        if not existing:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Preferences not found for user {user_id}"
            )
        
        # Update preferences
        prefs_data = {
            'preferences': preferences.dict(),
            'smart_matching_enabled': existing.get('smart_matching_enabled', True),
        }
        
        success = await firebase_service.save_user_preferences(
            user_id=user_id,
            preferences=prefs_data
        )
        
        if success:
            return {
                "success": True,
                "message": "Preferences updated successfully",
                "user_id": user_id
            }
        else:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to update preferences"
            )
            
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error updating preferences: {str(e)}"
        )


@router.delete("/preferences/{user_id}", status_code=status.HTTP_200_OK)
async def delete_preferences(user_id: str):
    """
    Delete user preferences (disable smart matching)
    
    **Parameters:**
    - user_id: User ID
    
    **Response:**
    ```json
    {
        "success": true,
        "message": "Preferences deleted successfully",
        "user_id": "user123"
    }
    ```
    """
    try:
        # Instead of deleting, disable smart matching
        prefs_data = {
            'smart_matching_enabled': False,
        }
        
        success = await firebase_service.save_user_preferences(
            user_id=user_id,
            preferences=prefs_data
        )
        
        if success:
            return {
                "success": True,
                "message": "Smart matching disabled successfully",
                "user_id": user_id
            }
        else:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to disable smart matching"
            )
            
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error disabling smart matching: {str(e)}"
        )
